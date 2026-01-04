# Skip List

## What is it?

A Skip List is a probabilistic data structure that allows fast search, insertion, and deletion operations within an ordered sequence of elements. It achieves O(log n) average time complexity by maintaining multiple layers of linked lists, where each higher layer acts as an "express lane" that skips over many elements. Invented by William Pugh in 1989, it provides a simpler alternative to balanced trees like AVL or Red-Black trees while offering similar performance guarantees.

## How it works?

1. The bottom layer (level 0) is a regular sorted linked list containing all elements
2. Each higher layer contains a subset of elements from the layer below
3. An element at level i has a probability p (typically 0.5) of also appearing at level i+1
4. Search starts from the top-left and moves right until finding a larger element, then drops down
5. Insertion finds the position at each level and links the new node with probability p at each level
6. Deletion removes the node from all levels where it appears
7. The expected number of levels is O(log n)

The randomization eliminates the need for complex rebalancing operations required by deterministic balanced trees.

## Use cases?

- In-memory ordered indexes
- Redis sorted sets (ZSET) implementation
- LevelDB and RocksDB MemTable
- Priority queues with efficient update operations
- Concurrent data structures (lock-free implementations)
- Range query support in databases
- Real-time leaderboards and ranking systems
- Interval scheduling problems
- Lock-free concurrent sorted maps

## Code Sample (Rust)

```rust
use std::ptr;

const MAX_LEVEL: usize = 16;
const P: f64 = 0.5;

struct Node<K, V> {
    key: K,
    value: V,
    forward: Vec<*mut Node<K, V>>,
}

struct SkipList<K, V> {
    head: *mut Node<K, V>,
    level: usize,
    len: usize,
}

impl<K: Ord + Default, V: Default> SkipList<K, V> {
    fn new() -> Self {
        let head = Box::into_raw(Box::new(Node {
            key: K::default(),
            value: V::default(),
            forward: vec![ptr::null_mut(); MAX_LEVEL],
        }));
        SkipList { head, level: 0, len: 0 }
    }

    fn random_level() -> usize {
        let mut lvl = 0;
        while rand::random::<f64>() < P && lvl < MAX_LEVEL - 1 {
            lvl += 1;
        }
        lvl
    }

    fn insert(&mut self, key: K, value: V) {
        let mut update: Vec<*mut Node<K, V>> = vec![ptr::null_mut(); MAX_LEVEL];
        let mut current = self.head;

        unsafe {
            for i in (0..=self.level).rev() {
                while !(*current).forward[i].is_null()
                    && (*(*current).forward[i]).key < key {
                    current = (*current).forward[i];
                }
                update[i] = current;
            }

            let new_level = Self::random_level();
            if new_level > self.level {
                for i in (self.level + 1)..=new_level {
                    update[i] = self.head;
                }
                self.level = new_level;
            }

            let new_node = Box::into_raw(Box::new(Node {
                key,
                value,
                forward: vec![ptr::null_mut(); new_level + 1],
            }));

            for i in 0..=new_level {
                (*new_node).forward[i] = (*update[i]).forward[i];
                (*update[i]).forward[i] = new_node;
            }

            self.len += 1;
        }
    }

    fn search(&self, key: &K) -> Option<&V> {
        let mut current = self.head;

        unsafe {
            for i in (0..=self.level).rev() {
                while !(*current).forward[i].is_null()
                    && (*(*current).forward[i]).key < *key {
                    current = (*current).forward[i];
                }
            }

            current = (*current).forward[0];

            if !current.is_null() && (*current).key == *key {
                return Some(&(*current).value);
            }
        }

        None
    }

    fn delete(&mut self, key: &K) -> bool {
        let mut update: Vec<*mut Node<K, V>> = vec![ptr::null_mut(); MAX_LEVEL];
        let mut current = self.head;

        unsafe {
            for i in (0..=self.level).rev() {
                while !(*current).forward[i].is_null()
                    && (*(*current).forward[i]).key < *key {
                    current = (*current).forward[i];
                }
                update[i] = current;
            }

            current = (*current).forward[0];

            if current.is_null() || (*current).key != *key {
                return false;
            }

            for i in 0..=self.level {
                if (*update[i]).forward[i] != current {
                    break;
                }
                (*update[i]).forward[i] = (*current).forward[i];
            }

            drop(Box::from_raw(current));

            while self.level > 0 && (*self.head).forward[self.level].is_null() {
                self.level -= 1;
            }

            self.len -= 1;
            true
        }
    }

    fn len(&self) -> usize {
        self.len
    }
}

impl<K, V> Drop for SkipList<K, V> {
    fn drop(&mut self) {
        unsafe {
            let mut current = (*self.head).forward[0];
            while !current.is_null() {
                let next = (*current).forward[0];
                drop(Box::from_raw(current));
                current = next;
            }
            drop(Box::from_raw(self.head));
        }
    }
}

fn main() {
    let mut list: SkipList<i32, String> = SkipList::new();

    list.insert(3, "three".to_string());
    list.insert(1, "one".to_string());
    list.insert(4, "four".to_string());
    list.insert(1, "one-updated".to_string());
    list.insert(5, "five".to_string());

    println!("Length: {}", list.len());
    println!("Search 3: {:?}", list.search(&3));
    println!("Search 2: {:?}", list.search(&2));

    list.delete(&3);
    println!("After delete 3: {:?}", list.search(&3));
}
```

## Pros and Cons

### Pros
- Simple to implement compared to balanced trees
- O(log n) average time for search, insert, delete
- Easy to implement concurrent/lock-free versions
- Efficient range queries and ordered iteration
- No complex rebalancing required
- Cache-friendly sequential access at bottom level
- Space efficient with tunable parameters

### Cons
- O(n) worst-case time complexity (rare with good randomness)
- More memory overhead than arrays or simple linked lists
- Performance depends on quality of random number generator
- Not as cache-friendly as arrays for random access
- Pointer-heavy structure can be slow on modern CPUs
- No guaranteed worst-case bounds (probabilistic only)

## Frameworks or libraries using it

- **Rust**: `skiplist` crate, `crossbeam-skiplist` for concurrent version
- **Redis**: Sorted sets (ZSET) use skip lists internally
- **LevelDB/RocksDB**: MemTable implementation uses skip lists
- **Java**: ConcurrentSkipListMap and ConcurrentSkipListSet
- **Apache Lucene**: Uses skip lists for posting list compression
- **MemSQL**: Skip list based indexes
- **QuestDB**: Uses skip lists for time series indexing
- **HBase**: MemStore uses skip lists
