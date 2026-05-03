# Briefs as Code

## What is it?

Briefs-as-code is a planning technique where strategic artifacts (delivery briefs, Gantt charts, exec summaries, roadmaps, architecture docs) live as structured markdown in a git repo. AI agents synthesize the scattered inputs (Miro boards, Linear projects, Confluence pages, meeting notes, running infrastructure) into one canonical location, and a generation step produces polished, print-ready HTML the executive actually reads.

The repo becomes the PM tool. The brief is an artifact, not a ceremony. One source, many consumers: executives read the polished HTML, engineers read the workstream README, and AI agents read everything and can write code, regenerate diagrams, or produce the next brief with full context.

## The Problem with Planning Artifacts

```
┌────────────────────────────────────────────────────────────────────┐
│              Where Strategic Planning Lives Today                  │
│                                                                    │
│   Miro boards ──┐                                                  │
│   Linear      ──┤                                                  │
│   Confluence  ──┼──► Stale, scattered, not diffable                │
│   PowerPoint  ──┤                                                  │
│   Someone's   ──┘                                                  │
│   head                                                             │
│                                                                    │
│   Exec reads stale version of one                                  │
│   Engineer reads stale version of another                          │
│   Nobody is looking at the same thing                              │
└────────────────────────────────────────────────────────────────────┘
```

The artifacts that matter most to leadership have the worst tooling. They are manually produced in PowerPoint by a PM who context-switches between six workstreams. They go stale the day after the steering committee meeting. They are not diffable, not version-controlled, and not connected to the source of truth.

Meanwhile, the source of truth (architecture docs, meeting notes, API specs, codebase, live infrastructure state) sits in git repos, Linear boards, and running clusters reachable from the CLI. The information exists. It is just not in a form anyone with three minutes can consume.

## The Repo Shape

```
docs/
  landscape.md          # what we have today
  north-star.md         # where we are heading
  roadmap.md            # what is in flight
  in-flight.html        # Gantt chart (standalone HTML)
  workstreams/
    platform/           # architecture, principles, diagrams, brief
    product-a/          # architecture, API specs, delivery plan
    product-b/          # architecture, meeting notes, brief
    ...
```

Each workstream has a README with structured planning content: current state, target, phases, risks, team. The deeper workstreams also have `architecture.md`, D2 diagrams, API specs, and meeting notes.

## The Six-Question Brief

The consumable output is `brief.html`: a hand-crafted, print-ready delivery document that answers six questions in one page.

```
┌───────────────────────────────────────────────────────────────────┐
│                       The Brief Template                          │
│                                                                   │
│  1. What are we doing and why                                     │
│  2. Where are we           (status bar: 4 metrics at a glance)    │
│  3. What are the tracks    (card grid with status pills)          │
│  4. When                   (timeline with milestones, deps)       │
│  5. What do we need        (numbered asks with owner tags)        │
│  6. What could go wrong    (risk cards with mitigations)          │
└───────────────────────────────────────────────────────────────────┘
```

Every brief shares a CSS template. Consistent typography (serif headings, sans body), consistent components (status bars, cards, timeline rows, risk grids, team cells). The exec sees the same visual language across every workstream — not because a designer was involved, but because the AI follows a template.

## How the Agents Fit

The AI agent is not writing strategy. It is doing the synthesis work humans skip because it is tedious.

```
┌─────────────────┬────────────────────────────────────────────────┐
│ Phase           │ What the agent does                            │
├─────────────────┼────────────────────────────────────────────────┤
│ Exploration     │ Read Miro boards, Linear, git repos, CLI       │
│                 │ tools to inspect running infra and current     │
│                 │ state                                          │
├─────────────────┼────────────────────────────────────────────────┤
│ Consolidation   │ Pull planning content from scattered sources   │
│                 │ into one canonical location, sanitize, track   │
│                 │ what moved so originals can be archived        │
├─────────────────┼────────────────────────────────────────────────┤
│ Generation      │ /brief platform reads README, architecture     │
│                 │ doc, principles → polished HTML following the  │
│                 │ template                                       │
├─────────────────┼────────────────────────────────────────────────┤
│ Maintenance     │ D2 source files compile to SVG via post-edit   │
│                 │ hooks; brief HTML regenerates when markdown    │
│                 │ changes; freshness checks skip unchanged       │
└─────────────────┴────────────────────────────────────────────────┘
```

The agent does in one session what would take a PM a week of context-gathering. The output is diffable: when priorities change, `git diff` shows exactly what shifted.

## One Source, Many Consumers

```
┌────────────────────────────────────────────────────────────────┐
│                  Three Consumers, One Source                    │
│                                                                 │
│   ┌──────────────┐    ┌──────────────┐    ┌────────────────┐   │
│   │  Executives  │    │  Engineers   │    │  AI Agents     │   │
│   │              │    │  & PMs       │    │                │   │
│   │  Read        │    │  Read        │    │  Read          │   │
│   │  brief.html  │    │  workstream  │    │  everything    │   │
│   │              │    │  README      │    │                │   │
│   │  Polished,   │    │  State,      │    │  Generate      │   │
│   │  one page,   │    │  phases,     │    │  briefs, write │   │
│   │  print-ready │    │  team,       │    │  code, render  │   │
│   │              │    │  decisions   │    │  diagrams      │   │
│   └──────────────┘    └──────────────┘    └────────────────┘   │
│                                                                 │
│              ▲              ▲                ▲                  │
│              └──────────────┴────────────────┘                  │
│                             │                                   │
│                  Structured markdown in git                     │
└────────────────────────────────────────────────────────────────┘
```

No context-loading ceremony. No separate summary doc for the bot. The plan IS the agent's context, and every future task starts with the agent already oriented.

> "The application logic of the software is being defined and edited as markdown, and the actual code that is generated by the agent is sort of becoming a low-level implementation detail." — Hartley Brody

This is the broader 2026 shift: `llms.txt`, `AGENTS.md` under the Linux Foundation, Cloudflare's Markdown for Agents. Briefs-as-code applies the same pattern one level up, at the planning layer.

## Capex vs Opex: Making Invisible Work Visible

A side effect of the format: tagging workstreams as capex (funded project, dedicated team, deadline) or opex (done alongside capex work, no budget, same people).

```
┌─────────────────────┬──────────────────────────────────────────┐
│ Capex (blue bars)   │ Opex (gold bars)                         │
├─────────────────────┼──────────────────────────────────────────┤
│ Funded project      │ Tech debt, resilience, migrations        │
│ Dedicated team      │ Performance, observability                │
│ Deadline            │ Done alongside capex work                │
│ Project sponsor     │ No budget protection                     │
│ Visible in roadmap  │ Same engineers' time                     │
│                     │ Cost invisible until the incident         │
└─────────────────────┴──────────────────────────────────────────┘
```

Opex work prevents the next incident but has no project sponsor. Making it visible in the same repo, with the same brief format, forces the conversation: "this work has no budget protection, and the risk of not doing it is the next production incident." The brief makes the cost visible before the incident.

## What This Replaces

```
┌─────────────────────────────────┬────────────────────────────────┐
│ Before                          │ After                          │
├─────────────────────────────────┼────────────────────────────────┤
│ Confluence pages going stale    │ Markdown in git, updates       │
│ because updating them is a chore │ naturally because architecture │
│                                 │ docs ARE the source            │
├─────────────────────────────────┼────────────────────────────────┤
│ PowerPoint decks for steering   │ One-page A4 brief, consistent  │
│ committees                      │ design system, regenerated     │
│                                 │ from current data              │
├─────────────────────────────────┼────────────────────────────────┤
│ Miro boards as system of record │ Miro is brainstorming input;   │
│                                 │ repo is system of record       │
├─────────────────────────────────┼────────────────────────────────┤
│ Verbal status updates in        │ The brief exists. Read it      │
│ meetings                        │ first; ask better questions    │
└─────────────────────────────────┴────────────────────────────────┘
```

This is not replacing Jira or Linear — those still track tickets. It is replacing the layer above: strategic planning artifacts that connect "what are we building" to "why does this matter."

This is Amazon's six-pager principle applied to platform planning, except the six-pager writes itself from the architecture docs you are already maintaining.

## What It Does Not Solve

The brief does not replace judgment. It does not decide priorities, resolve trade-offs, or tell you whether your timeline is realistic. It makes the inputs to those decisions visible and consistent. The human still decides. The agent just stops them from having to also be the typesetter.

## Try It

```
┌──────────────────────────────────────────────────────────────────┐
│                    Adoption Recipe                                │
│                                                                   │
│  1. One repo with docs/workstreams/ per initiative               │
│                                                                   │
│  2. Structured README per workstream:                             │
│     type (capex/opex), timeline, status, current state,           │
│     target, phases                                                │
│                                                                   │
│  3. Brief template:                                               │
│     shared CSS with status bars, cards, timelines, risks,         │
│     team grids                                                    │
│                                                                   │
│  4. AI skill (/brief):                                            │
│     reads workstream docs → generates brief.html                  │
│                                                                   │
│  5. D2 for diagrams:                                              │
│     text-based source committed alongside markdown,               │
│     compiled to SVG via D2 CLI                                    │
│                                                                   │
│  6. Post-edit hooks:                                              │
│     regenerate HTML exports and re-render D2 diagrams when        │
│     sources change                                                │
└──────────────────────────────────────────────────────────────────┘
```

The hard part is not the tooling. It is the discipline of keeping the markdown current. But that is easier than keeping a Confluence page current, because the markdown is in the same repo as the architecture decisions. You update the plan and the brief follows.

## Why This Matters Now

```
┌──────────────────────────────────────────────────────────────────┐
│                The 2026 Pattern                                   │
│                                                                   │
│   Code layer       │ AGENTS.md, llms.txt, Cloudflare Markdown    │
│                    │ for Agents                                   │
│   ─────────────────┼───────────────────────────────────────────   │
│   Planning layer   │ Briefs-as-code: same pattern, one level up  │
│   ─────────────────┼───────────────────────────────────────────   │
│   The shift        │ Markdown is the interface humans and agents │
│                    │ both consume; generated code and generated  │
│                    │ briefs are downstream artifacts             │
└──────────────────────────────────────────────────────────────────┘
```

Briefs-as-code is the tooling that lets a single person do both jobs: the engineer writes the architecture, the agent produces the exec brief. The repo is the PM tool. The brief is an artifact, not a ceremony. The tech leader stays in flow.

## Links

- Briefs as Code (original post by paddo): https://paddo.dev/blog/briefs-as-code/
- Your PM tool was designed for humans: https://paddo.dev
- Product engineering is the new superpower: https://paddo.dev
- Your AGENTS.md is already a liability: https://paddo.dev
- D2 diagram language: https://d2lang.com
- llms.txt proposal: https://llmstxt.org
- AGENTS.md (Linux Foundation): https://agents.md
- Cloudflare Markdown for Agents: https://blog.cloudflare.com
