# Agent Memory

## 1. What is Agent Memory?

Agent memory is the ability of an AI agent to store, retrieve, and use information across interactions. Without memory, an agent starts fresh every conversation -- it forgets past context, user preferences, and learned knowledge. Memory gives agents continuity, personalization, and the ability to build on prior work. There are multiple types of memory architectures, each with different tradeoffs in terms of capacity, retrieval speed, precision, and cost.

## 2. Types of Memory

```
┌────────────────┬──────────────────────┬──────────────────────┬──────────────────────────┐
│     Type       │     Short-Term       │     Long-Term        │     Episodic             │
├────────────────┼──────────────────────┼──────────────────────┼──────────────────────────┤
│ What it stores │ Current conversation │ Facts, preferences   │ Past interactions        │
├────────────────┼──────────────────────┼──────────────────────┼──────────────────────────┤
│ Lifespan       │ Single session       │ Persistent           │ Persistent               │
├────────────────┼──────────────────────┼──────────────────────┼──────────────────────────┤
│ Storage        │ Context window       │ Files, DB, vectors   │ Conversation logs        │
├────────────────┼──────────────────────┼──────────────────────┼──────────────────────────┤
│ Retrieval      │ Already in context   │ Search/lookup        │ Similarity search        │
├────────────────┼──────────────────────┼──────────────────────┼──────────────────────────┤
│ Analogy        │ Working memory (RAM) │ Knowledge (notebook) │ Autobiography (journal)  │
├────────────────┼──────────────────────┼──────────────────────┼──────────────────────────┤
│ Cost           │ Tokens per turn      │ Storage + retrieval  │ Embedding + search       │
└────────────────┴──────────────────────┴──────────────────────┴──────────────────────────┘
```

**Short-Term Memory**: The conversation history within the current context window. This is the simplest form -- everything said so far is visible to the model. Limited by context window size (8K to 200K tokens depending on model). When the window fills up, older messages get dropped or summarized.

**Long-Term Memory**: Persisted information that survives across sessions. Can be implemented as:
- **File-based**: Markdown files, JSON, YAML stored on disk (Claude Code's CLAUDE.md, memory files)
- **Database-backed**: SQL or NoSQL stores for structured facts (user preferences, project context)
- **Vector-based (RAG)**: Embeddings stored in vector databases for semantic retrieval

**Episodic Memory**: Records of past interactions and experiences. The agent can recall "last time we discussed X, we decided Y." Useful for maintaining continuity across long-running projects.

**Semantic Memory**: General knowledge and facts extracted from interactions. "The user prefers Python over Java" or "This project uses PostgreSQL."

**Procedural Memory**: Learned patterns for how to accomplish tasks. "When deploying this service, always run migrations first." Often encoded in system prompts or tools rather than stored dynamically.

## 3. Memory Architectures

### RAG (Retrieval-Augmented Generation)

The most common architecture for agent memory at scale. Information is converted to embeddings (dense vector representations) and stored in a vector database. At query time, the user's input is embedded and the most similar stored vectors are retrieved and injected into the context.

```
┌──────────┐    embed    ┌──────────────┐    store    ┌──────────────┐
│ Document │────────────>│  Embeddings  │────────────>│ Vector DB    │
└──────────┘             └──────────────┘             └──────┬───────┘
                                                             │
┌──────────┐    embed    ┌──────────────┐    search   ┌──────┴───────┐
│  Query   │────────────>│ Query Vector │────────────>│  Top-K Match │
└──────────┘             └──────────────┘             └──────┬───────┘
                                                             │
                                                     ┌───────v───────┐
                                                     │ Inject into   │
                                                     │ LLM Context   │
                                                     └───────────────┘
```

### Conversation Buffer

Store the full conversation history. Simple but hits context limits fast.

### Conversation Summary

Periodically summarize older messages to compress history. Keeps the gist while reducing token count. Loses detail.

### Sliding Window

Keep only the last N messages. Simple, predictable token usage. Forgets everything outside the window.

### Entity Memory

Extract and maintain a database of entities (people, projects, concepts) and their attributes from conversations. Good for tracking facts about specific things.

### Knowledge Graph

Store facts as triples (subject, predicate, object) in a graph database. Enables relationship-based queries. More complex to build and maintain but powerful for reasoning about connections.

## 4. PROS of Memory Systems

- **Continuity**: Agents remember context across sessions, reducing repetition and re-explanation
- **Personalization**: Agents adapt to user preferences, coding style, and domain expertise over time
- **Scalability**: RAG-based memory can handle millions of documents without hitting context limits
- **Cost Efficiency**: Retrieving only relevant context is cheaper than stuffing everything into the prompt
- **Better Decisions**: Access to historical context improves agent reasoning and reduces hallucination
- **Team Knowledge**: Shared memory allows multiple agents or users to benefit from accumulated knowledge

## 5. CONS of Memory Systems

- **Retrieval Quality**: Semantic search is approximate -- it can miss relevant info or return irrelevant results
- **Stale Data**: Memories can become outdated, leading agents to act on information that is no longer true
- **Privacy Concerns**: Persistent memory stores sensitive information that needs proper access controls and data retention policies
- **Complexity**: Adding memory increases system complexity (embedding pipeline, vector DB, retrieval tuning)
- **Cost**: Embedding generation, vector storage, and similarity search all have ongoing costs
- **Hallucination Risk**: If the memory contains incorrect information, the agent will confidently use it
- **Cold Start**: New agents or users start with empty memory, no personalization until enough interactions accumulate

## 6. Implementation Approaches

```
┌──────────────────┬────────────────────────┬──────────────────┬───────────────────────┐
│    Approach      │       Tools            │    Best For      │     Complexity        │
├──────────────────┼────────────────────────┼──────────────────┼───────────────────────┤
│ File-based       │ Markdown, JSON files   │ Small projects   │ Low                   │
├──────────────────┼────────────────────────┼──────────────────┼───────────────────────┤
│ SQLite/SQL       │ SQLite, PostgreSQL     │ Structured facts │ Low-Medium            │
├──────────────────┼────────────────────────┼──────────────────┼───────────────────────┤
│ Vector DB        │ Pinecone, Qdrant       │ Large knowledge  │ Medium                │
├──────────────────┼────────────────────────┼──────────────────┼───────────────────────┤
│ Managed Memory   │ Mem0, Zep              │ Plug-and-play    │ Low (managed service) │
├──────────────────┼────────────────────────┼──────────────────┼───────────────────────┤
│ Knowledge Graph  │ Neo4j, Amazon Neptune  │ Relationships    │ High                  │
├──────────────────┼────────────────────────┼──────────────────┼───────────────────────┤
│ Hybrid           │ Vector + SQL + Files   │ Production apps  │ High                  │
└──────────────────┴────────────────────────┴──────────────────┴───────────────────────┘
```

## 7. Real-World Memory Implementations

**Claude Code**: Uses file-based memory. CLAUDE.md for project context, ~/.claude/ for user preferences and memories stored as markdown files with frontmatter. Simple, transparent, version-controllable.

**ChatGPT**: Server-side memory that extracts and stores facts from conversations. User can view and manage stored memories. Automatically recalled in future conversations.

**Mem0**: Open-source memory layer that extracts facts from conversations and stores them as embeddings. Supports user-level, session-level, and agent-level memory. Works with any LLM framework.

**Zep**: Long-term memory service for AI assistants. Extracts entities and relationships, builds temporal knowledge graphs, and provides semantic search over conversation history.

**LangChain/LangGraph**: Provides memory abstractions (ConversationBufferMemory, ConversationSummaryMemory, VectorStoreRetrieverMemory) that plug into chains and graphs.

**Strands Agents**: Integrates with Mem0, Bedrock Knowledge Bases, Elasticsearch, and MongoDB Atlas for memory.

## 8. Code Sample - Simple File-Based Memory (Python)

```python
import json
from pathlib import Path

class FileMemory:
    def __init__(self, path: str = "memory.json"):
        self.path = Path(path)
        self.data = self._load()

    def _load(self) -> dict:
        if self.path.exists():
            return json.loads(self.path.read_text())
        return {"facts": [], "preferences": {}}

    def _save(self):
        self.path.write_text(json.dumps(self.data, indent=2))

    def add_fact(self, fact: str):
        if fact not in self.data["facts"]:
            self.data["facts"].append(fact)
            self._save()

    def set_preference(self, key: str, value: str):
        self.data["preferences"][key] = value
        self._save()

    def get_context(self) -> str:
        facts = "\n".join(f"- {f}" for f in self.data["facts"])
        prefs = "\n".join(f"- {k}: {v}" for k, v in self.data["preferences"].items())
        return f"Known facts:\n{facts}\n\nPreferences:\n{prefs}"

memory = FileMemory()
memory.add_fact("User prefers Python over Java")
memory.set_preference("code_style", "minimal, no comments")
print(memory.get_context())
```

## 9. Code Sample - RAG Memory with Embeddings (Python)

```python
import numpy as np
from openai import OpenAI

client = OpenAI()

class VectorMemory:
    def __init__(self):
        self.texts = []
        self.embeddings = []

    def add(self, text: str):
        response = client.embeddings.create(
            model="text-embedding-3-small",
            input=text
        )
        self.texts.append(text)
        self.embeddings.append(response.data[0].embedding)

    def search(self, query: str, top_k: int = 3) -> list[str]:
        response = client.embeddings.create(
            model="text-embedding-3-small",
            input=query
        )
        query_vec = np.array(response.data[0].embedding)
        scores = [
            np.dot(query_vec, np.array(emb))
            for emb in self.embeddings
        ]
        top_indices = np.argsort(scores)[-top_k:][::-1]
        return [self.texts[i] for i in top_indices]

memory = VectorMemory()
memory.add("The project uses PostgreSQL 16 with pgvector extension")
memory.add("Deployments go through staging first, then production")
memory.add("The team prefers trunk-based development")

results = memory.search("what database do we use?")
for r in results:
    print(r)
```

## 10. Choosing a Memory Strategy

```
Is your knowledge base small (< 100 items)?
├── Yes -> File-based or SQLite
└── No
    ├── Do you need semantic/fuzzy search?
    │   ├── Yes -> Vector DB (Pinecone, Qdrant, Weaviate)
    │   └── No -> SQL database
    └── Do you need relationship queries?
        ├── Yes -> Knowledge Graph (Neo4j)
        └── No -> Vector DB + SQL hybrid
```

For most agent applications, start with file-based memory (simple, debuggable, version-controllable) and move to vector-based RAG only when the knowledge base grows beyond what fits in a context window.
