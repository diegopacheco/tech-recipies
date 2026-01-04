# Cuckoo Filter

## What is it?

A Cuckoo Filter is a probabilistic data structure for approximate set membership testing, similar to a Bloom filter but with additional capabilities. Named after the cuckoo bird's behavior of displacing eggs from nests, it uses cuckoo hashing to store fingerprints of items. Unlike Bloom filters, Cuckoo filters support deletion of elements while maintaining similar space efficiency and false positive rates. It was introduced by Fan, Andersen, Kaminsky, and Mitzenmacher in 2014.

## How it works?

1. Compute a fingerprint (short hash) of the item to be inserted
2. Calculate two candidate bucket positions using the fingerprint
3. If either bucket has space, insert the fingerprint there
4. If both buckets are full, randomly choose one and kick out existing fingerprint
5. The kicked-out fingerprint is relocated to its alternate bucket
6. Repeat relocation until an empty slot is found or max kicks reached
7. For lookup, check if the fingerprint exists in either candidate bucket
8. For deletion, remove the fingerprint from whichever bucket contains it

The key insight is that the alternate bucket can be computed from the current bucket and fingerprint, enabling deletions without storing the original item.

## Use cases?

- Deduplication in data pipelines
- Network packet filtering and routing
- Cache admission policies
- Database query filtering
- Spam detection systems
- URL shortener collision detection
- Distributed cache invalidation
- Malware signature detection
- Content delivery network edge filtering
- Real-time blacklist checking

## Code Sample (Rust)

```rust
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

const BUCKET_SIZE: usize = 4;
const MAX_KICKS: usize = 500;
const FINGERPRINT_SIZE: u8 = 8;

struct CuckooFilter {
    buckets: Vec<[u8; BUCKET_SIZE]>,
    num_buckets: usize,
}

impl CuckooFilter {
    fn new(capacity: usize) -> Self {
        let num_buckets = (capacity / BUCKET_SIZE).max(1);
        CuckooFilter {
            buckets: vec![[0; BUCKET_SIZE]; num_buckets],
            num_buckets,
        }
    }

    fn fingerprint<T: Hash>(item: &T) -> u8 {
        let mut hasher = DefaultHasher::new();
        item.hash(&mut hasher);
        let fp = (hasher.finish() % 255) as u8 + 1;
        fp
    }

    fn hash1<T: Hash>(&self, item: &T) -> usize {
        let mut hasher = DefaultHasher::new();
        item.hash(&mut hasher);
        (hasher.finish() as usize) % self.num_buckets
    }

    fn hash2(&self, index: usize, fp: u8) -> usize {
        let mut hasher = DefaultHasher::new();
        fp.hash(&mut hasher);
        (index ^ (hasher.finish() as usize)) % self.num_buckets
    }

    fn insert<T: Hash>(&mut self, item: &T) -> bool {
        let fp = Self::fingerprint(item);
        let i1 = self.hash1(item);
        let i2 = self.hash2(i1, fp);

        for slot in &mut self.buckets[i1] {
            if *slot == 0 {
                *slot = fp;
                return true;
            }
        }

        for slot in &mut self.buckets[i2] {
            if *slot == 0 {
                *slot = fp;
                return true;
            }
        }

        let mut current_index = if rand::random() { i1 } else { i2 };
        let mut current_fp = fp;

        for _ in 0..MAX_KICKS {
            let slot_index = rand::random::<usize>() % BUCKET_SIZE;
            std::mem::swap(&mut self.buckets[current_index][slot_index], &mut current_fp);
            current_index = self.hash2(current_index, current_fp);

            for slot in &mut self.buckets[current_index] {
                if *slot == 0 {
                    *slot = current_fp;
                    return true;
                }
            }
        }

        false
    }

    fn contains<T: Hash>(&self, item: &T) -> bool {
        let fp = Self::fingerprint(item);
        let i1 = self.hash1(item);
        let i2 = self.hash2(i1, fp);

        self.buckets[i1].contains(&fp) || self.buckets[i2].contains(&fp)
    }

    fn delete<T: Hash>(&mut self, item: &T) -> bool {
        let fp = Self::fingerprint(item);
        let i1 = self.hash1(item);
        let i2 = self.hash2(i1, fp);

        for slot in &mut self.buckets[i1] {
            if *slot == fp {
                *slot = 0;
                return true;
            }
        }

        for slot in &mut self.buckets[i2] {
            if *slot == fp {
                *slot = 0;
                return true;
            }
        }

        false
    }
}

fn main() {
    let mut filter = CuckooFilter::new(1000);

    filter.insert(&"hello");
    filter.insert(&"world");
    filter.insert(&"rust");

    println!("Contains 'hello': {}", filter.contains(&"hello"));
    println!("Contains 'world': {}", filter.contains(&"world"));
    println!("Contains 'missing': {}", filter.contains(&"missing"));

    filter.delete(&"hello");
    println!("After delete, contains 'hello': {}", filter.contains(&"hello"));
}
```

## Pros and Cons

### Pros
- Supports deletion (unlike standard Bloom filters)
- Better space efficiency than Bloom filters for same false positive rate
- Better lookup performance (only 2 memory accesses)
- Cache-friendly memory access pattern
- Predictable worst-case lookup time
- Lower false positive rate for same memory usage

### Cons
- Insertion can fail when filter is too full (typically >95% capacity)
- More complex implementation than Bloom filters
- Fingerprint collisions can cause false deletions
- Not suitable for counting occurrences
- Maximum capacity must be estimated in advance
- Relocation during insert can be slow in worst case

## Frameworks or libraries using it

- **Rust**: `cuckoofilter` crate, `scalable_cuckoo_filter` crate
- **Redis**: RedisBloom module includes Cuckoo filter support
- **Go**: `cuckoo` package for Cuckoo filter implementation
- **C++**: `cuckoofilter` library by CMU
- **Python**: `cuckoo` and `scalable-cuckoo-filter` packages
- **Apache Impala**: Uses Cuckoo filters for runtime filtering
- **Cassandra**: Considered for partition filtering
- **RocksDB**: Evaluated for SST file filtering
- **ScyllaDB**: Uses Cuckoo filters for efficient lookups
