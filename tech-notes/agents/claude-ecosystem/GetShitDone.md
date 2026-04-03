# GetShitDone

## 1. What is it?

Get Shit Done (GSD) is a lightweight meta-prompting, context engineering, and spec-driven development system for Claude Code (and also OpenCode and Gemini CLI). Created by a developer known as TACHES (GitHub: @glittercowboy), it is an orchestration layer that sits on top of Claude Code and transforms it from an inconsistent code generator into a reliable, structured development system.

The core problem it solves is "context rot" -- the quality degradation that happens as Claude fills its context window. Instead of running one long session that gradually degrades, GSD spawns fresh Claude subagent instances for each task, each getting a clean 200,000 token context window. Task 50 has the same quality as Task 1.

The philosophy is: "The complexity is in the system, not in your workflow."

- GitHub: github.com/glittercowboy/get-shit-done (12,300+ stars, 1,200+ forks)
- Install: `npx get-shit-done-cc --claude --global`

## 2. Main Features

- Parallel Subagent Orchestration -- spawns fresh Claude instances per task with full 200k token contexts, main context window stays at 30-40%
- Spec-Driven Development -- enforces the workflow: Idea -> Roadmap -> Phase Plan -> Atomic Execution
- Atomic Git Commits -- each task gets its own commit immediately after completion, independently revertable
- Max-3-Task Plans -- each plan contains a maximum of 3 tasks, running in a fresh subagent with zero accumulated garbage
- Codebase Mapping -- /gsd:map-codebase spawns parallel agents to analyze your stack, architecture, conventions, and concerns
- Structured State Management -- .planning/ directory tracks PROJECT.md, ROADMAP.md, STATE.md, ISSUES.md, and config.json
- Phase-Based Workflow Commands -- /gsd:plan-phase, /gsd:execute-plan, /gsd:complete-milestone, /gsd:verify-work
- Gap Resolution -- built-in verification and gap-closure workflow
- Multi-Runtime Support -- works on Claude Code, OpenCode, and Gemini CLI

## 3. Pros

- Solves context rot effectively -- fresh subagent contexts mean no quality degradation over long projects
- Lightweight and simple -- no enterprise theater, no sprint ceremonies, no story points
- Low learning curve compared to BMAD and other frameworks
- Excellent user reviews -- users report better results than BMAD, SpecKit, and Taskmaster
- Trusted by engineers at Amazon, Google, Shopify, and Webflow
- Atomic, traceable commits -- git bisect can find the exact failing task
- Intelligent project planning -- Claude asks product-centered questions and extracts sensible steps from vague project descriptions
- Active community and ecosystem with multiple forks and adaptations
- Easy installation -- single npx command, works on Mac, Windows, and Linux

## 4. Cons

- High token consumption -- the "quizzing" phases and subagent spawning consume significant tokens
- Slow execution -- a full project can take 45-60 minutes, with about 30 minutes of GSD working while you wait
- Requires clear requirements from the user -- GSD helps structure work, but still needs you to articulate what you want
- Requires autonomous execution -- approving each action manually defeats the purpose
- Jargon-heavy despite claiming simplicity -- plans, requirements, phases, waves, checkpoints
- OpenCode adaptation is not perfect -- community ports to non-Claude-Code runtimes have gaps
- Learning curve for phase optimization -- users need experience to know which phases to streamline
- Critics argue it may be temporary -- as Claude Code's native tooling improves, these frameworks may be absorbed into simpler patterns

## 5. Comparison

| Tool | Key Difference vs GetShitDone |
|------|-------------------------------|
| claude-flow | More infrastructure-heavy than GSD. claude-flow is a full orchestration platform with swarm intelligence. GSD focuses purely on spec-driven solo development. |
| BMAD | BMAD is the most complex option -- full agile role simulation with 21 agents. GSD does similar things but streamlined for solo developers. BMAD excels at comprehensive documentation; GSD excels at simplicity and speed. |
| Ralph | Ralph is simpler than GSD -- just a brute-force loop. GSD has task decomposition, codebase mapping, and milestone verification. Ralph has none of that. |
| SuperClaude | Different philosophy entirely. SuperClaude enhances Claude's capabilities through commands and persona-based interactions. GSD is a workflow system; SuperClaude is a capability enhancer. |
| ContinuousClaude | ContinuousClaude is a CI/CD automation loop or context management framework. GSD is a spec-driven development system. Different focus. |
| GasTown | GasTown operates at a completely different scale and ambition level, coordinating dozens of Claude Code instances in parallel. GSD is a solo-developer workflow; GasTown is a multi-agent workspace manager. |

## 6. Why is it unique?

GSD occupies a specific niche that no other tool fills as well: it is the simplest spec-driven orchestration layer for solo developers using Claude Code. Its uniqueness comes from targeted simplicity (explicitly rejecting "enterprise theater"), treating context rot as a first-class problem (the max-3-task-per-plan constraint and fresh subagent spawning are architectural decisions driven by this single concern), the "Lean Orchestrator" pattern where the orchestrator never does heavy lifting (only spawns, waits, and integrates), and being opinionated but minimal (prescribes a specific workflow without imposing roles, ceremonies, or excessive abstraction layers).

## 7. Simple Usage

```bash
npx get-shit-done-cc --claude --global

claude

/gsd:map-codebase

/gsd:new-project

/gsd:plan-phase 1

/gsd:execute-plan

/gsd:verify-work 1

/gsd:plan-phase 1 --gaps
/gsd:execute-phase 1 --gaps-only

/gsd:plan-phase 2

/gsd:complete-milestone
```

The .planning/ directory will be created with:
```
.planning/
  PROJECT.md
  ROADMAP.md
  STATE.md
  ISSUES.md
  config.json
  codebase/
    STACK.md
    ARCHITECTURE.md
    STRUCTURE.md
    CONVENTIONS.md
    TESTING.md
    INTEGRATIONS.md
    CONCERNS.md
```
