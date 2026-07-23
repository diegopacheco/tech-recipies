# Bonus

## What is it?

A **bonus** is compensation paid *on top of* base salary — cash (usually) handed over for a reason beyond simply showing up: hitting a target, joining, staying, or delivering something specific. Where base salary is the fixed, guaranteed floor of your pay, a bonus is **variable**: its size and its existence both flex with performance, circumstance, or a promise the company made to get you in the door. That variability is the entire point. A bonus lets a company pay for *outcomes* rather than *time*, dangle cash to win a hire, and reward the year that went well without permanently raising the salary line it has to fund forever.

Bonuses matter because they're the most flexible lever in a comp package and the one most exposed to conditions. Unlike a raise, a bonus doesn't compound into next year's base. Unlike [[RSUs]] or [[stock-options]], it's usually cash you can spend immediately — no vesting, no strike price, no waiting for a liquidity event. But that immediacy comes wrapped in strings: performance gates, clawback clauses, retention dates. The bonus is where a company's real priorities show, because it's the pay it hands out only when it gets what it wanted.

## How it works

A bonus is defined by its **trigger** — the condition that releases the money — and there are several distinct kinds, each solving a different problem for the company.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Type                 │ Trigger / purpose                                          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Annual / performance │ Paid after the yearly review. Tied to individual + company │
│                      │ performance. The main recurring bonus; a % of salary.      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Signing / sign-on    │ One-time, paid to accept an offer. Wins the hire and offsets│
│                      │ a competing offer or thin first-year equity. Often clawed  │
│                      │ back if you leave early.                                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Retention / stay     │ Paid to a key person to stay through a date/milestone       │
│                      │ (acquisition, migration). 12–24 month strings attached.    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Spot / discretionary │ Surprise reward for a specific contribution, outside the    │
│                      │ review cycle. Small, fast, morale-focused.                 │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Milestone / referral │ Tied to a concrete event — shipping a project, referring a │
│                      │ hire who sticks. Directly outcome-linked.                  │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The **annual bonus** is the one most people mean. It's set as a **target percentage of base salary** (your "target bonus"), then modulated up or down by a **company performance multiplier** and an **individual performance multiplier**. A great year for you at a great year for the company pays well above target; a company miss can zero it out no matter how well you personally did.

The **signing bonus** exists mostly to solve a timing problem. Tech equity ([[RSUs]]/[[stock-options]]) vests on a back-loaded schedule — little in year one — so a company front-loads cash to make the first-year total competitive. That's why signing bonuses cluster at hiring surges and why they carry **clawbacks**: leave within (typically) 6–24 months and you repay some or all of it.

## How is it calculated

The annual bonus is the one with real arithmetic; most other types are flat negotiated amounts.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Quantity                   │ Formula                                            │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Target bonus               │ base salary × target bonus %                       │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Actual annual bonus        │ target bonus × company multiplier × individual mult│
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Clawback owed (signing)    │ signing bonus × (unserved months ÷ clawback period)│
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Federal tax withholding    │ flat 22% supplemental rate (37% above $1M/yr)      │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

Worked example: base salary **$180,000**, target bonus **15%** → target of **$27,000**. The company hits its plan (multiplier **1.0**) and you had a strong year (individual multiplier **1.2**) → actual bonus **$32,400**. On the tax side, the IRS treats bonuses as **supplemental wages**, withheld at a **flat 22%** federal rate (37% on amounts over $1M) — separate from your salary withholding, which is why a bonus often *looks* under-taxed on the payslip and gets trued-up at filing, the mirror image of the [[RSUs]] withholding gap.

A signing-bonus clawback: you took a **$40,000** signing bonus with a **24-month** clawback and leave after **9 months**. Unserved = 15 months → you may owe **$40,000 × 15/24 = $25,000** back. Terms vary — some are all-or-nothing, some prorate like this.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Setting              │ Typical bonus practice                                     │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech             │ Annual target bonus ~10–20% of base, tied to company +     │
│                      │ individual perf. Large signing bonuses ($50k–$150k for     │
│                      │ senior eng in hot markets) to offset back-loaded equity.   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups             │ Cash bonuses are rare/small — cash is scarce. They lean on │
│                      │ [[stock-options]] for upside; use signing & referral       │
│                      │ bonuses to accelerate hiring, spot bonuses for morale.     │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ During M&A           │ Retention bonuses (10–25% specialists, 25–50% managers,    │
│                      │ 50%+ execs) to hold key people through the deal.           │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Sales roles          │ Commission + on-target-earnings (OTE) rather than a % bonus;│
│                      │ pay scales directly with quota attainment.                 │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The split is stark: **established companies pay cash bonuses, startups mostly don't.** A startup guards its [[cash-flow]] and pays upside in equity, reserving cash bonuses for the narrow cases where cash is the only tool that works — winning a specific hire (signing), sourcing talent (referral), or a cheap morale win (spot). Big Tech, sitting on cash, runs a full annual-bonus machine and adds signing bonuses precisely to paper over the thin first year of [[RSUs]]. A notable 2023 wrinkle: during layoffs, Google and Meta *waived* signing-bonus clawbacks for laid-off staff, while others enforced them strictly — a reminder that clawback terms are contract, not law.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ Strengths                                   │ Limits / traps                              │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Immediate cash — no vesting, no strike, no  │ Variable and often discretionary — can       │
│ liquidity event needed                      │ shrink or vanish in a bad company year       │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Pays for outcomes, not time — sharp         │ Doesn't compound: unlike a raise, it resets  │
│ incentive alignment                         │ to zero every year                           │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Flexible lever — company rewards a good year│ Signing/retention clawbacks lock you in; owe │
│ without permanently raising the salary line │ money back if you leave early                │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Signing bonus offsets thin first-year equity│ 22% flat withholding can under- or over-tax; │
│                                             │ trued up at filing                          │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Fast to deploy (spot bonuses) for morale    │ Gameable targets can drive short-term        │
│                                             │ behavior over long-term health              │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The core tension: a bonus is the most *responsive* pay a company has and the least *reliable* pay an employee has. Because it doesn't compound and can be cut, a heavily bonus-weighted package shifts risk onto the worker — great in boom years, painful when the company multiplier goes to zero. And any bonus tied to a metric invites gaming that metric; a bonus is only as good as the target behind it — the trigger has to reward *why* the outcome matters, not just a number that's easy to hit.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use bonuses                                       │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech / corporates│ Full annual bonus programs + large signing bonuses to win  │
│                      │ and retain senior engineers and PMs                        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups             │ Signing and referral bonuses to speed hiring; spot bonuses │
│                      │ for morale — cash bonuses otherwise minimal                │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Acquirers (M&A)      │ Retention bonuses to keep critical talent through and after│
│                      │ a deal closes                                              │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Sales orgs           │ Commission/OTE structures — the purest pay-for-outcome     │
│                      │ bonus model                                                │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Consulting / finance │ Among the highest bonus-as-%-of-base ratios of any         │
│                      │ industry; large signing bonuses for new hires              │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

A bonus is the flexible, conditional layer of pay — cash the company releases only when it gets the outcome, the hire, or the stay it wanted. For the employee it's the best and worst kind of compensation at once: immediate and spendable, unlike [[RSUs]] or [[stock-options]], but non-compounding and revocable, unlike base salary. The practical reads are three: know your *target* bonus and what actually moves the multipliers; treat any signing or retention bonus as a *loan you earn out* over the clawback period, not free money; and plan for the 22% flat withholding to under-cover you at tax time. Salary is what you're paid to show up; a bonus is what you're paid to *win* — and the strings on it tell you exactly what winning means to your employer.

## Links

- Average Bonus Percentage in Tech: What the Data Shows (Pave): https://www.pave.com/blog-posts/average-bonus-percentage-tech
- Average bonus percentage by industry in 2026 (Oyster): https://www.oysterhr.com/library/what-is-a-good-bonus-percentage
- Employee Bonus Guide: Types of Bonuses & Plan Structures (Business.com): https://www.business.com/articles/employee-bonuses/
- Signing Bonus Guide 2026: Amounts by Role, Clawbacks & Tax Rules (Treegarden): https://treegarden.io/blog/signing-bonus-best-practices-us/
- Most Common Types of Bonuses and How They Work (Indeed): https://www.indeed.com/career-advice/career-development/bonuses
- Retention Bonus Guide 2026: How to Keep Your Best Talent (Qobra): https://www.qobra.co/blog/retention-bonus
- Using Sign-On Bonuses With Clawback Provisions (Aaron Hall, Attorney): https://aaronhall.com/using-sign-on-bonuses-with-clawback-provisions/
- The 15 Tech Companies With the Highest Signing Bonuses (Entrepreneur): https://www.entrepreneur.com/money-finance/the-15-tech-companies-with-the-highest-signing-bonuses/304043
- Signing Bonus Clawback After Layoff 2026 (SeveranceCalc): https://severancecalc.com/blog/signing-bonus-clawback-severance
