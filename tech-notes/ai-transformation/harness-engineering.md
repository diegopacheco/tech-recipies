# Harness Engineering — Research Report (May 2026)

## What it is

**Harness engineering** is the discipline of designing the non-model runtime that wraps a Large Language Model so it behaves as a reliable production agent. The community formula is:

> **Agent = Model + Harness**

The "harness" is everything that is **not** the model: prompts, context management, tool registries, sandboxes, permission gates, memory, sub-agent orchestration, hooks, evals, and observability. The thesis is that as foundation models commoditize, the durable engineering value moves into the scaffolding around them. Martin Fowler frames it as *"feedforward guides and feedback sensors around coding agents"* — an emerging engineering discipline, not a one-time config.

The market headline driving the conversation: roughly **88% of AI-agent projects never reach production**, and surveys attribute about **65% of enterprise failures to context drift**, not model quality.

---

## How it works — the canonical loop

Every harness, regardless of vendor, implements some flavor of:

```
gather context  →  decide / call tool  →  act in sandbox  →  observe  →  verify  →  repeat
```

Analysis of ~70 open-source agent projects shows ~60% use a literal Agent Loop; the rest layer on event-driven, state-machine, or graph/flow schedulers (LangGraph, Pulumi-style DAGs). Underneath, the same six concerns recur:

1. **State & persistence** — checkpoints, worktrees, session resume after disconnect.
2. **Security & governance** — permission gates, scoped credentials, audit trails.
3. **Orchestration & tool dispatch** — when to plan, when to act, which tool.
4. **Memory** — short-term scratchpad, long-term store, retrieval policies.
5. **Observability** — traces, tool-call timing, decision logs, evals.
6. **Context management** — what enters the window, what gets evicted, what gets summarized.

Claude Code's leaked architecture popularized a specific six-layer breakdown: **context injection · loop state in memory + worktree isolator · destructive-action hooks behind a permission gate · subagent context firewalls · MCP/bash tool dispatch · verification phase**.

---

## Patterns (what works)

| Pattern | What it does |
|---|---|
| **Agent Loop** | The default call-observe-decide cycle; ~60% of OSS agents use it directly. |
| **Supervisor / Subagent** | One coordinator decomposes work; isolated sub-agents run focused tasks. LangGraph 2.0 codified this as a primitive. |
| **Context Firewall** | Sub-agents get their own context window so the parent stays small. Used heavily by Claude Code. |
| **Worktree Isolation** | Each agent works on a git worktree so destructive edits are reversible. |
| **Permission Gate / Rule Pipeline** | Hooks check every tool call against a rule pipeline before it touches the host. |
| **Three Autonomy Tiers** | Approval-First → Curated Allow-list → Sandboxed Full-Auto. Trade per-action approval for safety-by-construction. |
| **Constraint Harness** | Rules files, lint configs, type systems, schemas shrink the agent's solution space *before* generation. |
| **Feedback Loops** | Give the model a way to *verify* its work (run tests, type-check, re-read). Reported 2–3x quality lift. |
| **Schema Validation** | Catches ~60–70% of tool-call errors before app code sees them. |
| **Prompt Cache Hygiene** | Strip dynamic elements (e.g. timestamps) from the top of the prompt so the cache stays warm — the difference between "prohibitive" and "high-margin." |
| **Bounded Deterministic Workflows** | Replace open-ended swarms with phase-gated pipelines and human-on-the-loop circuit breakers. |
| **Hooks** | User-defined scripts that fire on tool events to enforce policy, log, or auto-correct. |

---

## Anti-patterns (what doesn't)

1. **Tool Bloat.** 30–50 tools when <10 are relevant. Measurable degradation kicks in around **20 tools** — selection accuracy collapses.
2. **Over-constraining.** Rules so strict they reject valid refactors. Slows the agent without improving output.
3. **Unconstrained multi-agent meshes.** Open-ended swarms look impressive in demos and fail in prod. Enterprises are explicitly moving away from them toward Supervisor + Phase Gating.
4. **Context drift.** Not pruning, summarizing, or firewalling sub-tasks. The dominant failure mode (~65% of enterprise failures).
5. **Spec-bloat / SDD-by-default.** Treating "more markdown" as a harness improvement — degrades attention, ages faster than code (see `SDD-research.md` in this repo; the harness community is converging on the same conclusion).
6. **Skipping evals.** Treating harness changes as untestable — they're not; every harness change is a regression risk.
7. **Mixing inferential and computational controls without distinction.** Using the LLM where a linter would do (Fowler's specific critique).
8. **No verification phase.** Generate-and-pray. Agents that can't observe their own output don't converge.

---

## Pros

- Decouples reliability from raw model capability — a **decent model + great harness beats a great model + bad harness**.
- Models can be swapped (Opus → Sonnet → next-gen) without re-architecting the system.
- Centralizes safety, audit, and governance — single place to enforce compliance.
- Sandboxing and permission gates make destructive actions reversible.
- Long-running sessions and sub-agent spawning become first-class instead of bolt-on.

## Cons

- New, fast-moving discipline — patterns are still being named in real time, churn is high.
- Vendor lock-in risk when adopting hosted harnesses (Anthropic Managed Agents, OpenAI AgentKit).
- Token + per-session-hour billing creates a second cost axis to reason about.
- Easy to over-engineer: a 12-tool harness with 4 sub-agents, hooks, and a graph scheduler for what could've been a single prompt.
- Observability and evals are still immature; debugging non-deterministic loops remains painful.
- Harness changes can silently regress behavior — without evals you won't notice.

---

## What companies are doing / building

**Hosted / managed harnesses**
- **Anthropic — Managed Agents** (public beta, Apr 2026): sandboxed runtime, sub-agent spawning, outcome-driven loops, $0.08/session-hour on top of tokens. Pitched as "stop rebuilding the harness on every project."
- **OpenAI — AgentKit + Agents SDK**: visual builder + SDK, guardrails, MCP, state. More drag-and-drop oriented.
- **LangChain — LangGraph 2.0**: codifies Router / Supervisor / Subagent as primitives, type-safe streaming, managed hosting.
- **Pulumi**: positioning IaC patterns for agent infrastructure.

**Coding-agent harnesses (consumer + dev tools)**
- **Cursor** ($2.3B round) — IDE-native harness.
- **Cognition / Devin 2.0** ($400M round) — autonomous coder harness.
- **Anthropic Claude Code** — reference harness many others now imitate; "the Claude Code leak" became a teaching artifact.
- **OpenAI Codex (CLI + cloud)** — sibling harness to Claude Code, different choices on permissions and isolation.
- **Amazon Q Developer, Replit Agent, Bolt.new, Lovable, Windsurf** — Google acqui-hired Windsurf's founders for $2.4B; Cognition bought the remainder for $250M.
- **Augment Code** — explicitly positioning as "constraint harness for coding agents."
- **HumanLayer** — human-in-the-loop primitives for agent harnesses.

**Adopters in production**
- **Notion** (Custom Agents alpha), **Asana** (AI Teammates), **Atlassian** (Jira-embedded dev agents), **Rakuten** (per-function specialist agents into Slack/Teams), **Vibecode** (prompt-to-deployed app default) — all running on Anthropic's Managed Agents.

**Market shape**
- Agentic engineering is the **single most-funded AI subcategory in 2026**.
- The market has split into three lanes: **no-code platforms · developer frameworks · autonomous coders**.
- Industry shorthand: *"2026 is the year of harnesses, not just agents."*

---

## TL;DR

Harness engineering treats the LLM as a frozen reasoning core and moves all the interesting engineering — orchestration, safety, memory, tools, verification — into the runtime surrounding it. The patterns that survived contact with production are boring on purpose: tight tool sets, sub-agent context firewalls, sandboxed worktrees, permission gates, verification loops, and prompt-cache discipline. The anti-patterns that keep killing projects are tool bloat, context drift, and unconstrained multi-agent swarms. The companies winning right now are the ones treating the harness as their product, not their plumbing.

---

## Sources

- [Effective Harnesses for Long-Running Agents — Anthropic Engineering](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness Engineering for Coding Agent Users — Martin Fowler](https://martinfowler.com/articles/harness-engineering.html)
- [Agent Harness Engineering — O'Reilly Radar](https://www.oreilly.com/radar/agent-harness-engineering/)
- [Agent Harness Engineering — Addy Osmani](https://addyosmani.com/blog/agent-harness-engineering/)
- [The Agent Harness: Why the LLM Is the Smallest Part of Your Agent System — MongoDB](https://www.mongodb.com/company/blog/technical/agent-harness-why-llm-is-smallest-part-of-your-agent-system)
- [What Is an Agent Harness? — Arize AI](https://arize.com/blog/what-is-an-agent-harness/)
- [Harness Engineering for AI Coding Agents — Augment Code](https://www.augmentcode.com/guides/harness-engineering-ai-coding-agents)
- [Skill Issue: Harness Engineering for Coding Agents — HumanLayer](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
- [AI Agent Harness Failures: 13 Anti-Patterns and Root Causes — Atlan](https://atlan.com/know/agent-harness-failures-anti-patterns/)
- [What Is Harness Engineering AI? The Definitive 2026 Guide — Atlan](https://atlan.com/know/what-is-harness-engineering/)
- [Agent Harness Engineering — The Rise of the AI Control Plane — Adnan Masood](https://medium.com/@adnanmasood/agent-harness-engineering-the-rise-of-the-ai-control-plane-938ead884b1d)
- [Inside the Agent Harness: How Codex and Claude Code Actually Work — Jonathan Fulton](https://medium.com/jonathans-musings/inside-the-agent-harness-how-codex-and-claude-code-actually-work-63593e26c176)
- [The Claude Code Leak: 10 Agentic AI Harness Patterns — Ken Huang](https://kenhuangus.substack.com/p/the-claude-code-leak-10-agentic-ai)
- [Claude Code Agent Harness: Architecture Breakdown — WaveSpeed](https://wavespeed.ai/blog/posts/claude-code-agent-harness-architecture/)
- [Claude Code Architecture Explained: Six Harness Layers Beyond the LLM — Mervin Praison](https://mer.vin/2026/05/claude-code-architecture-explained-six-harness-layers-beyond-the-llm/)
- [What Is an Agent Harness? — MindStudio](https://www.mindstudio.ai/blog/what-is-agent-harness-architecture-explained)
- [Harness capabilities — LangChain DeepAgents docs](https://docs.langchain.com/oss/python/deepagents/harness)
- [All Agent Harnesses: The Live Comparison — htek.dev](https://htek.dev/articles/all-agent-harnesses-live-comparison)
- [Agentic Harness Engineering: LLMs as the New OS — Decoding AI](https://www.decodingai.com/p/agentic-harness-engineering)
- [The Rise of AI Harness Engineering — Cobus Greyling](https://cobusgreyling.substack.com/p/the-rise-of-ai-harness-engineering)
- [Building Your Own Agent Harness — Martin C. Richards](https://www.martinrichards.me/post/building_your_own_agent_harness/)
- [Awesome Harness Engineering (curated list) — GitHub](https://github.com/ai-boost/awesome-harness-engineering)
- [How Building AI Agents Has Changed in 2026 — Pulumi](https://www.pulumi.com/blog/how-building-ai-agents-has-changed/)
- [12 Best Agentic Engineering Platforms and AI Tools (2026) — Taskade](https://www.taskade.com/blog/agentic-engineering-platforms)
