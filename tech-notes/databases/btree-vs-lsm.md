# B-Tree vs LSM-Tree

## What is it?

B-Tree and LSM-Tree are the two dominant storage engine data structures in databases. A B-Tree is an update-in-place structure that maintains sorted data in a balanced tree of fixed-size pages (typically 4-16 KB), optimized for reads and point lookups. An LSM-Tree is an append-only structure that buffers writes in memory and flushes sorted runs to disk, optimized for write throughput. Choosing between them is one of the most consequential storage engine decisions — it determines the performance profile of every read, write, and scan the database will ever serve.

## How they work?

### B-Tree Structure

```
                    ┌─────────────────────┐
                    │   Root Page         │
                    │  [10 | 20 | 30]     │
                    └──┬────┬────┬────┬───┘
                       │    │    │    │
          ┌────────────┘    │    │    └────────────┐
          ▼                 ▼    ▼                 ▼
   ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐
   │ <10        │  │ 10-19      │  │ 20-29      │  │ ≥30        │
   │ [3|5|7]    │  │ [12|15|18] │  │ [22|25|28] │  │ [35|40|50] │
   └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘
         │               │               │               │
         ▼               ▼               ▼               ▼
    Leaf Pages       Leaf Pages      Leaf Pages      Leaf Pages
    (data rows)      (data rows)     (data rows)     (data rows)

Write: find the correct leaf page → update in place
       If page is full → split into two pages, update parent

Read: traverse from root to leaf → O(log n) page reads
      Typically 3-4 levels for millions of rows
```

### LSM-Tree Structure

```
┌──────────────────┐
│  Memtable        │  In-memory sorted buffer
│  (writes here)   │
└────────┬─────────┘
         │ flush when full
         ▼
┌──────────────────┐
│  Level 0         │  Recently flushed SSTables (may overlap)
│  [SST][SST][SST] │
└────────┬─────────┘
         │ compaction
         ▼
┌──────────────────┐
│  Level 1         │  Non-overlapping sorted runs
│  [SST_A][SST_B]  │  ~10x size of L0
└────────┬─────────┘
         │ compaction
         ▼
┌──────────────────┐
│  Level 2         │  ~10x size of L1
│  [SST][SST][SST] │
└────────┬─────────┘
         │
         ▼
       ...more levels...

Write: append to WAL → insert into memtable → done
Read: check memtable → L0 → L1 → L2 → ... (use bloom filters)
```

## Amplification Factors

```
Three types of amplification determine storage engine performance:

┌──────────────────┬────────────────────────────────────────────────┐
│ Amplification    │ Definition                                      │
├──────────────────┼────────────────────────────────────────────────┤
│ Write            │ Ratio of bytes written to disk vs bytes        │
│ amplification    │ written by the application. Higher = more      │
│                  │ disk I/O per write.                             │
├──────────────────┼────────────────────────────────────────────────┤
│ Read             │ Number of disk reads required to serve one     │
│ amplification    │ point query. Higher = slower reads.            │
├──────────────────┼────────────────────────────────────────────────┤
│ Space            │ Ratio of disk space used vs actual data size.  │
│ amplification    │ Higher = more wasted space.                    │
└──────────────────┴────────────────────────────────────────────────┘

You can optimize for at most two of the three. Reducing one
typically increases another.

             Write Amp
               ▲
              / \
             /   \
            /     \
           /       \
          /  pick   \
         /   two     \
        /             \
       ▼───────────────▼
  Read Amp          Space Amp
```

### Amplification Comparison

```
┌──────────────────┬──────────────┬──────────────┐
│ Factor           │ B-Tree       │ LSM-Tree     │
├──────────────────┼──────────────┼──────────────┤
│ Write amp        │ ~2-3x        │ ~10-30x      │
│                  │ (write page  │ (compaction   │
│                  │  + WAL)      │  rewrites)    │
├──────────────────┼──────────────┼──────────────┤
│ Read amp         │ ~1-2 reads   │ ~1-N reads   │
│ (point lookup)   │ (index       │ (check each   │
│                  │  traversal)  │  level, bloom │
│                  │              │  filters help) │
├──────────────────┼──────────────┼──────────────┤
│ Space amp        │ ~1.5-2x      │ ~1.1-1.3x    │
│                  │ (page fill   │ (compaction   │
│                  │  factor ~70%)│  reclaims     │
│                  │              │  space)       │
└──────────────────┴──────────────┴──────────────┘
```

## Head-to-Head Comparison

```
┌─────────────────────┬──────────────────┬──────────────────────┐
│ Property            │ B-Tree           │ LSM-Tree             │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Write pattern       │ Random I/O       │ Sequential I/O       │
│                     │ (update in place)│ (append + compact)   │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Read pattern        │ 1-4 page reads   │ Check memtable +     │
│ (point lookup)      │ (tree traversal) │ multiple levels      │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Range scan          │ Follow leaf page │ Merge-sort across    │
│                     │ linked list      │ levels               │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Write throughput    │ Lower            │ Higher               │
│                     │ (random writes)  │ (sequential writes)  │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Read latency        │ Predictable      │ Variable             │
│                     │ (few page reads) │ (depends on levels)  │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Space efficiency    │ ~60-70% page     │ ~90%+ after          │
│                     │ utilization      │ compaction           │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Write amplification │ Low (2-3x)       │ High (10-30x)        │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Compression         │ Moderate         │ Excellent            │
│                     │ (page-level)     │ (sorted blocks)      │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Concurrency         │ Page-level locks │ Lock-free writes     │
│                     │ or latches       │ (memtable)           │
├─────────────────────┼──────────────────┼──────────────────────┤
│ SSD wear            │ Lower            │ Higher               │
│                     │ (less rewriting) │ (compaction)         │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Latency spikes      │ Rare             │ Compaction storms    │
│ (p99)               │                  │ cause spikes         │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Delete performance  │ Mark + reuse     │ Tombstone until      │
│                     │ page space       │ compaction           │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Maturity            │ ~50 years        │ ~30 years            │
│                     │ (1970, Bayer)    │ (1996, O'Neil)       │
└─────────────────────┴──────────────────┴──────────────────────┘
```

## Databases and Their Storage Engines

```
┌──────────────────┬──────────────┬─────────────────────────────────┐
│ Database         │ Engine       │ Notes                            │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ PostgreSQL       │ B-Tree       │ Heap + B-Tree indexes. MVCC     │
│                  │              │ with visibility map.             │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ MySQL (InnoDB)   │ B-Tree       │ Clustered B+Tree. Primary key   │
│                  │              │ determines physical order.      │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ SQLite           │ B-Tree       │ B-Tree for tables and indexes.  │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ MongoDB (WiredTiger)│ B-Tree   │ Switched from MMAP to B-Tree    │
│                  │              │ in WiredTiger engine (3.2+).    │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ RocksDB          │ LSM-Tree     │ Facebook. Multi-threaded        │
│                  │              │ compaction. Embeddable.         │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ Cassandra        │ LSM-Tree     │ Size-tiered or leveled          │
│                  │              │ compaction. Distributed.        │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ CockroachDB      │ LSM-Tree     │ Pebble engine (Go LSM).         │
│                  │ (Pebble)     │ Distributed SQL.                │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ TiDB             │ LSM-Tree     │ TiKV uses RocksDB.              │
│                  │ (RocksDB)    │ Distributed SQL.                │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ ScyllaDB         │ LSM-Tree     │ C++ rewrite of Cassandra.       │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ FoundationDB     │ LSM-Tree     │ Apple. Ordered KV store.        │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ MySQL (MyRocks)  │ LSM-Tree     │ RocksDB backend for MySQL.      │
│                  │              │ Better compression, write perf. │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ Spanner          │ Both         │ Google. LSM for writes,         │
│                  │              │ B-Tree-like for reads.          │
└──────────────────┴──────────────┴─────────────────────────────────┘
```

## When to Use Which

```
Use B-Tree when:
  ✓ Read-heavy workload (OLTP with many point lookups)
  ✓ Need predictable read latency (low p99)
  ✓ Frequent updates to existing rows
  ✓ Strong transaction semantics (row-level locking)
  ✓ SSD longevity matters (lower write amplification)
  ✓ Small to medium dataset that fits in buffer pool

Use LSM-Tree when:
  ✓ Write-heavy workload (logs, events, time-series, IoT)
  ✓ Sequential scan / range query heavy
  ✓ Need high write throughput
  ✓ Data compresses well (sorted keys = better compression ratios)
  ✓ Disk space is a concern (better space efficiency)
  ✓ Write-once-read-many pattern
  ✓ Append-mostly workloads (events, audit logs)
```

## Hybrid Approaches

```
┌──────────────────┬───────────────────────────────────────────────┐
│ Approach         │ Description                                    │
├──────────────────┼───────────────────────────────────────────────┤
│ BW-Tree          │ Microsoft. Lock-free B-Tree with delta         │
│ (Hekaton)        │ updates (append-like) on B-Tree pages.        │
├──────────────────┼───────────────────────────────────────────────┤
│ Bε-Tree          │ Fractal tree. B-Tree with buffers at each     │
│ (TokuDB)         │ internal node. Batches writes. Bridges the    │
│                  │ gap between B-Tree reads and LSM writes.      │
├──────────────────┼───────────────────────────────────────────────┤
│ WiscKey           │ Key-value separation. LSM for keys only,     │
│                  │ values in a separate log. Reduces write amp.  │
├──────────────────┼───────────────────────────────────────────────┤
│ PebblesDB        │ Fragmented LSM-Tree. Guards reduce write     │
│                  │ amplification while maintaining read perf.    │
├──────────────────┼───────────────────────────────────────────────┤
│ SplinterDB       │ VMware. Branch-and-bound tree that combines   │
│                  │ B-Tree structure with log-structured writes.  │
└──────────────────┴───────────────────────────────────────────────┘
```

## Pros (B-Tree)

- **Predictable Read Latency**: O(log n) with small constant — typically 3-4 page reads
- **Low Write Amplification**: update in place means ~2-3x write amp
- **Mature Ecosystem**: 50+ years of optimization, tooling, and battle-testing
- **Transaction Support**: page-level locking enables strong ACID semantics
- **Efficient Updates**: modifying existing rows does not create duplicates
- **SSD Friendly**: fewer total bytes written extends SSD lifespan

## Pros (LSM-Tree)

- **High Write Throughput**: sequential writes saturate disk bandwidth
- **Better Compression**: sorted data compresses 2-5x better than B-Tree pages
- **Space Efficient**: compaction reclaims space from updates and deletes
- **Scales with Disk**: adding more disk directly increases capacity and throughput
- **Simple Concurrency**: lock-free memtable writes, immutable SSTables
- **Crash Recovery**: WAL + immutable SSTables make recovery straightforward

## Cons (B-Tree)

- **Write Performance**: random I/O on writes limits throughput (especially on HDD)
- **Page Fragmentation**: partially filled pages waste space (~30% typical)
- **Compression**: random page layout compresses poorly compared to sorted SSTable blocks
- **Page Splits**: inserts that cause page splits are expensive and can cascade

## Cons (LSM-Tree)

- **Read Amplification**: worst-case reads touch every level
- **Write Amplification**: compaction rewrites data 10-30x
- **Compaction Spikes**: background compaction competes for I/O and CPU
- **Tombstone Accumulation**: deletes are not free — tombstones persist until compaction
- **Tuning Complexity**: compaction strategy, level sizes, bloom filter config require expertise

## Use Cases

- **B-Tree**: PostgreSQL OLTP, MySQL web applications, MongoDB document queries, financial systems with strict latency SLAs, small-medium datasets with mixed read/write
- **LSM-Tree**: Cassandra event stores, RocksDB-backed stream processing state, time-series ingestion, log aggregation, write-heavy IoT platforms, distributed NewSQL (CockroachDB, TiDB)
