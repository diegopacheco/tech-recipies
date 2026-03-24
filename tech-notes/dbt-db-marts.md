# dbt Data Marts

## What is it?

dbt (data build tool) Data Marts is an approach to building analytical data marts using dbt as the transformation layer inside a data warehouse. Instead of building data marts through stored procedures or external ETL tools, dbt models define SQL-based transformations that read from raw/staged data and produce curated, business-specific datasets organized as data marts. Each mart is a logical grouping of models scoped to a business domain.

The typical project structure follows a layered approach:
- **Staging Layer**: Cleans and renames raw source data (1:1 with source tables)
- **Intermediate Layer**: Joins and business logic that combine staged models
- **Marts Layer**: Final denormalized tables/views exposed to consumers (BI tools, analysts)

## Who created it? When?

dbt was created by **Fishtown Analytics** (now **dbt Labs**) in **2016**, founded by Tristan Handy. The data marts pattern within dbt emerged from community best practices and was formalized in dbt's official style guide and the "How we structure our dbt projects" guide. The concept of data marts itself predates dbt (Ralph Kimball's dimensional modeling from the 1990s), but dbt modernized the approach by making marts version-controlled, testable, and code-driven.

## How it works?

1. **Source Declaration**:
   - Raw tables are declared in `sources.yml` files
   - dbt tracks source freshness and lineage
   - Sources represent the entry point from upstream systems

2. **Staging Models**:
   - One staging model per source table
   - Light transformations: renaming columns, casting types, filtering deleted records
   - Materialized as views to avoid storage duplication
   - Located in `models/staging/<source_name>/`

3. **Intermediate Models**:
   - Combine multiple staging models with joins and business logic
   - Handle grain changes, aggregations, and pivots
   - Not exposed to end users directly
   - Located in `models/intermediate/`

4. **Mart Models**:
   - Final business-facing tables scoped to a domain (finance, marketing, sales)
   - Materialized as tables or incremental models for performance
   - Contain business metrics, dimensions, and facts
   - Located in `models/marts/<domain>/`

5. **Testing and Documentation**:
   - Schema tests validate uniqueness, not-null, referential integrity, accepted values
   - Custom tests encode business rules
   - Documentation lives alongside models in `.yml` files
   - dbt generates a DAG showing full lineage from source to mart

6. **Execution**:
   - `dbt run` executes models in dependency order
   - `dbt test` runs all defined tests
   - `dbt build` combines run + test in order
   - Orchestrated via Airflow, Dagster, Prefect, or dbt Cloud

## Project Structure

```
models/
├── staging/
│   ├── stripe/
│   │   ├── _stripe__sources.yml
│   │   ├── _stripe__models.yml
│   │   ├── stg_stripe__payments.sql
│   │   └── stg_stripe__invoices.sql
│   └── salesforce/
│       ├── _salesforce__sources.yml
│       ├── stg_salesforce__accounts.sql
│       └── stg_salesforce__opportunities.sql
├── intermediate/
│   ├── int_payments_pivoted_to_orders.sql
│   └── int_customer_order_history.sql
└── marts/
    ├── finance/
    │   ├── _finance__models.yml
    │   ├── fct_revenue.sql
    │   └── dim_customers.sql
    ├── marketing/
    │   ├── _marketing__models.yml
    │   ├── fct_campaigns.sql
    │   └── dim_channels.sql
    └── sales/
        ├── _sales__models.yml
        ├── fct_orders.sql
        └── dim_products.sql
```

## Pros

- **Version Controlled**: All transformations live in Git with full history and code review
- **Testable**: Built-in testing framework catches data quality issues before they reach consumers
- **Modular**: Layered architecture promotes reuse and reduces duplication
- **Self-Documenting**: Documentation and lineage generated automatically from code
- **SQL Native**: Analysts who know SQL can contribute without learning a new language
- **Environment Support**: Dev, staging, and production environments with schema separation
- **Incremental Processing**: Incremental materializations handle large tables efficiently
- **Open Source**: Core dbt is free with a large ecosystem of packages and adapters
- **Warehouse Agnostic**: Works with Snowflake, BigQuery, Redshift, Databricks, Postgres, and others
- **Lineage Visibility**: Full DAG visualization from raw sources to final marts
- **Jinja Templating**: Macros and Jinja enable DRY patterns and dynamic SQL generation

## Cons

- **SQL Only**: Complex transformations (ML, graph processing) are awkward or impossible in pure SQL
- **Warehouse Dependency**: All compute happens in the warehouse, costs scale with query complexity
- **No Streaming**: dbt is batch-only, not suitable for real-time transformations
- **Learning Curve**: Jinja templating, ref() functions, and project conventions take time to learn
- **Orchestration Needed**: dbt itself has no scheduler, requires external orchestrator for production
- **Testing Limitations**: Data tests run after materialization, not before bad data enters the warehouse
- **Macro Complexity**: Heavy Jinja macro usage can make SQL unreadable and hard to debug
- **State Management**: Incremental models require careful handling of late-arriving data
- **No Data Extraction**: dbt only transforms, it does not ingest or extract data
- **Monorepo Challenges**: Large dbt projects with many marts can have long build times and complex dependencies

## Use Cases

- **Business Intelligence**: Building curated datasets for dashboards and reports in Looker, Tableau, or Power BI
- **Financial Reporting**: Creating auditable, tested financial models with full lineage
- **Customer Analytics**: Building customer 360 views by joining data across CRM, payments, and product usage
- **Marketing Attribution**: Combining ad platform data into unified campaign performance marts
- **Product Analytics**: Transforming event data into user behavior metrics and funnels
- **Data Warehouse Modernization**: Replacing stored procedures and legacy ETL with version-controlled SQL
- **Regulatory Compliance**: Documented lineage and tested transformations for audit trails
- **Self-Serve Analytics**: Providing analysts with clean, well-documented datasets they can trust
- **Multi-Source Integration**: Consolidating data from SaaS tools (Stripe, Salesforce, HubSpot) into unified marts
- **Metric Layers**: Defining canonical business metrics in code with dbt metrics or Semantic Layer
