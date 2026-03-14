# LangFlow

## What It Is

LangFlow is an open-source, visual framework for building multi-agent and RAG (Retrieval-Augmented Generation) applications. It provides a drag-and-drop UI to design, prototype, and deploy AI workflows without writing extensive code. Originally built on LangChain, it has evolved to support a broader ecosystem. LangFlow is maintained by DataStax and is available self-hosted or via DataStax's managed cloud.

- GitHub: [https://github.com/langflow-ai/langflow](https://github.com/langflow-ai/langflow)
- Website: [https://www.langflow.org](https://www.langflow.org)
- Docs: [https://docs.langflow.org](https://docs.langflow.org)
- License: MIT
- Language: Python (backend), TypeScript/React (frontend)
- Stars: 50,000+ on GitHub

## How It Works

LangFlow uses a graph-based architecture where each node represents a component (LLM, prompt template, tool, vector store, retriever, etc.). Users connect nodes visually to create directed acyclic graphs (DAGs).

```
+---------------------------+
|   Browser UI (React)      |
|   Drag & Drop Canvas      |
+-----------+---------------+
            | REST / WebSocket
            v
+-----------+---------------+
|  Python Backend (FastAPI)  |
|  - Flow Engine            |
|  - Component Registry     |
|  - Graph Executor         |
+-----------+---------------+
            |
            v
+-----------+---------------+
|  Components / Integrations |
|  - LLMs, Vector Stores    |
|  - Tools & Agents         |
|  - Document Loaders       |
+---------------------------+
```

1. Users drag components onto the canvas and connect them with edges
2. Each component has typed inputs and outputs
3. The backend traverses the graph topologically, executing each node
4. Every flow is automatically exposed as a REST API endpoint
5. Flows can be exported as JSON for version control

## Main Features

| Feature | Description |
|---|---|
| **Visual Flow Builder** | Drag-and-drop canvas to compose AI pipelines |
| **Multi-Agent Support** | Build multi-agent systems with collaboration and delegation |
| **RAG Pipelines** | Document loaders, text splitters, embeddings, vector stores, retrievers |
| **LLM Integrations** | OpenAI, Anthropic, Gemini, Ollama, HuggingFace, Groq, Cohere, and more |
| **Vector Store Support** | Astra DB, Pinecone, Chroma, Weaviate, Qdrant, FAISS, Milvus |
| **Custom Components** | Create custom Python components and register them in the UI |
| **API Auto-Generation** | Every flow becomes a REST API with auto-generated docs |
| **Chat Interface** | Built-in chat playground for testing flows |
| **Flow Export/Import** | JSON export for sharing and version control |
| **Observability** | Integration with LangSmith and LangFuse |

## Pros

- Low barrier to entry for non-developers
- Rapid prototyping of AI pipelines
- Extensive LLM, vector store, and tool integrations
- Every flow automatically becomes a REST API
- Open source (MIT license)
- Active community with frequent updates
- Custom Python components for extensibility
- Self-hostable for full data control

## Cons

- Visual abstraction makes debugging complex flows harder
- Graph execution engine adds performance overhead
- Large flows become visually cluttered
- Some advanced configurations not exposed in the visual interface
- Core relies on LangChain patterns
- Web UI + backend consume more resources than a simple script
- Rapid development can lead to breaking changes between versions

## Alternatives

| Tool | Description |
|---|---|
| **Flowise** | Node.js-based drag-and-drop UI for LLM flows |
| **Dify** | Open-source LLM app platform with built-in hosting |
| **n8n** | General-purpose workflow automation with AI capabilities |
| **Haystack** | Code-first LLM framework with optional visual editor |
| **CrewAI** | Code-first multi-agent orchestration framework |
| **LangGraph** | Code-first graph-based agent orchestration by LangChain |
| **Rivet** | TypeScript-based visual AI programming environment |
| **Vellum** | Commercial LLM workflow platform with evaluation features |
| **PromptFlow (Azure)** | Microsoft's LLM workflow tool integrated with Azure |

## Link to Code

### Installation

```bash
pip install langflow
langflow run
```

### Using podman

```bash
podman run -it --rm -p 7860:7860 langflowai/langflow:latest
```

### Python API Call

```python
import requests

BASE_URL = "http://localhost:7860"
FLOW_ID = "your-flow-id-here"

def run_flow(message: str) -> dict:
    url = f"{BASE_URL}/api/v1/run/{FLOW_ID}"
    payload = {
        "input_value": message,
        "output_type": "chat",
        "input_type": "chat",
    }
    response = requests.post(url, json=payload)
    return response.json()

result = run_flow("What is retrieval augmented generation?")
print(result)
```

### Custom Component

```python
from langflow.custom import Component
from langflow.io import MessageTextInput, Output
from langflow.schema import Data

class TextProcessorComponent(Component):
    display_name = "Text Processor"
    description = "Processes input text and returns structured data."

    inputs = [
        MessageTextInput(name="input_text", display_name="Input Text", required=True),
    ]

    outputs = [
        Output(display_name="Processed Data", name="output", method="process_text"),
    ]

    def process_text(self) -> Data:
        text = self.input_text
        word_count = len(text.split())
        return Data(data={"text": text, "word_count": word_count})
```

- GitHub: [https://github.com/langflow-ai/langflow](https://github.com/langflow-ai/langflow)
- PyPI: [https://pypi.org/project/langflow](https://pypi.org/project/langflow)
