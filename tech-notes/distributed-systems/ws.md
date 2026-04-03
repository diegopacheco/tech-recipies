# WebSockets

## What is WebSockets?

WebSocket is a communication protocol that provides full-duplex communication channels over a single TCP connection. Unlike HTTP, which is request-response based, WebSocket allows both the client and server to send messages independently at any time. The protocol starts with an HTTP handshake and then upgrades to the WebSocket protocol (WS or WSS for secure connections).

## How is WebSockets Different from SSE?

| Aspect | WebSocket | SSE |
|--------|-----------|-----|
| Direction | Bidirectional | Unidirectional (server to client) |
| Protocol | WS/WSS (separate protocol) | HTTP |
| Reconnection | Manual implementation | Automatic built-in |
| Data format | Text and binary | Text only (UTF-8) |
| Firewall/Proxy | May have issues with proxies | Works through most proxies |
| Browser support | Native WebSocket API | Native EventSource API |
| Complexity | More complex | Simple |
| Use case | Real-time apps, games, chat | News feeds, notifications |

## Pros and Cons of WebSockets

### Pros
- Full-duplex bidirectional communication
- Low latency after connection established
- Supports both text and binary data
- Efficient for high-frequency message exchange
- Native browser support via WebSocket API
- Single persistent connection reduces overhead

### Cons
- More complex to implement than SSE
- Manual reconnection logic required
- May face issues with firewalls and proxies
- Requires WebSocket-aware load balancers
- Connection state must be managed
- Higher server resource usage for many connections

## Libraries Using WebSockets

### Java
- Spring WebSocket
- Java-WebSocket
- Tyrus (Reference Implementation)
- Jetty WebSocket

### Scala
- Akka HTTP
- http4s
- Play Framework
- ZIO HTTP

### Rust
- tokio-tungstenite
- axum (with websocket feature)
- actix-web
- warp

### Go
- gorilla/websocket
- nhooyr.io/websocket
- gobwas/ws
- Standard library (golang.org/x/net/websocket)

### Node.js/TypeScript
- ws
- Socket.IO
- uWebSockets.js
- Fastify WebSocket

## Alternatives

- **SSE** - Server-to-client streaming over HTTP
- **Long Polling** - Client repeatedly polls server
- **gRPC Streaming** - Bidirectional streaming over HTTP/2
- **MQTT** - Lightweight pub/sub messaging protocol
- **WebTransport** - Modern API using HTTP/3 and QUIC
- **Socket.IO** - Real-time engine with WebSocket and fallbacks

## How WebSockets Work Under the Hood

1. Client sends HTTP GET request with `Upgrade: websocket` and `Connection: Upgrade` headers
2. Client includes `Sec-WebSocket-Key` header with random base64 value
3. Server responds with HTTP 101 Switching Protocols
4. Server sends `Sec-WebSocket-Accept` header with computed hash
5. Connection upgrades from HTTP to WebSocket protocol
6. Both sides can now send frames independently
7. Frames contain opcode (text, binary, ping, pong, close) and payload
8. Either side can send ping/pong frames for keepalive
9. Either side can initiate close handshake with close frame
10. Connection terminates after close frame exchange

## WebSocket Code in Rust

```rust
use axum::{
    extract::ws::{Message, WebSocket, WebSocketUpgrade},
    response::Response,
    routing::get,
    Router,
};
use futures::{SinkExt, StreamExt};

async fn ws_handler(ws: WebSocketUpgrade) -> Response {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    while let Some(Ok(msg)) = socket.next().await {
        if let Message::Text(text) = msg {
            let response = format!("Echo: {}", text);
            if socket.send(Message::Text(response.into())).await.is_err() {
                break;
            }
        }
    }
}

#[tokio::main]
async fn main() {
    let app = Router::new().route("/ws", get(ws_handler));
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
```

Dependencies in `Cargo.toml`:
```toml
[dependencies]
axum = { version = "0.7", features = ["ws"] }
tokio = { version = "1", features = ["full"] }
futures = "0.3"
```
