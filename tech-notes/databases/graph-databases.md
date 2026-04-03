# Graph Databases

## What is it?

A graph database is a database that uses graph structures — nodes (vertices), edges (relationships), and properties — to store, query, and traverse data. Unlike relational databases where relationships are expressed through foreign keys and JOINs (computed at query time), graph databases store relationships as first-class citizens alongside the data. Traversing a relationship is a constant-time pointer lookup, not a table scan or index lookup. This makes graph databases orders of magnitude faster than relational databases for queries that involve multiple hops across relationships — friend-of-a-friend, shortest path, recommendation engines, fraud detection, and knowledge graphs.

## How it works?

### Data Model: Property Graph

```
The property graph model (used by Neo4j, Amazon Neptune, Memgraph):

Nodes have:
  - Labels (types): Person, Company, Product
  - Properties: {name: "Alice", age: 30}

Edges have:
  - Type: WORKS_AT, KNOWS, PURCHASED
  - Direction: (Alice)-[WORKS_AT]->(Acme)
  - Properties: {since: 2020, role: "engineer"}


    (Alice)──[KNOWS {since: 2015}]──►(Bob)
       │                                │
       │                                │
  [WORKS_AT                        [WORKS_AT
   {since: 2020}]                   {since: 2019}]
       │                                │
       ▼                                ▼
    (Acme Corp)                     (Beta Inc)
       │                                │
  [LOCATED_IN]                     [LOCATED_IN]
       │                                │
       ▼                                ▼
    (New York)                      (London)
```

### Data Model: RDF (Resource Description Framework)

```
RDF uses triples: (subject, predicate, object)

  <Alice>  <knows>      <Bob>
  <Alice>  <worksAt>    <AcmeCorp>
  <Alice>  <age>        "30"^^xsd:integer
  <AcmeCorp> <locatedIn> <NewYork>

Everything is a URI or literal. No properties on edges.
Edges are modeled as additional triples.

SPARQL query:
  SELECT ?person ?company WHERE {
    ?person <worksAt> ?company .
    ?company <locatedIn> <NewYork> .
  }
```

### Property Graph vs RDF

```
┌─────────────────────┬──────────────────┬──────────────────────┐
│ Aspect              │ Property Graph   │ RDF                  │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Data unit           │ Nodes + Edges    │ Triples (S, P, O)    │
│                     │ with properties  │                      │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Schema              │ Optional labels  │ OWL / RDFS ontology  │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Query language      │ Cypher, Gremlin  │ SPARQL               │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Edge properties     │ Native           │ Reification needed   │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Standards           │ GQL (ISO), openCypher│ W3C standard     │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Interoperability    │ Vendor-specific  │ Universal (URIs)     │
├─────────────────────┼──────────────────┼──────────────────────┤
│ Best for            │ Application data │ Knowledge graphs,    │
│                     │ (social, fraud)  │ linked data, ontology│
└─────────────────────┴──────────────────┴──────────────────────┘
```

### Storage: Index-Free Adjacency

```
Relational (JOIN-based):

  Person Table:                    Knows Table:
  ┌────┬───────┐                  ┌──────────┬──────────┐
  │ id │ name  │                  │ person_id│ friend_id│
  ├────┼───────┤                  ├──────────┼──────────┤
  │ 1  │ Alice │                  │ 1        │ 2        │
  │ 2  │ Bob   │                  │ 2        │ 3        │
  │ 3  │ Carol │                  └──────────┴──────────┘
  └────┴───────┘

  "Friends of friends of Alice" = 2 JOINs
  Cost grows with table size (O(n) per JOIN)


Graph (index-free adjacency):

  Node: Alice
    edges: ──► [Bob]         ← direct pointer, O(1)

  Node: Bob
    edges: ──► [Carol]       ← direct pointer, O(1)

  "Friends of friends of Alice":
    Alice → follow pointer → Bob → follow pointer → Carol
    Cost depends on number of relationships, NOT total graph size
    O(k) where k = number of edges traversed
```

### Query: Cypher (Neo4j)

```
Find friends of friends:
  MATCH (a:Person {name: "Alice"})-[:KNOWS]->(friend)-[:KNOWS]->(fof)
  RETURN fof.name

Shortest path:
  MATCH p = shortestPath(
    (a:Person {name: "Alice"})-[:KNOWS*]-(b:Person {name: "Dave"})
  )
  RETURN p

Recommendation (people you may know):
  MATCH (a:Person {name: "Alice"})-[:KNOWS]->(friend)-[:KNOWS]->(suggestion)
  WHERE NOT (a)-[:KNOWS]->(suggestion) AND suggestion <> a
  RETURN suggestion.name, COUNT(friend) AS mutual_friends
  ORDER BY mutual_friends DESC
  LIMIT 10

Fraud ring detection:
  MATCH (a:Account)-[:TRANSFERRED_TO]->(b:Account)-[:TRANSFERRED_TO]->(c:Account)
        -[:TRANSFERRED_TO]->(a)
  RETURN a, b, c
```

## Major Graph Databases

```
┌──────────────────┬────────────┬───────────────────────────────────┐
│ Database         │ Model      │ Details                            │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Neo4j            │ Property   │ Market leader. Cypher query lang. │
│                  │ Graph      │ ACID. Clustering (Enterprise).    │
│                  │            │ Native graph storage engine.      │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Amazon Neptune   │ Both       │ Managed AWS. Supports both        │
│                  │ (PG + RDF) │ Gremlin (PG) and SPARQL (RDF).   │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Memgraph         │ Property   │ In-memory. Cypher-compatible.     │
│                  │ Graph      │ Real-time streaming integration.  │
├──────────────────┼────────────┼───────────────────────────────────┤
│ JanusGraph       │ Property   │ Open-source. Distributed. Uses   │
│                  │ Graph      │ Cassandra/HBase for storage,     │
│                  │            │ Elasticsearch for indexing.       │
├──────────────────┼────────────┼───────────────────────────────────┤
│ TigerGraph       │ Property   │ Distributed. GSQL query lang.    │
│                  │ Graph      │ Parallel graph computation.      │
├──────────────────┼────────────┼───────────────────────────────────┤
│ ArangoDB         │ Multi-model│ Document + Graph + Key-Value.    │
│                  │            │ AQL query language.               │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Dgraph           │ Property   │ Distributed. GraphQL-native.     │
│                  │ Graph      │ DQL (modified GraphQL).          │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Apache AGE       │ Property   │ PostgreSQL extension for graph.  │
│                  │ Graph      │ openCypher on top of Postgres.   │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Stardog          │ RDF        │ Enterprise knowledge graph.      │
│                  │            │ SPARQL, reasoning, inference.    │
├──────────────────┼────────────┼───────────────────────────────────┤
│ Blazegraph       │ RDF        │ Open-source. Powers Wikidata.    │
│                  │            │ SPARQL 1.1 compliant.            │
└──────────────────┴────────────┴───────────────────────────────────┘
```

## Graph vs Relational: When Relationships Dominate

```
Query: "Find all people within 4 degrees of connection from Alice"

Relational (PostgreSQL):
  Depth 2: 0.01s
  Depth 3: 0.1s
  Depth 4: 10s        ← exponential JOIN cost
  Depth 5: timeout     ← impractical

Graph (Neo4j):
  Depth 2: 0.001s
  Depth 3: 0.005s
  Depth 4: 0.02s      ← linear growth
  Depth 5: 0.05s      ← still fast

The deeper the traversal, the bigger the performance gap.
```

## Graph Algorithms

```
┌──────────────────────┬──────────────────────────────────────────┐
│ Algorithm            │ Use Case                                  │
├──────────────────────┼──────────────────────────────────────────┤
│ Shortest Path        │ Navigation, network routing, social      │
│ (Dijkstra, A*)       │ distance                                 │
├──────────────────────┼──────────────────────────────────────────┤
│ PageRank             │ Influence ranking, importance scoring    │
├──────────────────────┼──────────────────────────────────────────┤
│ Community Detection  │ Clustering users, fraud ring detection   │
│ (Louvain, Label Prop)│                                          │
├──────────────────────┼──────────────────────────────────────────┤
│ Centrality           │ Finding influential nodes (betweenness,  │
│                      │ closeness, degree centrality)            │
├──────────────────────┼──────────────────────────────────────────┤
│ Connected Components │ Finding isolated clusters, network       │
│                      │ partitions                               │
├──────────────────────┼──────────────────────────────────────────┤
│ Node Similarity      │ Recommendation, deduplication            │
│ (Jaccard, Cosine)    │                                          │
├──────────────────────┼──────────────────────────────────────────┤
│ Link Prediction      │ Predicting future relationships          │
│                      │ (friend suggestions)                     │
└──────────────────────┴──────────────────────────────────────────┘
```

## Pros

- **Relationship Performance**: traversals are O(k) where k = edges, not O(n) where n = table size
- **Natural Modeling**: graphs map directly to real-world entities and relationships
- **Flexible Schema**: add new node types, labels, and edge types without migration
- **Deep Traversals**: multi-hop queries (3+ levels) are fast and practical
- **Pattern Matching**: Cypher/Gremlin express complex patterns concisely
- **Graph Algorithms**: built-in PageRank, shortest path, community detection
- **Connected Data**: ideal when the value is in the connections, not just the entities
- **Evolving Schema**: no ALTER TABLE — add properties and relationships at any time

## Cons

- **Not for Tabular Data**: aggregations, reporting, and analytical queries are slower than RDBMS/columnar
- **Scaling Challenges**: distributed graph partitioning (graph sharding) is fundamentally hard
- **No Standard Language**: Cypher, Gremlin, SPARQL, GSQL, DQL — fragmented ecosystem (GQL ISO standard in progress)
- **Smaller Ecosystem**: fewer ORMs, fewer managed services, less community tooling than relational
- **Batch Processing**: bulk inserts and full-graph analytics are slower than purpose-built analytics engines
- **Super Nodes**: nodes with millions of edges (celebrities in social graphs) degrade traversal performance
- **Transaction Scope**: distributed graph transactions across partitions are complex
- **Maturity**: fewer production deployments, less battle-testing than PostgreSQL/MySQL

## Use Cases

- **Social Networks**: friend recommendations, mutual connections, influence graphs
- **Fraud Detection**: ring detection, suspicious transaction chains, identity resolution
- **Knowledge Graphs**: Google Knowledge Graph, Wikidata, enterprise knowledge management
- **Recommendation Engines**: "customers who bought X also bought Y" via collaborative filtering on graphs
- **Network / IT Operations**: dependency mapping, impact analysis, root cause analysis
- **Identity and Access Management**: who has access to what, through which roles and groups
- **Supply Chain**: tracing components through multi-tier supplier networks
- **Drug Discovery**: molecular interaction networks, protein-protein interactions
- **Master Data Management**: linking customer, product, and organizational data across systems
- **Genealogy**: family trees, ancestry networks
