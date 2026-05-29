# LangChain Managed Deep Agents

## What is it?

Managed Deep Agents is an API-first **hosted runtime** for creating, running, and operating deep agents, announced by LangChain (Victor Moreira) on May 13, 2026 in private beta. It takes the open-source **Deep Agents** harness and gives it "a durable home in LangSmith": you keep the agent *definition* in your repo, and LangChain runs the *operational layer* - threads, checkpointing, streaming, context, sandboxes, and observability.

The thesis behind it: building a useful agent is getting easy, but *operating* one in production is still hard. A long-running agent needs more than a model call - durable execution, streaming, memory, files, tool access, human approval, sandboxes, tracing, and a way to improve over time. Teams can build all that themselves, but it's a lot to own before the agent has even reached users. Managed Deep Agents packages that infrastructure so developers focus on agent behavior instead of rebuilding the runtime around it.

## Background: open-source Deep Agents

Deep Agents (the open-source project, `langchain-ai/deepagents`, launched March 15, 2026) is a "batteries-included" agent [[harness]] - a structured runtime for planning, memory, tool use, and context isolation across multi-step tasks. It hit ~9.9k GitHub stars within hours of its March update. Its core building blocks:

- **Planning** - a `write_todos` tool the agent uses to lay out and track its plan.
- **Filesystem tools** - `read_file`, `write_file`, `edit_file`, `ls`, `glob`, `grep`.
- **Shell access** - `execute`, sandboxed, for running commands and code.
- **Subagents** - a `task` tool that spawns subagents for delegated work (context isolation).
- **Context management** - auto-summarization and saving large outputs to files to keep the main context lean.

Managed Deep Agents does not replace this - it hosts it. You build with the open-source harness, then hand the *running* of it to LangSmith.

## What the managed layer adds

The private beta ships a small set of managed primitives.

### Managed runtime

Create a managed Deep Agent without standing up your own agent server. The runtime gives you **durable threads, streaming runs, checkpointing, and human-in-the-loop** workflows. Through the API (surface under `/v1/deepagents`) you create agents, update their configuration, create threads, and stream runs from your own product or platform workflow.

### Tools and sandboxes

Tools are configured through `tools.json` - the same model as open-source Deep Agents - and you can enable **human-in-the-loop on any tool** defined there. The runtime also supports **sandbox-backed execution** for workflows that need code, shell, and file I/O (analyzing data, manipulating files, running scripts, creating artifacts). Instead of rebuilding tool/sandbox setup per agent, that configuration lives in the managed runtime.

### Agent context, files, and Context Hub

Managed Deep Agents keeps the familiar Deep Agents project shape - `AGENTS.md`, `skills/`, `subagents/`, and `tools.json` - and **stores and versions those files in LangSmith** so the agent definition can evolve over time.

The differentiated piece is **Context Hub**: a managed place for the agent to retain and update the context it needs *across runs* - user preferences, project details, research notes, operating procedures, working state. This is the part that lets an agent "improve from the work it actually does," not just from what was in the prompt at deploy time.

Optionally, **LangSmith Engine** reviews agent traces to find bugs and improvement areas across prompts and code. Between runs, the agent can review past conversations, learn from real usage, and update its Context Hub files. The example given: a support-triage agent notices users keep asking about the same internal process and updates its operating notes accordingly.

## How it works

The launch path is API-first:

1. Create or update an agent with the Managed Deep Agents API.
2. Upload or reference the files that define it - instructions, skills, subagents, tool config.
3. Create a thread and stream a run from your app, with **no custom agent server to deploy**.
4. Inspect traces and the agent's context live in LangSmith as it runs.

## Where it sits

| | Open-source Deep Agents | Managed Deep Agents |
|---|---|---|
| What it is | The agent harness (planning, tools, subagents, files) | A hosted runtime that operates that harness |
| You own | Everything - server, state, files, sandboxes, tracing | The agent definition (in your repo) |
| LangSmith owns | Nothing (you self-host) | Threads, checkpointing, streaming, sandboxes, Context Hub, observability |
| Best for | Full control, custom infra | Fastest path from harness to production |

## Why it matters

This is the "operate" half of the agent stack getting productized. Through 2025-2026 the industry got good at *defining* agents - planning loops, subagents, tool use - but every team then re-built the same operational scaffolding (durable threads, sandboxes, memory stores, tracing) before shipping. Managed Deep Agents is LangChain's bet that this scaffolding is undifferentiated heavy lifting that should be a managed service, the same shift that hosted databases made over self-managed ones.

Two design choices stand out:

1. **The agent definition stays in your repo.** You're not locked into a GUI builder - the harness is open source and the files (`AGENTS.md`, `skills/`, `subagents/`, `tools.json`) are yours. LangSmith manages the *runtime*, not the *agent*. This is a meaningfully different posture from closed agent platforms.
2. **Context Hub treats persistence as a first-class product.** Memory that updates from real usage is the same idea [[hermes-agent]] bets on (a learning loop over a persistent store) - here it's offered as managed infrastructure with LangSmith Engine doing the trace-driven self-improvement.

The honest caveats: it's **private beta, design-partners-first**, so no self-serve access or public pricing yet, and it's a deeper commitment to the LangSmith platform - the durable execution, Context Hub, and tracing all live there. The agent definition is portable (open-source harness), but the operational value you're paying for is not. As with all "agents that improve from usage," the open question is whether Context Hub + LangSmith Engine compounds into reliability or accumulates noise that needs curation.

## Availability

- **Stage:** private beta, opened to design partners first before broader self-serve access.
- **Access:** join the LangSmith Managed Deep Agents waitlist.
- **Built on:** open-source Deep Agents (`langchain-ai/deepagents`) + LangSmith.

## Links

* https://www.langchain.com/blog/introducing-managed-deep-agents
* https://docs.langchain.com/langsmith/deploy-managed-deep-agent
* https://docs.langchain.com/oss/python/deepagents/overview
* https://www.langchain.com/deep-agents
* https://github.com/langchain-ai/deepagents
* https://www.langchain.com/blog/introducing-langsmith-engine
* https://www.langchain.com/langsmith-managed-deep-agents-waitlist
* https://www.marktechpost.com/2026/03/15/langchain-releases-deep-agents-a-structured-runtime-for-planning-memory-and-context-isolation-in-multi-step-ai-agents/
