# Consensus: Raft and Paxos

## What is it?

Consensus is the problem of getting a group of nodes to agree on a single value (or an ordered sequence of values) even when some nodes crash, messages are lost or delayed, and the network is unreliable. It is the foundation of every system that needs a single source of truth across machines: replicated state machines, leader election, distributed locks, configuration stores, and the replicated log behind databases and message brokers.

A consensus protocol must satisfy four properties:

- **Agreement**: no two correct nodes decide different values
- **Validity (integrity)**: the decided value was proposed by some node
- **Termination (liveness)**: every correct node eventually decides
- **Fault tolerance**: progress continues as long as a majority of nodes are alive

The practical formulation is the **replicated state machine**: if every node applies the same commands in the same order to a deterministic state machine, every node ends up in the same state. Consensus is what produces that single agreed-upon order. The ordered command sequence is a [[write-ahead-log]] replicated across nodes.

## The FLP impossibility

In **1985**, **Fischer, Lynch, and Paterson** proved that in a fully asynchronous system (no bound on message delay) no deterministic protocol can guarantee consensus if even a single node may crash. There is always an execution that runs forever without deciding.

Real protocols sidestep FLP by assuming **partial synchrony**: the network is asynchronous most of the time but becomes synchronous long enough (via timeouts) to make progress. This is why every consensus algorithm uses timeouts and why none can promise both safety and liveness during an arbitrarily bad partition. Consensus systems choose **safety over liveness**: under a partition they stop making progress rather than risk disagreement. In [[cap-pacelc]] terms, consensus systems are **CP**.

## Quorums

Consensus relies on **majority quorums**. With `N = 2f + 1` nodes you tolerate `f` failures, because any two majorities overlap in at least one node, and that overlap carries the latest decision forward.

```
N=3  → tolerates 1 failure   (quorum = 2)
N=5  → tolerates 2 failures   (quorum = 3)
N=7  → tolerates 3 failures   (quorum = 4)

Why odd numbers: N=4 also tolerates only 1 failure (quorum = 3)
but costs an extra node, so 3, 5, 7 are the usual choices.
```

---

## Paxos

### Who created it? When?

**Leslie Lamport** designed Paxos around **1989** and published it in **1998** as "The Part-Time Parliament" (an allegory about a Greek island parliament that most readers found impenetrable). He followed up in **2001** with "Paxos Made Simple." Paxos is the theoretical bedrock of distributed consensus and won Lamport the Turing Award.

### Roles

- **Proposer**: proposes a value, drives a round
- **Acceptor**: votes on proposals; a majority of acceptors forms a quorum
- **Learner**: learns the chosen value

A single node usually plays all three roles.

### How single-decree Paxos works

Paxos agrees on one value through two phases. Each round carries a globally unique, increasing **proposal number** `n`.

```
Phase 1 — Prepare / Promise
  Proposer → all acceptors:  PREPARE(n)
  Acceptor: if n > any prepare it has seen:
              promise not to accept anything < n
              reply PROMISE(n, highestAcceptedProposal)
  Proposer waits for a majority of promises.

Phase 2 — Accept / Accepted
  Proposer picks the value:
     if any acceptor already accepted a value, REUSE the one
       with the highest accepted proposal number
     else use its own value
  Proposer → all acceptors:  ACCEPT(n, value)
  Acceptor: if it has not promised a higher n, accept and
              reply ACCEPTED(n, value)
  A majority of ACCEPTED means the value is CHOSEN.
```

The key safety trick is in Phase 2: a proposer cannot freely pick a value if any earlier value might already be chosen — it must re-propose the highest already-accepted value. This is what guarantees agreement across competing proposers.

### Multi-Paxos

Single-decree Paxos agrees on one value. Real systems need an ordered log of many values, which is **Multi-Paxos**: elect a stable **leader** that skips Phase 1 for subsequent entries (Phase 1 is run once to claim leadership, then each log slot needs only Phase 2). This collapses the steady state to a single round trip per command, the same shape as Raft.

### Paxos variants

- **Fast Paxos** (Lamport, 2005): clients send directly to acceptors, saving a round trip at the cost of larger quorums and collision handling
- **Cheap Paxos**: uses auxiliary acceptors only during failures to cut cost
- **Flexible Paxos** (Howard et al, 2016): Phase 1 and Phase 2 quorums only need to intersect each other, not themselves — enables smaller, asymmetric quorums
- **EPaxos (Egalitarian Paxos)** (Moraru et al, 2013): leaderless, commits commutative commands in one round trip without a single bottleneck leader
- **Generalized Paxos**: exploits commutativity so non-conflicting commands need no ordering

---

## Raft

### Who created it? When?

**Diego Ongaro and John Ousterhout** designed Raft at Stanford and published it in **2014** as "In Search of an Understandable Consensus Algorithm." Its explicit goal was understandability — Multi-Paxos was notoriously hard to implement correctly, and Raft was engineered to be teachable and to map directly onto real code. It became the default consensus algorithm for a generation of infrastructure.

### Core ideas

Raft decomposes consensus into three sub-problems: **leader election**, **log replication**, and **safety**. Every node is in one of three states:

```
            timeout, start election
   ┌──────┐ ──────────────────────▶ ┌───────────┐
   │      │                         │ Candidate │
   │      │ ◀── discovers leader ── │           │
   │Follow│     or new term         └─────┬─────┘
   │ -er  │                               │ wins majority of votes
   │      │ ◀── higher term seen ──┐      ▼
   │      │                        │  ┌────────┐
   └──────┘                        └──│ Leader │
        ▲                             └────┬───┘
        └─── discovers higher term ───────┘
```

**Terms** act as a logical clock: time is divided into numbered terms, each beginning with an election. At most one leader per term. Every message carries a term; a node seeing a higher term immediately reverts to follower. This single rule eliminates split-brain.

### Leader election

Followers expect periodic heartbeats (`AppendEntries` with no entries) from the leader. If a follower's **randomized election timeout** (e.g. 150–300ms) elapses with no heartbeat, it becomes a candidate, increments the term, votes for itself, and sends `RequestVote` RPCs. Randomized timeouts make simultaneous candidacies rare, so elections usually resolve in one round.

### Log replication

```
Client → Leader: command
  Leader appends entry to its own log (uncommitted)
  Leader → followers: AppendEntries(term, prevLogIndex,
                        prevLogTerm, entries, leaderCommit)
  Followers append if their log matches at prevLogIndex
  Once a MAJORITY has the entry, leader marks it COMMITTED
  Leader applies to state machine, replies to client
  Followers apply once they learn commitIndex advanced
```

The **Log Matching Property** guarantees consistency: if two logs contain an entry with the same index and term, the logs are identical up through that index. `AppendEntries` carries `prevLogIndex`/`prevLogTerm`, and a follower rejects entries that do not match, forcing the leader to back up and repair the follower's log.

### Safety: the election restriction

A node will only grant its vote to a candidate whose log is **at least as up-to-date** as its own (compared by last entry's term, then index). This guarantees a new leader already contains every committed entry, so committed entries are never lost or overwritten. A leader only commits entries from its own current term (committing older-term entries indirectly), closing a subtle safety hole.

### Membership changes

Changing the cluster set safely is hard because two majorities could form during the transition. Raft offers **joint consensus** (a transitional configuration that requires majorities of both old and new sets) and, more commonly, **single-server changes** (add or remove one node at a time so old and new majorities always overlap).

### Log compaction

Logs cannot grow forever. Nodes take **snapshots** of the state machine and discard the prefix of the log they cover. A lagging or newly added follower that is behind the snapshot point is caught up via an `InstallSnapshot` RPC.

---

## Related protocols

- **Viewstamped Replication (VR)** — Oki and Liskov, **1988**, actually predates Paxos and is structurally close to Raft (views ≈ terms, primary ≈ leader). "VR Revisited" (2012) modernized it.
- **Zab (ZooKeeper Atomic Broadcast)** — the protocol behind Apache ZooKeeper. Primary-backup, total order broadcast, optimized for high read throughput and recovery.
- **Multi-Paxos** — the production form of Paxos used inside Google Chubby and Spanner.

## Comparison

```
┌───────────────────┬──────────────┬─────────────┬───────────────┬──────────────────┐
│ Protocol          │ Leader       │ Understand- │ Steady-state  │ Notable users    │
│                   │              │ ability     │ round trips   │                  │
├───────────────────┼──────────────┼─────────────┼───────────────┼──────────────────┤
│ Single Paxos      │ No           │ Hard        │ 2             │ theory           │
├───────────────────┼──────────────┼─────────────┼───────────────┼──────────────────┤
│ Multi-Paxos       │ Yes (stable) │ Hard        │ 1             │ Chubby, Spanner  │
├───────────────────┼──────────────┼─────────────┼───────────────┼──────────────────┤
│ Raft              │ Yes (strong) │ Easy        │ 1             │ etcd, Consul,    │
│                   │              │             │               │ TiKV, CockroachDB│
├───────────────────┼──────────────┼─────────────┼───────────────┼──────────────────┤
│ Zab               │ Yes (primary)│ Medium      │ 1             │ ZooKeeper        │
├───────────────────┼──────────────┼─────────────┼───────────────┼──────────────────┤
│ Viewstamped Repl  │ Yes (primary)│ Medium      │ 1             │ research, Harp   │
├───────────────────┼──────────────┼─────────────┼───────────────┼──────────────────┤
│ EPaxos            │ Leaderless   │ Hard        │ 1 (fast path) │ research         │
└───────────────────┴──────────────┴─────────────┴───────────────┴──────────────────┘
```

## Raft vs Paxos

| Aspect | Raft | Paxos |
|---|---|---|
| Design goal | Understandability | Theoretical minimalism |
| Leadership | Strong leader, all writes flow through it | Leaderless core; Multi-Paxos adds a leader |
| Log | Contiguous, no holes allowed | Slots can be filled out of order |
| Membership change | Joint consensus / single-server | Not specified in core, added by implementations |
| Mental model | Prescriptive, maps to code | A toolkit needing many decisions |
| Reputation | Easy to implement correctly | Easy to implement subtly wrong |

## Pros

- **Strong consistency**: produces a single linearizable order of operations across the cluster
- **Fault tolerance**: survives `f` failures with `2f + 1` nodes, no data loss of committed entries
- **No split-brain**: terms/views and majority quorums guarantee at most one effective leader
- **Foundation for everything stateful**: leader election, locks, config, replicated logs all reduce to consensus
- **Well understood**: decades of proofs, formal verification (TLA+), and battle-tested implementations
- **Automatic recovery**: a failed leader triggers a new election with no operator intervention

## Cons

- **Majority required for writes**: loses write availability when a majority is unreachable (CP, not AP — see [[cap-pacelc]])
- **Latency floor**: every committed write needs a round trip to a majority, costly across regions
- **Leader bottleneck**: all writes funnel through one node in Raft and Multi-Paxos
- **Small clusters only**: quorum cost makes 3–7 nodes typical; consensus does not scale to hundreds of voting members (use [[gossip-swim]] for large-scale membership instead)
- **Cross-region pain**: wide-area majorities add tens of milliseconds per write; needs careful placement or hierarchical designs
- **Implementation hazards**: edge cases in log truncation, snapshots, and membership changes are easy to get wrong
- **Reconfiguration risk**: changing the member set is the most bug-prone part of any implementation

## Who Uses It?

- **etcd** (Raft): the consistent key-value store behind Kubernetes
- **Consul** (Raft): service discovery and config; combines Raft for state with [[gossip-swim]] for membership
- **CockroachDB / TiKV / YugabyteDB** (Raft per range): consensus on each data shard
- **Google Chubby and Spanner** (Multi-Paxos): lock service and globally distributed database
- **Apache ZooKeeper** (Zab): coordination service used by Kafka (legacy), HBase, and others
- **Apache Kafka KRaft** (Raft): replaces ZooKeeper for controller metadata
- **MongoDB** (Raft-like replica set protocol) for primary election and oplog replication
- **HashiCorp Nomad / Vault** (Raft) for cluster state

## Use Cases

- **Leader election**: pick exactly one coordinator among replicas
- **Distributed locks and leases**: mutual exclusion with fencing tokens
- **Configuration management**: a consistent, watchable source of truth (etcd, Consul, ZooKeeper)
- **Replicated databases**: agree on the transaction/commit order across replicas
- **Replicated logs**: the ordered [[write-ahead-log]] underneath state machines and brokers
- **Metadata control planes**: Kubernetes, Kafka KRaft, and schedulers storing cluster state
- **Sharded systems**: one consensus group per shard/range so the cluster scales horizontally while each shard stays strongly consistent

## Links

* https://lamport.azurewebsites.net/pubs/paxos-simple.pdf
* https://raft.github.io/raft.pdf
* https://raft.github.io/ (visualizations and implementation list)
* https://groups.csail.mit.edu/tds/papers/Lynch/jacm85.pdf (FLP impossibility)
