# Data Architecture Concepts

##  Entity Model

- Represents business objects and their relationships in a domain
- Focuses on structure: entities, attributes, and relationships
- Used in application design (e.g., ORM models, database schemas)
- Example: Customer, Order, Product with foreign keys linking them

## Canonical Data Model (CDM)

- A standardized, enterprise-wide data format for integration
- Acts as a "common language" between systems
- Decouples source/target systems - each system translates to/from the canonical format
- Reduces integration complexity from O(n²) to O(n)
- Example: All systems (CRM, ERP, billing) agree on a single Customer schema for data exchange

## Data Mart

- A subset of a data warehouse optimized for a specific business area
- Pre-aggregated, denormalized data for analytics/reporting
- Read-optimized, not for transactional use
- Example: A "Sales Data Mart" with pre-calculated metrics like monthly revenue by region

## Key Differences

```
┌───────────────┬───────────────────────┬──────────────────────┬──────────────────────┐
│    Aspect     │     Entity Model      │ Canonical Data Model │      Data Mart       │
├───────────────┼───────────────────────┼──────────────────────┼──────────────────────┤
│ Purpose       │ Application structure │ System integration   │ Analytics/reporting  │
├───────────────┼───────────────────────┼──────────────────────┼──────────────────────┤
│ Scope         │ Single application    │ Enterprise-wide      │ Business unit/domain │
├───────────────┼───────────────────────┼──────────────────────┼──────────────────────┤
│ Normalization │ Typically normalized  │ Standardized format  │ Denormalized         │
├───────────────┼───────────────────────┼──────────────────────┼──────────────────────┤
│ Users         │ Developers            │ Integration teams    │ Analysts/BI tools    │
├───────────────┼───────────────────────┼──────────────────────┼──────────────────────┤
│ Operations    │ CRUD                  │ Transform/translate  │ Read-only queries    │
└───────────────┴───────────────────────┴──────────────────────┴──────────────────────┘
```

In short: Entity models define structure, CDMs enable interoperability, and data marts enable analysis.