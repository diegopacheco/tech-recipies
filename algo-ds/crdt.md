# CRDT

## What is it?

A CRDT (Conflict-free Replicated Data Type) is a data structure designed for distributed systems that can be replicated across multiple nodes, updated independently and concurrently without coordination, and automatically merged to achieve eventual consistency. CRDTs guarantee that all replicas converge to the same state regardless of the order in which updates are received. Developed by Marc Shapiro and colleagues around 2011, CRDTs eliminate the need for consensus protocols or locking in many distributed scenarios.

## How it works?

There are two main types of CRDTs:

**State-based (CvRDT):**
1. Each replica maintains complete state
2. Replicas periodically send their full state to others
3. States are merged using a join operation that forms a semilattice
4. Merge must be commutative, associative, and idempotent

**Operation-based (CmRDT):**
1. Only operations (deltas) are transmitted between replicas
2. Operations must be commutative (order-independent)
3. Requires reliable broadcast (all operations eventually delivered)
4. More bandwidth-efficient than state-based

Common CRDTs include G-Counter (grow-only), PN-Counter (positive-negative), G-Set, OR-Set (observed-remove), LWW-Register (last-writer-wins), and sequences for collaborative text editing.

## Use cases?

- Collaborative text editing (Google Docs, Figma)
- Distributed databases (Riak, Redis CRDT)
- Offline-first mobile applications
- Multi-player game state synchronization
- Shopping carts in e-commerce
- Distributed caching
- Real-time collaboration tools
- Edge computing with intermittent connectivity
- Chat applications with offline support
- Version control systems

## Code Sample (Rust)

```rust
use std::collections::{HashMap, HashSet};

trait CRDT {
    fn merge(&mut self, other: &Self);
}

#[derive(Clone, Debug)]
struct GCounter {
    counts: HashMap<String, u64>,
    node_id: String,
}

impl GCounter {
    fn new(node_id: &str) -> Self {
        GCounter {
            counts: HashMap::new(),
            node_id: node_id.to_string(),
        }
    }

    fn increment(&mut self) {
        *self.counts.entry(self.node_id.clone()).or_insert(0) += 1;
    }

    fn value(&self) -> u64 {
        self.counts.values().sum()
    }
}

impl CRDT for GCounter {
    fn merge(&mut self, other: &Self) {
        for (node, &count) in &other.counts {
            let entry = self.counts.entry(node.clone()).or_insert(0);
            *entry = (*entry).max(count);
        }
    }
}

#[derive(Clone, Debug)]
struct PNCounter {
    positive: GCounter,
    negative: GCounter,
}

impl PNCounter {
    fn new(node_id: &str) -> Self {
        PNCounter {
            positive: GCounter::new(node_id),
            negative: GCounter::new(node_id),
        }
    }

    fn increment(&mut self) {
        self.positive.increment();
    }

    fn decrement(&mut self) {
        self.negative.increment();
    }

    fn value(&self) -> i64 {
        self.positive.value() as i64 - self.negative.value() as i64
    }
}

impl CRDT for PNCounter {
    fn merge(&mut self, other: &Self) {
        self.positive.merge(&other.positive);
        self.negative.merge(&other.negative);
    }
}

#[derive(Clone, Debug)]
struct GSet<T: Clone + Eq + std::hash::Hash> {
    elements: HashSet<T>,
}

impl<T: Clone + Eq + std::hash::Hash> GSet<T> {
    fn new() -> Self {
        GSet { elements: HashSet::new() }
    }

    fn add(&mut self, element: T) {
        self.elements.insert(element);
    }

    fn contains(&self, element: &T) -> bool {
        self.elements.contains(element)
    }

    fn elements(&self) -> &HashSet<T> {
        &self.elements
    }
}

impl<T: Clone + Eq + std::hash::Hash> CRDT for GSet<T> {
    fn merge(&mut self, other: &Self) {
        for element in &other.elements {
            self.elements.insert(element.clone());
        }
    }
}

#[derive(Clone, Debug, Eq, PartialEq, Hash)]
struct UniqueTag {
    node_id: String,
    counter: u64,
}

#[derive(Clone, Debug)]
struct ORSet<T: Clone + Eq + std::hash::Hash> {
    elements: HashMap<T, HashSet<UniqueTag>>,
    tombstones: HashMap<T, HashSet<UniqueTag>>,
    node_id: String,
    counter: u64,
}

impl<T: Clone + Eq + std::hash::Hash> ORSet<T> {
    fn new(node_id: &str) -> Self {
        ORSet {
            elements: HashMap::new(),
            tombstones: HashMap::new(),
            node_id: node_id.to_string(),
            counter: 0,
        }
    }

    fn add(&mut self, element: T) {
        self.counter += 1;
        let tag = UniqueTag {
            node_id: self.node_id.clone(),
            counter: self.counter,
        };
        self.elements.entry(element).or_insert_with(HashSet::new).insert(tag);
    }

    fn remove(&mut self, element: &T) {
        if let Some(tags) = self.elements.remove(element) {
            self.tombstones.entry(element.clone()).or_insert_with(HashSet::new).extend(tags);
        }
    }

    fn contains(&self, element: &T) -> bool {
        self.elements.get(element).map_or(false, |tags| !tags.is_empty())
    }

    fn elements(&self) -> Vec<&T> {
        self.elements.keys().filter(|e| self.contains(e)).collect()
    }
}

impl<T: Clone + Eq + std::hash::Hash> CRDT for ORSet<T> {
    fn merge(&mut self, other: &Self) {
        for (element, tags) in &other.elements {
            let entry = self.elements.entry(element.clone()).or_insert_with(HashSet::new);
            for tag in tags {
                if !self.tombstones.get(element).map_or(false, |t| t.contains(tag)) {
                    entry.insert(tag.clone());
                }
            }
        }

        for (element, tags) in &other.tombstones {
            let tombstone_entry = self.tombstones.entry(element.clone()).or_insert_with(HashSet::new);
            tombstone_entry.extend(tags.clone());

            if let Some(element_tags) = self.elements.get_mut(element) {
                for tag in tags {
                    element_tags.remove(tag);
                }
            }
        }
    }
}

#[derive(Clone, Debug)]
struct LWWRegister<T: Clone> {
    value: Option<T>,
    timestamp: u64,
    node_id: String,
}

impl<T: Clone> LWWRegister<T> {
    fn new(node_id: &str) -> Self {
        LWWRegister {
            value: None,
            timestamp: 0,
            node_id: node_id.to_string(),
        }
    }

    fn set(&mut self, value: T, timestamp: u64) {
        if timestamp > self.timestamp {
            self.value = Some(value);
            self.timestamp = timestamp;
        }
    }

    fn get(&self) -> Option<&T> {
        self.value.as_ref()
    }
}

impl<T: Clone> CRDT for LWWRegister<T> {
    fn merge(&mut self, other: &Self) {
        if other.timestamp > self.timestamp {
            self.value = other.value.clone();
            self.timestamp = other.timestamp;
        }
    }
}

fn main() {
    println!("=== G-Counter ===");
    let mut counter1 = GCounter::new("node1");
    let mut counter2 = GCounter::new("node2");

    counter1.increment();
    counter1.increment();
    counter2.increment();

    println!("Counter1: {}", counter1.value());
    println!("Counter2: {}", counter2.value());

    counter1.merge(&counter2);
    counter2.merge(&counter1);

    println!("After merge - Counter1: {}", counter1.value());
    println!("After merge - Counter2: {}", counter2.value());

    println!("\n=== OR-Set ===");
    let mut set1: ORSet<String> = ORSet::new("node1");
    let mut set2: ORSet<String> = ORSet::new("node2");

    set1.add("apple".to_string());
    set1.add("banana".to_string());
    set2.add("cherry".to_string());
    set2.remove(&"apple".to_string());

    set1.merge(&set2);
    set2.merge(&set1);

    println!("Set1 elements: {:?}", set1.elements());
    println!("Set2 elements: {:?}", set2.elements());
}
```

## Pros and Cons

### Pros
- No coordination required (no locks, no consensus)
- Always available for reads and writes
- Automatic conflict resolution
- Works with network partitions
- Eventual consistency guaranteed mathematically
- Enables offline-first applications
- Scales horizontally

### Cons
- Higher memory usage (metadata for conflict resolution)
- Limited data types compared to traditional structures
- Eventual consistency may not suit all use cases
- Complexity in implementing custom CRDTs
- Tombstones can accumulate (garbage collection needed)
- May have surprising semantics (e.g., add-remove conflicts)
- Not suitable for operations requiring strong consistency

## Frameworks or libraries using it

- **Rust**: `crdts` crate, `automerge` (JSON CRDT), `yrs` (Yjs port)
- **Riak**: Distributed database with built-in CRDT support
- **Redis**: CRDT-based active-active geo-replication
- **Figma**: Real-time collaborative design tool
- **Apple Notes**: Cross-device synchronization
- **SoundCloud**: Distributed counters for play counts
- **Automerge**: JSON CRDT library for collaborative apps
- **Yjs**: High-performance CRDT for text editing
- **OrbitDB**: Peer-to-peer database on IPFS
- **Phoenix LiveView**: Presence tracking with CRDTs
