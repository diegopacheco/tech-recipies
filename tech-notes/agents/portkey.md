# Portkey

## 1. What is it?

Portkey AI Gateway is an open-source, blazing-fast AI gateway written in TypeScript that acts as a unified control plane for routing, observing, and governing requests to 1,600+ LLMs and AI providers. It brings production reliability to GenAI workloads with minimal code changes, integrating in under 2 minutes with a 122kb footprint and sub-millisecond overhead. It combines routing, reliability, observability, guardrails, and governance into a single package.

- GitHub: github.com/Portkey-AI/gateway -- 10,200+ stars
- Language: TypeScript
- Latest version: 1.8.2 (gateway), 3.0.3 (npm SDK)
- License: MIT
- Install (Python): `pip install portkey-ai`
- Install (Node): `npm i portkey-ai`
- Install (Self-host): `npx @portkey-ai/gateway`

## 2. Main Features

- Unified API access to 1,600+ LLMs (OpenAI, Anthropic, Gemini, Mistral, Cohere, Bedrock, Vertex AI, Azure, Ollama, and more)
- Automatic retries with exponential backoff (up to 5 retries per request)
- Load balancing across multiple API keys and providers with configurable weights
- Fallback routing: automatically switch to a backup model or provider on failure
- Virtual Keys: secure abstraction layer over raw API keys with rotate, revoke, and monitor capabilities
- Semantic and simple caching to reduce costs and improve latency
- 50+ built-in AI guardrails for input/output validation, content filtering, PII detection, and prompt injection prevention
- Full observability with 40+ metadata fields per request including cost, latency, tokens, and accuracy
- End-to-end distributed tracing connecting model calls, tool invocations, and agent steps
- Prompt management with versioning, A/B testing, and rollback
- Multi-modal support: text, vision, audio (TTS/STT), and image generation models
- MCP (Model Context Protocol) compatibility for agentic workflows
- Enterprise features: SSO, audit trails, RBAC, compliance controls
- Drop-in replacement compatible with the OpenAI SDK interface

## 3. Pros

- Extremely low latency overhead (~1ms) and tiny binary footprint (122kb)
- Open source (MIT) with a self-hosted option requiring zero vendor lock-in
- Drop-in OpenAI SDK compatibility means minimal migration effort
- Unified API surface eliminates the need to learn provider-specific SDKs
- Virtual key vault decouples secret management from application code
- Semantic caching meaningfully reduces LLM API costs for repetitive workloads
- 1,600+ provider integrations is one of the largest in the ecosystem
- Integrated guardrails reduce the need for a separate content-safety service
- Deep observability and tracing built-in without a separate monitoring tool
- Agent and MCP support future-proofs the stack for agentic AI workflows
- Enterprise-ready with SOC 2, SSO, and audit trail support

## 4. Cons

- Real-world latency overhead can reach 20-40ms when using advanced guardrails and complex routing
- In third-party benchmarks, Portkey had 65% higher latency than Kong AI Gateway under load
- Free (Dev) tier caps at 10,000 monthly logs (~330 requests/day), very low for production use
- Pro tier charges $9 per additional 100K logs, which adds up at scale
- Full enterprise feature set (SSO, audit trails, advanced guardrails) requires paid plans starting at $49/month
- Complex routing configurations add setup overhead
- Lacks native model training, fine-tuning, or MLOps capabilities
- Self-hosting requires Node.js infrastructure and ongoing maintenance
- Smaller community compared to LiteLLM for pure open-source use cases

## 5. Comparison

| Feature | Portkey | LiteLLM | OpenRouter | RouteLLM |
|---|---|---|---|---|
| Type | Full AI Gateway + Control Plane | OpenAI-compatible LLM proxy | Unified LLM API marketplace | Cost-based model routing |
| Open Source | Yes (MIT) | Yes (MIT) | No (SaaS) | Yes (Apache 2.0) |
| Self-hostable | Yes | Yes | No | Yes |
| LLM Providers | 1,600+ | 100+ | 400+ | 2 (strong vs weak model) |
| Language | TypeScript | Python | SaaS | Python |
| Routing Type | Rule-based + config-driven | Rule-based | Provider marketplace | ML-based (trained classifiers) |
| Fallback / Retry | Yes | Yes | Limited | No |
| Load Balancing | Yes (weighted) | Yes | No | No |
| Caching | Yes (simple + semantic) | Yes (Redis) | No | No |
| Guardrails | 50+ built-in | Basic | None | None |
| Observability | Full (40+ fields, traces) | Basic logs | Minimal | None |
| Virtual Keys | Yes | Yes (via proxy) | No | No |
| Prompt Management | Yes | No | No | No |
| Enterprise Features | Yes (SSO, RBAC, audit) | Limited | No | No |
| Best For | Production enterprise GenAI | Self-hosted proxy/cost control | Simple multi-provider access | Cost optimization via smart routing |

## 6. Why is it unique?

Portkey is the only solution that combines all five layers in one package: routing + reliability + observability + guardrails + governance. LiteLLM is a routing proxy. OpenRouter is a marketplace. RouteLLM is a cost-routing research framework. None of them bring all layers together. The Virtual Key Vault as a first-class primitive allows issuing virtual keys that abstract over raw provider API keys with per-key rate limits, budgets, and revocation. Semantic caching built-in means Portkey can cache semantically similar queries, returning cached responses for prompts that mean the same thing even if worded differently. As AI workloads shift to multi-step agent loops, Portkey's end-to-end distributed tracing across tool calls and MCP compatibility makes it one of the few gateways ready for agentic production workloads.

## 7. Simple Usage

```python
from portkey_ai import Portkey

client = Portkey(
    api_key="PORTKEY_API_KEY",
    virtual_key="OPENAI_VIRTUAL_KEY"
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Explain AI gateways in one sentence."}]
)

print(response.choices[0].message.content)
```

With fallback routing (OpenAI -> Anthropic on failure):

```python
from portkey_ai import Portkey, createConfig

config = createConfig({
    "strategy": {"mode": "fallback"},
    "targets": [
        {"virtual_key": "OPENAI_VIRTUAL_KEY", "model": "gpt-4o"},
        {"virtual_key": "ANTHROPIC_VIRTUAL_KEY", "model": "claude-sonnet-4-20250514"}
    ]
})

client = Portkey(api_key="PORTKEY_API_KEY", config=config)

response = client.chat.completions.create(
    messages=[{"role": "user", "content": "What is semantic caching?"}]
)

print(response.choices[0].message.content)
```

With load balancing across two keys:

```python
from portkey_ai import Portkey, createConfig

config = createConfig({
    "strategy": {"mode": "loadbalance"},
    "targets": [
        {"virtual_key": "OPENAI_KEY_1", "weight": 0.7},
        {"virtual_key": "OPENAI_KEY_2", "weight": 0.3}
    ]
})

client = Portkey(api_key="PORTKEY_API_KEY", config=config)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Hello from load balanced routing."}]
)

print(response.choices[0].message.content)
```

Install and run:
```bash
pip install portkey-ai
python main.py
```
