# HyperLogLog

## What is it?

HyperLogLog (HLL) is a probabilistic data structure used for estimating the cardinality (count of distinct elements) of a multiset. It provides approximate counts using significantly less memory than exact counting methods. With just 12KB of memory, HyperLogLog can estimate cardinalities of billions of unique elements with a typical error rate of about 2%. It was invented by Philippe Flajolet and colleagues in 2007.

## How it works?

1. Hash each incoming element to produce a uniformly distributed bit string
2. Divide elements into m registers using the first few bits of the hash
3. For each element, count the number of leading zeros in the remaining hash bits
4. Store only the maximum leading zero count seen for each register
5. The cardinality estimate uses the harmonic mean of 2^(register values)
6. Apply bias corrections for small and large cardinalities

The intuition is that if you observe a hash with k leading zeros, you've likely seen about 2^k distinct elements. By using multiple registers and combining estimates, accuracy improves significantly.

## Use cases?

- Counting unique visitors to a website
- Counting unique search queries
- Database query optimization (estimating distinct values)
- Network traffic analysis (unique IP addresses)
- Social media analytics (unique user interactions)
- Detecting anomalies in streaming data
- Distributed systems cardinality estimation
- Real-time analytics dashboards
- A/B testing unique user counts

## Code Sample (Rust)

```rust
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};

struct HyperLogLog {
    registers: Vec<u8>,
    num_registers: usize,
    alpha: f64,
}

impl HyperLogLog {
    fn new(precision: u8) -> Self {
        let num_registers = 1 << precision;
        let alpha = match num_registers {
            16 => 0.673,
            32 => 0.697,
            64 => 0.709,
            _ => 0.7213 / (1.0 + 1.079 / num_registers as f64),
        };
        HyperLogLog {
            registers: vec![0; num_registers],
            num_registers,
            alpha,
        }
    }

    fn add<T: Hash>(&mut self, item: &T) {
        let mut hasher = DefaultHasher::new();
        item.hash(&mut hasher);
        let hash = hasher.finish();

        let index = (hash as usize) & (self.num_registers - 1);
        let remaining = hash >> (self.num_registers.trailing_zeros());
        let leading_zeros = (remaining.leading_zeros() + 1) as u8;

        if leading_zeros > self.registers[index] {
            self.registers[index] = leading_zeros;
        }
    }

    fn count(&self) -> f64 {
        let sum: f64 = self.registers
            .iter()
            .map(|&r| 2.0_f64.powi(-(r as i32)))
            .sum();

        let estimate = self.alpha * (self.num_registers as f64).powi(2) / sum;

        if estimate <= 2.5 * self.num_registers as f64 {
            let zeros = self.registers.iter().filter(|&&r| r == 0).count();
            if zeros > 0 {
                return self.num_registers as f64 * (self.num_registers as f64 / zeros as f64).ln();
            }
        }

        estimate
    }

    fn merge(&mut self, other: &HyperLogLog) {
        for (i, &val) in other.registers.iter().enumerate() {
            if val > self.registers[i] {
                self.registers[i] = val;
            }
        }
    }
}

fn main() {
    let mut hll = HyperLogLog::new(14);

    for i in 0..100_000 {
        hll.add(&i);
    }

    println!("Estimated cardinality: {:.0}", hll.count());
    println!("Actual cardinality: 100000");
    println!("Memory used: {} bytes", hll.registers.len());
}
```

## Pros and Cons

### Pros
- Extremely memory efficient (12KB for billions of elements)
- O(1) time complexity for add and count operations
- Mergeable (can combine estimates from distributed systems)
- Configurable precision vs memory trade-off
- Well-understood error bounds (standard error ~1.04/sqrt(m))
- Works well with streaming data

### Cons
- Approximate results only (not exact counts)
- Cannot remove elements or get intersection directly
- Error rate is probabilistic, not bounded
- Not suitable when exact counts are required
- Small cardinalities have higher relative error
- Hash function quality affects accuracy

## Frameworks or libraries using it

- **Rust**: `hyperloglog` crate, `probabilistic-collections` crate
- **Redis**: PFADD, PFCOUNT, PFMERGE commands for HyperLogLog
- **PostgreSQL**: `postgresql-hll` extension
- **Apache Spark**: approxCountDistinct function
- **Elasticsearch**: cardinality aggregation uses HyperLogLog++
- **Apache Flink**: HyperLogLog for approximate distinct counts
- **Google BigQuery**: APPROX_COUNT_DISTINCT uses HyperLogLog++
- **Presto/Trino**: approx_distinct function
- **Apache DataSketches**: HLL implementation with union operations
