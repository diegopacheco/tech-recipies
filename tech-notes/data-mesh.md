# Data Mesh

## What is it?

Data Mesh is a decentralized sociotechnical approach to data architecture that shifts data ownership from centralized data teams to domain-oriented teams. It treats data as a product and applies principles from distributed systems and domain-driven design to data management. Instead of a monolithic data lake or warehouse owned by a central team, each business domain owns and publishes its data as a product.

The architecture is built on four core principles:
- **Domain Ownership**: Each domain team owns their data end-to-end (ingestion, processing, serving)
- **Data as a Product**: Domains treat their data outputs as products with clear SLAs, documentation, and quality guarantees
- **Self-Serve Data Platform**: A shared infrastructure platform that enables domains to build and manage data products autonomously
- **Federated Computational Governance**: Global policies and standards applied across all domains through automation

## Who created it? When?

Data Mesh was introduced by **Zhamak Dehghani** in **2019**. She published her foundational article "How to Move Beyond a Monolithic Data Lake to a Distributed Data Mesh" while working as a Principal Technology Consultant at ThoughtWorks. She later expanded on the concept in her book "Data Mesh: Delivering Data-Driven Value at Scale" published in 2022.

## How it works?

1. **Domain Identification**:
   - Organization identifies business domains (e.g., orders, customers, inventory)
   - Each domain is assigned a team responsible for their data

2. **Data Product Creation**:
   - Domain teams build data products from their operational systems
   - Each data product has discoverable APIs, documentation, and quality metrics
   - Products are designed for consumption by other domains

3. **Self-Serve Platform**:
   - Central platform team provides infrastructure as a service
   - Domains use platform tools to build, deploy, and monitor data products
   - Abstracts complexity of storage, compute, and data pipelines

4. **Federated Governance**:
   - Global standards for interoperability (schemas, naming, security)
   - Policies encoded as code and enforced automatically
   - Data product catalog for discovery across domains

5. **Data Consumption**:
   - Consumers discover data products through a central catalog
   - Subscribe to data products via standardized interfaces
   - Cross-domain analytics built by combining multiple data products

## Pros

- **Scalability**: Distributes data work across multiple teams, avoiding central bottlenecks
- **Domain Expertise**: Data owned by teams who understand the business context
- **Faster Time to Value**: Domains can iterate independently without waiting for central teams
- **Data Quality**: Clear ownership improves accountability and data quality
- **Agility**: Teams can evolve their data products without affecting others
- **Reduced Coupling**: Domains are decoupled through well-defined interfaces
- **Better Alignment**: Data architecture mirrors organizational structure

## Cons

- **Organizational Change**: Requires significant cultural and organizational transformation
- **Coordination Overhead**: Maintaining interoperability across domains is challenging
- **Duplication Risk**: Similar data may be duplicated across domains
- **Skill Requirements**: Each domain team needs data engineering expertise
- **Governance Complexity**: Balancing autonomy with global standards is difficult
- **Initial Investment**: Building self-serve platform requires upfront effort
- **Not for Small Organizations**: Overhead may not be justified for smaller companies
- **Cross-Domain Queries**: Joining data across domains can be complex and slow

## Use Cases

- **Large Enterprises**: Organizations with multiple business units and complex data needs
- **E-commerce Platforms**: Separating order, inventory, customer, and shipping domains
- **Financial Institutions**: Banks with distinct domains like retail, corporate, and trading
- **Healthcare Organizations**: Patient data, clinical data, billing as separate domains
- **Streaming Services**: Content, user engagement, recommendations as separate data products
- **Logistics Companies**: Fleet, warehouse, delivery, and customer domains
- **Insurance Companies**: Claims, underwriting, policy, and customer domains
- **Telecommunications**: Network, billing, customer service, and marketing domains
- **Organizations Scaling Data Teams**: When centralized data teams become bottlenecks
- **Companies Adopting Microservices**: Natural extension of microservices to data
