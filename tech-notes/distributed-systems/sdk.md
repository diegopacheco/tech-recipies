# SDK Design

## What is an SDK

An SDK (Software Development Kit) is the library layer a provider ships so developers call a service without hand-writing HTTP, auth, serialization, retries, and pagination. A good SDK turns a raw API into an idiomatic, typed, discoverable surface in the target language. The API is the contract; the SDK is the ergonomics.

The bar set by AWS, Google Cloud, Stripe, and Azure: the SDK should raise developer productivity first. Completeness, extensibility, and performance matter but are secondary to being easy and predictable.

## Core Qualities

| Quality | Meaning |
|---|---|
| Idiomatic | Feels native to the language (async/await in Python, context in Go, Promises in JS) |
| Consistent | Same names, shapes, and behavior across methods and across languages |
| Discoverable | IDE autocomplete guides the user; types encode the contract |
| Predictable | No surprises in retries, errors, or side effects |
| Progressive | Sensible defaults up front, advanced knobs hidden until needed |
| Resilient | Retries, timeouts, and backoff built in, not bolted on |

Azure's priority order for consistency: consistent within the language first, then consistent with the service, then consistent across all languages.

---

## Handwritten vs Generated

| Approach | Pros | Cons |
|---|---|---|
| Handwritten | Best ergonomics, language-native feel | Expensive to maintain across many languages |
| Generated (OpenAPI / protobuf / Smithy) | Cheap to scale to N languages, always in sync with API | Can feel machine-made, leaky abstractions |
| Generated core + handwritten layer | Consistency plus polish | More moving parts |

The pattern most large providers converged on: generate the transport and model layer from a spec, then hand-write or hand-tune the ergonomic surface on top.

- AWS uses **Smithy** (its own IDL) to generate all SDKs.
- Google generates from **protobuf / Google API service configs**.
- Azure generates from **TypeSpec / OpenAPI** and layers hand-written convenience methods.
- Stripe generates model definitions from an internal OpenAPI spec, hand-tunes each language.

---

## Layered Architecture

Almost every mature SDK is built in layers, so the ergonomic surface stays thin and the plumbing is shared.

```
+-----------------------------------------+
|  Service Client (typed methods)         |  createOrder(), listOrders()
+-----------------------------------------+
|  Resource / Model layer (typed objects) |  Order, Customer, PageIterator
+-----------------------------------------+
|  Core: retries, auth, pagination, errors|  shared "core" / "azure-core" / stripe.Client
+-----------------------------------------+
|  Transport (HTTP/2, gRPC, connection    |
|  pool, TLS, timeouts)                    |
+-----------------------------------------+
```

The core layer (Azure calls it `azure-core`, AWS `smithy-client` + middleware, Google `gax`) is shared by every service client so retries, auth, and telemetry behave identically everywhere.

---

## The Client Object

The client is the main entry point. It holds configuration, credentials, and a connection pool. Create it once and reuse it — a new client per request throws away pooled connections and cached credentials.

```python
client = PaymentsClient(
    api_key="sk_live_...",
    timeout=30,
    max_retries=3,
    region="us-east-1",
)

order = client.orders.create(customer_id="cus_123", amount=4200)
```

Rules the big providers follow:

- Minimize the number of top-level clients so there is a clear starting point.
- Group operations under resource namespaces (`client.orders`, `client.customers`).
- The client is thread-safe and meant to be shared; the request objects are not.
- Configuration is immutable after construction.

### Options Pattern

Configuration grows unbounded, so pass an options object or functional options rather than a long positional argument list.

```go
client := payments.NewClient(
    payments.WithAPIKey(key),
    payments.WithTimeout(30*time.Second),
    payments.WithMaxRetries(3),
    payments.WithBaseURL("https://api.acme.com"),
)
```

```typescript
const client = new PaymentsClient({
  apiKey: process.env.ACME_KEY,
  timeout: 30_000,
  maxRetries: 3,
});
```

---

## Authentication

The SDK owns auth so the caller only supplies a credential and never touches header formatting.

| Credential type | Handling |
|---|---|
| API key | Map to the correct header (`Authorization: Bearer ...`) |
| OAuth2 / token | Acquire, cache, and refresh before expiry |
| Signed requests | Compute the signature per request (AWS SigV4) |
| mTLS | Manage the client certificate on the transport |

Principles:

- Give a clear error at construction if credentials are missing or malformed.
- Distinguish `401` (bad credential) from `403` (valid credential, no permission).
- Never log secrets. Redact tokens in debug output.
- Support a credential chain (explicit param, then env var, then config file, then instance metadata) — this is the AWS default credential provider pattern.

---

## Errors

Errors are where SDK quality is felt most. Map transport and protocol failures into a typed hierarchy the caller can branch on.

```python
try:
    client.orders.create(...)
except RateLimitError as e:
    backoff(e.retry_after)
except AuthenticationError:
    refresh_credentials()
except InvalidRequestError as e:
    log.warning("bad field: %s", e.param)
except APIError as e:
    alert(e.request_id)
```

Design rules:

- One base error type, specific subclasses for each failure class.
- Carry the `request_id` on every error so support can trace it.
- Include the HTTP status, the service error code, the human message, and the offending field.
- Never leak raw stack traces from the transport as the public surface.
- Separate the four failure classes: **input** (4xx, do not retry), **auth**, **rate limit** (retry after), **transient server / network** (retry with backoff).

---

## Retries, Backoff, and Jitter

Transient failures (`503`, `429`, connection reset, timeout) are expected in distributed systems. The SDK retries them so the caller does not have to.

- Retry only **idempotent** or idempotency-keyed requests. Never blindly retry a non-idempotent `POST`.
- First retry quickly (one failure is often random noise), then exponential backoff (a pattern of failures is a chronic problem).
- Add **jitter** to spread retries across clients and avoid the thundering herd.
- Cap total retries and total elapsed time.
- Respect the server's `Retry-After` header when present.

```python
def backoff_delay(attempt, base=0.5, cap=60):
    exp = min(cap, base * (2 ** attempt))
    return random.uniform(0, exp)
```

Azure's default: retry 3 times, exponential strategy, initial delay 0.8s, max delay 60s. Stripe retries the first attempt quickly, then exponential backoff with jitter, and refuses to retry past the 24h idempotency-key window.

---

## Idempotency

Retries are only safe if the server can recognize a duplicate. The SDK generates an **idempotency key** (a V4 UUID or high-entropy random string) per logical operation and sends it on every attempt of that operation.

```
POST /v1/orders
Idempotency-Key: 8f14e45f-ceea-467a-9f3b-...
```

- The key stays constant across retries of the same call, so the server returns the original result instead of creating a duplicate.
- The key changes for a genuinely new operation.
- Keys have a server-side expiry (Stripe: 24h), so the SDK must not retry a mutating call after that window.
- This is what makes automatic retry of `POST` safe.

---

## Pagination

List endpoints return partial pages. The SDK hides the page-fetching loop behind an iterator so the caller writes one `for` loop.

| Style | How it works | When |
|---|---|---|
| Offset / limit | `?offset=40&limit=20` | Small, stable datasets |
| Cursor / token | `?page_token=abc` | Large or fast-changing data (preferred) |

Cursor pagination avoids duplicates and skipped rows when data changes mid-scan, which is why it is the production default.

```python
for order in client.orders.list(status="paid"):
    process(order)
```

```go
it := client.Orders.List(ctx, &ListParams{Status: "paid"})
for it.Next() {
    process(it.Order())
}
if err := it.Err(); err != nil { ... }
```

The auto-paginator fetches the next page transparently when the current one is exhausted.

---

## Timeouts and Deadlines

Every request needs a bound, or a hung server hangs the caller forever.

- Set a default per-request timeout and let callers override it.
- Propagate a deadline / cancellation token (`context.Context` in Go, `AbortSignal` in JS, `CancellationToken` in .NET) through the whole call.
- On retry, subtract elapsed time from the overall budget so total time stays bounded.
- Separate connect timeout from read timeout.

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
order, err := client.Orders.Get(ctx, "ord_123")
```

---

## Naming Conventions

Consistent naming is what makes an SDK feel like one product instead of a pile of endpoints.

| Concept | Convention |
|---|---|
| Client | `<Service>Client` — `PaymentsClient`, `StorageClient` |
| Create | `create`, returns the created resource |
| Read one | `get` / `retrieve` |
| Read many | `list`, returns a paginated iterator |
| Update | `update` (partial), `replace` (full) |
| Delete | `delete` |
| Long-running | return an operation/poller (`begin_*`, `*Async`, `Poller`) |

Rules:

- Use the target language's casing (`camelCase` in JS/Java, `snake_case` in Python, `PascalCase` methods in .NET/Go exports).
- Use the same verb for the same semantics everywhere. Do not mix `fetch`, `get`, and `retrieve` for the same action.
- Model names mirror the service's resource names (`Order`, `Customer`, `Invoice`).
- Enums are namespaced and always carry an unspecified/zero value.

---

## Telemetry and Observability

The SDK should be observable in production without the caller wiring it up.

- Send a descriptive `User-Agent` with SDK name, version, language, and OS so the provider can attribute traffic and spot outdated clients.
- Emit spans/metrics through **OpenTelemetry** so requests join the caller's traces.
- Expose hooks/interceptors (middleware) so users can add logging, metrics, or header injection.
- Support a debug/verbose mode that logs requests and responses with secrets redacted.

```
User-Agent: acme-sdk-python/2.4.1 (Python/3.12; Linux)
```

### Middleware / Interceptor Pattern

A pipeline of handlers wraps every request — the same mechanism AWS uses for its middleware stack and gRPC for interceptors.

```
request -> [auth] -> [retry] -> [logging] -> [signing] -> transport -> response
```

---

## Versioning and Stability

- Follow **SemVer** strictly: breaking change bumps major, features bump minor, fixes bump patch.
- Pin the **API version** the SDK targets, separate from the SDK's own version, so server changes don't silently break clients.
- Announce breaking changes with deprecation warnings before removal.
- Keep a changelog and a documented support window.
- Ship types/stubs (`.pyi`, `.d.ts`) so static analysis works.

---

## Testing

- Unit-test the model and error mapping against recorded fixtures.
- Record/replay real HTTP interactions (VCR-style) so tests are deterministic and offline.
- Run contract tests against the live sandbox to catch API drift.
- Test retry, pagination, and timeout logic explicitly — these are the parts users cannot fix themselves.

---

## Packaging and Distribution

- Publish to the language's standard registry (PyPI, npm, Maven Central, crates.io, Go modules, NuGet).
- Keep the dependency footprint minimal; transitive deps are attack surface and version-conflict risk.
- Ship one installable artifact per language, semantically versioned.
- Provide a quickstart that gets to a first successful call in under five minutes.

---

## How the Big Four Do It

| Provider | Spec / Codegen | Core layer | Notable pattern |
|---|---|---|---|
| AWS | Smithy IDL | middleware stack | SigV4 signing, credential provider chain, waiters |
| Google Cloud | protobuf + gRPC | GAX (Google API eXtensions) | auto-retry config per method, streaming |
| Stripe | internal OpenAPI | per-language `Client` | idempotency keys, auto-pagination, expandable objects |
| Azure | TypeSpec / OpenAPI | azure-core | uniform `ClientOptions`, pollers for long-running ops |

Common ground across all four: layered architecture, shared core for retries/auth/telemetry, idiomatic surface per language, built-in retries with backoff, cursor pagination hidden behind iterators, typed errors carrying a request id, and a strong versioning contract.

---

## Checklist for a Proper SDK

- [ ] Single, reusable, thread-safe client with an options object
- [ ] Credential chain, redacted secrets, clear auth errors
- [ ] Typed error hierarchy with request id and error code
- [ ] Automatic retries with exponential backoff and jitter
- [ ] Idempotency keys on mutating requests
- [ ] Auto-pagination behind a native iterator
- [ ] Per-request timeout and deadline propagation
- [ ] Consistent naming across methods and languages
- [ ] OpenTelemetry spans and a descriptive User-Agent
- [ ] Middleware/interceptor hooks
- [ ] SemVer, pinned API version, deprecation policy
- [ ] Record/replay tests plus live sandbox contract tests
- [ ] Published to the standard registry with minimal dependencies

---

## Links

- [Building great SDKs — Pragmatic Engineer (Gergely Orosz & Quentin Pradet)](https://newsletter.pragmaticengineer.com/p/building-great-sdks)
- [Client libraries best practices — Google Cloud](https://cloud.google.com/apis/docs/client-libraries-best-practices)
- [Azure SDK General Design Guidelines](https://azure.github.io/azure-sdk/general_design.html)
- [Azure SDK General Introduction (principles)](https://azure.github.io/azure-sdk/general_introduction.html)
- [Azure SDK Core (retries, telemetry)](https://azure.github.io/azure-sdk/general_azurecore.html)
- [Stripe SDKs overview](https://docs.stripe.com/sdks)
- [Stripe — Designing robust and predictable APIs with idempotency](https://stripe.com/blog/idempotency)
- [Stripe — Idempotent requests API reference](https://docs.stripe.com/api/idempotent_requests)
- [Stripe — Advanced error handling](https://docs.stripe.com/error-low-level)
- [Idempotency and retry logic in stripe-node (DeepWiki)](https://deepwiki.com/stripe/stripe-node/3.5-idempotency-and-retry-logic)
- [AWS Smithy — IDL behind the AWS SDKs](https://smithy.io/)
- [Guiding Principles for Building SDKs — Auth0](https://auth0.com/blog/guiding-principles-for-building-sdks/)
- [Comprehensive Analysis of Design Patterns for REST API SDKs](https://vineeth.io/posts/sdk-development)
- [How to Build SDKs for Your API — Speakeasy](https://www.speakeasy.com/blog/how-to-build-sdks)
- [API Design Patterns: pagination, versioning, error handling — Zuplo](https://zuplo.com/learning-center/api-design-patterns)
