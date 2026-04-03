# Time-Series Databases

## What is it?

A time-series database (TSDB) is a database optimized for storing, querying, and analyzing data points indexed by time. Each data point typically consists of a timestamp, a metric name (or set of labels/tags), and one or more values. TSDBs are purpose-built for workloads where data arrives in chronological order, is rarely updated, and queries span time ranges (last 5 minutes, last 24 hours, last 30 days). They exploit the append-only, time-ordered nature of this data to achieve compression ratios and query performance that general-purpose databases cannot match.

## How it works?

### Data Model

```
Traditional TSDB (metric-based):

  metric_name{label1="value1", label2="value2"}  timestamp  value

  cpu_usage{host="web01", region="us-east"}  1711900800  72.5
  cpu_usage{host="web01", region="us-east"}  1711900810  74.1
  cpu_usage{host="web02", region="us-west"}  1711900800  45.2
  memory_used{host="web01"}                  1711900800  8192

Tag-based (wide-column):

  ┌──────────┬──────────────┬───────────┬───────────┬──────────┐
  │ time     │ host         │ cpu_usage │ mem_used  │ disk_io  │
  ├──────────┼──────────────┼───────────┼───────────┼──────────┤
  │ 10:00:00 │ web01        │ 72.5      │ 8192      │ 1024     │
  │ 10:00:10 │ web01        │ 74.1      │ 8200      │ 1030     │
  │ 10:00:00 │ web02        │ 45.2      │ 4096      │ 512      │
  └──────────┴──────────────┴───────────┴───────────┴──────────┘
```

### Storage Architecture

```
Incoming data (time-ordered):

  t1: cpu=72.5
  t2: cpu=74.1
  t3: cpu=73.8
  t4: cpu=75.0
  ...

Storage:
┌─────────────────────────────────────────────────┐
│  In-Memory Buffer (Head Block)                   │
│  Recent data (last 2 hours)                      │
│  Fast writes, not yet compressed                 │
└──────────────────┬──────────────────────────────┘
                   │ flush / compaction
                   ▼
┌─────────────────────────────────────────────────┐
│  Persistent Blocks (on disk)                     │
│                                                  │
│  Block 1: [00:00 - 02:00]  ← compressed, immutable
│  Block 2: [02:00 - 04:00]  ← compressed, immutable
│  Block 3: [04:00 - 06:00]  ← compressed, immutable
│  ...                                             │
│                                                  │
│  Each block contains:                            │
│    - Chunk files (compressed time-value pairs)   │
│    - Index (series → chunk offset)               │
│    - Tombstones (deleted ranges)                 │
│    - Metadata                                    │
└─────────────────────────────────────────────────┘
```

### Compression

```
Time-series data compresses extremely well because:
  - Timestamps are monotonically increasing (delta-of-delta encoding)
  - Values change slowly (XOR encoding, Gorilla compression)

Delta-of-delta for timestamps:
  Raw:      1000, 1010, 1020, 1030, 1040
  Delta:    -, 10, 10, 10, 10
  Delta²:  -, -, 0, 0, 0         ← mostly zeros, compress to bits

XOR for values (Gorilla / Facebook):
  Values:   72.5, 72.8, 72.6, 72.9
  XOR:      -, small diff, small diff, small diff
  
  Only the differing bits are stored.
  Typical compression: 1.37 bytes per data point (Gorilla paper)

Compression ratios:
  Raw float64 + int64 timestamp = 16 bytes per point
  Compressed = 1-2 bytes per point
  10-16x compression ratio typical
```

### Downsampling and Retention

```
Raw data:     1 point per second  → 86,400 points/day
5-min avg:    1 point per 5 min   → 288 points/day
1-hour avg:   1 point per hour    → 24 points/day
1-day avg:    1 point per day     → 1 point/day

Retention policy:
  ┌──────────────┬──────────────────┬─────────────┐
  │ Resolution   │ Retention        │ Storage     │
  ├──────────────┼──────────────────┼─────────────┤
  │ Raw (1s)     │ 7 days           │ ~600 MB     │
  │ 5-min avg    │ 90 days          │ ~10 MB      │
  │ 1-hour avg   │ 2 years          │ ~1 MB       │
  │ 1-day avg    │ forever          │ ~100 KB     │
  └──────────────┴──────────────────┴─────────────┘

Automatic downsampling (Thanos, Cortex, VictoriaMetrics):
  Raw data is automatically aggregated into lower resolutions
  before older raw data is deleted.
```

## Major TSDBs

### Prometheus

```
┌─────────────────────────────────────────────────┐
│  Prometheus                                      │
│                                                  │
│  Pull-based: scrapes /metrics endpoints          │
│  Storage: local TSDB (custom, Gorilla-inspired)  │
│  Query: PromQL                                   │
│  Retention: local disk (default 15 days)         │
│                                                  │
│  Architecture:                                   │
│  ┌──────────────┐     ┌──────────────┐          │
│  │ Targets      │◄────│ Prometheus   │          │
│  │ (exporters)  │pull │ Server       │          │
│  └──────────────┘     │              │          │
│                       │ ┌──────────┐ │          │
│                       │ │ TSDB     │ │          │
│                       │ │ (local)  │ │          │
│                       │ └──────────┘ │          │
│                       └──────┬───────┘          │
│                              │                   │
│                       ┌──────▼───────┐          │
│                       │ Grafana      │          │
│                       │ (dashboard)  │          │
│                       └──────────────┘          │
│                                                  │
│  Long-term storage: Thanos, Cortex, Mimir,      │
│  VictoriaMetrics (remote write/read)             │
└─────────────────────────────────────────────────┘
```

### InfluxDB

```
┌─────────────────────────────────────────────────┐
│  InfluxDB                                        │
│                                                  │
│  Push-based: clients write via HTTP/gRPC         │
│  Storage: TSI (Time-Structured Index) + TSM      │
│  Query: InfluxQL or Flux (v2), SQL (v3)          │
│  Clustering: InfluxDB Cloud (managed)            │
│                                                  │
│  Data model:                                     │
│    measurement,tag1=v1,tag2=v2 field1=x,field2=y ts
│                                                  │
│  InfluxDB v3 (2024+):                            │
│    - Rewritten in Rust                           │
│    - Apache Arrow / DataFusion query engine       │
│    - Parquet storage                              │
│    - SQL support                                  │
└─────────────────────────────────────────────────┘
```

### TimescaleDB

```
┌─────────────────────────────────────────────────┐
│  TimescaleDB                                     │
│                                                  │
│  PostgreSQL extension (not a separate database)  │
│  Full SQL support (it IS PostgreSQL)             │
│                                                  │
│  Key concept: Hypertable                         │
│  ┌──────────────────────────────────────────┐   │
│  │ Hypertable (virtual table)               │   │
│  │                                          │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐      │   │
│  │  │ Chunk  │ │ Chunk  │ │ Chunk  │      │   │
│  │  │ 00:00- │ │ 01:00- │ │ 02:00- │      │   │
│  │  │ 01:00  │ │ 02:00  │ │ 03:00  │      │   │
│  │  └────────┘ └────────┘ └────────┘      │   │
│  │                                          │   │
│  │  Each chunk = a regular PostgreSQL table  │   │
│  │  Automatic partitioning by time          │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  Advantages:                                     │
│    - Full SQL, JOINs, transactions, extensions   │
│    - Continuous aggregates (materialized views)  │
│    - Compression (columnar within chunks)        │
│    - pg_dump, pg_restore, replication all work   │
└─────────────────────────────────────────────────┘
```

### VictoriaMetrics

```
┌─────────────────────────────────────────────────┐
│  VictoriaMetrics                                 │
│                                                  │
│  Drop-in Prometheus replacement                  │
│  Written in Go, single binary                    │
│  Long-term storage for Prometheus                │
│                                                  │
│  Architecture (cluster mode):                    │
│  ┌─────────────┐  ┌─────────────┐              │
│  │ vminsert    │  │ vmselect    │              │
│  │ (writes)    │  │ (queries)   │              │
│  └──────┬──────┘  └──────┬──────┘              │
│         │                │                      │
│         └────────┬───────┘                      │
│                  ▼                               │
│         ┌──────────────┐                        │
│         │ vmstorage    │                        │
│         │ (data nodes) │                        │
│         └──────────────┘                        │
│                                                  │
│  Key features:                                   │
│    - 10x less RAM than Prometheus                │
│    - Supports PromQL, MetricsQL                  │
│    - High compression (better than Prometheus)   │
│    - Supports remote write from Prometheus       │
└─────────────────────────────────────────────────┘
```

### QuestDB

```
┌─────────────────────────────────────────────────┐
│  QuestDB                                         │
│                                                  │
│  Written in Java + C (JIT for filters)           │
│  Column-oriented storage                         │
│  SQL with time-series extensions                 │
│                                                  │
│  Ingestion: 1.4M rows/sec on single node         │
│  Protocol: InfluxDB Line Protocol, PostgreSQL    │
│            wire protocol, HTTP REST              │
│                                                  │
│  Key features:                                   │
│    - SIMD-accelerated queries                    │
│    - Memory-mapped files                         │
│    - SAMPLE BY (time-based aggregation)          │
│    - LATEST ON (last value per series)           │
│    - Built-in web console                        │
└─────────────────────────────────────────────────┘
```

## Comparison

```
┌──────────────────┬────────────┬────────────┬────────────┬────────────┐
│ Feature          │ Prometheus │ InfluxDB   │ Timescale  │ Victoria   │
│                  │            │ (v3)       │ DB         │ Metrics    │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Model            │ Pull       │ Push       │ Push/Pull  │ Pull       │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Query language   │ PromQL     │ SQL        │ SQL        │ PromQL /   │
│                  │            │            │            │ MetricsQL  │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Storage engine   │ Custom TSDB│ Parquet    │ PostgreSQL │ Custom     │
│                  │            │ (Arrow)    │ (chunks)   │            │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Clustering       │ No (use    │ Cloud only │ Multi-node │ Yes        │
│                  │ Thanos/    │            │ (Timescale │ (cluster)  │
│                  │ Mimir)     │            │  Cloud)    │            │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Long-term        │ Limited    │ Yes        │ Yes        │ Yes        │
│ storage          │ (15d def)  │            │            │            │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ JOINs            │ No         │ Yes (v3)   │ Yes (full  │ No         │
│                  │            │            │ SQL)       │            │
├──────────────────┼────────────┼────────────┼────────────┼────────────┤
│ Best for         │ Metrics,   │ IoT,       │ SQL teams, │ Prometheus │
│                  │ alerting   │ analytics  │ mixed      │ at scale   │
│                  │            │            │ workloads  │            │
└──────────────────┴────────────┴────────────┴────────────┴────────────┘
```

## Pros

- **Write Performance**: append-only, time-ordered writes are extremely fast
- **Compression**: 10-16x compression ratios with delta and XOR encoding
- **Time-Range Queries**: partitioning by time makes range scans efficient (skip irrelevant blocks)
- **Downsampling**: automatic aggregation reduces storage costs for historical data
- **Purpose-Built Functions**: rate(), increase(), histogram_quantile(), moving averages, rollups
- **Retention Policies**: automatic deletion of data older than a configured threshold
- **Cardinality Handling**: inverted indexes on labels/tags enable fast filtering
- **Ecosystem**: Grafana, alerting, recording rules, remote write/read protocols

## Cons

- **High Cardinality**: too many unique label combinations (user_id as a label) degrades performance
- **No JOINs**: most TSDBs (Prometheus, VictoriaMetrics) do not support relational JOINs
- **Limited Updates**: data is append-only — updating a past data point is expensive or unsupported
- **Schema Rigidity**: changing label names or metric structures requires migration
- **Operational Complexity**: clustering, long-term storage, and HA require additional components
- **Query Language Fragmentation**: PromQL, Flux, InfluxQL, SQL — no universal standard
- **Backfill Difficulty**: inserting historical data out of order can be slow or unsupported
- **Single-Node Limits**: Prometheus has no built-in clustering — needs Thanos/Mimir/Cortex

## Use Cases

- **Infrastructure Monitoring**: CPU, memory, disk, network metrics from servers and containers
- **Application Performance Monitoring (APM)**: request latency, error rates, throughput
- **IoT Sensor Data**: temperature, pressure, humidity from thousands of devices
- **Financial Market Data**: tick-by-tick price data, order book snapshots
- **Network Monitoring**: bandwidth, packet loss, latency across switches and routers
- **Energy / Smart Grid**: power consumption, generation, grid frequency at high resolution
- **DevOps Alerting**: Prometheus + Alertmanager for threshold-based and anomaly alerting
- **Capacity Planning**: historical resource usage trends for forecasting
- **SLA Monitoring**: uptime, availability, and error budget tracking over time
- **Real-Time Dashboards**: Grafana dashboards showing live metrics with historical context
