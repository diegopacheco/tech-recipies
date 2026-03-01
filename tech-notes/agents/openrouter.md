# OpenRouter

## 1. What is it?

OpenRouter is a fully managed, hosted API gateway and marketplace that provides a single unified endpoint to access 400+ large language models from dozens of providers including OpenAI, Anthropic, Google, Meta, Mistral, Cohere, and many open-source model hosts. You sign up, get an API key, point the OpenAI SDK base_url to openrouter.ai, and access any model by its slug. OpenRouter proxies the request to the appropriate upstream provider, normalizes the response in OpenAI-compatible format, and you pay one consolidated bill.

- Website: openrouter.ai
- Users: 2 million+ global users
- Funding: $40 million raised in June 2025 at $500M valuation
- Models: 400+ across all major providers
- Pricing: 5.5% platform fee on credit purchases (card), 5% on crypto
- BYOK: first 1M requests/month free, then 5% of equivalent OpenRouter cost

## 2. Main Features

- Single OpenAI-compatible API endpoint for 400+ models across all major providers
- Automatic provider failover: if a provider goes down, the next available provider is tried automatically
- Smart routing variants: `:nitro` (fastest throughput), `:floor` (lowest cost), auto-router (picks optimal model based on prompt complexity)
- Web search plugin: append `:online` to any model slug to inject real-time web search results with citations into the context
- PDF and image processing support across compatible models with OCR for PDFs
- Zero Token Insurance: no charge for failed/empty responses
- Consolidated billing: one credit balance across all models and providers
- Prompt logging off by default with opt-in logging available
- Zero Data Retention (ZDR) mode for privacy-sensitive workloads
- Model rankings, uptime pages, and per-provider latency visibility in real-time
- Fallback model lists configurable per request
- Integrations with LangChain, LlamaIndex, PydanticAI, TanStack AI
- Free tier with rate-limited access to select models

## 3. Pros

- Zero infrastructure overhead: fully managed, no servers to run or maintain
- Drop-in OpenAI SDK compatibility: often just two lines of code to switch from OpenAI
- Massive model catalog: access GPT-4o, Claude, Llama, Mistral, Gemini, and hundreds more from one key
- Transparent pricing: no hidden markups on base token costs, platform fee is flat and disclosed
- Built-in reliability via automatic failover and multi-provider routing
- Web search augmentation on any model without changing application logic
- Real-time model/provider status and latency tracking publicly visible
- BYOK support lets you use your own provider quotas while keeping the unified interface
- Zero Data Retention mode supports privacy-critical applications
- Single bill simplifies finance and accounting for multi-provider usage
- Zero Token Insurance removes cost risk on failed completions

## 4. Cons

- Adds approximately 25ms of latency overhead per request compared to calling providers directly
- Not suitable for strict enterprise compliance scenarios requiring AWS PrivateLink or air-gapped deployment
- SOC 2 report not publicly downloadable, compliance documentation requires NDA negotiation
- No public uptime SLA, formal guarantees require enterprise contract
- Routing logic (especially auto-router) can be opaque if not actively monitored
- Pay-as-you-go credit model requires active balance management to avoid service interruption
- Rate limits on free-tier models can be unreliable for production workloads
- Dependent on upstream provider feature availability (fine-tuning, embeddings vary by provider)
- Not designed for on-premises or air-gapped enterprise deployments
- No self-hosted option available
- No guardrails, virtual keys, or advanced access control

## 5. Comparison

| Feature | OpenRouter | LiteLLM | Portkey | RouteLLM |
|---|---|---|---|---|
| Type | Hosted SaaS marketplace | Self-hosted proxy/SDK | Managed SaaS + OSS gateway | Open-source routing framework |
| Hosting | Cloud only (no self-hosting) | Self-hosted (Docker) | Self-hosted or managed | Self-hosted |
| Model Catalog | 400+ models | 100+ providers | 1,600+ LLMs | 2 models (strong vs weak) |
| Setup Time | Under 5 minutes | 15-30 minutes | Under 5 minutes | Moderate (needs training) |
| Pricing | 5.5% platform fee | Free (self-host) | Free tier + $49/mo Pro | Free |
| OpenAI Compatible | Yes (drop-in) | Yes (drop-in) | Yes (drop-in) | Partial |
| Failover | Yes (automatic) | Yes (configurable) | Yes (configurable) | No |
| Observability | Basic usage logs | OTEL, Langfuse, Helicone | Full dashboard and tracing | None |
| Guardrails | None | Basic | 50+ built-in | None |
| Enterprise Features | Limited | Rate limits, budgets | SSO, RBAC, audit trails | None |
| Web Search Plugin | Yes (`:online` variant) | No | No | No |
| Unique Routing | `:nitro`, `:floor`, auto-router | Load balancing, fallback | Retry, fallback, canary | ML-based cost-quality router |
| Best For | Zero-infra multi-model access | Self-hosted enterprise gateway | Observability + guardrails | Cost optimization between 2 models |

## 6. Why is it unique?

OpenRouter functions as a live marketplace where providers compete on latency, price, and uptime with rankings publicly visible in real time. Model variants as first-class API concepts (`:nitro`, `:floor`, `:online` suffixes) let you express routing intent directly in the model slug without writing routing logic. Appending `:online` to any model name adds real-time web retrieval powered by Exa.ai to any model in the catalog with no retrieval pipeline to build. Zero Token Insurance means failed completions do not consume credits. LiteLLM gives you breadth but requires infrastructure. Portkey gives you managed hosting but focuses on observability. RouteLLM gives you cost optimization but only between two models. OpenRouter uniquely combines breadth, zero operations, provider competition, and built-in reliability into a single hosted service.

## 7. Simple Usage

```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["OPENROUTER_API_KEY"],
    base_url="https://openrouter.ai/api/v1",
)

response = client.chat.completions.create(
    model="anthropic/claude-sonnet-4",
    messages=[
        {"role": "user", "content": "Explain what OpenRouter is in one paragraph."}
    ],
)

print(response.choices[0].message.content)
```

With fallback routing:

```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["OPENROUTER_API_KEY"],
    base_url="https://openrouter.ai/api/v1",
)

response = client.chat.completions.create(
    model="anthropic/claude-sonnet-4",
    messages=[{"role": "user", "content": "What is the weather in Paris today?"}],
    extra_body={
        "models": ["anthropic/claude-sonnet-4", "openai/gpt-4o"],
        "route": "fallback",
    },
)

print(response.choices[0].message.content)
```

With web search (`:online` variant):

```python
import os
from openai import OpenAI

client = OpenAI(
    api_key=os.environ["OPENROUTER_API_KEY"],
    base_url="https://openrouter.ai/api/v1",
)

response = client.chat.completions.create(
    model="anthropic/claude-sonnet-4:online",
    messages=[{"role": "user", "content": "What happened in AI news this week?"}],
)

print(response.choices[0].message.content)
```

Install and run:
```bash
pip install openai
export OPENROUTER_API_KEY="your-key-here"
python main.py
```
