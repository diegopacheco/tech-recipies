# The 10x Engineer

## What is it?

The **10x engineer** is the belief — part observation, part myth — that some software engineers are roughly *an order of magnitude* more productive than an average one: that a single exceptional developer can out-build ten ordinary ones. It is one of Silicon Valley's most durable folk ideas, invoked to justify enormous pay gaps, aggressive hiring bars, tiny elite teams, and the founder fantasy of the lone genius who ships what a whole department couldn't. The "10x" is rarely meant literally; it's shorthand for a claimed **extreme, non-linear spread** in engineering output — the idea that talent in this field doesn't distribute on a gentle bell curve but on something with a very long tail.

The concept matters because the Valley has *built institutions* on it. Leveling ladders, [[stock-options]] grants skewed toward "key" engineers, "we only hire the top 1%" recruiting, two-pizza teams, and the whole cult of the rockstar/ninja/10x developer all assume the premise is true. It's also one of the most *contested* ideas in the industry: the research behind the number is thin and old, the term became a punchline after a viral 2019 thread, and a large camp argues the "10x engineer" is a harmful myth that mistakes *context* (a great codebase, a clear problem, a supportive team) for an innate property of a person. Whether you believe it or not, you have to reckon with it, because it silently shapes how SV hires, pays, and organizes.

## How it works

The idea operates as a **hiring and org-design heuristic**: if output is wildly unequal, then the highest-leverage move isn't adding headcount, it's finding and retaining the rare few at the top of the distribution — and paying almost anything to keep them. This is why SV compensation is so top-heavy and why a senior engineer's [[stock-options]] or [[RSUs]] can dwarf a junior's by far more than 10x, even though salaries compress. The belief also underwrites the small-team ethos: if one great engineer beats ten average ones, you'd rather have three great ones than thirty mediocre, because coordination cost (the [[cash-flow]] and communication drag of a big team) grows faster than output.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ The claim decomposed │ What's actually being asserted                             │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Output variance      │ Best and worst developers differ by ~10x (some studies     │
│                      │ cite 20–28x) on time-to-complete and defect rates.         │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Non-linear tail      │ Productivity is log-normal, not a bell curve — a thin top   │
│                      │ tail contributes outsized share of the output.             │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Innate vs contextual │ The contested core: is the 10x a property of the *person*, │
│                      │ or of the person-in-a-good-environment?                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Multiplier vs adder  │ The strongest version: the best engineers *multiply* others│
│                      │ (mentoring, tooling, leverage), not just out-type them.    │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The most defensible reading isn't the "types 10x faster" caricature — it's the **multiplier** version: the rare engineer whose real output is the *leverage they create for everyone else* — the platform, the abstraction, the tool, the code review that levels up the team. On that reading "10x" isn't one person coding furiously in the corner; it's one person whose work makes ten other people meaningfully better. That is also why the myth is dangerous when taken literally: the corner-genius who ships alone and mentors no one can be a **net negative** at team scale, even while looking individually prolific.

## Where the number comes from

The "10x" figure has a real but shaky pedigree, and tracing it is half the story.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Source                     │ What it actually found / its problem               │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Sackman, Erikson & Grant   │ The origin. Found up to ~28:1 spread in programmer │
│ (1968)                     │ performance — but mixed online vs offline coding   │
│                            │ and small samples, inflating the range.            │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Later replications         │ Repeatedly found large variance (often cited ~10x  │
│ (1980s–2000s)              │ on time, larger on defects) across many studies.   │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ The Leprechauns of SW Eng  │ Laurent Bossavit traces the "10x" citation chain   │
│ (Bossavit)                 │ and shows how much rests on one flawed 1968 study. │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ The 2019 viral thread      │ Shekhar Kirani's "signs of a 10x engineer" tweets  │
│                            │ went viral and were widely ridiculed — the term    │
│                            │ curdled into a meme.                                │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

The number traces back primarily to **Sackman, Erikson & Grant (1968)**, an experiment that reported performance ratios as high as **28:1** between the best and worst programmers. Later work (Peopleware, Code Complete, various studies) kept finding *large* variance, which is why the folk belief persists — the spread is real even if "10x" is a rounded, borrowed figure. But the skeptics, led by Laurent Bossavit's *The Leprechauns of Software Engineering*, show how thin the original evidence is and how a single flawed study got laundered through decades of citation into an "established fact." The 2019 explosion — Accel partner **Shekhar Kirani's viral thread** listing the supposed "signs of a 10x engineer" (works alone, ignores meetings, no documentation) — is what finally turned the phrase into a punchline, because the "signs" described an *anti-social liability*, not a hero.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Setting              │ How the 10x belief shows up                                │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech             │ Elite hiring bars ("top 1%"), leveling ladders, and        │
│                      │ heavily top-weighted [[RSUs]] to retain the presumed few.  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups             │ Tiny founding teams betting the company on a handful of    │
│                      │ great engineers paid in [[stock-options]] upside.          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Modern eng culture   │ Shift from "10x individual" to "10x team" — leverage,      │
│                      │ platform, and force-multipliers over lone heroes.          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ AI era (2025+)       │ "10x" reframed as AI-augmented output; [[vibe-coding]] and │
│                      │ copilots claimed to make ordinary engineers 10x.           │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The mature move across the industry is to **retire the lone-genius reading and keep the leverage one.** Serious engineering orgs now talk about "force multipliers" and "10x teams" rather than 10x individuals, precisely because the corner-genius pattern breeds bus-factor risk, poor documentation, and toxic-brilliant-jerk dynamics that cost more than they produce. The newest twist is the AI reframing: the 2025 pitch is that copilots and [[vibe-coding]] turn an *average* engineer into a 10x one, moving the multiplier from a rare person to a widely available tool — which, if true, quietly dissolves the original premise that the 10x is scarce.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ What's true / useful in it                  │ Where it misleads / harms                   │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Output variance is genuinely large — talent │ "10x" is a borrowed, rounded number resting  │
│ and skill really do differ a lot            │ on one thin 1968 study                       │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ The leverage/multiplier reading is real —   │ The literal "types 10x faster" caricature    │
│ great engineers uplift whole teams          │ celebrates anti-social, low-doc behavior     │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Justifies investing heavily in a few strong │ Confuses context (good codebase, clear task, │
│ hires over many weak ones                   │ support) with an innate personal trait       │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Focuses orgs on leverage and tooling, not   │ Feeds brilliant-jerk tolerance and bus-      │
│ raw headcount                               │ factor risk; excuses toxic stars             │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The defining error is treating 10x as an **innate property of a person** rather than a property of a *person in a context*. The same engineer is 10x in a clean codebase with a sharp problem and a team that removes friction, and 0.1x dropped into a legacy swamp with unclear goals and constant interruptions. Cultures that believe in innate 10x-ness tolerate the toxic star, under-invest in the environment that actually produces high output, and mistake individual heroics for organizational health — the exact opposite of what the leverage reading recommends.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they invoke the 10x engineer                           │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Founders / recruiters│ Justify elite hiring bars and outsized offers for a few     │
│                      │ "key" engineers                                            │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Comp / leveling      │ Rationalize steeply top-weighted [[stock-options]] and     │
│ committees           │ [[RSUs]] for senior staff and principal engineers          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Eng leaders          │ Increasingly reframe it as force-multiplier / 10x-team,    │
│                      │ steering away from lone-hero worship                       │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ AI vendors           │ Market copilots and agents as the thing that makes any     │
│                      │ engineer 10x — the multiplier as a purchasable tool        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Skeptics / academics │ Cite Bossavit and the weak provenance to debunk the literal│
│                      │ claim and warn against the toxic-star culture it feeds     │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

The 10x engineer is half true and half dangerous. The *true* half: engineering output really is wildly unequal, and the best engineers create leverage — tools, platforms, mentorship — that lifts everyone around them, which is why SV pays so steeply for the top of the distribution. The *dangerous* half: the literal "one person, ten times the code" reading rests on a single shaky 1968 study, celebrates the anti-social corner-genius the 2019 meme skewered, and confuses a supportive *context* with an innate personal trait. The practical read is to chase the **multiplier, not the mythical individual** — build the environment (clean code, clear problems, low friction) that lets ordinary-to-great engineers do their best work, and be suspicious of any culture that tolerates a toxic star on the theory that they're "worth ten." In the AI era the whole premise is shifting anyway: if [[vibe-coding]] really does make an average engineer 10x, the scarce genius the myth was built on stops being scarce.

## Links

- The 10x Engineer thread that went viral (Shekhar Kirani, 2019) — coverage: https://www.businessinsider.com/10x-engineer-silicon-valley-debate-2019-7
- Exploratory experimental studies comparing online and offline programming performance (Sackman, Erikson & Grant, 1968): https://dl.acm.org/doi/10.1145/362851.362858
- The Leprechauns of Software Engineering (Laurent Bossavit): https://leanpub.com/leprechauns
- Peopleware: Productive Projects and Teams (DeMarco & Lister): https://en.wikipedia.org/wiki/Peopleware:_Productive_Projects_and_Teams
- The 10x programmer, and other myths in software engineering: https://www.itworld.com/article/2823759/enterprise-software-the-10x-programmer-and-other-myths-in-software-engineering.html
- What is a 10x engineer, really? (The Pragmatic Engineer, Gergely Orosz): https://blog.pragmaticengineer.com/the-product-minded-engineer/
</content>
