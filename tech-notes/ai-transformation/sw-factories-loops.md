# Software Factory Loops

## What is it?

A software factory is not a pipeline, it is a **loop**. Agents turn intent into shipped code, and something — tests, a reviewer, a human, production — pushes a signal back. What separates one factory from another is not the model or the tool; it is **where the feedback edges are drawn** and **what each edge is allowed to change**. A loop that only fixes code gets the same bug again next week. A loop that fixes the code *and* the harness that produced it gets a different, rarer bug.

By 2026 the teams publicly running factories — Stripe, Spotify, Uber, OpenAI, StrongDM, Every, HumanLayer — converged on a handful of loop shapes. They differ on three questions:

- **What gates production?** Nothing, tests, an agent reviewer, a human, or a holdout scenario suite.
- **What does a failure teach?** The code only, or the harness (rules, skills, tests, tools, docs).
- **Who closes the loop?** A human reading diffs, an agent reading a signal, or a cron job.

This note captures six common loops, from the naive one everybody starts with to the "dark" one almost nobody should run. See [[ai-software-factories]] for the factory concept, [[loop-engineering]] for the discipline of writing loops, and [[harness-engineering]] for the layer the good loops keep improving.

## The one idea every loop is judged by

Mitchell Hashimoto named it "Engineer the Harness", step 5 of his February 2026 post *My AI Adoption Journey*:

> *"Anytime you find an agent makes a mistake, you take the time to engineer a solution such that the agent never makes that mistake again."*

OpenAI's harness team (Ryan Lopopolo) phrased the same thing as a question they asked on every failure: *"what capability, context, or structure is missing?"* — never "try harder." Boris Cherny's most important Claude Code tip (Jan 2, 2026) is the other half: *"give Claude a way to verify its work. If Claude has that feedback loop, it will 2-3x the quality of the final result."*

So every loop below can be scored on two axes: **does it verify before production**, and **does it feed failures back into the harness**.

```
┌──────────────────────────┬───────────────────────────┬──────────────────────────┐
│                          │ fixes CODE only           │ fixes CODE + HARNESS     │
├──────────────────────────┼───────────────────────────┼──────────────────────────┤
│ no gate before prod      │ Loop 1  ship-and-fix      │ (rare, unstable)         │
├──────────────────────────┼───────────────────────────┼──────────────────────────┤
│ machine gates            │ Loop 4  ralph backpressure│ Loop 2  gated adversarial│
│ (tests, agent reviewers) │                           │ Loop 5  holdout scenarios│
├──────────────────────────┼───────────────────────────┼──────────────────────────┤
│ human gate               │ classic PR review         │ Loop 3  approval +       │
│                          │                           │         postmortem       │
├──────────────────────────┼───────────────────────────┼──────────────────────────┤
│ background, no ticket    │ —                         │ Loop 6  garbage collector│
└──────────────────────────┴───────────────────────────┴──────────────────────────┘
```

## Loop 1 — Ship and Fix (the reactive loop)

```
   plan ──→ implement ──→ prod
                            │
                            ↓
                      issue in prod
                            │
                            ↓
                           fix ──→ prod
```

**What it is.** The agent plans, writes the code, and it goes to production. Production *is* the test suite. When something breaks, a ticket, an alert, or a user report becomes the next prompt, the agent patches it, and the patch ships the same way. Nothing upstream changes.

**Where people run it.** This is where almost every team starts, usually by accident: an agent opens PRs, a human skims and merges, and the only real signal is the error tracker. Tooling has made the right-hand side of the loop very good. Sentry's **Seer Autofix** reads the stack trace, request payload, and breadcrumbs, and when confidence is high opens a PR with tests included. Factory wires Sentry into its Droids so an error fires, the Droid checks how many users are affected, replays the session, and proposes a fix. Codex CLI plus the Sentry MCP server collapses error-to-PR into one agent conversation.

**The case that ended it.** In July 2025 Dex Horthy's team at HumanLayer wired tickets, incidents, and product requests directly into an autonomous coding loop and let agents merge code no human read. Within three months the codebase had degraded so badly that a single production bug took weeks of manual debugging — no amount of prompting Opus 4.1 found the root cause, which turned out to be a primary key routed wrongly through the whole codebase. They shut it down and threw the system out. Horthy's talk on it is titled *"Harness Engineering is not Enough: Why Software Factories Fail."*

**Why it fails.**
- The fix edge only touches **code**, so the same class of bug keeps coming back in a new place.
- Every fix is written with no memory of why the last one was needed; entropy compounds.
- Users are the verification step. Mean time to detect is set by your customers.
- Fast-looking velocity hides comprehension debt until one bug costs more than the whole quarter saved.

**When it is acceptable.** Throwaway prototypes, internal tools with one user, or as the *fix arm* inside a better loop (Seer-style autofix is great when a gate still sits in front of prod).

## Loop 2 — Gated Adversarial Loop (verify, ship, then improve the harness)

```
   plan ──→ implement ──→ test ──fail──→ back to implement
                            │
                          pass
                            ↓
                   adversarial review ──reject──→ back to implement
                            │
                         approve
                            ↓
                     deploy to prod
                            │
                            ↓
                    improve harness ──→ next plan starts smarter
```

**What it is.** The maker is not allowed to grade itself. Deterministic verifiers (build, lint, types, tests) run first because they are cheap and never lie. Then a **separate reviewer** — a fresh-context agent, a different model, or a structured critic — attacks the diff before merge. After shipping, whatever friction the cycle hit (a flaky test, a missing tool, a rule the reviewer had to enforce by hand) is written back into the harness so the next run does not hit it.

**Who runs it.**

```
┌──────────────────┬────────────────────────────────────────────────────────────┐
│ Team             │ How the loop looks in practice                             │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Spotify (Honk)   │ Deterministic verifiers for format/build/test, then an     │
│                  │ LLM-as-judge fed the diff + the original prompt. Judge     │
│                  │ vetoes ~25% of changes; the agent course-corrects about    │
│                  │ half of those. 1,500+ PRs merged. Added because agents got │
│                  │ "ambitious" — refactoring or disabling flaky tests.        │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Stripe (Minions) │ Blueprints mix deterministic steps with agent loops on a   │
│                  │ 30M-line codebase; dev box → change → checks → CI → PR.    │
│                  │ 1,300+ PRs/week, no human-written code, still reviewed.    │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ OpenAI (harness) │ 3 engineers, ~1M LOC, ~1,500 PRs in 5 months, zero manual  │
│                  │ code. Agents review each other; every failure is answered  │
│                  │ with "what capability, context, or structure is missing?"  │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Every (Compound  │ Plan → work → review → compound. The compound step writes  │
│ Engineering)     │ what the cycle taught into files the next session reads.   │
│                  │ Kieran Klaassen runs Cora this way; open plugin of 35      │
│                  │ skills across 14 agent hosts.                              │
└──────────────────┴────────────────────────────────────────────────────────────┘
```

**Adversarial review, concretely.** The reviewer runs with no access to the maker's reasoning (fresh context), ideally on a different model family, read-only, with a checklist that includes *scope creep* — the failure Spotify's judge exists to catch. Research on the "Adversarial Review" protocol (arXiv 2608.18167) adds a third role, a critic that audits the review itself before the maker edits, and beat a five-agent baseline on LiveCodeBench with three agents.

**Why it works.** Two independent gates catch different failures: tests catch *wrong*, the adversarial reviewer catches *unasked-for* and *unmaintainable*. The harness-improvement step turns the reviewer's repeated objections into rules and checks, so review load falls over time instead of growing with output.

**How it fails.**
- The reviewer shares the maker's blind spots (same model, same context) and rubber-stamps.
- "Improve harness" becomes a junk drawer — AGENTS.md grows until the agent ignores it. The working rule from practitioners: every line must trace to a real observed failure; if nobody remembers the incident, delete the rule.
- Production feedback never reaches the harness because the improvement step only runs on what review saw.

## Loop 3 — Approval Gate with Postmortem (two feedback edges)

```
   plan ──→ implement ──→ test ──→ approved?
                                      │
                    ┌───── yes ───────┴──────── no ─────┐
                    ↓                                    ↓
                  prod                              postmortem
                    │                                    │
                    ↓                                    ↓
                prod bug? ── yes ──→ fix ──→ improve harness
                    │                                    │
                    no                                   ↓
                    ↓                          re-run from plan
                  done
```

**What it is.** A human (or a policy-bound approver) owns the ship decision. The key difference from Loop 2 is that **a denial is treated like an incident**. A rejected PR gets a short blameless postmortem — which rule was missing, which check would have caught it — and the answer goes into the harness *before* the work is retried. A production bug goes through the same door: fix the code, then fix the harness so the class of bug cannot recur. Two different failure signals, one learning sink.

**Why the postmortem on denial matters.** An empirical study of 654 rejected agent PRs across five coding agents (arXiv 2602.04226) found **67.9% had no clear reviewer feedback**. A separate study of 11,048 closed agentic PRs found 33.1% had no observable rationale at all. In a loop without a forced postmortem, the most valuable signal a reviewer produces — *why not* — is simply lost, and the agent whose session already ended never sees it.

**Who runs it.**
- **Uber** — more than 70% of PRs attributed to agents by August 2026, 3,600+ agent skills, 30K+ skill executions a day. Managed agents handle review, self-healing CI, on-call triage and bug debugging *"with human reviews/escalations."* Uber's Minion deliberately stops at a draft PR instead of pushing to CI, because hammering shared CI before a human confirms a feature works was wasteful.
- **Mitchell Hashimoto's** workflow is the individual version: every agent mistake becomes either an AGENTS.md line or a programmed tool (a screenshot script, a filtered test runner) so the mistake cannot happen again.
- **Canary-gated teams** automate half of the "approved?" box: deterministic SLO thresholds roll back clear failures instantly, an agent reasons about the ambiguous middle, and genuinely uncertain calls still go to a human.

**Why it works.** It is the only loop in this list where *both* a human "no" and a production bug permanently change the system. Approval rates rise and review time drops because reviewers stop repeating themselves.

**How it fails.**
- Human approval becomes the bottleneck; review bandwidth, not agent throughput, caps the factory.
- Postmortems turn into ceremony — a template filled in with no harness diff attached. A postmortem that does not end in a commit to rules, tests, or tools did not happen.
- Approvers rubber-stamp under volume, silently degrading this into Loop 1.

## Loop 4 — Ralph Backpressure Loop (one task, fresh context, forever)

```
   ┌──────────────────────────────────────────────────────────────┐
   │ while true:                                                  │
   │   read PROMPT.md + specs + fix_plan.md                       │
   │   pick the single most important item                        │
   │   implement it                                               │
   │   run build / tests / types  ──fail──→ loop again, same item │
   │   commit, update fix_plan.md                                 │
   │   exit  → fresh process, clean context                       │
   └──────────────────────────────────────────────────────────────┘
```

**What it is.** Geoffrey Huntley's technique from July 2025: a literal `while true` that pipes a prompt file into a coding agent. State lives on disk (`PROMPT.md`, specs, `fix_plan.md`), not in the conversation, so every iteration starts in a clean context window. Huntley named it after Ralph Wiggum because it is *"deterministically bad in an undeterministic world"* — any one iteration may be wrong, but failures are predictable and progress is durable.

**The core rule: backpressure beats direction.** Instead of telling the agent what to do in more detail, you make wrong output get rejected automatically — compilers, type checkers, tests, linters. And *one thing per loop*, only one.

**Who runs it.** Huntley used it to clone software and build a programming language; The Register covered it in January 2026, and Anthropic shipped an official Ralph Wiggum plugin for Claude Code. Dex Horthy's Research-Plan-Implement workflow borrows the same insight — compact state into a markdown artifact before the context leaves the "smart zone" (roughly the first ~100K tokens), then restart fresh.

**Why it works.** No trajectory poisoning, trivial to build, and it scales by throwing hours at a problem instead of attention.

**How it fails.**
- Without strong backpressure it is Loop 1 with a faster clock.
- It improves the *plan file*, not the harness; systemic mistakes repeat every iteration.
- No halting condition means burning tokens on an item that can never pass. Needs an iteration cap and a no-progress check.

## Loop 5 — Holdout Scenario Convergence (the dark factory loop)

```
   humans write spec + curate scenarios (hidden from coding agents)
                            │
                            ↓
   agents implement ──→ run scenarios against Digital Twin Universe
          ↑                                  │
          │                                  ↓
          └──── satisfaction too low ── score trajectories
                                             │
                                  satisfaction high enough
                                             ↓
                                           ship
```

**What it is.** StrongDM's AI team (Justin McCarthy, Jay Taylor, Navan Chauhan) runs a factory with three charter rules: *code must not be written by humans; code must not be reviewed by humans; if you haven't spent at least $1,000 on tokens today per human engineer, your software factory has room for improvement.* The gate is not a code review. It is a suite of **scenarios** — end-to-end user stories stored outside the codebase so coding agents never see them, the way a model never trains on its test set. An LLM judges each trajectory, and **satisfaction** is the fraction of observed trajectories across all scenarios that likely satisfy the user.

**The Digital Twin Universe.** Scenarios run against working behavioral clones of Okta, Jira, Slack, Google Docs, Google Drive and Google Sheets, mimicking their interfaces, edge cases and behaviors — thousands of scenarios per hour.

**Where the harness improvement lives.** Humans do not touch code; they touch the **spec and the scenario set**. A production escape means a missing scenario, and adding it is the harness fix. That is Loop 3's postmortem edge, moved from code review to evaluation. See [[eval-driven-development]] and [[ai-dark-factory]].

**Why it works (for them).** Holdout scenarios resist the agent gaming its own tests, and the twins make verification cheap enough to run constantly. It is Dan Shapiro's Level 5 — *"nobody reviews AI-produced code, ever."*

**How it fails.**
- The factory is exactly as good as the scenario set; anything not in a scenario is unverified.
- Twins drift from the real services they imitate.
- Nobody understands the code when the judge is wrong — the HumanLayer failure mode, with better tests. Stanford's CodeX asked the obvious question in its write-up title: *"Built by Agents, Tested by Agents, Trusted by Whom?"*

## Loop 6 — Garbage Collector (the background entropy loop)

```
   cron (nightly / weekly)
          │
          ↓
   scan repo for drift: golden-principle violations, stale docs,
   lint debt, needlessly optional props, architecture erosion
          │
          ↓
   pick ONE bounded issue ──→ fix ──→ verify ──→ small PR
                                                   │
                                                   ↓
                                     human reviews next morning
                                                   │
                                                   ↓
                                     update quality grade ──→ next run
```

**What it is.** A loop with no ticket and no customer. It exists because every other loop produces code faster than humans can keep it coherent. A scheduled agent picks exactly one deviation from the codebase's standards, fixes it, and opens a PR small enough to review with coffee.

**Who runs it.**
- **OpenAI's harness team** encoded "golden principles" (prefer shared utilities over hand-rolled helpers, validate data at boundaries instead of probing YOLO-style) and runs recurring background Codex tasks that scan for deviations, update quality grades, and open targeted refactoring PRs. They started with manual cleanup Fridays; it consumed **20% of engineering time** and still could not keep pace.
- **HumanLayer**, after shutting down its dark factory, runs a nightly GitHub Actions cron: fix one anti-pattern, commit, open one PR. The team wakes up to a codebase that is incrementally better.
- **Uber** managed agents and **Spotify Honk** migrations run the fleet-wide version of the same loop across thousands of components.

**Why it works.** It attacks entropy on a timer instead of waiting for it to become an incident, and each PR is a unit a human can still understand. It is the slow loop from [[slow-fast-loops]] applied to code health.

**How it fails.** Cosmetic churn that nobody reviews, or conflicts with feature work landing the same day. Keep it to one issue per run and ranked by real cost.

## Side by side

```
┌──────┬─────────────────────┬───────────────────┬───────────────────┬───────────┐
│ Loop │ Gate before prod    │ Failure teaches   │ Human role        │ Shapiro   │
├──────┼─────────────────────┼───────────────────┼───────────────────┼───────────┤
│ 1    │ none (users)        │ code only         │ writes tickets    │ 3 → chaos │
├──────┼─────────────────────┼───────────────────┼───────────────────┼───────────┤
│ 2    │ tests + adversarial │ code + harness    │ owns harness,     │ 4         │
│      │ agent reviewer      │ after each ship   │ spot-checks       │           │
├──────┼─────────────────────┼───────────────────┼───────────────────┼───────────┤
│ 3    │ tests + human       │ code + harness on │ approves, runs    │ 3 → 4     │
│      │ approval            │ denial AND on bug │ postmortems       │           │
├──────┼─────────────────────┼───────────────────┼───────────────────┼───────────┤
│ 4    │ backpressure (build,│ plan file only    │ writes specs,     │ 4         │
│      │ tests, types)       │                   │ watches the loop  │           │
├──────┼─────────────────────┼───────────────────┼───────────────────┼───────────┤
│ 5    │ holdout scenarios + │ spec + scenarios  │ curates scenarios │ 5         │
│      │ satisfaction score  │                   │ never reads code  │           │
├──────┼─────────────────────┼───────────────────┼───────────────────┼───────────┤
│ 6    │ tests + morning PR  │ quality grades +  │ reviews small PRs │ 4         │
│      │ review              │ golden principles │                   │           │
└──────┴─────────────────────┴───────────────────┴───────────────────┴───────────┘
```

```
┌──────┬──────────────────────────────┬─────────────────────────────────────────┐
│ Loop │ Named after / popularized by │ Public numbers                          │
├──────┼──────────────────────────────┼─────────────────────────────────────────┤
│ 1    │ everyone, by default         │ HumanLayer: codebase unusable in ~3 mo  │
├──────┼──────────────────────────────┼─────────────────────────────────────────┤
│ 2    │ Spotify Honk, Stripe Minions,│ Honk judge vetoes ~25%; Stripe 1,300+   │
│      │ OpenAI, Every                │ PRs/week; OpenAI ~1M LOC in 5 months    │
├──────┼──────────────────────────────┼─────────────────────────────────────────┤
│ 3    │ Mitchell Hashimoto, Uber     │ Uber >70% of PRs agent-attributed;      │
│      │                              │ 67.9% of rejected agent PRs lack reason │
├──────┼──────────────────────────────┼─────────────────────────────────────────┤
│ 4    │ Geoffrey Huntley (Ralph)     │ started July 2025; Anthropic plugin     │
├──────┼──────────────────────────────┼─────────────────────────────────────────┤
│ 5    │ StrongDM (McCarthy)          │ $1,000 tokens/engineer/day target       │
├──────┼──────────────────────────────┼─────────────────────────────────────────┤
│ 6    │ OpenAI, HumanLayer           │ manual cleanup ate 20% of eng time      │
└──────┴──────────────────────────────┴─────────────────────────────────────────┘
```

## How they compose

Real factories do not pick one. The mature pattern seen at Uber, OpenAI, and Stripe is a **stack of loops at different speeds**:

```
   ┌──────────────────────────────────────────────────────────────────┐
   │ INNER  (seconds–minutes)  Loop 4  backpressure inside one task   │
   │ MIDDLE (hours)            Loop 2 or 3  gate + learn per change   │
   │ OUTER  (nightly)          Loop 6  garbage collector              │
   │ PROD   (on signal)        Loop 1's fix arm  — alert → agent → PR │
   │                           but routed back through Loop 3's gate  │
   └──────────────────────────────────────────────────────────────────┘
```

The rule for composing them: **no edge may skip the harness.** Autofix from production is fine as long as its PR goes through the same gate and the same postmortem as anything else. The moment a signal can reach production without a gate, or a failure can be closed without changing the harness, the whole stack quietly becomes Loop 1.

## Choosing a loop

- **Starting out, small team, product with users** — Loop 3. Human approval is affordable at low volume, and the postmortem-on-denial habit builds the harness you will need later.
- **High PR volume, reviewers drowning** — Loop 2. Move the first "no" to an adversarial agent so humans only see changes that already survived a hostile read.
- **Well-specified greenfield, strong tests, long unattended runs** — Loop 4 inside Loop 2.
- **Codebase getting worse while velocity looks great** — add Loop 6 now, not after the incident.
- **Security or regulated software** — Loop 3 at minimum. StrongDM runs Loop 5 on security software, but it spent months building the twins and scenarios first; the scenarios *are* its review.
- **Never** run Loop 1 on anything you will have to debug yourself.

## What This Means

The shape of the loop matters more than the model in it. HumanLayer and StrongDM had access to the same frontier models in 2025; one threw its factory out after three months and the other ships security software with no human reading code. The difference was where the feedback edges went — HumanLayer's fixes went into code, StrongDM's went into scenarios.

The three loops people draw first map onto a progression. Loop 1 learns nothing. Loop 2 learns from what it shipped. Loop 3 learns from what it was *not allowed* to ship and from what broke — which is where most of the information is. Adding a postmortem to a denial is cheap, and the research on rejected agent PRs says it is exactly the signal teams are throwing away.

Two things are true across every loop in this note. First, **verification is the product** — Cherny's 2-3x, Spotify's 25% veto rate, StrongDM's satisfaction score are all the same bet. Second, **a harness that only grows eventually stops working**, so improving the harness includes deleting rules that no longer trace to a real failure. Build the loop so each failure makes the next one rarer, and put a garbage collector behind it, because the loop will produce code faster than anyone can keep it coherent. See [[harness-patterns]], [[ai-workflow-patterns]] and [[ai-native-engineering]].

## Links

- https://mitchellh.com/writing/my-ai-adoption-journey
- https://openai.com/index/harness-engineering/
- https://www.latent.space/p/harness-eng
- https://x.com/bcherny/status/2007179861115511237
- https://engineering.atspotify.com/2025/12/feedback-loops-background-coding-agents-part-3
- https://engineering.atspotify.com/2025/11/spotifys-background-coding-agent-part-1
- https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents
- https://stripe.dev/blog/minions-stripes-one-shot-end-to-end-coding-agents-part-2
- https://blog.bytebytego.com/p/how-stripes-minions-ship-1300-prs
- https://www.uber.com/us/en/blog/efficient-software-factory/
- https://newsletter.pragmaticengineer.com/p/how-uber-uses-ai-for-development
- https://every.to/guides/compound-engineering-gets-an-upgrade
- https://github.com/EveryInc/compound-engineering-plugin
- https://www.augmentcode.com/guides/adversarial-code-review
- https://arxiv.org/abs/2608.18167
- https://addyosmani.com/blog/agentic-code-review/
- https://arxiv.org/html/2602.04226
- https://arxiv.org/html/2605.22534
- https://ghuntley.com/ralph/
- https://github.com/ghuntley/how-to-ralph-wiggum
- https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md
- https://www.theregister.com/2026/01/27/ralph_wiggum_claude_loops/
- https://linearb.io/blog/dex-horthy-humanlayer-rpi-methodology-ralph-loop
- https://finance.biggo.com/news/15099f5634f5ab9a
- https://www.developersdigest.tech/blog/software-factories-fail-harness-engineering
- https://mastra.ai/podcasts/the-software-factory-dex-horthy-on-shipping-fast-without-ai-slop
- https://simonwillison.net/2026/Feb/7/software-factory/
- https://factory.strongdm.ai/
- https://law.stanford.edu/2026/02/08/built-by-agents-tested-by-agents-trusted-by-whom/
- https://simonwillison.net/2026/Jan/28/the-five-levels/
- https://www.danshapiro.com/blog/2026/01/the-five-levels-from-spicy-autocomplete-to-the-software-factory/
- https://blog.sentry.io/self-healing-software/
- https://sentry.io/cookbook/self-healing-workflow-seer/
- https://codex.danielvaughan.com/2026/05/09/codex-cli-sentry-mcp-production-error-triage-automated-bug-resolution/
- https://factory.ai/news/software-factory
- https://encore.dev/articles/ai-software-factory-architecture
- https://www.datacamp.com/tutorial/agent-harness-engineering
- https://devopsboys.com/blog/ai-agents-progressive-delivery-decision-making-2026
