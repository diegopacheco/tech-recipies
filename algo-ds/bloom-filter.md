# Bloom Filter

## What is it?

A Bloom Filter is a space-efficient probabilistic data structure designed to test whether an element is a member of a set. It can tell you with certainty that an element is NOT in the set, but can only tell you that an element is PROBABLY in the set (with a controllable false positive rate). Invented by Burton Howard Bloom in 1970, it uses multiple hash functions and a bit array to achieve extremely compact set representation.

## How it works?

1. Initialize a bit array of m bits, all set to 0
2. Choose k independent hash functions, each mapping elements to positions 0 to m-1
3. To add an element: compute all k hash values and set those bit positions to 1
4. To query an element: compute all k hash values and check if all positions are 1
5. If any position is 0, the element is definitely not in the set
6. If all positions are 1, the element is probably in the set (may be false positive)
7. The optimal number of hash functions k = (m/n) * ln(2), where n is expected elements

False positive probability: (1 - e^(-kn/m))^k

## Use cases?

- Database query optimization (avoiding disk lookups for non-existent keys)
- Web caching (checking if URL was seen before)
- Spell checkers (quick dictionary lookup)
- Network routers (packet filtering)
- Distributed systems (checking data existence across nodes)
- Cryptocurrency (Bitcoin SPV clients use Bloom filters)
- Malware detection (signature matching)
- Duplicate content detection
- Password breach checking
- CDN cache filtering

## Code Sample (Rust)

```rust
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

struct BloomFilter {
    bits: Vec<bool>,
    num_hashes: usize,
    size: usize,
}

impl BloomFilter {
    fn new(size: usize, num_hashes: usize) -> Self {
        BloomFilter {
            bits: vec![false; size],
            num_hashes,
            size,
        }
    }

    fn optimal(expected_elements: usize, false_positive_rate: f64) -> Self {
        let size = (-(expected_elements as f64 * false_positive_rate.ln()) / (2.0_f64.ln().powi(2))).ceil() as usize;
        let num_hashes = ((size as f64 / expected_elements as f64) * 2.0_f64.ln()).ceil() as usize;
        Self::new(size.max(1), num_hashes.max(1))
    }

    fn hash<T: Hash>(&self, item: &T, seed: usize) -> usize {
        let mut hasher = DefaultHasher::new();
        item.hash(&mut hasher);
        seed.hash(&mut hasher);
        (hasher.finish() as usize) % self.size
    }

    fn insert<T: Hash>(&mut self, item: &T) {
        for i in 0..self.num_hashes {
            let pos = self.hash(item, i);
            self.bits[pos] = true;
        }
    }

    fn contains<T: Hash>(&self, item: &T) -> bool {
        for i in 0..self.num_hashes {
            let pos = self.hash(item, i);
            if !self.bits[pos] {
                return false;
            }
        }
        true
    }

    fn false_positive_rate(&self, inserted: usize) -> f64 {
        let k = self.num_hashes as f64;
        let m = self.size as f64;
        let n = inserted as f64;
        (1.0 - (-k * n / m).exp()).powf(k)
    }

    fn union(&self, other: &BloomFilter) -> Option<BloomFilter> {
        if self.size != other.size || self.num_hashes != other.num_hashes {
            return None;
        }
        let mut result = BloomFilter::new(self.size, self.num_hashes);
        for i in 0..self.size {
            result.bits[i] = self.bits[i] || other.bits[i];
        }
        Some(result)
    }

    fn count_bits_set(&self) -> usize {
        self.bits.iter().filter(|&&b| b).count()
    }
}

fn main() {
    let mut filter = BloomFilter::optimal(1000, 0.01);

    println!("Filter size: {} bits", filter.size);
    println!("Number of hashes: {}", filter.num_hashes);

    filter.insert(&"apple");
    filter.insert(&"banana");
    filter.insert(&"cherry");

    println!("Contains 'apple': {}", filter.contains(&"apple"));
    println!("Contains 'banana': {}", filter.contains(&"banana"));
    println!("Contains 'grape': {}", filter.contains(&"grape"));

    for i in 0..100 {
        filter.insert(&i);
    }

    println!("Bits set: {}", filter.count_bits_set());
    println!("Estimated FP rate: {:.4}", filter.false_positive_rate(103));
}
```

## Pros and Cons

### Pros
- Extremely space-efficient compared to storing actual elements
- O(k) time complexity for both insert and lookup (k = number of hash functions)
- No false negatives (if it says "not in set", it's definitely not)
- Simple to implement and understand
- Union of two Bloom filters is trivial (bitwise OR)
- Configurable trade-off between space and false positive rate

### Cons
- Cannot delete elements (use Counting Bloom Filter for deletion)
- False positives are possible (though controllable)
- Cannot retrieve stored elements
- Cannot count exact number of elements
- Size must be determined in advance
- Performance degrades as filter fills up

## Frameworks or libraries using it

- **Rust**: `bloom` crate, `bloomfilter` crate, `probabilistic-collections`
- **Apache Cassandra**: Uses Bloom filters to reduce disk I/O
- **Apache HBase**: Bloom filters for StoreFile lookups
- **LevelDB/RocksDB**: SST file Bloom filters
- **Redis**: RedisBloom module for Bloom filter support
- **PostgreSQL**: bloom index extension
- **Apache Spark**: BloomFilter class for join optimization
- **Google Chrome**: Safe Browsing uses Bloom filters
- **Bitcoin**: SPV clients use Bloom filters for transaction filtering
- **Squid Proxy**: Cache digest uses Bloom filters
