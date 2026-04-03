# LSM-Trees

## What is it?

A Log-Structured Merge-Tree (LSM-Tree) is a data structure designed for write-heavy workloads. Instead of updating data in place (like a B-Tree), an LSM-Tree buffers writes in an in-memory sorted structure (memtable), then flushes it as an immutable sorted file (SSTable) to disk. Background compaction merges and sorts these files to maintain read performance. The key insight is that sequential writes to disk are orders of magnitude faster than random writes, so converting random writes into sequential writes dramatically improves write throughput.

## Who created it? When?

The LSM-Tree was invented by **Patrick O'Neil**, **Edward Cheng**, **Dieter Gawlick**, and **Elizabeth O'Neil** in a **1996** paper titled *"The Log-Structured Merge-Tree (LSM-Tree)"*. It remained relatively obscure until **Google's Bigtable paper (2006)** described a production LSM-Tree implementation. **LevelDB** (2011, Google) and **RocksDB** (2012, Facebook fork of LevelDB) brought LSM-Trees into widespread use. Today, LSM-Trees power Cassandra, ScyllaDB, CockroachDB, TiKV, FoundationDB, DynamoDB, and many more.

## How it works?

### Write Path

```
1. Write arrives
       │
       ▼
┌──────────────────┐
│  Write-Ahead Log │  Sequential append (durability)
│  (WAL)           │
└──────────┬───────┘
           │
           ▼
┌──────────────────┐
│  Memtable        │  In-memory sorted structure
│  (Red-Black Tree │  (SkipList or Red-Black Tree)
│   or SkipList)   │
│                  │  Fast writes: O(log n)
└──────────┬───────┘
           │
           │  When memtable reaches threshold (e.g., 64MB)
           ▼
┌──────────────────┐
│  Flush to disk   │  Write sorted data as immutable SSTable
│  as SSTable      │  Sequential write (fast)
└──────────┬───────┘
           │
           ▼
┌──────────────────┐
│  Level 0         │  Multiple SSTables, possibly overlapping
│  (unsorted)      │  key ranges
└──────────────────┘
```

### SSTable Structure

```
SSTable (Sorted String Table):

┌───────────────────────────────────────────────┐
│  Data Block 0                                  │
│  ┌─────────┬─────────┬─────────┬─────────┐   │
│  │ key1:v1 │ key2:v2 │ key3:v3 │ key4:v4 │   │
│  └─────────┴─────────┴─────────┴─────────┘   │
├───────────────────────────────────────────────┤
│  Data Block 1                                  │
│  ┌─────────┬─────────┬─────────┬─────────┐   │
│  │ key5:v5 │ key6:v6 │ key7:v7 │ key8:v8 │   │
│  └─────────┴─────────┴─────────┴─────────┘   │
├───────────────────────────────────────────────┤
│  Index Block                                   │
│  ┌──────────────────┬──────────────────┐      │
│  │ key1 → offset 0  │ key5 → offset X  │      │
│  └──────────────────┴──────────────────┘      │
├───────────────────────────────────────────────┤
│  Bloom Filter                                  │
│  (probabilistic: is key maybe in this file?)   │
├───────────────────────────────────────────────┤
│  Footer (metadata, offsets to index/filter)    │
└───────────────────────────────────────────────┘

Properties:
  - Immutable once written (never modified)
  - Keys are sorted within each SSTable
  - Enables efficient range scans
  - Bloom filter avoids unnecessary disk reads
```

### Read Path

```
Query: GET(key)
       │
       ▼
┌──────────────────┐
│  Memtable        │  Check in-memory first (newest data)
│  (active)        │  Found? → return
└──────────┬───────┘
           │ not found
           ▼
┌──────────────────┐
│  Immutable       │  Recently flushed memtable (if any)
│  Memtable        │  Found? → return
└──────────┬───────┘
           │ not found
           ▼
┌──────────────────┐
│  Level 0         │  Check each SSTable (may overlap)
│  SSTables        │  Bloom filter → index → data block
└──────────┬───────┘
           │ not found
           ▼
┌──────────────────┐
│  Level 1         │  Non-overlapping key ranges
│  SSTables        │  Binary search on file boundaries
└──────────┬───────┘
           │ not found
           ▼
┌──────────────────┐
│  Level 2 ... N   │  Each level 10x larger
│  SSTables        │  At most one SSTable per level contains the key
└──────────────────┘

Worst case: read every level (O(levels) disk reads)
Bloom filters eliminate most unnecessary reads (false positive rate ~1%)
```

### Compaction

```
Why compact?
  - Too many SSTables = slow reads (must check each one)
  - Deleted keys (tombstones) waste space
  - Updated keys have multiple versions across files

Level 0:  [SST1] [SST2] [SST3] [SST4]   ← overlapping ranges
              │       │       │
              └───────┴───────┘
                      │
               merge + sort
                      │
                      ▼
Level 1:  [SST_A] [SST_B] [SST_C]        ← non-overlapping ranges
                      │
               merge with Level 2
                      │
                      ▼
Level 2:  [SST_X] [SST_Y] [SST_Z] [SST_W]

Each level is ~10x the size of the previous level.
```

### Compaction Strategies

```
┌──────────────────┬───────────────────────────────────────────────┐
│ Strategy         │ How it works                                   │
├──────────────────┼───────────────────────────────────────────────┤
│ Leveled          │ Each level has non-overlapping key ranges.     │
│ (LevelDB,        │ Compaction merges one L(n) file with          │
│  RocksDB default)│ overlapping L(n+1) files. Best read           │
│                  │ performance. Higher write amplification.       │
├──────────────────┼───────────────────────────────────────────────┤
│ Size-Tiered      │ SSTables of similar size are merged together. │
│ (Cassandra       │ Lower write amplification. Temporary space    │
│  default, HBase) │ spikes during compaction. Worse read perf.    │
├──────────────────┼───────────────────────────────────────────────┤
│ FIFO             │ Oldest SSTables are dropped (TTL-based).      │
│                  │ No merging. For time-series / expiring data.  │
├──────────────────┼───────────────────────────────────────────────┤
│ Universal        │ RocksDB alternative. Merges files based on    │
│ (RocksDB)        │ size ratio. Lower write amp than leveled,     │
│                  │ higher space amp. Good for write-heavy.       │
└──────────────────┴───────────────────────────────────────────────┘
```

### Write Amplification

```
Write amplification = total bytes written to disk / bytes written by application

Example (leveled compaction, 10x size ratio, 7 levels):
  - A key written to memtable → flushed to L0
  - L0 compacted into L1 (rewritten)
  - L1 compacted into L2 (rewritten)
  - ... up to L6
  - Worst case: ~10-30x write amplification

           Application writes 1 MB
                    │
                    ▼
           Disk sees 10-30 MB of actual I/O

Trade-off:
  Low write amp  ←→  High read amp (more files to check)
  High write amp ←→  Low read amp (fewer, well-organized files)
```

## Systems Using LSM-Trees

```
┌──────────────────┬────────────────────────────────────────────────┐
│ System           │ Details                                         │
├──────────────────┼────────────────────────────────────────────────┤
│ LevelDB          │ Google. Leveled compaction. Single-threaded.   │
│                  │ Reference implementation.                      │
├──────────────────┼────────────────────────────────────────────────┤
│ RocksDB          │ Facebook fork of LevelDB. Multi-threaded.     │
│                  │ Column families, transactions, TTL, compression│
├──────────────────┼────────────────────────────────────────────────┤
│ Cassandra        │ Size-tiered (default) or leveled compaction.  │
│                  │ Distributed LSM across cluster.                │
├──────────────────┼────────────────────────────────────────────────┤
│ ScyllaDB         │ C++ rewrite of Cassandra. LSM with compaction │
│                  │ scheduling. Shard-per-core architecture.       │
├──────────────────┼────────────────────────────────────────────────┤
│ CockroachDB      │ Uses Pebble (Go LSM engine, LevelDB-inspired).│
│                  │ Distributed SQL on top of LSM.                 │
├──────────────────┼────────────────────────────────────────────────┤
│ TiKV             │ Uses RocksDB as storage engine. Raft + LSM.   │
├──────────────────┼────────────────────────────────────────────────┤
│ FoundationDB     │ Custom LSM variant. Ordered key-value store.  │
├──────────────────┼────────────────────────────────────────────────┤
│ DynamoDB         │ AWS. Internal LSM-based storage engine.        │
├──────────────────┼────────────────────────────────────────────────┤
│ InfluxDB (TSI)   │ Time-series index uses LSM structure.         │
├──────────────────┼────────────────────────────────────────────────┤
│ BadgerDB         │ Go. Key-value separation (WiscKey design).    │
│                  │ Values stored separately from LSM.             │
└──────────────────┴────────────────────────────────────────────────┘
```

## Pros

- **High Write Throughput**: all writes are sequential (memtable flush + WAL append)
- **Space Efficient**: compaction removes deleted and overwritten keys
- **Crash Recovery**: WAL ensures durability — replay WAL to rebuild memtable after crash
- **Compression**: SSTables compress well because keys are sorted and similar keys are adjacent
- **Range Scans**: sorted SSTables enable efficient range queries
- **Tunable**: compaction strategy, memtable size, bloom filter bits, compression codec are all configurable
- **Proven at Scale**: powers some of the largest databases in production (Cassandra, DynamoDB, CockroachDB)
- **Append-Only**: immutable SSTables simplify concurrency and backup

## Cons

- **Read Amplification**: point lookups may check memtable + multiple SSTable levels
- **Write Amplification**: data is rewritten multiple times during compaction (10-30x typical)
- **Space Amplification**: during compaction, old and new SSTables coexist temporarily (up to 2x space)
- **Compaction Storms**: large compactions consume CPU, I/O, and memory — can spike latency
- **Tombstone Overhead**: deletes create tombstones that persist until compacted away
- **Unpredictable Latency**: compaction can cause latency spikes at p99/p999
- **Tuning Complexity**: choosing compaction strategy, memtable size, and level ratios requires workload knowledge
- **Bloom Filter Memory**: bloom filters must be in memory for fast reads — large datasets need significant RAM

## Use Cases

- **Write-Heavy Workloads**: event logs, time-series, IoT data, analytics ingestion
- **Key-Value Stores**: embedded storage engines (RocksDB, LevelDB, BadgerDB)
- **Distributed Databases**: Cassandra, ScyllaDB, CockroachDB, TiDB — all use LSM as the local engine
- **Message Queues**: Kafka uses log-structured storage (conceptually similar)
- **Search Indexes**: Lucene segments are conceptually similar to LSM SSTables
- **Blockchain**: LevelDB/RocksDB as the state store for Ethereum, Bitcoin
- **Stream Processing**: Flink and Kafka Streams use RocksDB for local state
- **Cache Backends**: persistent cache layers with high write rates
