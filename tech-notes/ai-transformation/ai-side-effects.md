# AI Side Effects

## What is it?

**AI side effects** are the costs of agentic engineering that never show up on the dashboard. The tools work. The PRs merge. The tests are green. Velocity is up and everybody can feel it. And underneath that, three separate meters are running: your judgement is quietly being replaced by the model's (**cognitive surrender**), your understanding of your own system is being spent down like a credit line (**cognitive debt**), and your attention — the one resource in the pipeline that cannot be cloned — is being taxed harder every time you spawn another agent (**orchestration tax**).

These are not three names for the same thing, and that distinction is the whole point of this note. Cognitive surrender is a **posture** — a moment-to-moment psychological act. Cognitive debt is the **balance sheet** — what accumulates after thousands of those moments. Orchestration tax is the **structural pressure** — the reason the posture keeps slipping in the first place. They form a loop: the tax makes surrender rational, surrender accrues debt, debt makes you slower at review, and being slower at review raises the tax. Addy Osmani, paddo and Dex Horthy have each been circling one corner of this triangle for a year; put their work side by side and the loop closes.

This is the human-side companion to [[ai-slop-crisis]] (what happens to the code) and [[ai-dark-factory]] (what happens when you remove the human entirely). Where [[slow-down-to-speed-up]] argues for deliberate pace and [[token-hard-vs-smart]] argues for deliberate spend, this note argues for **deliberate attention** — and names the three specific ways it leaks.

## The Numbers

```
┌──────────────────────────────────────────────────────┬───────────────────────────┐
│ Metric                                                │ Value                     │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Participants accepting AI's WRONG answer (Wharton)    │ 73–80% of trials          │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Confidence increase when AI available (same study)    │ +11.7% (half answers wrong)│
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Comprehension quiz: AI-assisted vs manual (Anthropic) │ 50% vs 67% (−17 pts)      │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Same study, delegation posture vs inquiry posture     │ <40% vs >65%              │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ LLM users unable to quote their own essay (MIT)       │ 83%                       │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Same, one session AFTER the tool was taken away       │ 78% (debt did not clear)  │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Experienced devs with AI tools, measured (METR)       │ 19% SLOWER                │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Same devs, self-estimated after the fact              │ 20% FASTER (39 pt gap)    │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Coordination overhead in naive multi-agent setups     │ 40–60% of execution time  │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Agent-authored PRs on GitHub, 6 months                │ 4M → 17M                  │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Merged code that is AI-authored (DX, 135K devs)       │ 22%                       │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Extra findings per AI-co-authored PR (CodeRabbit,13M) │ 1.7x (1.4x critical)      │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ AI changes needing prod debugging after QA (Lightrun) │ 43%                       │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Delivery stability change with AI adoption (DORA '25) │ −7.2%                     │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Dex Horthy's unreviewed "dark factory" survival time  │ 4 months                  │
├──────────────────────────────────────────────────────┼───────────────────────────┤
│ Re-onboarding cost onto that codebase afterwards      │ 3 weeks                   │
└──────────────────────────────────────────────────────┴───────────────────────────┘
```

The two most useful pairs in that table are the **39-point METR gap** (measured slower, felt faster) and the **78% after withdrawal** (the debt did not clear when the tool went away). Both say the same uncomfortable thing: the side effects are invisible from the inside, precisely to the person paying them.

---

# 1. Cognitive Surrender

## What it means

The term comes from Steven Shaw and Gideon Nave at Wharton — *"Thinking — Fast, Slow, and Artificial: How AI is Reshaping Human Reasoning and the Rise of Cognitive Surrender"* (2026). Addy Osmani brought it into the engineering conversation in May 2026. Their distinction is the part worth memorising:

```
┌────────────────────┬──────────────────────────────┬──────────────────────────────┐
│                    │ Cognitive OFFLOADING         │ Cognitive SURRENDER          │
├────────────────────┼──────────────────────────────┼──────────────────────────────┤
│ What you hand off  │ The HOW                      │ The HOW and the WHAT         │
├────────────────────┼──────────────────────────────┼──────────────────────────────┤
│ What you keep      │ The WHAT — the judgement of  │ Nothing. There is no         │
│                    │ whether the result is sane   │ independent view to compare  │
├────────────────────┼──────────────────────────────┼──────────────────────────────┤
│ Analogy            │ Calculator, GPS, compiler    │ Autopilot with nobody in     │
│                    │                              │ the left seat                │
├────────────────────┼──────────────────────────────┼──────────────────────────────┤
│ Failure signal     │ You override the tool when   │ You cannot override, because │
│                    │ it's wrong                   │ you never formed a view      │
├────────────────────┼──────────────────────────────┼──────────────────────────────┤
│ Feels like         │ Speed                        │ Speed                        │
└────────────────────┴──────────────────────────────┴──────────────────────────────┘
```

The last row is the trap. **Both feel identical from the inside.** Shaw and Nave ran three experiments across 1,372 participants and roughly 10,000 trials. Merely having AI available was enough to trigger surrender: participants accepted the AI's answer even when it was deliberately wrong, in 73–80% of those trials — and their **self-reported confidence went up 11.7%** while doing it. They were borrowing the model's confidence, which is always high, and wearing it as their own.

Shaw's own framing is deliberately non-alarmist and worth repeating verbatim:

> "Cognitive surrender is not the same as saying AI is bad or that using AI is irrational; in many settings, AI can improve judgment. The key issue is calibration: knowing when AI is helping you think and when it is quietly doing the thinking for you."

## Where it shows up in engineering

Nobody surrenders on the obvious stuff. You catch the hallucinated import. Surrender happens where the cost of forming an independent view feels disproportionate to the task:

```
┌─────────────────────┬────────────────────────────┬──────────────────────────────┐
│ Moment              │ What you did               │ What actually happened       │
├─────────────────────┼────────────────────────────┼──────────────────────────────┤
│ Reading the diff    │ Scanned a 600-line PR,     │ You ratified it. The         │
│                     │ names looked fine, tests   │ surrender was the ABSENCE of │
│                     │ green, approved            │ a decision                   │
├─────────────────────┼────────────────────────────┼──────────────────────────────┤
│ Debugging a scary   │ Pasted the stack trace,    │ You removed the symptom, not │
│ stack trace         │ got a fix, it worked       │ the bug. Your mental model   │
│                     │                            │ is now wrong somewhere you   │
│                     │                            │ can't point to              │
├─────────────────────┼────────────────────────────┼──────────────────────────────┤
│ Making a design     │ Asked queue-or-direct-     │ You took the model's FRAMING │
│ call                │ call, got a confident      │ of the problem and its       │
│                     │ paragraph, went with it    │ answer in the same gesture   │
├─────────────────────┼────────────────────────────┼──────────────────────────────┤
│ Learning a new      │ Had it generate the        │ −17 points on comprehension  │
│ library             │ working code               │ vs the control group         │
└─────────────────────┴────────────────────────────┴──────────────────────────────┘
```

## Why software engineers are unusually exposed

- **Surface signals look correct by default.** Generated code compiles, lints, runs, and matches the file around it. Most professions have no such strong "looks plausible" filter for AI output. Ours does — and it is the *wrong* filter. **Surface correctness is not systemic correctness**, and the gap between them is exactly where surrender hides.
- **Throughput is the visible metric.** PRs merged, tickets closed. Nothing in that set distinguishes "I built this and understand it" from "the agent built it and I approved it." Surrender is invisible to the dashboard.
- **Confidence transfers cleanly.** Models speak in declaratives; code review reads declaratives as authority. When the agent writes "we debounce at 300ms here to avoid jank," it sounds like institutional knowledge even though the number was invented on the spot. You inherit the certainty without the (nonexistent) reasoning.
- **It composes.** Once you have accepted a chunk you do not understand, the next change to that chunk is almost guaranteed to be another surrender, because forming a view now requires reconstructing the part you skipped. **Surrender is path-dependent.**

The Microsoft Research / Carnegie Mellon survey of 319 knowledge workers (936 first-hand work tasks) found the governing relationship: *higher confidence in the AI correlates with less critical thinking; higher confidence in yourself correlates with more.* Which means the tools that feel best are the ones most likely to induce it.

## Consequences

```
┌──────────────┬───────────────────────────────────────────────────────────────────┐
│ Horizon      │ What you actually pay                                             │
├──────────────┼───────────────────────────────────────────────────────────────────┤
│ Same day     │ Nothing. This is the problem                                      │
├──────────────┼───────────────────────────────────────────────────────────────────┤
│ Same sprint  │ A subtle transaction-boundary change ships. Tests were green      │
├──────────────┼───────────────────────────────────────────────────────────────────┤
│ 3 months     │ You defend a design in a meeting and cannot reconstruct the why   │
├──────────────┼───────────────────────────────────────────────────────────────────┤
│ 6 months     │ Something breaks. One engineer can fix it from first principles.  │
│              │ The other cannot. On paper they shipped the same amount           │
├──────────────┼───────────────────────────────────────────────────────────────────┤
│ Career       │ You can only ship with an agent watching. The labour market is    │
│              │ already re-pricing what that is worth                             │
└──────────────┴───────────────────────────────────────────────────────────────────┘
```

## How to deal with it

**Personal calibration — the question to keep asking is "am I forming an independent view, or adopting the model's wholesale?"**

- **Construct an expectation before reading the output.** Before running the agent on anything non-trivial, write down what you think the answer should look like. Three lines or fifty. Queue or direct call. This module or that one. If the agent matches, you are calibrated. If it does not, you now have a real choice: *am I wrong, or is it?* **That choice is the thing surrender skips.**
- **Read the diff like the AI didn't write it.** Would you merge this from a junior on the strength of "the tests pass"? No. The job hasn't changed; only the author has. "Seems right" is still not a review.
- **Ask the model to argue against itself.** Models will produce an equally confident counter-argument on request. That second pass is cheap and it breaks the borrowed-confidence effect. If you cannot reason about which of the two is right, you just found the spot where you were about to surrender.
- **Notice when you're tired.** Surrender is a fatigue phenomenon — the first PR of the day gets a review, the fifth gets a glance. "Stop letting the agent generate when I'm too tired to evaluate" is now part of the job.
- **Watch where the confidence is coming from.** If you are defending a choice you cannot reconstruct, that is a surrender artifact. Go rebuild the *why* before the conversation continues.
- **Ask for the explanation before the code.** In unfamiliar territory the first prompt should be "explain how this works and what the tradeoffs are." Same tool, opposite outcome: inquiry posture scored >65% on comprehension, delegation posture <40%.

**Structural moves — build a harness that makes surrender harder ([[harness-engineering]], [[harness-patterns]]):**

- **Verification as a hard exit criterion.** Every agent-completed task must terminate in concrete evidence: a passing test, a screenshot, a runtime trace, a signoff. "It looks done" is the surrender-friendly exit; "here is the evidence" is the surrender-resistant one. This is the same discipline [[eval-driven-development]] and [[private-evals]] apply to models, pointed at humans.
- **Anti-rationalization tables.** Pair every common excuse for skipping a step with a pre-written rebuttal. *"This task is too simple to need a spec." → "Acceptance criteria still apply."* Models are exceptional at generating plausible reasons to skip the rigorous step; you want the rebuttal written *before* Friday afternoon, not argued on the day.
- **Smaller scope, smaller PRs.** Surrender scales with size. A 50-line change you can read; a 600-line change you cannot. **The unit of review is the unit of comprehension.**
- **Friction by design.** A required design doc before generation, a confirmation before merge, a checklist before deploy. Friction has a bad name in productivity discourse, and it is exactly what stands between offloading and surrender.
- **Solo time at the keyboard.** Write some code without the agent every week — as a calibration exercise, not a moral one. The day you cannot comfortably build something simple unassisted is the day offloading became surrender and you missed it.

Andy Clark's framing is the target state: the difference between **delegating** to an AI and **cooperating** with it. Delegation produces surrender. Cooperation produces **mutual amplification** — your prompts sharpen the output, which sharpens your next prompts, which sharpens your model of the problem. You can feel the difference: with amplification you end the session with a sharper mental model than you started with, not a fuzzier one.

---

# 2. Cognitive Debt

## What it means

**Cognitive debt** is the compounding balance you accrue by outsourcing thinking. The term comes from MIT Media Lab's *"Your Brain on ChatGPT: Accumulation of Cognitive Debt when Using an AI Assistant for Essay Writing Task"* (Kosmyna et al., arXiv 2506.08872) — deliberately borrowed from technical debt: short-term gain, compounding long-term cost.

If cognitive surrender is the transaction, cognitive debt is the balance. **Each act of surrender is a tiny loan.** The codebase grows by a patch you do not understand. The architecture absorbs a decision you did not make. The test suite gains a test you did not think to specify. None of these are a problem on the day they happen. They compound.

## The MIT study, in detail

54 participants wrote essays across three sessions in three arms — LLM, search engine, and brain-only — under EEG.

```
┌──────────────────┬───────────────────┬─────────────────┬────────────────────────┐
│ Arm              │ Neural connectivity│ Ownership felt  │ Could quote own work?  │
├──────────────────┼───────────────────┼─────────────────┼────────────────────────┤
│ Brain-only       │ Strongest, most    │ Highest         │ Yes                    │
│                  │ distributed        │                 │                        │
├──────────────────┼───────────────────┼─────────────────┼────────────────────────┤
│ Search engine    │ Moderate           │ Middle          │ Mostly                 │
├──────────────────┼───────────────────┼─────────────────┼────────────────────────┤
│ LLM              │ Weakest coupling   │ Lowest          │ 83% could NOT quote a  │
│                  │                    │                 │ single line            │
└──────────────────┴───────────────────┴─────────────────┴────────────────────────┘
```

Session 4 is the part everyone skips and it is the most important one. 18 participants came back and **swapped arms**:

- **LLM-to-Brain** (tool taken away): still showed reduced alpha and beta connectivity — under-engagement persisted. **78% still could not quote their own work.** The debt did not clear when the tool did.
- **Brain-to-LLM** (tool newly given): higher memory recall, strong occipito-parietal and prefrontal activation. People who had built the mental model first *used the tool better.*

That asymmetry is the actionable finding. **Order of operations matters.** A CHI 2026 study found the same shape from a different angle: when people had LLM access at the *start* of a task, the model framed the whole problem, and decisions were measurably worse even when the human did the rest of the work themselves.

## Comprehension debt — the organizational version

Addy Osmani's *comprehension debt* is the same disease at team scale: **the growing gap between how much code exists in your system and how much of it any human genuinely understands.**

Unlike technical debt, which announces itself — slow builds, tangled deps, the dread when you touch that one module — comprehension debt **breeds false confidence**. The codebase looks clean. The tests are green. The reckoning arrives quietly, at the worst possible moment. Margaret-Anne Storey documented a student team that hit the wall in week seven: they could no longer make simple changes without breaking something, and nobody could explain *why* any design decision had been made. The theory of the system had evaporated.

The mechanism is a speed asymmetry:

```
┌────────────────────────────────┬────────────────────────────────────────────────┐
│ Before AI                       │ After AI                                       │
├────────────────────────────────┼────────────────────────────────────────────────┤
│ Senior reviewed FASTER than     │ A junior generates FASTER than a senior can    │
│ a junior could write            │ critically audit                               │
├────────────────────────────────┼────────────────────────────────────────────────┤
│ Review was a bottleneck — but a │ Review is a throughput problem. The quality    │
│ PRODUCTIVE, educational one     │ gate became a queue                            │
├────────────────────────────────┼────────────────────────────────────────────────┤
│ Reading a PR FORCED             │ Volume too high; output is syntactically clean, │
│ comprehension, spread knowledge │ superficially correct — the exact signals that  │
│ across the team                 │ historically triggered merge confidence         │
└────────────────────────────────┴────────────────────────────────────────────────┘
```

Dex Horthy's four-month experiment is the extreme instance. From July to November 2025 HumanLayer ran a fully automated pipeline where agents wrote, reviewed and deployed and **no human read a single line**. Production broke. No amount of prompting Opus 4.1 could find the root cause. Days of wading through spaghetti to discover a primary key wrongly routed through the entire codebase — and then **three weeks to re-onboard humans onto a codebase no human had ever read.** That is comprehension debt paid in full, with interest, in one lump sum. Full story in [[ai-dark-factory]].

Horthy's structural explanation is worth keeping: today's coding models are trained on SWE-bench-shaped rewards. **The reward signal rewards passing a test on turn five. It does not penalize the technical debt that surfaces on turn fifty.** The cost function of bad architecture cannot be evaluated by running a unit test, so it was never trained in.

## Why tests and specs are not the answer

Two obvious escape hatches, both with ceilings:

- **Tests.** A suite covering all observable behaviour would in many cases be more complex than the code it validates — and complexity you cannot reason about provides no safety. Deeper: **you cannot write a test for behaviour you never thought to specify.** Nobody writes a test asserting that dragged items shouldn't go fully transparent. And when an agent changes behaviour and updates 300 test cases to match, the question shifts from "is this correct?" to "were all those changes necessary?" — which tests cannot answer. Only comprehension can.
- **Specs.** Appealing in exactly the way Waterfall was appealing. But translating a spec into code involves an enormous number of implicit decisions — edge cases, data structures, error handling, performance tradeoffs — that no spec captures. **A spec detailed enough to fully describe a program is more or less the program, written in a non-executable language.** Horthy went further and now calls his own original line-by-line planning practice *anti-leverage*: reading a twenty-page plan alongside a twenty-page PR doubled review time without improving outcomes. Add spec drift — the code always diverges, and reconciliation is something models are bad at — and detailed specs become a second artifact to maintain. See [[briefs-as-code]] and [[prototypes-over-prds]] for the version of this that does work.

## Consequences

- **The measurement gap.** Velocity looks immaculate. DORA metrics hold. PR counts up. Coverage green. Calibration committees see throughput improvements and *cannot see* comprehension deficits, because no artifact of how organizations measure output captures that dimension. The incentive system optimizes correctly for what it measures; what it measures no longer captures what matters.
- **Silent liability transfer.** The organizational assumption that *reviewed code is understood code* no longer holds. Engineers approved code they did not understand, which now carries implicit endorsement. Liability got distributed without anyone deciding to distribute it.
- **A value inversion.** As volume goes up, the engineer who genuinely understands the system becomes *more* valuable, not less — the one who can look at a diff and know which behaviours are load-bearing, who remembers why that decision was made under pressure eight months ago. That becomes the scarce resource the whole system depends on. See [[ai-native-engineering]].
- **The regulation horizon.** When AI-generated code runs healthcare, financial infrastructure and government services, *"the AI wrote it and we didn't fully review it"* will not survive a post-incident report.

## How to deal with it

- **Two metrics, not one.** End sessions by asking: *did I learn anything today, or did I just close issues?* Sometimes "just closed issues" is the honest and fine answer. If it is the answer for months, debt is accruing. Ship and learn are separate metrics; your manager will only ever ask about the first.
- **Form a hypothesis before you ask.** Two or three sentences on what you think the problem is. Use the model's answer to *test* your theory, not to replace it.
- **Explain before generate, when learning.** The single highest-leverage habit in the data. Same tool, used to interrogate rather than produce, builds instead of erodes the mental model.
- **Use Learning Mode when out of your depth.** Anthropic, OpenAI and Google all ship Socratic modes now. Almost nobody uses them for production work — filed under "for students." That is a mistake. The feature that helps a sophomore learn React works for a senior learning Rust; you just have to be willing to feel like a beginner again.
- **Re-derive by hand occasionally.** Take something the model wrote and rebuild it from scratch. It is the calibration check that tells you how much you have quietly lost.
- **Slow loops instead of fast ones.** Horthy's replacement for the dark factory: a nightly cron in CI that fixes exactly *one* anti-pattern — a lint violation, a needlessly optional prop — commits, and opens **one small PR**. The team wakes up to a codebase incrementally better, and every PR is small enough for genuine human review. Four agents, four PRs, all read before merge. "Build one loop at a time and keep them small and contained." See [[loop-engineering]] and [[slow-fast-loops]].
- **Frequent intentional compaction.** Before context leaves the smart zone, extract the state into a verified markdown artifact and start fresh. Treat those artifacts as **tactical and ephemeral** — compress, verify, discard once code is written, regenerate next time. Tokens are cheaper than human time spent maintaining stale documents.
- **Rotate ownership of comprehension.** Somebody has to hold the theory of the system. Make it a named role, not an assumption.

---

# 3. Orchestration Tax

## What it means

Named on stage at Google I/O 2026 by Richard Seroter, on a panel with Addy Osmani, Aja Hammerly and Ciera Jaspan: *"You can't manage twenty agents successfully in your own brain."* Addy's formulation:

> "Running multiple agents does not mean there is more of you."

**The orchestration tax is the structural gap between agent production and what you can actually merge.** It is what happens when you put a single-threaded resource in charge of a concurrent one. Crucially, and this is the part people get wrong: **it is not a discipline problem. It is an architecture problem.**

## The asymmetry nobody prices in

```
┌──────────────────────────────┬──────────────────────────────────────────────────┐
│ Starting an agent            │ Closing the loop on an agent                     │
├──────────────────────────────┼──────────────────────────────────────────────────┤
│ One keystroke. One sentence  │ Someone checks correctness, reconciles it with    │
│                              │ what the other agents touched, holds the          │
│                              │ architecture in their head                       │
├──────────────────────────────┼──────────────────────────────────────────────────┤
│ Infinitely parallel          │ Strictly serial                                  │
├──────────────────────────────┼──────────────────────────────────────────────────┤
│ Free                         │ Your entire remaining attention                  │
└──────────────────────────────┴──────────────────────────────────────────────────┘
```

Two pieces of old performance engineering explain the rest:

- **You are the GIL.** Python lets you spawn any number of threads, but only one executes bytecode at a time because they must acquire the lock. You are the Global Interpreter Lock of your agent fleet. They all run at once; the moment any of their work needs genuine architectural understanding or conflict resolution, it must acquire the lock. **There is one lock. You hold it.**
- **Amdahl's Law makes it precise.** Speedup from parallelism is capped by the serial fraction. In agentic development **the serial fraction is the judgement.** Spawning eight agents does not speed up your judgement — it deepens the queue feeding into it. Optimizing the non-bottleneck never increases throughput; it just grows the pile of unfinished work in front of the bottleneck.

Measured, naive multi-agent setups spend **40–60% of total execution time on coordination alone**. And the human coordination is worse, because it is unbilled: reading output from one system, pasting into another, remembering context, resolving conflicts, cleaning up. That is unpaid orchestration tax.

## The tiredness has a specific cause

Addy: *"I never felt more productive with my tools but I am also more tired than I ever been. Both halves are completely real and they have the same cause."*

Every check-in on an agent you have been away from is a **context switch**: flush your brain, reload a different context from cold. CPUs do this in microseconds and architects still work hard to avoid it. You do it in minutes and **you never reload perfectly**. Five agents is not one workload done five times. It is five cold reloads plus a permanent background process worrying about which agent you should be checking.

## Where the tax gets paid when you refuse to pay it deliberately

This is the link back to sections 1 and 2, in Addy's own words:

> "If you try to grind it out, the limit just shows up as shallow code reviews or experiencing cognitive surrender where you just accept the agent's code because forming your own opinion costs attention you don't have anymore. You either pay the tax deliberately or you let it quietly destroy your understanding of your own system."

The industry-scale version of the same bill, from paddo's *Agents Merge. Someone Still Has to Ship.*: GitHub merged 518.7M PRs in 2025, up 29% YoY, with agent-authored PRs going **4M → 17M in six months**. DX (135K devs) puts 22% of merged code as AI-authored, with daily AI users merging ~60% more PRs. CodeRabbit across 13M PRs finds AI-co-authored PRs carry **1.7x more findings, 1.4x critical, ~75% more logic and correctness issues**. Lightrun finds **43% of AI-generated changes need debugging in production after passing QA and staging**. DORA 2025 names the pattern **Acceleration Whiplash**: throughput up, stability down 7.2%, MTTR barely moving. *The numerator went up. The denominator went up faster.*

Amazon paid it in cash in March 2026 — two outages traced to AI-assisted code deployed without proper approval, a ~6-hour disruption costing ~120,000 orders on March 2 and a second dropping US order volume 99% for ~6 hours on March 5 (~6.3M orders), followed by a 90-day code safety reset and a hard senior-approval requirement across 335 critical systems.

And METR's randomized trial is the perception version: 16 experienced open-source developers, 246 real tasks in codebases they knew well, measured **19% slower** with AI tools — while estimating afterward that they were **20% faster**. A 39-point gap between what happened and what it felt like. The generation step is memorable; the verification step is not.

## The 19-agent trap

paddo's contribution is the counter-intuitive half: **more orchestration scaffolding makes it worse, not better.** Frameworks like BMAD mirror the org chart — Analyst agent, PM agent, Architect agent, Scrum Master agent, Developer agent, QA agent, nineteen of them with defined handoffs. It *feels* right because it maps to how software has always been built. That is exactly the problem.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Why it feels right         │ Why it fails                                       │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Maps to the org chart      │ AI doesn't work like a team of humans. You are     │
│                            │ recreating the coordination friction AI removed    │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Phase gates = quality      │ Phases existed because iteration was expensive.    │
│                            │ Iteration is now seconds. Gates are pure friction  │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ More structure = better    │ Every layer of scaffolding consumes tokens that    │
│ output                     │ could hold project context, dilutes signal, and    │
│                            │ creates persona-vs-intent conflicts                │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Explains well in a deck    │ It optimizes for EXPLAINABILITY, not effectiveness.│
│                            │ Cargo cult SDLC                                    │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

The reference point: Boris Cherny, who created Claude Code, describes his own setup as *"surprisingly vanilla"* — Plan Mode first, a short shared CLAUDE.md of roughly **2,000 tokens** treated as a "do not repeat" ledger, verification loops, a handful of parallel sessions. No 19-agent orchestration, no multi-phase specification workflow, no external coordination layer. Compare against BMAD's multi-file agent configurations, orders of magnitude larger, all competing for attention in the same context window. Related: [[12-factor-agents]], [[SDLC-death]].

## How to deal with it

**Architect your attention the way you architect any concurrent system.**

- **Scale the fleet to your review rate, not to the UI.** Good concurrent systems use **backpressure**: the producer slows to match the consumer. Your agent count is the producer; your review rate is the consumer. The right number of parallel agents is how many you can genuinely code review. For most people that is a **low single digit**. The tool will happily let you spawn twenty; that is a UI feature, not a capacity statement.
- **Sort the work into two piles.** Pile one: isolated work you are happy to delegate to background agents, running async, needing you only at the final gate. Pile two: complex work where **the judgement IS the work** — a weird bug, an architecture call. The big mistake is trying to parallelize pile two. It just thrashes the lock and everything comes out worse.
- **Batch your reviews.** Reviewing four agents in one sitting is far cheaper than checking one, leaving, and returning cold. Give agents a long leash; let work pile up; process the batch.
- **Only spend the lock on judgement.** Never spend your brain on what the machine can verify itself. Make the agent produce a passing test or a screenshot. Agents can prove the boring 80% themselves so your scarce attention goes to the 20% that genuinely needs a human. The DoD devsecops factory vision targets 90% of issues caught by automation — that number is roughly the ceiling of *verifiable* tasks.
- **Protect your serial time.** The bottleneck deserves your best hours, not the leftover minutes between check-ins. Sometimes the highest-leverage move is to close the laptop full of agents and think hard about one problem with the lock held the whole time. **Orchestrating is not the work. It is the overhead around the work.**
- **Find the leverage point.** Horthy's third factory model: one hour of human architectural planning collapses uncertainty so that implementation review takes twenty minutes instead of hours. *"An hour spent over here in planning can save you four hours in implementation."* That path yields 2–3x with near-human quality, against 30–50% for reading every line and catastrophe for reading none.
- **Decouple merge from release.** paddo's release-layer playbook, since the tax lands hardest downstream: agents merge behind a feature flag and a human controls exposure (reverting a flag is one click; reverting a release is a paged team); tiny PRs each reviewable in under five minutes; auto-rollback on the four golden signals; risk-score the diff by blast radius so high-risk routes to humans and low-risk rides the auto-merge train; auto-batch the deploy queue. **The human owns the checkpoints; the system owns the transitions.**
- **Start vanilla.** Plan Mode, a focused short CLAUDE.md, verification loops. Add complexity when you hit a concrete limit — not when someone sends you a framework link.

Honest caveats on that playbook, also from paddo: Stripe's 1,145 PRs/day requires test infrastructure most teams will not have this year, and cargo-culting continuous deploy without the underlying investment is precisely the failure DORA names. Feature flags accrete into permanent forks nobody is scheduled to retire. Auto-rollback assumes telemetry you probably do not have at user-journey granularity. Risk scores are advisory — a model judging another model's diff is not a closed loop. And MTTR is the next bottleneck: as deploys/day climb, on-call load climbs with it, and AI has done the least to help there.

---

## How The Three Compound

```
                     ┌──────────────────────────┐
                     │    ORCHESTRATION TAX     │
                     │  more agents than you    │
                     │  have attention to steer │
                     └────────────┬─────────────┘
                                  │ forming your own view
                                  │ now costs attention
                                  │ you don't have
                                  ▼
                     ┌──────────────────────────┐
                     │   COGNITIVE SURRENDER    │
                     │  you accept the output   │
                     │  instead of judging it   │
                     └────────────┬─────────────┘
                                  │ each acceptance
                                  │ is a small loan
                                  ▼
                     ┌──────────────────────────┐
                     │  COGNITIVE / COMPREHENSION│
                     │           DEBT            │
                     │  code exists that nobody  │
                     │  in the building understands│
                     └────────────┬─────────────┘
                                  │ a weaker mental model
                                  │ makes review slower
                                  │ and shallower
                                  ▼
                     ┌──────────────────────────┐
                     │  REVIEW THROUGHPUT DROPS │
                     │  the serial bottleneck   │
                     │  gets narrower ──────────┼──► back to the top
                     └──────────────────────────┘
```

Each turn of the loop is invisible on the dashboard and each turn tightens the next. This is why treating any one of the three in isolation does not hold: personal discipline alone loses to the tax, backpressure alone does not repay the debt, and paying down the debt without fixing the fleet size just re-accrues it next sprint.

## The Diagnostic

Which one do you actually have?

```
┌────────────────────────────────────────────┬────────────────────────────────────┐
│ Symptom                                     │ Which side effect                  │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ You defend a design and can't reconstruct   │ Surrender (already booked as debt) │
│ why it was chosen                           │                                    │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ You approve PRs faster than you could read  │ Surrender, driven by the tax       │
│ them out loud                               │                                    │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ Nobody on the team can explain how two      │ Comprehension debt                 │
│ subsystems are meant to fit together        │                                    │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ Simple changes keep breaking unrelated      │ Comprehension debt, late stage     │
│ things                                      │                                    │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ You feel maximally busy and can't name what │ Orchestration tax                  │
│ shipped this week                           │                                    │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ You are more productive AND more tired than │ Orchestration tax                  │
│ you have ever been                          │                                    │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ PR count is up, incidents and rework are up │ All three, at org scale            │
│ faster                                      │ (Acceleration Whiplash)            │
├────────────────────────────────────────────┼────────────────────────────────────┤
│ You could not build something simple today  │ Debt, personal, advanced           │
│ without an agent                            │                                    │
└────────────────────────────────────────────┴────────────────────────────────────┘
```

## What This Means

None of this is an argument against the tools. Osmani ships more with them than without and says the people sitting this out are making the bigger mistake; Horthy's whole company exists to make agents work; paddo's advice is to ship faster, just through a system rather than through heroics. The argument is narrower and harder: **the tools are the same in both outcomes — the posture and the architecture are what differ.**

Cognitive surrender is a calibration failure you commit dozens of times a day without noticing. Cognitive debt is what those failures add up to, and the MIT session-4 data says it does not clear the moment you put the tool down. The orchestration tax is the force that makes both of them the rational local choice, because forming your own opinion costs attention you already spent spawning agent number nine.

The counter-move is the same shape in all three cases: **stop optimizing the part that was never the constraint.** Generation is not the constraint. Agent count is not the constraint. The constraint is one human's ability to judge whether what came back is right, and to still understand the system six months from now. Everything worth doing here — backpressure on the fleet, verification as an exit criterion, explain-before-generate, small PRs, slow loops, one hour of planning to save four of implementation — is a way of spending that one scarce resource on the only thing that actually requires it.

The honest test is the one Addy ends on. **If your code is shipping and your understanding of the system is shrinking, you are paying with cognitive debt. If your code is shipping and your understanding is growing, you are doing the job, just faster than before.**

## Links

- Cognitive Surrender (Addy Osmani): https://addyosmani.com/blog/cognitive-surrender/
- The Orchestration Tax (Addy Osmani): https://addyosmani.com/blog/orchestration-tax/
- Comprehension Debt — the hidden cost of AI generated code (Addy Osmani): https://addyosmani.com/blog/comprehension-debt/
- Don't Outsource the Learning (Addy Osmani): https://addyosmani.com/blog/dont-outsource-learning/
- Thinking — Fast, Slow, and Artificial (Shaw & Nave, Wharton, SSRN): https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6097646
- Thinking Fast, Slow, Artificially: AI and Your Brain (Wharton Executive Education): https://executiveeducation.wharton.upenn.edu/thought-leadership/wharton-at-work/2026/05/thinking-fast-slow-and-artificially/
- Wharton researchers coined 'cognitive surrender' (TNW): https://thenextweb.com/news/wharton-cognitive-surrender-ai-chatbots-decisions-moot-app
- Your Brain on ChatGPT (MIT Media Lab): https://www.media.mit.edu/publications/your-brain-on-chatgpt/
- Your Brain on ChatGPT (arXiv 2506.08872): https://arxiv.org/abs/2506.08872
- Your Brain on ChatGPT project site: https://www.brainonllm.com/
- How AI Impacts Skill Formation (Anthropic, arXiv 2601.20245): https://arxiv.org/abs/2601.20245
- The Impact of Generative AI on Critical Thinking (Microsoft Research / CMU): https://www.microsoft.com/en-us/research/publication/the-impact-of-generative-ai-on-critical-thinking-self-reported-reductions-in-cognitive-effort-and-confidence-effects-from-a-survey-of-knowledge-workers/
- Measuring the Impact of Early-2025 AI on Experienced Developer Productivity (METR, arXiv 2507.09089): https://arxiv.org/abs/2507.09089
- The 19-Agent Trap (paddo): https://paddo.dev/blog/the-19-agent-trap/
- Agents Merge. Someone Still Has to Ship. (paddo): https://paddo.dev/blog/agents-merge-someone-ships/
- The SDLC Is Collapsing Too (paddo): https://paddo.dev/blog/sdlc-is-collapsing/
- Guardrails by Default (paddo): https://paddo.dev/blog/guardrails-by-default/
- Context engineering with Dex Horthy (The Pragmatic Engineer): https://newsletter.pragmaticengineer.com/p/context-engineering-with-dex-horthy
- Dex Horthy: A Fully Automated 'Dark Factory' Corrupted a Codebase in Three Months: https://finance.biggo.com/news/15099f5634f5ab9a
- 12-Factor Agents (Dex Horthy / HumanLayer): https://github.com/humanlayer/12-factor-agents
- No Vibes Allowed: Solving Hard Problems in Complex Codebases (Dex Horthy talk): https://bagrounds.org/videos/no-vibes-allowed-solving-hard-problems-in-complex-codebases-dex-horthy-humanlayer
- The Multi-Agent Coordination Tax: https://medium.com/@georgethomasm_89397/the-multi-agent-coordination-tax-why-your-ai-agents-are-slower-than-you-think-1b88d7cd74ea
- Are you paying an AI 'swarm tax'? (VentureBeat): https://venturebeat.com/orchestration/are-you-paying-an-ai-swarm-tax-why-single-agents-often-beat-complex-systems
