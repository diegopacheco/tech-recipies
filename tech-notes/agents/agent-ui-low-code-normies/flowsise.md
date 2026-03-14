# FlowiseAI (Flowise)

## What It Is

Flowise is an open-source, low-code tool for building LLM applications using a visual drag-and-drop interface. Built on LangChain and LlamaIndex, it lets users create AI workflows, chatbots, and agents without writing extensive code. Written in TypeScript/JavaScript on Node.js with 30,000+ GitHub stars.

- GitHub: [https://github.com/FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise)
- Website: [https://flowiseai.com](https://flowiseai.com)
- Docs: [https://docs.flowiseai.com](https://docs.flowiseai.com)
- License: Apache 2.0

## How It Works

```
Browser (React UI)
    |
    v
Flowise Server (Express.js / Node.js)
    |
    v
LangChain / LlamaIndex Runtime
    |
    v
LLM Providers / Vector DBs / Tools / APIs
```

1. **Canvas** - Web-based drag-and-drop interface for composing nodes
2. **Nodes** - LLM providers, prompt templates, memory, vector stores, document loaders, tools, chains/agents
3. **Connections** - Edges between node ports defining data flow
4. **Chatflows** - Chain-based flows; **Agentflows** - Autonomous agent flows with branching and looping
5. **Execution** - Visual graph compiled to LangChain/LlamaIndex code at runtime
6. **API** - Every flow automatically exposed as a REST API endpoint
7. **Storage** - SQLite (default), MySQL, or PostgreSQL

## Main Features

| Feature | Description |
|---|---|
| **Visual Flow Builder** | Drag-and-drop canvas for LLM chains, agents, RAG pipelines |
| **100+ Integrations** | OpenAI, Anthropic, Gemini, Bedrock, Azure, Ollama, HuggingFace, Cohere, Mistral, Groq |
| **RAG Support** | Document loaders (PDF, CSV, DOCX), text splitters, embeddings, vector stores (Pinecone, Weaviate, Chroma, Qdrant, FAISS) |
| **Agentflows** | Sequential, parallel, conditional branching, looping |
| **Multi-Agent** | Multiple agents collaborating or delegating |
| **Custom Tools** | JavaScript custom tools or any API connection |
| **Chat Memory** | Buffer, Window, Summary, and persistent DB-backed memory |
| **API & SDK** | Auto REST API, Python and TypeScript SDKs |
| **Streaming** | SSE streaming for real-time chat |
| **Marketplace** | Community-shared flow templates |
| **Caching** | Redis or in-memory response caching |

## Pros

- No coding required for functional LLM apps
- Apache 2.0 open source, free self-hosting
- Rapid prototyping (RAG chatbot in minutes)
- Extensive integrations for LLMs, vector DBs, tools
- Every flow becomes an API instantly
- Active community with shared templates
- Custom JavaScript escape hatch for complex logic
- Flexible deployment (Docker, npm, cloud)
- Streaming support

## Cons

- Visual builder limits complex custom logic
- Debugging visual flows harder than debugging code
- Performance overhead from abstraction layer
- Tightly coupled to LangChain/LlamaIndex
- JSON-in-database storage limits Git version control
- Node.js only server
- Single-server architecture by default
- Enterprise features (RBAC, audit) limited in open-source
- Documentation can lag behind features

## Alternatives

| Tool | Description |
|---|---|
| **LangFlow** | Python-based visual LLM flow builder (DataStax) |
| **Dify** | Open-source LLM app platform with model management |
| **n8n** | General-purpose automation with AI capabilities |
| **Rivet** | Developer-focused visual AI programming (TypeScript) |
| **Haystack** | Code-first LLM framework with optional visual editor |
| **Vellum** | Enterprise LLM workflow platform |
| **PromptFlow (Azure)** | Microsoft's LLM workflow tool for Azure |
| **CrewAI** | Code-first multi-agent orchestration |

## Link to Code

### Installation via npm

```bash
npm install -g flowise
npx flowise start
```

### Installation via Docker

```bash
docker pull flowiseai/flowise
docker run -d --name flowise -p 3000:3000 flowiseai/flowise
```

### Using the API (Python)

```python
import requests

API_URL = "http://localhost:3000/api/v1/prediction/<chatflow-id>"

def query(payload):
    response = requests.post(API_URL, json=payload)
    return response.json()

output = query({"question": "What is FlowiseAI?"})
print(output)
```

### Using the Python SDK

```bash
pip install flowise
```

```python
from flowise import Flowise, PredictionData

client = Flowise(base_url="http://localhost:3000")

completion = client.create_prediction(
    PredictionData(
        chatflowId="<chatflow-id>",
        question="What is FlowiseAI?",
        streaming=True
    )
)

for chunk in completion:
    print(chunk)
```

- GitHub: [https://github.com/FlowiseAI/Flowise](https://github.com/FlowiseAI/Flowise)
- npm: [https://www.npmjs.com/package/flowise](https://www.npmjs.com/package/flowise)
- Docker Hub: [https://hub.docker.com/r/flowiseai/flowise](https://hub.docker.com/r/flowiseai/flowise)
