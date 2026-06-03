# Traffic Record & Replay

## What is it?

Traffic record & replay is the practice of capturing real requests that hit a production system and re-issuing them somewhere else: a staging environment, a new version of the service, a canary, or a test suite. Instead of writing synthetic requests by hand, you reuse the exact shape, volume, and weirdness of live traffic. The captured stream becomes a reusable asset that can be replayed deterministically, amplified for load testing, mirrored in real time to a shadow service, or diffed against a refactored implementation.

The core idea splits into two halves that are often confused:

- **Record/replay** captures traffic to disk (a file, a "cassette") and re-issues it later. Offline, deterministic, repeatable.
- **Shadow/mirror** tees live traffic in real time to a second destination whose response is thrown away. Online, fire-and-forget, no storage required.

Both let you test new code against real-world inputs without exposing users to the new code.

## Why it matters?

Hand-written tests encode what an engineer *imagined* users would send. Production traffic encodes what users *actually* send: malformed headers, surprising encodings, legacy clients, rare query combinations, and the long tail of inputs nobody wrote a test for. Replaying real traffic finds the bugs that synthetic suites miss.

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Question                 │ How record/replay answers it                  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Will the refactor break  │ Diff old vs new responses on real requests    │
│ anything?                │ (Diffy)                                       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Can the new service take │ Mirror prod traffic to the canary, watch it   │
│ production load?         │ (Envoy/Istio)                                 │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Will the deploy hold up  │ Replay captured traffic at 2x-10x rate        │
│ at peak?                 │ (GoReplay amplification)                      │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Are my tests fast and    │ Record HTTP once into a cassette, replay      │
│ deterministic?           │ forever offline (VCR/WireMock)                │
└──────────────────────────┴───────────────────────────────────────────────┘
```

## How it works?

Every record/replay system is some subset of this pipeline:

```
   PRODUCTION                 CAPTURE              TRANSFORM            REPLAY / COMPARE
  ┌──────────┐             ┌──────────┐         ┌──────────┐          ┌──────────────┐
  │  client  │──request──▶ │  tee /   │──tap──▶ │ scrub PII│──────▶   │  staging /   │
  └──────────┘             │  sniff / │         │ rewrite  │          │  candidate / │
        │                  │  proxy   │         │ rate-cap │          │  cassette    │
        ▼                  └──────────┘         │ dedupe   │          └──────┬───────┘
  ┌──────────┐                   │              └──────────┘                 │
  │ real svc │◀──response────────┘                                          ▼
  └──────────┘              (real path is never blocked)            ┌──────────────┐
                                                                    │ discard resp │
                                                                    │  OR diff vs  │
                                                                    │  baseline    │
                                                                    └──────────────┘
```

1. **Capture** — tap the traffic without affecting the live path. Three layers:
   - **Network / packet** — sniff the NIC with libpcap (`tcpdump` on steroids). No code change, no proxy, no latency added. GoReplay works this way.
   - **Proxy / sidecar / mesh** — an in-path proxy or Envoy sidecar duplicates the request. Diffy and Istio mirroring work here.
   - **Application / SDK** — a library inside the process intercepts the HTTP client and writes interactions to a cassette. VCR, WireMock, Polly.js work here.

2. **Store or stream** — write to a `.gor` / `.har` / cassette file for offline replay, or pipe straight to a destination for online mirroring.

3. **Transform** — the part everyone underestimates. Scrub PII and secrets, rewrite hosts/headers, cap or amplify the rate, drop duplicates, normalize non-deterministic fields.

4. **Replay or compare** — fire the requests at the target. Either discard the response (shadow/load), match it to a stored response (cassette tests), or diff it against a baseline (regression testing).

## Modes

### 1. Shadow / Mirror (online, fire-and-forget)

Live traffic is copied to a second service. The copy runs **out of band** of the critical path: the user's response comes only from the primary, and the mirrored response is discarded. This is the safest way to expose new code to real load because users never see its output.

```
        ┌──────────▶ primary (canary)  ──response──▶ user
client ─┤
        └─ ─ ─ ─ ─▶ shadow (new build) ──response──▶ /dev/null
              (fire and forget, out of band)
```

### 2. Diff Testing (online, 3-way compare)

Send each request to multiple versions and compare the responses. A regression is a difference between old and new that is *not* explained by random noise. This is how you trust a rewrite without writing a single new assertion.

### 3. Capture-and-Replay to Staging (offline)

Record a window of production traffic to a file, then replay it against a staging environment on demand. Reproducible, shareable, and detached from live timing.

### 4. Record-and-Replay Cassettes (offline, deterministic tests)

A test makes a real HTTP call the first time and records the request/response pair into a "cassette." Every subsequent run replays from the cassette instead of hitting the network. Tests become fast, hermetic, and immune to flaky third-party APIs.

### 5. Load Testing / Amplification (offline)

Replay the captured stream faster than it was recorded, or fan one request into many. A captured hour replayed at 5x rate stress-tests the system with realistic request mixes instead of a flat synthetic benchmark.

## Production Tools

### GoReplay

Open-source traffic capture/replay tool written in Go, created by **Leonid Bugaev (buger) in 2013**. It listens on a network interface in the background — it is a network analyzer, not a proxy, so it adds no latency and needs no infrastructure change beyond running the daemon next to the service.

```
sudo gor --input-raw :8000 --output-stdout            # acts like tcpdump
sudo gor --input-raw :8000 --output-http http://staging.env   # replay live
sudo gor --input-raw :8000 --output-file requests.gor          # record to disk
gor --input-file "requests.gor|200%" --output-http http://staging   # replay at 2x
```

- Rate control: `--output-http "http://staging|10%"` mirrors only 10% of traffic; amplify for load testing by replaying captured files at higher percentages.
- Middleware hook lets you rewrite, filter, or scrub requests in any language before they are replayed.
- ~18k+ GitHub stars; adopted by the likes of GitHub and Shopify. Now maintained under the probelabs org.

### Diffy (Twitter)

Open-sourced by **Twitter in 2015** (now `twitter-archive/diffy`). Diffy is a proxy that multicasts every incoming request to **three** instances and compares the results:

```
                         ┌──▶ PRIMARY   (current code, run A) ─┐
   request ──▶ Diffy ────┼──▶ SECONDARY (current code, run B) ─┼──▶ compare
                         └──▶ CANDIDATE (new code)            ─┘
```

- **candidate vs primary** = raw differences (potential regressions).
- **primary vs secondary** = noise, since both run the *same* code (timestamps, UUIDs, ordering, random fields).
- Diffy's novelty is **noise cancellation**: differences seen between the two identical instances are subtracted out, so the reported diffs are real regressions, not incidental variance.
- Premise: *if two implementations return similar responses across a large, diverse set of real requests, treat them as equivalent and the new one as regression-free* — no hand-written assertions required.

### Envoy / Istio Request Mirroring

Built into the **Envoy** proxy (Lyft) and exposed through **Istio** (Google/IBM/Lyft) service-mesh config. A `VirtualService` (or the Gateway API `RequestMirror` filter) shadows traffic to a second service.

- **Fire and forget**: the mirrored response is discarded and never reaches the user; mirroring happens out of band of the critical path.
- The mirrored request's `Host`/`Authority` header is appended with **`-shadow`** so the target can tell it is shadow traffic and avoid duplicate side effects.
- `mirrorPercentage` controls the fraction mirrored (absent = 100%), so you can start shadowing 1% and ramp up.

```yaml
http:
- route:
  - destination: { host: reviews, subset: v1 }
  mirror: { host: reviews, subset: v2 }
  mirrorPercentage: { value: 5.0 }
```

### VCR / WireMock / Polly.js (record into cassettes)

The test-time family: record real HTTP into a file once, replay deterministically forever.

- **VCR** — the original Ruby gem (Myron Marston, ~2010). Records request/response pairs into YAML "cassettes," matches future requests, and plays back the stored response. Spawned a whole ecosystem of ports: **VCR.py** and **Betamax** (Python), **php-vcr** (PHP), **ExVCR** (Elixir), **vcr-clj** (Clojure), and more.
- **WireMock** — Java tool by **Tom Akehurst, started 2011**. Runs as a library or standalone server; can **record by proxying** to a real backend, then serve the captured responses as stubs. Now multi-language with a hosted cloud option.
- **Polly.js** — Netflix's JavaScript record/replay library (open-sourced 2018). Intercepts fetch/XHR in browser or Node, persists interactions (HAR-like), and replays them for fast, deterministic front-end and integration tests.

## Comparison

```
┌──────────────┬──────────────────┬──────────────────────┬──────────────┬─────────────────┐
│ Tool         │ Capture Layer    │ Primary Mode         │ Diffs resp?  │ Origin          │
├──────────────┼──────────────────┼──────────────────────┼──────────────┼─────────────────┤
│ GoReplay     │ Network (pcap)   │ Capture + replay     │ No           │ Bugaev, 2013    │
├──────────────┼──────────────────┼──────────────────────┼──────────────┼─────────────────┤
│ Diffy        │ HTTP proxy       │ Live diff testing    │ Yes (3-way)  │ Twitter, 2015   │
├──────────────┼──────────────────┼──────────────────────┼──────────────┼─────────────────┤
│ Envoy/Istio  │ Service mesh     │ Shadow / mirror      │ No           │ Lyft/Google     │
├──────────────┼──────────────────┼──────────────────────┼──────────────┼─────────────────┤
│ VCR          │ App library      │ Record → cassette    │ No (matches) │ Ruby, ~2010     │
├──────────────┼──────────────────┼──────────────────────┼──────────────┼─────────────────┤
│ WireMock     │ App / server     │ Record → stub        │ No (matches) │ Akehurst, 2011  │
├──────────────┼──────────────────┼──────────────────────┼──────────────┼─────────────────┤
│ Polly.js     │ App (JS)         │ Record → replay      │ No (matches) │ Netflix, 2018   │
└──────────────┴──────────────────┴──────────────────────┴──────────────┴─────────────────┘
```

## Hard Problems

Record/replay looks trivial until it meets production reality. The difficulty is never the capture — it is everything in the transform step.

1. **Side effects on replay** — a replayed `POST /charge` can double-charge a card; a mirrored `send_email` can spam users. Shadow targets must point writes at sandboxed downstreams, or the captured stream must be filtered to read-only verbs. This is the single biggest footgun.
2. **Non-determinism / noise** — timestamps, generated IDs, ordering, and random fields differ on every run, drowning real diffs in false positives. Requires normalization or noise cancellation (Diffy's whole reason for existing).
3. **PII and secrets in the capture** — real traffic contains tokens, passwords, card numbers, and personal data. Stored cassettes and replay logs become a compliance and breach liability unless scrubbed at capture time.
4. **Expired auth / time travel** — replayed requests carry old auth tokens, signed timestamps, and TTLs that have since expired, so the target rejects them. Replay often needs token refresh or signature relaxation.
5. **Cassette rot / state drift** — a recorded response captures the world at record time. When the upstream changes, the cassette silently lies and tests pass against a reality that no longer exists. Cassettes need periodic re-recording.
6. **Idempotency and dedupe** — mirroring at-least-once or replaying overlapping windows can deliver the same request twice; downstreams must dedupe or tolerate duplicates.
7. **Volume and sampling** — full-fidelity capture of high-QPS systems is expensive to store and replay. Most setups sample (1-10%) and accept reduced coverage of the long tail.
8. **Stateful sequences** — replaying requests out of order breaks flows that depend on prior state (login → action → logout); some traffic only makes sense as an ordered session.

## Pros

- **Real-world coverage**: tests against inputs users actually send, including the long tail no engineer would write by hand.
- **No hand-written assertions**: diff testing trusts production behavior as the oracle instead of guessed expected values.
- **Safe rollout**: shadow/mirror exposes new code to real load with zero user-visible risk.
- **Realistic load tests**: amplified real traffic beats flat synthetic benchmarks for finding capacity limits.
- **Deterministic, fast tests**: cassettes remove network flakiness and third-party API dependence from CI.
- **Cheap to start**: packet-sniff capture (GoReplay) needs no code change and adds no latency.
- **Confidence in refactors**: prove a rewrite is equivalent across millions of real requests.

## Cons

- **Side-effect danger**: replaying writes against shared systems can corrupt data or spam users.
- **Privacy/compliance burden**: captured traffic is full of PII and secrets that must be scrubbed and governed.
- **Noise handling is hard**: without normalization, non-determinism makes diffs unusable.
- **Maintenance cost**: cassettes go stale and must be re-recorded; mirroring config drifts.
- **Partial coverage**: sampling and read-only filtering mean replay never fully mirrors production.
- **Auth/time fragility**: expired tokens and stale signatures break replay of secured endpoints.
- **Storage and replay cost**: high-QPS capture is expensive to keep and to re-run.
- **Ordering blind spots**: stateless replay misses bugs that only appear in ordered sessions.

## Use Cases

- **Regression testing during refactors**: prove old and new services behave identically (Diffy).
- **Canary validation**: shadow production traffic to a new build before cutover (Envoy/Istio).
- **Load and stress testing**: replay captured traffic at amplified rates to find capacity ceilings (GoReplay).
- **Cache and connection warming**: replay real traffic to a fresh instance before routing users to it, avoiding cold-cache [[tail-latency]] spikes.
- **Deterministic CI**: record third-party API calls into cassettes so tests run offline and fast (VCR, WireMock, Polly.js).
- **Migration validation**: confirm a database, framework, or language migration preserves responses.
- **Bug reproduction**: capture the exact production request that triggered an incident and replay it locally.
- **Config/infra change safety**: validate a load-balancer, proxy, or kernel change against mirrored live traffic.
- **API contract verification**: ensure a service still honors the contracts its real clients depend on.
- **Synthetic monitoring**: continuously replay a known-good request set against production to detect drift.

## Links

* https://goreplay.org/
* https://github.com/buger/goreplay
* https://github.com/twitter-archive/diffy
* https://blog.twitter.com/engineering/en_us/a/2015/diffy-testing-services-without-writing-tests
* https://istio.io/latest/docs/tasks/traffic-management/mirroring/
* https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/router_filter
* https://github.com/vcr/vcr
* https://wiremock.org/docs/record-playback/
* https://netflix.github.io/pollyjs/
* https://leonsbox.com/projects/goreplay/
