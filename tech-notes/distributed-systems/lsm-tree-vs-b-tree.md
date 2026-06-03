# LSM-Trees vs B-Trees

## What is it?

LSM-trees and B-trees are the two dominant on-disk data structures behind storage engines. They solve the same problem — keep sorted key-value data on durable storage with fast lookups, inserts, and range scans — but make opposite bets. **B-trees update data in place** and are optimized for reads. **LSM-trees never update in place**; they buffer writes in memory and flush them as immutable sorted files, optimizing for writes. Picking between them decides the write throughput, read latency, and space footprint of every database built on top.

Both rely on a [[write-ahead-log]] for durability and both can use [[bloom-filters]] to skip unnecessary disk reads.

## Who created them? When?

- **B-tree**: **Rudolf Bayer and Edward McCreight** at Boeing, **1970** ("Organization and Maintenance of Large Ordered Indices"). The **B+tree** variant (all values in leaves, leaves linked for range scans) became the standard for relational databases.
- **LSM-tree (Log-Structured Merge-tree)**: **Patrick O'Neil, Edward Cheng, Dieter Gawlick, and Elizabeth O'Neil**, **1996** ("The Log-Structured Merge-Tree"). Popularized by Google **Bigtable** (2006) and its open-source descendants LevelDB and RocksDB.

---

## B-tree

A balanced tree of fixed-size pages (typically 4–16 KB). Internal pages hold keys and child pointers; leaf pages hold the actual rows. The tree stays shallow (3–4 levels covers billions of keys), so a lookup is a handful of page reads.

```
                 ┌───────────────┐
                 │   [ 30 | 70 ]  │   root (internal page)
                 └──┬─────┬─────┬─┘
            ≤30    │   30-70 │   >70 │
          ┌────────▼┐  ┌─────▼──┐  ┌─▼───────┐
          │[10|20] │  │[40|55] │  │[80|90]  │   leaf pages
          │ rows…  │  │ rows…  │  │ rows…   │
          └────────┘  └────────┘  └─────────┘
```

### How writes work

To insert or update, find the leaf page and **modify it in place**. If the page overflows, **split** it and push a key up to the parent (which may cascade). Updates overwrite the existing value. Durability comes from a [[write-ahead-log]] (redo log) written before the page itself, so a crash mid-write can be recovered.

### Cost profile

- **Reads**: excellent and predictable — O(log n) page reads, one path root to leaf
- **Writes**: a small update can rewrite a whole page (**write amplification**), and updates scatter across the disk (**random I/O**)
- **Space**: pages are left partially empty (typically ~70% full) to allow in-place inserts (**fragmentation**)

---

## LSM-tree

Writes go to an in-memory sorted structure (the **memtable**, often a skip list) plus an append-only [[write-ahead-log]]. When the memtable fills, it is flushed to disk as an immutable, sorted **SSTable** (Sorted String Table). SSTables accumulate and are periodically merged by **compaction**.

```
WRITE PATH                              READ PATH (newest → oldest)
                                        check memtable
  write ─▶ WAL (durability)             then SSTables, top down,
        └▶ memtable (in RAM, sorted)    using bloom filters to skip
              │ when full, flush                │
              ▼                                 ▼
        ┌──────────────────────────────────────────────┐
  L0    │ SSTable  SSTable  SSTable   (recent flushes)  │
  L1    │ SSTable────SSTable────SSTable  (compacted)    │
  L2    │ SSTable──────SSTable──────SSTable             │
  ...   │ (each level ~10x larger than the one above)   │
        └──────────────────────────────────────────────┘
        compaction merges & drops overwritten/deleted keys
```

### How writes work

Every write is a sequential append to the memtable and WAL — **no random I/O, no in-place update**. Updates and deletes are just newer entries; a delete writes a **tombstone** marker. The latest value wins. Because SSTables are immutable, writes are extremely cheap and sequential.

### Reads and bloom filters

A read may have to check the memtable and several SSTables, newest first, because the key could live in any of them. To avoid touching SSTables that cannot contain the key, each SSTable carries a [[bloom-filters]] — "definitely not here" lets the engine skip the file's disk read entirely. Without bloom filters, LSM reads would be far slower than B-tree reads.

### Compaction

Background **compaction** merges SSTables, discarding overwritten values and tombstones, keeping read amplification and space in check. The compaction strategy is the single biggest tuning lever:

- **Size-tiered (STCS)**: merge SSTables of similar size. Write-friendly, but high space amplification (multiple copies coexist before merge). Cassandra default for write-heavy workloads.
- **Leveled (LCS)**: keep each level non-overlapping and ~10x the previous. Read- and space-friendly, but more write amplification from constant re-merging. RocksDB/LevelDB default.
- **Time-windowed (TWCS)**: bucket by time, ideal for time-series and TTL data where old data is dropped wholesale.

---

## The amplification tradeoff (RUM conjecture)

Every storage engine trades off three amplifications. The **RUM conjecture** (Athanassoulis et al, 2016) states you can optimize at most two of Read, Update (write), and Memory (space) — improving one worsens another.

```
┌───────────────────────┬───────────────┬───────────────┐
│ Amplification         │ B-tree        │ LSM-tree      │
├───────────────────────┼───────────────┼───────────────┤
│ Write amplification   │ Medium-High   │ Low (writes)  │
│  (bytes written /     │ (page rewrite)│ but compaction│
│   bytes of data)      │               │ adds its own  │
├───────────────────────┼───────────────┼───────────────┤
│ Read amplification    │ Low           │ Medium-High   │
│  (extra reads/lookup) │ (one path)    │ (many SSTables│
│                       │               │  + bloom)     │
├───────────────────────┼───────────────┼───────────────┤
│ Space amplification   │ Medium        │ Low-Medium    │
│  (storage / data)     │ (fragmentation│ (compact, but │
│                       │  ~30% slack)  │  STCS bloats) │
└───────────────────────┴───────────────┴───────────────┘
```

A subtle point: LSM has *low* write amplification at the application boundary (cheap sequential writes) but compaction reintroduces write amplification in the background. The win is that it is **sequential** I/O, which both SSDs and HDDs handle far better than the random writes a B-tree generates.

## Comparison

```
┌──────────────────────┬────────────────────────┬───────────────────────────┐
│ Aspect               │ B-tree                 │ LSM-tree                  │
├──────────────────────┼────────────────────────┼───────────────────────────┤
│ Write pattern        │ In-place, random I/O   │ Append-only, sequential   │
│ Write throughput     │ Lower                  │ Higher                    │
│ Point read latency   │ Low, predictable       │ Higher, more variable     │
│ Range scans          │ Excellent (linked      │ Good (merge across        │
│                      │  leaves)               │  SSTables)                │
│ Space efficiency     │ Fragmentation slack    │ Compact (post-compaction) │
│ Read amplification   │ Low                    │ High without bloom filters│
│ Write amplification  │ Page-level             │ Compaction-level          │
│ Tail latency         │ Stable                 │ Compaction can spike it   │
│ Concurrency          │ Page locks / latches   │ Immutable files, simpler  │
│ Best for             │ Read-heavy, OLTP       │ Write-heavy, ingest       │
│ Durability           │ WAL (redo log)         │ WAL (commit log)          │
└──────────────────────┴────────────────────────┴───────────────────────────┘
```

## Middle ground

- **Fractal trees / Bε-trees** (TokuDB, used in Percona): buffer writes inside internal nodes, getting LSM-like write throughput with B-tree-like reads
- **WiscKey / key-value separation**: store large values separately from keys to cut compaction write amplification (RocksDB BlobDB, Badger)
- **Bw-tree** (Microsoft): a lock-free, latch-free B-tree using delta records, used in SQL Server Hekaton and the Sled engine

## Pros

### B-tree
- **Predictable, low read latency**: one root-to-leaf path, stable tail latency
- **Excellent range scans**: linked leaf pages stream sorted data efficiently
- **Mature**: 50+ years of optimization, the backbone of every major RDBMS
- **Strong transactional fit**: in-place updates pair naturally with MVCC and locking

### LSM-tree
- **High write throughput**: sequential appends, no random in-place updates — ideal for ingest
- **SSD-friendly**: sequential writes reduce write amplification and SSD wear
- **Better compression**: immutable, sorted SSTables compress well in large blocks
- **Compact on disk**: compaction reclaims space from overwritten and deleted keys
- **Simple concurrency**: immutable files mean readers never block writers

## Cons

### B-tree
- **Write amplification**: a tiny update can rewrite an entire page
- **Random I/O on writes**: scattered page writes hurt on spinning disks and stress SSDs
- **Fragmentation**: pages run partially full, wasting space
- **Lock contention**: in-place updates need page latches, limiting write concurrency

### LSM-tree
- **Read amplification**: a key may live in many SSTables, requiring bloom filters and caches to stay fast
- **Compaction overhead**: background merging consumes CPU, disk I/O, and bandwidth
- **Tail latency spikes**: a large compaction can stall foreground reads/writes ([[tail-latency]])
- **Tombstone problems**: deletes linger until compaction; many tombstones slow reads (a known Cassandra pitfall)
- **Tuning complexity**: compaction strategy, level sizes, and bloom filter bits must be tuned per workload
- **Space amplification (STCS)**: size-tiered compaction can transiently hold several copies of the data

## Who Uses It?

### B-tree
- **PostgreSQL** (B+tree indexes, heap tables)
- **MySQL / InnoDB** (clustered B+tree)
- **Oracle, SQL Server, DB2** (B+tree)
- **SQLite, Berkeley DB, LMDB** (B+tree)
- **MongoDB WiredTiger** (B-tree option)

### LSM-tree
- **RocksDB / LevelDB** (the reference LSM engines; RocksDB backs countless systems)
- **Apache Cassandra / ScyllaDB** (SSTables + size-tiered/leveled compaction)
- **Google Bigtable, HBase** (the original LSM-at-scale)
- **Apache Kafka** (the log itself is LSM-adjacent; see [[kafka-vs-rabbitmq-comparison]])
- **CockroachDB, TiKV, YugabyteDB** (RocksDB/Pebble under a Raft layer — see [[consensus-raft-paxos]])
- **InfluxDB, Prometheus TSDB** (LSM-style for time-series)

## Use Cases

- **Read-heavy OLTP (B-tree)**: transactional applications with mixed reads/updates and range queries
- **Write-heavy ingest (LSM)**: logging, metrics, event streams, IoT telemetry, clickstreams
- **Time-series (LSM + TWCS)**: high-cardinality metrics with TTL-based expiry
- **Key-value caches and embedded stores (LSM)**: RocksDB embedded inside larger systems
- **Distributed databases (LSM)**: per-shard storage under a consensus/replication layer
- **Analytical scans (B+tree or column stores)**: ordered range reads over large datasets
- **Secondary indexes**: B-trees for selective lookups, LSM for write-amplification-sensitive indexes

## Links

* https://www.cs.umb.edu/~poneil/lsmtree.pdf (original LSM paper)
* https://github.com/facebook/rocksdb/wiki
* https://nivdayan.github.io/rum.pdf (RUM conjecture)
* https://www.bzero.com/ (B-tree history: Bayer & McCreight 1970)
