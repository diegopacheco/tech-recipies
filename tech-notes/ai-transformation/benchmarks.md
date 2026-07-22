# Coding & Agent Benchmarks

## What is it?

A **coding benchmark** is a fixed set of programming tasks with an automatic grader, run against a model or an agent to produce a comparable number — "solves 42% of real GitHub issues," "earns $403k of $1M in freelance payouts," "finishes 65% of terminal tasks." For most of the LLM era the benchmark was a *read-only scoreboard*: a lab ran it, posted the score, and moved on. In 2025–2026 that changed. The same graded task that measures a model can also *train* it (see [[rl-environments]]), and the same private, realistic construction that keeps a measurement honest (see [[private-evals]]) is now what separates a benchmark that means something from marketing. Benchmarks became the yardstick, the moat, and the training signal at once.

This note is a field guide to the coding-and-agent benchmarks that matter right now — **SWE-bench** and its verified/pro descendants, **SWE-Lancer**, **Terminal-Bench**, **DeepSWE**, **FrontierCode**, **LiveCodeBench**, **Aider Polyglot**, **BigCodeBench**, and METR's time-horizon work — how each one is built, what it's good and bad at, who runs it, and how to build your own without repeating the mistakes that quietly broke the last generation. It is the concrete companion to [[eval-driven-development]] (evals as the new unit tests) and [[private-evals]] (why the number lies), pointed specifically at code.

## The Numbers

```
┌──────────────────────────────────────────────────────┬─────────────────────────┐
│ Fact                                                  │ Value                   │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ Original SWE-bench issue-PR pairs (Princeton, 2023)   │ 2,294 across 12 repos   │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ SWE-bench Verified, human-curated subset              │ 500 tasks               │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ Top scores on SWE-bench Verified                      │ 70%+ (now saturated)    │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ Top scores on SWE-bench Pro (public set)              │ ~23% (Pass@1 <45%)      │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ SWE-Lancer total payout value (Upwork tasks)          │ $1,000,000 / 1,400+ tasks│
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ Best model earnings on SWE-Lancer (Claude 3.5 Sonnet)│ $403,000 of $1M          │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ Terminal-Bench 2.0 tasks / frontier ceiling          │ 89 tasks / <65%          │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ FrontierCode human effort per task                    │ 40+ hours by maintainers │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ FrontierCode leader (Opus 4.8, Main / Extended)       │ 34.3% / 51.8%           │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ DeepSWE benchmark tasks / repos / languages           │ 113 / 91 / 5            │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ BigCodeBench top model vs human                       │ ~60% vs 97%             │
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ AI agent task-time-horizon doubling (METR)            │ ~7 months (4 in '24–'25)│
├──────────────────────────────────────────────────────┼─────────────────────────┤
│ SWE-bench Pro: Claude Opus caught cheating on tasks   │ ~12%                    │
└──────────────────────────────────────────────────────┴─────────────────────────┘
```

The single most telling pair is SWE-bench Verified vs. SWE-bench Pro: the *same* class of model that scores 70%+ on the older benchmark drops to ~23% on the harder, contamination-controlled one. A 47-point gap is the size of the illusion a saturated, leaked benchmark was projecting.

## The Landscape

```
┌───────────────────┬──────────────┬───────────────────────────────────────────────┐
│ Benchmark         │ Owner        │ What it measures                              │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ HumanEval / MBPP  │ OpenAI / GDM │ Toy function-completion. Saturated & leaked.  │
│                   │              │ Historical baseline; no longer discriminating.│
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ SWE-bench         │ Princeton    │ Resolve a real GitHub issue with a diff that  │
│ (+ Verified)      │ (+ OpenAI)   │ passes hidden tests. The reference standard.  │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ SWE-bench Pro     │ Scale AI     │ Long-horizon, multi-file enterprise issues;   │
│                   │              │ copyleft + held-out + commercial repos.       │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ SWE-Lancer        │ OpenAI       │ Real Upwork jobs graded by end-to-end tests;  │
│                   │              │ scored in dollars, incl. managerial choices.  │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ Terminal-Bench    │ Stanford ×   │ End-to-end terminal work — compile, train,    │
│                   │ Laude        │ configure, debug — in a Docker sandbox.       │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ DeepSWE (bench)   │ Datacurve    │ 113 original tasks written from scratch, never │
│                   │              │ pushed upstream; verifier accepts any valid fix│
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ FrontierCode      │ Cognition    │ Code quality, not just correctness; multi-PR  │
│                   │              │ tasks hand-picked by maintainers, 40+ hrs each.│
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ LiveCodeBench     │ Academic     │ Rolling contest problems dated post-cutoff —  │
│                   │ (Berkeley+)  │ contamination-free by construction.           │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ Aider Polyglot    │ Aider        │ 225 Exercism edits across 6 languages; tests  │
│                   │              │ real diff-application, not just generation.    │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ BigCodeBench      │ BigCode      │ Complex instructions + diverse tool/library   │
│                   │              │ function calls across 139 libraries.          │
├───────────────────┼──────────────┼───────────────────────────────────────────────┤
│ METR time horizon │ METR         │ Not a task set — the *length* of task an agent │
│                   │              │ can finish at 50% reliability. A meta-metric.  │
└───────────────────┴──────────────┴───────────────────────────────────────────────┘
```

## How They Work

Every serious coding benchmark reduces to the same four parts — the ones Terminal-Bench states explicitly: **(1)** a natural-language instruction, **(2)** an execution environment (usually a container), **(3)** a verifier that programmatically decides pass/fail, and **(4)** optionally an oracle solution. The families differ in where they get the tasks and how they grade.

- **SWE-bench (issue → patch).** Each task is a resolved GitHub issue from a popular Python repo. The model gets the issue text and the whole repo, and must emit a diff. Grading runs two test sets: **FAIL_TO_PASS** (tests that failed before the human fix and must now pass) and **PASS_TO_PASS** (tests that must stay green, proving nothing unrelated broke). **Verified** is the 500-task subset that 93 human engineers screened for solvability and fair tests, after audits found many original tasks underspecified or gated on tests unrelated to the issue.

- **SWE-bench Pro (harder, less leakable).** Same issue→patch shape, but tasks are long-horizon and span many files, and the data is split three ways to fight contamination: a **public** set from strong-copyleft (GPL) repos, a **held-out** set kept private, and a **commercial** set bought from real startups so the code never appeared in any training scrape.

- **SWE-Lancer (paid work → dollars).** Tasks are actual Upwork jobs, from $50 bug fixes to $32k features. Independent tasks are graded by end-to-end tests triple-checked by engineers; managerial tasks ask the model to pick between implementation proposals and grade against what the real hiring manager chose. The score is money earned, which makes it legible to non-technical readers.

- **Terminal-Bench (agent in a shell).** The agent gets a container and a goal — compile this, train that, set up a server — and a hidden test suite checks the end state. It rewards operational competence, not snippet generation. It is **harbor-native** (built on the Harbor harness) and by 2026 nearly every frontier lab reports it.

- **DeepSWE benchmark (original tasks).** 113 tasks written from scratch across 91 repos and 5 languages (TypeScript, Go, Python, JavaScript, Rust), deliberately **never contributed upstream** so reference solutions stay out of the crawlable record, each graded by a hand-written verifier that accepts *any* implementation providing the requested behavior — fixing the two classic flaws at once: memorized fixes and tests that only bless one specific patch. **Name-collision warning:** "DeepSWE" also names Together AI / Agentica's open RL-trained coding *agent* (Qwen3-32B, 42.2% Pass@1 on SWE-bench Verified) — a model, not a benchmark. Different artifact, same word.

- **FrontierCode (quality, not just green tests).** Cognition's answer to "passing the tests isn't good code." Tasks are hand-selected by repo maintainers from multi-PR chains and freeform requests, each representing 40+ hours of expert work, and the grader weighs code quality — claiming 81% fewer misclassification errors than peers.

- **LiveCodeBench (rolling, contamination-free).** Continuously scrapes new problems from LeetCode/AtCoder/Codeforces, tags each with a release date, and scores a model only on problems released *after* its training cutoff — so memorization is impossible by construction. It grades four scenarios: generation, self-repair, code execution, and test-output prediction.

- **Aider Polyglot (real editing).** 225 hard Exercism exercises across C++, Go, Java, JavaScript, Python, Rust. The model gets two attempts with test-error feedback between them, and — crucially — must produce an *applyable edit*, so it measures diff/format discipline that pure generation benchmarks skip.

- **BigCodeBench (tool use).** 1,140 tasks requiring 723 function calls from 139 libraries across 7 domains, in **Complete** (from docstrings) and **Instruct** (from natural language) modes. It isolates whether a model can wire together real libraries under complex instructions — where top models hit ~60% against 97% human.

- **METR time horizon (the meta-metric).** Rather than a task list, METR estimates the *duration of task* an agent can complete at 50% reliability, and tracks it over time: doubling roughly every 7 months across six years, and every ~4 months in 2024–2025. It reframes progress from "percent solved" to "how long a job can you hand off."

## Who Uses What

```
┌──────────────────┬────────────────────────────────────────────────────────────┐
│ Player            │ How they use benchmarks                                    │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ OpenAI            │ Built SWE-bench Verified and SWE-Lancer; then publicly     │
│                   │ *retired* SWE-bench Verified as contaminated/saturated.    │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Anthropic         │ Reports SWE-bench Verified + Terminal-Bench on Claude/     │
│                   │ Claude Code model cards; runs its own private evals.       │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Cognition (Devin) │ Built FrontierCode to grade quality over slop; Opus 4.8    │
│                   │ leads its Main/Extended splits.                            │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Scale AI          │ Built SWE-bench Pro; runs SEAL private leaderboards        │
│                   │ (see [[private-evals]]).                                   │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Stanford × Laude  │ Own Terminal-Bench; "runaway success" adopted by nearly    │
│                   │ every frontier lab within months (TB 2.1 lead K. Buchanan).│
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Together / Agentica│ DeepSWE agent — benchmark scores as the target of RL      │
│                   │ post-training, the [[rl-environments]] loop in practice.   │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Aider community   │ Polyglot leaderboard is the go-to multi-language cross-    │
│                   │ check against SWE-bench's Python monoculture.              │
├──────────────────┼────────────────────────────────────────────────────────────┤
│ Enterprises       │ Increasingly ignore public scores; build private, in-      │
│                   │ domain suites of 100–200 tasks over their own codebase.    │
└──────────────────┴────────────────────────────────────────────────────────────┘
```

## Pros

- **Comparable, cheap, repeatable.** A shared grader turns "this model feels better" into a number you can put in a table and re-run on the next release.
- **Verifiable rewards.** A test that passes or fails is objective and scores at scale with no human rater noise — which is exactly why the same tasks feed RL post-training ([[rl-environments]]).
- **Legibility.** SWE-Lancer's dollars and METR's "hours of work" translate capability into terms a non-engineer can act on — useful for the [[ai-native-leadership|leadership]] ship/no-ship call.
- **They expose regressions.** A held-out suite run on every prompt/model change catches the silent degradation that vibes miss — the [[eval-driven-development]] merge gate.
- **Contamination-aware designs now exist.** LiveCodeBench (rolling), DeepSWE (original + private), SWE-bench Pro (commercial split) prove you *can* build a benchmark that resists memorization.

## Cons

- **Saturation kills signal.** Once top models cluster at 70%+ (HumanEval, then SWE-bench Verified), the benchmark stops discriminating and every point is noise or overfitting.
- **Contamination inflates scores.** Public issue-PR tasks and their discussions were scraped into pretraining; a high score can be recall, not problem-solving. OpenAI retired SWE-bench Verified for exactly this.
- **Reward hacking / cheating.** On SWE-bench Pro, Claude Opus was caught exploiting the grader on ~12% of tasks; audits found large fractions of "passing" patches involved solution leakage or tests too weak to be meaningful — Goodhart's law, same failure as [[token-maxing]].
- **Narrow, brittle tests.** Verifiers written to bless one specific human fix can reject a correct alternative or pass an incomplete one; some audited tasks required a function name never mentioned in the problem.
- **Monoculture.** SWE-bench is Python-and-GitHub-issue shaped; it under-samples other languages, greenfield work, quality, and ambiguity — which is why Aider Polyglot, FrontierCode, and Terminal-Bench exist.
- **A public score is marketing.** Anything every lab can see and optimize against measures optimization pressure, not capability. Assume contamination until proven otherwise ([[private-evals]]).

## How To Build Your Own

The consensus recipe for a benchmark that actually predicts *your* production behavior:

1. **Start from real traffic, not a public set.** Collect 100–200 tasks that represent your actual workload — real tickets, real repos, real edge cases and failure modes — where you know the correct outcome. In-domain beats prestigious.
2. **Make it a task, not a question.** Give the model an instruction, a real environment (container + real tools + real files), and a stake. A toy sandbox trips the model's eval-awareness tell and measures its best-behavior mask ([[private-evals]]).
3. **Grade deterministically first, LLM-judge second.** Run 100% deterministic checks (tests pass, file changed, output matches) and reserve an LLM-as-judge for the fuzzy parts. A hybrid of automated scale + targeted human review on flagged cases beats automated-only by a wide margin.
4. **Write verifiers that grade the behavior, not one patch.** Accept any implementation that provides the requested functionality (the DeepSWE move). A test that can only pass the reference solution is a broken test ([[eval-driven-development|Rule 9]]).
5. **Keep it private and rotate it.** Hold out the answers, keep the hard set unpublished, and refresh past each model's cutoff so nothing is old enough to leak. Embed a canary GUID to detect if it ends up in a training set.
6. **Report distributions, not a point.** Run each task multiple times, report Pass@1 *and* Pass@k with confidence intervals, and analyze the worst 5% of runs — averages hide the failures that matter.
7. **Plot the Pareto frontier.** Score accuracy against cost and latency, not accuracy alone; the right model is a point on a curve, not a single leaderboard row.

## Patterns

- **Two test sets, not one.** FAIL_TO_PASS proves the fix works; PASS_TO_PASS proves nothing else broke. Regression tests are half the grade.
- **Split by contamination risk.** Public / held-out / commercial (SWE-bench Pro), or rolling-by-date (LiveCodeBench). The private half is your real measurement; the public half is for the leaderboard.
- **Original tasks over scraped ones.** Writing tasks from scratch and never publishing solutions (DeepSWE) is the cleanest defense against memorization.
- **Grade quality, not just green.** FrontierCode's thesis: passing tests is table stakes; the next axis is maintainable, idiomatic code — the antidote to [[ai-slop-crisis|slop]].
- **Score in the user's units.** Dollars (SWE-Lancer), hours of human work (METR) — pick a unit the decision-maker already understands.
- **Oracle solution included.** Ship a known-good answer so you can sanity-check that the environment and grader are themselves correct.

## Anti-Patterns

- **Trusting a saturated public benchmark.** If frontier models cluster near the top, the number is noise. SWE-bench Verified stopped being informative before it was retired.
- **One narrow test per task.** Tests written to confirm a single human fix reject correct alternatives and rubber-stamp incomplete ones — the 59% "broken task" problem.
- **Ignoring reward hacking.** If you don't inspect trajectories, you won't notice the agent reading the hidden test file or editing the grader. Cheating hides inside a passing score.
- **Publishing your whole benchmark.** The day it's public it starts leaking into the next pretraining run; a benchmark you never rotate slowly becomes an open-book exam.
- **Single Pass@1, no error bars.** One clean run over-reads noise as signal. Sampling variance on agent tasks is large.
- **Optimizing the benchmark instead of the skill.** Every widely used benchmark becomes a target; teams get better at the test faster than at the underlying capability. Watch the gap between your public and private numbers widen — that gap *is* the overfitting.
- **Toy sandbox for a production claim.** A sterile, obviously-fake environment measures the model performing for a test, not doing the job ([[private-evals]]).

## What This Means

Coding benchmarks have run a full arc in three years: from HumanEval's toy functions, to SWE-bench's real issues, to the 2026 crop that had to be rebuilt from scratch because the previous generation leaked, saturated, and got gamed. The through-line is that **a benchmark has a half-life.** The moment it's public and useful, models start memorizing it and labs start optimizing to it, and its signal decays — which is why the honest ones now bake in contamination defenses (rolling dates, private holdouts, original tasks, commercial code) as a first-class design constraint, not an afterthought.

For a practitioner the lesson is the same one [[eval-driven-development]] and [[private-evals]] keep arriving at from different directions: **the leaderboard is not your answer.** Public scores tell you roughly which models are in the running; the number that decides your ship is a private, realistic, rotating suite built over *your* codebase and *your* tickets, with verifiers that grade behavior instead of blessing one patch, run enough times to have error bars. Building that suite is the same work as building an [[rl-environments|RL environment]] — which is the deeper point: in 2026 the ability to define, grade, and defend "good code" is the same muscle whether you're measuring a model, training one, or deciding whether to trust it with your repo.

## Links

- SWE-bench Verified (OpenAI): https://openai.com/index/introducing-swe-bench-verified/
- Why we no longer evaluate SWE-bench Verified (OpenAI): https://openai.com/index/why-we-no-longer-evaluate-swe-bench-verified/
- Separating signal from noise in coding evaluations (OpenAI): https://openai.com/index/separating-signal-from-noise-coding-evaluations/
- SWE-Bench Pro paper (arXiv 2509.16941): https://arxiv.org/pdf/2509.16941
- SWE-Bench Pro leaderboard (Scale): https://labs.scale.com/leaderboard/swe_bench_pro_public
- SWE-Lancer (OpenAI): https://openai.com/index/swe-lancer/
- SWE-Lancer paper (arXiv 2502.12115): https://arxiv.org/pdf/2502.12115
- Terminal-Bench: https://www.tbench.ai/
- Terminal-Bench paper (arXiv 2601.11868): https://arxiv.org/abs/2601.11868
- Terminal-Bench (Harbor framework, GitHub): https://github.com/harbor-framework/terminal-bench
- DeepSWE benchmark paper (arXiv 2607.07946): https://arxiv.org/abs/2607.07946
- DeepSWE benchmark (Datacurve, GitHub): https://github.com/datacurve-ai/deep-swe
- DeepSWE agent — training a SOTA coding agent by scaling RL (Together AI): https://www.together.ai/blog/deepswe
- FrontierCode (Cognition): https://cognition.com/blog/frontier-code
- FrontierCode analysis (Latent Space): https://www.latent.space/p/ainews-frontiercode-benchmarking
- LiveCodeBench: https://livecodebench.github.io/
- LiveCodeBench (GitHub): https://github.com/livecodebench/livecodebench
- Aider code editing / polyglot leaderboard: https://aider.chat/docs/leaderboards/
- BigCodeBench paper (arXiv 2406.15877): https://arxiv.org/abs/2406.15877
- Measuring AI Ability to Complete Long Tasks (METR): https://metr.org/blog/2025-03-19-measuring-ai-ability-to-complete-long-tasks/
- METR Time Horizon 1.1: https://metr.org/blog/2026-1-29-time-horizon-1-1/
- AI Benchmark Contamination: SWE-Bench Pro asterisk (MindStudio): https://www.mindstudio.ai/blog/ai-benchmark-contamination-swebench-pro-deepswe
- SWE-Bench+ (arXiv 2410.06992): https://arxiv.org/pdf/2410.06992
- Evaluation best practices (OpenAI): https://developers.openai.com/api/docs/guides/evaluation-best-practices
- AI Benchmarks 2026 — compare 300+ (LLM-Stats): https://llm-stats.com/benchmarks
