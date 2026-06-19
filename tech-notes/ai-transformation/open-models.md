# Open Models

## What is it?

**Open models** (more precisely *open-weight* models) are LLMs whose trained
parameters are published for anyone to download, run, fine-tune, and self-host —
as opposed to *closed* models (GPT, Claude, Gemini) that exist only behind a
vendor API. The distinction that matters in 2026 is not "open source" in the
strict OSI sense — almost none ship training data or the full pipeline — but
**open weights under a permissive license** (MIT or Apache-2.0) that lets a
company download a frontier-class model and run it on its own hardware with no
vendor in the loop.

The story of 2025–2026 is that **open weights stopped being a generation behind
and went almost entirely Chinese.** The labs that matter for open models today —
DeepSeek, Moonshot (Kimi), MiniMax, Zhipu/Z.ai (GLM), Alibaba (Qwen) — are all
Chinese, all shipping MoE models in the 230B–1T parameter range, all optimized
for **agentic coding and tool use**, and all priced at a fraction of the closed
frontier. The Western open contribution narrowed to OpenAI's `gpt-oss`, NVIDIA's
Nemotron, Meta's fading Llama, Europe's Mistral, and Google's Gemma. The catalyzing event was the
**DeepSeek R1 moment** in January 2025 (see below) — the week the market realized
a cheap open model could match a closed reasoning model.

This note connects directly to [[build-vs-buy]] (open weights are the strongest
"build/self-host" option), [[harness-engineering]] (an open model is only as good
as the harness wrapping it), [[token-maxing]] (open weights collapse per-token
cost), and [[rl-environments]] (post-training, not pretraining, is where these
models now win).

## The Numbers

```
┌──────────────────────────────────────────────────────┬─────────────────────────────────┐
│ Metric                                               │ Value                           │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Nvidia market cap wiped in one day (27 Jan 2025) on  │ ~$600 billion (-17%) — biggest  │
│ the DeepSeek R1 news                                 │ 1-day loss ever                 │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ DeepSeek's claimed R1 training cost                  │ ~$6 million                     │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Top open model on the Artificial Analysis Index      │ Kimi K2.6 (~54, #1 open)        │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Largest open-weight MoE from a major lab             │ Kimi K2 — 1T total / ~32B       │
│                                                      │ active                          │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Smallest credible multimodal open model (on-device)  │ Gemma 4 — ~270M–4B, runs on a   │
│                                                      │ phone                           │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Open-weight parameter range (smallest → largest)     │ ~270M (Gemma 4) → 1T (Kimi K2)  │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Open-weight SWE-Bench Pro leaders (mid-2026)         │ MiniMax M3 ~59.0%, GLM-5.1      │
│                                                      │ ~58.4%                          │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Cheapest credible coding model (input/output per 1M) │ DeepSeek V4 Flash ~$0.14 /      │
│                                                      │ $0.28                           │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Sequential tool calls Kimi K2 Thinking sustains      │ 200–300 without a human         │
├──────────────────────────────────────────────────────┼─────────────────────────────────┤
│ Frontier-class open models shipped Apr–Jun 2026      │ 5+ (GLM, Kimi, MiniMax,         │
│                                                      │ DeepSeek, Qwen lines)           │
└──────────────────────────────────────────────────────┴─────────────────────────────────┘
```

A caveat on cadence: these labs ship point releases almost monthly (M2 → M2.5 →
M3; GLM-5 → 5.1 → 5.2; K2 → K2 Thinking → K2.6; DeepSeek V3.2 → V4). Specific
version numbers and scores below are a **snapshot as of June 2026** and will be
stale within weeks. The structural facts — which lab, which license, which
architecture, who's adopting — are the durable part.

## The Contenders

```
┌─────────────┬──────────────┬────────────┬────────────────────────┬──────────────────────────┐
│ Family      │ Lab /        │ License    │ Architecture (params)  │ Position                 │
│             │ Country      │            │                        │                          │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ DeepSeek    │ DeepSeek, CN │ MIT        │ 671B MoE / 37B active, │ Price/perf king; the lab │
│ (V3.2, V4)  │              │            │ sparse attn (DSA)      │ that started it all      │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ Kimi K2     │ Moonshot, CN │ Mod. MIT   │ 1T MoE / ~32B active   │ #1 open on aggregate     │
│ (K2.6)      │              │            │                        │ index; agentic + tools   │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ MiniMax     │ MiniMax, CN  │ MIT/Apache │ ~230B MoE / ~10B       │ Compact, cheap, coding;  │
│ (M2, M3)    │              │            │ active                 │ best $/SWE-bench point   │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ GLM (5.1,   │ Zhipu /      │ MIT        │ ~744B MoE              │ Cleanest license; tops   │
│ 5.2)        │ Z.ai, CN     │            │                        │ SWE-Bench Pro            │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ Qwen        │ Alibaba, CN  │ Apache 2.0 │ MoE + dense, 0.6B–235B │ Widest family; Max/Plus  │
│ (Qwen3.x)   │              │ *          │ (235B/22B active)      │ tiers closed, rest open  │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ Gemma       │ Google, US   │ Gemma **   │ Dense + multimodal,    │ Best Western small /     │
│ (Gemma 4)   │              │            │ ~270M–27B              │ on-device open model;    │
│             │              │            │                        │ from Gemini              │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ Nemotron    │ NVIDIA, US   │ Open       │ Hybrid                 │ Efficiency play; small,  │
│ (Nano 2, 3) │              │ (NVIDIA)   │ Transformer-Mamba MoE, │ high-throughput agents   │
│             │              │            │ 9B/12B                 │                          │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ gpt-oss     │ OpenAI, US   │ Apache 2.0 │ MoE, 21B/3.6B &        │ OpenAI's only open       │
│ (20b, 120b) │              │            │ 117B/5.1B active, 128K │ weights; text-only       │
│             │              │            │                        │ reasoning                │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ Llama 4     │ Meta, US     │ Llama      │ MoE: Scout 109B,       │ Fading; Meta moved       │
│             │              │ Comm. ***  │ Maverick 400B,         │ consumer apps off it;    │
│             │              │            │ Behemoth ~2T total     │ 10M ctx Scout            │
│             │              │            │ (17–288B active)       │                          │
├─────────────┼──────────────┼────────────┼────────────────────────┼──────────────────────────┤
│ Mistral     │ Mistral, FR  │ Apache 2.0 │ 675B MoE / ~41B active │ Europe's flagship open   │
│ Large 3     │ (EU)         │            │                        │ weights; sovereignty     │
│             │              │            │                        │ play                     │
└─────────────┴──────────────┴────────────┴────────────────────────┴──────────────────────────┘
  * Qwen "Max"/"Plus" flagships are closed-weight; the rest of the line is Apache-2.0.
 ** Gemma uses Google's custom Gemma Terms — source-available, not OSI open source.
*** Meta's community license is source-available, not OSI-approved open source.
```

## The DeepSeek Moment (Jan 2025)

```
┌──────────────────────────────────────────────────────────────────────┐
│                 27 January 2025 — the day it broke open                │
│                                                                       │
│   DeepSeek releases R1, an open-weight reasoning model, claiming       │
│   ~o1-level performance trained for ~$6M.                              │
│                          │                                            │
│                          ▼                                            │
│   Nvidia drops 17% in a day — ~$600B erased, the largest single-day   │
│   market-cap loss in history. Whole AI-capex thesis questioned.       │
│                          │                                            │
│                          ▼                                            │
│   "A wake-up call for anyone who thought secrecy and closed           │
│    architectures were the key to US AI leadership."                   │
│                          │                                            │
│                          ▼                                            │
│   The narrative flips: cheap + open + Chinese is now a frontier       │
│   force, not a follower. Every Chinese lab accelerates open releases. │
└──────────────────────────────────────────────────────────────────────┘
```

R1 mattered less for the exact benchmark numbers than for the *demonstration that
the moat was thinner than priced in*. It reframed open weights from "good enough
for hobbyists" to "a strategic threat to a trillion-dollar capex story." Every
trend in this note flows downstream of that week.

## The Models, One by One

**DeepSeek (MIT).** The price/performance anchor of the whole category — a **671B-param MoE
with ~37B active**. V3.2
(Dec 2025) introduced **DeepSeek Sparse Attention (DSA)** to cut long-context
cost while holding quality; it posts MMLU ~88.5 and reasoning near Kimi K2
Thinking / GPT-5 class, with a "Speciale" variant claiming IMO/IOI gold-medal
results. The V4 line pushes agentic coding to the top of the open pack at the
lowest token price (V4 Flash ~$0.14/$0.28 per 1M). MIT-licensed, so commercially
unencumbered. This is the model most teams reach for when cost is the constraint.

**Kimi K2 (Moonshot, modified MIT).** The aggregate-quality leader. A **1T-param
MoE with ~32B active**, built explicitly as an *agentic* model: K2 Thinking
reasons across **200–300 sequential tool calls** without human intervention and
posts SWE-Bench Verified ~71%, Terminal-Bench ~47%, SWE-Multilingual ~61%. K2.6
(Apr 2026) is native-multimodal and tops the neutral Artificial Analysis Index
among open models (~#4 overall). It's the open model most often *repackaged* by
Western tools — Cursor, Cloudflare, Perplexity.

**MiniMax (MIT/Apache).** The efficiency specialist: ~230B total but only ~10B
active, which makes it cheap to serve. M2 posts a strong agentic index (~56) at
~$0.255/$1.00; the M3 line (mid-2026) claims native multimodality, ~1M context,
and the **top open-weight SWE-Bench Pro (~59%)** — the cheapest model clearing
~80% on SWE-bench Verified. The pick when you want frontier-ish coding on a
budget and a small activated footprint.

**GLM / Z.ai (MIT).** The license story plus top-tier coding. ~744B MoE; GLM-5.1
(Apr 2026) hit **#1 on SWE-Bench Pro (~58.4)**, nudging past GPT-5.4 and Claude
Opus 4.6 on that benchmark, and reportedly delivering ~95% of Claude Opus coding
performance. GLM-5.2 (Jun 2026) added a **1M-token context**. The clean **MIT
license** is the differentiator for enterprises that want to fine-tune and ship
commercially with zero ambiguity.

**Qwen (Alibaba, Apache-2.0 — mostly).** The broadest, most-deployed family:
sizes from 0.5B dense up to 235B+ MoE, almost all under **Apache-2.0**. The
catch: the flagship **"Max" and "Plus" tiers are closed-weight**, API-only via
Alibaba Cloud. Qwen3.7 Max (May 2026) ranks ~#5 on the Artificial Analysis Index
with 1M context and 35-hour autonomous runs, but you can't download it. Qwen's
open dense models are the default for **local/private coding assistants**.

**Nemotron / "N2" (NVIDIA, open).** NVIDIA's efficiency line. **Nemotron Nano 2**
(9B/12B) uses a **hybrid Transformer-Mamba** architecture for high throughput and
low latency — built for cheap, fast, *many*-agent systems rather than single
giant calls. The Nemotron 3 family (Nano/Super/Ultra) extends this. NVIDIA's
incentive is obvious: open models that sell GPUs.

**gpt-oss (OpenAI, Apache-2.0).** OpenAI's only open-weight release: `gpt-oss-20b`
and `gpt-oss-120b` (both MoE: 21B-total/3.6B-active and 117B-total/5.1B-active),
Apache-2.0, 128K context, **text-only** reasoning. Solid and
genuinely unrestricted, but a generation behind the Chinese frontier on agentic
coding and with no multimodality.

**Gemma 4 (Google, Gemma license).** Google's open-weight family, distilled
from the same research as Gemini. A **dense, multimodal line spanning ~270M to
~27B** — deliberately small enough to run on a single GPU, a laptop, or a phone,
which is the entire point. Gemma 3's 27B already posted a top-tier **LMArena Elo
(~1338)** and broad multilingual coverage (140+ languages) while staying
single-GPU; Gemma 4 extends that with sharper multimodal reasoning, ~128K
context, and stronger small-model results (MMLU-Pro ~67 at 27B). It is **not** an
agentic-coding contender — it trails the Chinese MoE leaders badly on SWE-Bench
and long-horizon tool use — but it is the best Western *small / on-device* open
model and the easiest to embed. The catch is the **Gemma Terms of Use**:
commercial use is allowed, but it is a custom Google license with a
prohibited-use policy, *not* Apache/MIT or OSI open source — read it like
Llama's, not DeepSeek's.

**Llama 4 (Meta, community license).** The former open-weight king, now fading.
Scout (109B total / 17B active), Maverick (400B / 17B active), and Behemoth
(~2T / 288B active) launched Apr 2025 under Meta's
**source-available community license** (not OSI open source). By 2026 Meta moved
its own consumer apps *off* Llama, and the model trails the latest closed and
Chinese-open frontier on most tasks.

**Mistral Large 3 (Apr/Dec 2025, Apache-2.0).** Europe's flagship: a **675B MoE
(~41B active)**, 256K context, Apache-2.0, strong on academic benchmarks
(MMLU-Pro ~73, MATH-500 ~94). Paired with Magistral (reasoning), Pixtral
(vision), Devstral (coding). The story here is **sovereignty** — an EU lab buying
its own GPUs for an EU datacenter, the non-Chinese, non-US open option.

## Benchmarks (snapshot, mid-2026)

```
┌──────────────────────┬──────────────┬──────────────┬──────────────────────┬────────────────┐
│ Model (params)       │ AA Intel.    │ SWE-Bench    │ Coding / agentic     │ Notable        │
│                      │ Index (~)    │ Pro (~)      │ headline             │ context win    │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ Kimi K2.6 (1T / 32B  │ ~54 (#1      │ —            │ SWE-V ~71%, Term-B   │ 200–300 tool   │
│ act)                 │ open)        │              │ ~47%                 │ calls          │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ GLM-5.1 / 5.2        │ high         │ ~58.4 (#1)   │ ~95% of Opus coding  │ 1M ctx (5.2)   │
│ (~744B)              │              │              │                      │                │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ MiniMax M3 (~230B /  │ ~38 (M2.7)   │ ~59.0 (#1    │ cheapest >80% SWE-V  │ 1M ctx,        │
│ 10B)                 │              │ open)        │                      │ multimodal     │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ DeepSeek V3.2/V4     │ ~GPT-5 class │ V4 Pro leads │ MMLU ~88.5; IMO/IOI  │ DSA sparse     │
│ (671B / 37B)         │ on reasoning │ agentic open │ gold                 │ attention      │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ Qwen3.7 Max *        │ ~56.6 (#5    │ —            │ 35-hr run, 1,158     │ 1M ctx         │
│ (closed)             │ overall)     │              │ calls                │                │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ Gemma 4 (~270M–27B)  │ — (not       │ —            │ LMArena Elo ~1338    │ 128K ctx,      │
│                      │ agentic)     │              │ (27B); MMLU-Pro ~67  │ multimodal,    │
│                      │              │              │                      │ on-device      │
├──────────────────────┼──────────────┼──────────────┼──────────────────────┼────────────────┤
│ Mistral Large 3      │ ~48          │ —            │ MMLU-Pro ~73,        │ 256K ctx       │
│ (675B / 41B)         │ (BenchLM)    │              │ MATH-500 ~94         │                │
└──────────────────────┴──────────────┴──────────────┴──────────────────────┴────────────────┘
  Numbers are approximate, vendor- and aggregator-reported, and move monthly.
  Treat as ordering, not gospel — verify on Artificial Analysis / OpenRouter live.
```

## Who Is Using Them

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Adopter           │ What they're doing                                   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Airbnb            │ Runs ~13 models; leans heavily on Alibaba's Qwen for │
│                   │ customer-service chat — cited cost + parity with US  │
│                   │ models over ChatGPT.                                  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Cursor            │ Repackaged Kimi K2 into the IDE-native coding harness;│
│                   │ Chinese open weights inside the hottest dev tool.     │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Perplexity        │ Added Kimi as its first Chinese / open model; routes  │
│                   │ Deep Research subtasks across 20+ frontier models.    │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Cloudflare        │ Introduced Kimi as a main model on its inference edge.│
├──────────────────┼──────────────────────────────────────────────────────┤
│ Self-hosting orgs │ Pick DeepSeek / MiniMax for best $-per-quality on own │
│ (cost-driven)     │ GPUs; MIT/Apache licenses make commercial use clean.  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ NVIDIA            │ Ships Nemotron open weights to drive GPU demand — the │
│                   │ supplier seeding the ecosystem that buys its hardware.│
├──────────────────┼──────────────────────────────────────────────────────┤
│ EU / sovereignty  │ Reach for Mistral Large 3 to keep weights, data, and │
│ buyers            │ inference inside European jurisdiction.               │
└──────────────────┴──────────────────────────────────────────────────────┘
```

Demand has gotten tight enough that some large companies now **pre-order capacity**
for Kimi access inside their coding tools — an open model with a waitlist.

## Licensing Matters

The license is half the product. For a company that wants to fine-tune and ship,
the gradient runs from "do whatever" to "ask permission":

```
┌────────────────────────┬────────────────────────────────────────────────┐
│ License                │ Practical meaning                              │
├────────────────────────┼────────────────────────────────────────────────┤
│ MIT (DeepSeek, GLM)    │ Do anything, commercial, no royalties, minimal │
│                        │ obligations. The cleanest for enterprise.      │
├────────────────────────┼────────────────────────────────────────────────┤
│ Apache-2.0 (Qwen*,     │ Like MIT + explicit patent grant. Also fully   │
│ Mistral, gpt-oss)      │ commercial. The other "safe" choice.           │
├────────────────────────┼────────────────────────────────────────────────┤
│ Modified MIT (Kimi K2) │ MIT-ish with an attribution/branding clause at │
│                        │ very large scale. Fine for nearly everyone.    │
├────────────────────────┼────────────────────────────────────────────────┤
│ Vendor community       │ Source-available, NOT OSI open source; usage   │
│ (Llama, Nemotron,      │ caps / acceptable-use carve-outs apply.        │
│ Gemma)                 │                                                │
├────────────────────────┼────────────────────────────────────────────────┤
│ Closed-weight (Qwen    │ API-only. Open *family* branding, closed       │
│ Max/Plus)              │ flagship. Read the tier, not the family name.  │
└────────────────────────┴────────────────────────────────────────────────┘
```

The headline irony of 2026: the **most permissively licensed frontier models are
Chinese** (MIT for DeepSeek and GLM), while the most capable Western models are
either closed (GPT, Claude, Gemini) or carry a non-OSI community license (Llama).

## Pros

- **Cost collapse.** Self-hosting or cheap API access takes per-token cost down
  10–50x versus the closed frontier. This is the [[token-maxing]] release valve —
  agentic workloads that burn billions of tokens become affordable.
- **No vendor lock-in.** You hold the weights. No deprecation surprise, no
  rate-limit at the worst moment, no silent model swap under your feature.
- **Data sovereignty / privacy.** Inference on your own hardware means prompts and
  proprietary code never leave your network — the deciding factor for regulated
  and sovereignty-conscious buyers.
- **Fine-tunable.** With MIT/Apache weights you can specialize on your domain —
  the [[rl-environments]] thesis applied in-house.
- **Auditability.** You can inspect, quantize, and instrument the model instead of
  trusting a black-box endpoint.
- **Agentic-first design.** The Chinese open leaders are built for tool use and
  long-horizon coding out of the box — they slot straight into a [[harness-engineering|harness]].

## Cons

- **Frontier gap (narrow but real).** The very best closed models (GPT-5.x, Claude
  Opus 4.x, Gemini 3.x) still edge open weights on the hardest reasoning and
  multimodal tasks. Open *leads* on price/perf, not on the absolute ceiling.
- **Self-hosting is hard and expensive.** A 1T-param MoE needs serious GPU memory;
  "free weights" still means a large infra and ops bill. Most teams end up renting
  hosted open-model APIs anyway.
- **Geopolitical / data risk.** Using Chinese models *via the vendor's API* sends
  data to China; even self-hosted, some orgs face procurement bans. (Self-hosting
  the weights removes the data-flow risk but not the policy risk.)
- **Version whiplash.** Monthly point releases mean benchmarks, prices, and "best
  pick" churn constantly — hard to standardize on.
- **Benchmark noise.** Vendor- and SEO-reported scores are inconsistent and
  sometimes inflated; the [[ai-slop-crisis|slop]] problem extends to model
  marketing. Trust neutral aggregators, not blog claims.
- **License traps.** "Open" branding hides closed flagships (Qwen Max) and non-OSI
  community licenses (Llama). Read the specific weight's license.

## The China Question

The strategic subtext is unavoidable: **open-weight AI in 2026 is largely a
Chinese export.** The U.S.-China Economic and Security Review Commission's "Two
Loops" report frames China's open-AI strategy as deliberate industrial policy —
give away strong weights, capture global developer mindshare and downstream
dependence, reinforce domestic hardware and tooling. For a buyer this creates a
genuine fork:

```
┌──────────────────────────────────────────────────────────────────────┐
│   Self-host Chinese open weights:  cheap, private, no data leaves —  │
│      but procurement / policy may still forbid it.                   │
│                                                                      │
│   Use Chinese models via vendor API:  cheapest + easiest —           │
│      but prompts/code flow to China. Often a hard no for regulated.  │
│                                                                      │
│   Use Western open (gpt-oss, Gemma, Mistral, Nemotron):  safer —     │
│      but a step behind on agentic coding, or smaller.                │
│                                                                      │
│   Use Western closed (GPT/Claude/Gemini):  top ceiling —             │
│      but maximum cost and lock-in.                                   │
└──────────────────────────────────────────────────────────────────────┘
```

There is no free lunch; the choice is which constraint you optimize for.

## What This Means

Open models have completed the move from "fast follower" to "frontier-adjacent at
a tenth of the price." For most teams the practical question is no longer *"is
open good enough?"* — for agentic coding it demonstrably is — but *"which
constraint dominates: cost, sovereignty, ceiling, or policy?"* That answer routes
you to a specific model:

- **Cost above all →** DeepSeek / MiniMax (MIT, cheapest, strong coding).
- **Best open quality →** Kimi K2 (aggregate #1, agentic, tool-heavy).
- **Top coding + clean license →** GLM (MIT, SWE-Bench Pro leader).
- **Local / private dense model →** Qwen open tiers (Apache, every size).
- **Western / sovereignty →** Mistral (EU), or gpt-oss / Gemma / Nemotron (US).

The deeper shift is that **the model is no longer the moat** — it's becoming a
commodity input. When a frontier-class coder is MIT-licensed and a tenth the
price, the durable advantage moves up the stack to the [[harness-engineering|harness]],
the [[rl-environments|evals and environments]], and the [[build-vs-buy|build-vs-buy]]
discipline around them. Owning the weights is table stakes; knowing what to *do*
with them is the work. That is also what makes the [[one-person-unicorn]] and
[[ai-native-engineering]] theses economically real: the raw intelligence is now
cheap enough that a very small team can afford to run a lot of it.

## Links

- Why NVIDIA's share price dropped 17% after DeepSeek news (IG): https://www.ig.com/en/news-and-trade-ideas/why-nvidia-s-share-price-dropped-17--after-deepseek-news-250128
- Two Loops: How China's Open AI Strategy Reinforces Its Industrial Dominance (USCC): https://www.uscc.gov/sites/default/files/2026-03/Two_Loops--How_Chinas_Open_AI_Strategy_Reinforces_Its_Industrial_Dominance.pdf
- DeepSeek-V3.2: Pushing the Frontier of Open Large Language Models (arXiv): https://arxiv.org/html/2512.02556v1
- A Technical Tour of the DeepSeek Models from V3 to V3.2 (Sebastian Raschka): https://magazine.sebastianraschka.com/p/technical-deepseek
- The Complete Guide to DeepSeek Models: V3, R1, V4 and Beyond (BentoML): https://www.bentoml.com/blog/the-complete-guide-to-deepseek-models-from-v3-to-r1-and-beyond
- Kimi K2: Open Agentic Intelligence (Moonshot): https://moonshotai.github.io/Kimi-K2/
- Introducing Kimi K2 Thinking (Moonshot): https://moonshotai.github.io/Kimi-K2/thinking.html
- moonshotai/Kimi-K2-Thinking (Hugging Face): https://huggingface.co/moonshotai/Kimi-K2-Thinking
- AINews — Moonshot Kimi K2.6: the world's leading Open Model (Latent Space): https://www.latent.space/p/ainews-moonshot-kimi-k26-the-worlds
- MiniMax M2 — API Pricing & Benchmarks (OpenRouter): https://openrouter.ai/minimax/minimax-m2
- MiniMax M2.5: Open Weights Models Catch Up to Claude Sonnet (OpenHands): https://www.openhands.dev/blog/minimax-m2-5-open-weights-models-catch-up-to-claude
- MiniMax-M2 — Intelligence, Performance & Price (Artificial Analysis): https://artificialanalysis.ai/models/minimax-m2-7
- GLM-5.1 Review: 94.6% of Claude Opus 4.6 Coding Performance (Serenities AI): https://serenitiesai.com/articles/glm-5-1-zhipu-coding-benchmark-claude-opus-comparison-2026
- GLM-5.2 Open Weights Live: Top Coding Benchmark, but API Use Carries China Data Risk (TechTimes): https://www.techtimes.com/articles/318543/20260617/glm-52-open-weights-live-top-coding-benchmark-api-use-carries-china-data-risk.htm
- Alibaba's Qwen 3.7 Max Becomes Highest-Placed Chinese Model on Artificial Analysis Index (OfficeChai): https://officechai.com/ai/qwen-3-7-max-benchmarks/
- Best Qwen Models in 2026 (Remote OpenClaw): https://www.remoteopenclaw.com/blog/best-qwen-models-2026
- NVIDIA Debuts Nemotron 3 Family of Open Models (NVIDIA Newsroom): https://nvidianews.nvidia.com/news/nvidia-debuts-nemotron-3-family-of-open-models
- nvidia/NVIDIA-Nemotron-Nano-12B-v2 (Hugging Face): https://huggingface.co/nvidia/NVIDIA-Nemotron-Nano-12B-v2
- Gemma 3 Technical Report (Google DeepMind): https://storage.googleapis.com/deepmind-media/gemma/Gemma3Report.pdf
- Welcome Gemma 3 (Hugging Face): https://huggingface.co/blog/gemma3
- Gemma open models — docs & sizes (Google AI for Developers): https://ai.google.dev/gemma
- The Best Open Source and Open-Weight LLM Models to Run Locally in 2026 (Hugging Face): https://huggingface.co/blog/daya-shankar/open-source-llm-models-to-run-locally
- Mistral Large 3: An Open-Source MoE LLM Explained (IntuitionLabs): https://intuitionlabs.ai/articles/mistral-large-3-moe-llm-explained
- Mistral Large 3 — Benchmarks, Pricing & Context Window (LLM-Stats): https://llm-stats.com/models/mistral-large-3-2509
- Best Chinese LLMs in 2026: DeepSeek V4, Kimi K2.6, GLM-5, Qwen (BenchLM): https://benchlm.ai/blog/posts/best-chinese-llm
- The Best Open-Source LLMs for Agentic Coding in 2026 (MindStudio): https://www.mindstudio.ai/blog/best-open-source-llms-agentic-coding-2026
- Open LLM Leaderboard 2026 (LLM-Stats): https://llm-stats.com/leaderboards/open-llm-leaderboard
- Airbnb opts for Chinese AI model over ChatGPT (MarketScreener): https://www.marketscreener.com/news/airbnb-opts-for-chinese-ai-model-over-chatgpt-ce7d5ddedf89f221
- Open-Source Model Inference Buying Guide: GLM-5.1, DeepSeek V4 Pro, Kimi K2.6 (Yage): https://yage.ai/share/ollama-cloud-vs-api-vs-subscriptions-en-20260428.html
