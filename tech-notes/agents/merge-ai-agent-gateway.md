# Merge Gateway

## What is it?

Merge Gateway is an LLM gateway - a single API endpoint that sits in front of every major model provider (OpenAI, Anthropic, Google, AWS Bedrock) and adds intelligent routing, failover, cost management, observability, and security on top. Merge calls it "the control plane for production AI." The pitch is "every model, one API, total control": you stop managing separate provider accounts and SDKs, and instead point all your traffic at one endpoint that handles which model runs, what it costs, and whether it's safe.

It comes from Merge (merge.dev), the company best known for its Unified API for product integrations (HRIS, CRM, ATS, etc.). Gateway is a different product aimed at the same structural problem one layer up: instead of unifying *SaaS integrations* behind one API, it unifies *LLM providers* behind one API.

A naming note worth holding onto: the page titled "AI Agent Gateway" is this LLM control plane. Merge separately ships **Merge Agent Handler** for connecting agents to third-party apps (API + MCP tools). Those are distinct products - this note is about the LLM gateway.

## The problem it solves

If you ship anything on top of LLMs, you accumulate provider sprawl: separate accounts, separate SDKs, separate billing, separate rate limits, and separate failure modes. When one provider has an outage, your product goes down. When a new model ships, you write code to adopt it. When spend balloons, you can't easily see which team or customer caused it. Gateway centralizes all of that into one endpoint so the application code stops caring which provider is behind it.

This is the [[harness]]-adjacent infrastructure layer, not a model: it doesn't make the model smarter, it makes running models in production survivable.

## How it works

You get a Merge Gateway API key and send requests through one endpoint. A routing policy (set per project or as an org default) decides which provider and model actually serves each request. The application doesn't have to name a model at all.

```python
from merge_gateway import MergeGateway

client = MergeGateway(api_key="YOUR_API_KEY")

response = client.responses.create(
    model="openai/gpt-5.2",
    input=[
        {"type": "message", "role": "system", "content": "You are a helpful programming tutor."},
        {"type": "message", "role": "user", "content": "Explain recursion with simple examples."},
    ],
)
print(response.output[0].content[0].text)
```

With a routing policy configured, the `model` field is optional: omit it or pass the sentinel `"default_routing"` and the policy picks the provider and model. Pass `project_id` in the request body to scope a request to a project (for budgets and attribution).

### Drop-in compatibility

You don't have to adopt Merge's SDK. Gateway speaks the major SDK dialects - point any client that allows a custom base URL at it and existing calls work unchanged:

| SDK | Base URL |
|---|---|
| OpenAI | `https://api-gateway.merge.dev/v1/openai` |
| Anthropic | `https://api-gateway.merge.dev/v1/anthropic` |
| AI SDK (Vercel) | `https://api-gateway.merge.dev/v1/ai-sdk` |
| LangChain | `https://api-gateway.merge.dev/v1/openai` |

So migration is usually a one-line base-URL change, not a rewrite.

## The three pillars

### Reliability

Connect to every major LLM through one endpoint. Merge routes each request automatically by **cost, latency, or quality**. Every new model Merge supports becomes available to you automatically - no code changes. When a provider goes down, **failover is instant**. There is also a "Build Your Own Router" option for custom routing logic.

### Efficiency

Cap spend by **project, team, or customer tier** in real time. **Context compression** automatically reduces token usage (and avoids context-window limits) to cut cost. Every dollar is attributable to a model, provider, and team, and all provider invoices consolidate into one. Windmill reports saving "more than $10,000 per month on LLM spend without sacrificing performance" using routing plus spend-cap rules.

### Security & compliance

Built in at the gateway layer, so it applies to all traffic regardless of which app or agent sent it:

- **Prompt injection protection**
- **Data loss prevention** (DLP)
- **Zero data retention**
- **Audit trail**
- **Roles and permissions**
- **Customer blocklist** and **geo-location routing**

Putting these at the gateway is the point: an action-level or content-level guardrail that every request passes through is more robust than asking each downstream app to enforce policy itself.

## Other features

- **Projects** - the unit for budgets, attribution, and scoping.
- **Tool calling** and **web search** - provider-agnostic, through the same endpoint.
- **Multimodal** support.
- **Models catalog** - the supported provider/model list.
- **Building with coding agents / install skills** - docs are agent-friendly (every page has a `.md` form, and `/llms.txt` + `/llms-full.txt` indexes), so a coding agent can wire Gateway in directly.

## Pricing

At launch Merge ran a **zero-markup / zero-fee for 12 months** promotion for accounts that sign up by June 30. Bank/ACH payment gives unlimited zero-fee spend; credit-card accounts get roughly $40,000 of fee coverage (derived from ~$100/month fee coverage over 12 months at ~3% card rates), with fees beyond that billed at standard card rates. Limited to one account per company, verified by email domain, subject to offer terms. You can **bring your own provider API keys**.

## Why it matters for agents

Agents amplify every problem this gateway addresses. An autonomous agent fans out many model calls, can be steered by injected content in tool outputs, and racks up token spend without a human watching the meter. Centralizing routing, spend caps, DLP, and injection protection at one chokepoint means those controls hold no matter how the agent behaves downstream - the same defense-in-depth logic behind [[claude-auto-mode]], applied at the model-access layer instead of the action-approval layer. For multi-agent or multi-tenant products, per-project budgets and attribution are what keep an agent's parallel fan-out from becoming an unbounded bill.

The honest caveat: a gateway is another hop in the request path and another vendor in the trust chain - it sees your prompts and traffic (mitigated by the zero-data-retention option), and its routing/failover is only as good as its provider coverage. The value is real when you run enough volume across enough providers that centralized routing, cost governance, and security pay for the extra hop; for a single-provider hobby project it's overhead you don't need yet.

## Links

* https://www.merge.dev/gateway
* https://docs.merge.dev/merge-gateway/get-started
* https://docs.merge.dev/merge-gateway/features/routing-policies/overview
* https://docs.merge.dev/merge-gateway/features/context-compression
* https://www.merge.dev/pricing-gateway
* https://www.merge.dev/case-studies/windmill-gateway
* https://www.merge.dev/merge-agent-handler
* https://www.merge.dev/blog/ai-agent-integration-platforms
