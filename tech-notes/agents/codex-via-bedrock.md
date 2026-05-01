# Codex via Bedrock

## What is Codex via Bedrock?

Codex via Bedrock is the integration that lets OpenAI's Codex coding agent run on top of OpenAI models served from Amazon Bedrock instead of OpenAI's own API. It is the result of an expanded AWS / OpenAI partnership announced in 2026 that puts OpenAI frontier models, the Codex agent, and OpenAI-powered Managed Agents inside Bedrock.

In practice it means a developer can use the Codex CLI, the Codex desktop app, or the Codex VS Code extension with AWS credentials only - no OpenAI API key, no separate OpenAI billing relationship. Inference goes through Bedrock, the bill goes to AWS, and existing AWS controls (IAM, PrivateLink, CloudTrail, guardrails, encryption) apply to every Codex call.

The integration is currently in limited preview.

## How it Works

Codex CLI v0.124.0 added native Bedrock support. The path is:

1. The Codex client (CLI, desktop, VS Code) is configured with a Bedrock provider instead of `api.openai.com`.
2. Requests go to **Bedrock Mantle's Responses API** - Bedrock's compatible implementation of OpenAI's Responses API, which Codex needs for streaming, tool use, and agent loops.
3. AWS SigV4 signs the request with the user's AWS credentials.
4. Bedrock routes the call to the chosen OpenAI model and returns the response.
5. Codex runs its agent loop locally, executing tool calls (file edits, shell commands) on the developer's machine.

The model runs in AWS infrastructure. The agent harness runs on the developer's laptop. Only the inference traffic crosses into Bedrock.

## Supported Models

The launch lineup on Bedrock spans both OpenAI's frontier closed models and the open-weights `gpt-oss` family. All are reachable through the same Bedrock Responses API that Codex CLI uses.

| Model ID | Type | Notes |
|---|---|---|
| `openai.gpt-5.5` | Frontier closed | OpenAI's flagship model, top tier for Codex coding work |
| `openai.gpt-5.4` | Frontier closed | Slightly older frontier tier |
| `openai.gpt-oss-120b` | Open-weights | Larger open model, predictable cost |
| `openai.gpt-oss-20b` | Open-weights | Smaller open model, faster / cheaper |

The April 2026 launch on Bedrock made GPT-5.5, GPT-5.4, `gpt-oss-120b`, and `gpt-oss-20b` available through the same Bedrock APIs customers already use for Anthropic, Meta, and Amazon Nova - and all of them can back Codex through the Responses API on Bedrock.

Note: GPT-5.5 was initially limited to ChatGPT-authenticated Codex sessions on the OpenAI side. On Bedrock, access is governed by AWS IAM and Bedrock model-access grants instead, which is one of the reasons enterprises chose this path.

## Requirements

- An **AWS account** with access to Amazon Bedrock in a region where the OpenAI models are enabled
- Model access granted in the Bedrock console for `openai.gpt-5.5`, `openai.gpt-5.4`, and/or `openai.gpt-oss-*`
- **Codex CLI v0.124.0** or later (or the desktop / VS Code variants with Bedrock support)
- AWS credentials available locally (env vars, `~/.aws/credentials`, or SSO)
- IAM permissions for `bedrock:InvokeModel` and the Responses API actions

## Setup

The exact flags depend on Codex CLI version, but the common pattern is:

```bash
export AWS_REGION=us-west-2
export AWS_PROFILE=my-profile

codex --provider bedrock --model openai.gpt-5.5
codex --provider bedrock --model openai.gpt-oss-120b
```

Some setups instead route Codex through a **Bedrock Access Gateway** - a small Lambda that exposes a Bedrock-backed OpenAI-compatible endpoint. In that mode Codex talks to the gateway URL with a self-defined API key, and the gateway calls Bedrock with IAM. This pattern is useful for teams that want to share Bedrock access without distributing AWS credentials.

## What You Get

- **Codex CLI** - terminal coding agent, same UX as the OpenAI-hosted version
- **Codex desktop app** - GUI version of the agent
- **VS Code extension** - inline Codex in the editor
- **Managed Agents** - OpenAI-powered agents fully hosted by Bedrock, callable from your AWS workloads

All of them benefit from Codex's core capabilities: code generation, refactoring, test generation, codebase explanation, and legacy modernization.

## Why Use Codex via Bedrock

- **One cloud relationship** - existing AWS commitment covers Codex usage; no separate OpenAI contract
- **Enterprise controls** - IAM, PrivateLink, CloudTrail, KMS, Bedrock Guardrails apply automatically
- **Data boundary** - inference stays inside the AWS account's Bedrock environment
- **Procurement** - bills through AWS Marketplace / EDP rather than a new vendor
- **Compliance** - inherits AWS's compliance posture (SOC, HIPAA, FedRAMP where applicable)

## Pros

- No OpenAI API key required - AWS auth only
- Spend counts toward existing AWS commitments
- Full Bedrock guardrails, logging, and network controls
- Same Codex agent experience developers already know
- Open-weights `gpt-oss` models give predictable cost and behavior
- Works with the Bedrock Access Gateway pattern for shared team access

## Cons

- Limited preview - availability, regions, and pricing still in flux
- Requires Codex CLI v0.124.0+ - older clients cannot target Bedrock
- Model availability and Responses-API parity vary by Bedrock region during the preview
- Not every Bedrock model works through Codex's tool-calling loop - the model must support tool calls
- Bedrock Responses API is AWS-specific - configurations do not port back to `api.openai.com` cleanly
- Latency and quota are bound by your Bedrock region, not OpenAI's global footprint
- Tool-use parity between Bedrock Responses API and the upstream OpenAI API can lag during preview

Sources:
- [OpenAI models, Codex, and Managed Agents come to AWS - OpenAI](https://openai.com/index/openai-on-aws/)
- [Amazon Bedrock now offers OpenAI models, Codex, and Managed Agents (Limited Preview) - AWS](https://aws.amazon.com/about-aws/whats-new/2026/04/bedrock-openai-models-codex-managed-agents/)
- [OpenAI frontier models on Amazon Bedrock - AWS](https://aws.amazon.com/bedrock/openai/)
- [OpenAI Models on AWS Bedrock: GPT-5.5, Codex & Agents Guide - Lushbinary](https://lushbinary.com/blog/openai-models-aws-bedrock-gpt-5-codex-agents-guide/)
- [OpenAI brings GPT-5.5, Codex, and managed agents to AWS - EdTech Innovation Hub](https://www.edtechinnovationhub.com/news/openai-brings-gpt-55-codex-and-managed-agents-to-aws-as-expanded-amazon-partnership-goes-live)
- [OpenAI on Amazon Bedrock: Codex, GPT-5.5, Managed Agents - Elevata](https://elevata.io/en/codex-openai-agents-on-amazon-bedrock-aws-setup-guide)
- [I tried Amazon Bedrock support for Codex CLI v0.124.0 - DevelopersIO](https://dev.classmethod.jp/en/articles/codex-cli-amazon-bedrock-mantle-responses-api/)
- [Use OpenAI Codex CLI with Amazon Bedrock Models - DEV Community](https://dev.to/aws-builders/use-openai-codex-cli-with-amazon-bedrock-models-pay-as-you-go-48eb)
- [AWS and OpenAI announce expanded partnership - About Amazon](https://www.aboutamazon.com/news/aws/bedrock-openai-models)
