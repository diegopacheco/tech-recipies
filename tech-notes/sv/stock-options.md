# Stock Options

## What is it?

A **stock option** is the *right* — not the obligation — to buy a set number of your company's shares at a fixed price, called the **strike price** (or exercise price), for a set window of time. That's the entire idea. The company hands you a coupon that says "you may buy 10,000 shares at $2 each, anytime in the next 10 years." If the shares are later worth $50, you buy at $2 and pocket the $48 spread. If they're worth $1, you tear up the coupon and lose nothing but the opportunity. An option is a bet on the *direction* of the stock, bought with a locked-in price today.

That optionality is the whole reason startups pay in options rather than [[RSUs]]. Early-stage shares are worth almost nothing, so a low strike price is cheap to grant and carries enormous leverage: a $0.10 strike on stock that IPOs at $40 is a 400x return per share. Options turn employees into leveraged owners of the upside, which is exactly the incentive a startup wants — everyone rowing toward the same exit. The flip side is the word *option* cuts both ways: an option whose strike sits above the market price is **underwater** and worth exactly nothing, which is the fate of most startup options because most startups fail. It is a lottery ticket with a strike price, and understanding options means understanding that asymmetry.

## How it works

An option moves through four stages: **grant → vest → exercise → sell.** You're *granted* the option with a strike price and a vesting schedule (classically 4 years, 1-year cliff — same shape as [[RSUs]]). As it *vests*, you earn the right to *exercise* — to actually pay the strike price and convert options into shares. Finally you *sell* the shares, ideally for far more than you paid. Nothing is owed at grant; the tax events cluster around exercise and sale, and they differ sharply by option type.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Type                 │ What it is / who gets it                                   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ ISO                  │ Incentive Stock Option. Employees only. Tax-favored: no    │
│ (Incentive)          │ ordinary income at exercise; can reach long-term capital   │
│                      │ gains — but the exercise spread triggers AMT.              │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ NSO / NQSO           │ Non-qualified Stock Option. Anyone — employees,            │
│ (Non-qualified)      │ contractors, advisors, board. Spread at exercise is taxed  │
│                      │ as ordinary income immediately. Simpler, less favorable.   │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The **strike price** cannot be set arbitrarily. For a private company it's fixed by a **409A valuation** — an independent appraisal of the fair market value (FMV) of the stock. The IRS requires options be struck at *no less than* FMV at grant; strike below it and both company and employee face brutal 409A penalties. Companies must refresh the 409A at least every 12 months, or sooner on a "material event" like a new funding round. This is why joining *before* a big round matters so much: your strike is locked to the old, lower valuation, and the next round marks the stock up above it.

## How is it calculated

The value of an option is the **spread**: what the shares are worth minus what you pay for them. The tax layered on top is where ISOs and NSOs diverge.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Quantity                   │ Formula                                            │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Cost to exercise           │ # options × strike price                           │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Spread (bargain element)   │ (FMV at exercise − strike) × # shares              │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ NSO tax at exercise        │ spread taxed as ordinary income (now)              │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ ISO at exercise            │ no ordinary income; spread is an AMT preference item│
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Gain at sale               │ (sale price − FMV-at-exercise) × shares → cap gain │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

Worked example: you hold **10,000 ISOs** struck at **$2**. The current 409A FMV is **$10**. Exercising costs **$20,000** (10,000 × $2). The spread is **$80,000** ((10 − 2) × 10,000) — with an ISO you owe *no* ordinary income tax on that, but the $80,000 is added to your **AMT** calculation and may generate a real cash tax bill even though you've sold nothing. Had these been NSOs, that $80,000 spread would be ordinary income the day you exercise, taxed at your full marginal rate. Later, if you sell the shares at $30, the extra $20/share ($200,000) is a capital gain — long-term (and lower-taxed) if you held the shares over a year from exercise and two years from grant.

Three rules that quietly govern everything:

- **The $100k ISO limit.** If more than **$100,000** of ISOs (measured by strike-price value) becomes exercisable for the first time in one calendar year, the excess is automatically treated as NSOs. Vesting schedules are structured around this cap.
- **The 83(b) election / early exercise.** Some plans let you exercise *before* vesting. Pairing early exercise with an **83(b) election** (filed within 30 days, now via IRS Form 15620) taxes the spread while it's ~zero, starting the capital-gains clock immediately. Powerful for founders and very early employees when the strike ≈ FMV.
- **AMT is a cash-flow trap.** Exercising ISOs early, while FMV is close to the strike, keeps the spread small and the AMT hit small. Wait until the stock has 10x'd and the AMT on a huge paper spread can exceed the cash you have — for stock you still can't sell.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Stage                │ Typical option practice                                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Seed / early-stage   │ ISOs to employees, NSOs to advisors/contractors. Low       │
│                      │ strike from an early 409A. 4-yr vest, 1-yr cliff.          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Growth-stage private │ Still options, higher strikes as 409A climbs. Some offer   │
│                      │ early exercise + 83(b); extended post-termination exercise │
│                      │ windows (from 90 days to years) as a perk.                 │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Late-stage / pre-IPO │ Shift toward double-trigger [[RSUs]] — strike prices grow  │
│                      │ too high and share value too real for options to make      │
│                      │ sense for new hires.                                       │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Public companies     │ Mostly [[RSUs]] for staff; options survive mainly for      │
│                      │ executives as a leveraged, upside-only incentive.          │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The industry pattern mirrors [[RSUs]] exactly, from the other side: **options are the instrument of the cheap, risky, early company.** The classic 90-day post-termination exercise window is the harshest term for employees — leave and you have 90 days to find (often) tens of thousands in cash to exercise or forfeit everything you vested. The employee-friendly reform, popularized by companies like Pinterest and Coinbase, is extending that window to 7–10 years, so leaving doesn't force an immediate, expensive exercise decision.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ Strengths                                   │ Limits / traps                              │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Massive leverage — a low strike on a stock  │ Can go underwater and be worth exactly zero  │
│ that 100x's is life-changing                │ if the strike sits above market price        │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ No tax at grant; ISOs defer/avoid ordinary  │ Exercising costs real cash up front — and    │
│ income entirely                             │ AMT can hit before you can sell a thing      │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ ISOs can reach lower long-term capital      │ 90-day exercise window on leaving forces a   │
│ gains rates if held long enough             │ pay-or-forfeit cash decision                 │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Aligns employees with the exit — pure       │ Complex: ISO vs NSO, 409A, AMT, $100k limit, │
│ upside incentive                            │ 83(b), holding periods — easy to get wrong   │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ 83(b) + early exercise can start the        │ Illiquid — you may owe tax on a private      │
│ cap-gains clock while the spread is ~zero   │ paper gain you cannot turn into cash         │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The defining trap is the collision of **AMT and illiquidity**: exercise ISOs after the company has 10x'd and you can owe a large cash tax bill on a paper spread, for shares in a private company you cannot sell to pay it. Whole cottage industries (secondary sales, exercise-financing lenders) exist to solve exactly this. The rule of thumb — *exercise early when the spread is small, or wait for real liquidity* — exists because the middle path can bankrupt you.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use stock options                                 │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups             │ The core equity currency of Silicon Valley — how early     │
│                      │ employees are paid in upside instead of cash                │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Founders             │ Early exercise + 83(b) at near-zero strike to lock in       │
│                      │ long-term capital gains treatment                          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Advisors / board     │ NSOs (they aren't employees, so can't get ISOs) as          │
│                      │ compensation for guidance and connections                  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Public execs         │ Options as a leveraged, shareholder-aligned slice of pay   │
│                      │ alongside [[RSUs]] and cash [[bonus]]                      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ 409A appraisers /    │ Independent valuation firms set the FMV that anchors every │
│ wealth advisors      │ strike price; advisors model AMT and exercise timing       │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

Stock options are a leveraged bet on a company's future, structured as a right to buy at yesterday's price. That leverage is the entire appeal — it's how a startup with no cash pays people in the possibility of getting rich — and its fragility is the entire risk: most options end underwater and worthless, and even the winners hide a tax-and-cash minefield (409A, AMT, the 90-day window, the $100k limit) between vesting and money in the bank. The mature-company answer to all that complexity is to stop using options and switch to [[RSUs]], which is exactly why options are the language of the early startup and RSUs the language of Big Tech. If you hold options, the two decisions that matter most are *when to exercise* and *how to survive the AMT* — get those right and the leverage works for you.

## Links

- ISO vs NSO Stock Options for Startups: Tax Treatment & Eligibility (Angel Investors Network): https://angelinvestorsnetwork.com/startups/iso-vs-nso-stock-options-for-startups
- What is a 409A Valuation? Understanding Fair Market Value for Startup Stock Options (Secfi): https://secfi.com/learn/409a-valuation-stock-options-startup
- How Does a 409A Valuation Determine Your Stock Option Strike Price? (Qapita): https://www.qapita.com/blog/409a-valuation-strike-price
- Stock Options Tax Guide 2026: ISO vs NSO, AMT, and State Tax Differences (Country Tax Calc): https://www.countrytaxcalc.com/tax-guides/usa/stock-options-tax-guide-2026/
- 83(b) Election and Early ISO Exercise (Phoenix Strategy Group): https://www.phoenixstrategy.group/blog/83b-election-and-early-iso-exercise
- 83(b) election for stock options: when it makes sense to file (Secfi): https://secfi.com/learn/83b-election
- Should You Early Exercise Stock Options? ISOs, NSOs & 83(b) Guide (VIP Wealth Advisors): https://vipwealthadvisors.com/insights/early-exercise-stock-options-iso-nso-83b-election
- 409A Valuation & Stock Options: Compliance & Best Practices (Eqvista): https://eqvista.com/409a-valuation/employee-stock-options-409a-valuations/
- Early Exercise Options with an 83(b) Election (ESO Fund): https://www.esofund.com/blog/early-exercise-options-83b-election
