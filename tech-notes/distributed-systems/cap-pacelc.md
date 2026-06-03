# CAP, PACELC, and Consistency Models

## What is it?

CAP and PACELC are the framing theorems that explain the fundamental tradeoffs every distributed data system must make. They tell you what you are allowed to want. **Consistency models** are the menu of concrete guarantees a system can actually offer, ranging from "every read sees the latest write everywhere" down to "reads eventually catch up." Together they are the vocabulary for reasoning about replicated state: [[consensus-raft-paxos]] systems sit at the strong-consistency end, while [[consistent-hashing]]-based Dynamo systems sit at the available end.

## CAP Theorem

### Who created it? When?

**Eric Brewer** stated the CAP conjecture in his **2000** PODC keynote. **Seth Gilbert and Nancy Lynch** proved it formally in **2002**, turning it into a theorem.

### The three properties

- **Consistency (C)**: every read returns the most recent write or an error (this is linearizability, not the C in ACID)
- **Availability (A)**: every request to a non-failing node returns a non-error response (not necessarily the latest)
- **Partition tolerance (P)**: the system keeps working despite messages being dropped or delayed between nodes

### What CAP actually says

The popular "pick 2 of 3" phrasing is misleading. **Network partitions are not optional** — in any real distributed system, partitions will happen, so P is mandatory. The real choice appears **only during a partition**, and it is binary:

```
        No partition (the normal case)
        → you can have BOTH C and A

        Partition happens
        → a node that cannot reach its peers must choose:

   ┌────────────────────────┐     ┌────────────────────────┐
   │  CP  — stay consistent │     │  AP — stay available   │
   │  reject the request    │     │  answer with possibly  │
   │  (or block) rather     │     │  stale data rather     │
   │  than risk divergence  │     │  than reject           │
   └────────────────────────┘     └────────────────────────┘
```

So the meaningful split is **CP vs AP**. "CA" only describes a single-node or non-distributed system that gives up the moment the network splits.

## PACELC

### Who created it? When?

**Daniel Abadi** proposed PACELC in **2010** (formalized in a 2012 IEEE Computer article) to fix CAP's biggest blind spot: CAP only describes behavior **during** a partition and says nothing about the tradeoff during normal operation, which is where systems spend ~99.99% of their life.

### The formulation

```
if (Partition) then choose (Availability | Consistency)
Else            then choose (Latency     | Consistency)
```

Replication forces a tradeoff even with a healthy network: to guarantee a read sees the latest write, you must coordinate across replicas, which costs **latency**. If you skip the coordination you get a faster but possibly stale answer. PACELC names the four resulting classes:

```
┌──────────┬──────────────────────────────────────────────────────────┐
│ Class    │ Behavior                                                  │
├──────────┼──────────────────────────────────────────────────────────┤
│ PA / EL  │ On partition favor Availability; else favor Latency       │
│          │ The "always fast, eventually consistent" Dynamo family    │
├──────────┼──────────────────────────────────────────────────────────┤
│ PC / EC  │ On partition favor Consistency; else favor Consistency    │
│          │ The "always correct, pay the latency" consensus family    │
├──────────┼──────────────────────────────────────────────────────────┤
│ PA / EC  │ Available under partition, but consistent when healthy    │
├──────────┼──────────────────────────────────────────────────────────┤
│ PC / EL  │ Consistent under partition, but fast when healthy         │
└──────────┴──────────────────────────────────────────────────────────┘
```

### PACELC classification of real systems

```
┌────────────────────┬──────────┬───────────────────────────────────────┐
│ System             │ PACELC   │ Notes                                 │
├────────────────────┼──────────┼───────────────────────────────────────┤
│ DynamoDB / Dynamo  │ PA/EL    │ Tunable; default favors availability  │
│ Cassandra          │ PA/EL    │ Tunable consistency per query         │
│ Riak               │ PA/EL    │ Dynamo-style, eventual + CRDTs        │
│ Cosmos DB          │ PA/EL    │ Five tunable consistency levels       │
│ Google Spanner     │ PC/EC    │ TrueTime + Paxos, externally consist. │
│ HBase / BigTable   │ PC/EC    │ Strong, single-writer per region      │
│ MongoDB            │ PC/EC    │ Primary-based; tunable read/write conc.│
│ etcd / ZooKeeper   │ PC/EC    │ Consensus-backed, linearizable        │
│ VoltDB             │ PC/EC    │ Strongly consistent in-memory         │
│ PNUTS (Yahoo)      │ PC/EL    │ Timeline consistency, fast local reads│
└────────────────────┴──────────┴───────────────────────────────────────┘
```

Many modern stores are **tunable**: Cassandra and DynamoDB let you choose per-operation quorums, sliding along the spectrum request by request.

## Tunable consistency and quorums

Dynamo-style systems expose consistency as a knob via `R`, `W`, and `N`:

```
N = replicas per key
W = replicas that must acknowledge a write
R = replicas that must respond to a read

If R + W > N  → read and write quorums overlap → strong-ish consistency
If R + W ≤ N  → no guaranteed overlap → eventual consistency, lower latency

N=3, W=3, R=1  → fast reads, slow/fragile writes
N=3, W=1, R=1  → fast everything, weakest guarantee (AP/EL extreme)
N=3, W=2, R=2  → balanced quorum (overlap guaranteed)
```

This is the dial that places a single system anywhere from PA/EL to PC/EC.

## Consistency models (the spectrum)

Consistency models are ordered from strongest (most coordination, most latency) to weakest (least coordination, lowest latency).

```
STRONGEST  ┌─────────────────────────────────────────────┐
   │       │ Linearizability (atomic/strong)             │  reads see
   │       │   single global real-time order             │  latest write
   │       ├─────────────────────────────────────────────┤
   │       │ Sequential consistency                      │
   │       │   one global order, not tied to real time   │
   │       ├─────────────────────────────────────────────┤
   │       │ Causal consistency                          │  preserves
   │       │   causally related ops seen in order        │  cause→effect
   │       ├─────────────────────────────────────────────┤
   │       │ Session guarantees                          │  per-client
   │       │  read-your-writes, monotonic reads,         │  guarantees
   │       │  monotonic writes, writes-follow-reads      │
   │       ├─────────────────────────────────────────────┤
   │       │ Eventual consistency                        │  converges
   ▼       │   replicas converge if writes stop          │  someday
WEAKEST    └─────────────────────────────────────────────┘
```

### Definitions

- **Linearizability** (Herlihy & Wing, 1990): operations appear to take effect instantaneously at some point between invocation and response, consistent with real-time order. This is what [[consensus-raft-paxos]] gives you. "Strong consistency" usually means this.
- **Sequential consistency** (Lamport, 1979): all nodes see operations in the same total order, and each process's own operations keep their program order — but that order need not match wall-clock time.
- **Causal consistency**: if operation A causally precedes B (A "happened-before" B), everyone sees A before B. Concurrent operations may be seen in different orders. Captured with vector clocks. The strongest model still achievable while staying available under partition.
- **Session guarantees** (PNUTS/Bayou): practical per-client promises — *read-your-writes* (you see your own updates), *monotonic reads* (you never go backward in time), *monotonic writes* (your writes apply in order), *writes-follow-reads*.
- **Eventual consistency**: if updates stop, all replicas eventually converge to the same value. Says nothing about how long or what you read meanwhile. Conflict resolution (last-write-wins, or CRDTs) decides the converged value.
- **Bounded staleness**: reads are at most `t` seconds or `k` versions behind — a middle ground used by Cosmos DB.

## CAP/PACELC vs latency

CAP framing hides the everyday cost. **Strong consistency is not free even without partitions** — that is exactly PACELC's "ELC" half. Every linearizable read or write that must reach a quorum pays a coordination round trip, which directly inflates [[tail-latency]] in high-fan-out systems. The architectural decision is rarely "C or A"; it is usually "how much latency will I pay for how much consistency, per operation."

## Common misconceptions

- **"Pick 2 of 3"**: wrong. You don't choose P; partitions choose themselves. You choose C or A *during* a partition.
- **"CAP is about the whole system"**: it is per-operation. One database can serve linearizable and eventual reads side by side.
- **The C in CAP ≠ the C in ACID**: CAP's C is linearizability across replicas; ACID's C is application invariants within a transaction.
- **"Eventual consistency means inconsistent"**: it means convergent. With CRDTs or proper conflict resolution it is correct, just not immediate.
- **"NoSQL = AP, SQL = CP"**: false. Spanner is SQL and CP; Cassandra is NoSQL and tunable. The data model is orthogonal to the consistency model.

## Practical guidance

- **Choose CP/PC** when correctness beats availability: money movement, inventory, locks, leader election, unique constraints, anything where a stale read causes real damage.
- **Choose AP/EL** when availability and latency beat freshness: shopping carts, social feeds, presence, metrics, caches, like counts — high volume, tolerant of brief staleness.
- **Go tunable** when different operations have different needs: strong reads for checkout, eventual reads for the product catalog, in the same store.
- **Push for causal + session guarantees** as the sweet spot: they feel correct to users (you always see your own writes) while staying available and cheap.

## Use Cases

- **Financial ledgers and inventory**: PC/EC, linearizable — never sell the same seat twice
- **Coordination and config**: etcd/ZooKeeper, linearizable for leader election and locks
- **Shopping carts and sessions**: AP/EL with convergence — accept writes always, merge later
- **Social feeds, presence, counters**: AP/EL — staleness is invisible to users, availability is everything
- **Global multi-region apps**: PACELC drives placement — pay cross-region latency for consistency, or keep reads local and accept staleness
- **Collaborative editing**: causal consistency + CRDTs for convergence without coordination
- **Multi-cloud databases**: tunable per-query consistency to match each workload's tolerance

## Links

* https://www.glassbeam.com/sites/all/themes/glassbeam/images/blog/10.1.1.67.6951.pdf (Gilbert & Lynch CAP proof)
* https://www.cs.umd.edu/~abadi/papers/abadi-pacelc.pdf (Abadi, PACELC)
* https://jepsen.io/consistency (consistency model map)
