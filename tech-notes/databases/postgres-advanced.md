# PostgreSQL Advanced

## Partitioning

Partitioning splits a large table into smaller physical pieces while keeping a single logical table interface.

### Partition Types

**Range Partitioning** — splits by value ranges, ideal for time-series data.
```sql
CREATE TABLE events (
    id BIGSERIAL,
    created_at TIMESTAMPTZ NOT NULL,
    payload JSONB
) PARTITION BY RANGE (created_at);

CREATE TABLE events_2025_q1 PARTITION OF events
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE events_2025_q2 PARTITION OF events
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');
```

**List Partitioning** — splits by discrete values, useful for region or status.
```sql
CREATE TABLE orders (
    id BIGSERIAL,
    region TEXT NOT NULL,
    total NUMERIC
) PARTITION BY LIST (region);

CREATE TABLE orders_us PARTITION OF orders FOR VALUES IN ('us-east', 'us-west');
CREATE TABLE orders_eu PARTITION OF orders FOR VALUES IN ('eu-west', 'eu-central');
```

**Hash Partitioning** — distributes rows evenly, good for uniform spread.
```sql
CREATE TABLE sessions (
    id UUID NOT NULL,
    data JSONB
) PARTITION BY HASH (id);

CREATE TABLE sessions_p0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_p1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_p2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_p3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### Partition Pruning

PostgreSQL automatically skips irrelevant partitions when the WHERE clause matches the partition key.
```sql
EXPLAIN SELECT * FROM events WHERE created_at = '2025-02-15';
```
The query plan will only scan `events_2025_q1`, not all partitions.

Enable with `SET enable_partition_pruning = on;` (on by default since PG 11).

### Partition Indexes

Each partition gets its own indexes. You can create an index on the parent and it propagates.
```sql
CREATE INDEX ON events (created_at);
```

### Detach and Attach

```sql
ALTER TABLE events DETACH PARTITION events_2025_q1;
ALTER TABLE events ATTACH PARTITION events_2025_q1
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
```

Detaching is useful for archiving old data or bulk loading into a partition offline.

### Default Partition

Catches rows that don't match any defined partition.
```sql
CREATE TABLE events_default PARTITION OF events DEFAULT;
```

---

## JSONB

JSONB stores JSON in a decomposed binary format. Faster reads and indexing than JSON (which stores raw text).

### JSONB vs JSON

| Feature | JSON | JSONB |
|---|---|---|
| Storage | Raw text | Binary |
| Duplicate keys | Preserved | Last one wins |
| Key order | Preserved | Not preserved |
| Indexing | No | GIN, GiST |
| Read speed | Slower (re-parse) | Faster |
| Write speed | Faster | Slightly slower |

### Operators

```sql
SELECT data->'name' FROM users;          -- returns JSONB element
SELECT data->>'name' FROM users;         -- returns TEXT
SELECT data#>'{address,city}' FROM users; -- nested path as JSONB
SELECT data#>>'{address,city}' FROM users; -- nested path as TEXT
```

### Containment and Existence

```sql
SELECT * FROM users WHERE data @> '{"role": "admin"}';
SELECT * FROM users WHERE data ? 'email';
SELECT * FROM users WHERE data ?| array['email', 'phone'];
SELECT * FROM users WHERE data ?& array['email', 'phone'];
```

| Operator | Meaning |
|---|---|
| `@>` | Contains |
| `<@` | Contained by |
| `?` | Key exists |
| `?|` | Any key exists |
| `?&` | All keys exist |

### JSONB Functions

```sql
SELECT jsonb_each(data) FROM users;
SELECT jsonb_object_keys(data) FROM users;
SELECT jsonb_array_elements('[1,2,3]'::jsonb);
SELECT jsonb_typeof(data->'age') FROM users;
SELECT jsonb_set(data, '{role}', '"superadmin"') FROM users;
SELECT data || '{"verified": true}'::jsonb FROM users;
SELECT data - 'temporary_field' FROM users;
SELECT jsonb_strip_nulls(data) FROM users;
```

### GIN Indexes on JSONB

```sql
CREATE INDEX idx_users_data ON users USING GIN (data);
```

Supports `@>`, `?`, `?|`, `?&` operators.

For specific path queries:
```sql
CREATE INDEX idx_users_role ON users USING GIN ((data->'role'));
```

Expression index for a single key lookup:
```sql
CREATE INDEX idx_users_email ON users ((data->>'email'));
```

### JSONB Aggregation

```sql
SELECT jsonb_agg(name) FROM users WHERE active = true;
SELECT jsonb_object_agg(key, value) FROM settings;
```

### jsonb_path_query (SQL/JSON Path — PG 12+)

```sql
SELECT jsonb_path_query(data, '$.items[*] ? (@.price > 100)') FROM orders;
SELECT jsonb_path_exists(data, '$.address.city') FROM users;
```

---

## CTEs (Common Table Expressions)

CTEs define temporary named result sets within a query using `WITH`.

### Basic CTE

```sql
WITH active_users AS (
    SELECT id, name, email
    FROM users
    WHERE active = true
)
SELECT * FROM active_users WHERE email LIKE '%@corp.com';
```

### Multiple CTEs

```sql
WITH
    active AS (
        SELECT id, name FROM users WHERE active = true
    ),
    recent_orders AS (
        SELECT user_id, COUNT(*) as order_count
        FROM orders
        WHERE created_at > NOW() - INTERVAL '30 days'
        GROUP BY user_id
    )
SELECT a.name, COALESCE(r.order_count, 0) as orders
FROM active a
LEFT JOIN recent_orders r ON a.id = r.user_id;
```

### Recursive CTEs

Useful for hierarchical data like org trees, categories, or graphs.

```sql
WITH RECURSIVE org_tree AS (
    SELECT id, name, manager_id, 0 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    SELECT e.id, e.name, e.manager_id, ot.depth + 1
    FROM employees e
    JOIN org_tree ot ON e.manager_id = ot.id
)
SELECT * FROM org_tree ORDER BY depth, name;
```

Generate a series without generate_series:
```sql
WITH RECURSIVE nums AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM nums WHERE n < 100
)
SELECT n FROM nums;
```

### CTE Materialization (PG 12+)

By default PG 12+ may inline CTEs (optimize them like subqueries). Force materialization if you need it:

```sql
WITH active_users AS MATERIALIZED (
    SELECT * FROM users WHERE active = true
)
SELECT * FROM active_users;
```

Or prevent it:
```sql
WITH active_users AS NOT MATERIALIZED (
    SELECT * FROM users WHERE active = true
)
SELECT * FROM active_users;
```

### Writable CTEs

CTEs can do INSERT, UPDATE, DELETE and return affected rows.

```sql
WITH deleted AS (
    DELETE FROM sessions
    WHERE expires_at < NOW()
    RETURNING *
)
SELECT COUNT(*) as cleaned FROM deleted;
```

Move rows between tables:
```sql
WITH moved AS (
    DELETE FROM orders WHERE status = 'archived'
    RETURNING *
)
INSERT INTO orders_archive SELECT * FROM moved;
```

### CTE vs Subquery vs Temp Table

| Approach | Scope | Materialized | Reusable in query |
|---|---|---|---|
| Subquery | Single use | Optimizer decides | No |
| CTE | Single query | Configurable (PG 12+) | Yes |
| Temp table | Session | Always | Yes, across queries |

---

## Useful Combinations

### Partitioned Table with JSONB

```sql
CREATE TABLE logs (
    id BIGSERIAL,
    ts TIMESTAMPTZ NOT NULL,
    level TEXT,
    payload JSONB
) PARTITION BY RANGE (ts);

CREATE TABLE logs_2025_03 PARTITION OF logs
    FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE INDEX ON logs USING GIN (payload);
```

Query with partition pruning + JSONB containment:
```sql
SELECT ts, payload->>'message'
FROM logs
WHERE ts >= '2025-03-01' AND ts < '2025-03-02'
  AND payload @> '{"level": "ERROR"}';
```

### CTE with JSONB Aggregation

```sql
WITH user_tags AS (
    SELECT id, jsonb_array_elements_text(data->'tags') AS tag
    FROM users
)
SELECT tag, COUNT(*) as user_count
FROM user_tags
GROUP BY tag
ORDER BY user_count DESC;
```
