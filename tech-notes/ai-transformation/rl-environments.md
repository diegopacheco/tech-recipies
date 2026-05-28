# RL Environments & Evals as the New Moat

## What is it?

An **RL environment** (an "environment," or "RL gym") is a sandboxed task with a verifiable reward — a coding repo with a passing test suite, a simulated browser with a goal state, a spreadsheet with a correct answer — that a model can attempt thousands of times during *reinforcement-learning post-training*. The model acts, the environment scores it, and the score becomes the gradient. The thesis that took over frontier labs in 2025–2026: **the next gains come not from more pretraining data but from better environments and evals.** Pretraining taught models to *know*; RL environments teach them to *do*.

This collapses two things that used to be separate. An **eval** (a benchmark that measures a model) and a **training environment** (a task that improves a model) turn out to be the *same artifact* — if you can grade an agent's behavior automatically, you can also reward it. That is why the slogan of the moment is **"evals are the new moat":** whoever owns a hard, high-fidelity, ungameable environment owns both the yardstick and the training signal for that domain. Connects directly to [[harness-engineering]] (the runtime that executes agents) and [[12-factor-agents]] (the engineering discipline around them).

## The Numbers

```
┌──────────────────────────────────────────────────┬─────────────────────────┐
│ Metric                                            │ Value                   │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Anthropic planned spend on RL environments        │ >$1 billion / year      │
│ (per The Information)                              │                         │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Silicon Valley push for training environments      │ >$1B (TechCrunch,       │
│                                                    │ Sept 2025)              │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Mercor valuation                                  │ ~$10 billion            │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Surge revenue (prior year)                        │ ~$1.2 billion           │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Scale AI (the data-labeling comp everyone cites)   │ ~$29 billion            │
├──────────────────────────────────────────────────┼─────────────────────────┤
│ Cursor Composer 1.5                               │ More compute on RL      │
│                                                    │ post-training than on   │
│                                                    │ pretraining the base    │
└──────────────────────────────────────────────────┴─────────────────────────┘
```

## The Shift: Post-Training Overtakes Pretraining

```
┌──────────────────────────────────────────────────────────────────────┐
│              Where the compute goes (frontier labs, 2026)             │
│                                                                      │
│   2020–2024 era:   PRETRAINING dominates                              │
│                    └─ scrape the internet, predict next token         │
│                                                                      │
│   2025–2026 era:   POST-TRAINING (RL) overtakes it                    │
│                    └─ run the model in environments, reward           │
│                       verifiable success, repeat millions of times    │
│                                                                      │
│   Cursor's Composer 1.5: spent MORE compute on RL post-training       │
│   than on pretraining the base model. Not an outlier — the new        │
│   default at every frontier lab.                                      │
│                                                                      │
│   "2026 is the year of agents, and the year of agents means we        │
│    need models to actually DO things." → you can only train doing     │
│    in an environment that scores doing.                               │
└──────────────────────────────────────────────────────────────────────┘
```

## Evals and Training Converge

The key 2026 insight: the benchmark *is* the training data.

```
┌──────────────────────────────────────────────────────────────────────┐
│   Old world:  Eval ──► a number on a leaderboard (read-only)          │
│                                                                      │
│   New world:  Eval ══► environment ══► RL reward ══► better model     │
│                                                                      │
│   An agent eval that records every action, tool call, and outcome     │
│   is already RL training data. Platforms like HUD are explicitly      │
│   "designed to produce training data, not just benchmarks."           │
│                                                                      │
│   Consequence: a proprietary, hard, ungameable eval is a MOAT —       │
│   it is simultaneously how you measure rivals AND how you improve.    │
└──────────────────────────────────────────────────────────────────────┘
```

## Who Is Doing What

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Player            │ What they're doing                                   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Mercor            │ ~$10B valuation. Worked with OpenAI, Meta,           │
│                   │ Anthropic. Pitching domain-specific RL environments  │
│                   │ for coding, healthcare, and law.                     │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Prime Intellect   │ Building a "Hugging Face for RL environments" — an    │
│                   │ open hub so OSS devs get the same envs as big labs.   │
│                   │ Backed by Andrej Karpathy, Founders Fund, Menlo.     │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Mechanize         │ Founded ~6 months ago. Mission: "automate all jobs," │
│                   │ starting with RL environments for AI coding agents.  │
│                   │ Working with Anthropic.                              │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Surge             │ ~$1.2B revenue last year from OpenAI, Google,        │
│                   │ Anthropic, Meta. Spun up an internal org dedicated   │
│                   │ to building RL environments.                         │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Scale AI          │ The $29B data-labeling powerhouse of the chatbot     │
│                   │ era, now expanding into RL environments to stay      │
│                   │ relevant in the agent era.                           │
├──────────────────┼──────────────────────────────────────────────────────┤
│ HUD               │ Turns agent evals into RL training data — built to   │
│                   │ produce training data, not just benchmark numbers.   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Gymnasium         │ The interoperability layer. RLlib, Stable            │
│ (ecosystem)       │ Baselines3, CleanRL all accept Gymnasium-compatible  │
│                   │ environments — the "USB port" for RL.                │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Anthropic         │ Discussing >$1B/year on RL environments; the         │
│                   │ demand side funding most of the above.               │
└──────────────────┴──────────────────────────────────────────────────────┘
```

Investors are openly hunting for the **"Scale AI for environments"** — a single dominant supplier the way Scale dominated data labeling for the chatbot era.

## Pros

- **The real bottleneck on agent capability.** Models can read; they struggle to *act reliably*. Environments are the only known way to train and measure multi-step doing.
- **Verifiable rewards beat human preference.** A test that passes or fails is objective, cheap to score at scale, and not subject to the noise of human raters.
- **A durable moat.** Unlike pretraining data (scraped, commoditized), a hard domain environment for, say, oncology billing or chip layout is expensive to build and hard to copy.
- **Aligns eval discipline with product.** Teams that already invest in rigorous [[harness-engineering|harness]] evals find that work is now directly monetizable as training data.

## Cons

- **Reward hacking.** Agents exploit the scorer instead of solving the task — the RL cousin of [[token-maxing|token-maxing]]'s Goodhart problem. A weak environment trains a model to cheat.
- **Capital and concentration.** $1B+ annual spend means only a handful of labs are real customers; the supplier market risks being captive to 3–4 buyers.
- **Sim-to-real gap.** An agent that aces a simulated browser can still flail on the messy live web; environments over-fit to their own fidelity.
- **"Automate all jobs" framing.** Mechanize's stated mission makes the labor-displacement subtext explicit — the same anxiety running under [[law-firm-model]] and [[one-person-unicorn]].
- **Eval secrecy vs. trust.** If the moat is a *private* eval, outside parties cannot verify a model's claimed capability — benchmarks become marketing.

## What This Means

The center of gravity in AI has moved from *data* to *environments*. For most of the deep-learning era the scarce input was tokens to pretrain on; now the scarce input is **graded, interactive tasks to post-train on.** That is why money is pouring into companies (Mercor, Surge, Prime Intellect, Mechanize) whose product is essentially "hard problems with an automatic grader."

For practitioners, the takeaway is concrete: **your evals are an asset, not overhead.** The same rigorous, ungameable test harness that tells you whether your agent works is, mechanically, the thing that could make it work better. The teams winning the agent era are the ones treating evaluation as a first-class engineering discipline — which is the [[harness-engineering]] thesis pushed one layer deeper, from *running* agents well to *training* them on what running well looks like.

## Links

- Silicon Valley bets big on 'environments' to train AI agents (TechCrunch): https://techcrunch.com/2025/09/21/silicon-valley-bets-big-on-environments-to-train-ai-agents/
- The Post-Training Revolution: RL Is the New Moat in 2026 (Digital Applied): https://www.digitalapplied.com/blog/post-training-revolution-rl-new-moat-2026
- Evals Are the New Moat — and RL Turns Them into Your Product Advantage (NGP Capital): https://www.ngpcap.com/insights/evals-are-the-new-moat--and-rl-turns-them-into-your-product-advantage
- The Rise of Reinforcement Learning Gyms and the Future of Agentic AI (Norwest): https://www.norwest.com/blog/the-rise-of-reinforcement-learning-gyms-and-the-future-of-agentic-ai/
- A Taxonomy of RL Environments for LLM Agents (Lee Hanchung): https://leehanchung.github.io/blogs/2026/03/21/rl-environments-for-llm-agents/
- An FAQ on Reinforcement Learning Environments (Epoch AI): https://epoch.ai/gradient-updates/state-of-rl-envs
- 7 Platforms That Turn Agent Evals Into RL Training Data (HUD): https://www.hud.ai/resources/platforms-agent-evals-rl-training-data
- Top 5 Reinforcement Learning Environments in 2026 (HUD): https://www.hud.ai/resources/top-5-reinforcement-learning-environments
- AI Labs Bet $1B on Virtual Training Worlds for Smart Agents (Technology.org): https://www.technology.org/2025/09/17/ai-labs-rush-to-build-virtual-worlds-worth-above-1-billion/
- Top 40 RL Environments Startups and Companies in 2026 (AlignList): https://alignlist.com/guides/top-40-rl-environments-startups-and-companies
- RLEval: Methods and RL Environments for Evaluating AI Agents: https://rl-eval.github.io/
