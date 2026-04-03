# MessagePack

## What is it?

MessagePack is a binary serialization format that is like JSON but smaller and faster. It encodes data into a compact binary representation while preserving the same data model as JSON — maps, arrays, strings, numbers, booleans, and null. MessagePack is schemaless — you do not need a schema definition to encode or decode data. Any valid JSON document can be converted to MessagePack and back without loss.

## Who created it? When?

MessagePack was created by **Sadayuki Furuhashi** in **2008** in Japan. It was designed as a more efficient alternative to JSON for RPC and data interchange. The format gained adoption through the **msgpack-rpc** library and was later adopted by Redis (RESP3 alternatives), Fluentd (log transport), and numerous game engines and embedded systems. Libraries exist for 50+ programming languages.

## How it works?

### Encoding Format

MessagePack uses a type-prefix byte to indicate the type and length of each value.

```
JSON:                              MessagePack (hex):
{"compact": true, "schema": 0}    82 A7 compact C3 A6 schema 00

Breakdown:
  82         → fixmap with 2 entries
  A7         → fixstr with 7 bytes
  "compact"  → 63 6F 6D 70 61 63 74
  C3         → true
  A6         → fixstr with 6 bytes
  "schema"   → 73 63 68 65 6D 61
  00         → positive fixint 0

JSON:   27 bytes (with no whitespace)
MsgPack: 18 bytes (33% smaller)
```

### Type System

```
┌──────────────────┬─────────────┬────────────────────────────────┐
│ Type             │ Format byte │ Range / Notes                  │
├──────────────────┼─────────────┼────────────────────────────────┤
│ positive fixint  │ 0x00 - 0x7f │ 0 to 127                      │
├──────────────────┼─────────────┼────────────────────────────────┤
│ negative fixint  │ 0xe0 - 0xff │ -32 to -1                     │
├──────────────────┼─────────────┼────────────────────────────────┤
│ uint 8/16/32/64  │ 0xcc - 0xcf │ unsigned integers              │
├──────────────────┼─────────────┼────────────────────────────────┤
│ int 8/16/32/64   │ 0xd0 - 0xd3 │ signed integers                │
├──────────────────┼─────────────┼────────────────────────────────┤
│ float 32/64      │ 0xca / 0xcb │ IEEE 754                       │
├──────────────────┼─────────────┼────────────────────────────────┤
│ fixstr           │ 0xa0 - 0xbf │ string up to 31 bytes          │
├──────────────────┼─────────────┼────────────────────────────────┤
│ str 8/16/32      │ 0xd9 - 0xdb │ longer strings                 │
├──────────────────┼─────────────┼────────────────────────────────┤
│ bin 8/16/32      │ 0xc4 - 0xc6 │ raw bytes                      │
├──────────────────┼─────────────┼────────────────────────────────┤
│ fixarray         │ 0x90 - 0x9f │ array up to 15 elements        │
├──────────────────┼─────────────┼────────────────────────────────┤
│ array 16/32      │ 0xdc / 0xdd │ larger arrays                  │
├──────────────────┼─────────────┼────────────────────────────────┤
│ fixmap           │ 0x80 - 0x8f │ map up to 15 entries           │
├──────────────────┼─────────────┼────────────────────────────────┤
│ map 16/32        │ 0xde / 0xdf │ larger maps                    │
├──────────────────┼─────────────┼────────────────────────────────┤
│ nil              │ 0xc0        │ null                           │
├──────────────────┼─────────────┼────────────────────────────────┤
│ true / false     │ 0xc3 / 0xc2 │ boolean                        │
├──────────────────┼─────────────┼────────────────────────────────┤
│ ext              │ 0xc7 - 0xc9 │ application-defined types      │
│                  │ 0xd4 - 0xd8 │ (timestamp, custom)            │
└──────────────────┴─────────────┴────────────────────────────────┘
```

### Size Comparison

```
┌────────────────────────────┬──────┬──────────┬──────────┐
│ Data                       │ JSON │ MsgPack  │ Savings  │
├────────────────────────────┼──────┼──────────┼──────────┤
│ {"a":1}                    │ 7B   │ 3B       │ 57%      │
├────────────────────────────┼──────┼──────────┼──────────┤
│ {"name":"alice","age":30}  │ 25B  │ 16B      │ 36%      │
├────────────────────────────┼──────┼──────────┼──────────┤
│ [1,2,3,4,5]               │ 11B  │ 6B       │ 45%      │
├────────────────────────────┼──────┼──────────┼──────────┤
│ true                       │ 4B   │ 1B       │ 75%      │
├────────────────────────────┼──────┼──────────┼──────────┤
│ 42                         │ 2B   │ 1B       │ 50%      │
├────────────────────────────┼──────┼──────────┼──────────┤
│ Large nested object        │ 1KB  │ ~600B    │ ~40%     │
└────────────────────────────┴──────┴──────────┴──────────┘
```

## Comparison with Similar Formats

```
┌──────────────────┬───────────┬───────────┬───────────┬───────────┐
│ Feature          │ MsgPack   │ CBOR      │ BSON      │ JSON      │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Format           │ Binary    │ Binary    │ Binary    │ Text      │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Schema required  │ No        │ No        │ No        │ No        │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Size vs JSON     │ 30-50%    │ 30-50%    │ Sometimes │ Baseline  │
│                  │ smaller   │ smaller   │ larger    │           │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Parse speed      │ Fast      │ Fast      │ Medium    │ Slow      │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Human readable   │ No        │ No        │ No        │ Yes       │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Binary data      │ Yes (bin) │ Yes       │ Yes       │ Base64    │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Standardized     │ Spec      │ RFC 8949  │ BSON spec │ RFC 8259  │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Extension types  │ Yes (ext) │ Yes (tags)│ Limited   │ No        │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Notable users    │ Redis,    │ COSE,     │ MongoDB   │ Everything│
│                  │ Fluentd   │ WebAuthn  │           │           │
├──────────────────┼───────────┼───────────┼───────────┼───────────┤
│ Language support │ 50+       │ 30+       │ ~15       │ Universal │
└──────────────────┴───────────┴───────────┴───────────┴───────────┘
```

## Pros

- **Compact**: 30-50% smaller than JSON for equivalent data
- **Fast**: 2-10x faster to encode/decode than JSON
- **Schemaless**: no schema definition needed, same data model as JSON
- **Drop-In Replacement**: any JSON document converts to MessagePack and back losslessly
- **Binary Data**: native binary type (no Base64 encoding needed)
- **Extension Types**: custom types (timestamps, UUIDs) via the ext format
- **Cross-Language**: libraries in 50+ languages with consistent behavior
- **Simple Spec**: entire specification fits on a single page
- **Streaming**: self-delimiting format supports streaming decode

## Cons

- **Not Human Readable**: cannot inspect data without tooling
- **No Schema Enforcement**: no type safety or validation without external schema
- **Key Overhead**: map keys are stored as strings in every message (unlike Protobuf field numbers)
- **No Schema Evolution**: no built-in compatibility rules (add/remove fields freely but no enforcement)
- **Less Compact than Protobuf**: Protobuf uses field numbers (1-2 bytes) instead of string keys
- **No Built-in RPC**: no equivalent of gRPC, need separate RPC framework
- **Integer Ambiguity**: languages differ in how they handle int vs uint, 32-bit vs 64-bit
- **Limited Tooling**: fewer debugging and validation tools compared to JSON or Protobuf

## Use Cases

- **Log Transport**: Fluentd uses MessagePack as its internal data format for log forwarding
- **Redis Serialization**: Redis clients use MessagePack for storing complex values
- **RPC Frameworks**: msgpack-rpc for lightweight inter-process communication
- **Game Networking**: compact messages for real-time multiplayer state synchronization
- **IoT/Embedded**: small binary format for constrained devices with limited bandwidth
- **Caching**: storing serialized objects in Redis, Memcached with smaller memory footprint than JSON
- **WebSocket Messages**: binary WebSocket frames with MessagePack for real-time web apps
- **Configuration**: binary config files that are smaller and faster to parse than JSON/YAML
- **Data Pipelines**: compact encoding for high-throughput event streams
- **Mobile APIs**: reducing payload size and parse time for bandwidth-constrained mobile clients
