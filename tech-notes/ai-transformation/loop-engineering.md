# Loop Engineering

## What is it?

**Loop engineering** is the practice of designing the system that prompts your coding agent, instead of typing every prompt yourself. Addy Osmani's one line: *"Loop engineering is replacing yourself as the person who prompts the agent. You design the system that does it instead."* A loop is a recursive goal — you define a purpose, and the agent iterates until it is complete, with no human turn in between.

For roughly two years the workflow was high-effort ping-pong: you write a prompt, share context, read what came back, write the next prompt. Your attention is the engine; step away from the keyboard and the agent freezes mid-turn. Loop engineering is the move where you **stop being the engine**. You write a small program — a shell loop, a hosted task, or a few hundred lines of TypeScript — and *that* program talks to the model. It picks the next task, dispatches it, grades the result, logs the outcome, and decides whether to fire again. The model is no longer a chat partner; it is a function called inside a `while`.

The reframing: where prompt engineering asks *"What should I say to get the best output?"*, loop engineering asks *"What system should I build so the agent finds the work, does it, verifies it, and remembers what it did — without me in the loop at all?"*

## The quotes that started it

The term went mainstream in June 2026 off three near-simultaneous statements.

```
┌────────────┬──────────────────────┬─────────────────────────────────────────────┐
│ Date       │ Who                  │ What they said                              │
├────────────┼──────────────────────┼─────────────────────────────────────────────┤
│ ~Jun 5     │ Boris Cherny         │ "I don't prompt Claude anymore. I have      │
│ 2026       │ creator/head of      │ loops that are running. They're the ones    │
│            │ Claude Code,         │ prompting Claude and figuring out what to   │
│            │ Anthropic            │ do. My job is to write loops." (on stage)   │
├────────────┼──────────────────────┼─────────────────────────────────────────────┤
│ Jun 7      │ Peter Steinberger    │ "You shouldn't be prompting coding agents   │
│ 2026       │ founder PSPDFKit /   │ anymore. You should be designing loops that │
│            │ Nutrient             │ prompt your agents." (~2.2M views; tech     │
│            │                      │ Twitter fight over what it meant)           │
├────────────┼──────────────────────┼─────────────────────────────────────────────┤
│ Jun 2026   │ Addy Osmani          │ Synthesized both into "loop engineering"    │
│            │ eng lead, Google     │ across his blog + Substack; named the layer │
│            │ Chrome               │ and mapped it onto shipping products.       │
└────────────┴──────────────────────┴─────────────────────────────────────────────┘
```

What surprised Osmani is that this is *no longer a tooling project*. A year ago, a loop was a pile of bash you wrote and maintained forever and that was yours alone. Now the pieces ship inside the products — Steinberger's list maps almost exactly onto the OpenAI Codex app, and almost the same onto Claude Code. Once you see the shape is identical you stop arguing about which tool and just design a loop that works no matter which one you happen to be sitting in.

## Where it sits in the stack

Loop engineering is the floor above the harness. Each layer wraps the one below it.

```
┌──────────────────────────────────────────────────────────────────────┐
│  LOOP ENGINEERING   the harness on a timer: it spawns helpers,        │
│                     feeds itself, and decides the next task            │
│  ──────────────────────────────────────────────────────────────────   │
│  HARNESS ENGINEERING  the environment ONE agent runs inside:          │
│                       context, tools, sandbox, permissions, memory    │
│  ──────────────────────────────────────────────────────────────────   │
│  AGENTIC ENGINEERING  give the model hands and tools                  │
│  ──────────────────────────────────────────────────────────────────   │
│  PROMPT ENGINEERING   phrase one turn well (now table stakes)         │
└──────────────────────────────────────────────────────────────────────┘
```

Prompt engineering is not dead — it is the bottom rung, and prompting directly still works. The point of Cherny's quote is not that the work got *easier*; it is that the **leverage point moved** from phrasing to system design. See [[harness-engineering]] and [[harness-patterns]] for the layer underneath.

## How it works — the core cycle

At the center of every loop, regardless of scale, is the same four-step cycle:

```
        ┌──────────────────────────────────────────┐
        │                                          │
        ▼                                          │
    act  ──►  observe  ──►  reason  ──►  repeat? ───┘
   do a      read what     decide what    until the goal
   thing     came back     it means vs    is met (or a
                           the goal       guard trips)
```

Everything else — the schedule, the worktrees, the sub-agents, the state file — is scaffolding around that cycle. This is the same act-observe-reason loop the [[12-factor-agents]] and [[rl-environments]] notes describe; loop engineering is the discipline of making each stage *explicit and tunable* instead of letting it emerge implicitly inside one long prompt.

## The five pieces (and the sixth that remembers)

Osmani's anatomy: a loop needs five things, plus one place to remember.

```
┌───┬────────────────┬──────────────────────────────────────────────────┐
│ # │ Piece          │ Its job in the loop                              │
├───┼────────────────┼──────────────────────────────────────────────────┤
│ 1 │ Automations    │ Fire on a schedule; do discovery + triage by     │
│   │                │ themselves. The heartbeat that makes it a loop   │
│   │                │ and not a one-off run.                            │
├───┼────────────────┼──────────────────────────────────────────────────┤
│ 2 │ Worktrees      │ Isolate parallel agents so two of them don't     │
│   │                │ collide on the same files.                        │
├───┼────────────────┼──────────────────────────────────────────────────┤
│ 3 │ Skills         │ Write down project knowledge the agent would     │
│   │                │ otherwise guess (SKILL.md).                       │
├───┼────────────────┼──────────────────────────────────────────────────┤
│ 4 │ Plugins /      │ Plug the agent into the tools you already use    │
│   │ connectors     │ (built on MCP): issue tracker, DB, staging API,  │
│   │                │ Slack.                                            │
├───┼────────────────┼──────────────────────────────────────────────────┤
│ 5 │ Sub-agents     │ One has the idea, a different one checks it.      │
├───┼────────────────┼──────────────────────────────────────────────────┤
│ 6 │ State / memory │ A markdown file or a Linear board — anything     │
│   │                │ outside the single conversation — holding what's │
│   │                │ done and what's next. "The agent forgets, the    │
│   │                │ repo doesn't."                                    │
└───┴────────────────┴──────────────────────────────────────────────────┘
```

**Memory on disk, not in context, is the load-bearing trick.** A long-running loop forgets everything between runs; the model's context window resets. So the record of what is done and what is next has to live on disk (markdown, a progress file, a Linear board) where the next run re-reads it. Sounds too dumb to matter — it is the thing every long-running agent depends on.

**Automations are the heartbeat.** `/loop` re-runs a prompt on a cadence; `/goal` keeps going until a condition you wrote is actually true, and a *fresh* model decides whether the loop is done — the maker/checker split applied to the stop condition itself. OpenAI runs these internally for boring recurring work: daily issue triage, summarizing CI failures, writing commit briefings, hunting bugs someone added last week.

**Sub-agents keep the maker away from the checker.** The model that wrote the code is far too generous grading its own homework. A second agent with different instructions — and sometimes a different model — catches what the first one talked itself past. Because the loop runs while you are not watching, a verifier you actually trust is the only reason you can walk away. Sub-agents burn more tokens (each does its own model and tool work), so spend them where a second opinion is worth paying for.

## The same primitives in both products

The names differ; the capability is identical. This is why loop engineering stopped being a tooling argument.

```
┌──────────────┬──────────────────────────────────┬──────────────────────────────────┐
│ Primitive    │ OpenAI Codex app                 │ Claude Code                      │
├──────────────┼──────────────────────────────────┼──────────────────────────────────┤
│ Automations  │ Automations tab: pick project,   │ Scheduled tasks + cron, /loop,   │
│              │ prompt, cadence, environment;    │ /goal, lifecycle hooks, GitHub   │
│              │ results land in a Triage inbox;  │ Actions to keep running after    │
│              │ /goal for run-until-done         │ you close the laptop             │
├──────────────┼──────────────────────────────────┼──────────────────────────────────┤
│ Worktrees    │ Built-in worktree per thread     │ git worktree, --worktree flag,   │
│              │                                  │ isolation: worktree on a subagent│
├──────────────┼──────────────────────────────────┼──────────────────────────────────┤
│ Skills       │ Agent Skills (SKILL.md),         │ Agent Skills (SKILL.md)          │
│              │ invoked with $name or implicitly │                                  │
├──────────────┼──────────────────────────────────┼──────────────────────────────────┤
│ Plugins /    │ Connectors (MCP) + plugins for   │ MCP servers + plugins            │
│ connectors   │ distribution                     │                                  │
├──────────────┼──────────────────────────────────┼──────────────────────────────────┤
│ Sub-agents   │ Subagents as TOML in             │ Task subagents in .claude/agents/│
│              │ .codex/agents/                   │ , agent teams                    │
├──────────────┼──────────────────────────────────┼──────────────────────────────────┤
│ State        │ Markdown or Linear via connector │ Markdown (AGENTS.md, progress    │
│              │                                  │ files) or Linear via MCP         │
└──────────────┴──────────────────────────────────┴──────────────────────────────────┘
```

Connectors are why a loop can *act* inside your real environment instead of just telling you what it would do. A loop that only sees the filesystem is a tiny loop. With MCP connectors it reads the issue tracker, queries a database, hits a staging API, drops a message in Slack — the difference between an agent that says "here is the fix" and a loop that opens the PR, links the Linear ticket, and pings the channel once CI is green, by itself.

## Prompt engineering vs loop engineering

```
┌──────────────────┬─────────────────────┬──────────────────────────────┐
│ Dimension        │ Prompt engineering  │ Loop engineering             │
├──────────────────┼─────────────────────┼──────────────────────────────┤
│ Unit of work     │ One turn            │ An entire autonomous run     │
│ Who drives       │ You, manually       │ A system you designed        │
│ Duration         │ Seconds             │ Minutes to hours             │
│ Output           │ A response          │ A verified outcome           │
│ Leverage         │ 1x                  │ 10-100x                      │
│ Skill required   │ Phrasing            │ System design                │
└──────────────────┴─────────────────────┴──────────────────────────────┘
```

## Two scales, one mechanic

Shann Holmberg sketches the range. At the small end, a single agent walks research → draft → self-review → revise on repeat until the output meets the bar. At the large end, an orchestrator carves a goal into chunks, farms each to a specialist, and those specialists lean on their own helpers. The mechanic is the same act-observe-reason cycle; only the headcount changes.

## Is your task loop-shaped?

Before building a loop, run the candidate through three checks. Miss one and you are usually better off prompting it by hand or writing a plain script.

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Repetitive   │ You do it often enough that designing the system pays     │
│              │ back the design cost.                                     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Reviewable   │ "Done" can be expressed as a check the agent or a         │
│              │ verifier sub-agent can actually run. No pass condition →  │
│              │ the loop never knows when to stop.                        │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Valuable     │ The output is worth the tokens. Loops have a floor cost   │
│              │ in time and money; trivial work doesn't clear it.         │
└──────────────┴──────────────────────────────────────────────────────────┘
```

## Common practices

- **Three guards or it's not a loop.** Practitioner write-ups converge on the same trio: a hard **iteration cap** so a stuck loop can't spin forever; a **no-progress / diff check** that kills the run once the last few passes stop changing anything; and a **spend cap** in tokens or dollars that ends the run before the bill does. *"Without all three, what you are running isn't a loop. It's an open invoice."*
- **Split the maker from the checker.** Never let the model that wrote the code certify its own work. Use a separate verifier sub-agent, ideally a different model. (Osmani's "code agent orchestra" and "adversarial code review.")
- **Keep memory on disk.** State that survives between runs lives in markdown / a progress file / Linear, not in the context window.
- **Worktrees for anything parallel.** The moment you run more than one agent, file collisions become the failure mode — give each its own checkout.
- **Codify knowledge as Skills, not as walls of pasted instructions.** An automation that fires `$skill-name` stays maintainable; a schedule holding a giant instruction blob nobody updates does not.
- **Ground web-touching loops in fresh data.** "An open loop that writes code with no feedback is a machine for generating confident mistakes." Loops that research a competitor, read a fast-moving docs page, or check a status URL before acting use a web-data feedback layer (Firecrawl's search/scrape/crawl via MCP or CLI is the canonical fit).
- **Read the diffs.** The cure for the loop's biggest failure mode is one human still reviewing what shipped.

## Pros

- **Compounding leverage.** Build the loop once; get returns every time it runs. The reported jump is 10-100x over hand-prompting on loop-shaped work.
- **You stop being the bottleneck.** Discovery, triage, and recurring chores run on a schedule and bring findings to you, instead of you going around checking.
- **Tool-agnostic by construction.** The five-primitive shape is the same in Codex and Claude Code, so a well-designed loop ports across tools.
- **Verification becomes structural.** Splitting maker from checker bakes a real stop condition into the system rather than relying on the model's optimism.
- **Parallelism without chaos.** Worktrees let many agents run at once without stepping on each other.

## Cons / risks

- **The halting problem is your job.** *"The production version is that you write the loops, and most of your job is making sure they halt."* The loudest concern in every thread is runaway spend — people sharing receipts from loops that quietly chewed through hundreds of dollars overnight.
- **Comprehension debt.** The faster a loop ships code you did not write, the wider the gap between what exists in your repo and what you understand. A *smoother* loop grows the debt *faster* — unless someone reads the diffs. "Done" is a claim, not a proof.
- **Cognitive surrender.** When the loop runs itself it is tempting to stop having an opinion and take whatever it gives back. Same action — designing a loop — is the cure when done with judgment and the accelerant when done to avoid thinking.
- **Review bandwidth is the real ceiling.** Worktrees remove the mechanical collision, but *your* capacity to review decides how many agents you can actually run, not the tool. (The "orchestration tax.")
- **Token economics are unforgiving.** Sub-agents and long autonomous runs multiply cost; "token-rich vs token-poor" usage patterns vary wildly. See [[token-maxing]].
- **Still early and unproven.** Osmani himself is openly skeptical — "I believe this *may* be the future" — and stresses keeping balance with direct prompting.

## Who's doing it

**People who named and shaped it**
- **Boris Cherny** (creator/head of Claude Code, Anthropic) — "my job is to write loops."
- **Peter Steinberger** (founder, PSPDFKit / Nutrient) — the ~2.2M-view post that lit the fuse.
- **Addy Osmani** (engineering lead, Google Chrome) — coined and mapped the layer across blog + Substack; the GitHub reference repo became a community standard.
- **Shann Holmberg** — the single-agent vs orchestrator framing.

**Products that ship the primitives**
- **OpenAI Codex app** — Automations tab + Triage inbox, built-in worktrees, Agent Skills, MCP connectors, TOML sub-agents. OpenAI dog-foods it for issue triage, CI-failure summaries, commit briefings, bug hunting.
- **Claude Code** — `/loop`, `/goal`, cron, hooks, GitHub Actions, `git worktree` isolation, Agent Skills, MCP, task sub-agents and agent teams.

**Tooling growing around the loop**
- **Firecrawl** — positions itself as the web-data feedback layer inside loops (search / scrape / crawl via MCP server or CLI).
- **mem0** — pushing a "memory-first" design for loops (the on-disk state piece as a first-class product).
- **Community CLIs** — open-source starters such as `loop-audit`, `loop-init`, and `loop-cost` (cobusgreyling/loop-engineering) for scaffolding and cost-guarding loops.

## The debate

Developers are split on whether this is a real new abstraction or a rebrand. On Reddit the swing runs from *"this is genuinely the next abstraction layer"* to *"it's a cron job wearing a hat."* The honest read sits in the middle: the **primitives** (cron, worktrees, sub-processes, state files) are old; what is new is that they ship inside the agent products and compose into a named discipline with its own failure modes and guardrails.

The sharpest point is that the outcome depends entirely on the operator. *Two people can build the exact same loop and get opposite results — one moves faster on work they understand deeply, the other avoids understanding the work at all. The loop doesn't know the difference. You do.* That is why loop design is **harder** than prompt engineering, not easier: the leverage moved up a floor, and so did the responsibility.

## What this means

Loop engineering is the natural next rung after harness engineering: once a single agent runs reliably inside a good environment, the question becomes who pushes the button — and the answer is "a system you wrote, on a timer." The pieces are unglamorous on purpose: a schedule, worktrees, skills, connectors, a maker/checker split, and a memory file on disk. The hard parts are not the pieces; they are **making the loop halt** (iteration cap, no-progress check, spend cap) and **not letting your understanding rot** while the loop ships code you didn't write.

The careers that compound in this era won't belong to whoever writes the prettiest prompt — they'll belong to whoever designs the best loops *and still reads the diffs*. Build the loop. But build it like someone who intends to stay the engineer, not just the person who presses go. See [[ai-native-engineering]] for the broader role shift.

## Links

- https://addyosmani.com/blog/loop-engineering/
- https://addyo.substack.com/p/loop-engineering
- https://addyosmani.com/blog/agent-harness-engineering/
- https://addyosmani.com/blog/comprehension-debt/
- https://addyosmani.com/blog/long-running-agents/
- https://addyosmani.com/blog/cognitive-surrender/
- https://addyosmani.com/blog/orchestration-tax/
- https://addyosmani.com/blog/code-agent-orchestra/
- https://addyosmani.com/blog/adversarial-code-review/
- https://www.firecrawl.dev/blog/loop-engineering
- https://explainx.ai/blog/what-is-loop-engineering-ai-agents-2026
- https://smartscope.blog/en/generative-ai/methodology/loop-engineering-agent-loops-2026/
- https://www.mindstudio.ai/blog/what-is-loop-engineering-ai-coding-agents
- https://mem0.ai/blog/loop-engineering-for-ai-agents-memory-first-design
- https://tosea.ai/blog/loop-engineering-ai-agents-complete-guide-2026
- https://github.com/cobusgreyling/loop-engineering
- https://x.com/steipete/status/2063697162748260627
- https://developers.openai.com/codex/app/automations
- https://developers.openai.com/codex/skills
- https://developers.openai.com/codex/subagents
