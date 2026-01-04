# LSM Tree

## What is it?

A Log-Structured Merge Tree (LSM Tree) is a data structure designed to provide high write throughput for storage systems. It achieves this by buffering writes in memory and periodically flushing them to disk in sorted runs, then merging these runs in the background. Invented by Patrick O'Neil and colleagues in 1996, LSM trees form the foundation of many modern databases including LevelDB, RocksDB, Cassandra, and HBase.

## How it works?

1. Writes go to an in-memory buffer called MemTable (typically a skip list or red-black tree)
2. A Write-Ahead Log (WAL) ensures durability before acknowledging writes
3. When MemTable reaches a size threshold, it's frozen and flushed to disk as an immutable SSTable (Sorted String Table)
4. SSTables are organized into levels (L0, L1, L2, ...) with increasing size limits
5. Compaction merges SSTables from level N to level N+1, removing duplicates and deleted keys
6. Reads check MemTable first, then search SSTables from newest to oldest using Bloom filters
7. Each SSTable has an index for efficient key lookup

The "log-structured" name comes from treating the disk as an append-only log of sorted runs.

## Use cases?

- Write-heavy workloads (logging, time series, metrics)
- Key-value stores and NoSQL databases
- Embedded databases in applications
- Write-ahead logging systems
- Event sourcing storage
- Blockchain state storage
- Search engine indexing
- Message queue persistence
- Cache backing stores
- IoT data ingestion

## Code Sample (Rust)

```rust
use std::collections::BTreeMap;
use std::fs::{File, OpenOptions};
use std::io::{BufRead, BufReader, Write};
use std::path::PathBuf;

struct MemTable {
    data: BTreeMap<String, Option<String>>,
    size: usize,
}

impl MemTable {
    fn new() -> Self {
        MemTable {
            data: BTreeMap::new(),
            size: 0,
        }
    }

    fn put(&mut self, key: String, value: String) {
        self.size += key.len() + value.len();
        self.data.insert(key, Some(value));
    }

    fn delete(&mut self, key: String) {
        self.size += key.len();
        self.data.insert(key, None);
    }

    fn get(&self, key: &str) -> Option<Option<&String>> {
        self.data.get(key).map(|v| v.as_ref())
    }

    fn is_full(&self, threshold: usize) -> bool {
        self.size >= threshold
    }

    fn clear(&mut self) {
        self.data.clear();
        self.size = 0;
    }
}

struct SSTable {
    path: PathBuf,
    index: BTreeMap<String, u64>,
}

impl SSTable {
    fn create(path: PathBuf, data: &BTreeMap<String, Option<String>>) -> std::io::Result<Self> {
        let mut file = File::create(&path)?;
        let mut index = BTreeMap::new();
        let mut offset = 0u64;

        for (key, value) in data {
            let line = match value {
                Some(v) => format!("{}:{}\n", key, v),
                None => format!("{}:__TOMBSTONE__\n", key),
            };
            index.insert(key.clone(), offset);
            offset += line.len() as u64;
            file.write_all(line.as_bytes())?;
        }

        Ok(SSTable { path, index })
    }

    fn get(&self, key: &str) -> std::io::Result<Option<Option<String>>> {
        if !self.index.contains_key(key) {
            return Ok(None);
        }

        let file = File::open(&self.path)?;
        let reader = BufReader::new(file);

        for line in reader.lines() {
            let line = line?;
            if let Some((k, v)) = line.split_once(':') {
                if k == key {
                    if v == "__TOMBSTONE__" {
                        return Ok(Some(None));
                    }
                    return Ok(Some(Some(v.to_string())));
                }
            }
        }

        Ok(None)
    }
}

struct WriteAheadLog {
    file: File,
}

impl WriteAheadLog {
    fn new(path: &PathBuf) -> std::io::Result<Self> {
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .open(path)?;
        Ok(WriteAheadLog { file })
    }

    fn append(&mut self, op: &str, key: &str, value: Option<&str>) -> std::io::Result<()> {
        let entry = match value {
            Some(v) => format!("{}:{}:{}\n", op, key, v),
            None => format!("{}:{}\n", op, key),
        };
        self.file.write_all(entry.as_bytes())?;
        self.file.flush()
    }

    fn clear(&mut self, path: &PathBuf) -> std::io::Result<()> {
        self.file = File::create(path)?;
        Ok(())
    }
}

struct LSMTree {
    memtable: MemTable,
    sstables: Vec<SSTable>,
    wal: WriteAheadLog,
    data_dir: PathBuf,
    memtable_threshold: usize,
    sstable_counter: usize,
}

impl LSMTree {
    fn new(data_dir: PathBuf, memtable_threshold: usize) -> std::io::Result<Self> {
        std::fs::create_dir_all(&data_dir)?;
        let wal_path = data_dir.join("wal.log");
        Ok(LSMTree {
            memtable: MemTable::new(),
            sstables: Vec::new(),
            wal: WriteAheadLog::new(&wal_path)?,
            data_dir,
            memtable_threshold,
            sstable_counter: 0,
        })
    }

    fn put(&mut self, key: String, value: String) -> std::io::Result<()> {
        self.wal.append("PUT", &key, Some(&value))?;
        self.memtable.put(key, value);

        if self.memtable.is_full(self.memtable_threshold) {
            self.flush()?;
        }

        Ok(())
    }

    fn delete(&mut self, key: String) -> std::io::Result<()> {
        self.wal.append("DEL", &key, None)?;
        self.memtable.delete(key);
        Ok(())
    }

    fn get(&self, key: &str) -> std::io::Result<Option<String>> {
        if let Some(result) = self.memtable.get(key) {
            return Ok(result.cloned());
        }

        for sstable in self.sstables.iter().rev() {
            if let Some(result) = sstable.get(key)? {
                return Ok(result);
            }
        }

        Ok(None)
    }

    fn flush(&mut self) -> std::io::Result<()> {
        let path = self.data_dir.join(format!("sstable_{}.dat", self.sstable_counter));
        let sstable = SSTable::create(path, &self.memtable.data)?;
        self.sstables.push(sstable);
        self.sstable_counter += 1;
        self.memtable.clear();
        self.wal.clear(&self.data_dir.join("wal.log"))?;
        Ok(())
    }
}

fn main() -> std::io::Result<()> {
    let mut lsm = LSMTree::new(PathBuf::from("/tmp/lsm_test"), 1024)?;

    lsm.put("key1".to_string(), "value1".to_string())?;
    lsm.put("key2".to_string(), "value2".to_string())?;
    lsm.put("key3".to_string(), "value3".to_string())?;

    println!("key1: {:?}", lsm.get("key1")?);
    println!("key2: {:?}", lsm.get("key2")?);

    lsm.delete("key2".to_string())?;
    println!("key2 after delete: {:?}", lsm.get("key2")?);

    lsm.put("key1".to_string(), "updated_value1".to_string())?;
    println!("key1 after update: {:?}", lsm.get("key1")?);

    Ok(())
}
```

## Pros and Cons

### Pros
- Extremely high write throughput (sequential I/O)
- Efficient space utilization through compaction
- Good for write-heavy workloads
- Supports range scans efficiently
- Immutable SSTables simplify concurrency
- Write amplification is bounded
- Works well with SSDs and HDDs

### Cons
- Read amplification (may need to check multiple SSTables)
- Write amplification from compaction
- Space amplification during compaction
- Compaction can cause latency spikes
- More complex than B-trees
- Background compaction consumes resources
- Tuning compaction strategies requires expertise

## Frameworks or libraries using it

- **Rust**: `rust-rocksdb` (RocksDB bindings), `sled` embedded database
- **RocksDB**: Facebook's embedded key-value store
- **LevelDB**: Google's original LSM implementation
- **Apache Cassandra**: Distributed database using LSM trees
- **Apache HBase**: Hadoop database using LSM trees
- **ScyllaDB**: High-performance Cassandra alternative
- **CockroachDB**: Distributed SQL using RocksDB/Pebble
- **TiKV**: Distributed transactional key-value store
- **InfluxDB**: Time series database using TSM (LSM variant)
- **BadgerDB**: Pure Go LSM-based key-value store
