# ContinuousClaude

## 1. What is it?

There are two distinct projects called "ContinuousClaude" / "Continuous Claude":

**Project A: continuous-claude by Anand Chowdhary** -- A CLI tool (Bash script) that runs Claude Code in a continuous loop, autonomously creating Git branches, committing code, opening GitHub PRs, waiting for CI checks, and merging successful PRs -- or closing failed ones and retrying with knowledge of the failure. A shared markdown file (SHARED_TASK_NOTES.md) acts as persistent memory between iterations. Originally built because the author needed to go from 0% to 80%+ test coverage on a large codebase in a few weeks.

- GitHub: github.com/AnandChowdhary/continuous-claude

**Project B: Continuous-Claude-v3 by parcadei** -- A persistent, learning, multi-agent development environment built on top of Claude Code. It focuses on context management -- using hooks, ledgers, YAML handoffs, and isolated agent context windows to ensure Claude Code never loses learned knowledge when context compaction occurs. The motto is "Compound, don't compact."

- GitHub: github.com/parcadei/Continuous-Claude-v3

## 2. Main Features

**Anand's continuous-claude:**
- Runs Claude Code in a loop with configurable max runs (--max-runs) or max cost (--max-cost)
- Each iteration: new branch, code generation, commit, push, open PR, wait for CI, merge or discard
- Shared notes file (SHARED_TASK_NOTES.md) serves as external memory across iterations
- Git worktree support for parallel execution (--worktree)
- Piggybacks on existing GitHub workflows (code owner approval, CI checks, preview environments)
- Failed iterations close the PR and feed failure knowledge into the next attempt
- MIT License

**parcadei's Continuous-Claude-v3:**
- 32 specialized AI agents (aegis, herald, scribe, chronicler, session-analyst, etc.)
- 30 lifecycle hooks (SessionStart, PreToolUse, PreCompact, UserPromptSubmit, PostToolUse, etc.)
- 109 modular skills activated via natural language
- Continuity ledgers (CONTINUITY_*.md) and YAML handoffs preserve state across sessions
- Context usage monitoring with color-coded warnings (green < 60%, yellow 60-79%, red >= 80%)
- PreCompact hook blocks manual compaction and creates auto-handoffs instead
- Shift-left validation via hooks (runs pyright/ruff after edits, catches errors before tests)
- Agent orchestration with isolated context windows
- No paid services required

## 3. Pros

**Anand's version:**
- Dead simple -- a single Bash script, no heavy dependencies
- Leverages existing GitHub infrastructure (CI, reviews, branch protection)
- Persistent memory via a plain markdown file -- easy to inspect and edit manually
- Worktree support enables parallelism
- Designed for human-AI collaboration loops (human reviews between iterations)
- MIT licensed

**parcadei's version:**
- Comprehensive -- 32 agents, 109 skills, 30 hooks
- Solves the core "context compaction" problem that plagues long Claude Code sessions
- Structured handoff system means session knowledge truly persists
- Natural language activation -- no need to memorize slash commands
- Shift-left validation catches errors early
- Free and open source with no required paid services

## 4. Cons

**Anand's version:**
- Failed iterations discard all work (wasteful in terms of tokens and compute)
- No specialized agents or sub-agent orchestration -- single Claude Code instance looping
- Memory is just a flat markdown file -- no structured knowledge graph or database
- Requires gh CLI, jq, and authenticated Claude Code CLI
- No built-in context window management or compaction handling
- Relatively simple -- may not scale to very complex multi-service architectures

**parcadei's version:**
- Very large and opinionated framework -- heavy setup in .claude/ directory
- Learning curve to understand 32 agents, 109 skills, and 30 hooks
- May conflict with existing .claude/ configurations in a project
- Complexity may be overkill for simple projects
- Community fork ecosystem (v1, v2, v3, razor-ai fork) may cause confusion about which version to use

## 5. Comparison

| Tool | Key Difference vs ContinuousClaude |
|------|-------------------------------------|
| claude-flow | claude-flow manages multiple concurrent agents with swarm intelligence and SQLite memory. ContinuousClaude (Anand) is a simpler PR loop. ContinuousClaude v3 (parcadei) uses file-based ledgers and focuses on context preservation rather than swarm coordination. |
| BMAD | BMAD is a methodology/SOP, not a runtime loop. It enforces a rigid Plan-Architect-Implement-Review cycle. ContinuousClaude is about autonomous execution or context persistence, not process governance. |
| Ralph | Ralph and Anand's continuous-claude are conceptually similar -- both are autonomous loops. Ralph is PRD-driven (iterates over checklist items), while continuous-claude is PR-centric. |
| SuperClaude | SuperClaude adds capabilities as features through config injection. ContinuousClaude automates the loop (Anand) or manages context (parcadei). |
| GasTown | GasTown's Polecats are ephemeral by design (context dies, work survives in git). ContinuousClaude v3 takes the opposite approach -- context must be preserved via ledgers and handoffs. |
| GetShitDone | GSD is about prompt engineering and process optimization. ContinuousClaude (Anand) is about autonomous execution loops. ContinuousClaude v3 is about context management. |

## 6. Why is it unique?

Anand's continuous-claude is unique because it is the simplest possible approach to autonomous Claude Code execution -- a single Bash script that creates a CI/CD-like feedback loop between Claude Code and GitHub. No agents, no frameworks, no databases. Just a loop, a notes file, and GitHub PRs.

parcadei's Continuous-Claude-v3 is unique because it directly attacks the context compaction problem -- the single biggest limitation of long-running Claude Code sessions. While other tools add orchestration or process, this one ensures that knowledge genuinely accumulates session over session through ledgers, handoffs, and pre-compaction hooks. The "compound, don't compact" philosophy is a fundamentally different approach from tools that accept context loss and work around it.

## 7. Simple Usage

**Anand's continuous-claude:**

```bash
curl -fsSL https://raw.githubusercontent.com/AnandChowdhary/continuous-claude/refs/tags/v0.14.0/install.sh | bash

continuous-claude \
  --prompt "Add unit tests to reach 80% coverage" \
  --max-runs 10 \
  --owner myuser \
  --repo myproject
```

**parcadei's Continuous-Claude-v3:**

Clone or copy the .claude/ directory structure into your project, then start a Claude Code session. The hooks automatically load ledgers and handoffs on session start:

```
You: "Analyze the control flow of src/main.ts"
(Claude activates the TLDR analysis skill automatically)

You: "Create a handoff for the next session"
(Claude creates a YAML handoff preserving current context)
```
