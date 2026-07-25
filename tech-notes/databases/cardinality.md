# Cardinality

## What is it?

Cardinality is the **number of distinct values** in a set. In databases the word is used in three related but different senses, and mixing them up is the source of most confusion:

1. **Column cardinality** — how many distinct values a column holds. `country` in a users table might have 190 distinct values; `email` has as many distinct values as there are rows.
2. **Table cardinality** — how many rows a table (or an intermediate result set) holds. This is what a query planner means when it says "estimated cardinality 12,431".
3. **Relationship cardinality** — the 1:1, 1:N, N:M multiplicity between two entities in a data model. This is the ER-diagram meaning.

The first sense is the one that drives index design and monitoring cost, and it is the subject of this note.

```
  users (1,000,000 rows)
  ┌──────────────┬───────────────────┬───────────────────────────────┐
  │ column       │ distinct values   │ cardinality                   │
  ├──────────────┼───────────────────┼───────────────────────────────┤
  │ is_active    │ 2                 │ very low  (boolean)           │
  │ status       │ 5                 │ low       (enum)              │
  │ country      │ 190               │ medium                        │
  │ city         │ 40,000            │ high                          │
  │ user_id      │ 1,000,000         │ maximum   (unique)            │
  │ request_id   │ unbounded         │ unbounded (grows forever)     │
  └──────────────┴───────────────────┴───────────────────────────────┘
```

### Selectivity — the number that actually matters

Cardinality on its own is meaningless without the row count next to it. The useful derived metric is **selectivity**:

```
  selectivity = distinct_values / total_rows          (0 .. 1)

  average rows returned per value = total_rows / distinct_values
```

- `is_active` on 1M rows: selectivity `2/1,000,000 = 0.000002`. Each value matches ~500,000 rows.
- `user_id` on 1M rows: selectivity `1.0`. Each value matches exactly 1 row.

A predicate is worth an index roughly when it filters down to a small fraction of the table (in practice under ~5–10%, the point where random I/O per row beats a sequential scan). Selectivity is what tells you that.

### Measuring it

```sql
SELECT count(*) AS rows,
       count(DISTINCT country) AS distinct_country,
       count(DISTINCT country)::float / count(*) AS selectivity
FROM users;
```

Exact `COUNT(DISTINCT ...)` is expensive on large tables — it requires a sort or a hash of the whole column. Cheaper options:

```sql
SELECT attname, n_distinct, correlation
FROM pg_stats
WHERE tablename = 'users';
```

`pg_stats.n_distinct` is the planner's own estimate, gathered by `ANALYZE` from a sample:

- **positive** value = the estimated absolute number of distinct values
- **negative** value = a *ratio* to the row count (`-1` means "unique, scales with the table")

The negative form exists so the estimate stays correct as the table grows. For approximate counting at scale, **HyperLogLog** (Redis `PFCOUNT`, Postgres `postgresql-hll`, Presto `approx_distinct`) gives ~2% error in a few kilobytes of state instead of a full sort.

## What is high cardinality?

"High cardinality" means the number of distinct values is **large relative to the row count**, or worse, **unbounded** — it grows without limit as the system runs.

```
  LOW                        MEDIUM                      HIGH                     UNBOUNDED
  ─────────────────────────────────────────────────────────────────────────────────────────►
  boolean, enum,             country, product            city, customer_id,       request_id, trace_id,
  status, region,            category, http_code         email, IP address        session_id, timestamp,
  environment                                                                     full URL, error message
      2..20 values              20..10k values            10k..millions            grows forever
```

The critical distinction is **bounded vs unbounded**, not big vs small:

- `customer_id` is high cardinality but *bounded* by your customer count. It grows slowly and predictably.
- `trace_id` is *unbounded*. Every request mints a new value. There is no ceiling.

Bounded high cardinality is usually fine and often exactly what you want (unique keys are maximum cardinality by definition). Unbounded cardinality is what breaks systems, because every sizing assumption downstream is a function of the distinct-value count.

### Why high cardinality is a problem at all

It costs differently depending on where it lands:

| Where | What high cardinality costs |
|---|---|
| B-tree index | Larger index, more pages, slower writes — but *better* reads |
| Bitmap index | Explodes: one bitmap per distinct value |
| Query planner | Estimation error, which produces bad join orders |
| GROUP BY / DISTINCT | Hash table that no longer fits in `work_mem`, spills to disk |
| Partition key | Thousands of tiny partitions, planning-time overhead |
| Monitoring labels | Series explosion — memory, index, and cost grow multiplicatively |
| Distributed cache | Poor hit rate, unbounded key space |

The same property that makes a column *great* for an index (each value points at one row) makes it *catastrophic* as a metric label (each value creates a new time series held in RAM).

## High cardinality in indexes

### High cardinality is what makes a B-tree worth having

An index is only used when the planner believes it will read fewer pages than a sequential scan. With low cardinality, it will not.

```
  SELECT * FROM users WHERE is_active = true;     -- 500,000 of 1,000,000 rows
  ┌──────────────────────────────────────────────────────────────────┐
  │ index scan:  500k index entries  ──►  500k random heap fetches   │  slower
  │ seq scan:    1M sequential reads, no random I/O                  │  planner picks this
  └──────────────────────────────────────────────────────────────────┘

  SELECT * FROM users WHERE email = 'a@x.com';    -- 1 of 1,000,000 rows
  ┌──────────────────────────────────────────────────────────────────┐
  │ index scan:  ~3 page descents  ──►  1 heap fetch                 │  planner picks this
  │ seq scan:    1M sequential reads                                 │  far slower
  └──────────────────────────────────────────────────────────────────┘
```

The rule of thumb: **index the high-cardinality columns**. An index on a boolean is almost always dead weight — it is maintained on every write and never used on read.

### Composite index column order

In a multi-column B-tree, the leading column determines what the index can seek on. The classic guidance is "most selective column first", but the real rule is:

1. Columns used with **equality** predicates come first.
2. Among those, put the one that **narrows the result the most** first.
3. Range (`>`, `<`, `BETWEEN`) and `ORDER BY` columns come last — everything after the first range column can no longer be used for seeking.

```
  WHERE tenant_id = ? AND status = ? AND created_at > ?

  INDEX (tenant_id, status, created_at)   ─► seek on tenant+status, range scan on time   good
  INDEX (status, created_at, tenant_id)   ─► seek on 5 statuses, then filter everything  bad
```

A low-cardinality column is not useless in a composite index — as a *secondary* column it still cuts the scan, and as a leading column it can serve `ORDER BY` or partition-like grouping. It is only useless *alone*.

### Where high cardinality hurts an index

- **Write amplification**: every insert updates every index. A unique high-cardinality index on a hot table means random page writes, page splits, and WAL volume.
- **Size**: an index on a UUID column stores 16 bytes plus overhead per row and is essentially the size of the table's key space. Random UUIDv4 keys also destroy insert locality — use UUIDv7/ULID (time-ordered) so inserts append to the right-hand edge of the tree instead of splitting random pages.
- **Bitmap indexes invert the rule**: Oracle bitmap indexes, and column-store bitmap encodings, allocate one bitmap per distinct value. They are *excellent* at low cardinality and unusable at high cardinality.
- **Bad estimates on correlated columns**: the planner assumes independence. `WHERE city = 'Paris' AND country = 'France'` gets estimated as `sel(city) * sel(country)` — a number far smaller than reality, because city already implies country. The fix in Postgres is extended statistics:

```sql
CREATE STATISTICS city_country (dependencies, ndistinct)
  ON city, country FROM users;
ANALYZE users;
```

### Index type by cardinality

| Index type | Best cardinality | Notes |
|---|---|---|
| B-tree | high | The default; equality, ranges, sorting |
| Hash | high | Equality only, no ranges |
| Bitmap (Oracle) | low | One bitmap per value; deadly on high cardinality |
| BRIN | any, needs physical ordering | Tiny; stores min/max per block range |
| GIN / inverted | high, multi-valued | Arrays, JSONB, full text |
| Partial (`WHERE`) | rescues low cardinality | Index only the rare value |
| Bloom | many low-cardinality columns | Probabilistic, arbitrary column combinations |

### The low-cardinality escape hatch: partial indexes

When a column is low cardinality but the distribution is *skewed*, the rare value is still worth indexing:

```sql
CREATE INDEX idx_orders_pending ON orders (created_at)
  WHERE status = 'pending';
```

If 99.9% of orders are `completed`, this index contains only the 0.1% that matter. It is small, cheap to maintain, and highly selective — low cardinality turned into high selectivity.

## High cardinality in monitoring systems

This is where cardinality goes from "a tuning consideration" to "the thing that took down the monitoring stack".

### The unit of storage is a time series, not a metric

In Prometheus and every system that copied its model, a **time series is identified by the metric name plus the full set of label key/value pairs**. Change one label value and it is a different series, with its own index entry, its own chunk buffer, and its own memory footprint.

```
  http_requests_total{method="GET", status="200", handler="/api/users"}   ─► series #1
  http_requests_total{method="GET", status="500", handler="/api/users"}   ─► series #2
  http_requests_total{method="POST",status="200", handler="/api/users"}   ─► series #3
```

### Series count is a product, not a sum

Total series = the **cartesian product** of the distinct values of every label.

```
  method(5) × status(8) × handler(40) × pod(20) × region(3)

     5 × 8 × 40 × 20 × 3  =  96,000 series          fine

  now add user_id (100,000 distinct):

     96,000 × 100,000  =  9,600,000,000 series      the process dies
```

Each label you add multiplies. Adding one unbounded label does not increase cardinality — it *replaces* your cardinality budget with the size of that label's value space.

### What it actually costs

Rough numbers for Prometheus, useful for capacity math:

```
  ~ 1–3 KB of RAM per active series (head chunk + index + labels)
  ~ 1–2 bytes per sample on disk after compression

    1,000,000 active series  ─►  ~2–3 GB RAM just to hold the head block
   10,000,000 active series  ─►  OOM on most realistic hardware
```

Beyond memory, high cardinality degrades:

- **Query latency**: PromQL resolves a matcher by intersecting posting lists in the inverted index. More series means longer postings and more intersection work. A `sum by (job)` over 5M series has to touch 5M series.
- **Ingestion**: every scrape does a label-set hash lookup; a large series map means cache misses.
- **WAL and compaction**: more series means more index churn per block.
- **Vendor bill**: Datadog, New Relic, Grafana Cloud and Chronosphere bill primarily on **custom metrics = unique series**. A single label added to a common metric can multiply an invoice.

### Churn: the cardinality you forgot to count

**Churn** is series that are created and then go stale. It is the silent killer, because the *active* series count looks reasonable while the total series in the index keeps climbing.

```
  pod="api-7f9c8b-x4k2q"   ─►  new pod name on every deploy
  version="a1b2c3d"        ─►  new value on every release
  container_id             ─►  new value on every restart

  deploy 20 times a day × 50 pods = 1,000 dead-but-indexed series per day, per metric
```

Prometheus keeps stale series in the index for the retention period even after they stop receiving samples. Query planning still walks them.

### The label values that always cause incidents

```
  NEVER put these in a metric label:
  ──────────────────────────────────
  user_id, customer_id, account_id     unbounded, grows with the business
  request_id, trace_id, span_id        unbounded by definition
  session_id, order_id, transaction_id unbounded
  email, IP address, URL, query string  unbounded and often PII
  timestamp, epoch, date                unbounded and already the x-axis
  raw error message / stack trace       unbounded free text
  full file path, SQL statement         effectively unbounded
```

The tell is simple: **if the number of distinct values grows with traffic or time, it is not a label**. Metrics answer "how many / how fast / how bad" over a *bounded* set of dimensions. Identifying a specific request is the job of logs and traces.

### The unbounded-path trap

The most common accidental explosion is HTTP path labels:

```
  handler="/api/users/8f21c0/orders/993/items/44"    ─► one series per URL, forever

  handler="/api/users/{id}/orders/{oid}/items/{iid}" ─► one series, correct
```

Always label the **route template**, never the resolved path. The same applies to SQL: label the statement shape, not the statement with literals in it.

## How to fix it

### 1. Find it before you fix it

```promql
topk(20, count by (__name__)({__name__=~".+"}))

count(count by (label_name)(metric_name))

sum(scrape_samples_scraped) by (job)

prometheus_tsdb_head_series
```

```
  Tools:
  ──────
  promtool tsdb analyze /path/to/data     highest-cardinality metrics and labels in a block
  /status/tsdb  endpoint                   top 10 label names and values by series count
  Grafana Mimir / Cortex "cardinality API" per-tenant label cardinality
  pg_stats.n_distinct                      per-column cardinality estimate in Postgres
```

Rule: never start deleting labels until you know which metric and which label owns the series count. It is almost always one or two.

### 2. Fixes for monitoring cardinality

- **Drop the label at the source.** The cheapest fix. Remove it from the instrumentation, not from the pipeline.
- **Relabel it away at scrape time** when you do not control the source:

```yaml
metric_relabel_configs:
  - source_labels: [user_id]
    action: labeldrop
  - source_labels: [__name__]
    regex: 'debug_.*'
    action: drop
```

- **Bucket the value instead of keeping it raw.** Replace `latency_ms="437"` with a histogram. Replace `customer_id` with `customer_tier="enterprise|pro|free"`. Replace `status="503"` with `status_class="5xx"` where the exact code is not actionable.
- **Move the identity to the right tool.** High-cardinality identifiers belong in **logs** (Loki, Elasticsearch — indexed by time, searched by content) or **traces** (Tempo, Jaeger — indexed by trace ID). Exemplars are the bridge: they attach a trace ID to a histogram bucket without creating a series.
- **Aggregate at write time with recording rules**, then drop the raw series:

```yaml
groups:
  - name: aggregations
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job, status_class) (rate(http_requests_total[5m]))
```

- **Enforce limits so an explosion is a rejected write, not an outage:**

```yaml
sample_limit: 5000
label_limit: 20
label_value_length_limit: 128
target_limit: 500
```

  Mimir/Cortex/Thanos add per-tenant `max_global_series_per_user`. Fail the ingest, page the owner, keep the cluster up.

- **Stop the churn**: label with the `deployment`/`statefulset` name rather than the pod name, drop `container_id`, and expose the build version as a separate `build_info` gauge (one series) instead of a label on every metric.
- **Change the storage engine when the cardinality is genuinely required.** VictoriaMetrics, Mimir, Chronosphere and M3 handle far more series per node than vanilla Prometheus. This is the last resort, not the first move — it makes the problem affordable rather than absent.

### 3. Fixes for index and query cardinality

- **Drop indexes on low-cardinality columns.** Check `pg_stat_user_indexes.idx_scan = 0` and remove them; they only cost writes.
- **Replace them with partial indexes** on the selective value (`WHERE status = 'pending'`).
- **Reorder composite indexes** so equality columns lead and range columns trail.
- **Add extended statistics** for correlated columns so the planner stops multiplying selectivities that are not independent.
- **Raise the statistics target** on a skewed high-cardinality column so more values land in the MCV list:

```sql
ALTER TABLE events ALTER COLUMN tenant_id SET STATISTICS 1000;
ANALYZE events;
```

- **Use approximate distinct counts** (`HyperLogLog`, `approx_distinct`) for dashboards that ask "how many unique X" over billions of rows.
- **Watch `work_mem` on high-cardinality `GROUP BY`.** A grouping key with millions of distinct values builds a hash table that spills; either raise `work_mem` for that query or pre-aggregate.
- **Choose partition keys with low-to-medium cardinality.** Partitioning by `customer_id` across 100k customers creates 100k partitions and makes planning slower than the scan it was meant to avoid. Partition by time or by a hashed bucket count you choose.
- **Prefer time-ordered UUIDs (v7/ULID)** over UUIDv4 for primary keys so high cardinality does not also mean random write locality.

## Pros

- **High-cardinality columns make indexes effective** — selective predicates are the whole reason B-trees pay off.
- **Uniqueness is maximum cardinality** — primary keys, natural keys, and dedup keys depend on it.
- **Fine-grained dimensions enable precise analysis** — per-customer breakdowns are genuinely valuable in a system built to store them (a warehouse, a log store).
- **Cardinality estimates drive the query planner** — accurate distinct counts produce good join orders and access paths.
- **Sharding and partitioning need enough cardinality** to distribute load evenly across nodes.

## Cons

- **Series explosion in metrics** — cost grows as the product of label cardinalities, not the sum.
- **Memory and index pressure** — RAM per series, index size per distinct value, page splits per random key.
- **Planner estimation error** — high-cardinality and correlated columns are where estimates go wrong, and a wrong estimate becomes a wrong plan.
- **Spills to disk** — `GROUP BY`/`DISTINCT` over many distinct values exceeds the hash memory budget.
- **Vendor cost** — observability vendors bill on unique series; cardinality is a line item.
- **Bitmap indexes and column-store dictionaries degrade** as distinct values grow.
- **Cache dilution** — an unbounded key space produces a low hit rate no matter how large the cache.
- **PII risk** — the labels people are tempted to add (email, user ID, URL) are also the ones that leak personal data into a system with no access controls.

## Use Cases

- **Index design**: pick which columns get a B-tree, which get a partial index, and which get nothing.
- **Composite index ordering**: order columns by predicate type and selectivity.
- **Query plan debugging**: compare `EXPLAIN ANALYZE` estimated vs actual rows to find the misestimated cardinality that produced a bad join.
- **Metric label design**: decide what belongs in a label versus a log line or a trace attribute.
- **Observability cost control**: attribute spend to the metric and label that generate the series.
- **Capacity planning for TSDBs**: size RAM from active series count and forecast growth from churn.
- **Choosing a monitoring backend**: series-per-node limits are the deciding factor between Prometheus and VictoriaMetrics/Mimir.
- **Partition and shard key selection**: enough cardinality to spread load, not so much that partitions become unmanageable.
- **Data warehouse modeling**: dimension tables are low cardinality, fact tables are high — this drives encoding and compression choices.
- **Compression tuning**: low-cardinality columns compress with dictionary/RLE encoding; high-cardinality ones do not.
- **Deduplication and approximate analytics**: HyperLogLog sketches for unique-visitor style questions at scale.
