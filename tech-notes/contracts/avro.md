# Apache Avro

## What is it?

Apache Avro is a binary serialization format that embeds the schema with the data. Unlike Protobuf or Thrift which require code generation to read data, Avro can dynamically parse any message as long as the schema is available. Avro schemas are defined in JSON and support schema evolution with well-defined compatibility rules. It is the dominant serialization format in the Kafka ecosystem, where Confluent Schema Registry manages Avro schemas centrally.

## Who created it? When?

Avro was created by **Doug Cutting** (creator of Hadoop and Lucene) in **2009** as part of the Apache Hadoop project. It was designed to address limitations of existing serialization formats in the Hadoop ecosystem — specifically the need for a compact binary format with schema evolution and no code generation requirement. Avro became a top-level Apache project and the default serialization for Kafka through Confluent's Schema Registry.

## How it works?

### Schema Definition (JSON)

```json
{
  "type": "record",
  "name": "User",
  "namespace": "com.example",
  "fields": [
    { "name": "id", "type": "string" },
    { "name": "name", "type": "string" },
    { "name": "email", "type": ["null", "string"], "default": null },
    { "name": "age", "type": "int" },
    { "name": "tags", "type": { "type": "array", "items": "string" } },
    {
      "name": "status",
      "type": {
        "type": "enum",
        "name": "UserStatus",
        "symbols": ["ACTIVE", "INACTIVE", "BANNED"]
      },
      "default": "ACTIVE"
    }
  ]
}
```

### Avro Types

```
Primitive types: null, boolean, int, long, float, double, bytes, string

Complex types:
  record   → named fields (like a struct)
  enum     → named set of symbols
  array    → ordered collection of items
  map      → key-value pairs (keys are strings)
  union    → one of several types (["null", "string"] = nullable string)
  fixed    → fixed number of bytes
```

### Binary Encoding

Avro uses a compact binary encoding where field names are NOT included in the payload. The reader must have the schema to decode.

```
Writer schema defines field order.
Data is written in schema field order with no field tags or names.

User { id: "abc", name: "alice", age: 30 }

Binary: [length-prefixed "abc"][length-prefixed "alice"][zigzag-encoded 30]

No field numbers, no field names, no wire types in the payload.
The schema IS the encoding specification.
```

### Schema in the Container File

```
Avro container file (.avro):

┌─────────────────────┐
│ File Header          │
│  - magic bytes       │
│  - metadata (schema) │  ← schema embedded in file
│  - sync marker       │
├─────────────────────┤
│ Data Block 1         │
│  - count             │
│  - compressed data   │
├─────────────────────┤
│ Data Block 2         │
│  - count             │
│  - compressed data   │
├─────────────────────┤
│ ...                  │
└─────────────────────┘

For Kafka: schema is stored in Schema Registry, messages contain only a schema ID (4 bytes) + binary data.
```

## Schema Evolution

Avro supports evolution through **writer schema** (schema used to write the data) and **reader schema** (schema the consumer expects). The Avro library resolves differences at read time.

### Compatibility Types (Schema Registry)

```
┌──────────────────┬────────────────────────────────────────────────────┐
│ Compatibility    │ Rules                                              │
├──────────────────┼────────────────────────────────────────────────────┤
│ BACKWARD         │ New schema can read old data.                      │
│                  │ Can add fields with defaults, remove fields.       │
│                  │ Consumers upgrade first.                           │
├──────────────────┼────────────────────────────────────────────────────┤
│ FORWARD          │ Old schema can read new data.                      │
│                  │ Can remove fields with defaults, add fields.       │
│                  │ Producers upgrade first.                           │
├──────────────────┼────────────────────────────────────────────────────┤
│ FULL             │ Both backward and forward compatible.              │
│                  │ Can only add/remove fields that have defaults.     │
├──────────────────┼────────────────────────────────────────────────────┤
│ NONE             │ No compatibility checks. Anything goes.            │
└──────────────────┴────────────────────────────────────────────────────┘
```

### Safe Evolution Rules

```
┌────────────────────────────┬─────────┬────────────────────────────────┐
│ Change                     │ Safe?   │ Notes                          │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Add field with default     │ Yes     │ Old data uses default value    │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Remove field with default  │ Yes     │ New readers ignore old field   │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Add field without default  │ Risky   │ Breaks backward compat        │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Rename field               │ Yes     │ Use aliases for migration      │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Change type                │ Risky   │ Some promotions allowed        │
│                            │         │ (int→long, float→double)       │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Add enum symbol            │ Forward │ Old readers fail on unknown    │
├────────────────────────────┼─────────┼────────────────────────────────┤
│ Remove enum symbol         │ Backward│ New readers fail on removed    │
└────────────────────────────┴─────────┴────────────────────────────────┘
```

## Confluent Schema Registry

Centralized schema storage for Kafka. Producers register schemas, consumers fetch them by ID.

```
┌──────────┐   register schema   ┌─────────────────┐
│ Producer │────────────────────►│ Schema Registry  │
│          │◄── schema ID ───────│                  │
└────┬─────┘                     │ GET /schemas/{id}│
     │                           │ compatibility    │
     │ [schema_id + data]        │ checks on write  │
     ▼                           └────────┬────────┘
┌──────────┐                              │
│  Kafka   │                              │
│  Topic   │                              │
└────┬─────┘                              │
     │                           ┌────────▼────────┐
     ▼                           │ Schema Registry  │
┌──────────┐   fetch schema      │                  │
│ Consumer │────────────────────►│ GET /schemas/{id}│
│          │◄── schema ──────────│                  │
└──────────┘                     └─────────────────┘
```

## Comparison

```
┌──────────────────┬──────────────┬──────────────┬──────────────────────┐
│ Feature          │ Avro         │ Protobuf     │ Thrift               │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Schema language  │ JSON         │ .proto IDL   │ .thrift IDL          │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Schema in data   │ Yes (file)   │ No           │ No                   │
│                  │ or registry  │              │                      │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Code gen needed  │ Optional     │ Required     │ Required             │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Dynamic parsing  │ Yes          │ No           │ No                   │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Schema evolution │ Reader/writer│ Field numbers│ Field IDs            │
│                  │ resolution   │              │                      │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ RPC framework    │ Avro IPC     │ gRPC         │ Thrift RPC           │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Kafka ecosystem  │ Dominant     │ Supported    │ Rare                 │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Compression      │ Built-in     │ External     │ External             │
│                  │ (snappy,     │              │                      │
│                  │  deflate)    │              │                      │
└──────────────────┴──────────────┴──────────────┴──────────────────────┘
```

## Pros

- **Schema Embedded**: container files carry their schema, making them self-describing
- **Dynamic Typing**: read any Avro data without code generation using GenericRecord
- **Compact Binary**: no field names or numbers in the payload, very small messages
- **Schema Evolution**: reader/writer schema resolution handles version differences at runtime
- **Schema Registry**: centralized schema management and compatibility enforcement for Kafka
- **Compression**: built-in support for snappy, deflate, zstd compression in container files
- **Hadoop Native**: first-class support in HDFS, Hive, Spark, Flink
- **Union Types**: true union support (["null", "string", "int"]) unlike protobuf's limited oneof

## Cons

- **No Field Numbers**: encoding depends on schema field order, making schema evolution less intuitive than protobuf
- **JSON Schema Syntax**: verbose compared to protobuf's IDL
- **Code Gen Quality**: generated code is less ergonomic than protobuf-generated code in most languages
- **No Native RPC**: Avro IPC exists but is rarely used, gRPC (protobuf) dominates for RPC
- **Parse Speed**: slightly slower than protobuf due to schema resolution at read time
- **Tooling**: fewer developer tools compared to protobuf/gRPC ecosystem
- **Non-Kafka Usage**: outside the Kafka/Hadoop ecosystem, Avro adoption is low
- **Schema Ordering**: adding fields in the wrong position can break binary compatibility

## Use Cases

- **Kafka Events**: the standard serialization format for Kafka with Confluent Schema Registry
- **Data Pipelines**: Hadoop, Spark, Flink, Hive natively read/write Avro
- **Data Lake Storage**: Avro files on S3/HDFS with embedded schemas for long-term storage
- **Event Sourcing**: schema-evolved events stored in event stores with backward compatibility
- **CDC (Change Data Capture)**: Debezium outputs change events in Avro format
- **Schema-First APIs**: defining event contracts between teams with compatibility enforcement
- **Data Warehouse Ingestion**: loading Avro files from streaming pipelines into Snowflake, BigQuery, Redshift
- **Cross-Language Data Exchange**: sharing data between JVM, Python, and Go services via Schema Registry
