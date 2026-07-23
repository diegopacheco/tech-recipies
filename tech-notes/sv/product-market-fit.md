# Product-Market Fit

## What is it?

**Product-market fit (PMF)** is the moment a product finally satisfies a strong market demand — when the thing you built and the people who want it lock together and the market starts *pulling* the product out of you faster than you can push it. Marc Andreessen, who popularized the term, put it bluntly: it's "being in a good market with a product that can satisfy that market," and you can always *feel* when it's not happening (customers aren't getting value, word of mouth isn't spreading, sales cycles drag, deals die) and always feel when it is (you can't hire fast enough, servers fall over, money piles up). It is less a metric than a **phase change** — the same company, the same team, suddenly on the other side of a wall.

PMF matters because it is the hinge the entire startup game turns on. Andreessen's central claim is that **the only thing that matters is getting to product-market fit** — that a great team in a bad market loses to a mediocre team in a great market, and that everything a startup does divides cleanly into *before* PMF and *after*. Before it, nothing else you optimize — hiring, process, [[blitzscaling]], culture — actually helps, because you're pouring effort into a product the market doesn't want. After it, the job flips entirely: from *searching* for what works to *scaling* what already does. It is the concept the rest of this folder quietly assumes; the [[cash-flow]] burn, the [[stock-options]] upside, the [[rule-of-40]] growth all presuppose that somewhere a product finally fit its market.

## How it works

PMF is best understood as the transition between the two fundamental modes of a startup: **search** and **scale**. A pre-PMF company is a search function — running experiments, pivoting, talking to users, trying to find the market that pulls. A post-PMF company is an execution function — pouring fuel on a fire that's already lit. The failure mode that kills companies is confusing the two: scaling (hiring a big sales team, spending on ads, raising a mega-round) *before* the fit exists, which just makes you burn faster in the wrong direction.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Signal               │ Before PMF vs After PMF                                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Word of mouth        │ Before: you chase every user. After: users bring users.    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Retention curve      │ Before: cohorts decay toward zero. After: the curve        │
│                      │ flattens — a stable base keeps using it.                   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Usage / growth       │ Before: flat, effortful. After: pulls faster than you push.│
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Your problem         │ Before: "will anyone want this?" After: "can we keep up?"  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Where effort goes    │ Before: change the product. After: scale the machine.      │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The crucial and uncomfortable truth is that PMF usually arrives through a **pivot**, not the original plan. Slack was a failed game (Glitch); Instagram was a bloated check-in app (Burbn) stripped to photos; YouTube was a video-dating site. The [[mvp]] and lean-startup loop — build, measure, learn — exists precisely to shorten the search for fit by testing the smallest thing that could reveal whether the market pulls, before the money runs out.

## How you measure it

PMF famously "you know it when you feel it," but the Valley has built proxies that turn the feeling into numbers you can track toward.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Instrument                 │ What it measures / the threshold                   │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Sean Ellis test            │ Survey: "How would you feel if you could no longer │
│                            │ use this?" ≥40% answering "very disappointed" is   │
│                            │ the working PMF benchmark.                          │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Retention curve            │ Does the cohort-retention line flatten to a stable │
│                            │ plateau, or decay to zero? A flat asymptote = fit. │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Organic / word-of-mouth    │ Share of new users arriving unpaid; a rising organic│
│ growth                     │ mix signals the market is pulling.                 │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Net revenue retention      │ Existing customers expanding (>100% NRR) — they    │
│                            │ pay more over time without you re-selling.         │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

The **Sean Ellis 40% test** is the closest thing to a standard. Rahul Vohra of Superhuman turned it into a repeatable engine: survey users, ignore the "not disappointed" crowd, and obsess over the people who'd be "very disappointed" — build relentlessly for *them* while converting the "somewhat disappointed" fence-sitters. Superhuman drove its score from **22% to 58%** by doing exactly this. The lesson is that PMF isn't binary — it's a dial you can deliberately turn, cohort by cohort, rather than a lightning strike you wait for.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Stage                │ How they treat PMF                                         │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Pre-seed / seed      │ Everything is the search for fit — [[mvp]], user           │
│                      │ interviews, fast pivots. Raise just enough runway to find  │
│                      │ it before the [[cash-flow]] runs out.                      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Series A gate        │ VCs largely underwrite "have you found PMF?" — early        │
│                      │ retention and organic growth are the evidence they buy.    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Post-PMF growth      │ Switch from search to scale: hire GTM, spend, and          │
│                      │ [[blitzscaling]]. When growth-at-all-costs was rational.   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Public / mature      │ Chase PMF again per new product line — "PMF is not         │
│                      │ permanent"; markets shift and fit can be lost.             │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The dominant discipline is **don't scale before fit.** The graveyard of the 2000s and 2010s is full of companies that raised huge rounds and hired big sales teams on the *assumption* of PMF, then burned it all discovering the market wasn't there (Webvan, Quibi, countless "solutions in search of a problem"). The post-2022 tightening described in [[cash-flow]] is partly a return to this discipline: investors stopped funding the search indefinitely and started demanding evidence the fit is real before they'll fund the scale.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ Strengths of the concept                    │ Limits / traps                              │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ A single clarifying goal — before PMF,      │ Fuzzy: "you feel it" resists measurement and │
│ nothing else matters                        │ founders fool themselves into seeing it      │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Separates search from scale — stops you     │ False positives: a few loud fans or one big  │
│ scaling in the wrong direction              │ customer look like fit but don't generalize  │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Measurable proxies exist (40% test,         │ Not permanent — markets shift and a fit      │
│ retention curve) to track toward it         │ once found can quietly erode                 │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Reframes failure as a pivot, not a death —  │ Says little about *how* to get there — it    │
│ the search is supposed to be iterative      │ names the destination, not the road          │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The subtlest trap is **false PMF**: a handful of passionate early adopters, or one whale customer, produces the *feeling* of fit without the *reality* of a repeatable market. Founders scale on it, hire against it, and discover too late that the demand didn't generalize past the first few believers. The defense is the boring one — measure retention and organic pull across real cohorts, not anecdotes, and remember that fit is a plateau many users reach, not a spike a few do.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use the concept                                   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Founders             │ The north star of the early company — every experiment     │
│                      │ aims at reaching, then holding, PMF                        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ VCs                  │ The core Series A underwriting question; retention and     │
│                      │ organic growth are the evidence of it                      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Product / growth     │ Run the Sean Ellis survey, cohort-retention analysis, and  │
│ teams                │ the "very disappointed" segmentation to steer the roadmap  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Later-stage cos      │ Seek PMF anew for each product line — it isn't a one-time  │
│                      │ event but a state that can be lost                         │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

Product-market fit is the concept everything else in a startup hangs from — the phase change from a product nobody pulls to one the market yanks out of your hands. Andreessen's provocation still holds: before it, no amount of great hiring, process, or funding saves you; after it, the job flips from *searching* for what works to *scaling* it, and mistaking one mode for the other is how well-funded startups burn out. The practical reads are three: **don't scale before you've found fit**, prove fit with retention and organic pull rather than anecdotes or one loud customer, and treat the [[mvp]] loop as a deliberate search you must finish before the [[cash-flow]] does. Every [[stock-options]] fortune and every [[rule-of-40]] IPO in this folder is, underneath, a story of a product that finally fit its market.

## Links

- The Pmarca Guide to Startups, part 4: The only thing that matters (Marc Andreessen): https://pmarchive.com/guide_to_startups_part4.html
- Product/market fit (Wikipedia): https://en.wikipedia.org/wiki/Product/market_fit
- How Superhuman Built an Engine to Find Product-Market Fit (First Round Review): https://review.firstround.com/how-superhuman-built-an-engine-to-find-product-market-fit/
- Startup = Growth (Paul Graham): https://www.paulgraham.com/growth.html
- The Sean Ellis Test / 40% benchmark (Sean Ellis, GrowthHackers): https://www.startup-marketing.com/the-startup-pyramid/
- The Real Product Market Fit (Andreessen Horowitz): https://a16z.com/the-real-product-market-fit/
- The Lean Startup (Eric Ries): http://theleanstartup.com/principles
</content>
</invoke>
