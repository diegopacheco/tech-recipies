# LangFuse

## What It Is

LangFuse is an open-source LLM engineering platform for observability, tracing, evaluation, prompt management, and analytics for LLM-powered applications. It captures every interaction between your application and LLMs, providing full visibility into complex LLM pipelines, RAG systems, and AI agents. It supports self-hosting via Docker or a managed cloud service.

- GitHub: [https://github.com/langfuse/langfuse](https://github.com/langfuse/langfuse)
- Website: [https://langfuse.com](https://langfuse.com)
- Docs: [https://langfuse.com/docs](https://langfuse.com/docs)
- Python SDK: [https://github.com/langfuse/langfuse-python](https://github.com/langfuse/langfuse-python)
- JS/TS SDK: [https://github.com/langfuse/langfuse-js](https://github.com/langfuse/langfuse-js)

## How It Works

LangFuse instruments your application with lightweight SDKs. The core data model:

- **Trace** - One end-to-end execution (e.g., one user request)
- **Span** - A unit of work within a trace (function call, retrieval step)
- **Generation** - LLM call with model, input/output tokens, latency, cost
- **Event** - Lightweight discrete event within a trace
- **Score** - Numeric or categorical evaluation attached to traces

```
Your App (SDK) ---> LangFuse Server (API) ---> PostgreSQL + ClickHouse
                                                    |
                                              LangFuse Web UI
```

### Integration Patterns

- **Direct SDK** (Python/TypeScript): `langfuse.trace()`, `span()`, `generation()`
- **OpenAI SDK Wrapper**: Drop-in replacement auto-captures all OpenAI calls
- **LangChain Callback**: `CallbackHandler()` for auto-tracing chains and agents
- **LlamaIndex Callback**: Similar integration
- **Flowise / LiteLLM / Vercel AI SDK**: Native integrations
- **OpenTelemetry**: OTLP-based instrumentation
- **REST API**: Direct API for any language

```python
from langfuse import Langfuse

langfuse = Langfuse(
    public_key="pk-...",
    secret_key="sk-...",
    host="https://cloud.langfuse.com"
)

trace = langfuse.trace(name="my-llm-app", user_id="user-123")

span = trace.span(name="retrieval-step", input={"query": "What is LangFuse?"})
span.end(output={"documents": ["doc1", "doc2"]})

generation = trace.generation(
    name="openai-call",
    model="gpt-4",
    input=[{"role": "user", "content": "Hello"}],
    output="Hi there!",
    usage={"input": 10, "output": 5}
)

langfuse.flush()
```

## Main Features

- **Tracing** - Full trace capture with nested spans and generations, latency and token tracking
- **Prompt Management** - Version-controlled prompt templates, runtime fetching, A/B testing
- **Evaluation & Scoring** - Manual, programmatic, and LLM-as-judge evaluations
- **Analytics** - Cost tracking, latency percentiles, token usage trends, user-level analytics
- **Datasets** - Create from production traces, run experiments, compare versions
- **Prompt Playground** - Test prompts in the UI across models
- **Multi-tenancy** - Project-based organization, API key scoping, role-based access

## Pros

- Open source, self-hostable with full data control
- Low overhead async SDK with batched uploads
- Model agnostic (OpenAI, Anthropic, Cohere, Mistral, local models)
- Framework agnostic (LangChain, LlamaIndex, LiteLLM, Vercel AI SDK)
- Rich nested tracing model
- Automatic cost calculation
- Built-in prompt management and evaluation
- OpenTelemetry support
- Active community and frequent releases

## Cons

- Self-hosting requires PostgreSQL + ClickHouse + web server
- ClickHouse adds infrastructure complexity
- Real-time alerting less mature than dedicated APM tools
- UI can slow down with very large trace volumes
- Moved from MIT to ELv2 license for some components
- Advanced features (SSO, RBAC) cloud/enterprise only
- First-class SDKs only for Python and TypeScript
- Data model learning curve

## Alternatives

| Tool | Key Differentiator |
|------|-------------------|
| **LangSmith** | Deep LangChain integration, managed SaaS |
| **Arize Phoenix** | ML observability with LLM support, embeddings analysis |
| **W&B Weave** | Broader ML tracking platform with LLM tracing |
| **Helicone** | Proxy-based, zero-code integration |
| **Braintrust** | Focus on evaluation and experimentation |
| **OpenLLMetry (Traceloop)** | OpenTelemetry-native, any OTLP backend |
| **Datadog LLM Observability** | Enterprise APM ecosystem integration |

## Link to Code

### Full RAG Trace

```python
from langfuse import Langfuse
from openai import OpenAI

langfuse = Langfuse(public_key="pk-lf-...", secret_key="sk-lf-...", host="https://cloud.langfuse.com")
client = OpenAI()

trace = langfuse.trace(name="rag-pipeline", user_id="user-42")

retrieval_span = trace.span(name="document-retrieval", input={"query": "How does LangFuse work?"})
documents = ["LangFuse is an open-source LLM observability platform..."]
retrieval_span.end(output={"documents": documents, "count": len(documents)})

generation = trace.generation(
    name="llm-completion",
    model="gpt-4",
    input=[
        {"role": "system", "content": "Answer based on context: " + str(documents)},
        {"role": "user", "content": "How does LangFuse work?"}
    ]
)
response = client.chat.completions.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": "Answer based on context: " + str(documents)},
        {"role": "user", "content": "How does LangFuse work?"}
    ]
)
generation.end(
    output=response.choices[0].message.content,
    usage={"input": response.usage.prompt_tokens, "output": response.usage.completion_tokens}
)

trace.score(name="user-feedback", value=1, comment="Helpful answer")
langfuse.flush()
```

- GitHub: [https://github.com/langfuse/langfuse](https://github.com/langfuse/langfuse)
- Self-Hosting Guide: [https://langfuse.com/docs/deployment/self-host](https://langfuse.com/docs/deployment/self-host)
