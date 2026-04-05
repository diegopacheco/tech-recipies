# The Death of the SDLC

## What is it?

The traditional Software Development Lifecycle — Plan, Design, Build, Test, Review, Document, Deploy — is collapsing. These phases existed because iteration was expensive, context transfer between specialists was slow, and humans have cognitive limitations around context retention. AI agents that sustain multi-hour reasoning spans across the entire development workflow make phase boundaries irrelevant. The shift is from sequential pipeline with gates and handoffs to continuous flow with human checkpoints at judgment points. The phases were always just a way to organize work around human limitations. As those limitations shift, so does the organization.

## Why Phases Existed

```
┌───────────────────────────────────────────────────────────────┐
│              SDLC Phases Were Human Limitations                │
│                                                               │
│  Requirements → Design → Build → Test → Review → Deploy       │
│                                                               │
│  Each phase existed because:                                  │
│    - Context transfer between specialists cost weeks          │
│    - Code, tests, docs required massive human effort          │
│    - Cross-phase coordination demanded meetings               │
│    - Humans forget context between handoffs                   │
│    - Iteration cycles were weeks or months long               │
│                                                               │
│  Phase gates provided quality control because getting back    │
│  to a previous phase was expensive.                           │
│                                                               │
│  When iteration costs drop to seconds, phases become          │
│  friction, not safety.                                        │
└───────────────────────────────────────────────────────────────┘
```

## What Changed: Extended Agent Reasoning

METR research found leading models complete over 2 hours of continuous work with 50% confidence of correct answers. This went from 30 seconds a few years ago to hours. Anthropic's Claude Opus 4.6 has a 14.5-hour task completion horizon. Agents now sustain reasoning across the entire lifecycle simultaneously rather than handling isolated tasks.

```
┌───────────────────────────────────────────────────────────────┐
│              How Phases Blur Together                          │
│                                                               │
│  Planning + Building:                                         │
│    Agent reads specs, maps to code, identifies dependencies,  │
│    surfaces ambiguities — single pass, no handoff.            │
│                                                               │
│  Design + Implementation:                                     │
│    Agent scaffolds, generates boilerplate, translates mockups │
│    while concepts still evolve. No "design freeze."           │
│                                                               │
│  Building + Testing:                                          │
│    Tests written alongside implementation as integrated       │
│    workflow. No separate QA phase.                            │
│                                                               │
│  Review becomes continuous:                                   │
│    AI reviews all code before human review.                   │
│    Atlassian RovoDev 2026: 38.7% of AI review comments led   │
│    to additional code fixes.                                  │
│                                                               │
│  Documentation inline:                                        │
│    Updated concurrently with code changes rather than as      │
│    afterthought.                                              │
│                                                               │
│  The new cycle: Intent → Build → Observe → Repeat             │
��  No tickets, sprints, story points, separate QA phases,       │
│  or release trains.                                           │
└───────────────────────────────────────────────────────────────┘
```

## The DevOps Parallel

DevOps dissolved the Dev/Ops wall into continuous integration and deployment. The SDLC collapse is the same pattern applied to every remaining phase boundary. Planning, building, testing, reviewing, and deploying merge into a continuous agent-assisted flow with human oversight at judgment checkpoints.

## The Delegate / Review / Own Pattern

Across every phase, the same division of labor emerges:

```
┌──────────────────────────┬─────────────────────┬──────────────────────────┐
│ Phase                    │ Agent Does           │ Human Owns               │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Plan                     │ Feasibility, spec    │ Strategic decisions,     │
│                          │ reading, dependency  │ prioritization,          │
│                          │ mapping, difficulty  │ sequencing               │
│                          │ estimation           │                          │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Design                   │ Scaffolding,         │ Architecture patterns,   │
│                          │ boilerplate,         │ UX decisions, quality    │
│                          │ mockup translation   │ standards                │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Build                    │ Full implementation  │ Correctness, security,   │
│                          │ drafts (models, APIs,│ maintainability review   │
│                          │ UI, tests, docs)     │                          │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Test                     │ Test case generation │ Coverage alignment,      │
│                          │ from specs, edge     │ adversarial failure-mode │
│                          │ case surfacing       │ thinking                 │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Review                   │ Consistent review,   │ Merge decisions, arch    │
│                          │ cross-file tracing,  │ alignment, requirement   │
│                          │ code execution       │ verification             │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Document                 │ Summaries, deps,     │ Documentation strategy,  │
│                          │ system diagrams      │ customer-facing review   │
├──────────────────────────┼─────────────────────┼──────────────────────────┤
│ Deploy & Maintain        │ Log parsing, anomaly │ Validate diagnostics,    │
│                          │ surfacing, suspect   │ approve remediation,     │
│                          │ commits, hotfixes    │ handle novel incidents   │
└──────────────────────────┴─────────────────────┴──────────────────────────┘
```

## Always Have an Agent Running

Mitchell Hashimoto (HashiCorp co-founder, Ghostty creator) formalized the most practical workflow for the post-SDLC world: always have an agent actively working on something.

```
┌───────────────────────────────────────────────────────────────┐
│              The Hashimoto Workflow                            │
│                                                               │
│  "If I'm coding, I want an agent planning.                   │
│   If they're coding, I want to be reviewing.                  │
│   There should always be an agent doing something."           │
│                                                               │
│  Agent tasks are not always code:                             │
│    - Research on library options                              │
│    - Edge case analysis                                       │
│    - Deep thinking about potential gaps                       │
│    - Anything requiring 20+ min machine time but 60+ min     │
│      of human context-building                                │
│                                                               │
│  Before leaving desk: "What slow task could my agent do       │
│  while I'm gone?"                                             │
│                                                               │
│  Desktop notifications disabled. Agent checked on human       │
│  schedule, not vice versa. Background process, not pair       │
│  programmer.                                                  │
│                                                               │
│  Competition mode on hard problems:                           │
│    Two agents (Claude vs Codex) on same task simultaneously.  │
│    Different models have different blind spots.               │
│    Pick the better output. Maximum two — more creates         │
│    unsustainable cleanup overhead.                            │
│    Self-description: "mayor of a small town, not operator     │
│    of a factory floor"                                        │
└───────────────────────────────────────────────────────────────┘
```

### The Adoption Curve Nobody Talks About

Hashimoto initially tried Claude Code, found it unimpressive, abandoned it. Returned because "I started to get scared that I would be behind." Deliberately doubled his workload — every task done both manually and through AI to compare results. Slower for months. But discovered fundamental patterns organically: planning improves output, test harnesses increase reliability, CLAUDE.md prevents repeated mistakes. Senior engineers who gain maximum AI value are not true believers — they are skeptics honest enough to admit when tools work.

## The 19-Agent Trap

Complex multi-agent frameworks like BMAD (19 specialized agents) and SpecKit (waterfall phase workflows) tried to formalize the SDLC in agent form. They are the wrong answer.

```
┌───────────────────────────────────────────────────────────────┐
│              Why SDLC-in-Agent-Form Fails                     │
│                                                               │
│  BMAD architecture mirrors the org chart:                     │
│    Analyst → PM → Architect → Developer → QA                  │
│                                                               │
│  Problems:                                                    │
│    - Managing 19 agents recreates human coordination          │
│      overhead that AI should eliminate, not replicate          │
│    - Sequential handoffs between agents lose context          │
│    - Phase gates create friction, not quality                 │
│    - Agent personas create conflicts with user intent         │
│    - Framework instructions dilute signal with competing      │
│      directives                                               │
│    - Context window consumed by scaffolding instead of        │
│      project context                                          │
│    - Optimizes for explainability over effectiveness          │
│                                                               │
│  The psychological driver: complex scaffolding appeals to     │
│  stakeholders who need to explain AI in familiar org terms.   │
│  This is cargo cult SDLC.                                     │
│                                                               │
│  Research shows larger context drops output quality.          │
│  BMAD consumes orders of magnitude more tokens than needed.   │
│  Boris Cherny's CLAUDE.md: ~2,000 tokens. BMAD: 10x+ more.  │
└───────────────────────────────────────────────────────────────┘
```

### What Actually Works (The Boring Approach)

Boris Cherny (Claude Code creator) uses a surprisingly vanilla setup:

```
┌───────────────────────────────────────────────────────────────┐
│              The Boris Pattern                                 │
│                                                               │
│  1. Plan Mode First: most sessions start with plan mode,     │
│     back-and-forth refinement before execution                │
│                                                               │
│  2. Focused CLAUDE.md: short, updated when errors occur.     │
│     Functions as "do not repeat" ledger, not comprehensive    │
│     specification.                                            │
│                                                               │
│  3. Verification Loops: tests, browser, type checker — give  │
│     AI mechanisms to verify its own work.                     │
│                                                               │
│  4. Parallel Sessions: five simultaneous Claude instances     │
│     generate more throughput than single orchestrated agent.  │
│                                                               │
│  No 19-agent orchestration. No multi-phase workflows.        │
│  No external coordination layers.                             │
│                                                               │
│  "My setup might be surprisingly vanilla! Claude Code works   │
│   great out of the box."                                      │
└───────────────────────────────────────────────────────────────┘
```

## Gas Town — The Other Kind of Multi-Agent

Steve Yegge's Gas Town represents a fundamentally different approach from the 19-agent trap. Not a refutation of the BMAD critique — a different paradigm solving different problems.

```
┌───────────────────────────────────────────────────────────────┐
│              Two Architectures Compared                        │
│                                                               │
│  BMAD/SpecKit:                                                │
│    - Simulates org hierarchy through SDLC personas            │
│    - Sequential workflow: Analyst → PM → Architect → Dev → QA │
│    - Phase gates as quality control                           │
│    - Context pollution from competing role prompts            │
│    - Optimizes for explainability                             │
│                                                               │
│  Gas Town:                                                    │
│    - Operational roles, not SDLC simulation                   │
│    - Parallel execution across isolated environments          │
│    - External memory (Beads framework) not context windows    │
│    - Git-based state: GUPP (Git Up, Pull, Push)               │
│    - Mayor orchestrates, Polecats execute, Witness and        │
│      Deacon monitor health                                    │
│    - Each agent gets isolated Git worktree                    │
│                                                               │
│  Key difference: Gas Town avoids the "confused phase"         │
│  problem where agents debate whether they are in              │
│  "requirements phase" or "implementation phase."              │
└───────────────────────────────────────────────────────────────┘
```

### Gas Town Critique — The Chaos Reality

Gas Town is architecturally interesting but operationally chaotic. It is 100% vibecoded — Yegge has never read the code. Maggie Appleton called this "irresponsible and daft" and noted "should developers still look at code?" is becoming one of the most divisive debates.

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Problem                  │ Detail                                        │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Token burn               │ Peak $100/hour. Yegge burned through three    │
│                          │ $200/mo Claude Pro Max plans, maxing weekly   │
│                          │ limits on each.                               │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Murderous Deacon         │ The Deacon agent went rogue — cleaning up     │
│                          │ "stale" workers that were not stale, killing  │
│                          │ entire crews mid-task. Yegge: "Apologies to   │
│                          │ everyone being bitten by the murderous        │
│                          │ rampaging Deacon." Safety upgraded from       │
│                          │ "randomly rips user's face off" to "randomly  │
│                          │ kicks user in groin."                         │
├──────────────────────────┼───────────────────────────────────────────────┤
│ DoltHub production       │ Auto-merged failing tests into main. Five     │
│                          │ force pushes to main required for recovery.   │
│                          │ Requires constant human steering.             │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Agent conflict           │ When multiple agents disagree on merge        │
│                          │ strategies or code reviews, no principled     │
│                          │ resolution. Mayor breaks ties implicitly.     │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Observability            │ Monitoring worker state across tabs is        │
│                          │ frenetic plate-spinning. Human language and   │
│                          │ tmux injection problematic for coordination.  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Design bottleneck        │ System churns through implementation so fast  │
│                          │ that design and planning cannot keep up.      │
│                          │ Humans must "feed the engine" constantly.     │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Failing CI               │ Gas Town's own repository had failing CI.     │
│                          │ Hard to trust the future of development is    │
│                          │ built in a repo with broken builds.           │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Security                 │ YOLO mode needs hardened environments.        │
│                          │ Defense in depth required for any org to      │
│                          │ leverage coding agents safely.                │
└──────────────────────────┴───────────────────────────────────────────────┘
```

### The Verdict on Gas Town

Architecturally sound — correct primitives (external memory, parallel execution, Git coordination). Temporally premature — chaotic real-world results after weeks of development. The problems are engineering challenges, not architectural mistakes. For most developers, the Boris pattern (Plan Mode + focused CLAUDE.md + verification loops + parallel sessions) handles requirements without orchestration complexity. Gas Town is appropriate only for massive parallelization across large codebases at scale.

## Git Might Not Survive This

Mitchell Hashimoto argues Git in its current form may not endure the agent era. He bases this on advising a stealth company operating at agent scale.

```
┌───────────────────────────────────────────────────────────────┐
│              Why Git Breaks Under Agent Load                   │
│                                                               │
│  Merge Queue Saturation:                                      │
│    Human churn was manageable. Agent churn = 10-100x more.    │
│    Every push triggers rebases. Every rebase conflicts with   │
│    other agent pushes. Queue depth becomes unsustainable.     │
│                                                               │
│  Branch Information Loss:                                     │
│    Branches capture successful paths only. When agents        │
│    experiment and abandon approaches, negative signals        │
│    vanish. That lost data is "relatively important."          │
│                                                               │
│  Monorepo Scale:                                              │
│    Companies pursuing agent-heavy development hit real        │
│    performance and workflow problems. Not theoretical.        │
│                                                               │
│  The Gmail Moment:                                            │
│    Email required careful curation until Gmail gave unlimited  │
│    storage with search. Git still operates in curation mode:  │
│    save positives, discard negatives, prune branches.         │
│    Agent workflows need: save everything, build discovery.    │
│                                                               │
│  "This is the first time in 12-15 years that anyone is       │
│   even asking that question without laughing."                │
│                                                               │
│  The problem is not performance. GitHub's forge model         │
│  (branches, PRs, merge queues) was designed for human         │
│  cadence. Agent cadence breaks workflow assumptions before    │
│  performance limits hit.                                      │
└───────────────────────────────────────────────────────────────┘
```

## Infrastructure Under Stress

Everything was built for human-speed development and is now stress-tested by machine-speed development.

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Infrastructure           │ What Breaks                                   │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Editors                  │ Unprecedented mobility. Users switch          │
│                          │ constantly. Cursor reached valuation no       │
│                          │ pre-AI editor approached. Terminal            │
│                          │ renaissance.                                  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Forges (GitHub)          │ PR model, merge queues, branch model          ��
│                          │ designed for human cadence. Agent cadence     │
│                          │ overwhelms.                                   │
├──────────────────────────┼───────────────────────────────────────────────┤
│ CI/CD                    │ Pipelines designed for human-frequency        │
│                          │ commits. 10-100x more commits breaks          │
│                          │ assumptions.                                  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Testing                  │ Shifts from testing products to testing the   │
│                          │ development process itself. Harness           │
│                          │ engineering: each agent failure triggers      │
│                          │ tooling that catches it next time.            │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Version control (Git)    │ Most significant question mark. Everyone      │
│                          │ depends on it. Nobody questioned it for a     │
│                          │ decade. Now under existential pressure.       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Sandbox compute          │ Agents require isolated environments at       │
│                          │ scales Kubernetes was not designed for.       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Observability            │ Designed for human operators reviewing        │
│                          │ dashboards. Agent observability requires      │
│                          │ machine-readable health signals.              │
└──────────────────────────┴───────────────────────────────────────────────┘
```

## What Remains Distinctly Human

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Domain                   │ Why Agents Cannot Replace It                  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Strategic product vision │ Market selection, problem definition,         │
│                          │ customer value — requires taste and judgment  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Novel architecture       �� New abstractions, cross-cutting changes       │
│                          │ requiring deep system intuition               │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Ambiguous requirements   │ Resolution when specs lack clarity —          │
│                          │ requires understanding unstated context       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Ethical judgment          │ Data, privacy, impact decisions with moral   │
│                          │ weight                                        │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Final accountability     �� Engineers own shipped code regardless of      │
│                          │ who or what wrote it                          │
└──────────────────────────┴───────────────────────────────────────────────┘
```

The 90/90 rule persists. First 90% of code takes 90% of time. Remaining 10% — edge cases, integration issues, production hardening — takes the other 90%. Agents accelerate the first pass. The long tail remains.

## The Emerging Model

```
┌───────────────────────────────────────────────────────────────┐
│  Traditional SDLC:                                            │
│    Plan → Design → Build → Test → Review → Document → Deploy  │
│    Sequential pipeline. Gates. Handoffs. Weeks per cycle.     │
│                                                               │
│  Emerging model:                                              │
│    Continuous flow with human checkpoints at judgment points.  │
│    Agent sustains context across entire lifecycle.             │
│    Fewer handoffs, more checkpoints within continuous flow.    │
│    Unified context: single session spans plan → test.         ��
│    Role shift: specialists move from execution to review.     │
│                                                               │
│  The question shifts from:                                    │
│    "Which phase are we in?"                                   │
│  To:                                                          │
│    "What needs delegation, review, and human ownership?"      │
│                                                               │
│  Supporting tools that become less critical:                  │
│    - Storybook (agent generates + verifies in context)        │
│    - Jira (agents generate reports from prompts)              │
│    - Sprint ceremonies (continuous flow replaces sprints)     │
│    - Story points (agents just do the work)                   │
└───────────────────────────────────────────────────────────────┘
```

## What This Means

The SDLC is not evolving — it is collapsing. Phase boundaries existed because humans needed them: context gets lost in handoffs, specialists need scheduling, iteration was expensive. AI agents that sustain multi-hour reasoning spans across the entire lifecycle eliminate those constraints. The 19-agent trap (BMAD, SpecKit) tried to recreate SDLC phases in agent form and produced cargo cult process — familiar organizational structure with none of the effectiveness. Gas Town's parallel operational architecture is architecturally sound but operationally chaotic and premature. The boring approach works: Plan Mode, focused context, verification loops, parallel sessions. Mitchell Hashimoto's "always have an agent running" is the practical workflow — not maximizing productivity, but disciplined delegation of judgment-free tasks to machines. Git itself is under existential pressure from agent-speed development. The entire infrastructure stack — editors, forges, CI/CD, testing, version control, observability — was built for human pace and is now breaking under machine pace. Some will scale. Some will not. The organizations that thrive will be those that stop asking "which phase are we in?" and start asking "what requires human judgment and what does not?"

## Links

- SDLC Is Collapsing: https://paddo.dev/blog/sdlc-is-collapsing/
- Always Have an Agent Running: https://paddo.dev/blog/always-have-an-agent-running/
- The 19-Agent Trap: https://paddo.dev/blog/the-19-agent-trap/
- Gas Town Two Kinds of Multi-Agent: https://paddo.dev/blog/gastown-two-kinds-of-multi-agent/
- Gas Town Patterns and Bottlenecks (Maggie Appleton): https://maggieappleton.com/gastown
- Gas Town GitHub: https://github.com/steveyegge/gastown
- Gas Town Emergency Manual (Yegge): https://steve-yegge.medium.com/gas-town-emergency-user-manual-cf0e4556d74b
- Wrapping My Head Around Gas Town (Justin Abrahms): https://justin.abrah.ms/blog/2026-01-05-wrapping-my-head-around-gas-town.html
- DoltHub Day in Gas Town: https://www.dolthub.com/blog/2026-01-15-a-day-in-gas-town/
- Gas Town HN Discussion: https://news.ycombinator.com/item?id=46734302
- SDLC in AI Era 2026: https://www.groovyweb.co/blog/sdlc-ai-era-software-development-2026
- Agentic Development Lifecycle (EPAM): https://www.epam.com/insights/ai/blogs/agentic-development-lifecycle-explained
- SDLC Is Dead (Boris Tane): https://boristane.com/blog/the-software-development-lifecycle-is-dead/
- OpenAI Building AI-Native Engineering: https://openai.com/index/building-an-ai-native-engineering-team/
- METR Agent Task Completion Research: https://metr.org/blog/2025-03-19-measuring-ai-ability-to-complete-long-tasks/
- Hashimoto on Pragmatic Engineer Podcast: https://newsletter.pragmaticengineer.com/p/mitchell-hashimoto
- Gas Town and Where Software Is Going (Chainguard): https://www.chainguard.dev/unchained/gastown-and-where-software-is-going
