# Slow Down to Speed Up

## What is it?

**Slow down to speed up** is the counter-intuitive thesis that, in the agentic-coding era, the way to ship faster is to spend *more* time up front — on understanding, design, edge cases, and verification — and *less* time generating raw code. The phrase is borrowed from a Navy SEAL training mantra ("slow is smooth, smooth is fast"): rushing produces mistakes you have to backtrack and fix, which is slower overall.

Gergely Orosz put the idea back in circulation with a June 2, 2026 Pragmatic Engineer piece, *"Ideas: slow down to speed up when working with AI agents."* He wrote it from **Craft Conference in Budapest**, where his keynote — also titled "Slow down to speed up" — shared a stage with **Kent Beck**, **Hillel Wayne** (*Logic for Programmers*), and **Titus Winters** (*Software Engineering at Google*). The setup is one line: *"Devs are generating twice as much code (or more) than just 6 months ago, which is a problem for quality, reliability, and tech debt. A rational fix is available for these, but who's acting rationally?"*

The fix is not "use AI less." It is to point the speed at the *slow* parts — let the agent burn hours building a throwaway prototype so a human can learn something in an afternoon instead of finding it out in production six weeks later. Speed in service of slowness.

> Note: the body of Orosz's post is paywalled. This brief is built from the public lede, section headers, and his stated tactics, then triangulated against the public research he's reacting to (METR, GitClear, DORA, Stack Overflow).

## The Numbers — why the panic is rational

```
┌──────────────────────────────────────────────────┬─────────────────────────┐
│ Signal                                            │ Value                   │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Code generated per dev vs. 6 months earlier       │ ~2x or more (Orosz)     │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ METR RCT: experienced devs WITH AI                │ 19% SLOWER              │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ METR: what those devs BELIEVED                     │ 20% faster              │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ METR: perception-vs-reality gap                    │ ~39 points              │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ METR sample                                        │ 16 devs · 246 tasks ·   │
│                                                    │ repos >1M LOC           │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ GitClear: code duplication 2021 → 2024            │ 8.3% → 12.3% (~4x clones)│
├──────────────────────────────────────────────────┼─────────────────────────┤
│ GitClear: refactoring share 2021 → 2024           │ 25% → <10% (~60% drop)  │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ GitClear: copy/paste vs. "moved" (reused) code    │ copy/paste now exceeds  │
│                                                    │ reuse (1st time ever)   │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Stack Overflow: trust in AI accuracy              │ 40% → 29% YoY           │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Stack Overflow: "almost right, but not quite"     │ 66% top frustration     │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Stack Overflow: shipped code they didn't fully    │ 76% (at least sometimes)│
│ understand                                         │                         │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Devs reporting ≥1 negative AI impact on tech debt │ 88%                     │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Ox Security: AI anti-patterns across 300 repos    │ present in 80–100%      │
└──────────────────────────────────────────────────┴─────────────────────────┘
```

The headline contradiction: AI makes the *typing* faster, but the **time saved in creation is re-spent on auditing, debugging, and verification** — and then some. The output looks correct ("almost right, but not quite"), so the cost lands later, as the dominant failure mode of the [[ai-slop-crisis|AI-slop]] era.

## The Rational Fix — speed pointed at the slow parts

Orosz's tactics all share one shape: use the agent's speed to *front-load learning and constraints*, before a single line of production code is committed.

```
┌──────────────────────────────┬────────────────────────────────────────────┐
│ Tactic                       │ What you spend the speed on                   │
├──────────────────────────────┼────────────────────────────────────────────┤
│ Throwaway prototypes         │ Have AI build a working prototype in hours,   │
│                              │ show stakeholders, confirm you understood the │
│                              │ problem — BEFORE investing weeks. Speed in    │
│                              │ service of slowness.                          │
├──────────────────────────────┼────────────────────────────────────────────┤
│ Generate edge cases first    │ Ask AI to enumerate edge cases and failure    │
│                              │ modes against the DESIGN. Far cheaper to fix  │
│                              │ in a diagram than in production.              │
├──────────────────────────────┼────────────────────────────────────────────┤
│ Tests as executable spec     │ Kent Beck's framing: TDD is a "superpower"    │
│                              │ with agents — an unambiguous, mechanically    │
│                              │ verifiable definition of "correct."           │
├──────────────────────────────┼────────────────────────────────────────────┤
│ Architecture & constraints   │ Give the agent the patterns, boundaries, and  │
│ up front                     │ testing expectations so it produces code      │
│                              │ coherent with the codebase, not a new dialect.│
├──────────────────────────────┼────────────────────────────────────────────┤
│ Know when to STOP investing  │ Quality is a set of tradeoffs with no         │
│                              │ universal rule. Over-dogmatic reviews,         │
│                              │ standardization, and coverage have diminishing │
│                              │ returns too.                                  │
└──────────────────────────────┴────────────────────────────────────────────┘
```

The last row is the part most people miss. Orosz is explicit that this is *not* a call for infinite rigor: you can over-invest in quality to the point of diminishing returns. Underinvesting hampers speed; being overly dogmatic about code reviews, standardization, and test coverage reduces effectiveness just as badly. The skill is locating the inflection point — which is exactly why he frames it as "who's acting rationally?"

## What the research says about the tradeoff

The strongest external validation comes from the **2025 DORA report** (*State of AI-assisted Software Development*). Its finding maps almost exactly onto Orosz's thesis:

```
┌───────────────────────────────────────────────────────────────────────────┐
│  Higher AI adoption  →  higher throughput  AND  higher INSTABILITY          │
│                      →  yet better code quality & product performance        │
│                                                                             │
│  The instability is NOT inherent. Teams in loosely-coupled architectures    │
│  with fast feedback loops GAIN. Teams in tightly-coupled systems with slow  │
│  processes get little or nothing. AI value is unlocked by the surrounding   │
│  technical practices and platform quality — not by the tool.                │
└───────────────────────────────────────────────────────────────────────────┘
```

In other words: AI accelerates code creation and exposes weaknesses downstream. Without strong automated testing, mature version control, and fast feedback, more change volume just means more breakage. The "slow down" investments — tests, feedback loops, loose coupling — are precisely what convert the throughput into durable speed. This is the same conclusion the [[harness-engineering|harness]] community reached from the other direction: the verification phase and constraint surface, not the model, decide whether an agent converges.

## Pros

- **It's the cure for [[ai-slop-crisis|AI slop]] without rejecting AI.** You keep the velocity but spend it on prototypes, edge cases, and tests instead of unreviewed merges.
- **Front-loaded learning is cheap.** A throwaway prototype costs hours; the wrong product costs weeks. The [[prototypes-over-prds|prototype-first]] loop, now at agent speed.
- **Tests and specs are leverage on agents specifically.** An executable spec is the one thing that makes a non-deterministic model mechanically verifiable — Beck's "superpower."
- **Backed by data, not vibes.** METR, GitClear, DORA, and Stack Overflow all point the same way: raw generation up, comprehension and structure down.
- **Names the off-ramp.** Unlike most "quality" sermons, it explicitly warns against over-investing — diminishing returns are real.

## Cons

- **Nobody feels slow voluntarily.** The METR perception gap (think +20%, actually −19%) means the people who'd benefit most are the ones most convinced they don't need to. "Who's acting rationally?" is rhetorical.
- **The payoff is deferred and invisible.** Skipped tech debt and avoided incidents don't show up on a velocity dashboard; the prototype you threw away looks like waste.
- **No universal threshold.** "Slow down — but not too much" is correct and nearly unactionable without judgment that's itself scarce.
- **Org incentives push the other way.** When leadership measures lines, PRs, or shipped features, front-loading design reads as not-shipping.
- **The source is partly paywalled.** Orosz's full argument and any framework he proposes sit behind a subscription; the public surface is the lede and tactics.

## Who Is Saying / Doing What

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Person / source   │ Position                                             │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Gergely Orosz     │ "Slow down to speed up." 2x+ code generation is a    │
│ (Pragmatic Eng.)  │ quality/reliability/tech-debt problem; the rational  │
│                   │ fix is front-loaded prototypes, edge cases, tests.   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Kent Beck         │ TDD is a "superpower" with AI agents — tests are an  │
│                   │ unambiguous, executable spec of "correct."           │
├──────────────────┼──────────────────────────────────────────────────────┤
│ METR              │ RCT: experienced devs 19% SLOWER with AI while       │
│                   │ believing they were 20% faster. 69% kept using it.   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ DORA 2025         │ AI raises throughput AND instability; the instability│
│ (Google Cloud)    │ is a function of weak foundations, not AI itself.    │
├──────────────────┼──────────────────────────────────────────────────────┤
│ GitClear          │ 211M lines analyzed: duplication ~4x, refactoring    │
│                   │ down ~60%, copy/paste now exceeds code reuse.        │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Stack Overflow    │ Trust in AI accuracy 40%→29%; top gripe is "almost   │
│ Dev Survey        │ right, but not quite" (66%).                         │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Sonar / Augment   │ "The great toil shift" and "the 80% problem": agents │
│                   │ ship fast and accrue hidden, unaudited tech debt.    │
└──────────────────┴──────────────────────────────────────────────────────┘
```

## What This Means

"Slow down to speed up" is the 2026 correction to the first wave of agentic coding, where the win condition was lines-of-code-per-hour. The data has caught up: more generation, less comprehension, less refactoring, more duplication, more instability, lower trust. The bottleneck never was typing — it was *understanding what to build and verifying it works*, and AI made the typing so cheap that the bottleneck is now the entire job.

The rational move is to spend the agent's speed where humans were always slow: a throwaway prototype to validate understanding, an edge-case sweep against the design, tests that pin down "correct," and architectural constraints handed to the model up front. This is the [[briefs-as-code|specs-up-front]] discipline and the [[harness-engineering|verification harness]] meeting in the middle — and it's the same lesson [[ai-native-engineering|AI-native engineering]] keeps relearning: the model supplies output, the human supplies judgment, and the only way to make output trustworthy at agent speed is to invest in the slow parts on purpose.

The open question is the one Orosz ends on. The fix is rational and well-evidenced. Acting on it means feeling slow, deferring visible wins, and throwing away work — against a perception gap that tells you you're already fast. Who's acting rationally?

## Links

- Ideas: slow down to speed up when working with AI agents (Gergely Orosz / The Pragmatic Engineer): https://newsletter.pragmaticengineer.com/p/ideas-slow-down-to-speed-up-when
- TDD, AI agents and coding with Kent Beck (The Pragmatic Engineer podcast): https://newsletter.pragmaticengineer.com/p/tdd-ai-agents-and-coding-with-kent
- Measuring the Impact of Early-2025 AI on Experienced Open-Source Developer Productivity (METR): https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
- AI Copilot Code Quality: 2025 Research (GitClear): https://www.gitclear.com/ai_assistant_code_quality_2025_research
- Announcing the 2025 DORA Report (Google Cloud): https://cloud.google.com/blog/products/ai-machine-learning/announcing-the-2025-dora-report
- Balancing AI tensions: Moving from AI adoption to effective SDLC use (DORA): https://dora.dev/insights/balancing-ai-tensions/
- Developers remain willing but reluctant to use AI: 2025 Developer Survey (Stack Overflow): https://stackoverflow.blog/2025/12/29/developers-remain-willing-but-reluctant-to-use-ai-the-2025-developer-survey-results-are-here/
- The great toil shift: How AI is redefining technical debt (Sonar): https://www.sonarsource.com/blog/how-ai-is-redefining-technical-debt
- The 80% Problem: Why AI Agents Ship Fast But Create Hidden Technical Debt (Augment Code): https://www.augmentcode.com/guides/the-80-percent-problem-ai-agents-technical-debt
- AI can 10x developers...in creating tech debt (Stack Overflow blog): https://stackoverflow.blog/2026/01/23/ai-can-10x-developers-in-creating-tech-debt/
- Software Engineering: Slow is Smooth, Smooth is Fast (DEV): https://dev.to/johnai/software-engineering-slow-is-smooth-smooth-is-fast-4gl1
- bliki: Technical Debt (Martin Fowler): https://martinfowler.com/bliki/TechnicalDebt.html
