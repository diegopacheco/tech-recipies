# Replay Traffic

## What is it?

Traffic replay is the practice of capturing real production requests and replaying them against a different version, environment, or configuration of a service. The captured traffic — headers, body, timing, and order — is stored and then re-sent to a target system. Responses from the replay are compared against the original responses or a baseline to detect regressions, validate migrations, and load test with realistic traffic patterns. Unlike synthetic tests that simulate traffic, replay uses actual production request shapes, distributions, and edge cases.

## How it works?

### Capture and Replay Flow

```
Phase 1: Capture

Production Traffic
       │
       ▼
┌──────────────┐
│  Capture     │──► Store requests
│  Agent       │    (file, S3, Kafka)
│              │
│  (tap network│    What is captured:
│   or proxy)  │    - HTTP method, path, headers
│              │    - Request body
└──────────────┘    - Timestamp (for timing replay)
                    - Response (for comparison)


Phase 2: Replay

┌──────────────┐    Read requests     ┌──────────────┐
│  Stored      │───────────────────►  │  Replay      │
│  Traffic     │                      │  Engine      │
│  (file/S3)   │                      │              │
└──────────────┘                      │  - send to   │
                                      │    target    │
                                      │  - collect   │
                                      │    responses │
                                      └──────┬───────┘
                                             │
                                      ┌──────▼───────┐
                                      │  Target      │
                                      │  Service     │
                                      │  (v2, staging│
                                      │   or shadow) │
                                      └──────┬───────┘
                                             │
                                      ┌──────▼───────┐
                                      │  Compare     │
                                      │  Responses   │
                                      │  v1 vs v2    │
                                      └──────────────┘
```

### Capture Methods

```
┌────────────────────┬───────────────────────────────────────────────┐
│ Method             │ How it works                                   │
├────────────────────┼───────────────────────────────────────────────┤
│ Network tap        │ Capture raw packets at the network layer      │
│ (tcpdump, pcap)    │ Non-intrusive, captures everything            │
├────────────────────┼───────────────────────────────────────────────┤
│ Reverse proxy      │ Proxy sits in front of the service, copies    │
│ (GoReplay, mitmproxy)│ requests to a file or stream               │
├────────────────────┼───────────────────────────────────────────────┤
│ Application-level  │ Middleware or interceptor logs requests        │
│ logging            │ within the application code                   │
├────────────────────┼───────────────────────────────────────────────┤
│ Service mesh tap   │ Istio/Linkerd sidecar captures and mirrors    │
│                    │ traffic at the proxy layer (Envoy access log) │
├────────────────────┼───────────────────────────────────────────────┤
│ Load balancer logs │ ALB/NLB/HAProxy access logs with full         │
│                    │ request details (limited to headers + path)   │
├────────────────────┼───────────────────────────────────────────────┤
│ Message queue      │ Publish requests to Kafka/SQS for async       │
│                    │ capture and later replay                      │
└────────────────────┴───────────────────────────────────────────────┘
```

### Replay Modes

```
┌────────────────────┬───────────────────────────────────────────────┐
│ Mode               │ Description                                    │
├────────────────────┼───────────────────────────────────────────────┤
│ Real-time replay   │ Replay at the same rate as captured.          │
│                    │ Preserves original timing between requests.   │
├────────────────────┼───────────────────────────────────────────────┤
│ Accelerated replay │ Replay faster than original (2x, 5x, 10x).   │
│                    │ Used for load testing and stress testing.      │
├────────────────────┼───────────────────────────────────────────────┤
│ Decelerated replay │ Replay slower than original. Useful for       │
│                    │ debugging and step-by-step analysis.           │
├────────────────────┼───────────────────────────────────────────────┤
│ Burst replay       │ Replay all captured requests as fast as        │
│                    │ possible. Maximum stress test.                 │
├────────────────────┼───────────────────────────────────────────────┤
│ Filtered replay    │ Replay only requests matching criteria         │
│                    │ (specific endpoints, methods, users).          │
├────────────────────┼───────────────────────────────────────────────┤
│ Mutated replay     │ Modify requests before replaying (change       │
│                    │ headers, tokens, hostnames, parameters).       │
└────────────────────┴───────────────────────────────────────────────┘
```

## Tools

### GoReplay (gor)

Open-source tool for capturing and replaying HTTP traffic. Runs as a sidecar or standalone process.

```
Capture and replay in real time:

  gor --input-raw :8080 --output-http http://staging:8080

Capture to file:

  gor --input-raw :8080 --output-file requests.gor

Replay from file:

  gor --input-file requests.gor --output-http http://staging:8080

Replay at 2x speed:

  gor --input-file requests.gor \
      --output-http http://staging:8080 \
      --output-http-timeout 30s \
      --input-file-loop

Filter by URL:

  gor --input-raw :8080 \
      --output-http http://staging:8080 \
      --http-allow-url /api/v2/.*

Split to multiple outputs:

  gor --input-raw :8080 \
      --output-http http://staging:8080 \
      --output-http http://shadow:8080 \
      --output-file requests.gor
```

```
┌─────────────────────────────────────────────────┐
│                  GoReplay                        │
│                                                 │
│  ┌───────────┐    ┌───────────┐    ┌──────────┐│
│  │ Input     │───►│ Middleware│───►│ Output   ││
│  │           │    │ (filter,  │    │          ││
│  │ --input-  │    │  rewrite, │    │ --output-││
│  │   raw     │    │  rate     │    │   http   ││
│  │   file    │    │  limit)   │    │   file   ││
│  │   tcp     │    │           │    │   kafka  ││
│  └───────────┘    └───────────┘    └──────────┘│
└─────────────────────────────────────────────────┘
```

### tcpreplay

Replays network packets captured with tcpdump/pcap at the TCP/IP layer. Works at L3/L4, not HTTP-aware.

```
Capture with tcpdump:
  tcpdump -i eth0 -w traffic.pcap port 8080

Replay at original speed:
  tcpreplay -i eth0 traffic.pcap

Replay at 10x speed:
  tcpreplay -i eth0 --multiplier=10 traffic.pcap

Replay as fast as possible:
  tcpreplay -i eth0 --topspeed traffic.pcap
```

### Other Tools

```
┌────────────────────┬───────────────────────────────────────────────┐
│ Tool               │ Description                                    │
├────────────────────┼───────────────────────────────────────────────┤
│ GoReplay (gor)     │ HTTP-level capture and replay. Middleware      │
│                    │ pipeline for filtering and rewriting.          │
├────────────────────┼───────────────────────────────────────────────┤
│ tcpreplay          │ Packet-level replay from pcap files. L3/L4.   │
│                    │ No HTTP awareness.                             │
├────────────────────┼───────────────────────────────────────────────┤
│ mitmproxy          │ Interactive HTTPS proxy. Can record and        │
│                    │ replay flows. Supports scripting in Python.    │
├────────────────────┼───────────────────────────────────────────────┤
│ Hoverfly           │ API simulation and replay. Captures request/   │
│                    │ response pairs and serves them as a mock.      │
├────────────────────┼───────────────────────────────────────────────┤
│ VCR (Ruby/Python)  │ Records HTTP interactions and replays them     │
│                    │ in tests. Language-specific libraries.         │
├────────────────────┼───────────────────────────────────────────────┤
│ Gatling            │ Load testing tool that can replay recorded     │
│                    │ HAR files or access logs as load scenarios.    │
├────────────────────┼───────────────────────────────────────────────┤
│ k6                 │ Load testing with HAR import. Converts         │
│                    │ recorded traffic into test scripts.            │
├────────────────────┼───────────────────────────────────────────────┤
│ Speedscale         │ Kubernetes-native traffic replay platform.     │
│                    │ Captures via sidecar, replays in CI/CD.       │
└────────────────────┴───────────────────────────────────────────────┘
```

## Response Comparison

```
Original (v1):                    Replayed (v2):
  Request A ──► Response A          Request A ──► Response A'

Comparison Engine:
  ┌──────────────────────────────────────────┐
  │  Response A vs Response A'               │
  │                                          │
  │  Status code:  200 vs 200        ✓       │
  │  Body diff:    none              ✓       │
  │  Latency:      45ms vs 52ms     ✓ (<20%)│
  │                                          │
  │  Request B:                              │
  │  Status code:  200 vs 500        ✗ FAIL  │
  │  Body diff:    missing field     ✗ FAIL  │
  │  Latency:      30ms vs 2100ms   ✗ FAIL  │
  └──────────────────────────────────────────┘

What to compare:
  - HTTP status codes
  - Response body (JSON diff, ignoring timestamps/IDs)
  - Response headers
  - Latency (within acceptable threshold)
  - Error rates (aggregate)
```

## Handling Write Operations

```
Problem: replaying POST/PUT/DELETE against production corrupts data.

Solutions:

┌─────────────────────┬──────────────────────────────────────────────┐
│ Approach            │ How it works                                  │
├─────────────────────┼──────────────────────────────────────────────┤
│ Read-only replay    │ Filter out all non-GET requests. Simple but  │
│                     │ misses write-path bugs.                       │
├─────────────────────┼──────────────────────────────────────────────┤
│ Shadow database     │ Replay writes to a cloned database. Full     │
│                     │ coverage but expensive (DB clone + sync).     │
├─────────────────────┼──────────────────────────────────────────────┤
│ Dry-run mode        │ Application processes the write but does not │
│                     │ commit. Requires app-level support.           │
├─────────────────────┼──────────────────────────────────────────────┤
│ Idempotency keys    │ Replay with modified idempotency keys so     │
│                     │ writes create new records, not duplicates.   │
├─────────────────────┼──────────────────────────────────────────────┤
│ Staging replay      │ Replay against staging with production-like  │
│                     │ data. Safe but staging ≠ production.         │
├─────────────────────┼──────────────────────────────────────────────┤
│ Record-and-compare  │ Capture both request and response. Replay    │
│                     │ only validates the response matches without  │
│                     │ executing the write (mock backend).          │
└─────────────────────┴──────────────────────────────────────────────┘
```

## Architecture Patterns

### Inline Capture + Async Replay

```
Production:
                    ┌──────────────┐
  Client ──────────►│ GoReplay     │──────► Production Service (v1)
                    │ (capture)    │
                    └──────┬───────┘
                           │
                    Store to S3/Kafka
                           │
                    ┌──────▼───────┐
  Later:            │ Replay       │──────► Target Service (v2)
                    │ Engine       │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Diff Engine  │──────► Report
                    └──────────────┘
```

### Live Dual-Write (Mirror + Compare)

```
                    ┌──────────────────────────┐
  Client ──────────►│ Proxy / Mesh             │
                    │                          │
                    │  ┌──► v1 ──► Response ───┼──► Client
                    │  │                       │
                    │  └──► v2 ──► Response ───┼──► Discard
                    │              (compare)   │
                    └──────────────────────────┘
```

### CI/CD Pipeline Replay

```
┌──────┐    ┌──────┐    ┌───────────┐    ┌──────────┐    ┌──────┐
│ Push │───►│Build │───►│ Deploy to │───►│ Replay   │───►│ Pass │
│      │    │      │    │ staging   │    │ captured │    │ /Fail│
└──────┘    └──────┘    └───────────┘    │ traffic  │    └──────┘
                                         │ against  │
                                         │ staging  │
                                         │ + diff   │
                                         └──────────┘
```

## Pros

- **Real Traffic Patterns**: replays actual user behavior, not synthetic approximations
- **Regression Detection**: catches behavioral differences between versions with real request shapes
- **Load Testing Accuracy**: production traffic distribution is more realistic than hand-crafted load tests
- **Migration Validation**: validates API rewrites, database migrations, and framework upgrades with real traffic
- **No User Impact**: replay targets a shadow or staging system, not production users
- **Reproducibility**: captured traffic can be replayed repeatedly for debugging
- **Edge Case Coverage**: production traffic contains edge cases that synthetic tests miss
- **Time-Shifted Testing**: capture during peak hours, replay during off-hours for analysis

## Cons

- **Write Operations**: replaying mutations is dangerous without a shadow database or dry-run mode
- **Data Sensitivity**: captured traffic may contain PII, tokens, passwords (must sanitize)
- **Stale Tokens**: auth tokens and session cookies expire between capture and replay
- **State Dependency**: requests may depend on prior state (user created in request 1, modified in request 5)
- **Storage Cost**: high-traffic services generate large capture files (GB/hour)
- **Timing Sensitivity**: some bugs only manifest under exact production timing, hard to reproduce
- **Response Drift**: legitimate differences (timestamps, IDs, nonces) create false positives in diffs
- **Infrastructure Overhead**: capture agents add latency and resource consumption to production

## Use Cases

- **API Migration**: replaying traffic against a rewritten API to validate response compatibility
- **Database Migration**: replaying reads against a new database engine to compare query results
- **Framework Upgrade**: replaying traffic after upgrading a web framework to detect regressions
- **Load Testing**: replaying peak-hour traffic at 5x speed to find capacity limits
- **Performance Comparison**: replaying identical traffic against v1 and v2 to compare latency distributions
- **Debugging Production Issues**: capturing traffic around an incident for later analysis and reproduction
- **Schema Changes**: replaying traffic after changing serialization formats (JSON → Protobuf)
- **Cache Validation**: replaying traffic to verify cache hit rates after changing caching strategy
- **CDN Configuration**: replaying requests to validate new CDN routing rules before going live
- **Compliance Testing**: replaying sanitized production traffic in an isolated environment for audit validation
