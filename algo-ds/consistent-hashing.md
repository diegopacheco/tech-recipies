# Consistent Hashing

## What is it?

Consistent Hashing is a distributed hashing scheme that provides a way to distribute data across a cluster of nodes while minimizing reorganization when nodes are added or removed. Unlike traditional hashing where changing the number of buckets requires remapping almost all keys, consistent hashing only requires remapping K/n keys on average (where K is the number of keys and n is the number of nodes). Invented by Karger et al. in 1997, it forms the foundation of many distributed systems like DynamoDB, Cassandra, and content delivery networks.

## How it works?

1. Arrange a hash space as a ring (0 to 2^32-1 or similar range)
2. Hash each node identifier to position it on the ring
3. Hash each key to find its position on the ring
4. Walk clockwise from the key's position to find the first node - that node owns the key
5. When a node joins, it takes over keys from its clockwise neighbor
6. When a node leaves, its keys transfer to the next clockwise node
7. Virtual nodes (multiple positions per physical node) improve load distribution

The key insight is that adding/removing a node only affects keys between that node and its predecessor.

## Use cases?

- Distributed caching (Memcached, Redis Cluster)
- Distributed databases (Cassandra, DynamoDB, Riak)
- Load balancing across servers
- Content delivery networks (Akamai)
- Distributed file systems
- Sharding strategies
- Peer-to-peer networks (Chord DHT)
- Service discovery and routing
- Distributed hash tables
- Session affinity in web applications

## Code Sample (Rust)

```rust
use std::collections::{BTreeMap, HashMap};
use std::hash::{Hash, Hasher};
use std::collections::hash_map::DefaultHasher;

struct ConsistentHash {
    ring: BTreeMap<u64, String>,
    nodes: HashMap<String, Vec<u64>>,
    virtual_nodes: usize,
}

impl ConsistentHash {
    fn new(virtual_nodes: usize) -> Self {
        ConsistentHash {
            ring: BTreeMap::new(),
            nodes: HashMap::new(),
            virtual_nodes,
        }
    }

    fn hash<T: Hash>(key: &T) -> u64 {
        let mut hasher = DefaultHasher::new();
        key.hash(&mut hasher);
        hasher.finish()
    }

    fn add_node(&mut self, node: &str) {
        let mut positions = Vec::new();

        for i in 0..self.virtual_nodes {
            let virtual_key = format!("{}:{}", node, i);
            let hash = Self::hash(&virtual_key);
            self.ring.insert(hash, node.to_string());
            positions.push(hash);
        }

        self.nodes.insert(node.to_string(), positions);
    }

    fn remove_node(&mut self, node: &str) {
        if let Some(positions) = self.nodes.remove(node) {
            for pos in positions {
                self.ring.remove(&pos);
            }
        }
    }

    fn get_node(&self, key: &str) -> Option<&String> {
        if self.ring.is_empty() {
            return None;
        }

        let hash = Self::hash(&key);

        self.ring
            .range(hash..)
            .next()
            .or_else(|| self.ring.iter().next())
            .map(|(_, node)| node)
    }

    fn get_nodes(&self, key: &str, count: usize) -> Vec<&String> {
        if self.ring.is_empty() {
            return Vec::new();
        }

        let hash = Self::hash(&key);
        let mut result = Vec::new();
        let mut seen = std::collections::HashSet::new();

        let iter = self.ring.range(hash..).chain(self.ring.iter());

        for (_, node) in iter {
            if seen.insert(node) {
                result.push(node);
                if result.len() >= count {
                    break;
                }
            }
        }

        result
    }

    fn node_count(&self) -> usize {
        self.nodes.len()
    }

    fn key_distribution(&self, keys: &[&str]) -> HashMap<String, usize> {
        let mut distribution = HashMap::new();

        for node in self.nodes.keys() {
            distribution.insert(node.clone(), 0);
        }

        for key in keys {
            if let Some(node) = self.get_node(key) {
                *distribution.get_mut(node).unwrap() += 1;
            }
        }

        distribution
    }
}

struct ConsistentHashWithReplication {
    ch: ConsistentHash,
    replication_factor: usize,
}

impl ConsistentHashWithReplication {
    fn new(virtual_nodes: usize, replication_factor: usize) -> Self {
        ConsistentHashWithReplication {
            ch: ConsistentHash::new(virtual_nodes),
            replication_factor,
        }
    }

    fn add_node(&mut self, node: &str) {
        self.ch.add_node(node);
    }

    fn remove_node(&mut self, node: &str) {
        self.ch.remove_node(node);
    }

    fn get_replicas(&self, key: &str) -> Vec<&String> {
        self.ch.get_nodes(key, self.replication_factor)
    }
}

fn main() {
    let mut ch = ConsistentHash::new(150);

    ch.add_node("node-1");
    ch.add_node("node-2");
    ch.add_node("node-3");

    println!("Nodes in ring: {}", ch.node_count());

    let keys = ["user:1001", "user:1002", "user:1003", "order:5001", "session:abc"];
    for key in &keys {
        println!("{} -> {:?}", key, ch.get_node(key));
    }

    let test_keys: Vec<&str> = (0..1000).map(|i| Box::leak(format!("key:{}", i).into_boxed_str()) as &str).collect();
    let distribution = ch.key_distribution(&test_keys);
    println!("\nKey distribution across nodes:");
    for (node, count) in &distribution {
        println!("  {}: {} keys ({:.1}%)", node, count, *count as f64 / 10.0);
    }

    println!("\nAdding node-4...");
    ch.add_node("node-4");
    let new_distribution = ch.key_distribution(&test_keys);
    println!("New distribution:");
    for (node, count) in &new_distribution {
        println!("  {}: {} keys ({:.1}%)", node, count, *count as f64 / 10.0);
    }

    let mut chr = ConsistentHashWithReplication::new(150, 3);
    chr.add_node("node-1");
    chr.add_node("node-2");
    chr.add_node("node-3");
    chr.add_node("node-4");

    println!("\nReplicas for 'important-key': {:?}", chr.get_replicas("important-key"));
}
```

## Pros and Cons

### Pros
- Minimal key redistribution when nodes change (only K/n keys move)
- Scales horizontally with node additions
- Decentralized - no single point of failure
- Virtual nodes provide better load balancing
- Simple to implement and understand
- Works well with replication strategies
- Enables elastic scaling

### Cons
- Non-uniform distribution without virtual nodes
- Hot spots can still occur with skewed key access
- Adding many virtual nodes increases memory usage
- Rebalancing still required for optimal distribution
- Does not handle heterogeneous node capacities well (without weighted virtual nodes)
- Range queries are not naturally supported
- Clock drift can affect consistency in some implementations

## Frameworks or libraries using it

- **Rust**: `consistent-hash-ring` crate, `hashring` crate
- **Amazon DynamoDB**: Partitioning and replication
- **Apache Cassandra**: Token ring for data distribution
- **Riak**: Distributed key-value store
- **Memcached**: Client-side consistent hashing
- **Redis Cluster**: Slot-based variant of consistent hashing
- **Akka Cluster**: Actor distribution
- **Akamai CDN**: Content distribution
- **Discord**: Message routing and caching
- **Vimeo**: Video delivery infrastructure
