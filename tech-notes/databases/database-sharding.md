# Database Sharding

## What is it?

Database sharding is a horizontal scaling strategy that partitions data across multiple independent database instances (shards), where each shard holds a subset of the total data. Unlike vertical scaling (bigger machine) or read replicas (copies of the same data), sharding splits the data itself — each shard is responsible for a disjoint range or set of rows. Queries and writes are routed to the correct shard based on a shard key. Sharding allows a database to scale beyond the limits of a single machine's CPU, memory, disk, and I/O.

## How it works?

### Architecture

```
                    ┌──────────────┐
                    │  Application │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │ Shard Router │
                    │ (proxy or    │
                    │  app logic)  │
                    └──┬───┬───┬───┘
                       │   │   │
          ┌────────────┘   │   └────────────┐
          ▼                ▼                ▼
   ┌────────────┐  ┌────────────┐  ┌────────────┐
   │  Shard 0   │  │  Shard 1   │  │  Shard 2   │
   │            │  │            │  │            │
   │ users      │  │ users      │  │ users      │
   │ A-H        │  │ I-P        │  │ Q-Z        │
   │            │  │            │  │            │
   │ (separate  │  │ (separate  │  │ (separate  │
   │  database  │  │  database  │  │  database  │
   │  instance) │  │  instance) │  │  instance) │
   └────────────┘  └────────────┘  └────────────┘

Each shard:
  - Has its own CPU, memory, disk
  - Handles a subset of the data
  - Can be on a different machine / region
  - Can have its own replicas for HA
```

### Shard Key Selection

```
The shard key determines which shard a row belongs to.

shard_id = hash(shard_key) % num_shards

Good shard keys:
  ✓ High cardinality (many distinct values)
  ✓ Even distribution (no hot spots)
  ✓ Present in most queries (avoid cross-shard queries)
  ✓ Immutable (changing shard key = moving data between shards)

Bad shard keys:
  ✗ Low cardinality (country: only ~200 values)
  ✗ Monotonically increasing (timestamp: all writes go to last shard)
  ✗ Skewed distribution (tenant_id where one tenant has 80% of data)
```

## Sharding Strategies

### 1. Hash-Based Sharding

```
shard_id = hash(user_id) % num_shards

user_id=1001  →  hash(1001) % 3 = 0  →  Shard 0
user_id=1002  →  hash(1002) % 3 = 2  →  Shard 2
user_id=1003  →  hash(1003) % 3 = 1  →  Shard 1

Pros:
  - Even distribution (good hash function → uniform)
  - Simple routing logic
  
Cons:
  - Range queries span all shards (hash destroys order)
  - Adding shards requires rehashing (see: consistent hashing)
```

### 2. Range-Based Sharding

```
Shard 0: user_id    1 - 1,000,000
Shard 1: user_id    1,000,001 - 2,000,000
Shard 2: user_id    2,000,001 - 3,000,000

Or by time:
Shard 0: 2024-01 to 2024-06
Shard 1: 2024-07 to 2024-12
Shard 2: 2025-01 to 2025-06

Pros:
  - Range queries go to a single shard
  - Natural for time-series data
  
Cons:
  - Hot spots (latest time shard gets all writes)
  - Uneven distribution if data is not uniform
```

### 3. Directory-Based Sharding

```
Lookup table maps each key to its shard:

┌──────────────┬───────────┐
│ tenant_id    │ shard_id  │
├──────────────┼───────────┤
│ acme         │ shard-0   │
│ beta         │ shard-1   │
│ gamma        │ shard-0   │
│ delta        │ shard-2   │
└──────────────┴───────────┘

Pros:
  - Full control over placement
  - Can move tenants between shards for rebalancing
  - No rehashing when adding shards
  
Cons:
  - Lookup table is a single point of failure
  - Extra hop for every query (lookup → route)
```

### 4. Geographic Sharding

```
Route by user location:

  US users     →  Shard US (us-east-1)
  EU users     →  Shard EU (eu-west-1)
  APAC users   →  Shard APAC (ap-southeast-1)

Pros:
  - Low latency (data near users)
  - Data residency compliance (GDPR → EU data in EU)
  
Cons:
  - Cross-region queries are expensive
  - Uneven load if traffic distribution is skewed
```

## Comparison of Strategies

```
┌──────────────────┬──────────────┬──────────────┬──────────────┐
│ Strategy         │ Distribution │ Range Queries│ Resharding   │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Hash-based       │ Even         │ All shards   │ Hard         │
│                  │              │ (scatter)    │ (rehash)     │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Range-based      │ Can be       │ Single shard │ Split range  │
│                  │ uneven       │ (ordered)    │ (medium)     │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Directory-based  │ Controlled   │ Lookup       │ Update table │
│                  │              │ required     │ (easy)       │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Geographic       │ Varies       │ Per-region   │ Move users   │
│                  │ by region    │              │ (medium)     │
└──────────────────┴──────────────┴──────────────┴──────────────┘
```

## Cross-Shard Queries

```
Problem: query needs data from multiple shards.

SELECT * FROM orders WHERE user_id = 1001 AND product_id = 5001

If sharded by user_id: single shard → fast
If sharded by product_id: single shard → fast
If query needs both: depends on shard key choice

Cross-shard JOIN:
  SELECT u.name, o.total
  FROM users u JOIN orders o ON u.id = o.user_id
  WHERE o.date > '2025-01-01'

  If users and orders are on different shards:
    → scatter query to all shards
    → gather results
    → merge and JOIN in the router / application
    → expensive

Strategies to avoid cross-shard queries:
  1. Co-locate related data on the same shard (same shard key)
  2. Denormalize (duplicate data across shards)
  3. Use a global table (small reference tables replicated to all shards)
  4. Accept eventual consistency (async materialized views)
```

## Resharding

```
When you need more shards (or fewer):

Before:  3 shards    (each handles 33% of data)
After:   6 shards    (each handles 16% of data)

Approaches:

1. Stop-the-world (simplest, worst downtime):
   - Take the system offline
   - Redistribute all data
   - Bring the system back up

2. Double-and-split:
   - Create replicas of each shard
   - Split each shard's range in half
   - Redirect traffic
   - Delete the now-unnecessary half from each shard

3. Live resharding:
   - Start copying data to new shards in the background
   - Dual-write: new writes go to both old and new shard
   - Once copy is complete, switch reads to new shards
   - Stop writes to old shards

4. Consistent hashing:
   - Use a hash ring instead of modulo
   - Adding a shard only moves ~1/N of the data
   - Used by DynamoDB, Cassandra, Riak

┌──────────────┐     add shard     ┌──────────────┐
│ 3 shards     │  ──────────────►  │ 4 shards     │
│ modulo: move │                   │ consistent   │
│ ~66% of data │                   │ hash: move   │
│              │                   │ ~25% of data │
└──────────────┘                   └──────────────┘
```

## Sharding in Practice

```
┌──────────────────┬───────────────────────────────────────────────┐
│ System           │ How it shards                                  │
├──────────────────┼───────────────────────────────────────────────┤
│ Vitess           │ MySQL sharding proxy. Range or hash on        │
│ (YouTube)        │ vindex (virtual index). Online resharding.    │
├──────────────────┼───────────────────────────────────────────────┤
│ Citus            │ PostgreSQL extension. Distributed tables.     │
│ (Microsoft)      │ Hash on distribution column. Co-location.    │
├──────────────────┼───────────────────────────────────────────────┤
│ CockroachDB      │ Automatic range-based sharding. Ranges       │
│                  │ split and merge. Raft for replication.        │
├──────────────────┼───────────────────────────────────────────────┤
│ MongoDB          │ Built-in sharding. Hash or range shard key.  │
│                  │ mongos router. Config servers for metadata.   │
├──────────────────┼───────────────────────────────────────────────┤
│ Cassandra        │ Consistent hashing with vnodes. Partition    │
│                  │ key determines node. Automatic rebalancing.  │
├──────────────────┼───────────────────────────────────────────────┤
│ DynamoDB         │ Automatic partitioning by partition key.      │
│                  │ Consistent hashing. Transparent to user.     │
├──────────────────┼───────────────────────────────────────────────┤
│ Spanner          │ Automatic range-based. Splits based on       │
│                  │ load. Global distribution with TrueTime.     │
├──────────────────┼───────────────────────────────────────────────┤
│ Application-level│ App decides shard routing. Used by Stripe,   │
│ (custom)         │ Pinterest, Instagram (early days).           │
└──────────────────┴───────────────────────────────────────────────┘
```

## Pros

- **Horizontal Scaling**: add shards to increase capacity linearly
- **Write Throughput**: writes distribute across shards (no single-writer bottleneck)
- **Data Locality**: geographic sharding reduces latency and meets data residency requirements
- **Isolation**: one shard's failure does not affect other shards
- **Large Datasets**: store more data than a single machine can hold
- **Cost Efficient**: use many commodity machines instead of one large expensive machine
- **Independent Scaling**: hot shards can be given more resources independently

## Cons

- **Complexity**: application must handle routing, cross-shard queries, and distributed transactions
- **Cross-Shard Queries**: JOINs across shards are expensive and complex
- **Resharding**: adding or removing shards requires data migration (downtime risk)
- **Shard Key Lock-In**: choosing the wrong shard key is expensive to fix
- **Distributed Transactions**: ACID across shards requires two-phase commit or saga patterns
- **Operational Overhead**: N shards = N databases to monitor, backup, upgrade, and patch
- **Hot Spots**: poor shard key selection leads to uneven load
- **No Global Ordering**: auto-increment IDs do not work across shards (need distributed ID generation)
- **Testing Difficulty**: reproducing cross-shard bugs requires multi-instance test environments

## Use Cases

- **Multi-Tenant SaaS**: shard by tenant_id — each tenant's data isolated on a shard
- **Social Networks**: shard by user_id — user's data (posts, friends, messages) on one shard
- **E-Commerce**: shard by customer_id or region — localize customer data
- **Gaming**: shard by game server / region — players interact within their shard
- **IoT**: shard by device_id or time range — distribute sensor data across nodes
- **Financial Services**: shard by account_id — account operations stay on one shard
- **Analytics**: shard by time range — parallelize queries across time windows
- **Content Platforms**: shard by content_id — distribute storage of media and metadata
