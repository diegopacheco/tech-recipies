# FlatBuffers

## What is it?

FlatBuffers is a cross-platform binary serialization library created by Google that enables zero-copy deserialization. Unlike Protobuf, JSON, or Avro which require parsing the entire message into an in-memory object before accessing any field, FlatBuffers stores data in a flat binary buffer that can be accessed directly without deserialization. You read fields directly from the buffer using pointer arithmetic — no intermediate objects are created, no memory is allocated, and no parsing happens.

## Who created it? When?

FlatBuffers was created by **Wouter van Oortmerssen** at **Google** and open-sourced in **2014**. It was designed for game development and performance-critical applications where deserialization overhead is unacceptable. It is used internally at Google for games (Google Play Games), Android, and performance-sensitive systems. Facebook adopted it for their Android app to reduce memory allocations.

## How it works?

### Schema Definition (.fbs)

```
namespace example;

enum UserStatus : byte {
  Active = 0,
  Inactive = 1,
  Banned = 2
}

table Address {
  street: string;
  city: string;
  country: string;
}

table User {
  id: string;
  name: string (required);
  email: string;
  age: int;
  tags: [string];
  address: Address;
  status: UserStatus = Active;
}

table UserList {
  users: [User];
}

root_type UserList;
```

### Zero-Copy Access

```
Traditional serialization (Protobuf, JSON):

Binary Data ──► Parse/Decode ──► In-Memory Object ──► Access Field
                 (allocates memory, copies data)

FlatBuffers:

Binary Data ──► Access Field (direct pointer into buffer)
                (no allocation, no copy, no parsing)

┌──────────────────────────────────────────────────┐
│                  FlatBuffer                       │
│                                                  │
│  ┌────────┐  ┌────────────┐  ┌───────────────┐  │
│  │ vtable │  │ root table │  │ string/vector  │  │
│  │ (field │  │ (offsets to│  │ data           │  │
│  │  map)  │  │  fields)   │  │                │  │
│  └────────┘  └────────────┘  └───────────────┘  │
│       ↑            │                             │
│       │            │  user.name() follows offset  │
│       │            │  directly to string bytes    │
│       │            ▼                             │
│       └──── vtable maps field index to offset    │
└──────────────────────────────────────────────────┘
```

### Building a FlatBuffer

```
Builder builds bottom-up:
1. Create strings and nested objects first (leaves)
2. Create parent tables referencing the children
3. Finish the buffer

The buffer is built back-to-front in memory.
No intermediate objects are created.
```

### Generated Code Access

```cpp
auto users = GetUserList(buffer);
auto user = users->users()->Get(0);

auto name = user->name()->str();
auto age = user->age();
auto status = user->status();

auto addr = user->address();
auto city = addr->city()->str();
```

### Comparison: Access Patterns

```
JSON:
  1. Read entire JSON text
  2. Parse into tree (allocate strings, arrays, objects)
  3. Navigate tree to find field
  4. Read value
  Total: O(n) parse + allocations

Protobuf:
  1. Read binary data
  2. Decode all fields into generated object
  3. Access field on object
  Total: O(n) decode + allocations

FlatBuffers:
  1. Cast pointer to buffer
  2. Follow offset to field
  3. Read value directly from buffer
  Total: O(1) per field access, zero allocations
```

## FlatBuffers vs Protobuf vs Cap'n Proto

```
┌──────────────────┬──────────────┬──────────────┬──────────────┐
│ Feature          │ FlatBuffers  │ Protobuf     │ Cap'n Proto  │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Deserialization  │ Zero-copy    │ Full decode  │ Zero-copy    │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Memory alloc     │ None         │ Per message  │ None         │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Wire size        │ Larger       │ Smaller      │ Larger       │
│                  │ (alignment)  │ (varints)    │ (alignment)  │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Random access    │ O(1)         │ O(n) decode  │ O(1)         │
│                  │              │ then O(1)    │              │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Schema evolution │ Yes          │ Yes          │ Yes          │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Mutable buffers  │ Yes (in-     │ Yes (objects)│ Limited      │
│                  │ place update)│              │              │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Language support │ 15+          │ 10+          │ ~5           │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ RPC support      │ gRPC         │ gRPC         │ Cap'n Proto  │
│                  │              │ (native)     │ RPC          │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Ecosystem        │ Medium       │ Large        │ Small        │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Created by       │ Google       │ Google       │ Kenton Varda │
│                  │              │              │ (ex-Protobuf)│
└──────────────────┴──────────────┴──────────────┴──────────────┘
```

## Schema Evolution

```
┌────────────────────────────┬─────────┬────────────────────────────┐
│ Change                     │ Safe?   │ Notes                      │
├────────────────────────────┼─────────┼────────────────────────────┤
│ Add field to end of table  │ Yes     │ Old readers return default  │
├────────────────────────────┼─────────┼────────────────────────────┤
│ Remove field               │ Yes     │ Mark as deprecated, do not │
│                            │         │ reuse the field position    │
├────────────────────────────┼─────────┼────────────────────────────┤
│ Rename field               │ Yes     │ Binary uses offsets not     │
│                            │         │ names                      │
├────────────────────────────┼─────────┼────────────────────────────┤
│ Change field order         │ No      │ Field position determines   │
│                            │         │ vtable slot                │
├────────────────────────────┼─────────┼────────────────────────────┤
│ Change field type          │ No      │ Binary layout changes      │
├────────────────────────────┼─────────┼────────────────────────────┤
│ Add enum value             │ Yes     │ Old readers see unknown int│
├────────────────────────────┼─────────┼────────────────────────────┤
│ Change table to struct     │ No      │ Different binary layout     │
└────────────────────────────┴─────────┴────────────────────────────┘
```

## Pros

- **Zero-Copy Deserialization**: access fields directly from the buffer without parsing or allocating
- **Zero Allocation**: no heap allocations to read data, critical for GC-sensitive environments
- **O(1) Field Access**: jump directly to any field via vtable offset
- **Cross-Platform**: supports C++, Java, C#, Go, Python, Rust, JavaScript, TypeScript, and more
- **Schema Evolution**: add fields safely, old readers handle unknown fields gracefully
- **Mutable Buffers**: modify fields in place without rebuilding the entire buffer
- **Small Code Footprint**: generated code is simple and lightweight
- **Optional Fields**: fields not present take zero bytes in the buffer

## Cons

- **Larger Wire Size**: alignment padding and vtables make buffers larger than protobuf
- **Build Complexity**: constructing a buffer is more complex than creating a protobuf message (bottom-up construction)
- **Less Readable**: binary format with no JSON-equivalent for debugging (flatc can convert to JSON)
- **Smaller Ecosystem**: fewer tools, libraries, and community support than protobuf
- **Not Ideal for Small Messages**: vtable overhead is proportionally large for small messages
- **No Built-in Compression**: unlike Avro, no built-in compression support
- **Learning Curve**: vtable, offset, and builder concepts are less intuitive than protobuf's simple API
- **Streaming**: not designed for streaming protocols (entire buffer must be available)

## Use Cases

- **Game Development**: serializing game state, network messages, and asset metadata with zero allocation (used by Google Play Games)
- **Mobile Applications**: Facebook uses FlatBuffers on Android to reduce GC pressure and memory usage
- **Real-Time Systems**: low-latency message passing where deserialization overhead is unacceptable
- **Embedded Systems**: constrained devices with limited memory and no dynamic allocation
- **Machine Learning**: serializing model parameters and inference results (TensorFlow Lite uses FlatBuffers for model format)
- **IPC (Inter-Process Communication)**: shared memory buffers read directly by multiple processes
- **High-Frequency Trading**: zero-copy access to market data messages
- **Robotics**: ROS2 can use FlatBuffers for zero-copy message passing between nodes
- **Database Storage**: storing structured records that can be read without full deserialization
