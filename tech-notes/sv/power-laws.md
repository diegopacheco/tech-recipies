# Power Laws

## What is it?

A **power law** describes a distribution in which rare, extreme outcomes occur far more often than a normal bell curve would predict. Most observations are small, a few are enormous, and those few can dominate the total. In Silicon Valley the phrase usually means something practical rather than strictly mathematical: most startups fail or return little, while a tiny number become so valuable that they repay the losses and generate nearly all the gains.

That asymmetry is the hidden operating system of venture capital. It explains why VCs accept many failures, why every startup pitch needs a path to a billion-dollar market, why missing one exceptional company can hurt more than funding ten failures, and why founders and employees receive [[stock-options]] with limited downside and uncapped upside. The same worldview leaks into talent through the [[10x-engineer]], into markets through winner-take-most platforms, and into strategy through the belief that the best company, product, or person may matter more than everything else combined.

The term is also used carelessly. A **heavy-tailed** distribution is not automatically a power law, the Pareto "80/20 rule" is not its definition, and exponential growth is not the same thing. Exponential growth describes one quantity changing over time; a power law describes how many outcomes of different sizes appear across a population. Venture outcomes may be power-law distributed in their upper tail, log-normal, or another fat-tailed form. The reliable claim is the weaker one: **the average startup is a poor guide to the portfolio because outliers control the result.**

## How it works

For a continuous quantity `x`, a power-law probability density is commonly written:

```
p(x) = Cx^(-α), for x ≥ xmin

x     = outcome size
xmin  = point where power-law behavior begins
α     = scaling exponent
C     = normalization constant
```

The defining property is **scale invariance**. Multiplying the outcome by a fixed amount changes its probability by another fixed amount:

```
p(kx) / p(x) = k^(-α)
```

There is no natural "typical" scale in the tail. A lower `α` means a heavier tail and more weight on extreme outcomes. Under the usual continuous-density convention, when `2 < α < 3`, the theoretical mean exists but the variance does not. That makes familiar tools built around averages, standard deviations, and stable historical samples much less reliable.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Distribution         │ What the tail means                                        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Normal               │ Extremes vanish quickly; the average describes most cases. │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Exponential          │ Larger outcomes become unlikely at a constant exponential  │
│                      │ rate; the tail is longer than normal but still thin.        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Log-normal           │ Multiplicative growth creates a long right tail; can look   │
│                      │ like a power law over a limited range.                      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Power law / Pareto   │ The tail shrinks polynomially; rare giants remain plausible │
│                      │ and can dominate the sum.                                   │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

This is why merely drawing a straight line on a log-log chart is not proof. Clauset, Shalizi, and Newman showed that credible identification requires estimating `xmin` and `α`, testing goodness of fit, and comparing the result with alternatives such as a log-normal distribution. The visual pattern is a clue, not a verdict.

## Why Silicon Valley produces them

Silicon Valley does not just observe skewed outcomes; its technology and financing model can **amplify small early differences into enormous later gaps**.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Mechanism            │ How it amplifies the lead                                  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Multiplicative growth│ Retention, referrals, revenue, and reinvestment compound    │
│                      │ instead of adding a fixed amount each period.               │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Network effects      │ More users make the product more useful, attracting still   │
│                      │ more users and pushing a market toward a few hubs.          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Preferential attach. │ Capital, talent, partners, and press flow toward companies  │
│                      │ that already look successful: the rich get richer.          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Software economics   │ High fixed creation cost plus near-zero marginal delivery   │
│                      │ lets one product serve a global market.                     │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Equity optionality   │ A [[stock-options]] grant can fall to zero but has no fixed  │
│                      │ ceiling if the company becomes an outlier.                  │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

Barabási and Albert formalized one of these loops as **preferential attachment**: growing networks develop hubs because new nodes disproportionately connect to nodes that are already well connected. In startup terms, traction attracts funding; funding buys talent and distribution; those attract more users; the larger user base creates more traction. Quality matters, but path dependence means an early lead, a prestigious investor, or a lucky distribution channel can become self-reinforcing.

The [[product-market-fit]] phase change is where this loop often starts. Before fit, growth is pushed and fragile. After fit, organic demand, retention, and referrals can make growth multiplicative. Venture money then tries to accelerate the feedback loop before competitors catch it, even if doing so makes [[cash-flow]] deeply negative.

## What the evidence says

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Evidence                   │ Finding                                            │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ U.S. VC, 1985–2009         │ NBER researchers found about 55% of startups lost  │
│ (Kerr, Nanda, Rhodes-Kropf)│ money. The 6% returning more than 5x produced about│
│                            │ half of all gross returns.                         │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Horsley Bridge fund data   │ Roughly 6% of investments, representing 4.5% of    │
│ (reported by a16z)         │ dollars invested, generated about 60% of returns.  │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ 2,065 EIF-backed exits     │ The upper tail was consistent with a power law with│
│                            │ α ≈ 2.45, but the sample could not decisively beat  │
│                            │ a log-normal alternative.                          │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ AngelList seed investments │ Return multiples and winning-investment IRRs were  │
│                            │ consistent with power-law tails; early-stage breadth│
│                            │ improved the modeled chance of catching an outlier.│
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Private-equity fund data   │ A 2023 study found a smooth double-Pareto model fit │
│                            │ fund valuation multiples better than alternatives, │
│                            │ with especially fat tails in venture capital.       │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

The honest conclusion is not "the law has been proven everywhere." Private-company data is incomplete, valuations are stale and partly subjective, failures disappear from datasets, and the extreme tail contains few observations by definition. The evidence strongly supports **skew, fat tails, and outlier dependence**. Some datasets support an exact Pareto tail; others cannot distinguish it from log-normal or double-Pareto behavior.

## What it does to venture capital

A normal portfolio tries to avoid large mistakes and earn a good average return. A venture portfolio tries to avoid **missing the rare company that can return the fund**. Frequency matters less than magnitude because losses stop at 1x invested while a winner can return 10x, 50x, or 300x.

Worked portfolio: a **$100M fund** makes twenty equal **$5M** investments.

```
12 investments × 0x  =   $0M
 5 investments × 1x  =  $25M
 2 investments × 3x  =  $30M
 1 investment  × 30x = $150M
                         ─────
Gross proceeds          $205M
Gross multiple           2.05x
```

One company supplies **73% of all proceeds** and more than the fund's entire original capital. Without it, the other nineteen investments return only $55M and the fund loses money before fees and carry. This produces several rules that look strange outside venture:

- **Every initial investment needs outlier potential.** A safe company capped at a modest outcome may succeed operationally and still be unable to move a large fund.
- **Ownership matters as much as selection.** Finding the winner is insufficient if dilution leaves the fund with too little of it at exit.
- **Reserve capital for emerging winners.** Pro-rata follow-ons preserve ownership as the most valuable companies raise larger rounds.
- **Accept strikeouts, but do not celebrate them.** Great funds can lose often because their winners are larger; failure itself creates no return.
- **Treat omission as a major risk.** Passing on one 100x company can be more damaging than writing several checks that go to zero.

There is a real strategy dispute inside the power-law logic. Peter Thiel's concentrated reading says each company must plausibly return the whole fund and deserves concentrated attention. AngelList's quantitative work argues that seed investors without perfect foresight benefit from broad exposure to every credible deal, because selection can exclude the unknowable outlier. The synthesis is **breadth before signal, concentration after signal**: buy enough early optionality to catch the tail, then direct ownership, reserves, and operating help toward the companies proving they may occupy it.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Actor                │ Behavior produced by power-law thinking                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ VCs                  │ Build portfolios of asymmetric bets, seek fund-returning    │
│                      │ outcomes, reserve follow-on capital, tolerate a low hit rate.│
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Founders             │ Pitch enormous markets, prioritize speed after [[product-  │
│                      │ market-fit]], and pursue category leadership over a niche. │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups             │ Pay in [[stock-options]], concentrate resources on the     │
│                      │ strongest product, channel, market, and key people.        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Platforms            │ Use network effects, ecosystems, and low marginal cost to │
│                      │ turn an early advantage into winner-take-most scale.       │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Employees            │ Trade salary certainty for equity exposure to one highly  │
│                      │ uncertain company; outcomes become radically unequal.     │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

This is why a profitable small business and a venture-backable startup are not synonyms. A business can be excellent for its owners and customers while having no credible path to return a $500M fund. Venture capital selects for scalable markets and uncapped outcomes, then the selection pressure pushes founders toward [[techno-optimism]], speed, and market dominance. The financing model does not merely discover power-law companies; it encourages companies to behave as if becoming one is the only acceptable destination.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ What it gets right                         │ Where it misleads or harms                   │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Models asymmetric startup outcomes better  │ "Power law" is often asserted when evidence  │
│ than a bell curve                          │ proves only a heavy tail                     │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Makes magnitude, ownership, and omission   │ Survivorship bias turns lucky winners into   │
│ risk visible                               │ inevitable-looking stories                   │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Supports many bounded experiments when the │ Can excuse reckless growth, weak governance, │
│ upside is uncapped                         │ and waste as the price of swinging big       │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Explains why network effects and scale can │ Funnels capital and talent toward visible    │
│ create durable category leaders            │ leaders, strengthening the inequality it     │
│                                            │ claims merely to observe                      │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Warns that averages and hit rates can hide │ Devalues durable smaller companies because   │
│ the economics that matter                  │ they cannot become fund-returning outliers    │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The most dangerous move is turning a statistical pattern into a moral theory. If outcomes are skewed, it does not follow that the winners deserved every advantage, that the losers were foolish, or that concentration is always efficient. Preferential attachment says the opposite: early luck and social proof can compound alongside genuine quality. Power-law thinking is useful for sizing bets and understanding tails; it is not proof that whatever became largest was destined to win.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use power laws                                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Venture capitalists  │ Portfolio construction, ownership targets, reserves, and   │
│                      │ the requirement that every deal can return the fund.       │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ LPs / allocators     │ Judge access to top funds and accept long lockups because   │
│                      │ returns are concentrated across funds as well as companies.│
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Founders             │ Frame the company around a huge market and a path from      │
│                      │ [[product-market-fit]] to category dominance.              │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Employees            │ Evaluate whether [[stock-options]] or [[RSUs]] provide     │
│                      │ meaningful ownership of a plausible outlier.               │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Researchers          │ Test whether observed tails are truly Pareto, log-normal,   │
│                      │ double-Pareto, or simply too sparse to classify.           │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

Power laws are the mathematical idea that became Silicon Valley's management philosophy: **a few outcomes matter more than all the rest combined.** The strongest evidence is in venture returns, where losses are common and a small group of investments supplies most of the money; the same positive-feedback machinery appears in platform networks, startup financing, equity wealth, and the Valley's fascination with [[10x-engineer]] talent. The practical lesson is to optimize for expected magnitude rather than win rate, keep enough early optionality to avoid missing the tail, and protect ownership when a genuine winner emerges. The intellectual guardrail matters just as much: call the data heavy-tailed unless an exact power law has actually survived statistical testing, and never confuse a distribution of outcomes with a verdict about merit. In Silicon Valley, the outlier is the business model — but the story told about the outlier is often much cleaner than the evidence.

## Links

- Power-law distributions in empirical data (Clauset, Shalizi & Newman, SIAM Review): https://arxiv.org/abs/0706.1062
- Power laws, Pareto distributions and Zipf's law (M. E. J. Newman): https://arxiv.org/abs/cond-mat/0412004
- Entrepreneurship as Experimentation (Kerr, Nanda & Rhodes-Kropf, NBER): https://www.nber.org/papers/w20358
- The European venture capital landscape: an EIF perspective, Volume III — Liquidity events and returns of EIF-backed VC investments: https://www.eif.org/news_centre/publications/eif_wp_41.pdf
- Startup Growth and Venture Returns (Abraham Othman, AngelList): https://wellfound.com/pdf/growth.pdf
- Performance Data and the "Babe Ruth" Effect in Venture Capital (Chris Dixon, a16z): https://a16z.com/performance-data-and-the-babe-ruth-effect-in-venture-capital/
- Black Swan Farming (Paul Graham): https://paulgraham.com/swan.html
- Emergence of Scaling in Random Networks (Barabási & Albert, Science): https://doi.org/10.1126/science.286.5439.509
- Fat tails in private equity fund returns: The smooth double Pareto distribution (Henry Lahr): https://doi.org/10.1016/j.irfa.2022.102471
- The Power Law: Venture Capital and the Art of Disruption (Sebastian Mallaby): https://www.penguin.com.au/books/the-power-law-9780141988948
