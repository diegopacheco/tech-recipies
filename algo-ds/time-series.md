# Time Series Data Structure

## What is it?

A Time Series data structure is designed to store, retrieve, and analyze sequences of data points indexed by time. Each data point typically consists of a timestamp and one or more values. Time series data structures are optimized for append-heavy workloads, range queries over time windows, and efficient compression of sequential temporal data. They form the foundation of time series databases and monitoring systems.

## How it works?

1. Data points are stored in chronological order, typically append-only
2. Timestamps are used as the primary index for efficient range queries
3. Data is often partitioned by time (hourly, daily chunks) for better management
4. Compression techniques exploit temporal locality (delta encoding, run-length encoding)
5. Downsampling and rollups aggregate old data to save space
6. Write-ahead logs ensure durability for incoming data
7. Memory buffers hold recent data before flushing to disk
8. Indexing structures (B-trees, LSM trees) enable fast time-range lookups

Common representations include arrays of (timestamp, value) pairs, columnar storage, and specialized structures like Gorilla compression blocks.

## Use cases?

- Application and infrastructure monitoring (metrics, logs)
- Financial market data (stock prices, trading volumes)
- IoT sensor data collection
- Weather and climate data recording
- Network traffic analysis
- User behavior analytics
- Scientific experiments and measurements
- Healthcare patient monitoring
- Energy consumption tracking
- Predictive maintenance systems

## Code Sample (Rust)

```rust
use std::collections::BTreeMap;
use std::time::{SystemTime, UNIX_EPOCH};

struct DataPoint {
    timestamp: u64,
    value: f64,
}

struct TimeSeries {
    name: String,
    data: BTreeMap<u64, f64>,
}

impl TimeSeries {
    fn new(name: &str) -> Self {
        TimeSeries {
            name: name.to_string(),
            data: BTreeMap::new(),
        }
    }

    fn now() -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64
    }

    fn insert(&mut self, timestamp: u64, value: f64) {
        self.data.insert(timestamp, value);
    }

    fn insert_now(&mut self, value: f64) {
        self.insert(Self::now(), value);
    }

    fn range(&self, start: u64, end: u64) -> Vec<DataPoint> {
        self.data
            .range(start..=end)
            .map(|(&timestamp, &value)| DataPoint { timestamp, value })
            .collect()
    }

    fn last_n(&self, n: usize) -> Vec<DataPoint> {
        self.data
            .iter()
            .rev()
            .take(n)
            .map(|(&timestamp, &value)| DataPoint { timestamp, value })
            .collect()
    }

    fn average(&self, start: u64, end: u64) -> Option<f64> {
        let points: Vec<f64> = self.data
            .range(start..=end)
            .map(|(_, &v)| v)
            .collect();

        if points.is_empty() {
            None
        } else {
            Some(points.iter().sum::<f64>() / points.len() as f64)
        }
    }

    fn downsample(&self, bucket_size: u64) -> Vec<DataPoint> {
        let mut buckets: BTreeMap<u64, Vec<f64>> = BTreeMap::new();

        for (&ts, &val) in &self.data {
            let bucket = (ts / bucket_size) * bucket_size;
            buckets.entry(bucket).or_default().push(val);
        }

        buckets
            .into_iter()
            .map(|(ts, vals)| DataPoint {
                timestamp: ts,
                value: vals.iter().sum::<f64>() / vals.len() as f64,
            })
            .collect()
    }

    fn delta_encode(&self) -> Vec<(u64, f64)> {
        let mut result = Vec::new();
        let mut prev_ts = 0u64;
        let mut prev_val = 0.0f64;

        for (&ts, &val) in &self.data {
            result.push((ts - prev_ts, val - prev_val));
            prev_ts = ts;
            prev_val = val;
        }

        result
    }
}

fn main() {
    let mut ts = TimeSeries::new("cpu_usage");

    let base_time = 1000000u64;
    for i in 0..100 {
        ts.insert(base_time + i * 1000, (i % 50) as f64 + 20.0);
    }

    println!("Series: {}", ts.name);
    println!("Total points: {}", ts.data.len());

    let range = ts.range(base_time + 10000, base_time + 20000);
    println!("Points in range: {}", range.len());

    if let Some(avg) = ts.average(base_time, base_time + 50000) {
        println!("Average (first half): {:.2}", avg);
    }

    let downsampled = ts.downsample(10000);
    println!("Downsampled buckets: {}", downsampled.len());

    let deltas = ts.delta_encode();
    println!("Delta encoded points: {}", deltas.len());
}
```

## Pros and Cons

### Pros
- Optimized for time-based queries and range scans
- Efficient compression due to temporal patterns
- Fast append operations for write-heavy workloads
- Natural support for downsampling and aggregation
- Well-suited for streaming data ingestion
- Enables trend analysis and anomaly detection

### Cons
- Updates to historical data can be expensive
- Random access by non-time keys is slow
- Requires careful capacity planning for retention
- High cardinality labels can cause performance issues
- Complex queries may require pre-aggregation
- Data modeling requires understanding access patterns

## Frameworks or libraries using it

- **Rust**: `timeseries` crate, `influxdb-rust` client, `questdb-rs`
- **InfluxDB**: Purpose-built time series database with TSM storage
- **TimescaleDB**: PostgreSQL extension for time series
- **Prometheus**: Monitoring system with custom TSDB
- **Apache Kafka**: Stream processing with time-windowed operations
- **QuestDB**: High-performance time series database
- **VictoriaMetrics**: Fast and cost-effective monitoring solution
- **ClickHouse**: Column-oriented DBMS excellent for time series
- **Apache Druid**: Real-time analytics database
- **OpenTSDB**: Scalable time series database on HBase
