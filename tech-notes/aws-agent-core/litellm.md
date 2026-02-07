# LiteLLM

## What It Is

LiteLLM is an open-source Python library and proxy server by BerriAI that provides a unified interface to call 100+ LLM APIs using the OpenAI API format. It translates requests between your application and providers like OpenAI, Anthropic, Google (Vertex AI/Gemini), AWS Bedrock, Cohere, Mistral, Ollama, Hugging Face, Groq, DeepSeek, and many more through a single consistent API.

- GitHub: [https://github.com/BerriAI/litellm](https://github.com/BerriAI/litellm)
- Docs: [https://docs.litellm.ai](https://docs.litellm.ai)
- PyPI: [https://pypi.org/project/litellm/](https://pypi.org/project/litellm/)
- License: MIT (core), enterprise features under separate license

## How It Works

LiteLLM operates in two modes:

### SDK Mode (Python Library)
The Python SDK wraps `completion()` and `embedding()` calls into a unified interface. You specify the provider and model as a string (e.g., `anthropic/claude-3-opus-20240229`), and LiteLLM translates the OpenAI-compatible request into the native API format. Responses are normalized back to the OpenAI schema.

```python
import litellm

response = litellm.completion(
    model="anthropic/claude-3-opus-20240229",
    messages=[{"role": "user", "content": "Hello"}]
)
print(response.choices[0].message.content)
```

### Proxy Server Mode
A standalone FastAPI server that exposes an OpenAI-compatible REST API. Any application that talks to the OpenAI API can point at the LiteLLM proxy instead.

```bash
pip install 'litellm[proxy]'
litellm --model anthropic/claude-3-opus-20240229 --port 4000
```

Configured via `config.yaml`:

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: openai/gpt-4
      api_key: sk-xxx
  - model_name: gpt-4
    litellm_params:
      model: anthropic/claude-3-opus-20240229
      api_key: sk-ant-xxx

router_settings:
  routing_strategy: least-busy
```

## Main Features

- **Unified API** - Single `completion()`, `acompletion()`, `embedding()` interface across all providers
- **100+ Providers** - OpenAI, Anthropic, Google, AWS Bedrock, Cohere, Mistral, Ollama, Groq, DeepSeek, and more
- **Proxy Server** - OpenAI-compatible REST API server with virtual keys, budgets, and rate limits
- **Routing and Load Balancing** - Strategies: shuffle, least-busy, latency-based, cost-based
- **Fallbacks and Retries** - Automatic retries with configurable fallback models
- **Cost Tracking** - Per request, per user, per team, and per API key cost tracking with budget enforcement
- **Observability** - Integrations with Langfuse, Helicone, LangSmith, Datadog, Prometheus, OpenTelemetry
- **Caching** - In-memory, Redis, S3-based, and semantic caching
- **Authentication** - Virtual API keys, SSO (OIDC), role-based access control, JWT support
- **Guardrails** - Integration with Lakera, Presidio, and custom pre/post-call hooks
- **Streaming** - Full streaming support across providers
- **Function Calling / Tool Use** - Cross-provider support for function calling

## Pros

- Switch between LLM providers by changing a single string
- OpenAI-compatible proxy means any OpenAI SDK/tool works with LiteLLM
- Built-in cost tracking, budgets, and routing reduce operational overhead
- Automatic retries, fallbacks, and load balancing improve resilience
- MIT licensed core, free to use and modify
- Very actively maintained (20k+ GitHub stars)
- Easy setup: one pip install and one line of code
- Centralized management via proxy for teams and organizations

## Cons

- Translation layer adds some latency
- New provider features may lag behind until mappings are updated
- Some provider-specific features may not be fully exposed
- Running the proxy in production requires PostgreSQL + Redis + proxy management
- Enterprise features (SSO, advanced guardrails) are paid
- Debugging through the abstraction layer can be harder
- YAML config can become complex with many models and rules
- Python-only SDK; other languages must use the proxy

## Alternatives

| Tool | Description |
|------|-------------|
| **OpenRouter** | Hosted API gateway for multiple LLM providers, no self-hosting needed |
| **Portkey** | AI gateway with caching, fallbacks, load balancing, observability |
| **Helicone** | Observability and logging proxy for LLM APIs with caching |
| **LangChain** | Broader LLM framework that includes model abstraction |
| **AI Gateway (Cloudflare)** | Managed gateway for AI APIs with caching and rate limiting |
| **Kong AI Gateway** | API gateway with AI-specific plugins |
| **MLflow AI Gateway** | Part of MLflow for managing LLM API endpoints |
| **Unify AI** | Routes requests to the best model based on quality and cost |

## Link to Code

### Basic Usage

```python
import litellm
import os

os.environ["OPENAI_API_KEY"] = "sk-xxx"
os.environ["ANTHROPIC_API_KEY"] = "sk-ant-xxx"

response = litellm.completion(
    model="openai/gpt-4",
    messages=[{"role": "user", "content": "Hello"}],
    temperature=0.7,
    max_tokens=256
)
print(response.choices[0].message.content)
```

### Router with Fallbacks

```python
from litellm import Router

router = Router(
    model_list=[
        {"model_name": "primary", "litellm_params": {"model": "openai/gpt-4", "api_key": "sk-xxx"}},
        {"model_name": "fallback", "litellm_params": {"model": "anthropic/claude-3-sonnet-20240229", "api_key": "sk-ant-xxx"}}
    ],
    fallbacks=[{"primary": ["fallback"]}],
    num_retries=3
)

response = router.completion(model="primary", messages=[{"role": "user", "content": "Hello"}])
```

- GitHub: [https://github.com/BerriAI/litellm](https://github.com/BerriAI/litellm)
- Supported Providers: [https://docs.litellm.ai/docs/providers](https://docs.litellm.ai/docs/providers)
