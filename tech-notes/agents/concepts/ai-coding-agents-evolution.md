# AI coding Agents Evolution

Not necessarily in perfect timeline order, but we can see the evolution of AI coding agents in 4 waves, with some retrofitting in between.

<img src="ai-coding-agents-evolutions.png" width="600">

# Wave 1 - Pure AI coding Tools

Claude code, Codex and gemini CLI.

## Wave 2 - Frameworks on top of AI Coding Tools

Ralph, OMC, GSD, Continuous Claude

## Wave 3 - Multi-Agent Solutions

Gastown, Claude Flow, Superclaude

## Wave 4 - Threads

Cursor, Superset and Conductor.

## Retrofit 

Claude Teams -> Multi-agents like Claude Flow, Gastown, Superclaude
Codex App -> Threads like Cursor, Superset and Conductor.

## AI Evolution

Here is a bigger picture of evolution of AI. Nobody knows the future but my guess (as 2026) it's robotics. Perhaps there will be a correction or slight rollback, I said that in 2025.

<img src="ai-evolution-2026.png" width="600">

Why Rollback?
* Hype = Unrealistic Expectations
* No more Data (Synthetic data don't work well in all domains)
* Throwing more hardware does not do the trick anymore (Diminishing returns)
* We still rely on training, LLMs still cannot learn
* Token usage keeps increasing
* Models keep getting more expensive
* Researchers don't see a way out unless there is a breakthrough
* We already stalling since last year and changes are incremental
* What happens if is not sustainable? (like crypto, web3, metaverse)
* What happens when company realize they will not get 100x or even 10x so easily as productivity gains?
* Last year(2025) everybody want to get rid of juniors, this year is the middle level - what will be next year? everybody hiring again :D
* Anti-AI Movements keep growing

## What you think about this doc: Opus 4.6 / Claude Code? 

First run the model only focus on my typos, them I poke why did you not comment on the rollback - and I got this:
```
⏺ All typos fixed. Now about your question on the rollback/correction part:

Fair catch. I'm an AI - of course I'm not going to volunteer "yeah this whole thing might collapse." But honestly, your rollback
thesis has merit. The bullet points are real concerns that many researchers and engineers share. The parallel to
crypto/web3/metaverse hype cycles is relevant. Each of those had real technology underneath but the expectations outpaced
reality.

The points that hit hardest:
- Diminishing returns on hardware - scaling laws are showing cracks
- LLMs still can't learn - we're stuck on training-time knowledge, no real online learning
- Sustainability question - if companies don't see the ROI, budgets shrink fast
- The hiring cycle joke - that's probably the most honest observation in the whole doc

Whether it's a full rollback or just a correction/plateau is the real question. My bet (if I could bet) would be correction
rather than collapse - the tooling is genuinely useful, just not as transformative as the hype suggests.
```

## Frameworks and Size

```
┌─────┬─────────────────────────┬────────────┬────────┬─────────┬───────────┐
│  #  │        Framework        │   Tokens   │ % ctxw │  Lines  │   Chars   │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 1   │ GSD                     │ 283,800    │ 141.9% │ 7,500   │ 1,135,000 │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 2   │ SuperClaude             │ 80,000     │ 40%    │ 6,700   │ 270,000   │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 3   │ OMC                     │ 31,600     │ 15.8%  │ 3,195   │ 126,500   │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 4   │ Claude Flow             │ ~16,000    │ 8%     │ 1,000   │ 59,000    │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 5   │ Ralph Wiggum            │ 7,000      │ 3.5%   │ 745     │ 24,308    │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 6   │ BMAD                    │ 6,000 base │ 3%     │ 156,840 │ 5,454,268 │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 7   │ Claude Reflect          │ 3,150      │ 1.6%   │ 2,273   │ 91,219    │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 8   │ Continuous Claude       │ ~430       │ 0.21%  │ 2,314   │ 86,550    │
├─────┼─────────────────────────┼────────────┼────────┼─────────┼───────────┤
│ 9   │ Diego Pacheco CLAUDE.md │ 354        │ 0.18%  │ 34      │ 1,528     │
└─────┴─────────────────────────┴────────────┴────────┴─────────┴───────────┘
```

- GSD exceeds the entire context window (141.9%) — it can't even fit
- SuperClaude eats 40% before you type anything
- BMAD is deceptive: 6K base but 1.36M tokens fully loaded (680% of ctxw) — the 156K lines / 5.4M chars confirm that
- Claude Reflect similarly has a loaded variant at 25,600 tokens (12.8%)

## Links

OMC: https://github.com/Yeachan-Heo/oh-my-claudecode

The biggest culprits are the 32 agent definition files (~24,500 tokens alone) and the 40 MCP tool schemas (~6,250 tokens).

SuperClaude: https://github.com/SuperClaude-Org/SuperClaude_Framework

That's a significant chunk. Claude Opus has a 200K token context window, so SuperClaude is eating roughly 33-40% of your
available context before you even send your first message

GSD: https://github.com/gsd-build/get-shit-done

BMAD: https://github.com/bmad-code-org/BMAD-METHOD

OMC: https://github.com/Yeachan-Heo/oh-my-claudecode

Continuous Claude: https://github.com/AnandChowdhary/continuous-claude

Claude Flow: https://github.com/ruvnet/claude-flow

The heaviest offenders:
1. Task tool agent descriptions (~7K tokens) — 50+ agent type definitions
2. Skills registry (~4K tokens) — 70+ skill listings
3. MCP deferred tools (~3K tokens) — 200 tool names
4. CLAUDE.md (~1.8K tokens) — project instructions

Claude Reflect https://github.com/BayramAnnakov/claude-reflect

Ralph Wiggin: https://github.com/anthropics/claude-code/tree/main/plugins/ralph-wiggum