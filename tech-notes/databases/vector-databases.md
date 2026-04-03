# Vector Databases

## 1. What are Vector Databases?

Vector databases are specialized database systems designed to store, index, and query high-dimensional vectors (embeddings). In the context of AI agents, vector databases are the backbone of RAG (Retrieval-Augmented Generation) and long-term memory systems. When you convert text, images, or any data into embeddings using a model like OpenAI's text-embedding-3 or Cohere's embed-v3, you get vectors with hundreds or thousands of dimensions. Vector databases are optimized to find the most similar vectors to a query vector using approximate nearest neighbor (ANN) search, which is fundamentally different from exact-match queries in traditional databases.

## 2. How They Work

### Embedding
Text (or other data) is converted into a dense vector using an embedding model. Similar concepts end up as nearby vectors in the embedding space.

```
"Python is a programming language"  ->  [0.12, -0.45, 0.78, ..., 0.33]  (1536 dims)
"Java is a programming language"    ->  [0.11, -0.43, 0.76, ..., 0.31]  (1536 dims)  <- similar
"I like pizza"                      ->  [0.89, 0.12, -0.56, ..., -0.22] (1536 dims)  <- different
```

### Indexing
Vectors are organized using specialized index structures for fast similarity search:

```
┌──────────────────┬────────────────────────────────────────────────────────────┐
│  Index Type      │  How it Works                                              │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ HNSW             │ Hierarchical graph where each node connects to neighbors.  │
│                  │ Search navigates graph layers from coarse to fine.          │
│                  │ Best balance of speed and accuracy. Most common.            │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ IVF              │ Clusters vectors into buckets. Search only checks nearby   │
│                  │ clusters. Faster but less accurate than HNSW.               │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Flat (brute)     │ Compares query against every vector. 100% accurate but     │
│                  │ O(n) slow. Only viable for small datasets (< 10K vectors). │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Product Quant.   │ Compresses vectors to reduce memory. Trades accuracy for   │
│                  │ massive memory savings. Good for billion-scale datasets.    │
└──────────────────┴────────────────────────────────────────────────────────────┘
```

### Querying
A query vector is compared against indexed vectors using a distance metric:

```
┌──────────────────┬───────────────────────────────────────────────┐
│  Distance Metric │  Use Case                                     │
├──────────────────┼───────────────────────────────────────────────┤
│ Cosine Similarity│ Text embeddings (most common for NLP)         │
├──────────────────┼───────────────────────────────────────────────┤
│ Euclidean (L2)   │ Image embeddings, spatial data                │
├──────────────────┼───────────────────────────────────────────────┤
│ Dot Product      │ When vectors are already normalized           │
└──────────────────┴───────────────────────────────────────────────┘
```

## 3. Major Vector Databases

### Pinecone

https://www.pinecone.io/

Fully managed, cloud-native vector database. No infrastructure to manage.

**PROS**: Zero-ops (fully managed), fast query performance, scales automatically, metadata filtering, namespaces for multi-tenancy, serverless pricing option, strong uptime SLAs

**CONS**: Cloud-only (can't self-host), vendor lock-in, cost can grow fast at scale, limited querying flexibility compared to self-hosted options, no on-premises option for regulated industries

```python
from pinecone import Pinecone

pc = Pinecone(api_key="YOUR_KEY")
index = pc.Index("my-index")

index.upsert(vectors=[
    {"id": "doc1", "values": [0.12, -0.45, 0.78, ...], "metadata": {"source": "wiki", "topic": "python"}},
    {"id": "doc2", "values": [0.11, -0.43, 0.76, ...], "metadata": {"source": "docs", "topic": "java"}},
])

results = index.query(
    vector=[0.12, -0.44, 0.77, ...],
    top_k=5,
    filter={"topic": "python"},
    include_metadata=True
)
for match in results.matches:
    print(f"{match.id}: {match.score}")
```

### Qdrant

https://qdrant.tech/

Open-source vector database written in Rust. Can be self-hosted or used as a managed cloud service.

**PROS**: Open source (Apache 2.0), self-hostable, Rust performance, rich filtering (payload-based), hybrid search (vector + keyword), built-in quantization, gRPC and REST APIs, great documentation

**CONS**: Self-hosting requires ops expertise, smaller managed cloud compared to Pinecone, newer ecosystem, community support not as large as Elasticsearch/pgvector

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct

client = QdrantClient(url="http://localhost:6333")

client.create_collection(
    collection_name="knowledge",
    vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
)

client.upsert(
    collection_name="knowledge",
    points=[
        PointStruct(id=1, vector=[0.12, -0.45, 0.78, ...], payload={"text": "Python is a language", "source": "wiki"}),
        PointStruct(id=2, vector=[0.11, -0.43, 0.76, ...], payload={"text": "Java is a language", "source": "docs"}),
    ]
)

results = client.query_points(
    collection_name="knowledge",
    query=[0.12, -0.44, 0.77, ...],
    limit=5,
)
for point in results.points:
    print(f"{point.id}: {point.score} - {point.payload['text']}")
```

### Weaviate

https://weaviate.io/

Open-source vector database with built-in vectorization (can generate embeddings for you).

**PROS**: Built-in vectorization (no separate embedding pipeline needed), GraphQL API, hybrid search (vector + BM25), multi-modal (text, images), modules for different embedding models, self-hostable, good for prototyping

**CONS**: GraphQL API has a learning curve, built-in vectorization adds latency, heavier resource footprint than Qdrant, module system can be confusing, performance at very large scale lags behind Qdrant/Pinecone

```python
import weaviate
from weaviate.classes.config import Configure, Property, DataType

client = weaviate.connect_to_local()

collection = client.collections.create(
    name="Document",
    vectorizer_config=Configure.Vectorizer.text2vec_openai(),
    properties=[
        Property(name="text", data_type=DataType.TEXT),
        Property(name="source", data_type=DataType.TEXT),
    ]
)

collection.data.insert({"text": "Python is a programming language", "source": "wiki"})
collection.data.insert({"text": "Java is a programming language", "source": "docs"})

results = collection.query.near_text(
    query="programming languages",
    limit=5
)
for obj in results.objects:
    print(obj.properties["text"])

client.close()
```

### pgvector (PostgreSQL Extension)

https://github.com/pgvector/pgvector

Vector similarity search as a PostgreSQL extension. Use your existing PostgreSQL database for vectors.

**PROS**: No new infrastructure (just a PG extension), SQL interface, ACID transactions, combine vector search with regular SQL queries, battle-tested PostgreSQL reliability, easy to adopt for teams already on PostgreSQL

**CONS**: Performance lags behind purpose-built vector DBs at scale (>10M vectors), limited index types (IVFFlat, HNSW), resource-intensive for high-throughput vector workloads, tuning indexes requires expertise

```sql
CREATE EXTENSION vector;

CREATE TABLE documents (
    id serial PRIMARY KEY,
    text text,
    source text,
    embedding vector(1536)
);

INSERT INTO documents (text, source, embedding)
VALUES ('Python is a language', 'wiki', '[0.12, -0.45, 0.78, ...]');

CREATE INDEX ON documents USING hnsw (embedding vector_cosine_ops);

SELECT id, text, 1 - (embedding <=> '[0.12, -0.44, 0.77, ...]') AS similarity
FROM documents
ORDER BY embedding <=> '[0.12, -0.44, 0.77, ...]'
LIMIT 5;
```

## 4. Comparison

```
┌─────────────────┬───────────────┬───────────────┬───────────────┬───────────────┐
│    Feature      │   Pinecone    │    Qdrant     │   Weaviate    │   pgvector    │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Type            │ Managed       │ Open source   │ Open source   │ PG extension  │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Self-host       │ No            │ Yes           │ Yes           │ Yes           │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Language        │ N/A (SaaS)    │ Rust          │ Go            │ C             │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Index types     │ Proprietary   │ HNSW, custom  │ HNSW          │ IVFFlat, HNSW │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Hybrid search   │ Metadata only │ Yes           │ Yes (BM25)    │ With pg_trgm  │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Built-in embed  │ Yes (inference)│ No           │ Yes (modules) │ No            │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ API             │ REST, gRPC    │ REST, gRPC    │ GraphQL, REST │ SQL           │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ ACID            │ No            │ No            │ No            │ Yes           │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Scale (vectors) │ Billions      │ Billions      │ Hundreds of M │ Millions      │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Best for        │ Zero-ops prod │ Performance   │ Prototyping   │ Existing PG   │
├─────────────────┼───────────────┼───────────────┼───────────────┼───────────────┤
│ Pricing         │ Serverless or │ Free (self)   │ Free (self)   │ Free          │
│                 │ pod-based     │ or managed    │ or managed    │               │
└─────────────────┴───────────────┴───────────────┴───────────────┴───────────────┘
```

## 5. Use Cases for Agents

- **RAG Memory**: Store document embeddings and retrieve relevant chunks when the agent needs context
- **Long-Term Agent Memory**: Store conversation summaries and facts as embeddings, retrieve relevant memories for new conversations
- **Semantic Search**: Agent searches knowledge bases using meaning rather than keywords
- **Deduplication**: Detect near-duplicate content by comparing embedding similarity
- **Recommendation**: Agent suggests related items based on vector similarity
- **Anomaly Detection**: Flag vectors that are far from any cluster (unusual inputs or outputs)
- **Multi-Modal Search**: Store image and text embeddings together, search across modalities

## 6. Choosing a Vector Database

```
Do you already use PostgreSQL?
├── Yes, and dataset is < 5M vectors -> pgvector
├── Yes, but need high-throughput vector search -> Qdrant or Pinecone alongside PG
└── No
    ├── Want zero infrastructure management?
    │   └── Yes -> Pinecone
    └── Want to self-host?
        ├── Need maximum performance -> Qdrant
        ├── Need built-in vectorization -> Weaviate
        └── Need both -> Qdrant (with separate embedding pipeline)
```

For most AI agent use cases, start with pgvector if you already run PostgreSQL. Move to Qdrant (self-hosted) or Pinecone (managed) when you need better performance at scale or dedicated vector search features.
