# gRPC

## What is gRPC

gRPC is a high-performance RPC framework created by Google. It uses HTTP/2 for transport, Protocol Buffers (protobuf) as the serialization format, and provides code generation for multiple languages.

## gRPC vs REST

| Aspect | gRPC | REST |
|---|---|---|
| Protocol | HTTP/2 | HTTP/1.1 or HTTP/2 |
| Serialization | Protobuf (binary) | JSON (text) |
| Contract | .proto file (strict) | OpenAPI/Swagger (optional) |
| Code generation | Built-in | Third-party tools |
| Streaming | Bidirectional | Limited (SSE, WebSocket) |
| Browser support | Needs grpc-web proxy | Native |
| Payload size | Smaller (binary) | Larger (text) |
| Latency | Lower | Higher |
| Human readability | Not readable | Readable |
| Tooling (curl, Postman) | grpcurl, Evans | curl, Postman, browser |
| Load balancing | L7 aware (per-RPC) | Standard L4/L7 |

### When to Use gRPC

- Service-to-service communication (microservices)
- Low-latency, high-throughput requirements
- Polyglot environments (strong multi-language codegen)
- Streaming workloads (real-time feeds, chat, telemetry)

### When to Use REST

- Public APIs consumed by browsers
- Simple CRUD over HTTP
- Clients that can't run gRPC (IoT, legacy systems)
- When human readability matters more than performance

---

## Protocol Buffers (Protobuf)

Protobuf is an IDL (Interface Definition Language) and binary serialization format.

### Proto File Structure

```protobuf
syntax = "proto3";

package order;

option java_package = "com.myapp.order";
option go_package = "myapp/order";

message Order {
    string id = 1;
    string customer_id = 2;
    repeated Item items = 3;
    OrderStatus status = 4;
    double total = 5;
    google.protobuf.Timestamp created_at = 6;
}

message Item {
    string product_id = 1;
    string name = 2;
    int32 quantity = 3;
    double price = 4;
}

enum OrderStatus {
    ORDER_STATUS_UNSPECIFIED = 0;
    ORDER_STATUS_PENDING = 1;
    ORDER_STATUS_CONFIRMED = 2;
    ORDER_STATUS_SHIPPED = 3;
    ORDER_STATUS_DELIVERED = 4;
}
```

### Scalar Types

| Proto Type | Java | Go | Python | Rust |
|---|---|---|---|---|
| double | double | float64 | float | f64 |
| float | float | float32 | float | f32 |
| int32 | int | int32 | int | i32 |
| int64 | long | int64 | int | i64 |
| bool | boolean | bool | bool | bool |
| string | String | string | str | String |
| bytes | ByteString | []byte | bytes | Vec<u8> |

### Field Numbers

Field numbers are the wire identifiers. Once assigned, they should never change (backward compatibility). Numbers 1-15 use 1 byte on the wire, 16-2047 use 2 bytes. Use 1-15 for frequently set fields.

### Important Rules

- Fields are optional by default in proto3
- `repeated` means zero or more (like a list/array)
- Default values: 0 for numbers, empty string for strings, false for bools
- `oneof` for mutually exclusive fields
- `map<K,V>` for key-value pairs
- Never reuse a field number after removing a field — use `reserved`

```protobuf
message User {
    reserved 3, 8;
    reserved "old_field_name";

    string id = 1;
    string name = 2;

    oneof contact {
        string email = 4;
        string phone = 5;
    }

    map<string, string> metadata = 6;
}
```

---

## Service Definition

```protobuf
service OrderService {
    rpc CreateOrder(CreateOrderRequest) returns (Order);
    rpc GetOrder(GetOrderRequest) returns (Order);
    rpc ListOrders(ListOrdersRequest) returns (ListOrdersResponse);
    rpc WatchOrders(WatchOrdersRequest) returns (stream Order);
    rpc UploadItems(stream Item) returns (UploadItemsResponse);
    rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}

message CreateOrderRequest {
    string customer_id = 1;
    repeated Item items = 2;
}

message GetOrderRequest {
    string id = 1;
}

message ListOrdersRequest {
    string customer_id = 1;
    int32 page_size = 2;
    string page_token = 3;
}

message ListOrdersResponse {
    repeated Order orders = 1;
    string next_page_token = 2;
}
```

---

## Four Communication Patterns

### 1. Unary RPC

Standard request-response. Client sends one message, server responds with one message.

```
Client ---> [Request] ---> Server
Client <--- [Response] <--- Server
```

```protobuf
rpc GetOrder(GetOrderRequest) returns (Order);
```

### 2. Server Streaming

Client sends one request, server streams back multiple responses.

```
Client ---> [Request] ---> Server
Client <--- [Response 1] <--- Server
Client <--- [Response 2] <--- Server
Client <--- [Response N] <--- Server
```

```protobuf
rpc WatchOrders(WatchOrdersRequest) returns (stream Order);
```

### 3. Client Streaming

Client streams multiple messages, server responds once after receiving all.

```
Client ---> [Message 1] ---> Server
Client ---> [Message 2] ---> Server
Client ---> [Message N] ---> Server
Client <--- [Response] <--- Server
```

```protobuf
rpc UploadItems(stream Item) returns (UploadItemsResponse);
```

### 4. Bidirectional Streaming

Both sides send streams independently.

```
Client ---> [Message] ---> Server
Client <--- [Message] <--- Server
Client ---> [Message] ---> Server
Client <--- [Message] <--- Server
```

```protobuf
rpc Chat(stream ChatMessage) returns (stream ChatMessage);
```

---

## Code Generation

### Protoc Compiler

```bash
protoc --java_out=./gen --grpc-java_out=./gen order.proto
protoc --go_out=./gen --go-grpc_out=./gen order.proto
protoc --python_out=./gen --grpc_python_out=./gen order.proto
```

### Go Server

```go
type server struct {
    pb.UnimplementedOrderServiceServer
}

func (s *server) GetOrder(ctx context.Context, req *pb.GetOrderRequest) (*pb.Order, error) {
    order := findOrder(req.Id)
    if order == nil {
        return nil, status.Errorf(codes.NotFound, "order %s not found", req.Id)
    }
    return order, nil
}

func main() {
    lis, _ := net.Listen("tcp", ":50051")
    s := grpc.NewServer()
    pb.RegisterOrderServiceServer(s, &server{})
    s.Serve(lis)
}
```

### Go Client

```go
conn, _ := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
defer conn.Close()

client := pb.NewOrderServiceClient(conn)
order, err := client.GetOrder(context.Background(), &pb.GetOrderRequest{Id: "abc-123"})
```

### Java Server (Spring Boot + grpc-spring-boot-starter)

```java
@GrpcService
public class OrderGrpcService extends OrderServiceGrpc.OrderServiceImplBase {
    @Override
    public void getOrder(GetOrderRequest request, StreamObserver<Order> responseObserver) {
        Order order = findOrder(request.getId());
        responseObserver.onNext(order);
        responseObserver.onCompleted();
    }
}
```

---

## gRPC Status Codes

| Code | Name | When to use |
|---|---|---|
| 0 | OK | Success |
| 1 | CANCELLED | Client cancelled |
| 2 | UNKNOWN | Unknown error |
| 3 | INVALID_ARGUMENT | Bad input |
| 4 | DEADLINE_EXCEEDED | Timeout |
| 5 | NOT_FOUND | Resource doesn't exist |
| 6 | ALREADY_EXISTS | Duplicate |
| 7 | PERMISSION_DENIED | Auth failed |
| 8 | RESOURCE_EXHAUSTED | Rate limited |
| 9 | FAILED_PRECONDITION | State conflict |
| 13 | INTERNAL | Server bug |
| 14 | UNAVAILABLE | Transient failure, retry |
| 16 | UNAUTHENTICATED | No valid credentials |

---

## Metadata (Headers)

gRPC metadata is equivalent to HTTP headers.

```go
md := metadata.Pairs("authorization", "Bearer token123")
ctx := metadata.NewOutgoingContext(context.Background(), md)
order, err := client.GetOrder(ctx, req)
```

Server-side:
```go
func (s *server) GetOrder(ctx context.Context, req *pb.GetOrderRequest) (*pb.Order, error) {
    md, ok := metadata.FromIncomingContext(ctx)
    token := md["authorization"][0]
    ...
}
```

---

## Interceptors (Middleware)

### Unary Interceptor (Go)

```go
func loggingInterceptor(
    ctx context.Context,
    req interface{},
    info *grpc.UnaryServerInfo,
    handler grpc.UnaryHandler,
) (interface{}, error) {
    log.Printf("method: %s", info.FullMethod)
    start := time.Now()
    resp, err := handler(ctx, req)
    log.Printf("duration: %s, error: %v", time.Since(start), err)
    return resp, err
}

s := grpc.NewServer(grpc.UnaryInterceptor(loggingInterceptor))
```

### Chaining Multiple Interceptors

```go
s := grpc.NewServer(
    grpc.ChainUnaryInterceptor(
        loggingInterceptor,
        authInterceptor,
        recoveryInterceptor,
    ),
)
```

---

## Deadlines and Timeouts

Always set deadlines. Without them, a failing RPC can hang forever.

```go
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
order, err := client.GetOrder(ctx, req)
if status.Code(err) == codes.DeadlineExceeded {
    log.Println("request timed out")
}
```

Deadlines propagate across services. If Service A calls Service B with a 5s deadline and 2s are already spent, Service B gets 3s remaining.

---

## Load Balancing

### Client-Side (built-in)

gRPC maintains persistent HTTP/2 connections. Traditional L4 load balancers see one connection and send all traffic to one backend. Solutions:

- **Round-robin** (built-in): distributes RPCs across known backends
- **xDS / Envoy**: L7-aware proxy that balances per-RPC
- **Lookaside LB**: external service provides backend list (e.g., gRPC-LB protocol)

```go
conn, _ := grpc.Dial(
    "dns:///my-service:50051",
    grpc.WithDefaultServiceConfig(`{"loadBalancingPolicy":"round_robin"}`),
)
```

---

## Health Checking

Standard health check protocol defined by gRPC.

```protobuf
service Health {
    rpc Check(HealthCheckRequest) returns (HealthCheckResponse);
    rpc Watch(HealthCheckRequest) returns (stream HealthCheckResponse);
}
```

```go
import "google.golang.org/grpc/health"
import healthpb "google.golang.org/grpc/health/grpc_health_v1"

healthServer := health.NewServer()
healthpb.RegisterHealthServer(s, healthServer)
healthServer.SetServingStatus("order.OrderService", healthpb.HealthCheckResponse_SERVING)
```

---

## Reflection

Enables tools like grpcurl to discover services at runtime without .proto files.

```go
import "google.golang.org/grpc/reflection"

s := grpc.NewServer()
reflection.Register(s)
```

```bash
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50051 describe order.OrderService
grpcurl -plaintext -d '{"id":"abc"}' localhost:50051 order.OrderService/GetOrder
```

---

## gRPC-Web

Browsers can't use HTTP/2 trailers directly. gRPC-Web uses a proxy (Envoy or grpc-web) to bridge the gap.

```
Browser --> [gRPC-Web] --> Envoy Proxy --> [gRPC] --> Backend
```

Envoy config:
```yaml
filters:
  - name: envoy.filters.http.grpc_web
  - name: envoy.filters.http.cors
  - name: envoy.filters.http.router
```

---

## Proto Best Practices

- Use package names to avoid collisions
- Never reuse field numbers — use `reserved`
- Prefix enum values with the enum name (`ORDER_STATUS_PENDING`)
- Always have an `UNSPECIFIED = 0` enum value
- Use `google.protobuf.Timestamp` for time, not int64
- Use `google.protobuf.Duration` for durations
- Use wrapper types (`google.protobuf.StringValue`) when you need to distinguish zero-value from unset
- Keep messages small and focused
- Version via package name (`order.v1`, `order.v2`) not field additions
