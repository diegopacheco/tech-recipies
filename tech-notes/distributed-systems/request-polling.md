# Polling (Async Request-Reply)

## What is Polling?

Polling is a pattern for handling long-running work over a request/response API. Instead of blocking a single call until the work finishes, the client makes one request that starts a background job (for example, generating a large PDF, running a report, or encoding a video). The server accepts the job, returns immediately with a job identifier, and does the work asynchronously. The client then repeatedly calls a separate status endpoint using that identifier until the job reports it is done, at which point it fetches the result. This keeps requests short, avoids tying up connections and threads for minutes at a time, and survives client disconnects because the work lives on the server.

## How is Polling Different from a Blocking Request?

| Aspect | Polling (Async Request-Reply) | Blocking Request |
|--------|-------------------------------|------------------|
| Response time | Fast accept, work continues in background | Client waits for the full job |
| Connection lifetime | Short-lived per call | Held open for the entire job |
| Timeouts | Not bound by HTTP/proxy timeouts | Breaks on gateway/load balancer timeouts |
| Client disconnect | Job keeps running server-side | Work is lost or aborted |
| Progress visibility | Status endpoint can report progress | None until completion |
| Server resource usage | Threads freed between polls | One thread/connection pinned per job |
| Complexity | Needs job store and status API | Simple single call |

## Pros and Cons of Polling

### Pros
- Requests stay short, so they survive proxy and gateway timeouts
- Work continues even if the client disconnects or crashes
- Frees server threads and connections between status checks
- Status endpoint can expose progress, ETA, and partial results
- Works over plain HTTP with no special protocol or persistent connection
- Easy to scale: job producers and workers can be separate services

### Cons
- Extra latency between job completion and the next poll
- Wasted requests when polling too frequently for slow jobs
- Requires a durable job store to track state and results
- Client must handle retries, backoff, and terminal failure states
- Result must be stored until the client retrieves it (needs expiry/cleanup)
- More moving parts than a single synchronous call

## Libraries and Tools Used for Polling

### Java
- Spring `@Async` + `DeferredResult` / `CompletableFuture`
- Spring Batch (job status tracking)
- Quartz Scheduler
- Resilience4j (retry with backoff on the client)

### Scala
- Akka actors / Akka Streams for background jobs
- ZIO / Cats Effect fibers with a job registry
- Play Framework async actions
- Quartz (via Java interop)

### Rust
- tokio tasks + a shared job map
- Axum / Actix Web handlers returning a job id
- backon / tokio-retry for client polling backoff

### Go
- Standard `net/http` with goroutines and a job map
- Asynq / Machinery for background jobs
- Temporal Go SDK for durable workflows

### Node.js/TypeScript
- BullMQ / Bee-Queue (Redis-backed jobs)
- Agenda (MongoDB-backed jobs)
- p-retry for client-side polling backoff

## Alternatives

- **Long Polling** - Client request blocks on the server until the job finishes or a timeout fires, then reconnects
- **Webhooks / Callbacks** - Server calls a client-provided URL when the job completes, no polling needed
- **Server-Sent Events (SSE)** - Server pushes status updates over a single long-lived HTTP stream
- **WebSockets** - Full-duplex channel for pushing job progress and results in real time
- **Message Queue** - Client subscribes to a queue/topic and receives a completion message

## How Polling Works Under the Hood

1. Client sends `POST /jobs` to start the long-running work (e.g. generate a PDF)
2. Server persists a job record with status `pending` and a unique job id
3. Server returns `202 Accepted` with the job id and a status URL, then hands the work to a background worker
4. Worker picks up the job, sets status to `running`, and does the work
5. Client polls `GET /jobs/{id}` on an interval to read the current status
6. While the job is `pending` or `running`, the status endpoint returns progress
7. On success the worker stores the result and sets status to `done` with a result URL
8. On failure the worker sets status to `failed` with an error message
9. Client stops polling once it sees a terminal status (`done` or `failed`)
10. On `done`, the client fetches the result; the server expires old jobs and results after a retention window

To avoid hammering the server, clients typically start with a short interval and back off (linear or exponential) as the job runs longer, capped at a maximum interval.

## Polling Code in Rust

```rust
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Duration;

#[derive(Clone)]
enum Status {
    Running,
    Done(String),
    Failed(String),
}

type Jobs = Arc<Mutex<HashMap<u64, Status>>>;

#[tokio::main]
async fn main() {
    let jobs: Jobs = Arc::new(Mutex::new(HashMap::new()));

    let id = 1;
    jobs.lock().unwrap().insert(id, Status::Running);

    let worker_jobs = jobs.clone();
    tokio::spawn(async move {
        tokio::time::sleep(Duration::from_secs(3)).await;
        worker_jobs
            .lock()
            .unwrap()
            .insert(id, Status::Done("report.pdf".to_string()));
    });

    let mut delay = Duration::from_millis(200);
    loop {
        let status = jobs.lock().unwrap().get(&id).cloned();
        match status {
            Some(Status::Done(result)) => {
                println!("Ready: {}", result);
                break;
            }
            Some(Status::Failed(err)) => {
                println!("Failed: {}", err);
                break;
            }
            _ => {
                tokio::time::sleep(delay).await;
                delay = (delay * 2).min(Duration::from_secs(2));
            }
        }
    }
}
```

Dependencies in `Cargo.toml`:
```toml
[dependencies]
tokio = { version = "1", features = ["full"] }
```
