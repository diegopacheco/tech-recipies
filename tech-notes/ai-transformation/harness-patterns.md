# Agent Harness Patterns

A catalog of recurring patterns observed across modern agent harnesses (Claude Code, Codex, Cursor, Gemini CLI, Augment, Aider, OpenCode, BMAD, SuperClaude, Claude Flow, etc.). These are the building blocks that make a coding agent useful, controllable, and extensible.

## Catalog

### 1. Progressive Disclosure
Reveal capabilities, instructions, and context incrementally rather than dumping everything up front. The harness exposes a small surface by default; deeper knowledge (skills, sub-agents, tool schemas, plugin docs) is loaded only when the model signals intent.
- **Examples**: Claude Code Skills (loaded on `/skill-name`), deferred tool schemas (`ToolSearch`), lazy MCP server attachment, on-demand `CLAUDE.md` reads.
- **Why it matters**: Keeps the context window cheap; avoids polluting reasoning with irrelevant noise.

### 2. Advisor Pattern
A sub-agent or role gives recommendations without holding the keys to mutate state. The main agent decides whether to act on the advice.
- **Examples**: `Plan` agent in Claude Code, `code-reviewer-agent`, `security-reviewer-agent`, BMAD analyst/architect roles, Aider's `--ask` mode.
- **Why it matters**: Separates judgment from execution; lets you parallelize "second opinions" without risking writes.

### 3. Escape Hatch
A deliberate way for the user to break out of a constrained mode, override safety, or hand control back to a human.
- **Examples**: `ExitPlanMode`, `dangerouslyDisableSandbox`, `--no-verify` (with explicit user consent), `Other` option in `AskUserQuestion`, manual `! <command>` prefix.
- **Why it matters**: Constraints are useful only if they are not prisons; users need a clear way out without fighting the harness.

### 4. Include / Local Config Files
Hierarchical config picked up automatically from the filesystem — global → user → project → directory. Allows policy and context to travel with the codebase.
- **Examples**: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.aider.conf.yml`, `GEMINI.md`, `.augmentignore`, `settings.json` / `settings.local.json` layering.
- **Why it matters**: Lets teams encode conventions once and have every agent invocation respect them automatically.

### 5. Generic Execution Engine (Harness Core)
The harness itself is a thin, language-agnostic loop: read prompt → call model → execute tools → feed results back. All domain knowledge lives outside the engine.
- **Examples**: Claude Code's tool-loop, Codex CLI core, Aider's edit loop, OpenCode runtime, the Anthropic Agent SDK.
- **Why it matters**: A small, stable core is easier to harden, audit, and port across models; specialization is pushed to data (skills, configs, prompts).

### 6. Specialized Rules (Per-Task / Per-Language Files)
Reusable instruction packs scoped to a task type, language, or framework, selected at invocation time.
- **Examples**: Claude Code Skills (`java-backend-developer-agent`, `react-developer-agent`, `k6-stress-test-agent`), Cursor rule files, BMAD method packs, SuperClaude personas.
- **Why it matters**: Avoids re-explaining the same conventions every session; lets domain experts ship "best-practice bundles" as artifacts.

### 7. Hooks (PreTool / PostTool / Stop / SubmitPrompt)
Shell commands that run on lifecycle events, letting users inject linting, telemetry, redaction, or routing without modifying the agent.
- **Examples**: Claude Code `PreToolUse`/`PostToolUse`/`UserPromptSubmit` hooks, `cc-hook-tool-time-tracker`, context-mode auto-routing hook.
- **Why it matters**: Deterministic, user-owned guardrails outside the model's control plane.

### 8. Tool Allowlist / Permission Mode
Coarse and fine-grained gating of which tools the agent can call without confirmation. Modes include `plan`, `acceptEdits`, `bypassPermissions`, `default`.
- **Examples**: Claude Code permission modes, Cursor "auto-accept", Aider `--yes`, Codex `--dangerously-bypass`.
- **Why it matters**: Lets the same agent run interactively, semi-autonomously, or in CI without code changes.

### 9. Plan Mode / Dry-Run Separation
A read-only thinking phase that produces a plan; execution is a distinct, approval-gated phase.
- **Examples**: Claude Code Plan mode + `ExitPlanMode`, Aider `/architect`, BMAD's plan→build split, SDD flows.
- **Why it matters**: Cheap to iterate on intent before paying the cost of edits and side effects.

### 10. Sub-Agents / Delegation
Spawn isolated agent instances for sub-tasks; each has its own context window and tool set.
- **Examples**: Claude Code `Agent` tool, BMAD sub-roles, CrewAI crews, Strands multi-agents, Conductor.
- **Why it matters**: Protects the main context from large research outputs; enables parallel work.

### 11. Memory / Persistence Layer
Durable, file-based notes that survive across sessions — user profile, feedback, project state, references.
- **Examples**: Claude Code's `auto memory` (`MEMORY.md` + per-fact files), Aider chat history, Open Memory, Strands memory, beads.
- **Why it matters**: The agent stops re-asking the same questions and accumulates a working model of the user and project.

### 12. Slash Commands / Skills
User-invocable, named workflows that bundle a prompt template, allowed tools, and sometimes scripts.
- **Examples**: Claude Code slash commands, Cursor commands, BMAD "agents", custom skills like `/ultrareview`, `/security-review`, `/autobench`.
- **Why it matters**: Turns repeatable workflows into first-class, shareable artifacts.

### 13. MCP (Model Context Protocol) / External Tool Integration
A standardized protocol for plugging external tool servers (browsers, databases, repos, drives) into any harness.
- **Examples**: `mcp__playwright__*`, `mcp__repo-mcp__*`, Google Drive MCP, context-mode plugin.
- **Why it matters**: Decouples tool authors from harness authors; one MCP server works across Claude, Cursor, Codex, etc.

### 14. Context Compaction / Summarization
Automatically compress older conversation turns when the context window fills, keeping the recent tail verbatim.
- **Examples**: Claude Code auto-compaction, Aider `--map-tokens`, Cursor's rolling summary.
- **Why it matters**: Enables long sessions without losing the thread; trades fidelity for continuity.

### 15. Worktree / Sandbox Isolation
Run risky operations in an isolated git worktree, container, or sandbox so the main checkout is untouched until merge.
- **Examples**: Claude Code `isolation: "worktree"`, Codex sandbox, Cursor background agents, Anthropic Managed Agents.
- **Why it matters**: Lets the agent move fast without endangering uncommitted work.

### 16. Background / Async Tasks
Long-running tool calls or agents that don't block the main loop; the harness notifies the model when they finish.
- **Examples**: `run_in_background` on `Bash` and `Agent`, `Monitor` for streaming output, Continuous Claude, Cook (Race/Review/Orchestrate loops).
- **Why it matters**: Frees the agent to keep working while CI, deploys, or peer reviews run.

### 17. Scheduling / Cron / Loops
Run a prompt or skill on a schedule or until a condition is met.
- **Examples**: `/loop`, `/schedule`, `CronCreate`, `ScheduleWakeup`, Continuous Claude.
- **Why it matters**: Turns the agent into a stand-alone operator for monitoring, polling, and recurring chores.

### 18. Task / TODO Tracking
A structured to-do list the agent maintains as it works; visible to the user and survives context compaction.
- **Examples**: `TaskCreate`/`TaskUpdate`, `TodoWrite`, beads, SuperClaude task tracker.
- **Why it matters**: Externalizes planning state so neither agent nor user loses track of multi-step work.

### 19. Just-in-Time Tool Loading
The full tool catalog is referenced by name only; schemas are fetched on demand via a search tool.
- **Examples**: `ToolSearch` with `select:` queries, MCP lazy mounting, Skill-gated tool unlocks.
- **Why it matters**: Hundreds of tools become viable without burning tokens on schemas the agent never calls.

### 20. Confirmation Gates / Risk-Aware Prompts
The harness asks the user before destructive, irreversible, or shared-state actions (force-push, `rm -rf`, sending messages, dropping tables).
- **Examples**: Claude Code's "executing actions with care" policy, Cursor's destructive-command modal, Aider's git-commit prompts.
- **Why it matters**: Blast-radius awareness baked into the loop, not left to the model's discretion alone.

### 21. Multi-Agent Orchestration
Multiple specialized agents coordinated by a router, judge, or orchestrator — sometimes adversarial.
- **Examples**: Multi-Agent Verse, Auction House, Werewolf, Debate Club, PR Agent, Pixel Office, BMAD method, CrewAI, Strands.
- **Why it matters**: Different roles, models, or temperatures excel at different sub-problems; orchestration composes them.

### 22. Read-Before-Write Contract
The harness enforces that the model has read a file (or holds a fresh snapshot) before editing it.
- **Examples**: Claude Code's `Edit` requires prior `Read`, Aider's edit-block format, Cursor's apply-after-show.
- **Why it matters**: Prevents stale-overwrite bugs and forces the agent to ground its edits in current state.

### 23. Status Line / Observability
A persistent, model-visible (or user-visible) status surface — current branch, model, token usage, costs, queue.
- **Examples**: Claude Code status line skill, OpenTelemetry agent traces, Agent Observability stack, prompt-score, semantic drift detector.
- **Why it matters**: Makes the agent's resource usage and decisions inspectable instead of opaque.

### 24. Self-Correction / Retry Loops
When a tool call fails (tests red, lint error, hook block), the agent is expected to diagnose and fix rather than escalate.
- **Examples**: Aider's auto-lint/auto-test loop, Claude Code's "fix the underlying issue" guidance, Ralph reflection loops, Lisa Loop (agent-learner-prompt).
- **Why it matters**: Turns brittle one-shot generation into a robust converging process.

### 25. Spec-Driven / Test-First Flows
Force the agent to write a spec, design doc, or test before code; subsequent edits are gated by the spec.
- **Examples**: Verified SDD (VSDD), SDD-research, BMAD's PRD-first flow, autobench skill.
- **Why it matters**: Reduces hallucinated requirements; gives a checkable artifact to review against. (Caveat: oversized specs degrade — see `SDD-research.md`.)

### 26. Prompt / Skill Composition
Skills, personas, and prompts can be layered, included, or chained — like CSS cascades for instructions.
- **Examples**: SuperClaude personas, Skill stacking in Claude Code, BMAD method packs, Cursor rule includes.
- **Why it matters**: DRY for prompts; teams build a library instead of copy-pasting mega-prompts.

### 27. Snapshot / Checkpoint / Undo
Persist agent-induced changes as discrete checkpoints (commits, snapshots) so any step can be rolled back.
- **Examples**: Aider's auto-commit per edit, Cursor checkpoints, Codex shadow git, Claude Code's "new commit, never amend" guidance.
- **Why it matters**: Recovery without manual `git reflog` archaeology; encourages bolder experimentation.

### 28. User-in-the-Loop Questions
Structured asks back to the user mid-task, with constrained choices to keep responses parseable.
- **Examples**: `AskUserQuestion`, BMAD elicitation prompts, Cursor's clarification modals, java-spring-ai-ask-user-tool.
- **Why it matters**: Bridges ambiguity without dumping a wall of text on the user.

### 29. Output Routing / Context-Saving Sandboxes
Heavy tool output is processed in a side channel; only the agent's summary enters the main context.
- **Examples**: `context-mode` execute/execute_file, `Explore` sub-agent reading excerpts, MCP servers that paginate.
- **Why it matters**: Keeps the main loop fast and cheap even when tools produce megabytes.

### 30. Permission / Policy Cascade
Settings flow from system → org → user → project → run, with explicit precedence rules.
- **Examples**: Claude Code `settings.json` layering, Cursor team policies, Aider config files, Codex profiles.
- **Why it matters**: Centralized governance without blocking individual flexibility.

### 31. Telemetry / Evaluation Harness
A built-in or adjacent system to score agent runs — correctness, cost, latency, drift.
- **Examples**: autobench, prompt-score, agent-intent-eval, agent-semantic-similarity-eval, agent-memory-bench, local-agent-orama.
- **Why it matters**: You cannot improve a harness you cannot measure; eval loops drive iteration.

### 32. Identity / Role Personas
Named personas with embedded expertise, voice, and toolset that the user can summon.
- **Examples**: SuperClaude personas, BMAD roles (PM/Architect/Dev/QA), `*-developer-agent` skills, Claude Code sub-agent definitions.
- **Why it matters**: Mental shorthand for the user; consistent behavior across sessions.

### 33. Planner / Coder / Critic Triad
A specialized three-agent shape: one plans, one executes, one evaluates. Distinct from generic orchestrator-worker — the roles are fixed and the critic is mandatory.
- **Examples**: Anthropic's three-agent harness (April 2026) for full-stack long-running work, BMAD's PM/Dev/QA split, Claude Code Plan→Build→Review cycle, Chachamaru's claude-code-harness.
- **Why it matters**: Verification is forced into the loop, not optional; mistakes are caught before they accumulate across long sessions.

### 34. Context Reset (vs. Compaction)
Throw away the conversation and start fresh with a curated handoff brief, instead of summarizing in place. Compaction preserves continuity but causes "context anxiety" (the model gets cautious near the limit); a reset gives a clean slate.
- **Examples**: Anthropic's Sonnet 4.5 harness needed resets explicitly; Opus 4.5 reduced the need. Cook/Ralph reflection loops, BMAD per-story reset.
- **Why it matters**: Compaction and reset solve different problems — one for continuity, the other for behavior degradation near the context limit.

### 35. Filesystem-as-Context
Instead of pre-building dozens of bespoke tools, expose everything (code, runbooks, schemas, past notes) as files and give the agent `read_file`, `grep`, `find`, `shell`. Relevance emerges as the agent reads, not via upfront RAG querying.
- **Examples**: Microsoft Azure SRE agent (45% → 75% "Intent Met" after switching from 100+ tools to a filesystem), Claude Code's file-first stance, Aider repo maps.
- **Why it matters**: Avoids RAG's "you need the right query before you know what you need" trap; the filesystem is also a durable collaboration surface between agent and human.

### 36. LLM-as-Judge / Evaluator Sub-Agent
A separate model call (or sub-agent) scores, ranks, or vetoes another agent's output. Variants: single judge, panel/voter ensemble, adversarial critic, multi-round debate.
- **Examples**: ChatEval, DEBATE, CourtEval, MAJ-EVAL, agent-debate-club, prompt-score, agent-intent-eval, PR Agent reviewers.
- **Why it matters**: Cancels individual-model idiosyncrasies; cheaper than humans and faster than full eval suites for online filtering.

### 37. Parallel Sampling / Best-of-N
Spawn N independent attempts at the same task; pick the best by score, vote, or judge. Workers are interchangeable, not specialized.
- **Examples**: Local Agent Orama (adversarial parallel benchmark), Cook's Race loop, Codex parallel attempts, Connect-4 agent vs agent.
- **Why it matters**: Trades cost for reliability; variance among samples is often more informative than any single attempt.

### 38. Task DAG / Goal Decomposition
The harness decomposes a goal into a dependency graph, parallelizes independent nodes, then synthesizes. Different from a flat TODO list — edges encode ordering constraints.
- **Examples**: open-multi-agent (TypeScript DAG orchestration), DeepAgents, Strands multi-agents, BMAD epic→story breakdown.
- **Why it matters**: Unlocks parallelism on truly independent work; makes critical paths visible.

### 39. Middleware Layer
A pluggable band between model and tools handling cross-cutting concerns: redaction, rate limiting, retry, telemetry, cost capping, prompt-injection scrubbing.
- **Examples**: LangChain Deep Agents middleware, Portkey, LiteLLM gateways, AIDefence in Claude Flow, context-mode auto-routing.
- **Why it matters**: Centralizes guardrails so individual tools and agents don't each reinvent them.

### 40. Meta-Harness / Self-Improving Harness
The harness observes its own traces (failures, retries, token waste) and rewrites its own prompts, tool choices, or sub-agent configuration.
- **Examples**: Meta-Harness paper (arXiv 2603.28052), Azure SRE self-improvement loop, agent-learner-prompt (Lisa Loop), prompt-score, agent-semantic-drift-detector.
- **Why it matters**: The harness itself becomes a training target — you stop hand-tuning and start optimizing.

### 41. Entropy Management / Drift Repair
Scheduled agents that fix the natural decay of a working tree: stale docs, dead links, broken examples, outdated comments, divergent `CLAUDE.md` vs reality.
- **Examples**: design-doc-syncer-agent, fix-agents-md, agent-semantic-drift-detector, feature-documenter-agent, scheduled "groom" runs.
- **Why it matters**: Agents are great at producing artifacts and terrible at maintaining them — you need a counter-force or rot wins.

### 42. Deterministic Guardrails (Non-AI Constraints)
Linters, type checks, schema validators, structural tests, and pre-commit hooks enforce shape without involving the model. The model proposes; deterministic code decides.
- **Examples**: Pre-commit hooks, `leak-detector` skill (deterministic regexes), lint/typecheck gates in PR Agent, security-reviewer-agent with rule-based pre-filters.
- **Why it matters**: Cheap, fast, immune to prompt injection; catches the boring 80% before the model wastes tokens.

### 43. Outcome-Driven Loop (Success-Criteria Mode)
The user declares "done" as a checkable predicate (tests pass, benchmark above X, file matches schema). The harness iterates autonomously until the predicate holds or budget is exhausted.
- **Examples**: Anthropic Managed Agents outcome-driven mode (research preview), Continuous Claude, autobench, agent-runbook, Cook's converge loop.
- **Why it matters**: Decouples *what* from *how*; the user stops reviewing every step and only checks the final criterion.

### 44. Stop Condition / Budget Heuristic
Explicit termination rules: max iterations, max cost, no-change-detected, plateau detection, human ack. Without these, outcome-driven loops spin forever.
- **Examples**: Continuous Claude's `--max-cost` and no-changes-detected exit, `/loop` with intervals, `ScheduleWakeup` clamps, Cook's iteration cap.
- **Why it matters**: Open-ended loops are how agents burn $100 producing nothing. Termination is a first-class design problem, not an afterthought.

### 45. Diff / Patch Edit Format
The agent emits edits as structured diffs (search-replace blocks, unified diffs, AST patches) instead of rewriting whole files. Edits are validated against the current file state before applying.
- **Examples**: Aider's SEARCH/REPLACE blocks, Claude Code `Edit` with read-before-write, Codex unified diffs, Cursor apply mode.
- **Why it matters**: Catches stale-context overwrites, keeps token cost proportional to the change, and makes review trivial.

### 46. Skill Auto-Invocation / Intent Detection
Skills (or sub-agents) trigger themselves based on detected intent — keywords, file types, command shapes — rather than waiting for the user to type a slash command.
- **Examples**: Claude Code Skills with `description:` matching, context-mode auto-routing on large outputs, claude-api skill triggering on `anthropic` imports, frontend-design on `*.tsx` edits.
- **Why it matters**: Removes friction; users don't need to remember which incantation maps to which workflow.

## Cross-Cutting Themes

- **Determinism at the edges, flexibility in the middle**: hooks, configs, guardrails, and permission gates are deterministic; model reasoning is not. Push policy outward.
- **Externalize state**: memory files, task lists, plan documents, commits, filesystems — anything the model needs across compactions, resets, or sessions.
- **Composability over monoliths**: skills, MCP servers, sub-agents, middleware, and hooks all plug into a small core.
- **Blast-radius awareness**: every pattern above either reduces, contains, or makes reversible the side effects of an autonomous loop.
- **Agent = Model + Harness**: anything that isn't the model is harness. As models commoditize, the harness becomes the competitive surface.
- **Three interlocking systems**: context engineering (what the agent knows), architectural constraints (deterministic checks), entropy management (drift repair). A production harness needs all three.

## See Also

- [agents-pocs.md](./agents-pocs.md) — full POC catalog backing these patterns
- [continuous-claude.md](./continuous-claude.md) — background/loop + stop-condition pitfalls in depth
- [claude-managed-agents.md](./claude-managed-agents.md) — sandbox/worktree, outcome-driven loops, sub-agents
- [SDD-research.md](./SDD-research.md) — spec-driven flows, over-prompting caveats
- [multi-agents/claude-flow-vs-bmad-method.md](./multi-agents/claude-flow-vs-bmad-method.md) — orchestration vs guided patterns
- [frontend-tools-models-coding-agents.md](./frontend-tools-models-coding-agents.md) — harness comparison

## External References

- [Anthropic — Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Anthropic — Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Anthropic — Scaling Managed Agents: decoupling the brain from the body](https://www.anthropic.com/engineering/managed-agents)
- [OpenAI — Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/)
- [Addy Osmani — Agent Harness Engineering](https://addyosmani.com/blog/agent-harness-engineering/)
- [Martin Fowler — Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html)
- [HumanLayer — Skill Issue: Harness Engineering for Coding Agents](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents)
- [Augment Code — Harness Engineering for AI Coding Agents](https://www.augmentcode.com/guides/harness-engineering-ai-coding-agents)
- [LangChain — The Anatomy of an Agent Harness](https://www.langchain.com/blog/the-anatomy-of-an-agent-harness)
- [Arize — Context management in agent harnesses: memory, files, and subagents](https://arize.com/blog/context-management-in-agent-harnesses/)
- [Microsoft — Harness Engineering for Azure SRE Agent](https://techcommunity.microsoft.com/blog/appsonazureblog/the-agent-that-investigates-itself/4500073)
- [Microsoft — Agent Harness in Agent Framework](https://devblogs.microsoft.com/agent-framework/agent-harness-in-agent-framework/)
- [InfoQ — Anthropic Designs Three-Agent Harness for Long-Running Full-Stack AI Development](https://www.infoq.com/news/2026/04/anthropic-three-agent-harness-ai/)
- [arXiv — Dive into Claude Code: The Design Space of Today's and Future AI Agent Systems](https://arxiv.org/html/2604.14228v1)
- [arXiv — Agentic Harness Engineering: Observability-Driven Automatic Evolution of Coding-Agent Harnesses](https://arxiv.org/html/2604.25850v3)
- [arXiv — Meta-Harness: End-to-End Optimization of Model Harnesses](https://arxiv.org/html/2603.28052v1)
- [arXiv — Building AI Coding Agents for the Terminal: Scaffolding, Harness, Context Engineering](https://arxiv.org/html/2603.05344v1)
- [arXiv — When AIs Judge AIs: The Rise of Agent-as-a-Judge Evaluation](https://arxiv.org/html/2508.02994v1)
- [awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering)
- [Dive-into-Claude-Code](https://github.com/VILA-Lab/Dive-into-Claude-Code)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
