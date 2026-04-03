# Consistent Hashing

## What is it?

Consistent Hashing is a distributed hashing technique that minimizes the number of keys that need to be remapped when the number of nodes in a system changes. In traditional modular hashing (key % n), adding or removing a node causes nearly all keys to be reassigned. Consistent hashing maps both keys and nodes onto a circular hash ring so that only K/n keys need to move on average when a node is added or removed (where K is the total keys and n is the number of nodes).

## Who created it? When?

Consistent hashing was introduced by **David Karger, Eric Lehman, Tom Leighton, Rina Panigrahy, Matthew Levine, and Daniel Lewin** at MIT in **1997**. The paper "Consistent Hashing and Random Trees: Distributed Caching Protocols for Relieving Hot Spots on the World Wide Web" was published at STOC 1997. The technique was later popularized by Amazon's **Dynamo paper (2007)** and became foundational in distributed systems design.

## How it works?

1. **Hash Ring**:
   - Imagine a circular space from 0 to 2^32 - 1
   - Hash each node's identifier (IP, name) to a position on the ring
   - Hash each key to a position on the ring
   - A key is assigned to the first node found clockwise from its position

```
              Node A (pos 50)
                 ●
            /         \
          /             \
   Node D ●               ● Node B
  (pos 230)    hash ring    (pos 120)
          \             /
            \         /
                 ●
              Node C (pos 180)

Key "user:42" hashes to pos 95 → assigned to Node B (first node clockwise)
Key "order:7" hashes to pos 200 → assigned to Node D (first node clockwise)
```

2. **Adding a Node**:
   - New node is placed on the ring at its hash position
   - Only keys between the new node and its predecessor need to move
   - All other key assignments remain unchanged

```
Before: A(50) → B(120) → C(180) → D(230)
Add E at position 150:
- Only keys in range (120, 150] move from C to E
- Everything else stays put
```

3. **Removing a Node**:
   - Node is removed from the ring
   - Its keys are reassigned to the next node clockwise
   - All other key assignments remain unchanged

4. **Virtual Nodes (Vnodes)**:
   - Each physical node gets multiple positions on the ring
   - A node with 150 vnodes has 150 hash positions spread across the ring
   - Provides better load distribution and smoother rebalancing
   - More vnodes = more uniform distribution but more memory for the ring metadata

```
Physical Node A → vnode_A_0(20), vnode_A_1(95), vnode_A_2(210)
Physical Node B → vnode_B_0(55), vnode_B_1(140), vnode_B_2(250)

Keys are distributed across more positions, reducing hotspots
```

## Algorithms and Variants

### 1. Basic Consistent Hashing (Karger 1997)

Each node gets one position on the ring. Keys walk clockwise to find their node. Simple but produces uneven load distribution with few nodes.

- Lookup: O(log n) with sorted ring, binary search
- Space: O(n)
- Load variance: high with few nodes

### 2. Virtual Nodes (Dynamo-style)

Each physical node maps to many virtual positions on the ring. Standard approach in production systems. More vnodes means better balance but higher memory usage.

- Lookup: O(log V) where V = total virtual nodes
- Space: O(V)
- Load variance: decreases as vnode count increases
- Used by: Cassandra, DynamoDB, Riak

### 3. Jump Consistent Hashing (Google 2014)

A fast, memory-free algorithm by John Lamping and Eric Veach. Uses a mathematical formula instead of a ring. Produces perfectly balanced distribution. Only works when nodes are numbered sequentially (0, 1, 2, ...) and only supports adding/removing the last node.

- Lookup: O(log n)
- Space: O(1)
- Limitation: no arbitrary node removal
- Used by: Google internal systems

### 4. Rendezvous Hashing (Highest Random Weight)

Each key computes a weight for every node and picks the node with the highest weight. No ring structure. All nodes are considered for every key. Simpler to understand but O(n) per lookup.

- Lookup: O(n)
- Space: O(n)
- Advantage: no ring maintenance, easy to implement
- Used by: content delivery networks, distributed caches

### 5. Maglev Hashing (Google 2016)

Uses a precomputed lookup table for O(1) lookups. Designed for load balancers where speed matters. Provides near-perfect balance and minimal disruption on node changes.

- Lookup: O(1) via lookup table
- Space: O(M) where M is table size (prime number)
- Build time: O(M * n)
- Used by: Google Maglev load balancer

## Comparison

```
┌─────────────────────┬──────────┬────────┬──────────────┬──────────────────────┐
│ Algorithm           │ Lookup   │ Space  │ Balance      │ Arbitrary Removal    │
├─────────────────────┼──────────┼────────┼──────────────┼──────────────────────┤
│ Modular Hash        │ O(1)     │ O(1)   │ Good         │ Remaps all keys      │
├─────────────────────┼──────────┼────────┼──────────────┼──────────────────────┤
│ Basic Ring          │ O(log n) │ O(n)   │ Poor         │ Yes, minimal remap   │
├─────────────────────┼──────────┼────────┼──────────────┼──────────────────────┤
│ Ring + Vnodes       │ O(log V) │ O(V)   │ Good         │ Yes, minimal remap   │
├─────────────────────┼──────────┼────────┼──────────────┼──────────────────────┤
│ Jump Hash           │ O(log n) │ O(1)   │ Perfect      │ No, append-only      │
├─────────────────────┼──────────┼────────┼──────────────┼──────────────────────┤
│ Rendezvous          │ O(n)     │ O(n)   │ Good         │ Yes, minimal remap   │
├─────────────────────┼──────────┼────────┼──────────────┼──────────────────────┤
│ Maglev              │ O(1)     │ O(M)   │ Near-perfect │ Yes, rebuild table   │
└─────────────────────┴──────────┴────────┴──────────────┴──────────────────────┘
```

## Pros

- **Minimal Disruption**: Only K/n keys move when adding or removing a node
- **Horizontal Scalability**: Nodes can be added incrementally without full rehash
- **No Central Coordinator**: Each client can independently compute key-to-node mapping
- **Fault Tolerant**: Node failure only affects keys mapped to that node
- **Well Understood**: Battle-tested in production at massive scale for decades
- **Flexible Replication**: Easy to replicate keys to the next N nodes on the ring
- **Weighted Distribution**: Vnodes allow assigning more load to more powerful nodes
- **Language Agnostic**: Simple to implement in any language with a hash function

## Cons

- **Load Imbalance**: Basic ring without vnodes produces uneven distribution
- **Hotspots**: Popular keys still land on a single node regardless of hashing
- **Vnode Overhead**: Many vnodes increase memory usage and ring metadata size
- **Hash Function Dependency**: Poor hash functions cause clustering
- **Rebalancing Complexity**: Moving data between nodes on topology change is the hard part
- **No Range Queries**: Keys are scattered across nodes, range scans require hitting all nodes
- **Cascading Failure Risk**: If a node goes down, its successor absorbs all extra load suddenly
- **Stale Ring State**: Clients with outdated ring view route to wrong nodes

## Use Cases

- **Distributed Caches**: Memcached, Redis Cluster for partitioning keys across cache nodes
- **Distributed Databases**: Cassandra, DynamoDB, Riak, Voldemort for data partitioning
- **Load Balancers**: Distributing requests to backend servers with session affinity
- **Content Delivery Networks**: Mapping content to edge servers
- **Distributed File Systems**: GlusterFS, Ceph CRUSH map for placing data chunks
- **Service Discovery**: Routing requests to service instances
- **Sharding**: Database sharding where shard assignment must survive topology changes
- **Peer-to-Peer Networks**: Chord, Pastry, and other DHTs use consistent hashing as foundation
- **Stream Processing**: Partitioning stream keys across consumer instances
- **DNS Load Balancing**: Distributing DNS queries across resolver pools
