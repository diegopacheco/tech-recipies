# Redshift Zero-ETL

## What is it?

Redshift Zero-ETL is an AWS feature that enables near real-time data replication from transactional databases into Amazon Redshift without building or maintaining ETL pipelines. It automatically replicates data from supported sources (Aurora MySQL, Aurora PostgreSQL, RDS MySQL, DynamoDB) into Redshift, keeping the analytical copy continuously up to date. The goal is to eliminate the need for custom extract-transform-load pipelines between operational databases and the data warehouse.

The architecture consists of key components:
- **Zero-ETL Integration**: A managed replication link between a source and Redshift
- **Change Data Capture (CDC)**: Automatic capture of inserts, updates, and deletes from the source
- **Auto Replication**: Continuous data movement without user-managed infrastructure
- **Destination Database**: A Redshift database that mirrors source tables automatically

## Who created it? When?

Zero-ETL was announced by **AWS** at **re:Invent 2022** by CEO Adam Selipsky. The Aurora MySQL to Redshift integration became generally available in **2023**. Aurora PostgreSQL, RDS MySQL, and DynamoDB integrations followed in **2024**. The feature is part of AWS's broader strategy to reduce data engineering overhead and make analytics accessible without pipeline management.

## How it works?

1. **Integration Setup**:
   - Create a zero-ETL integration in the AWS console, CLI, or CloudFormation
   - Specify the source (Aurora cluster, RDS instance, or DynamoDB table)
   - Specify the target Redshift cluster or serverless namespace
   - AWS provisions the replication infrastructure automatically

2. **Initial Snapshot**:
   - Full snapshot of existing source data is loaded into Redshift
   - Tables are created automatically in the destination database
   - Schema mapping handles type conversions between source and Redshift

3. **Continuous Replication**:
   - CDC captures changes from the source transaction log
   - Inserts, updates, and deletes are propagated to Redshift in near real-time
   - Replication lag is typically seconds to minutes depending on volume
   - No user-managed jobs, queues, or schedulers involved

4. **Schema Evolution**:
   - New tables added to the source are automatically replicated
   - Column additions in the source are reflected in Redshift
   - Some DDL changes (drops, renames) require manual handling

5. **Data Consumption**:
   - Replicated data is queryable in Redshift like any other table
   - Can be joined with other Redshift tables, external tables, or data shares
   - BI tools and analytics workloads connect to Redshift as usual
   - dbt or other transformation tools can build marts on top of replicated tables

## Supported Sources

```
┌────────────────────────┬──────────────────────────────────────────────┐
│ Source                 │ Notes                                        │
├────────────────────────┼──────────────────────────────────────────────┤
│ Aurora MySQL           │ First GA integration, most mature            │
├────────────────────────┼──────────────────────────────────────────────┤
│ Aurora PostgreSQL      │ GA in 2024                                   │
├────────────────────────┼──────────────────────────────────────────────┤
│ RDS MySQL              │ GA in 2024                                   │
├────────────────────────┼──────────────────────────────────────────────┤
│ DynamoDB               │ Replicates items as rows in Redshift         │
├────────────────────────┼──────────────────────────────────────────────┤
│ Redshift (cross-acct)  │ Cross-account and cross-region replication   │
└────────────────────────┴──────────────────────────────────────────────┘
```

## Pros

- **No Pipeline Management**: Eliminates building, monitoring, and maintaining ETL jobs
- **Near Real-Time**: Data available in Redshift within seconds to minutes of source changes
- **Fully Managed**: AWS handles replication infrastructure, scaling, and recovery
- **Reduced Operational Cost**: No Glue jobs, Lambda functions, or Airflow DAGs to maintain
- **Automatic Schema Replication**: Source tables and new columns appear in Redshift automatically
- **Transactional Consistency**: Changes are applied in order preserving data integrity
- **Lower Latency**: Faster data availability compared to batch ETL schedules
- **Simple Setup**: Can be configured in minutes through the console or IaC
- **Cost Efficient**: No intermediate storage (S3 staging) or compute (Glue/EMR) needed
- **Native Integration**: Works within the AWS ecosystem without third-party tools

## Cons

- **AWS Lock-In**: Only works within the AWS ecosystem, no multi-cloud support
- **Limited Sources**: Only supports Aurora MySQL, Aurora PostgreSQL, RDS MySQL, and DynamoDB
- **No Transformation**: Data arrives as-is, transformations must happen in Redshift after replication
- **Schema Limitations**: Some DDL changes require manual intervention or re-creation of the integration
- **Source Overhead**: CDC adds some load to the source database
- **Data Type Mapping**: Not all source types map cleanly to Redshift types
- **No Filtering**: Cannot selectively replicate subsets of tables or rows during ingestion
- **Redshift Required**: Destination must be Redshift, cannot replicate to other warehouses
- **Cost Visibility**: Replication costs are bundled and can be hard to predict at scale
- **Maturity**: Relatively new feature, edge cases and limitations are still being discovered
- **No RDS PostgreSQL**: RDS PostgreSQL is not yet supported as a source

## Use Cases

- **Operational Analytics**: Real-time dashboards on top of transactional data without impacting production
- **OLTP to OLAP Bridge**: Querying relational data with Redshift's analytical engine without ETL
- **DynamoDB Analytics**: Running SQL analytics on DynamoDB data that would be expensive with DynamoDB scans
- **Data Warehouse Modernization**: Replacing custom CDC pipelines (DMS, Debezium) with a managed solution
- **Cross-Account Analytics**: Centralizing data from multiple AWS accounts into a single Redshift warehouse
- **Rapid Prototyping**: Getting transactional data into a warehouse quickly for ad-hoc analysis
- **Compliance Reporting**: Near real-time replicated data for audit and regulatory queries
- **Customer-Facing Analytics**: Low-latency data availability for embedded analytics products
- **Hybrid Architectures**: Combining zero-ETL replicated tables with S3-based data lakehouse tables in Redshift
- **Reducing Data Engineering Toil**: Freeing data teams from pipeline maintenance to focus on modeling and analysis
