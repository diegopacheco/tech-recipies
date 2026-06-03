# Rate Limiting

## What is it?

Rate limiting caps how many operations a client may perform in a window of time. It protects a service from being overwhelmed, enforces fairness across tenants, defends against abuse and runaway clients, and turns usage into a billable quota. Where [[load-shedding-backpressure]] reacts to *internal* overload, rate limiting is a *proactive, per-client* control applied at the edge: it decides whether to admit a request before any real work happens.

A limiter returns one of two answers per request — **allow** or **deny** — and on deny typically responds with HTTP `429 Too Many Requests` plus a `Retry-After` header.

## The core algorithms

There are five classic algorithms. Three of them (the window family) are covered from the data-structure angle in [[sliding-windown]]; here they are framed as admission-control mechanisms alongside the two bucket algorithms.

### 1. Token Bucket

A bucket holds up to `B` tokens and refills at `R` tokens/second. Each request removes one token; if the bucket is empty, the request is denied. Allows **bursts** up to `B` while enforcing an average rate of `R`.

```
refill R tokens/sec
        │
        ▼
   ┌─────────┐   request takes 1 token
   │ ● ● ● ● │ ───────────────────────▶ allow if ≥1 token
   │ ● ●     │                          deny  if empty
   └─────────┘
   capacity B (max burst)

state per client: { tokens, lastRefillTimestamp }
on request:
   tokens = min(B, tokens + (now - lastRefill) * R)
   if tokens >= 1: tokens -= 1; allow
   else: deny
```

Token bucket is the most widely used algorithm because it is cheap (two numbers per client, computed lazily — no background timer) and burst-friendly.

### 2. Leaky Bucket

Requests enter a queue (the bucket) and **leak out at a constant rate** `R`. If the bucket is full, new requests overflow and are dropped. Smooths bursty input into a steady output stream — the opposite emphasis from token bucket.

```
   requests in (bursty)
        │ │ │
        ▼ ▼ ▼
   ┌─────────────┐
   │ ▒ ▒ ▒ ▒ ▒   │  queue, capacity B
   └──────┬──────┘
          │ leak at fixed rate R
          ▼
     steady output ─────▶ service
   overflow (bucket full) → drop
```

Token bucket *permits* bursts; leaky bucket *absorbs and flattens* them. Use leaky bucket when the downstream needs a smooth, constant rate (e.g. a third-party API with a hard steady cap).

### 3. Fixed Window Counter

Count requests per fixed clock window (e.g. per minute). Simple and O(1), but suffers the **boundary burst** problem: a client can send `N` requests at 0:59 and `N` more at 1:00, getting `2N` in two seconds while never violating the per-minute count.

```
window [12:00:00 – 12:00:59]  count ≤ limit
   ✗ burst at 12:00:59 + burst at 12:01:00 = 2× limit across the boundary
```

### 4. Sliding Window Log

Store the timestamp of every request; on each new request, drop timestamps older than the window and count what remains. **Exact**, no boundary problem, but O(n) memory per client — expensive at scale.

### 5. Sliding Window Counter

Approximate the sliding window by weighting the previous fixed window's count by the overlap fraction. O(1) memory, no hard boundary burst, small approximation error. The pragmatic default used by Cloudflare and others.

```
rate ≈ current_window_count
     + previous_window_count × (overlap fraction of window)
```

## GCRA (Generic Cell Rate Algorithm)

GCRA is a precise, single-variable reformulation of the leaky bucket from ATM networking. Instead of tracking tokens, it tracks a single **theoretical arrival time (TAT)** — the earliest time the next request is allowed. It enforces both an average rate and a burst tolerance with one timestamp and no background refill loop, which makes it ideal for distributed limiters (one value to read/write atomically). Stripe's rate limiter is GCRA-based; the `redis-cell` module implements it.

```
emission interval T = 1 / rate
on request at time t_now:
   if t_now < TAT − burst_tolerance:  deny
   else: TAT = max(TAT, t_now) + T;  allow
```

## Distributed rate limiting

A single-node limiter is easy; rate limiting a fleet behind a load balancer is the hard part, because the limit is *global* but the counters are *local*.

```
┌──────────────────────────────────────────────────────────────┐
│ Approach          │ How                          │ Tradeoff   │
├───────────────────┼──────────────────────────────┼────────────┤
│ Centralized store │ every node reads/writes a     │ accurate,  │
│ (Redis + Lua)     │ shared counter atomically     │ adds latency│
│                   │                               │ + SPOF risk│
├───────────────────┼──────────────────────────────┼────────────┤
│ Local + sync      │ each node limits locally,      │ fast,      │
│ (gossip/periodic) │ periodically shares counts     │ approximate│
├───────────────────┼──────────────────────────────┼────────────┤
│ Sticky routing    │ route a client always to the   │ exact per  │
│ (consistent hash) │ same node ([[consistent-hashing]])│ client, hot│
│                   │                               │ keys risk  │
├───────────────────┼──────────────────────────────┼────────────┤
│ Quota allocation  │ central authority hands each   │ scalable,  │
│ (sliding budgets) │ node a slice of the global     │ slight     │
│                   │ budget, refilled periodically  │ slack      │
└───────────────────┴──────────────────────────────┴────────────┘
```

The Redis approach is dominant: a small Lua script does the read-modify-write atomically so concurrent nodes cannot race. For very high throughput, nodes limit locally against an allocated quota slice and reconcile with the central store asynchronously, trading a little accuracy for big latency and availability wins.

## Response semantics

A well-behaved limiter tells the client how to back off:

```
HTTP/1.1 429 Too Many Requests
Retry-After: 30
RateLimit-Limit: 1000
RateLimit-Remaining: 0
RateLimit-Reset: 30
```

Clients should honor `Retry-After` with exponential backoff and jitter to avoid synchronized retry storms (see [[tail-latency]] and [[load-shedding-backpressure]]).

## Comparison

```
┌──────────────────────┬──────────┬──────────┬─────────────┬──────────────────────┐
│ Algorithm            │ Time     │ Space    │ Bursts      │ Accuracy             │
├──────────────────────┼──────────┼──────────┼─────────────┼──────────────────────┤
│ Token Bucket         │ O(1)     │ O(1)     │ Allowed (B) │ Exact average        │
├──────────────────────┼──────────┼──────────┼─────────────┼──────────────────────┤
│ Leaky Bucket         │ O(1)     │ O(B)     │ Smoothed    │ Exact output rate    │
├──────────────────────┼──────────┼──────────┼─────────────┼──────────────────────┤
│ Fixed Window         │ O(1)     │ O(1)     │ Boundary bug│ Approximate          │
├──────────────────────┼──────────┼──────────┼─────────────┼──────────────────────┤
│ Sliding Window Log   │ O(n)     │ O(n)     │ None        │ Exact                │
├──────────────────────┼──────────┼──────────┼─────────────┼──────────────────────┤
│ Sliding Window Count │ O(1)     │ O(1)     │ Minimal     │ Good approximation   │
├──────────────────────┼──────────┼──────────┼─────────────┼──────────────────────┤
│ GCRA                 │ O(1)     │ O(1)     │ Tunable     │ Exact, single value  │
└──────────────────────┴──────────┴──────────┴─────────────┴──────────────────────┘
```

## Rate limiting vs concurrency limiting

These are different controls and are often confused:

- **Rate limit**: caps requests **per unit time** (e.g. 1000 req/min). Bounds *throughput*.
- **Concurrency limit**: caps requests **in flight at once** (e.g. 50 simultaneous). Bounds *queue depth* and is governed by Little's Law (see [[load-shedding-backpressure]]).

A slow downstream can be killed by 100 concurrent slow requests even at a modest per-minute rate, so production systems usually apply both.

## Pros

- **Protection from overload and abuse**: caps the blast radius of a misbehaving or malicious client
- **Fairness across tenants**: one noisy tenant cannot starve others (pairs with [[cell-based-architecture]] isolation)
- **Cost control and monetization**: usage tiers and quotas map directly to limits
- **Cheap to run**: token bucket / GCRA need a couple of numbers per client, computed lazily
- **DDoS mitigation layer**: throttles volumetric attacks before they reach application logic
- **Predictable capacity planning**: known per-client ceilings make aggregate load forecastable

## Cons

- **Distributed accuracy is hard**: global limits over many nodes are either slow (centralized) or approximate (local)
- **Hot keys**: a single very active client/key can become a bottleneck or unbalance sticky routing
- **Burst vs smoothness tension**: token bucket allows spikes, leaky bucket adds queueing latency — you must pick
- **Clock and skew issues**: window algorithms depend on synchronized time across nodes
- **Boundary effects**: fixed windows allow 2× bursts at edges; mitigated only by sliding variants
- **Legitimate traffic harmed**: too-aggressive limits reject real users; tuning the threshold is a balancing act
- **Added latency / SPOF**: a centralized Redis limiter adds a network hop and a dependency to every request
- **Retry amplification**: poorly implemented clients hammer on `429`, worsening the very overload the limit fights

## Who Uses It?

- **Stripe**: GCRA-based limiter (request rate + concurrency limiting), documented publicly
- **GitHub**: per-token API limits with `RateLimit-*` headers
- **Cloudflare**: sliding-window-counter rate limiting at the edge, plus DDoS protection
- **AWS API Gateway**: token-bucket throttling (rate + burst) per stage/key
- **Envoy / Istio**: a global rate-limit service (gRPC) with Redis backing, applied across a mesh
- **Kong / NGINX**: built-in rate-limiting plugins (leaky bucket / sliding window)
- **Redis**: `redis-cell` module implements GCRA as a primitive

## Use Cases

- **Public API quotas**: enforce per-key request ceilings and usage tiers
- **Login / OTP / password reset**: throttle to defeat credential stuffing and brute force
- **Write-heavy endpoints**: protect databases from runaway batch clients
- **Third-party API budgets**: leaky bucket smooths your outbound calls to a partner's hard limit
- **Multi-tenant SaaS fairness**: per-tenant limits prevent noisy-neighbor starvation
- **DDoS / abuse defense**: edge throttling of volumetric and application-layer floods
- **Cost protection for expensive operations**: cap calls to LLM inference, search, or report generation
- **Gradual rollout / canary**: limit traffic to a new build while it proves out

## Links

* https://stripe.com/blog/rate-limiters
* https://cloud.google.com/architecture/rate-limiting-strategies-techniques
* https://github.com/brandur/redis-cell (GCRA)
* https://datatracker.ietf.org/doc/draft-ietf-httpapi-ratelimit-headers/ (RateLimit header standard)
