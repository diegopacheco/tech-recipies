# Database Replication

## What is it?

Database replication is the practice of maintaining copies of the same data on multiple database instances (replicas) to achieve high availability, fault tolerance, read scalability, and geographic distribution. When a write occurs on one instance, the change is propagated to other instances so they all converge on the same state. The fundamental trade-off is between consistency (do all replicas see the same data at the same time?) and availability/performance (can we serve reads from any replica without waiting for synchronization?).

## How it works?

### Replication Topologies

```
1. Leader-Follower (Primary-Replica):

   Writes ──► ┌──────────┐ ──replication──► ┌──────────┐
              │  Leader   │                  │ Follower │ ◄── Reads
              │ (primary) │ ──replication──► ├──────────┤
              └──────────┘                  │ Follower │ ◄── Reads
                                            └──────────┘

   - All writes go to leader
   - Leader streams changes to followers
   - Followers serve read queries
   - If leader fails → promote a follower


2. Multi-Leader (Multi-Primary):

   Writes ──► ┌──────────┐ ◄──replication──► ┌──────────┐ ◄── Writes
              │ Leader 1 │                    │ Leader 2 │
              │ (DC-East)│                    │ (DC-West)│
              └──────────┘                    └──────────┘
                   ▲                               ▲
                   │                               │
              Local Reads                    Local Reads

   - Both accept writes
   - Bidirectional replication
   - Conflict resolution needed
   - Used for multi-datacenter setups


3. Leaderless (Peer-to-Peer):

              ┌──────────┐
         ┌───►│  Node 1  │◄───┐
         │    └──────────┘    │
         │         ▲          │
         ▼         │          ▼
   ┌──────────┐    │    ┌──────────┐
   │  Node 2  │◄───┘───►│  Node 3  │
   └──────────┘         └──────────┘

   - Any node accepts reads and writes
   - Quorum-based consistency (R + W > N)
   - No single point of failure
   - Used by Cassandra, DynamoDB, Riak
```

## Synchronous vs Asynchronous Replication

```
Synchronous:

  Client ──► Leader ──► Write to local disk
                  │
                  ├──► Send to Follower 1 ──► ACK ─┐
                  │                                  │
                  └──► Send to Follower 2 ──► ACK ─┤
                                                    │
             Client gets response ◄────────────────┘
             (after ALL replicas confirm)

  + Strong consistency (all replicas have the data)
  - Higher latency (wait for slowest replica)
  - Lower availability (one slow replica blocks writes)


Asynchronous:

  Client ──► Leader ──► Write to local disk ──► Response to client
                  │                               (immediate)
                  │
                  └──► Send to followers (background)
                       Follower 1: applies later
                       Follower 2: applies later

  + Low latency (client does not wait)
  + High availability (replica failure does not block writes)
  - Replication lag (followers may be behind)
  - Data loss risk (leader fails before replicating)


Semi-Synchronous:

  Client ──► Leader ──► Write to local disk
                  │
                  ├──► Send to Follower 1 ──► ACK ─┐
                  │                                  │
                  └──► Send to Follower 2 (async)   │
                                                    │
             Client gets response ◄────────────────┘
             (after at least ONE replica confirms)

  PostgreSQL: synchronous_standby_names = 'FIRST 1 (replica1, replica2)'
  MySQL: semi-sync replication plugin
```

## Replication Methods

```
┌─────────────────────┬──────────────────────────────────────────────┐
│ Method              │ How it works                                  │
├─────────────────────┼──────────────────────────────────────────────┤
│ Statement-based     │ Leader sends SQL statements to followers.    │
│                     │ Simple but non-deterministic functions       │
│                     │ (NOW(), RAND()) cause divergence.            │
├─────────────────────┼──────────────────────────────────────────────┤
│ Write-Ahead Log     │ Leader ships WAL (physical log) to          │
│ (WAL) shipping      │ followers. Byte-level replay. PostgreSQL    │
│                     │ streaming replication. Version-coupled.     │
├─────────────────────┼──────────────────────────────────────────────┤
│ Logical replication │ Leader sends logical changes (row-level     │
│                     │ inserts/updates/deletes). Version-          │
│                     │ independent. PostgreSQL logical decoding,   │
│                     │ MySQL binlog (ROW format).                  │
├─────────────────────┼──────────────────────────────────────────────┤
│ Trigger-based       │ Application-level triggers capture changes  │
│                     │ and write to a changelog table. Flexible    │
│                     │ but slow and fragile.                       │
├─────────────────────┼──────────────────────────────────────────────┤
│ Change Data Capture │ External tool (Debezium) reads the WAL/     │
│ (CDC)               │ binlog and streams changes to Kafka or      │
│                     │ another system. Decoupled from database.    │
└─────────────────────┴──────────────────────────────────────────────┘
```

## Replication Lag and Consistency

```
Replication lag = time between a write on the leader and
                  that write becoming visible on a follower.

Timeline:
  Leader:    write X=1  ─────────────────────────────────►
  Follower:             ──── lag ────  X=1 applied ──────►

Problems caused by lag:

1. Read-your-own-writes (read after write inconsistency):
   User writes a post → reads their profile → post not there yet
   
   Fix: read from leader for user's own data
        or track last write timestamp and wait for follower to catch up

2. Monotonic reads:
   User reads follower A (sees X=1) → reads follower B (sees X=0)
   Time goes backward from user's perspective
   
   Fix: pin user to a specific follower (session affinity)

3. Consistent prefix reads:
   Observer sees answer before the question (causal order violated)
   
   Fix: causal consistency tracking or read from leader
```

## Failover

```
Leader failure → promote a follower:

  1. Detect failure (heartbeat timeout, typically 10-30 seconds)
  2. Choose new leader (most up-to-date follower)
  3. Reconfigure system (clients write to new leader)
  4. Old leader rejoins as follower (when it recovers)

  Timeline:
  ────────────────────────────────────────────────►
       Leader fails    Detected    New leader
           │              │           │
           ▼              ▼           ▼
  [Leader serving]  [downtime]  [New leader serving]


Failover risks:

┌─────────────────────────┬────────────────────────────────────────┐
│ Risk                    │ Description                             │
├─────────────────────────┼────────────────────────────────────────┤
│ Data loss               │ Async follower may be behind leader.   │
│                         │ Unreplicated writes are lost.          │
├─────────────────────────┼────────────────────────────────────────┤
│ Split brain             │ Old leader comes back and both think   │
│                         │ they are leader → conflicting writes.  │
├─────────────────────────┼────────────────────────────────────────┤
│ Stale reads             │ New leader may not have all data from  │
│                         │ old leader → temporary stale reads.    │
├─────────────────────────┼────────────────────────────────────────┤
│ Cascading failures      │ Failover increases load on remaining   │
│                         │ replicas → potential cascade.          │
└─────────────────────────┴────────────────────────────────────────┘
```

## Multi-Leader Conflict Resolution

```
Conflict: two leaders write different values for the same key.

Leader 1: UPDATE users SET name = "Alice" WHERE id = 1
Leader 2: UPDATE users SET name = "Alicia" WHERE id = 1

Who wins?

┌──────────────────────┬──────────────────────────────────────────┐
│ Strategy             │ How it works                              │
├──────────────────────┼──────────────────────────────────────────┤
│ Last Writer Wins     │ Highest timestamp wins. Simple but        │
│ (LWW)                │ data loss (loser's write is discarded).  │
├──────────────────────┼──────────────────────────────────────────┤
│ Custom resolution    │ Application-level merge logic.            │
│                      │ (e.g., merge shopping carts, union sets) │
├──────────────────────┼──────────────────────────────────────────┤
│ CRDTs               │ Conflict-free Replicated Data Types.      │
│                      │ Mathematically guaranteed to converge.   │
├──────────────────────┼──────────────────────────────────────────┤
│ Operational transform│ Transform concurrent operations to        │
│                      │ preserve intent (Google Docs).           │
├──────────────────────┼──────────────────────────────────────────┤
│ Conflict flagging    │ Store both versions, let user resolve.    │
│                      │ CouchDB "conflicting revisions".         │
└──────────────────────┴──────────────────────────────────────────┘
```

## Quorum Replication (Leaderless)

```
N = total replicas
W = write quorum (number of replicas that must ACK a write)
R = read quorum (number of replicas read from)

Rule: W + R > N  →  at least one read will see the latest write

Common configurations:

  N=3, W=2, R=2:  strong consistency, tolerates 1 failure
  N=3, W=3, R=1:  read-optimized, any replica serves reads
  N=3, W=1, R=3:  write-optimized, writes are fast

Write (W=2, N=3):
  Client ──► Node 1 ──► ACK  ─┐
         ──► Node 2 ──► ACK  ─┤── 2 ACKs received → success
         ──► Node 3 ──► FAIL  ┘   (Node 3 will catch up via
                                    anti-entropy / read repair)

Read (R=2, N=3):
  Client ──► Node 1 ──► value=5 (old)  ─┐
         ──► Node 2 ──► value=7 (new)   ─┤── return newest (value=7)
                                          ┘   repair Node 1 (read repair)
```

## Replication in Practice

```
┌──────────────────┬──────────────┬─────────────────────────────────┐
│ Database         │ Topology     │ Details                          │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ PostgreSQL       │ Leader-      │ Streaming replication (WAL).    │
│                  │ Follower     │ Synchronous or async. Logical   │
│                  │              │ replication for selective tables.│
├──────────────────┼──────────────┼─────────────────────────────────┤
│ MySQL            │ Leader-      │ Binlog replication (ROW/STMT).  │
│                  │ Follower     │ GTID for failover. Group        │
│                  │ (+ Group Rep)│ Replication for multi-primary.  │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ MongoDB          │ Leader-      │ Replica sets (1 primary + N     │
│                  │ Follower     │ secondaries). Automatic failover│
│                  │              │ via election. Oplog replication. │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ Cassandra        │ Leaderless   │ Quorum (W + R > N). Tunable    │
│                  │              │ consistency per query. Hinted   │
│                  │              │ handoff for failed nodes.       │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ CockroachDB      │ Multi-leader │ Raft consensus per range.       │
│                  │ (Raft)       │ Strong consistency. Automatic   │
│                  │              │ rebalancing.                    │
├──────────────────┼──────────────┼─────────────────────────────────┤
│ DynamoDB         │ Leaderless   │ Quorum-based. Global Tables     │
│                  │              │ for multi-region (multi-leader).│
├──────────────────┼──────────────┼─────────────────────────────────┤
│ Spanner          │ Multi-leader │ Paxos per split. TrueTime for   │
│                  │ (Paxos)      │ global ordering. Linearizable.  │
└──────────────────┴──────────────┴─────────────────────────────────┘
```

## Comparison of Topologies

```
┌─────────────────┬──────────────┬──────────────┬──────────────────┐
│ Property        │ Leader-      │ Multi-Leader │ Leaderless       │
│                 │ Follower     │              │                  │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Write target    │ Leader only  │ Any leader   │ Any node         │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Consistency     │ Strong (sync)│ Eventual     │ Tunable          │
│                 │ or eventual  │ (conflicts)  │ (quorum)         │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Conflict risk   │ None         │ Yes          │ Yes              │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Write latency   │ Depends on   │ Local (low)  │ Quorum wait      │
│                 │ sync mode    │              │                  │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Read scaling    │ Add replicas │ Local reads  │ Any node reads   │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Failover        │ Promote      │ Other leaders│ No single        │
│                 │ follower     │ keep serving │ point of failure │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Complexity      │ Low          │ High         │ Medium           │
├─────────────────┼──────────────┼──────────────┼──────────────────┤
│ Best for        │ Most OLTP    │ Multi-DC     │ High             │
│                 │ workloads    │              │ availability     │
└─────────────────┴──────────────┴──────────────┴──────────────────┘
```

## Pros

- **High Availability**: if one node fails, others continue serving
- **Read Scalability**: distribute read load across multiple replicas
- **Geographic Distribution**: place replicas near users for lower latency
- **Disaster Recovery**: replicas in different regions survive regional outages
- **Zero-Downtime Upgrades**: upgrade followers one at a time, then failover
- **Backup Offloading**: take backups from a follower instead of the leader
- **Fault Tolerance**: N replicas tolerate N-1 failures (with quorum: N/2 - 1)

## Cons

- **Replication Lag**: async replicas serve stale data
- **Consistency Complexity**: read-your-writes, monotonic reads, and causal consistency require careful design
- **Failover Risk**: promoting a follower may lose unreplicated data
- **Conflict Resolution**: multi-leader and leaderless require conflict handling
- **Operational Cost**: N replicas = N times the storage, compute, and management
- **Network Dependency**: cross-region replication is limited by network latency and bandwidth
- **Split Brain**: network partition can cause two nodes to both believe they are leader
- **Schema Changes**: DDL must be coordinated across all replicas

## Use Cases

- **Read-Heavy Applications**: web applications where reads vastly outnumber writes
- **High Availability**: systems that cannot tolerate any downtime (finance, healthcare)
- **Multi-Region Deployment**: serving users globally with local read replicas
- **Disaster Recovery**: standby replicas in a different datacenter for failover
- **Analytics Offloading**: run heavy analytical queries on a read replica without impacting production
- **Migration**: replicate to a new database engine for zero-downtime migration
- **Compliance**: maintain copies in specific jurisdictions for data residency
- **Real-Time Dashboards**: dedicated read replica for real-time reporting and dashboards
