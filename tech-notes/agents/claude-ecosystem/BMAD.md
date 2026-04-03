# BMAD

## 1. What is it?

BMAD stands for Breakthrough Method for Agile AI-Driven Development. It is an open-source framework and methodology that transforms AI coding assistants (Claude Code, Cursor, Windsurf, VS Code) into a simulated agile development team. Rather than treating the AI as a single assistant, BMAD defines 21 specialized agent personas (Analyst, Product Manager, Architect, Scrum Master, Developer, QA, UX Designer, etc.) each represented as markdown files with YAML configuration. These agents collaborate through a structured pipeline: brainstorming, requirements gathering (PRD), architecture design, story creation, sprint planning, implementation, and review.

The core insight is "document sharding" -- breaking project documentation into atomic, AI-digestible pieces that persist across fresh chat sessions via git-versioned artifacts. Each agent produces documents that become input for the next agent, creating a factory-line workflow where context is never lost.

- GitHub: github.com/bmad-code-org/BMAD-METHOD
- Docs: docs.bmad-method.org
- Website: bmadcodes.com
- npm: `npx bmad-method install`
- Current version: v6 Alpha

## 2. Main Features

- 21 specialized AI agent personas (Analyst, PM, Architect, Scrum Master, Developer, QA, UX Designer, etc.)
- 50+ guided workflows with slash commands
- Scale-adaptive intelligence that adjusts from bug fixes to enterprise systems
- Document sharding -- atomic, AI-digestible artifacts that persist in git
- Codebase flattener tool that packages your entire codebase into a single XML file for AI context
- Expansion packs for non-software domains (creative writing, business strategy, wellness, education)
- IDE integration with Claude Code, Cursor, Windsurf, and VS Code
- Non-interactive CLI installation for CI/CD
- Adversarial review workflow where agents challenge each other's output
- Course-correction workflow for handling scope changes mid-sprint
- Git-versioned artifacts for full traceability of every decision

## 3. Pros

- Provides structure and repeatability to AI-assisted development, replacing ad-hoc "vibe coding" with a documented process
- Documentation is generated as a natural byproduct of the workflow, not an afterthought
- Story files embed full context (the "why" and "how"), reducing hallucination and context loss during implementation
- Git-based versioning of all artifacts provides traceability and accountability
- Domain-agnostic with expansion packs -- not limited to software development
- Free and open source with no paywalls
- Large and active community (120K+ views on the v4 Masterclass, 1200+ GitHub issues)
- Works with multiple LLM providers (Claude, GPT-4, Gemini, DeepSeek)
- Fresh chat per workflow avoids context window exhaustion
- Human-in-the-loop design -- the AI collaborates rather than replaces human judgment

## 4. Cons

- Steep learning curve: requires understanding 21 agents, YAML configs, CLI commands, and multi-phase handoffs
- Highly prescriptive and rigid workflow -- full PRD and architecture must be generated before any code is written
- Significant overhead for simple projects, prototypes, or small tasks
- AI fallibility cascades: if one agent produces flawed output, downstream agents may not catch the error
- Dependent on powerful LLMs with large context windows; smaller models struggle with the token-heavy artifacts
- Not truly automated -- still requires significant human guidance and review at each stage
- False positives in AI reviews (adversarial review agents will find "problems" that do not exist)
- Initially focused on single-service sprint cycles; microservices or multi-repo architectures require applying BMAD separately to each repo
- Compared to lighter alternatives (GSD, SpecKit), the cognitive overhead is substantially higher
- The method is more of a Standard Operating Procedure than a tool -- it enforces process discipline

## 5. Comparison

| Tool | Key Difference vs BMAD |
|------|------------------------|
| claude-flow | claude-flow is about runtime agent coordination (10+ agents working in parallel). BMAD is about the full development lifecycle from ideation to deployment. They are complementary -- BMAD for planning discipline, claude-flow for parallel execution. |
| Ralph | Ralph is the polar opposite in philosophy. A simple bash loop that feeds AI output back into itself until tasks complete. Where BMAD is comprehensive and structured, Ralph is radically simple and brute-force. |
| SuperClaude | SuperClaude is lighter and more suited for solo developers wanting structured commands without overhauling their workflow. BMAD is a complete SOP for teams wanting end-to-end agile process. |
| ContinuousClaude | ContinuousClaude focuses on autonomous execution within a CI/CD pipeline. BMAD focuses on planning and structured handoffs. |
| GasTown | GasTown is more infrastructure-focused (parallel agent spawning, crash recovery, git worktrees). BMAD is more methodology-focused (PRD, architecture, stories, sprints). |
| GetShitDone | GSD directly opposes BMAD's "enterprise theater" approach. GSD spawns fresh subagent contexts, uses atomic XML plans, and avoids sprint ceremonies. BMAD is maximum structure and documentation; GSD is minimal process overhead. |

## 6. Why is it unique?

BMAD is unique because it is not a tool or a library -- it is a complete software development methodology designed specifically for the AI era. Its distinguishing characteristics: documentation as the primary source of truth (not source code), agents represented as markdown files with YAML headers (editable, versionable, and understandable without programming knowledge), domain universality through expansion packs extending beyond software into any domain, and the only framework that simulates a full agile team lifecycle from brainstorming through sprint retrospectives with each role having defined inputs, outputs, and handoff protocols.

## 7. Simple Usage

```bash
npx bmad-method install

/bmad-help

/bmad-agent-bmm-analyst
# "I want to build a task management API with auth and team features"

/bmad-bmm-create-prd

/bmad-bmm-create-architecture

/bmad-bmm-create-stories

/bmad-bmm-sprint-planning

/bmad-bmm-dev
```

Each step should be run in a fresh chat session to avoid context window exhaustion. The artifacts produced by each step are persisted in git, so the next agent picks up exactly where the previous one left off.
