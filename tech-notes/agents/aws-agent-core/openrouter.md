# OpenRouter

## What It Is

OpenRouter is a unified API gateway for accessing large language models from multiple providers through a single endpoint. It routes requests between your application and dozens of AI providers including OpenAI, Anthropic, Google, Meta, Mistral, Cohere, and others. The platform provides a single OpenAI-compatible API that routes requests to the appropriate provider.

- Website: [https://openrouter.ai](https://openrouter.ai)
- API Docs: [https://openrouter.ai/docs](https://openrouter.ai/docs)
- Models: [https://openrouter.ai/models](https://openrouter.ai/models)

## How It Works

OpenRouter exposes a single REST API endpoint compatible with the OpenAI Chat Completions format:

```
https://openrouter.ai/api/v1/chat/completions
```

1. Sign up at openrouter.ai and get an API key
2. Add credits (pay-as-you-go)
3. Send requests specifying which model you want (e.g., `anthropic/claude-sonnet-4`)
4. OpenRouter routes to the appropriate provider
5. Response is returned in standardized format

Because it is OpenAI-compatible, you can use the official OpenAI SDK by changing the base URL:

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="YOUR_OPENROUTER_API_KEY",
)

completion = client.chat.completions.create(
    model="anthropic/claude-sonnet-4",
    messages=[{"role": "user", "content": "Hello"}],
)
print(completion.choices[0].message.content)
```

Smart routing via `openrouter/auto` picks the best model based on cost, latency, and capability. Fallback routing handles provider outages automatically.

## Main Features

- **Unified API** - One endpoint for 200+ models from 30+ providers, OpenAI-compatible format
- **Model Routing** - Automatic model selection via `openrouter/auto` for cost/speed/quality optimization
- **Provider Fallback** - Automatic failover between providers for high availability
- **OpenAI SDK Compatible** - Drop-in replacement; change base URL and API key
- **Pay-As-You-Go** - Per-token pricing close to original provider rates
- **Free Models** - Some models available free with rate limits
- **Streaming** - Full SSE streaming support
- **Function Calling / Tool Use** - Supports tool use for models that offer it
- **Multi-Modal** - Vision, image inputs where supported
- **Provider Preferences** - Specify preferred/avoided providers per request
- **OAuth/PKCE** - End users can auth with their own OpenRouter accounts
- **Usage Dashboard** - Per-model usage, costs, and request history

## Pros

- Single integration for dozens of providers and hundreds of models
- OpenAI-compatible API makes migration trivial
- No vendor lock-in to any single provider
- Automatic failover increases reliability
- Easy model comparison by swapping the model parameter
- Free tier for prototyping
- Pay-as-you-go without commitments
- Transparent per-model pricing
- New models added quickly after release

## Cons

- Small markup on token pricing vs direct provider access
- Additional network hop adds latency
- Third-party dependency in your critical AI path
- Some provider-specific features not exposed
- Free model rate limits are restrictive
- OpenRouter outage affects all your AI calls
- Credit-based prepaid model requires balance management
- Not suitable where direct provider contracts are required for compliance

## Alternatives

| Alternative | Description |
|---|---|
| **LiteLLM** | Open-source self-hosted OpenAI-compatible proxy for 100+ LLMs |
| **Portkey** | AI gateway with caching, logging, load balancing, fallbacks |
| **Unify AI** | Routes to best provider based on quality, cost, speed |
| **Amazon Bedrock** | AWS managed access to foundation models from multiple providers |
| **Azure AI Model Catalog** | Microsoft's multi-model access through Azure |
| **Google Vertex AI Model Garden** | Google Cloud's multi-model marketplace |
| **Direct Provider APIs** | Using each provider directly for maximum control and lowest cost |

## Link to Code

### Python with OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="YOUR_OPENROUTER_API_KEY",
)

completion = client.chat.completions.create(
    model="anthropic/claude-sonnet-4",
    messages=[{"role": "user", "content": "What is the capital of France?"}],
)
print(completion.choices[0].message.content)
```

### Streaming

```python
stream = client.chat.completions.create(
    model="anthropic/claude-sonnet-4",
    messages=[{"role": "user", "content": "Tell me a story."}],
    stream=True,
)
for chunk in stream:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="", flush=True)
```

### Provider Preferences

```python
completion = client.chat.completions.create(
    model="anthropic/claude-sonnet-4",
    messages=[{"role": "user", "content": "Hello"}],
    extra_body={
        "provider": {
            "order": ["Anthropic", "AWS Bedrock"],
            "allow_fallbacks": True,
        }
    },
)
```

### cURL

```bash
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer YOUR_OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "google/gemini-2.0-flash-001", "messages": [{"role": "user", "content": "Hello"}]}'
```

- Website: [https://openrouter.ai](https://openrouter.ai)
- API Docs: [https://openrouter.ai/docs](https://openrouter.ai/docs)
