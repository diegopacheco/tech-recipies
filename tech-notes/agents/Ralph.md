# Ralph

## 1. What is it?

Ralph (formally known as "Ralph Wiggum") is an autonomous AI agent loop technique and tool that runs AI coding agents (primarily Claude Code) repeatedly in a loop until all tasks defined in a PRD (Product Requirements Document) are complete. Named after the persistently hapless Ralph Wiggum character from The Simpsons, it was popularized by developer Geoffrey Huntley in mid-2025.

At its core, Ralph is a `while true` bash loop that repeatedly feeds a prompt to Claude Code. When Claude tries to exit (thinking it is done), the loop intercepts that exit, checks whether the completion criteria have been met, and if not, re-feeds the prompt with updated context. Each iteration can be a fresh context window, with memory persisting via git history, `progress.txt`, and `prd.json`.

Ralph grew so prominent that Anthropic formalized it into the official ralph-wiggum plugin shipped with Claude Code. It uses a "Stop Hook" mechanism that intercepts exit attempts and re-injects the original prompt using exit code 2.

Multiple implementations exist:
- Official plugin: anthropics/claude-code/plugins/ralph-wiggum
- Community: snarktank/ralph, frankbria/ralph-claude-code
- Extended: mikeyobrien/ralph-orchestrator, vercel-labs/ralph-loop-agent
- TUI: subsy/ralph-tui

## 2. Main Features

- Autonomous development loops with intelligent exit detection
- Dual-condition exit gate requiring BOTH completion indicators AND an explicit EXIT_SIGNAL
- Rate limiting with hourly reset (100 calls/hour, configurable)
- Circuit breaker with advanced error detection
- Response analyzer with semantic understanding and two-stage error filtering
- PRD-driven task tracking (reads prd.json and progress.txt each iteration)
- Fresh context window per iteration (in bash loop mode), preventing context rot
- Memory persistence via git history rather than in-context memory
- Works with multiple backends: Claude Code, Amp, Codex CLI, Gemini CLI
- Max-iterations safety cap to prevent runaway loops
- Completion-promise string matching for detecting task completion
- Supports overnight/unattended batch execution across multiple projects

## 3. Pros

- Extremely simple conceptually -- at its core, just a bash while loop
- Solves the "premature exit" problem where Claude stops before the job is truly done
- Fresh context per iteration avoids context window degradation over long tasks
- No complex orchestration framework needed -- git is the persistence layer
- Officially supported by Anthropic as a first-party Claude Code plugin
- Proven at scale: Geoffrey Huntley ran a 3-month loop that built a complete programming language
- Cost-effective for batch work: YC hackathon teams shipped 6+ repos overnight for ~$297
- Works for large refactors, batch operations, test coverage, and greenfield builds
- Community-validated with multiple independent implementations
- Shifts the skill from "directing Claude step by step" to "writing prompts that converge"

## 4. Cons

- High token costs: a 50-iteration loop on a large codebase can easily cost $50-$100+ in API credits
- Context compaction issues: long-running sessions suffer from context compaction where earlier instructions get compressed or lost, causing drift ("Compaction is the devil" -- Huntley)
- Unreliable completion detection: `--completion-promise` uses exact string matching, which is fragile
- Visual/UI bugs go undetected: functional tests pass but UI can be broken -- Ralph cannot verify visual correctness
- Does not replace human judgment: automates mechanical execution only; architectural and design decisions still require a human
- Trust and reviewability concerns: large diffs produced without human checkpoints raise code quality questions
- Platform compatibility: the plugin has an undocumented jq dependency that breaks on Windows/Git Bash
- Prompt quality dependency: results are only as good as the prompt and completion criteria you define
- No intelligent task decomposition: unlike multi-agent frameworks, Ralph just brute-forces the same prompt repeatedly
- Risk of infinite loops: without --max-iterations, a poorly defined completion promise can loop indefinitely

## 5. Comparison

| Tool | Key Difference vs Ralph |
|------|------------------------|
| claude-flow | claude-flow is a full platform with dozens of agents, vector DBs, and swarm topologies. Ralph is the opposite: just a bash loop and git. |
| BMAD | BMAD is comprehensive and structured with 21 persona agents and phased handoffs. Ralph has zero personas and one prompt. |
| SuperClaude | SuperClaude enhances one agent's effectiveness through config injection. Ralph re-runs the agent in a loop. They could be combined. |
| ContinuousClaude | ContinuousClaude is PR-centric, creating branches and waiting for CI checks. Ralph is prompt-centric, iterating until a completion string appears. Similar philosophy, different focus. |
| GasTown | GasTown costs ~$100/hour and uses a Mayor/Polecat architecture for parallel agents. Ralph costs less and uses nothing but bash and git for sequential execution. |
| GetShitDone | GSD focuses on context engineering, spawning fresh subagents with max-3-task plans. Ralph has no task decomposition -- it brute-forces one prompt repeatedly. |

## 6. Why is it unique?

Ralph is an anti-framework. While the AI agent ecosystem was building increasingly elaborate multi-agent swarms, persona systems, and orchestration platforms, Ralph proved that a `while true` bash loop could outperform them for many practical tasks. Its radical simplicity is its differentiator. Rather than fighting context window limits (like claude-flow's SQLite memory or ContinuousClaude's ledgers), Ralph embraces them by starting fresh each iteration. Prior work lives in git, not in the conversation. It went from a community hack to an Anthropic first-party plugin, which no other community pattern has achieved at this level.

## 7. Simple Usage

Using the official Claude Code plugin:

```bash
claude install-plugin ralph-wiggum

claude
> /ralph-loop "Implement all items in prd.json. Update progress.txt after each item. When all items are checked off, output DONE." --max-iterations 20 --completion-promise "DONE"
```

Using the original bash loop (no plugin needed):

```bash
#!/bin/bash
if [ -z "$1" ]; then
  exit 1
fi
for ((i=1; i<=$1; i++)); do
  result=$(claude -p "$(cat PROMPT.md)" --output-format text 2>&1) || true
  if [[ "$result" == *"COMPLETE"* ]]; then
    exit 0
  fi
done
```

Run it: `./ralph.sh 20`
