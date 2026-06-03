# Load Shedding, Backpressure, and Adaptive Concurrency

## What is it?

These are the three mechanisms that keep a system stable when demand exceeds capacity. Without them, an overloaded service does not slow down gracefully — it falls off a cliff: queues grow unboundedly, latency explodes, memory fills, timeouts cascade, retries amplify the load, and the system collapses into **congestion collapse** where it does work but completes nothing.

- **Backpressure**: propagate "slow down" upstream so producers stop sending faster than consumers can process
- **Load shedding**: when you cannot slow the source, deliberately reject or drop work to protect the rest
- **Adaptive concurrency**: continuously discover the right amount of in-flight work instead of hardcoding a limit

All three answer the same question — *what do I do with work I cannot handle right now?* — and they pair directly with [[rate-limiting]] (which caps the input rate) and [[tail-latency]] (which is the first symptom of impending overload).

## Why it matters: the physics of queues

### Little's Law

```
L = λ × W

L = average number of requests in the system (concurrency)
λ = arrival rate (requests/sec)
W = average time a request spends in the system (latency)
```

Little's Law is the foundation. It lets you compute a safe concurrency limit from a target latency and known throughput, and it explains why a fixed concurrency limit implicitly bounds latency.

### Latency explodes near saturation

Queueing theory shows that as utilization `ρ` (rho) approaches 1.0, waiting time grows without bound:

```
Wait time ∝ ρ / (1 − ρ)

ρ = 0.5  → factor 1.0   (system feels fine)
ρ = 0.8  → factor 4.0
ρ = 0.9  → factor 9.0
ρ = 0.95 → factor 19.0  (latency through the roof)
ρ = 0.99 → factor 99.0  (effectively down)
```

This is why running a service at 95%+ utilization is dangerous: a tiny traffic increase produces a massive latency jump. The job of these mechanisms is to keep the system off the right edge of that curve.

### The Universal Scalability Law

Adding workers does not scale linearly. The USL (Neil Gunther) captures two penalties: **contention** (serialized work, Amdahl's law) and **coherency** (cost of keeping workers in sync, which is quadratic). Past a point, more concurrency makes throughput *worse* — another reason a tunable concurrency limit beats "just add threads."

---

## Backpressure

Backpressure is flow control: a slow consumer signals a fast producer to ease off. The canonical mechanism is a **bounded queue** — when it fills, the producer blocks, slows, or is rejected.

```
Producer ──▶ [ bounded buffer ]  ──▶ Consumer
                    │
            buffer full?
            ├─ block the producer   (synchronous backpressure)
            ├─ drop newest/oldest   (lossy, becomes load shedding)
            └─ signal "slow down"   (reactive demand)
```

### Where it shows up

- **TCP flow control**: the receive window is pure backpressure — the receiver advertises how much it can take, the sender cannot outrun it
- **Reactive Streams** (`request(n)` demand signaling): Project Reactor, RxJava, Akka Streams — the consumer pulls exactly what it can handle
- **Bounded channels**: Go channels, Java `ArrayBlockingQueue`, Rust bounded `mpsc` — a full channel blocks the sender
- **gRPC / HTTP/2 flow control**: per-stream windows apply backpressure at the protocol layer (see [[http2-http3]])
- **Kafka consumer lag**: consumers pull at their own pace; the broker never pushes faster than they read (see [[kafka-vs-rabbitmq-comparison]])

### The catch: unbounded buffers

The most common production failure is an **unbounded queue** that "absorbs" bursts. It does not absorb them — it hides the overload until memory runs out, all while inflating latency (every request waits behind a huge backlog). Backpressure only works with **bounded** buffers. An unbounded buffer converts a throughput problem into a latency-and-memory catastrophe.

---

## Load shedding

When you cannot apply backpressure (the source is the open internet and will not slow down), you must **shed**: reject work fast and cheap so the work you do accept actually completes.

### Principles

- **Reject early and cheaply**: drop at the edge before expensive work begins; a request you reject after 90% of the work is wasted capacity
- **Fail fast**: return `503`/`429` immediately rather than queueing and timing out later
- **Shed by priority**: drop low-value work first to protect high-value work

### Prioritized / criticality-based shedding

Google's SRE practice tags every request with a **criticality**: `CRITICAL_PLUS`, `CRITICAL`, `SHEDDABLE_PLUS`, `SHEDDABLE`. Under load, shed the lowest tiers first.

```
                  load rising →
   capacity  ████████████████████░░░░  shed SHEDDABLE
             ████████████████░░░░░░░░  shed SHEDDABLE_PLUS
             ████████████░░░░░░░░░░░░  shed CRITICAL
   keep:     CRITICAL_PLUS always served while any capacity remains
```

### Graceful degradation and brownout

Rather than rejecting outright, return a **degraded** response: skip personalization, serve a cached or default result, drop optional enrichments. "Brownout" deliberately disables non-essential features to shed CPU while staying up.

### CoDel (Controlled Delay)

A smarter queue discipline (Nichols & Jacobson, 2012) that sheds based on **how long requests sit in the queue**, not queue length. If the minimum sojourn time over a window exceeds a target (e.g. 5ms), it starts dropping. This distinguishes a standing backlog (bad, shed it) from a brief burst (fine, keep it). Used in `fq_codel` networking and adapted by Facebook for service request queues.

---

## Adaptive concurrency limits

Static limits are wrong the moment they are set: downstream capacity changes with deploys, GC pauses, noisy neighbors, and traffic mix. **Adaptive concurrency** borrows from TCP congestion control to discover the limit continuously.

### The idea (Netflix concurrency-limits)

Treat your service like a TCP connection finding the right window. Watch latency as a congestion signal: when latency climbs relative to the best observed (no-load) latency, you are queueing, so shrink the limit. When latency is healthy, grow it.

```
gradient = RTT_noload / RTT_actual      (1.0 = no queueing)

newLimit = currentLimit × gradient + queueSize

gradient < 1  → latency rising → reduce concurrency limit
gradient ≈ 1  → healthy        → allow limit to grow
```

This is **AIMD-style** (additive increase, multiplicative decrease) or gradient-based control, the same family that keeps the internet from collapsing. The limit found is exactly Little's Law's `L` for your current target latency — no manual tuning, automatically tracking real capacity.

### TCP congestion-control lineage

- **AIMD** (Reno): grow linearly, cut hard on congestion — fair and stable
- **Vegas**: uses delay (RTT inflation) rather than loss as the congestion signal — the model adaptive limiters copy, because a slow service shows up as latency before it shows up as errors
- **Gradient** (Netflix): the delay-based limiter for RPC services

---

## Comparison

```
┌──────────────────────┬─────────────────────────┬───────────────────────────────┐
│ Mechanism            │ Controls                │ When to use                   │
├──────────────────────┼─────────────────────────┼───────────────────────────────┤
│ Backpressure         │ producer speed          │ you control the producer      │
│                      │                         │ (internal pipelines, streams) │
├──────────────────────┼─────────────────────────┼───────────────────────────────┤
│ Load shedding        │ which work to drop      │ source is uncontrollable      │
│                      │                         │ (public API under spike)      │
├──────────────────────┼─────────────────────────┼───────────────────────────────┤
│ Adaptive concurrency │ in-flight request count │ downstream capacity is        │
│                      │                         │ unknown / varies              │
├──────────────────────┼─────────────────────────┼───────────────────────────────┤
│ Rate limiting        │ request arrival rate    │ enforce fairness / quotas     │
│ ([[rate-limiting]])  │                         │ per client                    │
├──────────────────────┼─────────────────────────┼───────────────────────────────┤
│ Circuit breaker      │ calls to a sick         │ stop hammering a failing      │
│                      │ dependency              │ downstream, fail fast         │
└──────────────────────┴─────────────────────────┴───────────────────────────────┘
```

These compose: a public endpoint uses **rate limiting** for per-client fairness, **adaptive concurrency** to size in-flight work, **load shedding** when even that is exceeded, and **backpressure** internally between pipeline stages.

## Retries make it worse

Naive retries are a load multiplier: when a service is struggling, every client retrying triples the offered load exactly when it can least afford it (a **retry storm**). Defenses:

- **Retry budgets**: cap retries to a small fraction (e.g. 10%) of total requests, not per-call
- **Exponential backoff with jitter**: spread retries out, break synchronization (see [[tail-latency]])
- **Circuit breakers**: stop retrying a dependency that is clearly down
- **Deadline propagation**: never retry work whose deadline has already passed

## Pros

- **Stability under overload**: the system stays up and keeps completing work instead of collapsing
- **Bounded latency**: limiting concurrency caps queue depth, which by Little's Law caps latency
- **Graceful failure**: shed/degrade beats a hard crash that takes everything down
- **Self-tuning**: adaptive limits track real capacity through deploys and noisy neighbors with no manual tuning
- **Protects the critical path**: prioritized shedding sacrifices low-value work to keep revenue-critical work flowing
- **Prevents cascading failure**: stopping overload at the edge keeps it from rippling across [[cell-based-architecture]] and microservices

## Cons

- **Rejected work is still failure**: shedding trades a worse failure (collapse) for a milder one (some `503`s), but users still see errors
- **Tuning signals are subtle**: choosing the right latency target, criticality tiers, and CoDel thresholds takes measurement
- **Backpressure can deadlock**: blocking producers in a cycle of services can stall the whole graph if not designed carefully
- **Fairness is hard**: naive shedding can starve specific clients or request types
- **Observability cost**: you must measure no-load latency, queue times, and per-tier load to act correctly
- **False positives**: a brief latency blip can make an adaptive limiter over-shrink and needlessly reject work
- **Cross-team coordination**: criticality tiers only work if every caller tags requests honestly

## Who Uses It?

- **Netflix**: open-sourced `concurrency-limits` (adaptive, gradient-based) and pioneered bulkheads/circuit breakers with Hystrix
- **Google**: criticality-based load shedding and graceful degradation documented in the SRE book; Stubby/gRPC deadline propagation
- **Facebook/Meta**: adapted CoDel for service queue management at the thread-pool level
- **Envoy / Istio**: built-in adaptive concurrency filter, circuit breaking, and outlier detection (see [[traffic-replay]] for the same proxy layer)
- **AWS**: load shedding and brownout patterns documented in the Builders' Library
- **Lyft**: automatic concurrency limiting in their service mesh

## Use Cases

- **Public API under traffic spikes**: shed low-priority requests, return `429`/`503` fast, protect paying tiers
- **Microservice fan-out**: adaptive limits per downstream prevent one slow dependency from exhausting threads
- **Stream and batch pipelines**: bounded queues apply backpressure from sink back to source (Flink, Kafka Streams)
- **Thread-pool / connection-pool sizing**: CoDel-style shedding on queued work instead of unbounded waiting
- **Database connection pools**: cap in-flight queries so the database is never the bottleneck that takes the app down
- **Black Friday / flash sales**: graceful degradation drops recommendations and personalization to keep checkout alive
- **Mesh-wide protection**: Envoy concurrency limiting and circuit breaking applied uniformly across all services

## Links

* https://github.com/Netflix/concurrency-limits
* https://sre.google/sre-book/handling-overload/
* https://aws.amazon.com/builders-library/using-load-shedding-to-avoid-overload/
* https://queue.acm.org/detail.cfm?id=2209336 (CoDel, Nichols & Jacobson)
