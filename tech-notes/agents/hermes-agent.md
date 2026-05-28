# Hermes Agent

## What is Hermes Agent?

Hermes Agent is an open-source, self-hosted AI agent from Nous Research, released on 25 February 2026 under the MIT license. Its tagline is "the agent that grows with you." Unlike a stateless coding assistant that forgets everything between sessions, Hermes is designed to live on your own machine or server, accumulate memory over time, write its own reusable skills from experience, and reach you across the messaging platforms you already use (Telegram, Discord, Slack, WhatsApp, Signal, Email, CLI).

It is model-agnostic. You point it at whatever LLM you want - Nous's own Hermes 4 405B, Anthropic, OpenAI, Google, OpenRouter, OpenAI-compatible endpoints, or a local Ollama model - and the agent loop, memory, skills, and gateway stay the same. The project is led by Nous co-founder Teknium (Ryan Teknium) and grew an unusually large ecosystem of community skills and integrations within weeks of launch.

The distinction worth holding onto: most agents are a [[harness]] wrapped around a model with no durable identity. Hermes treats persistence as the product - the harness is built so the agent gets more capable the longer it runs, not just within a single session.

## How it Works

At the center is a conversation loop (`AIAgent`) driven by tool calls. Each turn the model sees the system prompt, conversation history, retrieved memory, and skill metadata, then emits text and/or tool calls that the harness executes and feeds back. Around that loop sit the pieces that make Hermes distinctive:

| Component | Role |
|---|---|
| **Agent loop** | `AIAgent` core conversation/tool-calling loop; `HermesCLI` interactive terminal UI |
| **Memory** | Multi-level memory stored in SQLite with FTS5 full-text search; session history, facts, and skill metadata are all searchable |
| **Skills** | Auto-generated reusable Python/Markdown skills; managed via a `skill_manage` tool; ships with 40+ built-in tools |
| **Subagents** | `delegate_tool` spawns isolated subagents, each with its own conversation, terminal, and Python RPC scripts; parent waits for the child's summary |
| **Code execution** | Sandboxed Python via `execute_code`, collapsing multi-step pipelines into a single inference call |
| **Gateway** | Routes messages from Telegram/Discord/Slack/WhatsApp/etc. into the agent loop; multi-channel from one process |
| **Scheduling** | Natural-language cron for unattended reports, backups, and briefings |
| **Transports** | Pluggable layers: Anthropic, ChatCompletions, ResponsesAPI, Bedrock |

### The learning loop

This is the core idea. When Hermes solves a hard problem, it does three things: writes a reusable skill file describing the workflow, stores the outcome in persistent memory, and adjusts its approach for next time. On future tasks it searches its own past conversations and skill library before acting. The claim is that repeated task patterns get faster and more reliable over time because the agent is distilling its own successful trajectories into callable capabilities rather than re-deriving them every session.

### Deployment backends

Tools execute inside an abstracted terminal environment, and Hermes supports six backends: **local, Docker, SSH, Singularity, Daytona, and Modal**. Daytona and Modal offer serverless persistence - the environment hibernates when idle and costs near zero - while keeping a dedicated machine the agent can return to. Container hardening and namespace isolation are part of the design for the sandboxed backends.

## Memory Architecture

The memory system is the differentiator, so it is worth separating from the rest:

- **Session memory** - the live conversation, persisted so a session can resume.
- **Long-term / episodic memory** - outcomes of past tasks, searchable via FTS5.
- **Skills** - successful workflows distilled into reusable Markdown/Python files, discoverable at runtime.
- **User model** - a deepening profile of who you are and how you work, carried across sessions and platforms.

Everything is stored locally in SQLite. There is no cloud store, no telemetry, and no vendor account required for the memory itself.

## Tooling and the Nous Tool Gateway

Out of the box Hermes ships with 40+ tools (web search, web extract, vision/image analysis, code execution, delegation, skill management, and more). Nous Portal subscribers additionally get the **Nous Tool Gateway**, which adds hosted web search, image generation, text-to-speech, and browser automation - so the agent can "see, speak, and browse" without you wiring up those providers yourself. Tools are discovered at runtime and registered for the model to call.

## Pros

- Persistent, local-first memory that genuinely carries across sessions and platforms - the agent is not amnesiac.
- Self-improving via the learning loop: it writes and refines its own skills, so repeated workflows get faster.
- Fully open source (MIT), self-hosted, no telemetry, no cloud lock-in; all data stays on your machine.
- Model-agnostic - works with local Ollama, frontier APIs, or Nous's own Hermes 4 405B.
- Meets you where you are: Telegram, Discord, Slack, WhatsApp, Signal, Email, CLI through one gateway process.
- Subagents with isolated terminals and contexts enable parallel, zero-context-cost pipelines.
- Multiple deployment backends, including serverless (Modal, Daytona) that hibernate when idle.
- Natural-language cron makes unattended automation (reports, backups, briefings) straightforward.

## Cons

- CLI-first and self-hosted: a real learning curve and activation energy for non-technical users.
- Multi-agent configuration via raw YAML profiles gets messy past two or three agents.
- The learning loop needs volume to pay off - one-off, never-repeated tasks give episodic memory nothing useful to retrieve.
- Not yet a fit for regulated/enterprise backend workflows: signed provenance, approval gates, and audit trails are immature.
- Self-hosting shifts operational burden (memory store, sandbox backends, gateway) onto you.
- Quality and benefit depend heavily on the model you plug in; a weak local model undercuts the whole experience.

## Hermes Agent vs Other Agents

- **vs Claude Code / one-shot coding agents** - Claude Code has lower activation energy and is better for rapid prototypes and one-off tasks. Hermes is suited to long-horizon, repeated work where it accumulates research, preferences, and skills over weeks. They are often used together: Hermes as the memory/learning layer, a coding agent for the writing.
- **vs orchestration-first agents (e.g. "OpenClaw"-style)** - those emphasize plugin breadth and multi-channel team workflows; Hermes emphasizes the learning layer (persistent memory, auto-generated skills, long-horizon reasoning). Community framing treats them as complementary rather than competing.

## Who is Using It

- **Nous Research** built and maintains it; co-founder Teknium leads development by commit volume.
- A large open-source community formed quickly around it - the GitHub repo accrued tens of thousands of stars within weeks of launch and spawned 80+ ecosystem projects (curated skill lists, self-evolution add-ons using DSPy + GEPA, community docs, install tutorials). Coverage spread beyond English-language tech press into Chinese and Japanese developer communities.
- Typical adopters are technical users and tinkerers who want a private, always-on personal agent with memory rather than a hosted SaaS assistant. (Note: the specific star and adoption numbers reported across third-party sites vary widely and many of those pages appear to be AI-generated SEO content - treat exact figures with skepticism and confirm against the GitHub repo.)

## Why It Matters

The dominant pattern in 2025-2026 was the stateless agent: powerful within a session, blank the next. Hermes Agent is a bet that the next axis of improvement is not raw model capability but durable identity - memory, self-authored skills, and a model of the user that compounds. If the learning loop holds up in practice, it changes the economics: instead of re-explaining context every session, the agent's value grows with use. Combined with its local-first, no-telemetry stance, it is also a statement about who should own the agent and its data - you, not a cloud provider.

The open question is whether self-generated skills and episodic memory actually compound into reliability at scale, or whether they accumulate noise that needs curation. That is the thing to watch as the project matures past its early releases.

## Links

- https://hermes-agent.nousresearch.com/
- https://hermes-agent.nousresearch.com/docs/
- https://hermes-agent.nousresearch.com/docs/developer-guide/architecture
- https://github.com/NousResearch/hermes-agent
- https://github.com/NousResearch/hermes-agent-self-evolution
- https://github.com/0xNyk/awesome-hermes-agent
- https://nousresearch.com/hermes3
- https://huggingface.co/NousResearch/Hermes-4-405B
- https://arxiv.org/pdf/2508.18255
- https://www.marktechpost.com/2026/02/26/nous-research-releases-hermes-agent-to-fix-ai-forgetfulness-with-multi-level-memory-and-dedicated-remote-terminal-access-support/
- https://www.datacamp.com/tutorial/hermes-agent
