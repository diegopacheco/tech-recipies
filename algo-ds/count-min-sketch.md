# Count-Min Sketch

## What is it?

A Count-Min Sketch (CMS) is a probabilistic data structure used for estimating the frequency of elements in a data stream. It provides approximate counts using sub-linear space, making it ideal for scenarios where exact counting would require too much memory. Invented by Graham Cormode and S. Muthu Muthukrishnan in 2003, it trades accuracy for space efficiency, providing counts that never underestimate but may overestimate the true frequency.

## How it works?

1. Create a 2D array of counters with d rows (hash functions) and w columns (width)
2. Choose d pairwise independent hash functions, one for each row
3. To increment count for an element: hash it with each function and increment the corresponding counter in each row
4. To query count for an element: hash it with each function and return the minimum value across all rows
5. The minimum is taken because collisions only add to counts, never subtract
6. Error bounds: with probability 1-δ, error ≤ εN where N is total count, w=⌈e/ε⌉, d=⌈ln(1/δ)⌉

The "count-min" name comes from incrementing counts and taking the minimum for queries.

## Use cases?

- Network traffic analysis (heavy hitters detection)
- Natural language processing (word frequency estimation)
- Database query optimization (frequency histograms)
- Click stream analysis
- Real-time analytics on streaming data
- Detecting trending topics in social media
- DDoS attack detection
- Cache admission policies
- Approximate join size estimation
- Finding frequent items in data streams

## Code Sample (Rust)

```rust
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

struct CountMinSketch {
    counters: Vec<Vec<u64>>,
    width: usize,
    depth: usize,
    seeds: Vec<u64>,
}

impl CountMinSketch {
    fn new(width: usize, depth: usize) -> Self {
        let seeds: Vec<u64> = (0..depth).map(|i| i as u64 * 0x9e3779b97f4a7c15).collect();
        CountMinSketch {
            counters: vec![vec![0; width]; depth],
            width,
            depth,
            seeds,
        }
    }

    fn with_error_rate(epsilon: f64, delta: f64) -> Self {
        let width = (std::f64::consts::E / epsilon).ceil() as usize;
        let depth = (1.0 / delta).ln().ceil() as usize;
        Self::new(width, depth)
    }

    fn hash<T: Hash>(&self, item: &T, seed: u64) -> usize {
        let mut hasher = DefaultHasher::new();
        seed.hash(&mut hasher);
        item.hash(&mut hasher);
        (hasher.finish() as usize) % self.width
    }

    fn increment<T: Hash>(&mut self, item: &T) {
        self.add(item, 1);
    }

    fn add<T: Hash>(&mut self, item: &T, count: u64) {
        for i in 0..self.depth {
            let index = self.hash(item, self.seeds[i]);
            self.counters[i][index] = self.counters[i][index].saturating_add(count);
        }
    }

    fn estimate<T: Hash>(&self, item: &T) -> u64 {
        let mut min = u64::MAX;
        for i in 0..self.depth {
            let index = self.hash(item, self.seeds[i]);
            min = min.min(self.counters[i][index]);
        }
        min
    }

    fn merge(&mut self, other: &CountMinSketch) {
        for i in 0..self.depth {
            for j in 0..self.width {
                self.counters[i][j] = self.counters[i][j].saturating_add(other.counters[i][j]);
            }
        }
    }

    fn total_count(&self) -> u64 {
        self.counters[0].iter().sum()
    }

    fn memory_usage(&self) -> usize {
        self.width * self.depth * std::mem::size_of::<u64>()
    }
}

struct HeavyHitters {
    cms: CountMinSketch,
    threshold: f64,
    total: u64,
    candidates: std::collections::HashMap<String, u64>,
}

impl HeavyHitters {
    fn new(epsilon: f64, delta: f64, threshold: f64) -> Self {
        HeavyHitters {
            cms: CountMinSketch::with_error_rate(epsilon, delta),
            threshold,
            total: 0,
            candidates: std::collections::HashMap::new(),
        }
    }

    fn add(&mut self, item: &str) {
        self.cms.increment(&item);
        self.total += 1;
        let estimate = self.cms.estimate(&item);
        if estimate as f64 >= self.threshold * self.total as f64 {
            self.candidates.insert(item.to_string(), estimate);
        }
    }

    fn get_heavy_hitters(&self) -> Vec<(&String, u64)> {
        self.candidates
            .iter()
            .filter(|(k, _)| self.cms.estimate(k.as_str()) as f64 >= self.threshold * self.total as f64)
            .map(|(k, _)| (k, self.cms.estimate(k.as_str())))
            .collect()
    }
}

fn main() {
    let mut cms = CountMinSketch::with_error_rate(0.001, 0.01);

    println!("Width: {}, Depth: {}", cms.width, cms.depth);
    println!("Memory: {} bytes", cms.memory_usage());

    for _ in 0..1000 {
        cms.increment(&"apple");
    }
    for _ in 0..500 {
        cms.increment(&"banana");
    }
    for _ in 0..100 {
        cms.increment(&"cherry");
    }

    println!("apple estimate: {}", cms.estimate(&"apple"));
    println!("banana estimate: {}", cms.estimate(&"banana"));
    println!("cherry estimate: {}", cms.estimate(&"cherry"));
    println!("grape estimate: {}", cms.estimate(&"grape"));

    let mut hh = HeavyHitters::new(0.001, 0.01, 0.1);
    let items = ["a", "a", "a", "a", "a", "b", "b", "c", "d", "e"];
    for item in &items {
        hh.add(item);
    }
    println!("Heavy hitters: {:?}", hh.get_heavy_hitters());
}
```

## Pros and Cons

### Pros
- Sub-linear space complexity O(1/ε * log(1/δ))
- O(1) time for both update and query operations
- Never underestimates (only overestimates due to collisions)
- Mergeable (can combine sketches from distributed systems)
- Simple to implement and understand
- Works well with streaming data
- Bounded error guarantees

### Cons
- Only provides approximate counts (not exact)
- Can only overestimate, never underestimate
- No way to delete or decrement counts in basic version
- High-frequency items cause more collisions affecting others
- Cannot enumerate stored items
- Memory usage depends on desired accuracy
- Not suitable when exact counts are required

## Frameworks or libraries using it

- **Rust**: `streaming-algorithms` crate, `probabilistic-collections` crate
- **Apache Spark**: CountMinSketch class for approximate aggregations
- **Apache Flink**: Count-Min Sketch for stream processing
- **Redis**: RedisBloom module includes CMS support
- **PostgreSQL**: Approximate query processing extensions
- **Apache Druid**: Approximate TopN queries
- **Twitter Algebird**: Scala library with CMS implementation
- **Google Sawzall**: Uses CMS for log analysis
- **Presto/Trino**: Approximate frequency functions
- **ClickHouse**: Approximate counting functions
