# n8n

## What It Is

n8n (pronounced "nodemation") is an open-source workflow automation platform that connects services, APIs, and applications through visual workflows. It is a self-hostable, source-available alternative to Zapier and Make. Built with TypeScript on Node.js, maintained by n8n GmbH (Berlin).

- GitHub: [https://github.com/n8n-io/n8n](https://github.com/n8n-io/n8n)
- Website: [https://n8n.io](https://n8n.io)
- Docs: [https://docs.n8n.io](https://docs.n8n.io)
- License: Sustainable Use License (source-available, not OSI open-source)

## How It Works

n8n uses a node-based visual workflow editor where each node represents an action, trigger, or data transformation. Workflows are composed by connecting nodes in a directed graph.

### Core Concepts

- **Workflow** - Collection of connected nodes, triggered manually, on schedule (cron), or by events (webhooks)
- **Node** - Building block performing a specific operation (API call, data transform, email, DB query)
- **Trigger Node** - Starts a workflow (webhook, cron, polling)
- **Connections** - Links between nodes defining data flow, supporting branching and merging
- **Credentials** - Securely stored API keys and OAuth tokens
- **Executions** - Each workflow run with full input/output history per node

### Execution Model

1. Trigger fires (webhook, cron, manual, event)
2. Data flows through connected nodes sequentially or in parallel branches
3. Each node processes incoming data items and outputs results
4. Error handling via per-node config or global error workflows

## Main Features

### Workflow Automation
- Visual drag-and-drop editor with 400+ built-in integrations
- Custom code via JavaScript and Python Code nodes
- Sub-workflows for modular logic
- Webhook, cron, and event-based triggers
- Error handling with retry logic and error workflows

### AI Agent Capabilities
- **AI Agent Node** - ReAct pattern agent that reasons, uses tools, observes, and iterates
- **LLM Integration** - OpenAI, Anthropic, Google Gemini, Ollama, Azure OpenAI, HuggingFace
- **Tool Nodes** - HTTP requests, DB queries, code execution, calculators
- **Memory Nodes** - Buffer, window, and vector store-backed memory (Pinecone, Qdrant, Supabase, Zep)
- **Vector Stores** - Pinecone, Qdrant, Chroma, Weaviate, pgvector for RAG workflows
- **Document Loaders** - PDFs, CSVs, web pages, Google Docs
- **Embeddings** - OpenAI, Cohere, HuggingFace, Ollama
- **Chains** - Sequential, retrieval QA, summarization, conversation chains

### Developer Features
- REST API for programmatic workflow management
- CLI for workflow management and execution
- Community nodes via npm
- Custom TypeScript node development

## Pros

- Self-hostable with full data control
- 400+ integrations out of the box
- Visual and code-friendly (JavaScript/Python code nodes)
- First-class AI agent support with LLMs, vector stores, RAG
- Active community (45,000+ GitHub stars)
- Free self-hosted option
- Detailed execution logs for debugging
- Extensible via custom TypeScript nodes
- Full REST API

## Cons

- Sustainable Use License restricts competing as a service (not true open-source)
- Complex data transformations require JavaScript and n8n-specific syntax
- Single-instance scaling limitations (queue mode with Redis needed)
- UI can be slow with very large workflows (100+ nodes)
- No native unit testing framework for workflows
- RBAC, SSO, audit logging require enterprise license
- Community node quality varies
- PostgreSQL required for production

## Alternatives

| Tool | Type | Key Difference |
|------|------|---------------|
| **Zapier** | SaaS | Easier for non-technical users, 6000+ integrations, no self-hosting |
| **Make (Integromat)** | SaaS | Strong visual builder, granular execution control, SaaS-only |
| **Apache Airflow** | Open-source | Python code-first DAG orchestration for data pipelines |
| **Temporal** | Open-source | Durable execution engine for distributed systems |
| **Windmill** | Open-source | Script-based workflow engine (Python, TS, Go, Bash) |
| **Activepieces** | Open-source | MIT-licensed n8n alternative with similar visual builder |
| **LangChain / LangGraph** | Library | Code-first LLM frameworks, more flexible for AI agents |
| **CrewAI** | Library | Multi-agent collaboration patterns |

## Link to Code

### Quick Start with Podman

```bash
podman run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  docker.io/n8nio/n8n
```

### Quick Start with npm

```bash
npx n8n
```

Access at `http://localhost:5678`.

### Custom Node (TypeScript)

```typescript
import {
  IExecuteFunctions,
  INodeExecutionData,
  INodeType,
  INodeTypeDescription,
} from 'n8n-workflow';

export class MyCustomNode implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'My Custom Node',
    name: 'myCustomNode',
    group: ['transform'],
    version: 1,
    description: 'A custom node',
    defaults: { name: 'My Custom Node' },
    inputs: ['main'],
    outputs: ['main'],
    properties: [
      { displayName: 'Value', name: 'value', type: 'string', default: '' },
    ],
  };

  async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
    const items = this.getInputData();
    const results: INodeExecutionData[] = [];
    for (let i = 0; i < items.length; i++) {
      const value = this.getNodeParameter('value', i) as string;
      results.push({ json: { value, processed: true } });
    }
    return [results];
  }
}
```

- GitHub: [https://github.com/n8n-io/n8n](https://github.com/n8n-io/n8n)
- AI Agent Docs: [https://docs.n8n.io/advanced-ai/](https://docs.n8n.io/advanced-ai/)
- Workflow Templates: [https://n8n.io/workflows](https://n8n.io/workflows)
