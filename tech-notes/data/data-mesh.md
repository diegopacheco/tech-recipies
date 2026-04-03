# Data Mesh

## 1. What is Data Mesh?

Data Mesh is a decentralized sociotechnical approach to data architecture that shifts data ownership from centralized data teams to domain-oriented teams. It treats data as a product and applies principles from distributed systems and domain-driven design to data management. Instead of a monolithic data lake or warehouse owned by a central team, each business domain owns and publishes its data as a product.

The concept was introduced by **Zhamak Dehghani** in **2019** while at ThoughtWorks, and later expanded in her book "Data Mesh: Delivering Data-Driven Value at Scale" (2022).

The architecture is built on four core principles:

- **Domain Ownership**: each domain team owns their data end-to-end (ingestion, processing, serving)
- **Data as a Product**: domains treat their data outputs as products with clear SLAs, documentation, and quality guarantees
- **Self-Serve Data Platform**: a shared infrastructure platform that enables domains to build and manage data products autonomously
- **Federated Computational Governance**: global policies and standards applied across all domains through automation

### How it works

1. **Domain Identification**: organization identifies business domains (orders, customers, inventory) and assigns teams responsible for their data
2. **Data Product Creation**: domain teams build data products with discoverable APIs, documentation, and quality metrics
3. **Self-Serve Platform**: central platform team provides infrastructure as a service, abstracting storage, compute, and pipelines
4. **Federated Governance**: global standards for interoperability encoded as code and enforced automatically
5. **Data Consumption**: consumers discover data products through a central catalog and subscribe via standardized interfaces

## 2. Pros

- **Scalability**: distributes data work across multiple teams, avoiding central bottlenecks
- **Domain Expertise**: data owned by teams who understand the business context
- **Faster Time to Value**: domains can iterate independently without waiting for central teams
- **Data Quality**: clear ownership improves accountability and data quality
- **Agility**: teams can evolve their data products without affecting others
- **Reduced Coupling**: domains are decoupled through well-defined interfaces
- **Better Alignment**: data architecture mirrors organizational structure

## 3. Cons

- **Organizational Change**: requires significant cultural and organizational transformation
- **Coordination Overhead**: maintaining interoperability across domains is challenging
- **Duplication Risk**: similar data may be duplicated across domains
- **Skill Requirements**: each domain team needs data engineering expertise
- **Governance Complexity**: balancing autonomy with global standards is difficult
- **Initial Investment**: building self-serve platform requires upfront effort
- **Not for Small Organizations**: overhead may not be justified for smaller companies
- **Cross-Domain Queries**: joining data across domains can be complex and slow

## 4. Comparisons with Other Architectures

### Data Mesh vs Data Lake

| Aspect | Data Mesh | Data Lake |
|---|---|---|
| Ownership | Decentralized, domain teams | Centralized data team |
| Data Model | Domain-specific schemas | Schema-on-read, raw storage |
| Governance | Federated, automated policies | Centralized governance |
| Scaling | Scales with number of domains | Scales with storage/compute |
| Risk | Duplication across domains | Data swamp (ungoverned dumping) |
| Best for | Large orgs with many domains | Exploratory analytics, ML pipelines |

### Data Mesh vs Data Warehouse

| Aspect | Data Mesh | Data Warehouse |
|---|---|---|
| Ownership | Domain teams | Central BI/DW team |
| Data Model | Polyglot, domain-driven | Star/snowflake schema, normalized |
| Flexibility | High, each domain evolves independently | Low, schema changes are costly |
| Latency | Varies by domain product | Batch-oriented, higher latency |
| Best for | Distributed organizations | Structured reporting and BI |

### Data Mesh vs Data Lakehouse

| Aspect | Data Mesh | Data Lakehouse |
|---|---|---|
| Architecture | Decentralized, multiple data products | Unified platform (lake + warehouse) |
| Ownership | Domain teams | Central or platform team |
| Technology | Any stack per domain | Single stack (Delta Lake, Iceberg, Hudi) |
| Query Engine | Per domain choice | Unified query engine |
| Best for | Organizational scalability | Technical unification of analytics and ML |

### Data Mesh vs ETL/ELT Pipelines

| Aspect | Data Mesh | Traditional ETL/ELT |
|---|---|---|
| Pipeline Ownership | Domain teams build and own | Central data engineering team |
| Coupling | Loose, via data product APIs | Tight, pipelines coupled to sources |
| Bottleneck | Distributed, no single bottleneck | Central team becomes bottleneck |
| Change Management | Domain-local changes | Cascading pipeline changes |
| Best for | Many independent data producers | Simple, well-defined data flows |

### Data Mesh vs Lambda/Kappa Architecture

| Aspect | Data Mesh | Lambda/Kappa |
|---|---|---|
| Focus | Organizational and ownership model | Technical processing model |
| Scope | End-to-end data management | Stream and batch processing |
| Complexity | Organizational complexity | Technical complexity (dual pipelines in Lambda) |
| Complementary | Yes, a domain can use Lambda/Kappa internally | Yes, can exist inside a Data Mesh domain |

## 5. Who is Using it?

- **Large Enterprises**: organizations with multiple business units and complex data needs
- **E-commerce Platforms**: separating order, inventory, customer, and shipping domains
- **Financial Institutions**: banks with distinct domains like retail, corporate, and trading
- **Healthcare Organizations**: patient data, clinical data, billing as separate domains
- **Streaming Services**: content, user engagement, recommendations as separate data products
- **Logistics Companies**: fleet, warehouse, delivery, and customer domains
- **Insurance Companies**: claims, underwriting, policy, and customer domains
- **Telecommunications**: network, billing, customer service, and marketing domains
- **Companies Adopting Microservices**: natural extension of microservices to data

Notable adopters include **JPMorgan Chase**, **Zalando**, **Netflix**, **Intuit**, **PayPal**, and **Saxo Bank**.
