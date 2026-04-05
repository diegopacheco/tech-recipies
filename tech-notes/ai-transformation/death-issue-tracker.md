# Death of Issue Tracking

## What is it?

In March 2026, Linear CEO Karri Saarinen declared that "issue tracking is dead." The argument is that traditional ticket-based systems were built for human-to-human handoffs, but AI agents don't need tickets — they need context. Static issue trackers institutionalize idle time by forcing AI to operate within human-centric constraints. The shift is from systems built for handoffs to systems centered on context and agents.

## Why Issue Tracking is Dying

```
┌────────────────────────────────────────────────────────────────────┐
│                  Traditional Issue Tracking                        │
│                                                                    │
│  PM writes ticket ──► Dev reads ticket ──► Dev writes code         │
│       │                     │                    │                  │
│    Idle time            Interpretation        Handoff              │
│    (waiting)            (context loss)        (more waiting)       │
│                                                                    │
│  Problem: Every handoff loses context and introduces delay         │
└────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│                  Agent-Centric Workflow                            │
│                                                                    │
│  Context captured ──► Agent picks up ──► Agent writes code         │
│       │                     │                    │                  │
│    Real-time            Full context          Immediate            │
│    (no waiting)         (no interpretation)   (no handoff)         │
│                                                                    │
│  Issues still exist but function as context containers for agents  │
└────────────────────────────────────────────────────────────────────┘
```

## The Numbers (Linear, March 2026)

```
┌─────────────────────────────────────┬──────────────────────┐
│ Metric                              │ Value                │
├─────────────────────────────────────┼──────────────────────┤
│ Enterprise workspaces with agents   │ 75%                  │
├─────────────────────────────────────┼──────────────────────┤
│ Agent work volume growth (3 months) │ 5x                   │
├─────────────────────────────────────┼──────────────────────┤
│ New issues created by agents        │ 25%                  │
└─────────────────────────────────────┴──────────────────────┘
```

## Linear's New Vision

Linear repositioned itself from an issue tracker to a context-capture platform for agents. Issues remain as core items but serve a different purpose — they are context containers that agents consume, not handoff artifacts that humans pass around.

### Current Features (Beta)

- Chat interface in web, mobile, desktop, Slack, Teams, Zendesk
- Issue creation from discussions ("make issues based on the discussion here")
- Skills: reusable automated workflows saved for future use
- Automations: workflows triggered when issues are created

### Planned Features

- Coding agent to write and debug code
- Codebase question-answering
- Code diff presentation inside Linear

## What Actually Dies

```
┌─────────────────────────────┬──────────────────────────────────────┐
│ What Dies                   │ What Replaces It                     │
├─────────────────────────────┼──────────────────────────────────────┤
│ Manual ticket creation      │ Agents create issues from context    │
├─────────────────────────────┼──────────────────────────────────────┤
│ Human-to-human handoffs     │ Context flows directly to agents     │
├─────────────────────────────┼──────────────────────────────────────┤
│ Sprint planning rituals     │ Continuous agent-driven execution    │
├─────────────────────────────┼──────────────────────────────────────┤
│ Status update meetings      │ Real-time agent progress tracking    │
├─────────────────────────────┼──────────────────────────────────────┤
│ Estimation ceremonies       │ Agents just do the work              │
├─────────────────────────────┼──────────────────────────────────────┤
│ Ticket grooming             │ Agent-consumable context curation    │
└─────────────────────────────┴──────────────────────────────────────┘
```

## The Competitive Landscape

Linear is not alone. Basecamp and others are pivoting to "agent-first" positioning. The race is to become the central hub in an agent-driven future, but as The Register noted, "these products all aim to place themselves at the center of an agent-driven future, but they cannot all be in that position."

## PM Tools Were Designed for Humans, Not Agents

Traditional PM tools exist to compensate for human cognitive limits. Every ceremony maps to a human weakness:

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Ceremony                 │ Human Limitation It Compensates               │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Standups                 │ Memory loss overnight                         │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Sprint planning          │ Inability to estimate accurately              │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Retros                   │ Recurring human mistakes                      │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Confluence               │ Human context-holding limitations             │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Jira tickets             │ Breaking work into chunks humans can digest   │
└──────────────────────────┴───────────────────────────────────────────────┘
```

Agents do not need any of these structures. They maintain context, complete multi-phase work autonomously, and can be modified through specification rather than cultural retros. Removing human coordination bottlenecks reveals how much process manages people versus producing software.

### The Atlassian Signal

```
┌────────────────────────────────────────┬────────────────────────────────┐
│ Metric                                 │ Value                          │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian stock decline (12 months)    │ -70%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian revenue growth (same period) │ +23%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian cloud revenue milestone      │ >$1B (first time)              │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian layoffs (post-article)       │ 1,600 (10% workforce)          │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian stock reaction to layoffs    │ +4%                            │
├────────────────────────────────────────┼────────────────────────────────┤
│ Block (Dorsey) layoffs                 │ 40% workforce, stock +24%      │
├────────────────────────────────────────┼────────────────────────────────┤
│ S&P 500 software index single-day drop │ -3.1% (~$1T market value)      │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian Data Center sales end        │ March 30, 2026                 │
├────────────────────────────────────────┼────────────────────────────────┤
│ Data Center full EOL                   │ 2029                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Cloud migration cost increase          │ ~50% for Premium tier          │
└────────────────────────────────────────┴────────────────────────────────┘
```

The market is pricing in a future where AI agents eliminate the need for human Jira users. AI agents reduce headcount, fewer employees need fewer software seats, per-seat revenue shrinks. Companies selling collaboration tools are cutting their own user base — admission that the per-seat model shrinks from both directions.

The forced Data Center EOL coincides with the moment alternatives shift from "which other human PM tool?" to "do we need human-coordination-optimized PM at all?"

### Agent-Native PM Tools

PM tools for the agent era function as APIs agents consume, not dashboards humans observe.

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Tool             │ Approach                                            │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Linear           │ Expanded MCP server for Claude and Cursor.          │
│                  │ Supports initiatives, milestones, updates.          │
│                  │ "Workflows shared by humans and agents."            │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Flux             │ Agent-native Kanban. CLI-first, git-native,         │
│                  │ MCP-integrated. "flux ready" shows unblocked tasks  │
│                  │ sorted by priority, consumable by agents directly.  │
└──────────────────┴──────────────────────────────────────────────────────┘
```

### The Tooling Arc

Developer tooling follows a consistent pattern: manual process -> tool managing process -> tool automating process -> process disappears entirely. Version control went from manual backups to CVS to Git to agents autonomously committing and branching. Testing went from manual QA to test frameworks to CI/CD to agents writing and fixing tests. Project management is entering the automation phase now.

### What This Does Not Solve

- Agents hallucinate, miss edge cases, introduce security vulnerabilities
- Bad specifications execute as quickly as good ones — someone still decides what to build
- Autonomous loops only work with clear acceptance criteria and review checkpoints
- Teams still establishing basic CI/CD will not leap to agent-native PM
- Agile principles (rapid iteration, working software over documentation) survive — the ceremony industrial complex does not

## Skepticism

- Security features for agents are not well documented beyond "operates within existing permissions"
- The 75% adoption stat is for enterprise workspaces with agents installed, not agents actively replacing human workflows
- Issue tracking was already evolving before AI — Kanban replaced Scrum rituals for many teams
- Complex projects still need human coordination that agents cannot replace
- "Issue tracking is dead" is partly marketing for Linear's pivot
- Agent-created issues can create noise and false positives at scale

## What This Means

The real insight is not that issue tracking dies completely, but that the ticket-as-handoff-artifact model is obsolete. In an agent world, the system of record shifts from "who should do this?" to "what context does an agent need to do this?" The tracker becomes an agent orchestration layer.

## Links

- Linear Next: https://linear.app/next
- The Register: https://www.theregister.com/2026/03/26/linear_agent/
- Hacker News Discussion: https://news.ycombinator.com/item?id=47507253
- Department of Product: https://departmentofproduct.substack.com/p/linear-says-issue-tracking-is-dead
- PM Tools Designed for Humans: https://paddo.dev/blog/your-pm-tool-was-designed-for-humans/
