# Claude Code Dynamic Workflows

## What is it?

Dynamic workflows let Claude write a JavaScript orchestration script for a task you describe, then hand that script to a separate runtime that executes it in the background - spinning up tens to hundreds of parallel subagents in a single session and checking its own work before anything reaches you. Anthropic shipped it on May 28, 2026 as a research preview, alongside Claude Opus 4.8.

The pitch: some problems are too big for one pass by a single agent, especially in large, legacy codebases - a bug hunt across an entire service, a migration touching hundreds of files, a plan you want stress-tested from every angle before committing. A single agent runs out of context and coordination capacity. Dynamic workflows move the *plan itself* into code so the orchestration can scale past what one conversation can hold. The framing is blunt: "work you'd normally plan in quarters now finishes in days."

A run can spawn up to **1,000 agents total**, with up to **16 running concurrently** (fewer on machines with limited CPU cores).

## The core idea - move the plan into code

This is the distinction that matters. With plain [[claude-code]] subagents or skills, *Claude* is the orchestrator: it decides turn by turn what to spawn next, and every intermediate result lands back in Claude's context window. That caps how big the task can get - context fills up, coordination gets sloppy.

A workflow script holds the loop, the branching, and the intermediate results *itself*. Claude's context only ever holds the final answer. The runtime tracks each agent's result as the run progresses.

| | Subagents | Skills | Workflows |
|---|---|---|---|
| What it is | A worker Claude spawns | Instructions Claude follows | A script the runtime executes |
| Who decides what runs next | Claude, turn by turn | Claude, following the prompt | The script |
| Where intermediate results live | Claude's context | Claude's context | Script variables |
| What's repeatable | The worker definition | The instructions | The orchestration itself |
| Scale | A few delegated tasks per turn | Same as subagents | Dozens to hundreds of agents per run |
| Interruption | Restarts the turn | Restarts the turn | Resumable in the same session |

Moving the plan into code buys more than raw agent count: it lets a workflow apply a repeatable *quality pattern*. Independent agents can adversarially review each other's findings before they are reported, or draft a plan from several angles and weigh them against each other - so the result is more trustworthy than a single pass.

## How a run works

1. You describe a task (or run a saved/bundled workflow command).
2. Claude writes a JavaScript orchestration script for it.
3. You approve the plan (prompt depends on permission mode - see below).
4. The runtime executes the script in an isolated environment, separate from your conversation, spinning subagents up in parallel across phases.
5. Your session stays responsive the whole time - the run is in the background.
6. You get one final report instead of a turn-by-turn transcript.

The script coordinates agents but has **no direct filesystem or shell access of its own** - the agents read, write, and run commands; the script just orchestrates them.

## Two ways to start a workflow

Anthropic recommends turning on [[claude-auto-mode]] first for the best experience (a long parallel run with constant approval prompts would be miserable). From there:

- **Ask directly** - put the word `workflow` in your prompt ("create a workflow to ...") and Claude writes one for the task.
- **Ultracode** - set `/effort ultracode`. This combines `xhigh` reasoning effort with automatic workflow orchestration: Claude decides on its own when a task warrants a workflow, for *every* substantive task in the session. A single request can turn into several workflows in a row - one to understand the code, one to make the change, one to verify it.

`ultracode` lasts for the current session and resets when you start a new one; drop back to `/effort high` for routine work. It only appears in the `/effort` menu on models that support `xhigh` effort.

## Bundled workflow: `/deep-research`

Claude Code ships one built-in workflow to try immediately:

```
/deep-research What changed in the Node.js permission model between v20 and v22?
```

It fans out web searches across several angles, fetches and cross-checks the sources it finds, votes on each claim, and returns a cited report with claims that did not survive cross-checking filtered out. Requires the WebSearch tool to be available. Workflows you save yourself become `/` commands the same way and show up in autocomplete alongside it.

## Watching and managing runs

Run `/workflows` to list running and completed workflows, then select one to open its progress view. The view shows each phase with its agent count, token total, and elapsed time.

| Key | Action |
|---|---|
| `↑` / `↓` | Select a phase or agent |
| `Enter` / `→` | Drill into a phase, then an agent, to read its prompt, recent tool calls, and result |
| `Esc` | Back out one level |
| `j` / `k` | Scroll within agent detail when it overflows |
| `p` | Pause or resume the run |
| `x` | Stop the selected agent, or the whole workflow when focus is on the run |
| `r` | Restart the selected running agent |
| `s` | Save the run's script as a command |

**Resume** works within the same session: stop a run, and on resume the agents that already completed return their cached results while the rest run live. But if you exit Claude Code while a workflow is running, the next session starts it fresh - resume does not survive a restart.

## Saving a workflow for reuse

When Claude writes a workflow for something you will repeat (a review you run on every branch, say), press `s` in `/workflows` to save that run's script as a command. Two locations, toggled with Tab in the save dialog:

- `.claude/workflows/` in the project - shared with everyone who clones the repo.
- `~/.claude/workflows/` in your home directory - available in every project, visible only to you.

It then runs as `/<name>` in future sessions. If a project workflow and a personal workflow share a name, the project one wins.

## Permissions

Your permission mode controls only the *launch* prompt, not what the agents do once running:

| Permission mode | When you're prompted to launch |
|---|---|
| Default, accept edits | Every run, unless you chose "don't ask again" for that workflow in this project |
| Auto | First launch only; a Yes records consent in user settings. Skipped entirely when `ultracode` is on |
| Bypass permissions, `claude -p`, Agent SDK | Never - the run starts immediately |

Crucially: the subagents a workflow spawns **always run in `acceptEdits` mode** and inherit your tool allowlist, regardless of the session's mode. File edits are auto-approved. Shell commands, web fetches, and MCP tools that are *not* in your allowlist can still prompt you mid-run - so for a long unattended run, add what the agents will need to your allowlist before starting.

## Behavior and limits

| Constraint | Why |
|---|---|
| No mid-run user input | Only agent permission prompts can pause a run. For sign-off between stages, run each stage as its own workflow |
| No direct filesystem/shell access from the workflow itself | Agents do the work; the script only coordinates |
| Up to 16 concurrent agents (fewer on low-core machines) | Bounds local resource use |
| 1,000 agents total per run | Prevents runaway loops |

## What it costs

A workflow spawns many agents, so a single run can use **meaningfully more tokens** than working the same task through conversation. Anthropic's own note: it "can consume substantially more tokens than a typical Claude Code session," and they recommend starting on a scoped task to get a feel for usage. Runs count toward your plan's usage and rate limits like any other session. You can stop a run from `/workflows` at any time without losing completed work.

Every agent uses your session's model unless the script routes a stage elsewhere. To control cost: check `/model` before a large run (in case you usually drop to a smaller model for routine work), and ask Claude to use a smaller model for stages that don't need the strongest one.

## What people use it for

- **Discovery and review across large codebases** - codebase-wide bug hunts, profiler-guided optimization audits, security/hardening passes (auth checks, input validation, unsafe patterns). Claude searches the repo in parallel, then runs *independent verification* on every finding so the report surfaces real issues, not noise. One early adopter reported it finding dead code and cleanup opportunities that static analysis missed.
- **Large migrations and modernization** - framework swaps, API deprecations, language ports spanning thousands of files, end to end.
- **Critical work you need checked twice** - when a wrong answer is expensive, a workflow gives Claude independent attempts at the problem plus adversarial agents trying to break the result before you see it.

## Why it matters

The dominant agent pattern has been a single conversation that orchestrates a handful of subagents, with every result flowing back through one context window. That ceiling is real: past a certain task size, the orchestrator runs out of room and attention. Dynamic workflows break the ceiling by codifying the plan as a script the runtime owns, so the agent's context stays small while the work fans out wide. It is a [[harness]]-level move, not a model capability - the same shift in thinking as [[claude-auto-mode]] (let a system, not the human, handle the parts that don't need a human) applied to orchestration instead of approval.

It also sits between two existing things: bigger than firing off a single subagent, lighter than standing up a full persistent agent team like [[hermes-agent]]. As one early user put it, it "fills the gap between firing off a single subagent and building out a full agent team."

The honest caveats are the cost and the preview status. Token spend scales with agent count and can balloon fast, the resume guarantee is weak (it does not survive exiting Claude Code), and there is no mid-run human input - you approve the plan up front and read the report at the end, with no checkpoint in between unless you split the work into separate workflows. Treat it as a power tool for genuinely large, parallelizable tasks, not the default mode for everyday work.

## Requirements

- **Version:** Claude Code v2.1.154 or later
- **Surfaces:** Claude Code CLI, Desktop app, VS Code extension; also the Claude API, Amazon Bedrock, Google Cloud Vertex AI, and Microsoft Foundry
- **Plans:** all paid plans. Max, Team, and Enterprise (Enterprise requires admin enablement). On **Pro**, turn it on from the Dynamic workflows row in `/config`
- **Recommended:** auto mode on; `xhigh`-capable model if you want `ultracode`

## Links

* https://claude.com/blog/introducing-dynamic-workflows-in-claude-code
* https://code.claude.com/docs/en/workflows
* https://code.claude.com/docs/en/sub-agents
* https://www.anthropic.com/news/claude-opus-4-8
* https://techcrunch.com/2026/05/28/anthropic-releases-opus-4-8-with-new-dynamic-workflow-tool/
* https://www.marktechpost.com/2026/05/28/anthropic-ships-claude-opus-4-8-alongside-dynamic-workflows-and-cheaper-fast-mode-with-workflows-capped-at-1000-subagents/
