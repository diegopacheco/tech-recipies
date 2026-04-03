# LiteLLM

## 1. What is it?

LiteLLM is an open-source Python SDK and AI Gateway (proxy server) developed by BerriAI that provides a unified, OpenAI-compatible API to call 100+ LLM providers. It acts as a reverse proxy that normalizes provider-specific request/response schemas (Bedrock, Azure, Anthropic, VertexAI, Cohere, Groq, HuggingFace, NVIDIA NIM, VLLM, Ollama, etc.) into a single consistent interface, eliminating the need to manage separate SDKs, API keys, and billing for each provider.

- GitHub: github.com/BerriAI/litellm -- 37,000+ stars
- Language: Python (>= 3.9)
- Latest version: 1.82.0 (March 2026)
- License: MIT
- Install: `pip install litellm` or `pip install 'litellm[proxy]'`

## 2. Main Features

- Unified OpenAI-format API across 100+ providers (OpenAI, Anthropic, Azure, Bedrock, VertexAI, Cohere, Groq, Mistral, HuggingFace, Ollama, NVIDIA NIM, VLLM, Sagemaker, and more)
- Load balancing and intelligent routing across multiple deployments of the same or different models
- Automatic retries with exponential backoff and fallback to alternate providers on failure
- Virtual keys for multi-tenant access control and per-key rate limiting
- Per-user, per-team, and per-API-key budget enforcement with real-time spend tracking
- Built-in response caching (Redis-backed) to reduce duplicate calls and cut costs
- Guardrails support for input/output validation and content filtering
- Streaming support with unified chunk format across providers
- Async support for high-throughput applications
- Admin dashboard UI for monitoring spend, requests, and model usage
- Observability integrations: Langfuse, Helicone, OpenTelemetry, Prometheus, Datadog
- Lowest-cost routing (computes real-time model pricing to pick cheapest option)
- Configurable via YAML for GitOps and policy-as-code workflows
- Docker/Kubernetes deployable proxy server

## 3. Pros

- Zero vendor lock-in: switch providers by changing a single string in the model parameter
- OpenAI-compatible interface: any existing OpenAI SDK code works with only a base URL change
- Truly self-hostable: runs on your own infrastructure, data never leaves your environment
- MIT licensed and free: no per-request markup, no SaaS fees for the core functionality
- Built-in cost control: budget routing with hard limits per virtual key, user, team, or tag
- Active development: 37k+ GitHub stars, frequent releases, large contributor community
- Broad provider coverage: 100+ providers including niche open-weight models and local inference servers
- Low latency proxy: ~8ms overhead
- Enterprise-ready: virtual keys, RBAC, audit logging, Redis caching, Kubernetes support
- Observability depth: native callbacks into Langfuse, Helicone, OpenTelemetry without extra middleware

## 4. Cons

- Stability at scale: rapid development cycle means frequent regressions between versions
- Operational overhead: running a high-throughput proxy requires Redis dependency, latency serialization, and state management
- Limited beyond routing: does not support model hosting, fine-tuning, or advanced agent workflow tracing
- Configuration complexity: YAML-based proxy configuration can take 15-30 minutes to set up
- Overkill for small teams: teams using only one or two providers gain little from the complexity
- No managed hosted option: unlike OpenRouter or Portkey, you must host and operate it yourself
- Dashboard is basic: functional but lacks depth of enterprise-grade observability tools

## 5. Comparison

| Feature | LiteLLM | Portkey | OpenRouter | RouteLLM |
|---|---|---|---|---|
| Type | Self-hosted proxy/SDK | Managed SaaS gateway | Managed SaaS marketplace | Open-source routing framework |
| License | MIT (open source) | MIT (gateway OSS) | Proprietary (SaaS) | Apache 2.0 (open source) |
| Hosting | Self-hosted | Cloud managed or self-hosted | Cloud only | Self-hosted |
| Providers | 100+ | 1,600+ | 400+ models | Strong/weak model pairs only |
| Pricing | Free (self-host) | Free tier + $49/mo Pro | 5.5% platform fee | Free |
| Load Balancing | Yes (latency, cost, usage) | Yes (weighted) | Yes (automatic) | No |
| Fallbacks | Yes | Yes | Yes | No |
| Cost Tracking | Yes (per key/user/team) | Yes (per workspace) | Basic | No |
| Virtual Keys | Yes (multi-tenant) | Yes (RBAC) | No | No |
| Caching | Yes (Redis) | Yes (simple + semantic) | No | No |
| Guardrails | Yes | Yes (50+ built-in) | No | No |
| Observability | Langfuse, Helicone, OTEL | Built-in + integrations | Minimal | None |
| Best For | Self-hosted enterprise gateway | Managed enterprise gateway | Quick multi-model access | Cost-optimized model routing |

## 6. Why is it unique?

LiteLLM is the only open-source, self-hosted gateway with enterprise multi-tenancy built in. Unlike OpenRouter (SaaS only) or Portkey (paid SaaS), LiteLLM gives full control over data residency, routing logic, and cost enforcement without a per-request fee. Its virtual key system enables complete multi-tenant isolation where different teams or projects each get their own rate limits, budgets, and logging within a single proxy deployment. RouteLLM (the ML-based smart router from LMSYS) is actually built on top of LiteLLM for its completion calls, which validates LiteLLM's role as the foundational open-source layer in the LLM routing ecosystem. The entire proxy configuration is declared in a YAML file that can be version-controlled and deployed via CI/CD pipelines, making it uniquely suited to infrastructure-as-code workflows.

## 7. Simple Usage

```python
import litellm

response = litellm.completion(
    model="gpt-4o",
    messages=[{"role": "user", "content": "What is the capital of France?"}]
)
print(response.choices[0].message.content)
```

Switching providers with zero code change:

```python
import litellm
import os

os.environ["ANTHROPIC_API_KEY"] = "your-key"

response = litellm.completion(
    model="anthropic/claude-sonnet-4-20250514",
    messages=[{"role": "user", "content": "What is the capital of France?"}]
)
print(response.choices[0].message.content)
```

Fallback across providers:

```python
import litellm

response = litellm.completion(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Hello"}],
    fallbacks=["anthropic/claude-sonnet-4-20250514", "gemini/gemini-1.5-pro"],
    num_retries=2
)
print(response.choices[0].message.content)
```

Router with load balancing:

```python
from litellm import Router

router = Router(
    model_list=[
        {"model_name": "gpt-4", "litellm_params": {"model": "gpt-4o", "api_key": "key-1"}},
        {"model_name": "gpt-4", "litellm_params": {"model": "azure/gpt-4", "api_key": "key-2", "api_base": "https://your-azure.openai.azure.com"}},
    ],
    routing_strategy="least-busy"
)

response = router.completion(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello"}]
)
print(response.choices[0].message.content)
```

Install and run:
```bash
pip install litellm
export OPENAI_API_KEY="your-key-here"
python main.py
```
