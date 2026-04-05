# Death of GitHub (as we know it)

## Intention

This document captures the transformation happening to GitHub and the developer workflow model it represents. The core thesis is that GitHub was built for a human-centric, PR-review workflow that is fundamentally misaligned with an AI-agent-driven world. As AI agents become primary code producers, the entire development lifecycle — from how intent is expressed (prompts instead of code), to how changes are proposed (prompt requests instead of pull requests), to how quality is assured — needs to be reimagined. This is not about GitHub disappearing, but about the platform and its workflow model becoming insufficient for the agentic future.

## Prompt Intention (PI)

The shift from code-first to prompt-first development means that developer intent is increasingly expressed as natural language prompts rather than hand-written code. The prompt becomes the primary artifact of developer work.

```
┌───────────────────────────────────────────────────────────────┐
│              The Intent Shift                                  │
│                                                               │
│  Old World:  Developer ──► Code ──► Commit ──► PR ──► Review  │
│                                                               │
│  New World:  Developer ──► Prompt ──► Agent ──► Code ──► Ship │
│                                                               │
│  What matters shifted from CODE to INTENT                     │
│  The prompt IS the specification                              │
│  The code is a generated artifact                             │
└───────────────────────────────────────────────────────────────┘
```

Two paradigms emerged in 2026, both deeply flawed:

### Vibe Coding — The Dangerous Default

Andrej Karpathy introduced "vibe coding" in February 2025: generating code via prompts without reading the output, assuming AI handles everything. In practice, this is trial-and-error development with no engineering discipline.

```
┌───────────────────────────────────────────────────────────────┐
│              Why Vibe Coding Fails                             │
│                                                               │
│  Core AI failures:                                            │
│    - Request Ignorance: ask for Java 25, get Java 21          │
│    - Hallucinations: invents non-existent APIs                │
│    - Library Dismissal: ignores specified libs for others     │
│                                                               │
│  Not reading code and not reading DIFFs is awful practice.    │
│                                                               │
│  Acceptable ONLY for:                                         │
│    - Small throwaway utilities (CSV-to-JSON)                  │
│    - Disposable prototypes never meant for production         │
│                                                               │
│  NEVER acceptable for:                                        │
│    - Core business logic (the revenue engine)                 │
│    - Production systems                                       │
│    - Anything with real users                                 │
│                                                               │
│  Bus Factor problem: vibe coding creates succession planning  │
│  vulnerabilities — no one understands the codebase because    │
│  no one read the code. Bus factor drops to zero.              │
│                                                               │
│  The gap: works great in a 5-minute recording.                │
│  Karpathy's Waymo: working 2014 prototype required 11+ years │
│  of real engineering before production deployment in 2025.    │
└───────────────────────────────────────────────────────────────┘
```

### Spec-Driven Development (SDD) — Waterfall in Disguise

SDD proposes writing detailed specification documents before the agent writes code. GitHub shipped the Spec Kit (72K+ stars). The idea: structured requirements, constraints, architecture, and acceptance criteria upfront.

```
┌───────────────────────────────────────────────────────────────┐
│              Why SDD Fails                                     │
│                                                               │
│  More documentation does NOT mean more clarity.               │
│                                                               │
│  Problems:                                                    │
│    - Context window overhead: excessive spec text creates     │
│      technical burden on the LLM itself                       │
│    - Code displacement: teams stop writing code and start     │
│      managing documents instead                               │
│    - No evidence more text produces superior outcomes          │
│    - Resurrects Waterfall anti-patterns in agile clothing     │
│                                                               │
│  François Zaninotto called it: "Waterfall Strikes Back"       │
│  Martin Fowler published critique analyzing tool implications │
│                                                               │
│  SDD is MDD (Model Driven Development) rebranded for the     │
│  LLM era. MDD failed. SDD will fail for the same reasons:    │
│  the map is not the territory, and specs drift from reality   │
│  the moment code starts running.                              │
└───────────────────────────────────────────────────────────────┘
```

### The Real Alternative: Vintage Coding + AI as Accelerator

Neither vibe coding (no discipline) nor SDD (all documents, no code) is the answer.

```
┌───────────────────────────────────────────────────────────────┐
│              Vintage Coding                                    │
│                                                               │
│  Deliberate coding practices where engineers write, read,     │
│  and understand their code — with or without AI assistance.   │
│                                                               │
│  Principles:                                                  │
│    - Read every line of AI-generated code                     │
│    - Read every DIFF before committing                        │
│    - Use AI for 10-30% productivity gain, not 100% delegation │
│    - Practice coding dojos: TDD, pair programming, no AI      │
│    - Master your tools, data structures, algorithms           │
│    - Maintain the ability to code without AI at all           │
│                                                               │
│  Analogy: a driver who passed the exam and has years of       │
│  practice drives safely. A driver constantly checking the     │
│  manual is dangerous. Many programmers now resemble manual-   │
│  consulting drivers — substituting LLMs for learning.         │
│                                                               │
│  AI is a power tool, not a replacement for skill.             │
│  Use it. Don't depend on it. Don't stop learning.             │
└───────────────────────────────────────────────────────────────┘
```

```
┌──────────────────────────┬──────────────────┬─────────────────────────┐
│ Approach                 │ Verdict          │ Risk                    │
├──────────────────────────┼──────────────────┼─────────────────────────┤
│ Vibe Coding              │ Avoid for prod   │ Bus factor 0, no        │
│                          │                  │ understanding of code   │
├──────────────────────────┼──────────────────┼─────────────────────────┤
│ Spec-Driven Development  │ Avoid entirely   │ Waterfall rebranded,    │
│                          │                  │ document management     │
│                          │                  │ replaces engineering    │
├──────────────────────────┼──────────────────┼─────────────────────────┤
│ Vintage Coding + AI      │ Recommended      │ Requires discipline     │
│                          │                  │ and continuous learning │
└──────────────────────────┴──────────────────┴─────────────────────────┘
```

In all cases, the developer's primary output is shifting toward intent expressed as language. But intent without engineering discipline — whether expressed as vibe prompts or heavyweight specs — produces fragile systems. The code still matters. Reading it still matters.

## Prompt Requests (PRs Reimagined)

If the prompt is the new unit of work, then a "Pull Request" should really be a "Prompt Request" — a proposal of intent, not a proposal of code. The traditional PR model assumes a human wrote code that another human reviews line by line. In an agent world, the code is generated and the real question is whether the intent was correct.

```
┌───────────────────────────────────────────────────────────────┐
│           Pull Request vs Prompt Request                       │
│                                                               │
│  Pull Request (Old)          Prompt Request (New)             │
│  ─────────────────           ────────────────────             │
│  Review code diffs           Review intent/spec               │
│  Human wrote the code        Agent wrote the code             │
│  Line-by-line review         Outcome-based validation         │
│  Manual test verification    Agent runs tests autonomously    │
│  Reviewer checks style       Agent follows style rules        │
│  Days to merge               Minutes to validate              │
│                                                               │
│  The bottleneck moved from WRITING code to EXPRESSING intent  │
└───────────────────────────────────────────────────────────────┘
```

Nat Friedman's new platform "Entire" ($60M seed, $300M valuation) reimagines Git as a unified database for code, intent, constraints, and reasoning. When an AI agent generates a commit, the CLI captures the session details (the prompt, the reasoning, the constraints) and pushes them alongside the code. This is the Prompt Request model in practice.

## What is it?

GitHub has become a single point of failure for the entire AI-assisted development ecosystem. AI coding agents like Claude Code, Codex CLI, and Cursor depend entirely on GitHub for pushing commits, opening PRs, running CI/CD via Actions, and fetching issue context. When GitHub goes down, the entire agentic workflow collapses. The February 9, 2026 outage exposed this fragility and raised fundamental questions about whether centralized platforms can serve as the backbone for autonomous agent workflows.

## The February 2026 Outage

```
┌──────────────────────────────────────────────────────────────────┐
│                    Timeline (Feb 9, 2026)                        │
│                                                                  │
│  15:54 UTC ──► Performance issues begin                         │
│       │                                                          │
│  16:xx UTC ──► Escalation to widespread degradation             │
│       │        - Notifications down                              │
│       │        - Web interface degraded                          │
│       │        - Pull request functionality broken               │
│       │                                                          │
│  ~18:24 UTC ──► Recovery (~2.5 hours total)                     │
│                                                                  │
│  Root cause: migration from legacy data centers to Azure         │
│  Traffic split between old and new systems caused bugs           │
└──────────────────────────────────────────────────────────────────┘
```

## What Broke for AI Agents

```
┌──────────────────────────┬───────────────────────────────────────┐
│ Agent Capability         │ Impact During Outage                  │
├──────────────────────────┼───────────────────────────────────────┤
│ Code pushing             │ Work stuck locally, agents stalled    │
├──────────────────────────┼───────────────────────────────────────┤
│ PR creation              │ Stopped entirely                      │
├──────────────────────────┼───────────────────────────────────────┤
│ CI/CD pipelines          │ GitHub Actions halted                 │
├──────────────────────────┼───────────────────────────────────────┤
│ Dependency fetching      │ GitHub-hosted packages unavailable    │
├──────────────────────────┼───────────────────────────────────────┤
│ Multi-agent collaboration│ Collapsed (shared repo = shared fate) │
├──────────────────────────┼───────────────────────────────────────┤
│ Issue context fetching   │ Agents lost access to requirements    │
└──────────────────────────┴───────────────────────────────────────┘
```

As one developer put it: "I need my code to pass CI, and get reviewed, so I can move on, otherwise the PRs just keep piling."

## The Deeper Problem

Git was designed to be decentralized. GitHub made it centralized. AI agents made the centralization a critical dependency.

```
┌───────────────────────────────────────────────────────────────┐
│                    Dependency Chain                            │
│                                                               │
│  AI Agent ──► GitHub API ──► GitHub Actions ──► GitHub Pkgs   │
│     │              │              │                   │        │
│     └──────────────┴──────────────┴───────────────────┘       │
│                                                               │
│              Single point of failure                          │
│              All eggs in one basket                           │
└───────────────────────────────────────────────────────────────┘
```

## The AI Slop Tsunami

GitHub is drowning in low-quality AI-generated pull requests. The platform that promoted Copilot now faces a flood of AI slop in open-source repositories. Only 1 in 10 AI-generated PRs meets quality standards. The other 9 waste maintainer time.

```
┌──────────────────────────────────────────────────────────────────┐
│                  AI PR Scale (Jan 2026 Dataset)                   │
│                                                                  │
│  Agentic PRs:  932,791  across 116,211 repositories             │
│  Human PRs:      6,618  (in same dataset for comparison)         │
│                                                                  │
│  Legitimate AI PRs:  ~10%                                        │
│  AI Slop:            ~90%  (abandoned, low-quality, off-target)  │
└──────────────────────────────────────────────────────────────────┘
```

GitHub's response in February 2026:
- Shipped settings to disable PRs entirely or restrict to collaborators only
- Evaluating AI triage tools and attribution signals for AI-generated content
- Community discussion on granular permissions and PR deletion

Daniel Stenberg shut down cURL's bug bounty program after 7 years because the AI slop confirmation rate dropped below 5%. His words: "The never-ending slop submissions take a serious mental toll."

GitHub also killed Copilot's unsolicited PR "tips" feature after developer backlash in March 2026.

## Multi-Agent Teams (2026 Shift)

In February 2026, every major AI coding platform shipped multi-agent capabilities within the same two-week window. The leap went from single-agent assistance to coordinated squads of AI agents that divide complex projects into parallel workstreams.

```
┌───────────────────────────────────────────────────────────────┐
│              Single Agent vs Multi-Agent (2026)                │
│                                                               │
│  2025: Human ──► 1 Agent ──► Code ──► PR                     │
│                                                               │
│  2026: Human ──► Orchestrator Agent                           │
│                    ├──► Agent A (backend)  ──►  ┐             │
│                    ├──► Agent B (frontend) ──►  ├──► Ship     │
│                    ├──► Agent C (tests)    ──►  │             │
│                    └──► Agent D (infra)    ──►  ┘             │
│                                                               │
│  This makes GitHub's single-PR model even more inadequate     │
│  Multi-agent work needs multi-branch, multi-PR orchestration  │
└───────────────────────────────────────────────────────────────┘
```

## AI Code Quality Problem

Research in 2026 shows AI-generated code has real quality issues:

```
┌───────────────────────────────────┬──────────────────────────┐
│ Metric                           │ Finding                   │
├───────────────────────────────────┼──────────────────────────┤
│ Bug rate vs humans               │ AI creates 1.7x more bugs│
├───────────────────────────────────┼──────────────────────────┤
│ Readability issues               │ AI has 3x more issues    │
├───────────────────────────────────┼──────────────────────────┤
│ Common errors                    │ ModuleNotFoundError,      │
│                                   │ TypeError, OSError        │
├───────────────────────────────────┼──────────────────────────┤
│ Developer AI tool adoption       │ ~85% by end of 2025      │
├───────────────────────────────────┼──────────────────────────┤
│ 2026 focus shift                 │ Productivity ──► Quality  │
└───────────────────────────────────┴──────────────────────────┘
```

## Ex-GitHub CEO's Move: Entire

Nat Friedman (ex-GitHub CEO) launched "Entire" — a developer platform built from scratch for AI agent collaboration. $60M seed round at $300M valuation. The core argument: traditional tools like issues, pull requests, and even Git itself need an overhaul for the agentic era.

```
┌───────────────────────────────────────────────────────────────┐
│                    Entire Platform                             │
│                                                               │
│  Git reimagined as a unified database for:                    │
│    - Code                                                     │
│    - Intent (the prompt that generated the code)              │
│    - Constraints (rules the agent followed)                   │
│    - Reasoning (why the agent made specific decisions)        │
│                                                               │
│  When agent commits ──► CLI captures session details          │
│                    ──► Pushes to dedicated branch              │
│                    ──► Intent travels with the code            │
│                                                               │
│  Integrates with: Claude Code, Gemini CLI                     │
│  Planned: Codex, Copilot CLI                                  │
│                                                               │
│  Addressable market: $15B dev tools ──► $1.3T software labor  │
└───────────────────────────────────────────────────────────────┘
```

This is the clearest signal that even GitHub insiders see the current model as dead for the agentic future. The platform that GitHub built is not the platform that agents need.

## What Needs to Change

```
┌────────────────────────────────┬─────────────────────────────────────┐
│ Current State                  │ What Should Exist                   │
├────────────────────────────────┼─────────────────────────────────────┤
│ Single remote (GitHub)         │ Multi-remote with automatic failover│
├────────────────────────────────┼─────────────────────────────────────┤
│ GitHub Actions only            │ Decoupled CI (Buildkite, Jenkins)   │
├────────────────────────────────┼─────────────────────────────────────┤
│ GitHub-hosted packages         │ Local caching via Artifactory       │
├────────────────────────────────┼─────────────────────────────────────┤
│ Agent assumes GitHub is up     │ Agent works offline-first           │
├────────────────────────────────┼─────────────────────────────────────┤
│ PR-centric workflow            │ Local validation + async push       │
├────────────────────────────────┼─────────────────────────────────────┤
│ GitHub as identity provider    │ Decoupled auth (SSO, federation)    │
└────────────────────────────────┴─────────────────────────────────────┘
```

## Platform Reliability

```
┌──────────────┬─────────────┬──────────────────────────────────┐
│ Platform     │ SLA Target  │ Notes                            │
├──────────────┼─────────────┼──────────────────────────────────┤
│ GitHub       │ 99.9%       │ Azure migration causing issues   │
├──────────────┼─────────────┼──────────────────────────────────┤
│ GitLab       │ 99.95%      │ Higher SLA target                │
├──────────────┼─────────────┼──────────────────────────────────┤
│ Bitbucket    │ -           │ Fewer headline incidents         │
└──────────────┴─────────────┴──────────────────────────────────┘
```

## What This Means

GitHub is not literally dying, but its role is being questioned. The PR-centric, human-review workflow that GitHub was built for is misaligned with an agent-driven world where code is generated, tested, and shipped autonomously. The future likely involves either GitHub evolving into an agent-native platform or new platforms built from scratch for agent workflows replacing it.

## Links

- GitHub Down Feb 2026: https://serenitiesai.com/articles/github-down-ai-coding-tools-dependency-2026
- AI Agents Fail at GitHub Issues (Research): https://arxiv.org/pdf/2503.12374
- Stack Overflow on AI Bugs: https://stackoverflow.blog/2026/01/28/are-bugs-and-incidents-inevitable-with-ai-coding-agents/
- Ex-GitHub CEO New Platform (HN): https://news.ycombinator.com/item?id=46961345
- GitHub Kill Switch for PRs (AI Slop): https://www.theregister.com/2026/02/03/github_kill_switch_pull_requests_ai/
- GitHub Copilot PR Tips Backlash: https://www.theregister.com/2026/03/30/github_copilot_ads_pull_requests/
- How AI Agents Modify Code (932K PRs Study): https://arxiv.org/html/2601.17581
- Failed Agentic PRs Study: https://arxiv.org/html/2601.15195
- Entire Platform (Nat Friedman $60M): https://startupnews.fyi/2026/02/11/former-github-ceo-60m-seed-devtools/
- Multi-Agent Teams 2026: https://aiautomationglobal.com/blog/agentic-coding-revolution-multi-agent-teams-2026
- Spec-Driven Development + GitHub Spec Kit: https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- GitHub Low-Quality Contributions Discussion: https://github.com/orgs/community/discussions/185387
- Vibe Coding (Prompt-Iterative): https://dasroot.net/posts/2026/04/vibe-coding-ai-devops-2026/
- Vibe Coding Critique: https://diegopacheco.github.io/The-Art-of-Sense-A-Philosophy-of-Modern-AI/chapter-1/VIBE_CODING.html
- SDD Critique: https://diegopacheco.github.io/The-Art-of-Sense-A-Philosophy-of-Modern-AI/chapter-4/SDD.html
- Microsoft Shaking Up GitHub for AI Battle: https://www.itpro.com/software/development/microsoft-github-reshuffle-ai-coding-anthropic-cursor
