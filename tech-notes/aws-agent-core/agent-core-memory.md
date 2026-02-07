# Amazon Bedrock AgentCore Memory

## What It Is

Amazon Bedrock AgentCore Memory is a managed service that provides persistent knowledge and context management for AI agents across sessions. It is part of the Amazon Bedrock AgentCore platform. Memory enables agents to remember user preferences, past interactions, and extracted knowledge, making them more effective over time. The service handles storage, retrieval, and semantic search of agent memories without requiring developers to manage vector databases or embedding pipelines.

- SDK: [https://github.com/aws/bedrock-agentcore-sdk-python](https://github.com/aws/bedrock-agentcore-sdk-python) (memory module)
- Samples: [https://github.com/awslabs/amazon-bedrock-agentcore-samples](https://github.com/awslabs/amazon-bedrock-agentcore-samples)
- Docs: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-get-started.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-get-started.html)

## How It Works

AgentCore Memory provides two primary memory types:

### Semantic Memory
Stores facts, preferences, and knowledge extracted from conversations. The service automatically extracts key information from agent interactions and stores them as semantic memories. These can be queried using natural language for relevant context.

### Episodic Memory
Stores full conversation sessions and interaction history. Agents can retrieve past conversations to maintain context across sessions.

The workflow:
1. During agent execution, conversations are sent to the Memory service
2. The service automatically extracts and indexes relevant information
3. On subsequent interactions, the agent queries Memory for relevant context
4. Retrieved memories are injected into the agent's prompt for personalized responses

```python
from bedrock_agentcore.memory import MemoryClient

memory = MemoryClient(memory_id="my-memory-store")

memory.save_conversation(
    session_id="session-123",
    messages=[
        {"role": "user", "content": "My favorite color is blue"},
        {"role": "assistant", "content": "I'll remember that your favorite color is blue!"}
    ]
)

results = memory.search(
    query="What is the user's favorite color?",
    user_id="user-456"
)
```

## Main Features

- **Semantic Memory** - Automatic extraction and storage of facts, preferences, and knowledge from conversations
- **Episodic Memory** - Full conversation history storage and retrieval
- **Semantic Search** - Natural language queries to find relevant memories
- **Multi-session Persistence** - Memories persist across agent sessions and invocations
- **User-scoped Memory** - Memories can be scoped per user for personalization
- **Automatic Extraction** - The service extracts key information without manual configuration
- **SDK Integration** - Python SDK with simple API for save, search, and manage operations
- **Managed Infrastructure** - No vector databases, embedding models, or indexing pipelines to manage
- **Integration with AgentCore Runtime** - Works seamlessly with agents deployed on AgentCore Runtime

## Pros

- Fully managed; no need to set up vector databases or embedding infrastructure
- Automatic knowledge extraction from conversations
- Semantic search with natural language queries
- Scales automatically with usage
- Tight integration with other AgentCore services
- Reduces boilerplate code for memory management

## Cons

- AWS-only; tied to Amazon Bedrock ecosystem
- New service with limited community adoption and documentation
- Less customization compared to self-managed vector database solutions
- Extraction quality depends on the underlying models
- Pricing model tied to AWS usage
- Limited control over how memories are extracted and ranked
- No self-hosted option

## Alternatives

| Alternative | Description |
|---|---|
| **Zep** | Open-source long-term memory for AI assistants with auto-extraction |
| **Mem0** | Open-source memory layer for AI applications |
| **Pinecone + custom logic** | Self-managed vector database with custom extraction |
| **ChromaDB** | Open-source embedding database for local or self-hosted memory |
| **Weaviate** | Open-source vector database with built-in ML models |
| **LangChain Memory** | Framework-level memory abstractions (Buffer, Summary, Entity) |
| **Redis + vector search** | Redis with vector similarity search for fast memory retrieval |
| **Qdrant** | Open-source vector search engine |

## Link to Code

- Memory Quick Start: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-get-started.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-get-started.html)
- Memory Tutorial Samples: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials)
- Python SDK Memory Module: [https://github.com/aws/bedrock-agentcore-sdk-python/tree/main/src/bedrock_agentcore/memory](https://github.com/aws/bedrock-agentcore-sdk-python/tree/main/src/bedrock_agentcore/memory)
