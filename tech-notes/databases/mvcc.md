# MVCC (Multi-Version Concurrency Control)

## What is it?

Multi-Version Concurrency Control (MVCC) is a concurrency control method where the database keeps multiple versions of each row, allowing readers to see a consistent snapshot of the data without blocking writers, and writers to proceed without blocking readers. Instead of locking a row when someone is reading it, the database serves the reader an older version of the row while the writer creates a new version. Each transaction sees a consistent snapshot of the database as of the time it started, regardless of concurrent modifications. MVCC is the dominant concurrency control mechanism in modern databases.

## Who created it? When?

The concept was described by **David P. Reed** in his **1978** MIT PhD dissertation. The first commercial implementation was in **InterBase** (later open-sourced as **Firebird**) in **1981** by **Jim Starkey**. **PostgreSQL** (originally POSTGRES, 1986, by **Michael Stonebraker** at Berkeley) adopted MVCC as its core concurrency model. **Oracle** implemented MVCC using undo segments starting with **Oracle 7** (1992). **MySQL InnoDB** (2001), **SQL Server** (2005, snapshot isolation), and virtually every modern database now uses some form of MVCC.

## How it works?

### Basic Concept

```
Without MVCC (locking):

  Transaction A (reading)     Transaction B (writing)
       │                            │
       │  SELECT * FROM t           │
       │  WHERE id = 1              │
       │       │                    │
       │   ┌───▼───┐               │
       │   │ LOCK  │◄──────────────│ UPDATE t SET x=2
       │   │ row 1 │               │ WHERE id = 1
       │   │       │               │      │
       │   │ READ  │               │   BLOCKED
       │   │ x = 1 │               │   (waiting for lock)
       │   └───┬───┘               │      │
       │   UNLOCK                  │      │
       │                           │   UNBLOCKED → writes x=2
       │                           │


With MVCC:

  Transaction A (reading)     Transaction B (writing)
       │                            │
       │  SELECT * FROM t           │
       │  WHERE id = 1              │
       │       │                    │  UPDATE t SET x=2
       │   ┌───▼───┐               │  WHERE id = 1
       │   │ READ  │               │       │
       │   │ v1    │◄── sees v1    │   ┌───▼───┐
       │   │ x = 1 │    (snapshot) │   │CREATE │
       │   └───────┘               │   │ v2    │
       │                           │   │ x = 2 │
       │  No blocking.             │   └───────┘
       │  Both proceed             │
       │  concurrently.            │   COMMIT → v2 visible
                                       to new transactions
```

### Version Chain

```
Row with id=1 over time:

  v1 (created by txn 100)    v2 (created by txn 105)    v3 (created by txn 110)
  ┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
  │ id: 1            │       │ id: 1            │       │ id: 1            │
  │ name: "Alice"    │       │ name: "Alicia"   │       │ name: "Ali"      │
  │ created_by: 100  │──────►│ created_by: 105  │──────►│ created_by: 110  │
  │ deleted_by: 105  │       │ deleted_by: 110  │       │ deleted_by: ∞    │
  └──────────────────┘       └──────────────────┘       └──────────────────┘
       (dead)                     (dead)                    (current)

  Transaction 103: sees v1 (name = "Alice")     ← started before txn 105
  Transaction 107: sees v2 (name = "Alicia")    ← started after txn 105
  Transaction 112: sees v3 (name = "Ali")       ← started after txn 110
```

### Snapshot Isolation

```
Each transaction sees data as of its start time (snapshot).

  Timeline:
  ─────────────────────────────────────────────────────►
  t=100      t=105        t=110        t=115

  Txn A starts (t=100)
    │
    │  Txn B starts (t=105)
    │    │  UPDATE row → v2
    │    │  COMMIT (t=107)
    │    │
    │  Txn A reads row → still sees v1
    │  (snapshot is t=100, before B committed)
    │
    │  Txn C starts (t=110)
    │    │  reads row → sees v2
    │    │  (snapshot is t=110, after B committed)
    │
    │  Txn A reads row again → still sees v1
    │  (consistent snapshot throughout transaction)
```

## PostgreSQL MVCC

```
PostgreSQL stores all versions in the main heap (table).

Heap Page:
┌──────────────────────────────────────────────┐
│  Row v1: xmin=100, xmax=105                  │  (dead, but still in heap)
│  Row v2: xmin=105, xmax=110                  │  (dead, but still in heap)
│  Row v3: xmin=110, xmax=∞                    │  (current, live)
└──────────────────────────────────────────────┘

  xmin = transaction ID that created this version
  xmax = transaction ID that deleted/updated this version (∞ = still live)

Visibility check:
  A row is visible to transaction T if:
    xmin is committed AND xmin < T's snapshot
    AND (xmax is not set OR xmax is not committed OR xmax > T's snapshot)

VACUUM:
  Dead rows accumulate → table bloat
  VACUUM reclaims space from dead rows that are no longer visible
  to any active transaction

  autovacuum runs periodically (configurable thresholds)

┌──────────────────┐     VACUUM      ┌──────────────────┐
│ Row v1 (dead)    │  ──────────►    │ (free space)     │
│ Row v2 (dead)    │                 │ (free space)     │
│ Row v3 (live)    │                 │ Row v3 (live)    │
└──────────────────┘                 └──────────────────┘
```

## MySQL InnoDB MVCC

```
InnoDB stores the current version in the clustered index.
Old versions are stored in the undo log.

Clustered Index (B-Tree):
┌──────────────────────────────────┐
│  Row: id=1, name="Ali"          │  ← current version only
│  trx_id=110, roll_ptr ──────────┼──► Undo Log
└──────────────────────────────────┘

Undo Log (rollback segment):
┌──────────────────────────────────┐
│  Undo record: name="Alicia"     │  ← previous version (v2)
│  trx_id=105, roll_ptr ──────────┼──► older undo record
└──────────────────────────────────┘
           │
           ▼
┌──────────────────────────────────┐
│  Undo record: name="Alice"      │  ← oldest version (v1)
│  trx_id=100, roll_ptr = NULL    │
└──────────────────────────────────┘

Read view:
  When a transaction starts, InnoDB creates a "read view"
  that lists all currently active (uncommitted) transactions.
  
  A row version is visible if:
    trx_id < smallest active txn (committed before read view)
    OR trx_id is the current transaction itself

Purge thread:
  Cleans undo records that are no longer needed by any read view.
  (equivalent of PostgreSQL's VACUUM)
```

## Comparison: PostgreSQL vs InnoDB MVCC

```
┌─────────────────────┬───────────────────┬───────────────────────┐
│ Aspect              │ PostgreSQL        │ MySQL InnoDB          │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Old versions stored │ In the heap       │ In undo log           │
│                     │ (main table)      │ (separate area)       │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Table bloat         │ Yes (dead rows    │ No (only current      │
│                     │ stay in heap)     │ version in index)     │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Cleanup mechanism   │ VACUUM            │ Purge thread          │
│                     │ (autovacuum)      │ (automatic)           │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Index updates       │ Every version     │ Only current version  │
│                     │ gets index entry  │ in clustered index    │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Sequential scan     │ Must check        │ Only live rows in     │
│ efficiency          │ visibility of     │ clustered index       │
│                     │ each tuple        │                       │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Long transaction    │ Prevents VACUUM   │ Prevents undo purge   │
│ impact              │ → table bloat     │ → undo log growth     │
├─────────────────────┼───────────────────┼───────────────────────┤
│ Update efficiency   │ Full row copy     │ Write undo record +   │
│                     │ in heap           │ update in place       │
└─────────────────────┴───────────────────┴───────────────────────┘
```

## Isolation Levels and MVCC

```
┌─────────────────────┬──────────────────────────────────────────────┐
│ Isolation Level     │ MVCC Behavior                                 │
├─────────────────────┼──────────────────────────────────────────────┤
│ Read Uncommitted    │ No MVCC needed. Read latest version           │
│                     │ (even uncommitted). Rarely used.              │
├─────────────────────┼──────────────────────────────────────────────┤
│ Read Committed      │ Fresh snapshot for each statement.            │
│                     │ A SELECT in the same transaction may see      │
│                     │ different data if other transactions commit   │
│                     │ between statements.                           │
├─────────────────────┼──────────────────────────────────────────────┤
│ Repeatable Read     │ Snapshot taken at transaction start.          │
│ (Snapshot Isolation)│ All reads see the same consistent snapshot.   │
│                     │ PostgreSQL default for RR. InnoDB default.   │
├─────────────────────┼──────────────────────────────────────────────┤
│ Serializable        │ Snapshot + conflict detection.                │
│                     │ PostgreSQL SSI detects read-write conflicts  │
│                     │ and aborts transactions that would violate   │
│                     │ serializability.                              │
└─────────────────────┴──────────────────────────────────────────────┘
```

## Write Conflicts

```
Write-Write Conflict (both MVCC implementations):

  Txn A: UPDATE t SET x = 10 WHERE id = 1
  Txn B: UPDATE t SET x = 20 WHERE id = 1

  Both try to write the same row:
    First writer wins → creates new version
    Second writer:
      Read Committed  → waits for first to commit, then re-evaluates
      Repeatable Read → aborts with serialization error
      Serializable   → aborts with serialization error

Write Skew (Snapshot Isolation anomaly):

  Txn A reads: account1 = 50, account2 = 50, total = 100
  Txn B reads: account1 = 50, account2 = 50, total = 100
  
  Txn A: withdraw 60 from account1 (50 - 60 = -10, but total still > 0)
  Txn B: withdraw 60 from account2 (50 - 60 = -10, but total still > 0)
  
  Both commit: total = -20 (violated invariant!)
  
  Snapshot isolation does not prevent this.
  Serializable isolation (PostgreSQL SSI) detects and aborts one.
```

## Pros

- **Readers Never Block Writers**: reads use snapshots, writes create new versions
- **Writers Never Block Readers**: concurrent reads see consistent older versions
- **Consistent Snapshots**: each transaction sees a point-in-time view of the database
- **No Read Locks**: eliminates lock contention for read-heavy workloads
- **High Concurrency**: many transactions can operate on the same data simultaneously
- **Time Travel**: some systems expose old versions for historical queries (AS OF TIMESTAMP)
- **Isolation Without Locking**: achieves repeatable read without shared locks on rows

## Cons

- **Storage Overhead**: old versions consume disk space (heap bloat or undo log growth)
- **Vacuum/Purge Overhead**: background cleanup of dead versions consumes CPU and I/O
- **Long Transaction Problem**: a long-running transaction prevents cleanup of all versions it might need
- **Write Conflicts**: concurrent writes to the same row still require conflict detection and possible abort
- **Write Skew**: snapshot isolation allows certain anomalies that serializable isolation prevents
- **Complexity**: implementing MVCC correctly is significantly more complex than simple locking
- **Index Maintenance**: PostgreSQL creates index entries for every version — index bloat
- **Monitoring Difficulty**: bloat, dead tuples, and undo log size require active monitoring

## Use Cases

- **OLTP Workloads**: high-concurrency transactional systems where reads and writes coexist
- **Reporting on Live Data**: long-running analytical queries on a consistent snapshot without blocking writes
- **Web Applications**: many concurrent users reading and writing the same tables
- **Financial Systems**: consistent reads of account balances while transfers are in progress
- **Content Management**: editors can write while readers see the last published version
- **Multi-Tenant SaaS**: high concurrency across many tenants sharing the same tables
- **Temporal Queries**: querying data as of a specific point in time (Spanner, CockroachDB, Oracle Flashback)
- **Replication**: MVCC snapshots are used to implement consistent replication (logical decoding in Postgres)
