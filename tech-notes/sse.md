# Server Sent Events (SSE)

## What is Server Sent Events?

Server Sent Events (SSE) is a server push technology that allows a server to send real-time updates to a client over a single HTTP connection. The client opens a persistent connection to the server, and the server can push data whenever new information is available. SSE uses the `text/event-stream` MIME type and is built on top of HTTP/1.1 or HTTP/2.

## How is SSE Different from WebSockets?

| Aspect | SSE | WebSocket |
|--------|-----|-----------|
| Direction | Unidirectional (server to client) | Bidirectional |
| Protocol | HTTP | WS/WSS (separate protocol) |
| Reconnection | Automatic built-in | Manual implementation |
| Data format | Text only (UTF-8) | Text and binary |
| Firewall/Proxy | Works through most proxies | May have issues with proxies |
| Browser support | Native EventSource API | Native WebSocket API |
| Complexity | Simple | More complex |

## Pros and Cons of SSE

### Pros
- Simple to implement using standard HTTP
- Automatic reconnection with last-event-id
- Works through firewalls and proxies without issues
- Lightweight protocol overhead
- Native browser support via EventSource API
- No special server infrastructure needed

### Cons
- Unidirectional only (server to client)
- Limited to text data (no binary)
- Connection limit per domain (6 in HTTP/1.1)
- Not suitable for high-frequency bidirectional communication
- Some older browsers lack support

## Libraries Using SSE

### Java
- Spring WebFlux (Flux streaming)
- Jersey SSE
- JAX-RS SSE API
- Micronaut

### Scala
- Akka HTTP
- http4s
- Play Framework
- ZIO HTTP

### Rust
- axum (tokio-stream)
- actix-web
- warp
- rocket

### Go
- Standard library (net/http)
- go-sse
- r3labs/sse
- gin (with streaming)

### Node.js/TypeScript
- Express with response streaming
- Fastify
- Hono
- better-sse

## Alternatives

- **WebSockets** - Full-duplex communication
- **Long Polling** - Client repeatedly polls server
- **HTTP/2 Server Push** - Push resources proactively
- **gRPC Streaming** - Bidirectional streaming over HTTP/2
- **MQTT** - Lightweight pub/sub messaging protocol
- **Socket.IO** - Real-time engine with fallbacks

## How SSE Works Under the Hood

1. Client sends HTTP GET request with `Accept: text/event-stream` header
2. Server responds with `Content-Type: text/event-stream` and keeps connection open
3. Server sends events in a specific format:
   ```
   event: message-type
   data: payload content
   id: unique-id

   ```
4. Each event ends with two newlines (`\n\n`)
5. Client receives events via EventSource API callbacks
6. On disconnect, browser automatically reconnects sending `Last-Event-ID` header
7. Server can send retry directive to control reconnection timing

## SSE Code in Rust

```rust
use axum::{response::sse::{Event, Sse}, routing::get, Router};
use futures::stream::{self, Stream};
use std::{convert::Infallible, time::Duration};
use tokio_stream::StreamExt;

async fn sse_handler() -> Sse<impl Stream<Item = Result<Event, Infallible>>> {
    let stream = stream::repeat_with(|| Event::default().data("hello"))
        .map(Ok)
        .throttle(Duration::from_secs(1));
    Sse::new(stream)
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/events", get(sse_handler));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
```

Dependencies in `Cargo.toml`:
```toml
[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
tokio-stream = "0.1"
futures = "0.3"
```
