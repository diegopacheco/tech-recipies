# Eval-Driven Development

## What is it?

**Eval-driven development (EDD)** is the practice of building an AI feature by first defining how you will *measure* whether it works, then iterating against that measurement until it passes — the same red-green-refactor instinct as test-driven development, rebuilt for systems that are probabilistic instead of deterministic. You do not assert that `f(x) == y`; you assemble a dataset of real inputs, run the agent over them, and grade the outcomes with a mix of code checks, model judges, and human labels. The grade is a **pass-rate over a distribution**, not a green dot, and the workflow is to drive that rate up release after release. The one-line slogan that carries it: **"evals are the new unit tests."**

This note is the *application builder's* half of evaluation. Its sibling [[rl-environments]] covers the *model trainer's* half — the insight that a graded task is simultaneously a benchmark and a reinforcement signal ("evals are the new moat"). They are the same artifact viewed from two desks: the lab uses the grader to *improve the model*, the product team uses it to *decide whether to ship*. EDD is also the discipline that [[ai-native-engineering]] names as the merge gate and [[harness-engineering]] runs inside the loop — pulled out and treated as a first-class craft of its own. The failure mode it exists to kill is the **vibe-check trap**: an agent that looks great in a few hand-run sessions, until someone tweaks a prompt and nobody can say whether anything still works.

## The Numbers

```
┌────────────────────────────────────────────────────┬──────────────────────────┐
│ Metric                                              │ Value                    │
├────────────────────────────────────────────────────┼──────────────────────────┤
│ LLM observability/eval platform market (2026)       │ ~$2.69B                  │
├────────────────────────────────────────────────────┼──────────────────────────┤
│ Same market, projected 2030                         │ ~$9.26B (~36% CAGR)      │
├────────────────────────────────────────────────────┼──────────────────────────┤
│ Braintrust Series B (Iconiq, a16z, Greylock)        │ $80M at ~$800M valuation │
├────────────────────────────────────────────────────┼──────────────────────────┤
│ Hamel & Shreya "AI Evals" course enrollment         │ 700+ students,           │
│                                                     │ 300+ companies           │
├────────────────────────────────────────────────────┼──────────────────────────┤
│ Promptfoo (red-team evals) outcome                  │ Acquired into OpenAI     │
│                                                     │ Frontier, Mar 2026       │
├────────────────────────────────────────────────────┼──────────────────────────┤
│ Free-forever OSS eval stacks                        │ DeepEval, Promptfoo,     │
│                                                     │ Ragas, Arize Phoenix     │
└────────────────────────────────────────────────────┴──────────────────────────┘
```

## The Thesis, In Quotes

The people building frontier models and the people funding the startups on top of them converged on the same point in 2025–2026:

```
┌────────────────────────────────────────────────────────────────────────────┐
│ "Evals are surprisingly often all you need."                                 │
│                                  — Greg Brockman, OpenAI President           │
│                                                                              │
│ "If there is one thing we can teach people, it's that writing evals is       │
│  probably the most important thing."                                         │
│                                  — Mike Krieger, Anthropic CPO               │
│                                                                              │
│ "Evals are emerging as the real moat for AI startups."                       │
│                                  — Garry Tan, Y Combinator CEO               │
│                                                                              │
│ Writing evals is becoming a core skill for anyone building products with AI. │
│                                  — Kevin Weil, OpenAI CPO (paraphrased)      │
└────────────────────────────────────────────────────────────────────────────┘
```

The throughline: in a stack where the model is rented and swappable, the durable thing a team owns is **its definition of "good" and the harness that enforces it.**

## TDD vs. EDD

EDD is not a new idea so much as the natural mutation of a discipline engineers already trust. What changes is that the system under test stopped being deterministic.

```
┌────────────────────┬─────────────────────────────┬──────────────────────────────┐
│ Dimension          │ TDD (deterministic code)    │ EDD (probabilistic system)   │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Unit of            │ assert f(x) == y, exact     │ graded outcome over a        │
│ correctness        │ pass / fail                 │ dataset; a pass-RATE         │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ System under test  │ a pure function             │ multi-step, adaptive agent   │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ The oracle         │ programmer writes the       │ code assertion, LLM-as-judge,│
│                    │ expected value              │ or human label               │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ A flaky test       │ is a bug to be fixed        │ is the baseline; you track   │
│                    │                             │ the rate, not a binary       │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ A failure means    │ the code is wrong           │ could be the prompt (spec),  │
│                    │                             │ the model (generalization),  │
│                    │                             │ or the data                  │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Coverage metric    │ lines / branches            │ a failure taxonomy built     │
│                    │                             │ from error analysis          │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Where data comes   │ programmer imagines cases   │ harvested from real          │
│ from               │                             │ production traces            │
├────────────────────┼─────────────────────────────┼──────────────────────────────┤
│ "Green" means      │ ship                        │ ship IF pass-rate ≥ threshold│
│                    │                             │ AND the estimate is tight    │
└────────────────────┴─────────────────────────────┴──────────────────────────────┘
```

## The Loop

The EDD workflow is a flywheel, and its unglamorous first step — **error analysis**, reading actual failures one by one and labeling them — is the step most teams skip and the one practitioners insist matters most.

```
   ┌──────────────────────────────────────────────────────────────────┐
   │                                                                    │
   ▼                                                                    │
 production traces ──► ERROR ANALYSIS ──► failure taxonomy ──► build    │
 (real inputs &       (read failures,    (the named ways      EVALUATORS│
  outputs)             label them)        it breaks)          code + LLM│
                                                              -as-judge │
                                                                  │     │
                                                                  ▼     │
   ship / monitor ◄── EVAL GATE in CI ◄── curated dataset ◄── validate  │
        │             (pass-rate ≥ X,      grows every         judge vs │
        └─────────────►threshold)          release            human ────┘
```

1. **Error analysis first.** Before any tooling, read a few dozen real traces and write down *how* the system fails. This produces a taxonomy of failure modes — the thing your evals will actually measure. It is the highest-leverage and most-skipped step.
2. **Build evaluators per failure mode.** Cheap deterministic checks where you can; an LLM-as-judge where the quality is subjective.
3. **Curate a dataset.** Real production inputs beat synthetic ones. The dataset is a compounding asset — it only grows.
4. **Gate the merge.** Run the suite in CI; block the deploy if the pass-rate drops below threshold. Fast/cheap smoke evals on every commit, the comprehensive suite nightly — exactly the unit-vs-integration split.
5. **Ship, observe, feed back.** Production telemetry surfaces new failures, which become new error-analysis fodder. The loop closes.

## The Three Gulfs

The cleanest mental model comes from Hamel Husain and Shreya Shankar's "AI Evals for Engineers & PMs" course. A failing AI feature is failing across one of three *gulfs*, and the cure is different for each — which is why "the agent is bad" is a useless diagnosis until you know which gulf you are in.

```
┌──────────────────────┬──────────────────────────────┬──────────────────────────┐
│ Gulf                 │ The problem                  │ The fix                  │
├──────────────────────┼──────────────────────────────┼──────────────────────────┤
│ Comprehension        │ You don't actually know what │ Error analysis — read    │
│                      │ your data or system does     │ the traces               │
├──────────────────────┼──────────────────────────────┼──────────────────────────┤
│ Specification        │ You can't tell the model     │ Better prompts, specs,   │
│                      │ precisely what you want      │ instructions             │
├──────────────────────┼──────────────────────────────┼──────────────────────────┤
│ Generalization       │ It fails even with a clear   │ Decompose the task,      │
│                      │ spec, across diverse inputs  │ change model/architecture│
└──────────────────────┴──────────────────────────────┴──────────────────────────┘
```

An automated evaluator's real job is to separate **specification failures** (fixable in the prompt) from **generalization failures** (the model genuinely can't, despite clear instructions). Confuse the two and you tune prompts forever against a problem only a better model or a decomposition will solve.

## The Three Kinds of Eval

```
┌──────────────────┬─────────────────────────────┬──────────────────────────────┐
│ Kind             │ What it grades              │ When to reach for it         │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Code-based       │ deterministic facts: JSON   │ format, structure, tool-call │
│ assertions       │ schema, regex, exact match, │ correctness, anything with a │
│                  │ did-it-call-the-right-tool  │ crisp right answer. Cheap,   │
│                  │                             │ fast, objective. Start here. │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ LLM-as-judge     │ subjective quality: tone,   │ when there's no string to    │
│                  │ helpfulness, faithfulness,  │ match. Scales human          │
│                  │ "did it answer the user"    │ judgment — but must itself   │
│                  │                             │ be validated against humans  │
├──────────────────┼─────────────────────────────┼──────────────────────────────┤
│ Human eval       │ the gold standard           │ to calibrate the judge, to   │
│                  │                             │ do error analysis, for the   │
│                  │                             │ cases that decide the launch │
└──────────────────┴─────────────────────────────┴──────────────────────────────┘
```

Cross-cutting this is **offline vs. online**: offline evals run against a frozen dataset in CI (the regression gate); online evals sample live production traffic (the early-warning system). Anthropic's own guidance lands on the same split — code-based checks for deterministic failures, an LLM-as-judge for the subjective ones — and notes that *without* any of this, debugging is purely reactive: wait for a complaint, reproduce by hand, fix, and pray nothing else regressed.

## Who's Doing What

```
┌──────────────────────┬────────────────────────────────────────────────────────┐
│ Player               │ Position                                               │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ Hamel Husain &       │ The canonical EDD methodology — error-analysis-first,  │
│ Shreya Shankar       │ the Three Gulfs, the Maven course (700+ students).     │
│ (Parlance Labs)      │ Reference text for how practitioners actually do this. │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ Braintrust           │ Dataset-first, model-agnostic; sandboxed Python custom │
│                      │ scorers. $80M Series B, ~$800M valuation.              │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ LangSmith (LangChain)│ Tracing + evals, tuned for LangGraph agent runs;       │
│                      │ default for LangChain-native stacks.                   │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ Arize Phoenix        │ OpenTelemetry-native; strongest portability for teams  │
│                      │ already instrumented with OTel. OSS + observability.   │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ Promptfoo            │ Security / red-team-focused evals. Acquired into the   │
│                      │ OpenAI Frontier stack, March 2026.                     │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ DeepEval (Confident) │ Code-first, pytest-style regression evals for RAG,     │
│                      │ outputs, and agent traces. OSS, free forever.          │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ UK AISI Inspect      │ Government-grade open eval framework; the rigor         │
│                      │ reference for safety and capability testing.           │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ OpenAI Evals         │ The original OSS framework + benchmark registry that   │
│                      │ seeded the "write your own eval" habit.                │
├──────────────────────┼────────────────────────────────────────────────────────┤
│ Anthropic            │ "Demystifying evals for AI agents"; Claude Code added  │
│                      │ evals first for narrow behaviors (concision, file      │
│                      │ edits), then complex ones (over-engineering). Also     │
│                      │ published the statistical-rigor and eval-awareness     │
│                      │ research the field needed.                             │
└──────────────────────┴────────────────────────────────────────────────────────┘
```

## Pros

- **Quality becomes systematic, not heroic.** "Did someone review this carefully?" turns into a CI check that cannot be skipped (Rule 9: tests verify intent).
- **Regressions are caught in seconds.** Change a prompt or swap a model, run the suite, and know exactly what broke instead of finding out from users.
- **It decouples you from any one model.** The discipline lives in the dataset and the graders, so upgrading the underlying LLM becomes a measured, shippable event rather than a leap of faith.
- **Error analysis surfaces failures you'd never guess.** Reading real traces consistently turns up failure modes no one would have invented in a planning meeting; the resulting dataset compounds in value.
- **It is the honest path to adopting a new model.** When a frontier release drops, the team with evals can answer "is it actually better *for us*" the same day; everyone else is back to vibes.

## Cons

- **The judge has biases of its own.** LLM-as-judge suffers position bias, verbosity bias, and self-preference (a model rating its own family higher). The judge needs to be evaluated against human labels before you trust it — evals all the way down.
- **Goodhart / overfitting.** Optimize hard enough to a fixed eval set and you tune the metric, not the task. This is the application-layer cousin of [[rl-environments|reward hacking]] and [[token-maxing]]'s gaming problem; rotate held-out sets to fight it.
- **Eval awareness.** Models can detect when they are being tested and behave differently — Anthropic documented exactly this in Claude Opus 4.6's BrowseComp performance, which makes a clean benchmark number less trustworthy than it looks.
- **Benchmark contamination.** Public test sets leak into training data; a high score can mean memorization rather than capability. Private, real-data evals are the only ungameable kind.
- **Statistical naivety.** A single pass-rate with no error bars is theater — Anthropic had to publish a statistical approach to model evals precisely because teams report point estimates and over-read tiny differences as progress.
- **Cost and latency.** Comprehensive LLM-judge suites are expensive to run on every commit; without a smoke-vs-nightly tier the eval gate becomes the thing engineers route around.
- **Error analysis is grunt work, so it gets skipped.** Teams jump straight to tooling, never read their traces, and ship generate-and-pray — the [[ai-slop-crisis|AI-slop]] failure mode wearing an eval-platform logo.

## What This Means

EDD is the concrete answer to the question the [[SDLC-death|collapse of the traditional SDLC]] and [[ai-native-engineering]] both leave hanging: *if the agent writes the code, what is the test?* The test is the eval, and the eval is where engineering judgment now lives. Writing the implementation got cheap; **defining "good" precisely and building the grader that enforces it did not.** That is the scarce skill, and it is why a sitting CPO at Anthropic and the president of OpenAI both say, in plain words, that writing evals is the single most important thing to learn.

The strategic read ties straight back to [[rl-environments]]: the grader is simultaneously how you *decide to ship* and, mechanically, how a model is *trained to do better* — which is why investors call evals a moat. For a product team the moat is narrower and more practical: in a world where the model is a commodity you rent, your **proprietary dataset of real failures and your battle-tested definition of correct** are the assets competitors can't copy by switching vendors. The teams that win the agent era are not the ones with the best model. They are the ones who can prove, on demand, that their system works — and watch the number go up.

## Links

- Eval-Driven Development (the methodology site): https://evaldriven.org/
- Eval-driven development: Build and evaluate reliable AI agents (Red Hat Developer): https://developers.redhat.com/articles/2026/03/23/eval-driven-development-build-evaluate-ai-agents
- How to Build Eval-Driven AI Observability for Agents (Latitude): https://latitude.so/blog/build-eval-driven-ai-observability-for-agents
- Eval-Driven Agent Development: What Actually Makes AI Agents Work (Dave Patten): https://medium.com/@dave-patten/eval-driven-agent-development-what-actually-makes-ai-agents-work-13fb7d4e1e77
- Why AI Evals Are the New Unit Tests (Aakash Gupta): https://aakashgupta.medium.com/why-ai-evals-are-the-new-unit-tests-the-quality-assurance-revolution-in-genai-456888217342
- AI Evals For Engineers & PMs (Hamel Husain & Shreya Shankar, Maven): https://maven.com/parlance-labs/evals
- LLM Evals: Everything You Need to Know (Hamel's Blog): https://hamel.dev/blog/posts/evals-faq/
- Bridging the Three Gulfs of LLM Development: A Primer to Evals (David Okpare): https://www.davidokpare.com/blog/a-primer-to-evals
- A pragmatic guide to LLM evals for devs (The Pragmatic Engineer): https://newsletter.pragmaticengineer.com/p/evals
- Demystifying evals for AI agents (Anthropic): https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- A statistical approach to model evaluations (Anthropic): https://www.anthropic.com/research/statistical-approach-to-model-evals
- Eval awareness in Claude Opus 4.6's BrowseComp performance (Anthropic): https://www.anthropic.com/engineering/eval-awareness-browsecomp
- evals are surprisingly often all you need (Greg Brockman): https://x.com/gdb/status/1733553161884127435
- Evals are emerging as the real moat for AI startups (Garry Tan): https://community.startuptalky.com/discussions/post/evals-are-emerging-as-the-r-ON7BNc03cUJP2Pm
- Top 7 LLM Evaluation Tools in 2026 (Confident AI): https://www.confident-ai.com/knowledge-base/compare/best-llm-evaluation-tools
- LLM Evaluation Tools: The Complete Comparison Guide 2026 (Inference.net): https://inference.net/content/llm-evaluation-tools-comparison/
- Large Language Model Observability Platform Market Report 2026 (Research and Markets): https://www.researchandmarkets.com/reports/6215671/large-language-model-llm-observability
- OpenAI Evals (GitHub): https://github.com/openai/evals
- UK AISI Inspect: https://inspect.aisi.org.uk/
