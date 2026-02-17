# oh-my-claudecode (OMC)

## 1. What is it?

oh-my-claudecode (OMC) is a teams-first multi-agent orchestration layer built on top of Claude Code CLI. Created by Yeachan Heo, it transforms a single Claude Code session into a coordinated swarm of specialized agents that plan, execute, verify, and fix code autonomously. It is open-source under the MIT License with over 1,000 commits, 160 releases, and 25 contributors on GitHub. The npm package is published as `oh-my-claude-sisyphus`.

- GitHub: github.com/Yeachan-Heo/oh-my-claudecode
- Website: yeachan-heo.github.io/oh-my-claudecode-website
- npm: oh-my-claude-sisyphus

OMC is not a standalone tool. It is a Claude Code plugin that injects a CLAUDE.md orchestration layer, 31 hooks, 37 skills, and 32 specialized agent definitions into the Claude Code runtime. Since v4.1.7 (current: v4.2.11), the canonical orchestration surface is Team -- a staged pipeline that coordinates multiple Claude Code sub-agents through plan, PRD, execution, verification, and fix phases.

## 2. Main Features

- Team-first staged pipeline: `team-plan -> team-prd -> team-exec -> team-verify -> team-fix (loop)` as the primary orchestration surface
- 32 specialized agents across three model tiers: Haiku (quick lookups), Sonnet (standard implementation), Opus (complex reasoning and architecture)
- 37 skills spanning execution (autopilot, ultrawork, ralph, pipeline, swarm), enhancement (deepsearch, analyze, tdd, code-review), and utilities (note, cancel, omc-doctor, hud)
- 31 hooks across four lifecycle events: UserPromptSubmit (keyword detection), Stop (continuation enforcement), PreToolUse (permission validation), PostToolUse (error recovery)
- Magic keyword system -- natural language triggers like `autopilot`, `ralph`, `ulw`, `team`, `plan`, `eco` that activate execution modes inline without slash commands
- 12 LSP tools for code intelligence: hover, goto-definition, find-references, document-symbols, workspace-symbols, diagnostics, rename, code-actions
- AST pattern matching via ast-grep integration for structural code search and transformation with meta-variables
- Multi-AI orchestration -- optional Gemini CLI (1M token context for design review) and Codex CLI (architecture validation) as external MCP providers
- Notepad system -- compaction-resilient memory that survives context window compression, with priority (permanent), working (7-day TTL), and manual sections
- Project memory -- persistent JSON store for tech stack, build commands, conventions, structure notes, and directives that persist across sessions
- State management at `.omc/state/` with per-mode JSON files tracking phase, iteration count, and linked modes
- HUD statusline with real-time orchestration metrics, agent status, token analytics, and configurable presets (minimal, focused, full, dense, analytics)
- Rate limit auto-resume daemon via tmux that detects API rate limits and re-starts Claude Code sessions automatically
- Stop callback notifications to Telegram, Discord, and Slack when execution completes or stalls
- Session replay via `.omc/state/agent-replay-*.jsonl` event timelines for post-mortem analysis
- Skill learning -- extracts reusable problem-solving patterns from sessions for future reuse
- Project Session Manager -- isolated dev environments using git worktrees and tmux sessions

## 3. Pros

- Zero learning curve: install the plugin, run `/oh-my-claudecode:omc-setup`, and natural language keywords handle the rest
- Genuine multi-agent parallelism: multiple Claude Code sub-agents work on independent tasks concurrently, unlike single-session tools
- Smart model routing saves 30-50% on token costs by sending simple tasks to Haiku and reserving Opus for complex reasoning
- Evidence-based verification protocol requires fresh (within 5 minutes) BUILD, TEST, LINT, FUNCTIONALITY, and ARCHITECT checks before claiming completion
- Ralph mode solves the premature-exit problem: loops until the verifier confirms all tasks are genuinely complete
- Composable skill architecture: execution skill + N enhancements + optional guarantee layer (e.g., autopilot + tdd + ralph)
- LSP and AST tools give agents real code intelligence rather than relying solely on text search and pattern matching
- Notepad survives context compaction, solving the memory loss problem that plagues long-running Claude Code sessions
- Plugin architecture means zero modification to Claude Code itself -- pure behavioral injection via CLAUDE.md and hooks
- Active development with 160+ releases and frequent iteration on the orchestration model
- MIT licensed, fully open source
- Supports cross-validation with external AI providers (Gemini, Codex) for architecture review and design consistency

## 4. Cons

- Requires Claude Max/Pro subscription ($100-200/month) plus optional Gemini/Codex subscriptions (~$60/month total for all three providers)
- Heavy context overhead: the injected CLAUDE.md, agent definitions, hook rules, and skill prompts consume significant tokens from the context window
- Depends on experimental Claude Code features (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) that Anthropic could change or remove
- Complex internal machinery: 31 hooks, 37 skills, and 32 agents create a large surface area for subtle bugs and unexpected interactions
- Legacy mode confusion: swarm, ultrapilot, and ecomode still exist as facades routing to Team, which can confuse users reading older documentation
- No visual verification: like Ralph, OMC agents cannot detect UI/visual bugs -- functional tests pass but rendered output may be broken
- Rate limits compound: multiple parallel agents consume API quota faster, hitting rate limits more frequently than single-session usage
- Debugging orchestration failures requires understanding the hook lifecycle, state files, and agent delegation chain -- non-trivial when things go wrong
- Token cost unpredictability: parallel agent execution can spike costs unexpectedly during ultrawork or team-exec phases
- Not officially backed by Anthropic -- community project that could break with Claude Code updates

## 5. Comparison

| Tool | Key Difference vs OMC |
|------|-----------------------|
| SuperClaude | SuperClaude is a single-session behavioral configuration framework (personas, commands, modes via markdown). OMC is a multi-agent orchestration system that spawns and coordinates parallel Claude Code sub-agents. SuperClaude makes one agent smarter; OMC makes many agents work together. |
| Ralph | Ralph is the atomic primitive: a while-true loop that re-runs Claude until done. OMC incorporates Ralph as one of its execution modes but adds 31 other agents, a staged pipeline, verification protocols, and parallel execution on top. Ralph is a bash loop; OMC is a full orchestration platform. |
| claude-flow | claude-flow uses external infrastructure (SQLite, vector DBs, custom coordination servers) to manage multiple Claude instances. OMC stays entirely within the Claude Code plugin ecosystem using native Task spawning, hooks, and CLAUDE.md injection. claude-flow is infrastructure-heavy; OMC is plugin-native. |
| BMAD | BMAD prescribes a full SDLC methodology with 21 persona agents and phased documentation artifacts. OMC focuses on execution orchestration rather than process methodology. BMAD tells you what to build and when; OMC gives you the agents to build it in parallel. |
| GasTown | GasTown is a Rust-based infrastructure platform with Mayor/Polecat architecture, crash recovery, and persistent messaging. OMC achieves similar coordination through Claude Code's native team and task primitives without external infrastructure. GasTown is a platform; OMC is a plugin. |
| GetShitDone | GSD is a context-engineering approach focused on spawning fresh sub-agents with max-3-task plans and aggressive context management. OMC shares the sub-agent philosophy but adds staged pipeline orchestration, verification loops, and persistent state. GSD is minimalist; OMC is comprehensive. |

## 6. Why is it unique?

OMC is the only tool that turns Claude Code's native plugin and hook system into a full multi-agent orchestration platform without any external infrastructure. While claude-flow needs SQLite and custom servers, and GasTown needs a Rust runtime, OMC operates entirely within Claude Code's own primitives: CLAUDE.md injection, the Task tool for sub-agent spawning, hooks for lifecycle interception, and the experimental teams API for coordination. The composable skill system (execution + enhancement + guarantee layers) lets users stack behaviors like `team ralph tdd` to get coordinated multi-agent execution with persistence loops and test-driven enforcement in a single natural language command. The three-tier model routing (Haiku/Sonnet/Opus) with optional cross-provider validation (Gemini/Codex) is something no other tool in the space offers. OMC also uniquely solves the context compaction problem through its notepad and project memory systems, and the HUD statusline gives real-time observability into what multiple agents are doing -- a capability that simply does not exist in simpler loop-based tools like Ralph or context-engineering tools like GetShitDone.

## 7. Simple Usage

```bash
/plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode
/plugin install oh-my-claudecode
/oh-my-claudecode:omc-setup
```

Then inside Claude Code:

```
autopilot: build a REST API with authentication and tests

ralph: refactor the database layer until all tests pass

/oh-my-claudecode:team 3:executor "fix all TypeScript errors in src/"

ulw fix all lint warnings across the project

plan the migration from Express to Fastify

/oh-my-claudecode:code-review

/oh-my-claudecode:security-review
```
