# Bitmap

## What is it?

A Bitmap (also called a bit array, bit vector, or bit set) is a data structure that uses individual bits to represent boolean values or set membership. Each bit in the array corresponds to a specific element or position, where 1 typically indicates presence/true and 0 indicates absence/false. Bitmaps provide an extremely space-efficient way to store and manipulate large sets of boolean flags.

## How it works?

1. Allocate a contiguous block of memory where each bit represents one element
2. To set a bit at position n: use bitwise OR with a mask (1 << n)
3. To clear a bit at position n: use bitwise AND with inverted mask ~(1 << n)
4. To check a bit at position n: use bitwise AND with mask (1 << n)
5. Set operations (union, intersection, difference) are performed using bitwise operators
6. The position in the bitmap directly maps to the value being represented

Modern implementations use 64-bit words for efficient CPU operations and cache utilization.

## Use cases?

- Database indexing (bitmap indexes for OLAP queries)
- Tracking user activity or feature flags
- Implementing sets with fast union/intersection operations
- Memory allocation tracking in operating systems
- Bloom filters and other probabilistic data structures
- Image processing and computer graphics
- Permission and capability flags
- Duplicate detection in large datasets
- Sparse matrix representations

## Code Sample (Rust)

```rust
struct Bitmap {
    bits: Vec<u64>,
    size: usize,
}

impl Bitmap {
    fn new(size: usize) -> Self {
        let num_words = (size + 63) / 64;
        Bitmap {
            bits: vec![0; num_words],
            size,
        }
    }

    fn set(&mut self, pos: usize) {
        if pos < self.size {
            self.bits[pos / 64] |= 1 << (pos % 64);
        }
    }

    fn clear(&mut self, pos: usize) {
        if pos < self.size {
            self.bits[pos / 64] &= !(1 << (pos % 64));
        }
    }

    fn get(&self, pos: usize) -> bool {
        if pos < self.size {
            (self.bits[pos / 64] & (1 << (pos % 64))) != 0
        } else {
            false
        }
    }

    fn count_ones(&self) -> usize {
        self.bits.iter().map(|w| w.count_ones() as usize).sum()
    }

    fn union(&self, other: &Bitmap) -> Bitmap {
        let mut result = Bitmap::new(self.size.max(other.size));
        for (i, (&a, &b)) in self.bits.iter().zip(other.bits.iter()).enumerate() {
            result.bits[i] = a | b;
        }
        result
    }

    fn intersection(&self, other: &Bitmap) -> Bitmap {
        let mut result = Bitmap::new(self.size.min(other.size));
        for (i, (&a, &b)) in self.bits.iter().zip(other.bits.iter()).enumerate() {
            result.bits[i] = a & b;
        }
        result
    }
}

fn main() {
    let mut bitmap = Bitmap::new(100);
    bitmap.set(5);
    bitmap.set(10);
    bitmap.set(42);

    println!("Bit 5: {}", bitmap.get(5));
    println!("Bit 7: {}", bitmap.get(7));
    println!("Count: {}", bitmap.count_ones());

    let mut other = Bitmap::new(100);
    other.set(10);
    other.set(20);

    let union = bitmap.union(&other);
    println!("Union count: {}", union.count_ones());
}
```

## Pros and Cons

### Pros
- Extremely memory efficient (1 bit per element)
- O(1) time for set, clear, and check operations
- Very fast set operations using CPU bitwise instructions
- Cache-friendly due to contiguous memory layout
- Hardware-accelerated population count (popcount) instructions
- Simple to implement and understand

### Cons
- Fixed size or requires resizing logic
- Sparse data wastes memory (use roaring bitmaps instead)
- Limited to representing integer-indexed elements
- Range of values must be known in advance
- Not suitable when universe size is very large and sparse
- No ordering information preserved

## Frameworks or libraries using it

- **Rust**: `bitvec` crate, `roaring` crate (Roaring Bitmaps), `fixedbitset` crate
- **Apache Lucene**: Uses bitmaps for document filtering and scoring
- **Redis**: BITFIELD and BITOP commands for bitmap operations
- **PostgreSQL**: Bitmap index scans for query optimization
- **Apache Druid**: Bitmap indexes for fast OLAP queries
- **ClickHouse**: Bitmap functions for analytics
- **RoaringBitmap**: Cross-language compressed bitmap library
- **Pilosa**: Distributed bitmap index database
