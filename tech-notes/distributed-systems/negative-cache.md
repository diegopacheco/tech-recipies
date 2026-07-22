# Negative Caching

## What is a Negative Cache?

A Negative Cache stores the result of a lookup that **failed** — a "not found", an error, or an empty response — so that repeated requests for the same missing item can be answered immediately without hitting the expensive backend again. Where a normal cache remembers what exists, a negative cache remembers what does **not** exist. Its main purpose is to protect slow or expensive sources (databases, DNS resolvers, remote services) from being hammered by requests for keys that will never return a value, and to defend against the cache penetration attack where an attacker floods the system with keys that are guaranteed to miss.

## How it works?

1. **Request arrives** for a key
2. **Check positive cache**: if the value is present, return it
3. **Check negative cache**: if the key is marked as "known missing", return the miss immediately without touching the backend
4. **On a real miss** (not in either cache):
   - Query the backend
   - If the backend returns a value, store it in the positive cache
   - If the backend returns "not found" / empty / error, store the key in the negative cache with a **short TTL**
5. **Expiration**: negative entries expire quickly (seconds to a few minutes) so that once the underlying data is created, the system starts serving it soon after

```
Request "user:9999" (does not exist)

  ┌──────────────┐   miss    ┌──────────────┐   miss    ┌──────────────┐
  │ Positive     │ ───────►  │ Negative     │ ───────►  │  Backend     │
  │ Cache        │           │ Cache        │           │  (DB / DNS)  │
  └──────────────┘           └──────────────┘           └──────────────┘
                                                               │
                                                    returns "NOT FOUND"
                                                               │
                                                               ▼
                             ┌──────────────┐   store key with short TTL
                             │ Negative     │ ◄──────────────────────────
                             │ Cache        │   negcache["user:9999"] = ∅
                             └──────────────┘

Next request "user:9999" (within TTL)

  ┌──────────────┐   miss    ┌──────────────┐   HIT
  │ Positive     │ ───────►  │ Negative     │ ───────►  return NOT FOUND
  │ Cache        │           │ Cache        │           (backend untouched)
  └──────────────┘           └──────────────┘
```

## Key Design Decisions

### 1. TTL for negative entries

Negative entries should live **much shorter** than positive ones. A missing key can become present at any time (someone signs up, a record is inserted, a DNS record is published). A long negative TTL means users keep seeing "not found" long after the data exists. Typical values are 5-60 seconds, sometimes up to a few minutes.

### 2. What counts as "negative"?

- **404 / not found**: safe to cache, the classic case
- **Empty result set**: safe to cache
- **Timeouts / 5xx errors**: cache with extreme caution and very short TTL, or not at all — a transient outage should not be remembered as "does not exist"
- **Auth failures**: usually should not be negatively cached, permissions change

### 3. Storing a marker, not the absence

The negative cache stores an explicit sentinel (a null marker, a tombstone, an empty object) so the code can distinguish "we know this is missing" from "we have never looked". Storing plain `null` is ambiguous in many cache clients, so a dedicated marker value is preferred.

## Negative Cache vs Bloom Filter

Both defend against lookups for non-existent keys, and they are often combined. See [[bloom-filters]].

```
┌────────────────────┬──────────────────────────┬──────────────────────────┐
│                    │ Negative Cache           │ Bloom Filter             │
├────────────────────┼──────────────────────────┼──────────────────────────┤
│ Answers            │ "this key is missing"    │ "this key is maybe       │
│                    │ (for keys already asked) │  present / definitely    │
│                    │                          │  absent" (for all keys)  │
├────────────────────┼──────────────────────────┼──────────────────────────┤
│ Populated by       │ actual failed lookups    │ known set of valid keys  │
├────────────────────┼──────────────────────────┼──────────────────────────┤
│ False positives    │ no (exact per key)       │ yes (tunable rate)       │
├────────────────────┼──────────────────────────┼──────────────────────────┤
│ Coverage           │ only keys seen before    │ every possible key       │
├────────────────────┼──────────────────────────┼──────────────────────────┤
│ Memory             │ grows with distinct      │ fixed, tiny              │
│                    │ missing keys queried     │                          │
└────────────────────┴──────────────────────────┴──────────────────────────┘
```

A common production pattern: a Bloom filter of all valid keys rejects the vast majority of never-existed keys up front, and a negative cache absorbs the rest (keys that pass the Bloom filter's false-positive check but still miss).

## Related Problems It Solves

### Cache Penetration

An attacker (or a buggy client) requests keys that never exist. Each request slips past the positive cache and hits the database directly. Under enough volume this overwhelms the backend. A negative cache turns those repeated misses into cheap cache hits. See also [[rate-limiting]] and [[load-shedding-backpressure]].

### DNS Negative Caching (RFC 2308)

DNS resolvers cache negative answers (NXDOMAIN, NODATA) using the SOA record's minimum TTL. This is the canonical, standardized form of negative caching and prevents the internet's root and authoritative servers from being flooded with queries for domains that do not exist.

## Pros

- **Protects the Backend**: Repeated lookups for missing keys never reach the database or remote service
- **Defends Against Cache Penetration**: Neutralizes floods of never-existent keys
- **Cheap Hits**: A negative hit is as fast as a positive hit
- **Simple to Add**: Usually a small change to the existing cache-aside logic
- **Standardized in DNS**: Well-understood, proven at internet scale (RFC 2308)
- **Reduces Tail Latency**: Missing-key requests no longer pay the full backend round trip

## Cons

- **Staleness Window**: A key created during the negative TTL keeps returning "not found" until the entry expires
- **Memory Growth**: An attacker can still fill the negative cache with millions of distinct fake keys (mitigate with a Bloom filter or bounded/LRU negative cache)
- **Wrong Things Cached**: Negatively caching transient errors (timeouts, 5xx) can prolong outages
- **Consistency Complexity**: Writes that create a key must invalidate the corresponding negative entry, or accept the TTL delay
- **Ambiguity Bugs**: Confusing "known missing" with "never looked up" causes subtle correctness errors if a sentinel is not used
- **Two Caches to Reason About**: Positive and negative caches must be kept coherent

## Use Cases

- **Cache-Aside Databases**: Redis / Memcached in front of a SQL or NoSQL store, caching "row not found" for a short TTL
- **DNS Resolvers**: Caching NXDOMAIN and NODATA answers per RFC 2308
- **CDN / Reverse Proxies**: Caching 404s so origin servers are not hit for missing assets
- **Authorization / Feature Flags**: Caching "no such flag" or "no override" lookups (with care around permission changes)
- **Microservice Lookups**: Caching negative responses from a remote service to avoid repeated cross-network calls
- **User / Profile Services**: Caching "username does not exist" during signup availability checks
- **Product Catalogs**: Caching misses for discontinued or never-existed SKUs to protect the catalog DB

## Who uses it?

- **DNS Infrastructure**: BIND, Unbound, and every recursive resolver implement negative caching per RFC 2308
- **Redis / Memcached Users**: Standard mitigation in the cache-aside pattern; widely documented by Alibaba and others as the fix for "cache penetration" (缓存穿透)
- **CDNs**: Cloudflare, Akamai, and Fastly cache negative responses (404s) at the edge
- **Netflix**: EVCache and its caching layers use negative caching to shield backing stores
- **Facebook / Meta**: TAO and Memcache tiers cache negative lookups to protect the social graph databases
- **HTTP Caches**: The HTTP spec (RFC 9111) allows caching of error responses such as 404 and 410
