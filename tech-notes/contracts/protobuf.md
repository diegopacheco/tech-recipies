# Protocol Buffers (Protobuf)

## What is it?

Protocol Buffers (protobuf) is a language-neutral, platform-neutral binary serialization format created by Google. You define data structures in `.proto` files using an Interface Definition Language (IDL), then use the protobuf compiler (`protoc`) to generate code in your target language (Java, Go, C++, Python, Rust, etc.). Protobuf encodes data into a compact binary format that is smaller and faster to parse than JSON or XML. It is the default serialization format for gRPC.

## Who created it? When?

Protobuf was created internally at **Google** starting in **2001** by **Jeff Dean, Sanjay Ghemawat**, and others to replace an earlier ad-hoc serialization format. It was open-sourced in **July 2008**. **Proto2** was the first public version. **Proto3** was released in **2016**, simplifying the language by removing required fields and default values. Protobuf is used internally by Google for virtually all inter-service communication — it processes billions of messages per second.

## How it works?

### Proto3 Syntax

```protobuf
syntax = "proto3";

package example.v1;

message User {
  string id = 1;
  string name = 2;
  string email = 3;
  int32 age = 4;
  repeated string tags = 5;
  Address address = 6;
  UserStatus status = 7;
}

message Address {
  string street = 1;
  string city = 2;
  string country = 3;
}

enum UserStatus {
  USER_STATUS_UNSPECIFIED = 0;
  USER_STATUS_ACTIVE = 1;
  USER_STATUS_INACTIVE = 2;
  USER_STATUS_BANNED = 3;
}

message GetUserRequest {
  string id = 1;
}

message GetUserResponse {
  User user = 1;
}

service UserService {
  rpc GetUser(GetUserRequest) returns (GetUserResponse);
  rpc ListUsers(ListUsersRequest) returns (stream User);
}
```

### Binary Encoding

```
Field number + wire type packed into a varint tag:

Tag = (field_number << 3) | wire_type

Wire types:
  0 = Varint (int32, int64, bool, enum)
  1 = 64-bit (fixed64, double)
  2 = Length-delimited (string, bytes, message, repeated)
  5 = 32-bit (fixed32, float)

Example: { name: "alice", age: 30 }

Encoded bytes (hex):
  12 05 61 6C 69 63 65    → field 2, wire type 2, length 5, "alice"
  20 1E                    → field 4, wire type 0, varint 30

Total: 9 bytes (vs ~28 bytes in JSON: {"name":"alice","age":30})
```

### Code Generation

```
proto file ──► protoc compiler ──► Generated code
                   │
          ┌────────┼────────┐
          ▼        ▼        ▼
       Java     Go       Python
    User.java  user.pb.go  user_pb2.py
```

## Schema Evolution Rules

```
┌────────────────────────────┬─────────┬────────────────────────────────────┐
│ Change                     │ Safe?   │ Notes                              │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Add new field              │ Yes     │ Old readers ignore unknown fields  │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Remove field               │ Yes*    │ Do not reuse the field number      │
│                            │         │ Use reserved to prevent reuse      │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Rename field               │ Yes     │ Binary format uses numbers not     │
│                            │         │ names, JSON mapping changes        │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Change field number        │ No      │ Breaks all existing data           │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Change field type           │ Risky   │ Some types compatible (int32 ↔     │
│                            │         │ int64), most are not               │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Change repeated ↔ scalar   │ No      │ Wire format differs                │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Add enum value             │ Yes     │ Old readers see unknown enum as 0  │
├────────────────────────────┼─────────┼────────────────────────────────────┤
│ Remove enum value          │ Yes*    │ Reserve the number                 │
└────────────────────────────┴─────────┴────────────────────────────────────┘

reserved 6, 15, 9 to 11;
reserved "old_field_name";
```

## gRPC Integration

Protobuf is the default serialization for gRPC. Service definitions in `.proto` files generate server stubs and client libraries.

```
┌────────┐  HTTP/2 + protobuf  ┌────────┐
│ Client │─────────────────────│ Server │
│ (stub) │◄────────────────────│ (impl) │
└────────┘                     └────────┘

gRPC patterns:
  Unary:              request ──► response
  Server streaming:   request ──► stream of responses
  Client streaming:   stream of requests ──► response
  Bidirectional:      stream ◄──► stream
```

## Comparison with Other Formats

```
┌──────────────┬──────────┬──────────┬───────────┬───────────┬──────────────┐
│ Feature      │ Protobuf │ JSON     │ Avro      │ Thrift    │ FlatBuffers  │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Format       │ Binary   │ Text     │ Binary    │ Binary    │ Binary       │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Schema       │ Required │ Optional │ Required  │ Required  │ Required     │
│              │ (.proto) │ (JSON    │ (.avsc)   │ (.thrift) │ (.fbs)       │
│              │          │ Schema)  │           │           │              │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Size         │ Small    │ Large    │ Small     │ Small     │ Smallest     │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Parse speed  │ Fast     │ Slow     │ Fast      │ Fast      │ Zero-copy    │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Human        │ No       │ Yes      │ No        │ No        │ No           │
│ readable     │          │          │           │           │              │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Schema in    │ No       │ No       │ Yes       │ No        │ No           │
│ payload      │          │          │           │           │              │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ RPC support  │ gRPC     │ REST     │ No        │ Yes       │ gRPC         │
├──────────────┼──────────┼──────────┼───────────┼───────────┼──────────────┤
│ Code gen     │ Yes      │ Optional │ Optional  │ Yes       │ Yes          │
└──────────────┴──────────┴──────────┴───────────┴───────────┴──────────────┘
```

## Pros

- **Compact**: 3-10x smaller than JSON for the same data
- **Fast**: parsing is 20-100x faster than JSON parsing
- **Strongly Typed**: schema enforces types at compile time
- **Backward/Forward Compatible**: schema evolution rules enable safe changes
- **Code Generation**: type-safe client/server code in 10+ languages
- **gRPC Native**: the standard serialization for high-performance RPC
- **Battle Tested**: used by Google for all internal communication since 2001
- **Well-Defined Semantics**: no ambiguity in encoding/decoding

## Cons

- **Not Human Readable**: binary format requires tooling to inspect
- **Schema Required**: cannot consume data without the .proto definition
- **No Self-Describing**: unlike Avro, the schema is not embedded in the payload
- **Limited Map Support**: maps are syntactic sugar over repeated key-value pairs
- **No Union Types**: oneof exists but is not a true union type
- **Tooling Required**: protoc compiler and language plugins must be installed and maintained
- **JSON Mapping Quirks**: proto3 JSON mapping has edge cases (int64 as string, enum as string)
- **Learning Curve**: IDL syntax, field numbering, and evolution rules require training

## Use Cases

- **Microservice Communication**: gRPC + protobuf for high-throughput, low-latency inter-service calls
- **Mobile APIs**: smaller payloads reduce bandwidth and battery usage on mobile networks
- **Data Pipelines**: serializing events in Kafka, Pub/Sub, Kinesis with schema enforcement
- **Configuration Files**: machine-readable config with type safety (Kubernetes uses protobuf internally)
- **Storage Format**: serializing objects to disk or databases (Spanner, Bigtable use protobuf)
- **Game Networking**: compact messages for real-time multiplayer game state synchronization
- **IoT Devices**: minimal payload size for constrained devices and low-bandwidth networks
- **API Contracts**: .proto files as the source of truth for API contracts between teams
