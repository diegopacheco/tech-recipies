# Write-Ahead Log (WAL)

## What is it?

A Write-Ahead Log is an append-only file to which a system records every change **before** applying it to its main data structures. The rule is in the name: write the intent to the log first, fsync it, and only then touch the actual data. If the process crashes mid-operation, recovery replays the log to restore a consistent state. The WAL is the single most important durability primitive in stateful systems — it is how databases survive crashes, how [[lsm-tree-vs-b-tree]] engines persist writes, how [[consensus-raft-paxos]] replicates state, and how [[kafka-vs-rabbitmq-comparison]] stores messages.

The WAL turns a random, multi-step in-place update into a single sequential append, which is both **safer** (atomic and recoverable) and **faster** (sequential I/O beats random I/O on every storage medium).

## Who created it? When?

The write-ahead logging discipline was formalized by **C. Mohan and colleagues at IBM Almaden** in **1992** as **ARIES** ("Algorithms for Recovery and Isolation Exploiting Semantics"), the recovery method underpinning DB2 and, in spirit, nearly every relational database since. The underlying idea — log intent before mutating data — predates ARIES in transaction processing systems of the 1970s–80s (System R, Gray's transaction work), but ARIES is the canonical reference.

## The two cardinal rules

```
1. WAL rule (log-before-data):
   the log record describing a change must reach durable storage
   BEFORE the changed data page is written.

2. Force-log-at-commit (durability):
   all log records of a transaction must be durable (fsync'd)
   BEFORE the commit is acknowledged to the client.
```

Rule 1 guarantees you can always **undo** an uncommitted change that leaked to disk. Rule 2 guarantees you can always **redo** a committed change that had not yet reached the data files. Together they give atomicity and durability across crashes.

## How it works

```
WRITE PATH
  1. client issues a change
  2. append a log record describing it → WAL (sequential append)
  3. fsync the WAL up to this record   (now durable)
  4. apply the change to in-memory pages / memtable / state machine
  5. acknowledge the client
  6. later, in the background, flush dirty data to the main files
  7. periodically CHECKPOINT, then truncate the now-redundant WAL prefix

CRASH RECOVERY
  1. find the last checkpoint
  2. REDO  every committed change logged after it (re-apply)
  3. UNDO  every uncommitted change that reached the data files
  → consistent state restored
```

### Log records and the LSN

Each record carries a monotonically increasing **Log Sequence Number (LSN)**. Data pages store the LSN of the last change applied to them, so recovery knows exactly which log records still need redoing for each page (the "redo from this LSN" test). ARIES logs both **redo** and **undo** information so it can roll forward committed work and roll back the losers.

```
WAL (append-only, grows →)
┌──────┬──────┬──────┬──────┬──────┬──────┬──────────┐
│ LSN1 │ LSN2 │ LSN3 │ CKPT │ LSN4 │ LSN5 │ ...      │
└──────┴──────┴──────┴──────┴──────┴──────┴──────────┘
                       ▲ checkpoint: everything ≤ here is in data files
   recover by replaying from the last checkpoint forward
```

## Durability vs performance: fsync and group commit

The expensive step is the `fsync` that forces the log to physical storage. Every durability decision is a tradeoff against this cost:

- **fsync on every commit**: maximum durability, but bounded by disk flush latency (each commit waits for the platter/flash)
- **Group commit**: batch many transactions' log records into one fsync. Throughput rises sharply while each transaction still waits only one flush. Used by virtually every serious database.
- **Async / delayed flush**: acknowledge before fsync (Postgres `synchronous_commit = off`, MySQL `innodb_flush_log_at_trx_commit = 2`). Big speedup, but a crash can lose the last fraction of a second of "committed" writes.

This is exactly the durability knob behind the latency numbers in [[kafka-vs-rabbitmq-comparison]]: `acks=all` with fsync is durable but slow; relaxing the flush trades durability for latency.

## Checkpointing, compaction, and truncation

A WAL cannot grow forever. A **checkpoint** writes all dirty data to the main files and records that the log up to some LSN is now fully reflected on disk, so that prefix can be discarded (truncated). In log-structured systems the WAL is also **compacted** — for a [[consensus-raft-paxos]] log this means snapshotting the state machine and dropping the covered entries; for a key-value log it means **log compaction** (keep only the latest value per key), which is how Kafka's compacted topics and Bitcask-style stores bound their size.

## Replication and change data capture

Because the WAL is the authoritative, ordered record of every change, it is the natural source for **replication** and **CDC**:

- **Physical log shipping**: stream raw WAL records to replicas that replay them byte-for-byte (Postgres streaming replication, MySQL redo).
- **Logical replication**: decode the WAL into row-level change events (Postgres logical decoding, MySQL binlog row format).
- **Change Data Capture**: tools like Debezium **read the WAL/binlog** to publish a stream of database changes into Kafka — turning a database's private durability log into a public event stream, the backbone of [[kappa-architecture]] and event-driven pipelines.
- **Consensus replication**: in Raft/Paxos the replicated log *is* a WAL agreed upon by a majority before commit — durability and replication unified into one structure (see [[consensus-raft-paxos]]).

## WAL vs alternative durability strategies

```
┌──────────────────┬─────────────────────────────┬──────────────────────────────┐
│ Strategy         │ How it ensures durability   │ Tradeoff                     │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Write-Ahead Log  │ log intent before mutating; │ extra log write, but         │
│                  │ replay on recovery          │ sequential & recoverable     │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Shadow paging    │ write new pages, atomically │ no log, but fragments data   │
│ (copy-on-write)  │ flip a root pointer         │ and complicates concurrency  │
│                  │ (LMDB, ZFS, Btrfs, CouchDB) │                              │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Force-at-commit  │ write all data pages before │ huge random I/O per commit,  │
│ (no WAL)         │ acknowledging               │ very slow                    │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Snapshot only    │ periodic full state dump    │ simple, but loses everything │
│ (Redis RDB)      │                             │ since the last snapshot      │
└──────────────────┴─────────────────────────────┴──────────────────────────────┘
```

WAL and shadow paging are the two mainstream answers. WAL wins for high write throughput and fine-grained changes (most databases); shadow paging wins where simplicity and crash-only design matter (LMDB).

## Pros

- **Crash recovery**: replaying the log restores a consistent state after any failure
- **Atomicity and durability**: delivers the A and D of ACID for transactions
- **Sequential I/O**: one append per change instead of scattered in-place writes — fast on SSD and HDD
- **Foundation for replication**: log shipping and CDC fall out for free from an ordered change log
- **Group commit throughput**: batching fsyncs amortizes the durability cost across many transactions
- **Point-in-time recovery**: archived WAL segments allow restoring to any moment (Postgres PITR)
- **Unifies durability and ordering**: the same structure that survives crashes also defines event order

## Cons

- **Double write**: data is written twice (once to the log, once to the data files), raising write amplification
- **fsync is the bottleneck**: durability is gated by disk flush latency unless batched or relaxed
- **Recovery time**: a long log since the last checkpoint means slow startup after a crash
- **Checkpoint tuning**: too frequent wastes I/O, too rare bloats the log and slows recovery
- **Storage overhead**: WAL segments plus archives consume disk; compaction/truncation must keep pace
- **Durability is a knob, not a guarantee**: async/relaxed flush modes can silently lose recent "committed" writes
- **Write-amplification interplay**: stacking a WAL under an [[lsm-tree-vs-b-tree]] adds another sequential write on top of compaction

## Who Uses It?

- **PostgreSQL**: the WAL (`pg_wal`) drives crash recovery, streaming replication, and PITR
- **MySQL / InnoDB**: redo log (crash recovery) plus binlog (replication and CDC)
- **SQLite**: WAL mode for concurrent readers during writes
- **Apache Kafka**: the partition log is a durable, replicated WAL that *is* the data (see [[kafka-vs-rabbitmq-comparison]])
- **etcd, Consul, CockroachDB, TiKV**: the replicated Raft log is a WAL (see [[consensus-raft-paxos]])
- **Cassandra / ScyllaDB / HBase**: a commit log fronts the memtable in their [[lsm-tree-vs-b-tree]] engines
- **RocksDB / LevelDB**: a WAL protects the memtable before it is flushed to SSTables
- **Redis**: the AOF (Append-Only File) is a WAL-style persistence option alongside RDB snapshots
- **Filesystems**: ext4, XFS, NTFS use journaling — a WAL for filesystem metadata

## Use Cases

- **Database durability**: survive crashes without losing committed transactions
- **Atomic multi-step changes**: ensure a transaction applies fully or not at all
- **Replication**: ship the log to replicas (physical or logical) for high availability
- **Change data capture**: read the WAL/binlog to emit a change stream into pipelines (Debezium → Kafka)
- **LSM storage engines**: protect the in-memory memtable until it is safely flushed
- **Consensus logs**: the agreed, replicated command sequence behind state machines
- **Point-in-time recovery**: archive WAL segments to restore a database to any past moment
- **Event sourcing**: an append-only log of changes as the system's source of truth, mirroring [[kappa-architecture]]

## Links

* https://www.postgresql.org/docs/current/wal-intro.html
* https://web.stanford.edu/class/cs345d-01/rl/aries.pdf (ARIES, Mohan et al, 1992)
* https://www.sqlite.org/wal.html
* https://debezium.io/documentation/ (CDC from the WAL/binlog)
