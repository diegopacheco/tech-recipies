# Gossip Protocols and SWIM Membership

## What is it?

Gossip (epidemic) protocols spread information through a cluster the way a rumor spreads through a crowd: each node periodically picks a few random peers and exchanges state with them. After enough rounds, every node converges on the same information without any central coordinator. **SWIM** is a specific gossip-based protocol for the most common use of gossip — **membership and failure detection**: knowing which nodes are alive, which are dead, and which just joined.

Gossip is the **AP, eventually consistent** answer to cluster coordination. Where [[consensus-raft-paxos]] gives strong agreement among a handful of nodes through majority quorums, gossip gives weak, eventually-consistent agreement among *thousands* of nodes with no quorum and no leader. Large systems use both: consensus for the authoritative control plane, gossip for scalable membership and dissemination.

## Who created them? When?

- **Gossip / epidemic protocols**: **Alan Demers et al** at Xerox PARC, **1987** ("Epidemic Algorithms for Replicated Database Maintenance"), built to keep the Clearinghouse name service replicas in sync.
- **SWIM**: **Abhinandan Das, Indranil Gupta, and Ashish Motivala** at Cornell, **2002** ("SWIM: Scalable Weakly-consistent Infection-style Process Group Membership Protocol"). HashiCorp later extended it with **Lifeguard** (2018) to reduce false failure detection.

## How gossip works

Each node runs a periodic loop (every `T`, e.g. 1s). It picks `k` random peers and exchanges state. Three styles:

```
PUSH      node tells peers what it knows
PULL      node asks peers what they know
PUSH-PULL node and peer exchange both ways  (fastest convergence)
```

Information spreads **exponentially**: in each round the number of informed nodes roughly multiplies, so a cluster of `N` nodes fully converges in **O(log N)** rounds.

```
round 0:  ●                       1 node knows
round 1:  ● ●                     2
round 2:  ● ● ● ●                 4
round 3:  ● ● ● ● ● ● ● ●         8
...       converges in ~log2(N) rounds, e.g. ~17 rounds for 100k nodes
```

### Two modes of gossip

- **Anti-entropy**: nodes periodically exchange and reconcile their *full* state (or digests/[[bloom-filters]]/Merkle trees of it) to repair any divergence. Reliable but heavier. Used for replica reconciliation.
- **Rumor-mongering (dissemination)**: nodes gossip only *recent updates* ("hot rumors") for a while, then stop. Lightweight, but a node that misses every round of a rumor never learns it — which is why systems combine rumor-mongering for speed with anti-entropy as a backstop.

## How SWIM works

SWIM's insight is to **separate failure detection from update dissemination**, and to detect failures with a fixed, constant per-node cost regardless of cluster size (naive all-to-all heartbeating is O(N²) and does not scale).

### Failure detection: ping, ping-req, suspicion

```
Every protocol period, node A picks one random member B to probe:

1. A ──ping──▶ B
   B ──ack──▶ A                      → B is alive, done

2. No ack within timeout?
   A asks k random members to probe B indirectly:
   A ──ping-req(B)──▶ C, D, E
   C ──ping──▶ B ──ack──▶ C ──ack──▶ A   → B alive after all
   (indirect ping routes around a bad A↔B network path)

3. Still no ack from anyone?
   A marks B as SUSPECT (not dead yet) and gossips the suspicion.
   If nobody refutes within a timeout, B is declared DEAD (CONFIRM).
```

The **indirect ping (ping-req)** is the key trick: it distinguishes "B is actually down" from "the single path between A and B is congested," sharply cutting false positives.

### Suspicion mechanism and incarnation numbers

SWIM does not jump straight to "dead." It marks a node **suspect** and lets the rest of the cluster refute it, which tolerates transient slowness. Each node carries an **incarnation number** it controls. If node B hears it is being suspected, it increments its incarnation and broadcasts an **alive** refutation that overrides the suspicion (higher incarnation wins). This prevents a healthy-but-slow node from being wrongly evicted.

### Piggybacking (infection-style dissemination)

SWIM does not run a separate gossip channel for membership changes. It **piggybacks** membership updates (joins, suspects, deaths, alive-refutations) onto the ping/ack messages it already sends. Dissemination costs almost nothing extra — it rides on the failure-detection traffic. This is the "infection-style" in the name.

### Lifeguard refinements (HashiCorp)

Real networks make slow nodes look dead. **Lifeguard** adds: a self-awareness score that makes a node back off its own accusations when it suspects it is the slow one, dynamic timeouts based on local health, and a buddy system to prioritize refutations — drastically reducing false failure detections in production.

## Failure detectors

SWIM's detector is binary-with-suspicion. A richer option is the **Phi Accrual Failure Detector** (Hayashibara et al, 2004), which outputs a *suspicion level* (phi) on a continuous scale from the history of inter-arrival times rather than a hard alive/dead flag. Applications pick their own phi threshold to trade detection speed against false positives. Used by **Cassandra** and **Akka Cluster**.

## Comparison

```
┌─────────────────────┬────────────────────┬─────────────────────┬──────────────────┐
│ Approach            │ Cost per node      │ Consistency         │ Scale            │
├─────────────────────┼────────────────────┼─────────────────────┼──────────────────┤
│ Central heartbeat   │ O(N) on the        │ Strong-ish, but     │ Hundreds         │
│ (all → coordinator) │ coordinator (SPOF) │ coordinator is SPOF │                  │
├─────────────────────┼────────────────────┼─────────────────────┼──────────────────┤
│ All-to-all heartbeat│ O(N) per node,     │ Eventually          │ Small clusters   │
│                     │ O(N²) total        │ consistent          │                  │
├─────────────────────┼────────────────────┼─────────────────────┼──────────────────┤
│ Gossip / SWIM       │ O(1) constant      │ Eventually          │ Thousands to     │
│                     │ per period         │ consistent (AP)     │ tens of thousands│
├─────────────────────┼────────────────────┼─────────────────────┼──────────────────┤
│ Consensus           │ O(N) per write,    │ Strong /            │ 3–7 voting nodes │
│ ([[consensus-raft-  │ majority quorum    │ linearizable (CP)   │                  │
│  paxos]])           │                    │                     │                  │
└─────────────────────┴────────────────────┴─────────────────────┴──────────────────┘
```

## Gossip vs consensus

They are complementary, not competing:

- **Consensus** ([[consensus-raft-paxos]]): few nodes, strong agreement, needs a majority, used for the authoritative source of truth (config, leader election, the committed log).
- **Gossip/SWIM**: many nodes, weak/eventual agreement, no quorum, used for membership, liveness, and best-effort state dissemination at scale.

Consul is the textbook combination: **Raft** for the strongly-consistent catalog and KV store, **SWIM (Serf/memberlist)** for scalable gossip-based membership across the datacenter. Cassandra similarly uses gossip for membership/topology while leaning on tunable quorums (see [[cap-pacelc]]) for data.

## Pros

- **Scalability**: constant per-node cost means it works from dozens to tens of thousands of nodes
- **No single point of failure**: fully decentralized, no coordinator to lose
- **Robust to partial failures**: a few dropped messages or dead nodes barely affect convergence
- **Fast convergence**: information reaches everyone in O(log N) rounds
- **Self-healing**: anti-entropy continuously repairs divergence; new nodes are absorbed automatically
- **Low, bounded bandwidth**: each node talks to only a few peers per round, regardless of cluster size
- **Network-fault tolerant**: indirect pings route around individual bad links

## Cons

- **Eventual, not strong, consistency**: there is a propagation delay; nodes briefly disagree on membership
- **No total ordering**: gossip does not order events; it only spreads them (use [[consensus-raft-paxos]] for order)
- **False positives under load**: slow nodes can be wrongly suspected; needs suspicion + Lifeguard-style tuning
- **Tuning sensitivity**: gossip interval, fanout, and timeouts must be tuned to cluster size and network
- **Redundant traffic**: the same update reaches a node multiple times (the cost of robustness)
- **Convergence is probabilistic**: bounded in expectation, not guaranteed by a deadline
- **Debugging is hard**: emergent, non-deterministic propagation makes incidents tricky to trace
- **Metadata bloat**: large membership lists and piggybacked state grow the per-message overhead

## Who Uses It?

- **Apache Cassandra / ScyllaDB**: gossip for membership, topology, and node state; phi-accrual failure detector
- **HashiCorp Consul, Serf, Nomad**: `memberlist` library implements SWIM + Lifeguard
- **Amazon DynamoDB / Dynamo**: gossip-based membership and failure detection in the original Dynamo design
- **Redis Cluster**: a gossip protocol propagates node and slot state across the cluster
- **Akka Cluster**: gossip membership with a phi-accrual detector
- **Riak**: gossip for ring state and membership (Dynamo-style)
- **CockroachDB**: a gossip network distributes cluster metadata (node liveness, store descriptors)
- **Uber Ringpop**: SWIM-based membership for application-layer sharding

## Use Cases

- **Cluster membership**: track which nodes are in the cluster as they join and leave
- **Failure detection**: detect and disseminate node death without an O(N²) heartbeat mesh
- **Topology / ring dissemination**: spread [[consistent-hashing]] ring changes so clients route correctly
- **Configuration and metadata propagation**: best-effort spread of feature flags, schema versions, node descriptors
- **Service discovery**: decentralized registry of available service instances
- **Database anti-entropy**: reconcile replica divergence using Merkle-tree/digest exchange
- **Application-layer sharding**: build sharded apps on top of a gossip membership list (Ringpop)
- **Monitoring and aggregation**: gossip-based aggregation of cluster-wide metrics

## Links

* https://www.cs.cornell.edu/projects/Quicksilver/public_pdfs/SWIM.pdf
* https://www.bailis.org/blog/doing-redundant-work-to-speed-up-distributed-queries/
* https://github.com/hashicorp/memberlist
* https://www.brianstorti.com/swim/
* https://dl.acm.org/doi/10.1145/41840.41841 (Demers et al, Epidemic Algorithms)
