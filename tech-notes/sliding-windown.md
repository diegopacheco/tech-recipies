# Sliding Window

## What is it?

Sliding Window is a technique used in algorithms and distributed systems where a fixed-size or variable-size window moves across a data structure (array, string, stream) to process elements in contiguous subsets. Instead of recalculating results from scratch for every position, the window slides by adding a new element and removing an old one, reducing redundant computation. The technique applies to both algorithmic problems (subarray/substring operations) and systems design (flow control, rate limiting, stream processing).

## Origins

The sliding window concept has two independent origins:
- **Networking**: Introduced in the **1970s** as part of TCP flow control and the Go-Back-N ARQ protocol for reliable data transmission
- **Algorithms**: Emerged as a well-known technique in competitive programming and algorithm design, popularized through problems involving subarrays and substrings

## How it works?

### Fixed-Size Window

1. Initialize the window with the first `k` elements
2. Compute the result for the initial window
3. Slide the window one position to the right: add the new element entering the window, remove the element leaving the window
4. Update the result incrementally
5. Repeat until the window reaches the end

```
Array: [1, 3, 5, 2, 8, 1, 4]    Window size k = 3

Step 1: [1, 3, 5] 2  8  1  4    sum = 9
Step 2:  1 [3, 5, 2] 8  1  4    sum = 9 - 1 + 2 = 10
Step 3:  1  3 [5, 2, 8] 1  4    sum = 10 - 3 + 8 = 15
Step 4:  1  3  5 [2, 8, 1] 4    sum = 15 - 5 + 1 = 11
Step 5:  1  3  5  2 [8, 1, 4]   sum = 11 - 2 + 4 = 13
```

### Variable-Size Window (Two Pointers)

1. Start with both left and right pointers at position 0
2. Expand the window by moving the right pointer
3. When a condition is violated, shrink the window by moving the left pointer
4. Track the optimal result during expansion and contraction
5. Repeat until the right pointer reaches the end

```
Find smallest subarray with sum >= 7:  [2, 1, 5, 2, 3, 2]

Expand right:  [2]                     sum = 2  (< 7, expand)
Expand right:  [2, 1]                  sum = 3  (< 7, expand)
Expand right:  [2, 1, 5]              sum = 8  (>= 7, record len=3, shrink)
Shrink left:      [1, 5]              sum = 6  (< 7, expand)
Expand right:     [1, 5, 2]           sum = 8  (>= 7, record len=3, shrink)
Shrink left:         [5, 2]           sum = 7  (>= 7, record len=2, shrink)
Shrink left:            [2]           sum = 2  (< 7, expand)
Expand right:           [2, 3]        sum = 5  (< 7, expand)
Expand right:           [2, 3, 2]     sum = 7  (>= 7, record len=3, shrink)

Answer: minimum length = 2
```

## Algorithms and Patterns

### 1. Maximum/Minimum in Sliding Window (Monotonic Deque)

Finds the max or min element in every window of size `k`. Uses a deque (double-ended queue) that maintains elements in decreasing order for max (increasing for min). Each element enters and leaves the deque at most once giving O(n) total time.

- Time: O(n)
- Space: O(k)
- Problems: sliding window maximum, stock price monitoring

### 2. Fixed Window Aggregation (Sum, Average, Count)

Maintains a running aggregate that updates incrementally as the window slides. Subtract the outgoing element and add the incoming element.

- Time: O(n)
- Space: O(1)
- Problems: maximum average subarray, number of subarrays with exact sum

### 3. Variable Window with HashMap (Frequency Map)

Uses a hash map to track character or element frequencies within the window. Expands until a condition is met, then shrinks to find the optimal window.

- Time: O(n)
- Space: O(k) where k is the alphabet or unique element count
- Problems: longest substring without repeating characters, minimum window substring, longest substring with at most k distinct characters

### 4. Variable Window with Condition Check

Expands the right boundary and contracts the left boundary based on a boolean condition (sum threshold, constraint violation). No hash map needed when the condition is purely numeric.

- Time: O(n)
- Space: O(1)
- Problems: smallest subarray with sum >= target, maximum consecutive ones with k flips

### 5. Sliding Window with Counting

Counts the number of valid subarrays or substrings by calculating the contribution of each window position. Often uses the formula: count(at most k) - count(at most k-1).

- Time: O(n)
- Space: O(1) or O(k)
- Problems: subarrays with k different integers, count of nice subarrays

### 6. Sliding Window Rate Limiter (Systems Design)

Tracks request timestamps in a window. Fixed window divides time into buckets. Sliding window log stores every timestamp. Sliding window counter approximates by weighting the previous bucket.

- Fixed Window Counter: O(1) time, O(1) space, but has boundary burst problem
- Sliding Window Log: O(n) time, O(n) space, exact but memory intensive
- Sliding Window Counter: O(1) time, O(1) space, approximation with weighted average

## Complexity Comparison

```
┌──────────────────────────────┬───────────┬──────────┬───────────────────────┐
│ Approach                     │ Time      │ Space    │ When to Use           │
├──────────────────────────────┼───────────┼──────────┼───────────────────────┤
│ Brute Force (all subarrays)  │ O(n²)     │ O(1)     │ Never in practice     │
├──────────────────────────────┼───────────┼──────────┼───────────────────────┤
│ Fixed Window                 │ O(n)      │ O(1)     │ Window size is given  │
├──────────────────────────────┼───────────┼──────────┼───────────────────────┤
│ Variable Window (two ptr)    │ O(n)      │ O(1)     │ Min/max subarray size │
├──────────────────────────────┼───────────┼──────────┼───────────────────────┤
│ Window + HashMap             │ O(n)      │ O(k)     │ Frequency constraints │
├──────────────────────────────┼───────────┼──────────┼───────────────────────┤
│ Window + Monotonic Deque     │ O(n)      │ O(k)     │ Min/max in window     │
├──────────────────────────────┼───────────┼──────────┼───────────────────────┤
│ Window + Sorted Structure    │ O(n logk) │ O(k)     │ Median in window      │
└──────────────────────────────┴───────────┴──────────┴───────────────────────┘
```

## Pros

- **Linear Time**: Reduces O(n²) or O(n·k) brute force to O(n) for most problems
- **Space Efficient**: Fixed window needs O(1) extra space, variable window needs O(k) at most
- **Incremental Updates**: Avoids redundant computation by reusing previous window results
- **Versatile**: Applies to arrays, strings, streams, and time-series data
- **Simple Implementation**: Core logic is straightforward once the pattern is recognized
- **Stream Compatible**: Works on infinite streams since it only needs the current window in memory
- **Composable**: Can combine with hash maps, deques, heaps, or trees for complex constraints
- **Real-Time Friendly**: Constant time per element makes it suitable for low-latency systems

## Cons

- **Monotonicity Requirement**: Variable window only works when expanding/shrinking is monotonic (adding elements never makes a bad window good again or vice versa)
- **Not Universal**: Problems with non-contiguous subsets or elements that can be skipped do not fit the pattern
- **Edge Cases**: Off-by-one errors are common with window boundaries and pointer movement
- **Negative Numbers**: Some sum-based sliding window approaches break with negative numbers
- **Pattern Recognition**: Knowing when to apply sliding window versus other techniques is not always obvious
- **Variable Window Complexity**: The shrink condition can be tricky to define correctly for complex constraints
- **Systems Tradeoffs**: In rate limiting, fixed windows have burst problems, sliding logs use too much memory, and sliding counters are approximate
- **Ordering Dependency**: Elements must be processed in order, cannot parallelize easily

## Use Cases

- **Maximum Sum Subarray of Size K**: Finding the contiguous subarray of fixed length with the largest sum
- **Longest Substring Without Repeating Characters**: Classic variable window problem using a frequency map
- **Minimum Window Substring**: Finding the smallest window containing all characters of a target string
- **Network Flow Control**: TCP sliding window protocol for reliable ordered delivery
- **Rate Limiting**: API request throttling using sliding window counters or logs
- **Stream Processing**: Tumbling and sliding windows in Apache Flink, Kafka Streams, and Spark Streaming
- **Stock Price Analysis**: Finding max profit, moving averages, or price extremes in time windows
- **DNA Sequence Analysis**: Finding repeated sequences or patterns in genomic strings
- **Time-Series Monitoring**: Detecting anomalies within rolling time windows (alerting, SLOs)
- **Load Balancing**: Tracking request rates per server over rolling intervals
