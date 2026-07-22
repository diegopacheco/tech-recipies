# Cash Flow

## What is it?

**Cash flow** is the movement of actual money into and out of a business over a period of time — not what it *earned* on paper, but what actually landed in or left the bank account. It is the single number that decides whether a company lives or dies, because a business does not go bankrupt when it stops being profitable; it goes bankrupt when it runs out of cash. The two are not the same thing. A company can post a fat accounting profit and still fail to make payroll if that "profit" is trapped in unpaid invoices, unsold inventory, or a factory it just bought. The old auditor's line captures it exactly: **profit is an opinion, cash is a fact.**

Profit is an opinion because it is built from accrual accounting — revenue is booked when *earned* (you shipped the goods, you signed the contract), expenses when *incurred*, regardless of when money changes hands. Depreciation, amortization, and revenue-recognition policy all shape the profit line without a single dollar moving. Cash flow strips all of that away and asks one blunt question: over this quarter, did more money come in than went out? That is why lenders, acquirers, and IPO investors treat the cash flow statement as the least gameable of the three financial statements, and why the whole apparatus of valuation — [[dcf]], the [[rule-of-40]], LBO models — is ultimately built on top of cash, not earnings.

## The Three Kinds of Cash Flow

Every cash flow statement splits into three buckets. Where the cash comes from matters as much as how much of it there is.

```
┌──────────────────────┬────────────────────────────────┬───────────────────────────┐
│ Section              │ What it captures               │ What it tells you         │
├──────────────────────┼────────────────────────────────┼───────────────────────────┤
│ Operating (CFO)      │ Cash from running the core     │ Is the actual business    │
│                      │ business — customers pay in,   │ self-funding? The healthi-│
│                      │ suppliers/wages/tax pay out    │ est source of cash.       │
├──────────────────────┼────────────────────────────────┼───────────────────────────┤
│ Investing (CFI)      │ Buying/selling long-term       │ Is it reinvesting (capex, │
│                      │ assets — capex, acquisitions,  │ M&A) or selling off the   │
│                      │ selling equipment              │ furniture to survive?     │
├──────────────────────┼────────────────────────────────┼───────────────────────────┤
│ Financing (CFF)      │ Raising/returning capital —    │ Is it living on investor  │
│                      │ debt, equity raises, dividends,│ money, or handing cash    │
│                      │ buybacks                       │ back to owners?           │
└──────────────────────┴────────────────────────────────┴───────────────────────────┘
```

The pattern of the three buckets is diagnostic. A mature healthy company shows **positive operating, negative investing, negative financing** — it earns cash, reinvests some, and returns the rest. A pre-IPO growth startup typically shows **negative operating, negative investing, hugely positive financing** — it burns cash and lives on the money it raises. That second pattern is fine right up until the financing tap closes, which is exactly what happened across 2022–2024 and reset how the market prices the difference.

## How it works: profit vs. cash

The clearest way to see why the two diverge is the walk from net income to operating cash flow. You take accounting profit and undo every place where the accountants recorded something that wasn't cash.

```
  Net Income (accounting profit)
  + Depreciation & Amortization      (non-cash expense — add it back)
  + Stock-based compensation         (non-cash expense — add it back)
  ± Change in working capital:
      − rise in receivables          (booked a sale, cash NOT collected yet)
      − rise in inventory            (spent cash on stock not yet sold)
      + rise in payables             (received goods, cash NOT paid yet)
  ─────────────────────────────────
  = Operating Cash Flow (CFO)
  − Capital Expenditures (capex)
  ─────────────────────────────────
  = Free Cash Flow (FCF)
```

Working capital is where profitable companies quietly die. A business growing fast books more and more revenue, but every new sale ties up cash in receivables and inventory *before* the customer pays. Grow fast enough on thin margins and you can be more profitable every quarter and more insolvent every quarter — the same time. This is the classic "growing broke" trap, and it is why cash flow, not the income statement, is the instrument that catches it.

## How to calculate it

The number everyone actually cares about is **Free Cash Flow (FCF)** — the cash left over after the business has paid to keep the lights on *and* funded the investment needed to stay in business. It is what's truly available to pay down debt, buy back stock, pay dividends, or reinvest, without raising a cent from anyone.

```
┌─────────────────────────────┬──────────────────────────────────────────────────┐
│ Metric                      │ Formula                                          │
├─────────────────────────────┼──────────────────────────────────────────────────┤
│ Free Cash Flow (FCF)        │ Operating Cash Flow − Capital Expenditures       │
├─────────────────────────────┼──────────────────────────────────────────────────┤
│ FCF (from the top)          │ EBIT×(1−tax) + D&A − ΔWorking Capital − Capex    │
├─────────────────────────────┼──────────────────────────────────────────────────┤
│ FCF Margin                  │ Free Cash Flow ÷ Revenue                         │
├─────────────────────────────┼──────────────────────────────────────────────────┤
│ Burn Rate (startups)        │ Cash spent per month (net outflow)               │
├─────────────────────────────┼──────────────────────────────────────────────────┤
│ Runway                      │ Cash in bank ÷ Monthly Burn Rate  (= months left)│
├─────────────────────────────┼──────────────────────────────────────────────────┤
│ FCF Yield                   │ Free Cash Flow ÷ Market Capitalization           │
└─────────────────────────────┴──────────────────────────────────────────────────┘
```

Worked numbers: a company reports **$120M operating cash flow** and spends **$30M on capex** → **$90M FCF**. On **$600M revenue** that's a **15% FCF margin** — a strong, self-funding software-like profile. A startup with **$18M in the bank** burning **$1.5M/month** has a **12-month runway** — one year to reach the next milestone or raise again, and the reason "18 months of runway" is the standard fundraising target.

Two flavors of FCF get used in valuation, and mixing them up breaks a model:
- **FCFF (to the firm)** — cash available to *all* capital providers, debt and equity, before interest. Discounted at [[wacc]]. Used in enterprise-value [[dcf]].
- **FCFE (to equity)** — cash left for shareholders *after* debt is serviced. Discounted at cost of equity.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ Strengths                                   │ Limits / traps                              │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Hardest statement to fake — cash either is  │ Lumpy: one big capex quarter or a tax refund│
│ in the bank or it isn't                     │ can distort a single period badly           │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Catches the "profitable but insolvent"      │ Can be flattered short-term by starving      │
│ death that the income statement hides       │ capex, stretching payables, cutting R&D     │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Basis of intrinsic valuation ([[dcf]]) —    │ Negative FCF isn't always bad — heavy        │
│ value = discounted future cash flows        │ reinvestment (Amazon for years) is rational  │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Directly answers "can this survive without  │ Stock-based comp add-back flatters tech FCF; │
│ raising more money?"                        │ it's a real cost to shareholders (dilution) │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Comparable across firms — strips out        │ Backward-looking; DCF forecasts of it are   │
│ accounting-policy and tax differences       │ only as good as the assumptions fed in      │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The single biggest manipulation to watch: a company can *manufacture* a good-looking quarter of operating cash flow by simply not paying its suppliers on time (stretching payables) and by deferring the capex it actually needs. Both boost cash now and mortgage the future. FCF is honest over years; over one quarter it can be dressed up.

## Who uses it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ Why they live on cash flow                                 │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ CFOs / treasurers    │ Day-to-day survival — payroll, supplier terms, covenant    │
│                      │ compliance, liquidity forecasting                          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Founders / startups  │ Burn rate and runway — the number that dictates when the   │
│                      │ next raise must close before the money runs out            │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ VCs                  │ Path-to-cash-generation; post-2022, "efficient growth" and │
│                      │ default-alive over growth-at-all-costs                     │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ PE / LBO buyers      │ FCF services the debt in a buyout — the whole model runs on │
│                      │ predictable cash; EBITDA used as a cash proxy for pricing   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Public equity        │ FCF yield & DCF for intrinsic value; Buffett's "owner       │
│ investors            │ earnings" is essentially FCF                                │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Lenders / banks      │ Can this borrower actually generate the cash to repay?     │
│                      │ Debt covenants are written against cash-flow ratios        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Credit rating agencies│ Cash-flow coverage ratios drive the credit rating          │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## Why it affects IPOs

An IPO is the moment a private company's cash story goes on public trial. Underwriters price the offering, and after listing the market re-prices it every day — both on a forward view of cash generation. For roughly a decade of cheap money, that view could be waved away: growth alone justified the multiple and a public offering was just the next, larger funding round. Since rates rose in 2022, the market flipped hard toward **profitability and a visible path to positive free cash flow**, and the IPO window effectively closed for companies that only had a growth story and a bonfire of cash.

The framework the market now applies to software IPOs is the **[[rule-of-40]]**: growth rate + profit margin should sum to ≥ 40. It exists precisely to force a trade-off between growth and cash generation — you can grow fast and burn, or grow slower and generate cash, but the *sum* must clear the bar. Companies holding a Rule-of-40 score above 40 for three or more consecutive years trade at materially higher multiples. In 2026 the twist is AI: heavy AI capex and compute costs are compressing margins and pushing Rule-of-40 scores *down*, reopening the exact growth-vs-cash tension IPO investors thought they'd settled.

```
┌───────────────┬───────┬───────────────────────────┬──────────────────────────────────┐
│ 2024–25 IPO   │ Price │ Cash-flow story           │ What the market did               │
├───────────────┼───────┼───────────────────────────┼──────────────────────────────────┤
│ Reddit (RDDT) │ $34   │ Long unprofitable, turned │ First profit post-IPO; stock ran  │
│               │       │ its first quarterly profit│ to ~$117 — cash-turn rewarded     │
├───────────────┼───────┼───────────────────────────┼──────────────────────────────────┤
│ CoreWeave     │ $40   │ Rev +737% to $1.9B, but   │ Roughly tripled — but persistent  │
│ (CRWV)        │       │ −$863M net loss, massive  │ debate over when GPU/data-center  │
│               │       │ GPU capex, negative FCF   │ capex ever turns to positive FCF  │
├───────────────┼───────┼───────────────────────────┼──────────────────────────────────┤
│ Circle (CRCL) │ $31   │ Cash-generative on reserve│ More than quadrupled from IPO     │
│               │       │ interest income           │ price                             │
└───────────────┴───────┴───────────────────────────┴──────────────────────────────────┘
```

CoreWeave is the cleanest illustration of the tension: explosive revenue and a $25.9B backlog, yet the entire investment debate is about *cash* — every dollar of growth is consumed by GPUs and data centers, so the question isn't "is it growing?" (obviously) but "when does operating cash flow overtake capex?" That is the difference between a company that lives on the financing bucket forever and one that becomes self-funding. Going public raises capital but also puts the company under a quarterly spotlight to prove exactly that turn. Meanwhile a business like Circle, cash-generative from day one on reserve interest, faces none of that scrutiny — the market pays up for cash it can see.

## What This Means

Cash flow is the ground truth beneath every other financial metric. Profit tells you whether the accounting says you won; cash flow tells you whether you can still open the doors next month. The whole tightening of the market since 2022 — the death of growth-at-all-costs, the Rule-of-40 gate on IPOs, VCs asking startups if they're "default alive" — is a single move: the world remembered that a company is a machine for generating cash, and started paying for the cash instead of the story. If you only ever learn to read one line on one financial statement, make it free cash flow.

## Links

- Free Cash Flow (FCF): Definition & How to Calculate It (Ramp): https://ramp.com/blog/free-cash-flow
- Free cash flow (FCF): Equation and meaning [2026] (QuickBooks): https://quickbooks.intuit.com/r/cash-flow/free-cash-flow/
- Free Cash Flow (FCF) Formula (Corporate Finance Institute): https://corporatefinanceinstitute.com/resources/valuation/fcf-formula-free-cash-flow/
- Free Cash Flow to Firm (FCFF): Formula + Calculator (Wall Street Prep): https://www.wallstreetprep.com/knowledge/free-cash-flow-to-firm-fcff/
- Free Cash Flow Explained: Importance and Calculation (PNC Insights): https://www.pnc.com/insights/small-business/manage-business-finances/free-cash-flow-explained-importance-and-calculation.html
- Discounted Cash Flow: Complete Guide to DCF Valuation (Ramp): https://ramp.com/blog/business-banking/what-is-discounted-cash-flow
- Discounted Cash Flow (DCF) Model: Definition, Formula & Training (Harvard Business School Online): https://online.hbs.edu/blog/post/discounted-cash-flow
- DCF Valuation Framework: Intrinsic Value Calculation Guide 2026 (AL Capital Advisory): https://alcapitaladvisory.com/research/frameworks/dcf.html
- The Rule of 40 in 2026 (CloudZero): https://www.cloudzero.com/blog/rule-of-40/
- Growth, Profitability, and the Rule of 40 for Private SaaS Companies (SaaS Capital): https://www.saas-capital.com/blog-posts/growth-profitability-and-the-rule-of-40-for-private-saas-companies/
- The Rule of 40: A Blueprint for Success (Aventis Advisors): https://aventis-advisors.com/rule-of-40/
- CoreWeave IPO: S-1 Breakdown ($1.9B Revenue) (Mostly Metrics): https://www.mostlymetrics.com/p/coreweave-ipo-s1-breakdown
- Will Circle, CoreWeave Perform Like Past IPO Winners Reddit, Astera Labs? (Benzinga): https://www.benzinga.com/markets/ipos/25/06/45874849/will-rising-stars-circle-coreweave-perform-like-past-ipo-winners-reddit-astera-labs
- Nvidia-Backed CoreWeave Files For IPO, Revenue Surges 737% To $1.9 Billion (Benzinga): https://benzinga.com/news/ipos/25/03/44100280/nvidia-backed-coreweave-files-for-ipo-amid-explosive-ai-growth-revenue-surges-737-to-1-9-billion
