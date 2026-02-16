# GasTown

## 1. What is it?

GasTown is a multi-agent orchestration framework created by Steve Yegge, released on January 1, 2026. It is written in Go (~189k LOC) and built on top of a git-backed issue tracking system called "Beads." GasTown presents itself as a Claude Code-like single-agent interface, but behind the scenes it spawns and manages 20-30+ specialized AI coding agents working in parallel. You interact with a coordinator agent called the "Mayor," which distributes work across ephemeral worker agents called "Polecats." It treats the development process like a factory: you talk to the foreman (Mayor), and it coordinates as many workers as needed.

- GitHub: github.com/steveyegge/gastown
- Docs: docs.gastownhall.ai
- License: MIT

## 2. Main Features

- Mayor-based orchestration: a coordinator agent (the Mayor, running on Opus) distributes tasks to worker agents (Polecats, running on Sonnet)
- Beads issue tracking: a git-backed structured data system that acts as external memory for agents, each bead has a prefix + 5-char alphanumeric ID (e.g., gt-abc12)
- Convoys: work tracking units that bundle multiple beads and get assigned to agents
- Git worktree isolation: each agent works in its own git worktree, preventing crashes from corrupting shared state
- Persistent hooks: work state survives agent crashes and session restarts via git-backed hooks
- GUPP principle (Gas Town Universal Propulsion Principle): when an agent finds work on its hook, it executes immediately -- no confirmation, no questions, no waiting
- Multi-agent runtime support: treats Claude Code, Goose, Codex, Gemini CLI, Cursor Agent, Amp, and Auggie as interchangeable runtimes
- Refinery: automated merge queue processing and conflict resolution
- Witness and Deacon: monitoring agents for system health and worker supervision
- CLI tools: gt (orchestration) and bd (bead management) command-line interfaces
- Lifecycle hooks: injects context at session start, context compaction, before tool use, every prompt, and session stop

## 3. Pros

- Massive parallelism: can run 20-30 agents simultaneously, compressing weeks of work into hours
- Git-native persistence and isolation via worktrees -- crashes do not corrupt shared state
- Durable workflows with auditable history; work survives agent restarts
- Agent-runtime agnostic: supports Claude Code, Goose, Codex, Gemini CLI, Cursor, Amp, and Auggie
- No SDLC phase-gating: enables true parallel execution without sequential handoff bottlenecks
- External memory via Beads prevents context loss across agent sessions
- Strong community attention and adoption, including by some Fortune 100 companies
- MIT licensed and installable via Homebrew, npm, or Go install

## 4. Cons

- Very high cost: approximately $100/hour burn rate in API costs
- Requires constant human steering and oversight -- not a hands-off system
- Still early-stage and not production-ready for most teams
- Practical parallelization caps around 5-7 agents for many users, despite theoretical 20-30
- Entirely "vibecoded" -- Yegge has publicly stated he has never looked at the generated code
- Aggressive YOLO behavior: auto-pushes branches, creates PRs, and has been observed merging PRs with failing tests
- Merge conflict volume scales with agent count; later-finishing agents face worse conflicts
- Steep learning curve: designed for developers at Stage 6-8 of Yegge's "Developer Evolution" model
- The "murderous rampaging Deacon" problem -- monitoring agents can behave unpredictably

## 5. Comparison

| Tool | Key Difference vs GasTown |
|------|---------------------------|
| claude-flow | Both do multi-agent orchestration. claude-flow uses SQLite + vector DB (heavier). GasTown uses git as its persistence layer (simpler). Some practitioners combine both. A bridge plugin exists. |
| BMAD | BMAD uses SDLC phase gates and role personas. GasTown explicitly avoids sequential phase-gating in favor of parallel operational roles. BMAD is more structured and predictable; GasTown prioritizes throughput. |
| Ralph | Ralph operates a single agent in a bash loop. GasTown operates dozens of parallel agents with a full orchestration layer. Ralph is simpler and cheaper; GasTown is for scale. |
| SuperClaude | SuperClaude enhances one agent's effectiveness through config injection. GasTown multiplies agents. SuperClaude is for making one agent excellent; GasTown is for managing a fleet. |
| ContinuousClaude | ContinuousClaude solves session persistence for one agent. GasTown solves persistence and coordination for many agents. ContinuousClaude is a building block; GasTown is a factory. |
| GetShitDone | GSD optimizes individual developer-agent interaction. GasTown replaces the single-agent model entirely with a swarm model. Different ambition levels entirely. |

## 6. Why is it unique?

GasTown treats AI-assisted coding as a factory operations problem rather than a single-assistant problem. Its core insight is that git is already a persistence and coordination layer -- so instead of inventing new infrastructure, it uses git worktrees for isolation, git-backed beads for external memory, and git history for auditability. The GUPP principle (agents execute immediately when they find work, no confirmation needed) combined with ephemeral Polecat workers that spawn, complete a task, create an MR, and disappear creates a model where agent identity persists but sessions are disposable. No other tool combines hierarchical agent roles, git-native persistence, multi-runtime support, and this level of parallelism into a single orchestration layer.

## 7. Simple Usage

```bash
brew install gastown

gt install ~/gt --git
cd ~/gt

gt rig add myproject https://github.com/you/repo.git

gt mayor attach
```

Inside the Mayor session:
```bash
gt convoy create "Build auth system" gt-x7k2m gt-p9n4q --notify
gt sling gt-x7k2m myproject
gt convoy list
gt agents
```

The `gt mayor attach` command opens a Claude Code session with the Mayor agent. You describe what you want built, and the Mayor breaks it into beads, creates convoys, and slings work to Polecat workers running in parallel terminal sessions.
