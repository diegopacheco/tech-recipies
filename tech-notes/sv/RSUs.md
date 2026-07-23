# RSUs (Restricted Stock Units)

## What is it?

A **Restricted Stock Unit (RSU)** is a company's promise to give you a set number of its own shares on a future date, *if* you're still there and *if* certain conditions are met. It is not stock — not yet. It is a bookkeeping entry, a unit, that turns into a real share only when it **vests**. Until then you own nothing you can sell, vote, or borrow against; you own a claim on the future. That single word — *restricted* — is the whole idea: the shares exist, they're earmarked for you, but a wall sits between you and them, and the wall comes down on a schedule the company controls.

RSUs are the dominant form of equity pay at public tech companies and, increasingly, at late-stage private ones. They exist because they solve a problem that plain [[stock-options]] don't: an RSU is **always worth something** the moment it vests, because it converts into a share you'd otherwise have to buy. An option can go underwater — if the strike price is above the market price, it's worthless paper. An RSU can't, short of the stock going to literal zero. That makes it a cleaner, lower-risk instrument to hand a rank-and-file engineer, and it's why Big Tech pays most of its "total comp" in RSUs rather than options. The trade-off is that an RSU has no leverage: you get the share, not the multiplied upside of a cheap option in a company that 100x's.

## How it works

An RSU grant moves through a fixed life: **grant → vest → deliver → sell.** You receive a grant (say 4,000 units) with a **vesting schedule** attached. As each tranche vests, the units convert to actual shares that land in your brokerage account. From that moment they're ordinary shares — hold them or sell them, your choice. The tax bill, crucially, is triggered at **vest**, not at grant and not at sale.

```
┌──────────────────────┬──────────────────────────────────────────────────────────┐
│ Vesting type         │ How it triggers                                          │
├──────────────────────┼──────────────────────────────────────────────────────────┤
│ Single-trigger       │ Time only. Common at public companies. Vests on the      │
│ (time-based)         │ calendar date; shares deliver and tax is owed then.      │
├──────────────────────┼──────────────────────────────────────────────────────────┤
│ Double-trigger       │ Time AND a liquidity event (IPO / acquisition). Standard │
│                      │ at private/pre-IPO firms — no tax until you can actually │
│                      │ sell. If the company never exits, the RSUs never vest.   │
├──────────────────────┼──────────────────────────────────────────────────────────┤
│ Performance (PSUs)   │ Vesting tied to metrics — revenue, TSR, milestones.      │
│                      │ Common for executives; payout can be 0–200%+ of target.  │
└──────────────────────┴──────────────────────────────────────────────────────────┘
```

The typical public-company schedule is **4 years with a 1-year cliff**: nothing vests for the first 12 months, then 25% lands at once, then the rest drips monthly or quarterly. The **cliff** protects the company from paying equity to someone who leaves in month three. Leave before the cliff and you walk away with zero.

The **double-trigger** design is the important twist for startups. A single time-based trigger at a *private* company is a trap: the units would vest, ordinary income tax would be owed on shares you *cannot sell* to pay that tax. Double-trigger defers everything — no shares delivered, no tax owed — until an IPO or acquisition creates a market. That's why pre-IPO firms like Stripe, Databricks, and their peers use it. The catch: if the exit never comes, the second trigger never fires, and years of "vested" time-based units deliver nothing.

## How is it calculated

An RSU's value is brutally simple: **shares × price**, with no strike price to subtract (unlike an [[stock-options]] grant). The complexity is entirely in the tax.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Quantity                   │ Formula                                            │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Grant value                │ # units × share price at grant (target $ figure)   │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Ordinary income at vest    │ # units vesting × Fair Market Value on vest date   │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Cost basis                 │ = FMV on vest date (the amount already taxed)      │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Capital gain/loss at sale  │ (sale price − vest-date FMV) × shares              │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

At vest, the full market value of the vested shares is added to your W-2 as **ordinary income** — taxed at your marginal federal rate plus state, local, Social Security, and Medicare, exactly like salary. The **withholding trap** catches thousands every April: employers withhold federal tax at a **flat 22%**, but if your income puts you in the 32% or 37% bracket, you're under-withheld on every RSU dollar and owe the gap. Later, when you *sell*, only the change in price *since vesting* is a capital gain (or loss). Sell immediately at vest and there's near-zero capital gain — the whole value was already taxed as income.

Worked example: 1,000 units vest when the stock is **$80**. That's **$80,000** of ordinary income on your W-2 this year. Your employer withholds 22% ($17,600) but you're a 35%-bracket earner — you actually owe ~$28,000, so ~$10,400 is due at tax time. Your cost basis is $80/share. If you hold and sell later at $110, the extra $30/share ($30,000) is a capital gain, long-term if you held over a year.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Stage                │ Typical RSU practice                                       │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech / public    │ RSUs are the core of total comp. 4-yr vest, 1-yr cliff.    │
│ (FAANG-tier)         │ Refresh grants every year; "sell-to-cover" auto-sells      │
│                      │ enough shares at vest to pay withholding.                  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Late-stage private   │ Double-trigger RSUs (time + IPO). Deferred tax until exit. │
│ (pre-IPO unicorns)   │ Grants expire (often ~7 yrs) if no liquidity event.        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Early-stage startup  │ Rarely RSUs — they use [[stock-options]] instead, because  │
│                      │ options can be granted at a low strike with real upside    │
│                      │ leverage and no tax at grant.                              │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Executives           │ Performance RSUs (PSUs) tied to TSR / financial targets,   │
│                      │ so pay aligns with shareholder outcomes.                   │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The rule of thumb: **options early, RSUs late.** A seed-stage company's stock is worth pennies, so cheap options with huge upside make sense and there's no tax problem. Once a company is worth billions, options would carry strike prices too expensive for employees to exercise, and the share price is high enough that RSUs are simply worth real money on day one — so the whole industry converts to RSUs as it matures. Back-loaded schedules and large front-loaded [[bonus]] payments are often used together to smooth the thin first-year equity.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ Strengths                                   │ Limits / traps                              │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Always worth something at vest — can't go   │ No leverage: you get the share, not the      │
│ underwater like an option                   │ multiplied upside of a cheap option          │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Simple to understand — no strike price, no  │ Taxed as ordinary income at vest whether or  │
│ exercise decision, no AMT                   │ not you sell — a phantom-income surprise     │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Strong golden-handcuff retention — leaving  │ 22% flat withholding under-covers high       │
│ forfeits unvested units                     │ earners → surprise April tax bill            │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Diversify freely once vested (sell same day)│ Double-trigger: if the company never exits,  │
│                                             │ time-vested RSUs deliver nothing             │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Value tracks the stock 1:1 — clean, no      │ Concentration risk: comp + net worth both    │
│ modeling needed                             │ ride on one employer's stock                 │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The subtlest trap is **phantom income**: at vest you owe real cash tax on shares you might not have sold. If the stock then falls, you can end up having paid tax on a value that evaporated — the classic story of 2000 and 2022 employees taxed at the peak on shares that later cratered. The defense is simple and unpopular: sell at vest and diversify, treating each vest as a cash bonus that happens to arrive as stock.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use RSUs                                          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech             │ Apple, Google, Amazon, Meta, Microsoft, Nvidia — RSUs are  │
│                      │ the majority of senior-engineer total comp                 │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Pre-IPO unicorns     │ Stripe, Databricks, and peers use double-trigger RSUs to   │
│                      │ hold talent through to a liquidity event                   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Employees            │ The instrument most rank-and-file tech workers hold; the   │
│                      │ vest calendar drives personal cash-flow and tax planning   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Boards / comp cmtes  │ Set grant sizes, refresh cadence, and PSU targets to align │
│                      │ pay with retention and shareholder return                  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Wealth advisors      │ Build sell/hold/diversify plans around vest dates and the  │
│                      │ withholding gap                                            │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

RSUs are equity for grown-up companies. They trade the lottery-ticket upside of [[stock-options]] for certainty: a share that's worth real money the day it vests, taxed like salary, with retention baked in through the vesting wall. For the employee the whole game reduces to two disciplines — plan for the tax that hits at vest whether you sell or not, and resist the pull to let your paycheck and your portfolio both ride on a single stock. Understand that the value is only ever `shares × price`, and that the interesting complexity lives entirely in *when* the tax lands, and you understand RSUs.

## Links

- How Restricted Stock Units (RSUs) Work: Complete Guide (Smart Finance): https://smartfinance.fyi/articles/rsu-complete-guide-2026
- RSU Tax Guide 2026: Vesting, Sell-to-Cover, and the Withholding Shortfall (National Tax Tools): https://nationaltaxtools.com/guides/rsu-tax/
- RSU Tax Guide 2026: How Restricted Stock Units Are Taxed (Country Tax Calc): https://www.countrytaxcalc.com/tax-guides/rsu-tax-guide-2026/
- RSU Guide: Tax and Vesting for Tech Professionals 2026 (Safe Landing Financial): https://safelandingfinancial.com/rsus/
- Double-Trigger RSUs: What You Need to Know (RLN Wealth): https://rlnwealth.com/double-trigger-rsus-what-you-need-to-know/
- Pre-IPO Tech Giants Using "Double-Trigger" RSU Vesting to Attract Talent (Savant Wealth): https://savantwealth.com/savant-views-news/article/pre-ipo-tech-giants-using-double-trigger-rsu-vesting-to-attract-talent/
- Double-Trigger RSUs Explained: Taxes, Vesting & What to Expect at IPO (Authentic Life FP): https://www.authenticlifefp.com/blog/double-trigger-rsus
- Restricted Stock Units: Taxes, Vesting and Key RSU Facts (Darrow Wealth Management): https://darrowwealthmanagement.com/blog/restricted-stock-units/
- What are RSUs and how do they work — 2026 guide (Wise): https://wise.com/gb/blog/what-are-rsus
