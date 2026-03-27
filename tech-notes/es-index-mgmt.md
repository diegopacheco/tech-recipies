# Elasticsearch Index Management

## What is it?

Elasticsearch Index Management is the set of techniques, APIs, and policies used to control the lifecycle of indices from creation to deletion. In production clusters handling logs, metrics, and time-series data, indices grow continuously and require automated strategies for rollover, tiered storage, compaction, and retention. Elasticsearch provides Index Lifecycle Management (ILM), data streams, templates, aliases, and operational APIs (rollover, shrink, force merge) to handle this at scale.

## Is Sliding Window a Common Pattern?

Yes. The sliding window pattern is one of the most widely used approaches for managing time-series indices in Elasticsearch, though Elastic calls it **rollover**. The concept is identical: new indices are created as the active write target while old indices age through storage tiers and eventually get deleted.

The pattern works as follows:
- A **write alias** points to the single active index receiving documents
- A **search alias** points to all indices (active and historical) for querying
- When the active index meets rollover conditions (size, age, doc count), a new index is created and the write alias switches to it atomically
- Old indices move through warm, cold, and frozen tiers before deletion

Today the recommended approach is **data streams** which implement this sliding window pattern automatically without manual alias management.

## Index Lifecycle Management (ILM)

ILM automates index management through policy-defined phases. You define a policy specifying phases and actions, attach it to an index template, and Elasticsearch handles transitions automatically.

### Phases

```
┌─────────┬──────────────────────────────────────────────────────────────────────┐
│ Phase   │ Description                                                        │
├─────────┼──────────────────────────────────────────────────────────────────────┤
│ Hot     │ Actively written and queried. Fast SSDs, multiple shards.           │
│         │ Actions: rollover, force merge, shrink, set priority                │
├─────────┼──────────────────────────────────────────────────────────────────────┤
│ Warm    │ No longer written, still queried regularly. Cheaper hardware.       │
│         │ Actions: read-only, shrink, force merge, allocate, migrate          │
├─────────┼──────────────────────────────────────────────────────────────────────┤
│ Cold    │ Rarely queried, slower responses acceptable. Cheapest storage.      │
│         │ Actions: searchable snapshot, allocate, migrate, read-only          │
├─────────┼──────────────────────────────────────────────────────────────────────┤
│ Frozen  │ Almost never queried. Extremely slow queries acceptable.            │
│         │ Actions: searchable snapshot                                        │
├─────────┼──────────────────────────────────────────────────────────────────────┤
│ Delete  │ Index permanently removed, storage freed.                           │
│         │ Actions: wait for snapshot, delete                                  │
└─────────┴──────────────────────────────────────────────────────────────────────┘
```

### ILM Policy

```json
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "30d",
            "max_primary_shard_size": "50gb"
          }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": { "number_of_shards": 1 },
          "forcemerge": { "max_num_segments": 1 }
        }
      },
      "cold": {
        "min_age": "90d",
        "actions": {
          "allocate": { "number_of_replicas": 0 }
        }
      },
      "delete": {
        "min_age": "365d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

If an index has been rolled over, `min_age` is relative to the rollover time, not the index creation time.

## Rollover API

Creates a new index when the current write index meets specified conditions.

### Rollover Conditions

- `max_age` -- maximum time since index creation (e.g., 7d, 30d)
- `max_docs` -- maximum number of documents
- `max_size` -- maximum index size (e.g., 50gb)
- `max_primary_shard_size` -- maximum primary shard size
- `max_primary_shard_docs` -- maximum documents per primary shard

Rollover triggers if **any** `max_*` condition is met AND **all** `min_*` conditions are satisfied.

Prefer document count or age over shard size as rollover triggers because shard size fluctuates during merge operations.

## Data Streams

Data streams are the modern abstraction for time-series data (logs, metrics, traces).

- A data stream is a collection of hidden, auto-generated **backing indices**
- The most recent backing index is the **write index** receiving all new documents
- Read requests are routed to all backing indices transparently
- Rollover is handled automatically
- Every document must contain a `@timestamp` field
- Designed for append-only use cases (updates/deletes require targeting the specific backing index)
- Backing index naming: `.ds-<data-stream-name>-<yyyy.MM.dd>-<generation>`

## Index Templates and Component Templates

### Index Templates

- Automatically apply settings, mappings, and aliases when creating indices matching `index_patterns`
- Use numeric `priority` for conflict resolution when multiple templates match
- Can reference component templates via `composed_of`
- Can create data streams or regular indices

### Component Templates

- Reusable building blocks defining mappings, settings, and aliases
- Not applied directly to indices, only referenced by index templates
- Merged in order specified in `composed_of` (last wins)

### Precedence (highest to lowest)

1. Explicit settings at index creation time
2. Index template settings
3. Component template settings (later in list wins)

## Aliases

Aliases provide a layer of indirection so applications never reference physical index names directly.

- **Write alias**: points to a single index for writes, switches atomically on rollover
- **Search alias**: points to multiple indices for reads
- **Filtered alias**: restricts queries to a subset of data (useful for multi-tenant segregation)
- Enable zero-downtime reindexing by atomically swapping alias targets

## Shrink and Force Merge

### Shrink

- Reduces the number of primary shards in an index
- Index must be read-only before shrinking
- Consolidates multiple shards into fewer (often one) to reduce overhead
- Used in warm/cold transitions after rollover

### Force Merge

- Reduces the number of Lucene segments within each shard
- Only perform on read-only indices (never on actively written indices)
- Merging to a single segment enables simpler, more efficient data structures
- Temporarily requires up to 3x the shard's storage during the merge operation
- Schedule during low-traffic periods

## Common Index Management Patterns

```
┌──────────────────────────────┬────────────────────────────────────────────────┐
│ Pattern                      │ When to Use                                    │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Time-based indices + ILM     │ Logs, metrics, traces, any time-series data   │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Data streams                 │ Modern replacement for manual time-based      │
│                              │ indices with automatic rollover                │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Hot-Warm-Cold architecture   │ Large clusters where storage cost matters     │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Alias-based rollover         │ Legacy approach before data streams existed   │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Zero-downtime reindex        │ Schema migrations, mapping changes            │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Shrink + force merge         │ Compacting read-only indices on warm/cold     │
├──────────────────────────────┼────────────────────────────────────────────────┤
│ Filtered aliases             │ Multi-tenant data isolation                   │
└──────────────────────────────┴────────────────────────────────────────────────┘
```

## Best Practices

- Target **10-50 GB per shard** to avoid JVM heap pressure from too many small shards
- Use **aliases** to decouple applications from physical index names
- Automate everything with **ILM policies** (rollover after 30-60 days or 50 GB is a common starting point)
- Use **data streams** for time-series data instead of manual alias management
- Use **bulk requests** instead of single-document indexing
- Disable refresh during bulk reindex operations (`refresh_interval: "-1"`)
- Use `best_compression` codec on cold/archived indices to reduce storage
- Schedule force merge and shrink during low-traffic windows
- Maintain at least one replica during maintenance
- Use lowercase names with hyphens and version numbers (e.g., `logs-v1`)

## Zero-Downtime Reindex

1. Create new index with updated mappings
2. Disable refresh during reindex (`refresh_interval: "-1"`)
3. Execute async reindex
4. Restore refresh interval
5. Atomically swap aliases
6. Delete old index

## Pros

- **Automated Lifecycle**: ILM eliminates manual index maintenance
- **Cost Optimization**: Hot-Warm-Cold architecture matches storage cost to data access patterns
- **Zero Downtime**: Alias swapping and rollover happen atomically
- **Scalable**: Data streams handle automatic rollover and naming
- **Flexible Retention**: Per-policy retention with phase-based transitions
- **Resource Efficient**: Shrink and force merge reclaim storage and reduce overhead

## Cons

- **Complexity**: ILM policies, templates, aliases, and data streams have a steep learning curve
- **Shard Management**: Getting shard size right requires monitoring and tuning
- **Force Merge Risk**: Temporarily requires up to 3x storage and produces large segments
- **Append-Only Limitation**: Data streams do not support direct updates or deletes
- **Phase Timing**: min_age calculations relative to rollover time can be confusing
- **Cluster State Overhead**: Too many indices and shards degrade cluster performance
