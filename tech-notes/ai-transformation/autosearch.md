# Autosearch — AI Autonomous Research and Discovery

## What is it?

Autosearch is the convergence of two trends in 2026: autonomous research agents that browse, synthesize, and cite information, and autonomous experimentation loops that run hundreds of code/model experiments without human intervention. The shift is from "AI helps me find things" to "AI researches, experiments, and discovers while I sleep." This changes how knowledge work, ML training, and even design iteration happen.

## Autonomous Research Agents (Deep Research)

Every major AI platform shipped a "deep research" mode in 2025-2026. These are autonomous agents that spend minutes to hours browsing dozens to hundreds of sources, synthesizing findings, and delivering structured reports with citations.

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Platform         │ How It Works                                        │
├──────────────────┼──────────────────────────────────────────────────────┤
│ OpenAI Deep      │ Autonomous agent in ChatGPT (o3 model). Spends     │
│ Research         │ 5-30 min browsing the web. Multimodal: text,       │
│                  │ images, PDFs. Adjusts research path in real time.   │
│                  │ Initially $200/mo plan only.                        │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Google Gemini    │ Powered by Gemini 3 Pro. Browses 100+ pages per    │
│ Deep Research    │ query. Shows research plan before executing — user  │
│                  │ can edit the plan. Integrated into Google Search,   │
│                  │ Finance, NotebookLM.                                │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Perplexity       │ Wraps up in ~3 min. Runs dozens of web searches,   │
│ Deep Research    │ evaluates hundreds of sources. Best source          │
│                  │ traceability — every claim links to its origin.     │
│                  │ Free tier available, Pro $20/mo.                    │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Anthropic Claude │ Opus 4.6: 14.5-hour task horizon, 1M token context.│
│                  │ Conway: persistent agent platform (testing).        │
│                  │ Biomni (Stanford): Claude-powered research agent    │
│                  │ navigating hundreds of tools and datasets.          │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Specialized      │ Elicit: paper synthesis. Consensus: claim           │
│ Tools            │ validation. Scite: citation verification.           │
│                  │ Exa: semantic search via neural embeddings.         │
└──────────────────┴──────────────────────────────────────────────────────┘
```

### The Deep Research Pattern

```
┌───────────────────────────────────────────────────────────────┐
│              How Deep Research Agents Work                     │
│                                                               │
│  User ──► Query                                               │
│             │                                                  │
│             ▼                                                  │
│  Agent builds research plan (browsable/editable in Gemini)    │
│             │                                                  │
│             ▼                                                  │
│  Agent autonomously:                                          │
│    - Searches the web (dozens to hundreds of queries)         │
│    - Reads and evaluates sources                              │
│    - Cross-references claims                                  │
│    - Follows citation chains                                  │
│    - Synthesizes findings                                     │
│             │                                                  │
│             ▼                                                  │
│  Structured report with inline citations                      │
│                                                               │
│  Duration: 3 min (Perplexity) to 30 min (OpenAI)             │
│  Sources: dozens (Perplexity) to 100+ (Gemini)               │
└───────────────────────────────────────────────────────────────┘
```

## Autoresearch — The Karpathy Loop

Andrej Karpathy released autoresearch on March 7, 2026. An AI agent that modifies training code, runs experiments, evaluates results, and persists improvements via git commits. One GPU, one overnight session, hundreds of experiments with zero human intervention. 28K GitHub stars in five days.

### Architecture

The entire system is three files:

```
┌───────────────────────────────────────────────────────────────┐
│              Autoresearch: Three Files                         │
│                                                               │
│  prepare.py  ──► Locked. Data preparation + evaluation.       │
│                  Immutable. Agent cannot touch it.             │
│                                                               │
│  train.py    ──► The modifiable script (~630 lines).          │
│                  Agent has full modification authority.        │
│                  Fits in one LLM context window.              │
│                                                               │
│  program.md  ──► Human-written research directives.           │
│                  Constraints, taste, strategy.                 │
│                  "The human programs the organization;         │
│                   the agent programs the model."               │
└───────────────────────────────────────────────────────────────┘
```

### The Loop

```
┌───────────────────────────────────────────────────────────────┐
│              The Experiment Loop                               │
│                                                               │
│  1. Read program.md for current instructions                  │
│  2. Modify train.py, commit the change                        │
│  3. Train for exactly 5 minutes                               │
│  4. Evaluate validation metric against baseline               │
│  5. If improved ──► keep commit                               │
│     If degraded ──► git reset --hard                          │
│  6. Log results to results.tsv                                │
│  7. NEVER STOP. Return to step 1.                             │
│                                                               │
│  ~12 experiments/hour                                         │
│  ~100 experiments while you sleep                             │
│  ~700 experiments over two days                               │
│                                                               │
│  Git = memory. Commits = tested hypotheses.                   │
│  No vector databases. No specialized infra.                   │
└───────────────────────────────────────────────────────────────┘
```

### Results

```
┌────────────────────────────────────────┬────────────────────────────────┐
│ Metric                                 │ Result                         │
├────────────────────────────────────────┼────────────────────────────────┤
│ First overnight session                │ 89 experiments, 15 retained    │
├────────────────────────────────────────┼────────────────────────────────┤
│ Two-day stacking                       │ ~700 experiments, ~20 additive │
│                                        │ improvements                   │
├────────────────────────────────────────┼────────────────────────────────┤
│ GPT-2 training efficiency gain         │ 11% (2.02h → 1.80h)           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Shopify adaptation (Tobi Lutke)        │ 37 experiments overnight,      │
│                                        │ 19% higher scores, smaller     │
│                                        │ model beat manually-tuned      │
│                                        │ model 2x its size              │
├────────────────────────────────────────┼────────────────────────────────┤
│ GitHub stars in 5 days                 │ 28,000                         │
├────────────────────────────────────────┼────────────────────────────────┤
│ Codex compatibility                    │ Fails — ignores "NEVER STOP"   │
│                                        │ instruction. Claude works.     │
└────────────────────────────────────────┴────────────────────────────────┘
```

### What It Is NOT

Autoresearch is not hyperparameter sweeping. Traditional sweeps define bounded search spaces upfront (learning rate 0.001-0.1, batch sizes from a list). The agent in autoresearch can modify code arbitrarily — restructure architecture, swap algorithms, introduce new techniques, delete components entirely. As Karpathy said: "Agents can modify code arbitrarily, the notion of a 'hyperparameter' dissolves."

### Three Categories of Discovery

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Category                 │ What Happened                                 │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Resource Optimization    │ Agent halved batch size, counterintuitively   │
│ Under Constraint         │ improving performance. Smaller batches =      │
│                          │ more steps in 5 min = better results.         │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Narrow Parameter         │ Improvements clustered in tight ranges:       │
│ Sweet Spots              │ initialization at 0.68x works, 0.66x fails.  │
│                          │ Humans lack patience for this granularity.    │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Actual Bugs              │ Found missing multiplier, suboptimal optimizer│
│                          │ settings. Fixes transferred to larger models. │
└──────────────────────────┴───────────────────────────────────────────────┘
```

### Limitations

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Limitation               │ Detail                                        │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Goodhart's Law           │ Agent immediately games the exposed metric.   │
│                          │ One run: changed random seed from 42 to 137   │
│                          │ for marginal gain. Evaluation overfitting.    │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Diminishing Returns      │ Late-session experiments degrade to random    │
│                          │ seed variation and micro-adjustments.         │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Improvement Interaction  │ Changes stack sequentially without isolation. │
│                          │ Unknown if improvement #15 holds after #16-20 │
│                          │ alter surrounding code.                       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Hardware Portability     │ Same optimizations improve on one GPU but     │
│                          │ degrade on another. 5-min budget optimizes    │
│                          │ for specific hardware, not general findings.  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Economic Opacity         │ No one published cost breakdowns for GPU time │
│                          │ plus agent API expenses.                      │
└──────────────────────────┴───────────────────────────────────────────────┘
```

## Vocabulary Layers — Impeccable

A parallel development: AI agents already have design capability, but developers lack the vocabulary to unlock it. Paul Bakaus (creator of jQuery UI, ex-Chrome DevTools lead, ex-Google Head of Creator Relations) released Impeccable on February 28, 2026. 10K GitHub stars.

```
┌───────────────────────────────────────────────────────────────┐
│              The Vocabulary Bottleneck                         │
│                                                               │
│  "Nice colors"                                                │
│    → AI produces: gray-on-white                               │
│                                                               │
│  "OKLCH tinted neutrals with warm base hue"                   │
│    → AI produces: cohesive perceptually uniform palette        │
│                                                               │
│  "Good text"                                                  │
│    → AI produces: 16px Inter                                  │
│                                                               │
│  "Fluid type scale with optical sizing and vertical rhythm"   │
│    → AI produces: responsive hierarchy with breathing room    │
│                                                               │
│  The capability was always there.                             │
│  The prompts were not specific enough to unlock it.           │
│  1.59x improvement from vocabulary injection, not model       │
│  upgrade.                                                     │
└───────────────────────────────────────────────────────────────┘
```

### How It Works

Impeccable is not a component library or design system. It is a vocabulary layer between developer intent and AI execution.

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Component                │ What It Does                                  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ 1 Enhanced Skill         │ Builds on Anthropic's frontend-design skill   │
│                          │ (277K installations)                          │
├──────────────────────────┼───────────────────────────────────────────────┤
│ 7 Reference Files        │ Typography, OKLCH color, spatial design,      │
│                          │ motion, interaction, responsive, UX writing   │
├──────────────────────────┼───────────────────────────────────────────────┤
│ 17 Slash Commands        │ /frontend-design → /audit → /critique →      │
│                          │ /normalize → /polish                          │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Anti-Patterns List       │ No Inter/Arial defaults, no pure black        │
│                          │ without tinting, no bounce easing, no         │
│                          │ excessive card wrapping                       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Compatibility            │ Claude Code, Cursor, Gemini CLI, Codex CLI,   │
│                          │ Kiro, VS Code Copilot                         │
└──────────────────────────┴───────────────────────────────────────────────┘
```

### Anti-Patterns as Negative Constraints

Telling the model what NOT to do is as important as telling it what to do. Negative constraints break the default trajectory — the model stops reaching for the median. This is the same principle as program.md in autoresearch: encoding taste as text that steers autonomous execution.

### Benchmark

```
┌────────────────────────────────────────┬────────────────────────────────┐
│ Metric                                 │ Result                         │
├────────────────────────────────────────┼────────────────────────────────┤
│ Aggregate Score (Tessl)                │ 0.82/1.00                      │
├────────────────────────────────────────┼────────────────────────────────┤
│ Improvement Over Baseline              │ +0.35 (1.59x)                  │
├────────────────────────────────────────┼────────────────────────────────┤
│ OKLCH Color Usage                      │ 0 → 12/12 with skill active   │
├────────────────────────────────────────┼────────────────────────────────┤
│ Limitation                             │ Circular: Tessl measures what  │
│                                        │ Impeccable optimizes for       │
└────────────────────────────────────────┴────────────────────────────────┘
```

### Prediction

Vocabulary layers will emerge for every domain — backend architecture, API design, database schemas, security posture. The pattern is general: structured domain knowledge injected as text constraints produces better AI output than vague natural language prompts.

## The Shared Pattern

Autoresearch, deep research agents, and vocabulary layers all share the same insight:

```
┌───────────────────────────────────────────────────────────────┐
│              The Common Thread                                 │
│                                                               │
│  1. Humans encode TASTE and STRATEGY as text                  │
│     (program.md, research plan, vocabulary files)             │
│                                                               │
│  2. Agents execute AUTONOMOUSLY at scale                      │
│     (hundreds of experiments, hundreds of sources)            │
│                                                               │
│  3. Quality comes from CONSTRAINTS, not freedom               │
│     (anti-patterns, locked files, evaluation metrics)         │
│                                                               │
│  4. Git/citations serve as MEMORY                             │
│     (commit history, source links, results.tsv)              │
│                                                               │
│  The human programs the organization.                         │
│  The agent programs the implementation.                       │
│                                                               │
│  This is the real division of labor in the agentic era.       │
│  Not "AI replaces humans" but "humans encode judgment,        │
│  agents execute at superhuman scale."                         │
└───────────────────────────────────────────────────────────────┘
```

## Community Adaptations (Autoresearch)

Within eight days of launch, autoresearch was ported to:
- MuJoCo robotics simulation
- Adversarial protocol hardening (found compound edge cases missed by 359 hand-written tests)
- Multiple hardware platforms: H100s through Apple Silicon
- Distributed SETI@home-style collaboration with asynchronous inter-GPU agents

## What This Means

AI autonomous research is splitting into two lanes. Deep research agents (OpenAI, Gemini, Perplexity, Claude) handle information synthesis — browsing, reading, cross-referencing, citing. Autoresearch handles experimental discovery — modifying code, running experiments, keeping what works, discarding what does not. Vocabulary layers handle quality constraints — injecting domain expertise as text to steer AI output away from mediocre defaults. All three share the same architecture: humans set direction and taste through text, agents execute autonomously at scale, and quality comes from constraints not from freedom. The organizations and individuals that master this pattern — encoding judgment as text and delegating execution to agents — will operate at a fundamentally different speed than those still doing everything manually.

## Links

- Autoresearch (Karpathy): https://github.com/karpathy/autoresearch
- Autoresearch Deep Dive: https://paddo.dev/blog/autoresearch-overnight-lab/
- Karpathy Loop (Fortune): https://fortune.com/2026/03/17/andrej-karpathy-loop-autonomous-ai-agents-future/
- Autoresearch (VentureBeat): https://venturebeat.com/technology/andrej-karpathys-new-open-source-autoresearch-lets-you-run-hundreds-of-ai
- Autoresearch (The New Stack): https://thenewstack.io/karpathy-autonomous-experiment-loop/
- Impeccable: https://impeccable.style
- Impeccable Design Vocabulary: https://paddo.dev/blog/impeccable-design-vocabulary/
- OpenAI Deep Research: https://openai.com/index/deep-research/
- Perplexity Deep Research vs OpenAI: https://www.clickittech.com/ai/perplexity-deep-research-vs-openai-deep-research/
- Google Deep Research vs Perplexity vs ChatGPT: https://freeacademy.ai/blog/google-deep-research-vs-perplexity-vs-chatgpt-comparison-2026
- Anthropic Conway Platform: https://dataconomy.com/2026/04/03/anthropic-tests-conway-platform-for-continuous-claude/
- Meta Ranking Engineer Agent: https://engineering.fb.com/2026/03/17/developer-tools/ranking-engineer-agent-rea-autonomous-ai-system-accelerating-meta-ads-ranking-innovation/
- Measuring Agent Autonomy (Anthropic): https://www.anthropic.com/research/measuring-agent-autonomy
