# Bloom Filters and Probabilistic Data Structures

## What is a Bloom Filter?

A Bloom Filter is a space-efficient probabilistic data structure that tests whether an element is a member of a set. It can tell you "definitely not in the set" or "probably in the set" but never gives false negatives. It uses a bit array and multiple hash functions to represent set membership without storing the actual elements. The tradeoff is a controllable false positive rate in exchange for massive space savings.

## Who created it? When?

The Bloom Filter was invented by **Burton Howard Bloom** in **1970** in his paper "Space/Time Trade-offs in Hash Coding with Allowable Errors" published in Communications of the ACM. Despite being over 50 years old it remains one of the most widely used data structures in databases, networks, and distributed systems.

## How it works?

1. **Initialization**:
   - Create a bit array of m bits, all set to 0
   - Choose k independent hash functions, each mapping to a position in [0, m-1]

2. **Insertion**:
   - Hash the element with all k hash functions
   - Set the bits at all k positions to 1

3. **Lookup**:
   - Hash the query element with all k hash functions
   - Check all k bit positions
   - If any bit is 0: element is definitely not in the set
   - If all bits are 1: element is probably in the set (may be a false positive)

4. **No Deletion**: Standard bloom filters do not support deletion because clearing a bit could affect other elements that hash to the same position

```
Insert "apple" with k=3 hash functions:

h1("apple") = 2    h2("apple") = 5    h3("apple") = 9

Bit array:  [0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]
                  ↑           ↑                 ↑

Insert "banana":
h1("banana") = 1   h2("banana") = 5   h3("banana") = 12

Bit array:  [0, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0]
                ↑  ↑        ↑              ↑        ↑

Lookup "cherry":
h1("cherry") = 2   h2("cherry") = 7   h3("cherry") = 12

Check: bit[2]=1 ✓  bit[7]=0 ✗  → Definitely NOT in set

Lookup "grape":
h1("grape") = 1    h2("grape") = 5    h3("grape") = 9

Check: bit[1]=1 ✓  bit[5]=1 ✓  bit[9]=1 ✓ → Probably in set (false positive!)
```

## Math Behind It

```
Given:
  n = number of elements to insert
  m = size of bit array
  k = number of hash functions

False positive probability:
  p ≈ (1 - e^(-kn/m))^k

Optimal number of hash functions:
  k = (m/n) * ln(2) ≈ 0.693 * (m/n)

Required bits per element for target false positive rate p:
  m/n = -1.44 * log2(p)

Practical sizing:
  1% false positive rate  → ~9.6 bits per element, k=7
  0.1% false positive rate → ~14.4 bits per element, k=10
  0.01% false positive rate → ~19.2 bits per element, k=13
```

## Variants and Related Structures

### 1. Counting Bloom Filter

Replaces each bit with a counter (typically 4 bits). Supports deletion by decrementing counters instead of clearing bits. Uses 4x more space than standard bloom filter.

- Supports: insert, lookup, delete
- Space: 4x standard bloom filter
- Risk: counter overflow with very frequent insertions
- Used by: network packet tracking, cache invalidation

### 2. Cuckoo Filter (Fan et al., 2014)

Stores fingerprints in a cuckoo hash table. Supports deletion natively. Better space efficiency than counting bloom filters. Can have slightly better lookup performance due to cache locality.

- Supports: insert, lookup, delete
- Space: more efficient than counting bloom filter for same false positive rate
- Limitation: has a maximum capacity, insertion can fail when full
- Used by: networking, deduplication systems

### 3. Count-Min Sketch (Cormode & Muthukrishnan, 2005)

Estimates the frequency of elements in a stream. Uses a 2D array of counters with multiple hash functions (one per row). Overestimates but never underestimates count. Space-efficient alternative to hash maps for frequency tracking.

- Query: estimated count of element (with overcount error)
- Space: O(w * d) where w = width, d = depth (number of hash functions)
- Error: ε = e/w overcount with probability 1 - δ where δ = e^(-d)
- Used by: network traffic monitoring, NLP word frequencies, database query optimization

### 4. HyperLogLog (Flajolet et al., 2007)

Estimates the cardinality (number of distinct elements) of a set. Uses only ~12KB of memory to count billions of unique elements with ~0.81% standard error. Works by observing the maximum number of leading zeros in hashed values.

- Query: approximate count of distinct elements
- Space: O(m) registers, typically 2^14 = 16384 registers using ~12KB
- Error: 1.04 / sqrt(m) standard error
- Used by: Redis PFCOUNT, database query planners, analytics (unique visitors)

### 5. Quotient Filter (Bender et al., 2012)

Stores fingerprints using quotienting. Supports deletion, merging, and resizing. Better cache performance than bloom filters due to data locality. Can be serialized and merged efficiently.

- Supports: insert, lookup, delete, merge, resize
- Space: slightly more than bloom filter per element
- Advantage: cache-friendly, mergeable, resizable
- Used by: SSD storage engines, log-structured merge trees

### 6. XOR Filter (Graf & Lemire, 2020)

Static filter built from a known set. Faster lookups and smaller than bloom filters. Cannot support dynamic insertions after construction. Uses 1.23 bits per key times fingerprint size.

- Supports: lookup only (static set)
- Space: ~1.23 * fingerprint bits per element
- Advantage: faster and smaller than bloom filter for static sets
- Limitation: set must be known at construction time
- Used by: read-only databases, static allow/deny lists

## Comparison

```
┌────────────────────┬─────────┬────────┬────────┬─────────┬──────────────────┐
│ Structure          │ Insert  │ Lookup │ Delete │ Space   │ Query Type       │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ Bloom Filter       │ O(k)    │ O(k)   │ No     │ ~10b/e  │ Membership       │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ Counting Bloom     │ O(k)    │ O(k)   │ O(k)   │ ~40b/e  │ Membership       │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ Cuckoo Filter      │ O(1)*   │ O(1)   │ O(1)   │ ~12b/e  │ Membership       │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ Count-Min Sketch   │ O(d)    │ O(d)   │ No     │ O(w*d)  │ Frequency        │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ HyperLogLog        │ O(1)    │ N/A    │ No     │ ~12KB   │ Cardinality      │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ Quotient Filter    │ O(1)*   │ O(1)*  │ O(1)*  │ ~13b/e  │ Membership       │
├────────────────────┼─────────┼────────┼────────┼─────────┼──────────────────┤
│ XOR Filter         │ Static  │ O(3)   │ No     │ ~9b/e   │ Membership       │
└────────────────────┴─────────┴────────┴────────┴─────────┴──────────────────┘
* amortized    b/e = bits per element    d = depth    w = width
```

## Pros

- **Extreme Space Efficiency**: Represents millions of elements in kilobytes
- **Constant Time Operations**: Insert and lookup are O(k) where k is small (3-10)
- **No False Negatives**: If the filter says "no", the element is definitely not present
- **Controllable Accuracy**: False positive rate is tunable by adjusting m and k
- **Simple Implementation**: Core logic is a bit array and hash functions
- **Cache Friendly**: Bit array fits in CPU cache for small to medium filters
- **Parallelizable**: Multiple hash functions can be computed independently
- **Union Support**: Two bloom filters can be merged with bitwise OR
- **No Stored Data**: Elements themselves are not stored, providing privacy benefits

## Cons

- **False Positives**: Will occasionally report elements as present when they are not
- **No Deletion**: Standard bloom filter cannot remove elements
- **No Enumeration**: Cannot list the elements that were inserted
- **No Count**: Cannot tell how many times an element was inserted (use Count-Min Sketch)
- **Fixed Size**: Bit array size must be chosen upfront, cannot grow dynamically
- **Hash Quality Matters**: Poor hash functions cause clustering and higher false positive rates
- **Tuning Required**: Must estimate n (number of elements) upfront to size m correctly
- **Overhead When Small**: For very small sets, a hash set is simpler and exact
- **No Intersection**: Cannot compute set intersection directly (unlike union)

## Use Cases

- **Database Query Optimization**: LSM-tree storage engines (LevelDB, RocksDB, Cassandra) use bloom filters to avoid reading SSTables that do not contain a key
- **Web Crawling**: Checking if a URL has already been visited without storing all URLs
- **Spell Checkers**: Fast check whether a word exists in the dictionary
- **Network Routing**: Checking packet membership in flow tables at line rate
- **CDN Cache**: Avoiding cache lookups for objects that were never cached
- **Malware Detection**: Chrome Safe Browsing uses bloom filters to check URLs against malware lists
- **Distributed Systems**: Checking if a key exists on a remote node before making a network call
- **Deduplication**: Detecting duplicate records in data pipelines without storing all seen records
- **Weak Password Detection**: Checking passwords against known breach lists without storing the list
- **Bioinformatics**: Checking k-mer existence in genome assembly without storing all sequences
- **Analytics Cardinality**: HyperLogLog for counting unique visitors, unique queries, unique IPs
- **Rate Limiting**: Count-Min Sketch for approximate per-user request counting
