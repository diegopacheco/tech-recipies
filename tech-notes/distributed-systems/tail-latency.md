# Tail Latency

## What is it?

Tail latency refers to the high-percentile response times in a system (p99, p99.9, p99.99). While median (p50) latency shows the typical experience, tail latency shows the worst-case experience that a small but real percentage of users hit on every request. In distributed systems, tail latency compounds: if a single user request fans out to 100 backend services, the probability that at least one of them hits a tail latency spike is very high, making the overall response slow.

The problem was formalized by **Jeff Dean and Luiz André Barroso** at Google in their 2013 paper **"The Tail at Scale"** published in Communications of the ACM.

## Why it matters?

Consider a service with p50 = 5ms and p99 = 100ms calling 100 backends in parallel:

```
Single call: 1% chance of being slow (>100ms)

Fan-out to 100 backends:
  P(all fast) = 0.99^100 = 36.6%
  P(at least one slow) = 1 - 0.99^100 = 63.4%

63.4% of user requests will be slower than 100ms
even though each individual service is fast 99% of the time
```

At higher fan-out:
```
┌────────────┬──────────────────────────────────┐
│ Fan-out    │ P(at least one p99 hit)          │
├────────────┼──────────────────────────────────┤
│ 1 backend  │ 1%                               │
├────────────┼──────────────────────────────────┤
│ 10         │ 9.6%                             │
├────────────┼──────────────────────────────────┤
│ 50         │ 39.5%                            │
├────────────┼──────────────────────────────────┤
│ 100        │ 63.4%                            │
├────────────┼──────────────────────────────────┤
│ 500        │ 99.3%                            │
└────────────┴──────────────────────────────────┘
```

## Common Causes

### Infrastructure-Level
1. **Garbage Collection**: GC pauses freeze the application for milliseconds to seconds (Java, Go, .NET)
2. **CPU Throttling**: Noisy neighbors on shared hardware steal CPU cycles, cgroups throttling in containers
3. **Network Congestion**: Switch buffer bloat, TCP retransmissions, packet loss causing exponential backoff
4. **Disk I/O**: SSD write stalls during compaction, HDD seek latency variance, page faults
5. **TLB Misses**: Large heap without huge pages causes frequent translation lookaside buffer misses
6. **Context Switches**: Excessive thread count causes OS scheduler overhead and cache thrashing
7. **NUMA Effects**: Accessing memory on a remote NUMA node costs 2-3x compared to local

### Application-Level
8. **Lock Contention**: Threads waiting on mutexes serialize and amplify latency
9. **Queue Buildup**: Request queues grow during load spikes, queueing time dominates processing time
10. **Cold Cache**: First request after cache eviction or restart hits the slow path (database, disk)
11. **Retry Storms**: Failed requests retry simultaneously causing load amplification
12. **Large Payloads**: Occasional large responses (serialization, network transfer) add variance
13. **Background Tasks**: Compaction, checkpointing, log rotation running on the same host

### Measurement Artifacts
14. **Coordinated Omission**: Load generators that wait for responses before sending the next request undercount tail latency by not measuring queueing time during slowdowns
15. **Averaging Percentiles**: Averaging p99 across instances hides the true distribution

## Mitigation Techniques

### 1. Hedged Requests

Send the same request to multiple replicas and use whichever responds first. Cancel the others. Dramatically reduces tail latency at the cost of extra load.

```
Client sends request to Replica A
After 5ms (p95 threshold), also send to Replica B
Use first response, cancel the other

Tail latency of hedged request:
  P(both slow) = P(A slow) * P(B slow)
  If P(slow) = 1%, hedged P(slow) = 0.01%
```

- Overhead: ~5% extra load for significant tail reduction
- Used by: Google BigTable, Cassandra speculative retry, S3

### 2. Tied Requests

Send the request to two servers simultaneously, but include a cancellation token. When one server starts processing, it notifies the other to cancel. Lower overhead than hedged requests.

- Overhead: minimal (most duplicates are cancelled before processing)
- Used by: Google systems internally

### 3. Request Deadlines and Timeouts

Every request carries a deadline. If the deadline is about to expire, the server stops work early and returns a partial result or error rather than completing a response nobody will wait for.

```
Client sets deadline: 200ms
Service A receives at t=0, processes, calls Service B at t=50ms
Service B receives with remaining deadline: 150ms
If Service B cannot finish in 150ms, it fails fast
```

- Propagate deadlines across the full call chain
- Cancel downstream work when upstream has already timed out

### 4. Latency-Aware Load Balancing

Route requests to the replica with the lowest recent latency instead of round-robin. Avoids sending traffic to a node experiencing a GC pause or I/O stall.

Strategies:
- **Least loaded**: Route to server with fewest in-flight requests
- **Peak EWMA**: Exponentially weighted moving average of response times (used by Finagle)
- **Choice of two**: Pick two random servers, send to the one with lower load (power of two choices)

### 5. Differentiated Service Classes

Separate high-priority latency-sensitive requests from batch background work. Use different thread pools, queues, or even different machines.

```
Priority queue:
  [HIGH] user-facing API requests → small queue, fast timeout
  [LOW]  batch analytics, replication → large queue, relaxed timeout
```

### 6. Reducing Head-of-Line Blocking

Break large requests into smaller chunks. A 10MB response blocks the connection while a 1KB response waits behind it.

- Break large RPCs into streaming chunks
- Use separate connections for latency-critical vs bulk traffic
- HTTP/2 multiplexing helps but does not eliminate TCP HOL blocking

### 7. Jitter and Backoff

Add randomized jitter to retries, timeouts, and periodic tasks to prevent thundering herd effects where many clients synchronize their behavior.

```
retry_delay = base_delay * 2^attempt + random(0, base_delay)
```

### 8. Warm Caches and Precomputation

Eliminate cold-cache latency spikes by prewarming caches on deploy and precomputing expensive results.

- Cache warming: populate cache before routing traffic to new instance
- Shadow traffic: replay production traffic to new instances before cutover
- Precomputation: materialize expensive queries on write instead of read

## Measurement

### Percentiles to Track

```
┌────────┬──────────────────────────────────────────────────┐
│ Metric │ What it tells you                                │
├────────┼──────────────────────────────────────────────────┤
│ p50    │ Typical user experience                          │
├────────┼──────────────────────────────────────────────────┤
│ p90    │ Slower-than-average experience, good baseline    │
├────────┼──────────────────────────────────────────────────┤
│ p99    │ Worst 1 in 100 requests, standard SLO target     │
├────────┼──────────────────────────────────────────────────┤
│ p99.9  │ 1 in 1000, matters for high-fan-out systems      │
├────────┼──────────────────────────────────────────────────┤
│ p99.99 │ 1 in 10000, matters for systems serving millions │
├────────┼──────────────────────────────────────────────────┤
│ max    │ Worst single request, often GC or timeout        │
└────────┴──────────────────────────────────────────────────┘
```

### Tools

- **HDR Histogram**: High dynamic range histogram that records latencies from microseconds to hours in a single structure without losing precision at the tails. Used by most serious latency benchmarking tools
- **wrk2**: HTTP benchmark tool that corrects for coordinated omission (unlike wrk, ab, or siege)
- **Prometheus histogram/summary**: histogram_quantile() computes percentiles from bucketed observations
- **OpenTelemetry**: Distributed traces show per-span latency to pinpoint which service or operation caused a tail spike

### Coordinated Omission Problem

Most load generators send request N+1 only after request N completes. If request N takes 500ms, the generator pauses for 500ms and does not measure the latency that would-be requests experienced during that pause.

```
Naive benchmark (coordinated omission):
  Request 1: 5ms
  Request 2: 5ms
  Request 3: 500ms (stall)
  Request 4: 5ms
  Reported p99: ~500ms
  Reality: requests that WOULD have arrived during the 500ms stall also experienced 500ms+ delay

Corrected benchmark:
  Measures what latency each request would have seen if sent at a fixed rate
  Reported p99: much higher than naive measurement
```

## Pros (of addressing tail latency)

- **Better User Experience**: p99 improvements affect real users, especially power users who make many requests
- **SLO Compliance**: Meeting p99 SLOs is harder and more meaningful than meeting p50 targets
- **Fan-Out Resilience**: Reducing tail latency at each service compounds across the call graph
- **Capacity Efficiency**: Systems with lower tail variance can run at higher utilization safely
- **Predictability**: Lower variance means more consistent behavior under load

## Cons (of tail latency mitigation)

- **Extra Resources**: Hedged requests consume additional compute and network bandwidth
- **Complexity**: Deadline propagation, priority queues, and speculative execution add implementation complexity
- **Diminishing Returns**: Reducing p99.99 may cost more than the business value it provides
- **Measurement Overhead**: High-resolution histograms and distributed tracing consume memory and CPU
- **Over-Optimization Risk**: Chasing tail latency when the real bottleneck is elsewhere wastes engineering effort
- **Harder to Debug**: Tail events are rare and intermittent, making them difficult to reproduce and diagnose

## Use Cases

- **Search Engines**: Google's web search fans out to thousands of shards, tail latency at any shard delays the whole response
- **E-Commerce**: Checkout page aggregates inventory, pricing, recommendations, and payment services in parallel
- **Ad Serving**: Real-time bidding with strict 100ms deadlines across multiple demand-side platforms
- **Video Streaming**: Manifest and segment requests need consistent low latency for smooth playback
- **Trading Systems**: Microsecond-level tail latency differences translate directly to money
- **Database Queries**: Scatter-gather queries across partitions wait for the slowest partition
- **Microservices**: Any service calling multiple downstream services in parallel is subject to tail amplification
- **CDN Edge**: Cache misses at the edge fan out to origin servers where tail latency determines user experience
- **Gaming**: Multiplayer game servers need consistent tick rates, p99 spikes cause visible lag
- **API Gateways**: Gateway aggregating multiple backend responses is only as fast as the slowest backend
