# Data Lakehouse

## What is it?

Data Lakehouse is a data architecture that combines the low-cost storage and schema flexibility of data lakes with the data management features and ACID transactions of data warehouses. It provides a unified platform that supports both business intelligence (BI) workloads and machine learning (ML) workloads without requiring data to be copied between systems.

The architecture consists of key components:
- **Open File Formats**: Data stored in open formats like Parquet or ORC on cheap object storage
- **Metadata Layer**: Table format layer (Delta Lake, Iceberg, Hudi) that adds ACID transactions, schema enforcement, and time travel
- **Query Engines**: Multiple engines can directly query the same data (Spark, Presto, Flink, Dremio)
- **Catalog**: Centralized metadata catalog for table discovery and governance

## Who created it? When?

The Data Lakehouse concept was formalized by **Databricks** in **2020**. The term was introduced in their paper "Lakehouse: A New Generation of Open Platforms that Unify Data Warehousing and Advanced Analytics" authored by Michael Armbrust, Ali Ghodsi, Reynold Xin, and Matei Zaharia. The architecture evolved from earlier work on Delta Lake (2019) and builds on concepts from both Apache Spark and traditional data warehousing.

## How it works?

1. **Data Ingestion**:
   - Raw data lands in object storage (S3, ADLS, GCS) in open file formats
   - Ingestion can be batch or streaming
   - Data is written as Parquet files managed by a table format layer

2. **Table Format Layer**:
   - Delta Lake, Apache Iceberg, or Apache Hudi sits on top of raw files
   - Provides transaction log for ACID guarantees
   - Enables schema evolution without rewriting data
   - Tracks file-level metadata for query optimization

3. **Data Quality and Governance**:
   - Schema enforcement prevents bad data from entering tables
   - Constraints and expectations validate data quality
   - Time travel allows querying historical snapshots
   - Audit logs track all changes

4. **Query Processing**:
   - Query engines read metadata layer to understand table structure
   - File pruning and data skipping optimize query performance
   - Same data serves both SQL analytics and ML workloads
   - Caching layers can accelerate frequent queries

5. **Data Consumption**:
   - BI tools connect via SQL endpoints
   - Data scientists access data directly for ML training
   - Streaming applications read change data feeds
   - No ETL required between analytical systems

## Pros

- **Unified Platform**: Single architecture for BI, data science, and streaming
- **Cost Effective**: Cheap object storage instead of proprietary warehouse storage
- **ACID Transactions**: Reliable writes with rollback capabilities
- **Schema Enforcement**: Data quality at write time
- **Open Formats**: No vendor lock-in, multiple engines can access data
- **Time Travel**: Query historical versions of data
- **Streaming Support**: Unified batch and streaming on same tables
- **Reduced Data Duplication**: No need to copy data between lake and warehouse
- **Scalability**: Separates storage and compute for independent scaling
- **ML Ready**: Direct access to data for training without ETL

## Cons

- **Query Performance**: May not match optimized data warehouses for complex SQL
- **Complexity**: Requires understanding of file formats, table formats, and engines
- **Tuning Required**: Performance depends on proper partitioning and file compaction
- **Tooling Maturity**: Ecosystem still evolving compared to traditional warehouses
- **Concurrency Limits**: High-concurrency workloads may need additional optimization
- **Small File Problem**: Streaming ingestion can create many small files requiring compaction
- **Skill Gap**: Teams need expertise in both data engineering and infrastructure
- **Governance Features**: Some enterprise features still catching up to mature warehouses

## Use Cases

- **Unified Analytics Platforms**: Organizations wanting single source of truth for all analytics
- **Machine Learning Pipelines**: Direct feature engineering on warehouse-quality data
- **Real-time Analytics**: Streaming data with immediate queryability
- **Data Warehouse Migration**: Moving from expensive proprietary warehouses to open alternatives
- **Multi-Engine Environments**: Organizations using Spark, Presto, and other engines together
- **Regulatory Compliance**: Industries requiring audit trails and data versioning
- **IoT Analytics**: High-volume sensor data with both streaming and historical analysis
- **Customer 360**: Combining transactional and behavioral data in single platform
- **Cost Optimization**: Reducing data warehouse costs while maintaining capabilities
- **Hybrid Cloud**: Organizations with data across multiple cloud providers
