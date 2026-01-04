# Segment Tree

## What is it?

A Segment Tree is a binary tree data structure used for storing intervals or segments, enabling efficient range queries and point updates. Each node represents a segment of the array, with the root representing the entire array and leaves representing individual elements. It answers queries like "what is the sum/min/max of elements from index i to j?" in O(log n) time while also supporting O(log n) updates. Segment trees are fundamental in competitive programming and database query optimization.

## How it works?

1. Build a binary tree where leaves are array elements
2. Each internal node stores aggregated information about its children (sum, min, max, etc.)
3. The root contains aggregate of entire array, left child covers first half, right child covers second half
4. Tree has 2n-1 nodes for an array of n elements (stored in array of size 4n for simplicity)
5. For range query [l, r]: recursively query left and right children, combine results for overlapping segments
6. For point update at index i: update leaf, then propagate changes up to root
7. Lazy propagation defers updates to enable O(log n) range updates

Node at index i has children at 2i+1 (left) and 2i+2 (right), parent at (i-1)/2.

## Use cases?

- Range sum/min/max queries
- Database query optimization
- Computational geometry (stabbing queries)
- Image processing (2D segment trees)
- Interval scheduling problems
- Stock price range queries
- Network bandwidth monitoring
- Game physics (collision detection ranges)
- Calendar/scheduling conflict detection
- Competitive programming contests

## Code Sample (Rust)

```rust
struct SegmentTree {
    tree: Vec<i64>,
    n: usize,
}

impl SegmentTree {
    fn new(arr: &[i64]) -> Self {
        let n = arr.len();
        let mut tree = vec![0; 4 * n];
        let mut st = SegmentTree { tree, n };
        st.build(arr, 0, 0, n - 1);
        st
    }

    fn build(&mut self, arr: &[i64], node: usize, start: usize, end: usize) {
        if start == end {
            self.tree[node] = arr[start];
        } else {
            let mid = (start + end) / 2;
            let left = 2 * node + 1;
            let right = 2 * node + 2;
            self.build(arr, left, start, mid);
            self.build(arr, right, mid + 1, end);
            self.tree[node] = self.tree[left] + self.tree[right];
        }
    }

    fn update(&mut self, index: usize, value: i64) {
        self.update_helper(0, 0, self.n - 1, index, value);
    }

    fn update_helper(&mut self, node: usize, start: usize, end: usize, index: usize, value: i64) {
        if start == end {
            self.tree[node] = value;
        } else {
            let mid = (start + end) / 2;
            let left = 2 * node + 1;
            let right = 2 * node + 2;
            if index <= mid {
                self.update_helper(left, start, mid, index, value);
            } else {
                self.update_helper(right, mid + 1, end, index, value);
            }
            self.tree[node] = self.tree[left] + self.tree[right];
        }
    }

    fn query(&self, l: usize, r: usize) -> i64 {
        self.query_helper(0, 0, self.n - 1, l, r)
    }

    fn query_helper(&self, node: usize, start: usize, end: usize, l: usize, r: usize) -> i64 {
        if r < start || l > end {
            return 0;
        }
        if l <= start && end <= r {
            return self.tree[node];
        }
        let mid = (start + end) / 2;
        let left = 2 * node + 1;
        let right = 2 * node + 2;
        let left_sum = self.query_helper(left, start, mid, l, r);
        let right_sum = self.query_helper(right, mid + 1, end, l, r);
        left_sum + right_sum
    }
}

struct LazySegmentTree {
    tree: Vec<i64>,
    lazy: Vec<i64>,
    n: usize,
}

impl LazySegmentTree {
    fn new(arr: &[i64]) -> Self {
        let n = arr.len();
        let mut st = LazySegmentTree {
            tree: vec![0; 4 * n],
            lazy: vec![0; 4 * n],
            n,
        };
        st.build(arr, 0, 0, n - 1);
        st
    }

    fn build(&mut self, arr: &[i64], node: usize, start: usize, end: usize) {
        if start == end {
            self.tree[node] = arr[start];
        } else {
            let mid = (start + end) / 2;
            self.build(arr, 2 * node + 1, start, mid);
            self.build(arr, 2 * node + 2, mid + 1, end);
            self.tree[node] = self.tree[2 * node + 1] + self.tree[2 * node + 2];
        }
    }

    fn push_down(&mut self, node: usize, start: usize, end: usize) {
        if self.lazy[node] != 0 {
            let mid = (start + end) / 2;
            let left = 2 * node + 1;
            let right = 2 * node + 2;

            self.tree[left] += self.lazy[node] * (mid - start + 1) as i64;
            self.tree[right] += self.lazy[node] * (end - mid) as i64;
            self.lazy[left] += self.lazy[node];
            self.lazy[right] += self.lazy[node];
            self.lazy[node] = 0;
        }
    }

    fn range_update(&mut self, l: usize, r: usize, value: i64) {
        self.range_update_helper(0, 0, self.n - 1, l, r, value);
    }

    fn range_update_helper(&mut self, node: usize, start: usize, end: usize, l: usize, r: usize, value: i64) {
        if r < start || l > end {
            return;
        }
        if l <= start && end <= r {
            self.tree[node] += value * (end - start + 1) as i64;
            self.lazy[node] += value;
            return;
        }
        self.push_down(node, start, end);
        let mid = (start + end) / 2;
        self.range_update_helper(2 * node + 1, start, mid, l, r, value);
        self.range_update_helper(2 * node + 2, mid + 1, end, l, r, value);
        self.tree[node] = self.tree[2 * node + 1] + self.tree[2 * node + 2];
    }

    fn query(&mut self, l: usize, r: usize) -> i64 {
        self.query_helper(0, 0, self.n - 1, l, r)
    }

    fn query_helper(&mut self, node: usize, start: usize, end: usize, l: usize, r: usize) -> i64 {
        if r < start || l > end {
            return 0;
        }
        if l <= start && end <= r {
            return self.tree[node];
        }
        self.push_down(node, start, end);
        let mid = (start + end) / 2;
        self.query_helper(2 * node + 1, start, mid, l, r) +
            self.query_helper(2 * node + 2, mid + 1, end, l, r)
    }
}

struct MinSegmentTree {
    tree: Vec<i64>,
    n: usize,
}

impl MinSegmentTree {
    fn new(arr: &[i64]) -> Self {
        let n = arr.len();
        let mut st = MinSegmentTree { tree: vec![i64::MAX; 4 * n], n };
        st.build(arr, 0, 0, n - 1);
        st
    }

    fn build(&mut self, arr: &[i64], node: usize, start: usize, end: usize) {
        if start == end {
            self.tree[node] = arr[start];
        } else {
            let mid = (start + end) / 2;
            self.build(arr, 2 * node + 1, start, mid);
            self.build(arr, 2 * node + 2, mid + 1, end);
            self.tree[node] = self.tree[2 * node + 1].min(self.tree[2 * node + 2]);
        }
    }

    fn query_min(&self, l: usize, r: usize) -> i64 {
        self.query_helper(0, 0, self.n - 1, l, r)
    }

    fn query_helper(&self, node: usize, start: usize, end: usize, l: usize, r: usize) -> i64 {
        if r < start || l > end {
            return i64::MAX;
        }
        if l <= start && end <= r {
            return self.tree[node];
        }
        let mid = (start + end) / 2;
        self.query_helper(2 * node + 1, start, mid, l, r)
            .min(self.query_helper(2 * node + 2, mid + 1, end, l, r))
    }
}

fn main() {
    let arr = vec![1, 3, 5, 7, 9, 11];
    let mut st = SegmentTree::new(&arr);

    println!("=== Sum Segment Tree ===");
    println!("Array: {:?}", arr);
    println!("Sum [1, 3]: {}", st.query(1, 3));
    println!("Sum [0, 5]: {}", st.query(0, 5));

    st.update(3, 10);
    println!("After update index 3 to 10:");
    println!("Sum [1, 3]: {}", st.query(1, 3));

    println!("\n=== Min Segment Tree ===");
    let min_st = MinSegmentTree::new(&arr);
    println!("Min [1, 4]: {}", min_st.query_min(1, 4));
    println!("Min [0, 5]: {}", min_st.query_min(0, 5));

    println!("\n=== Lazy Propagation ===");
    let mut lazy_st = LazySegmentTree::new(&arr);
    println!("Sum [0, 5]: {}", lazy_st.query(0, 5));
    lazy_st.range_update(1, 4, 10);
    println!("After adding 10 to range [1, 4]:");
    println!("Sum [0, 5]: {}", lazy_st.query(0, 5));
}
```

## Pros and Cons

### Pros
- O(log n) for both queries and updates
- Flexible (sum, min, max, GCD, or any associative operation)
- Supports lazy propagation for range updates
- Can be extended to 2D for matrix queries
- Persistent versions allow querying historical states
- Well-suited for dynamic data with frequent updates

### Cons
- O(n) space complexity (approximately 4n)
- More complex than simple prefix sums for static data
- Higher constant factor than Fenwick trees
- Not cache-friendly due to tree structure
- Overkill for simple problems without updates
- Implementation can be error-prone

## Frameworks or libraries using it

- **Rust**: `segment-tree` crate, `seg-tree` crate
- **C++ STL**: Not included but commonly implemented in competitive programming
- **Apache Druid**: Segment-based storage for time series
- **PostgreSQL**: GiST indexes use similar concepts
- **ClickHouse**: MergeTree engine with segment-like structure
- **Competitive Programming**: Codeforces, LeetCode, AtCoder problems
- **Game Engines**: Spatial queries and physics engines
- **Grafana/Prometheus**: Time-range aggregation queries
- **TimescaleDB**: Chunk-based time series with segment optimizations
