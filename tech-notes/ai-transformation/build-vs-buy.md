# Build vs Buy — The AI Flip

## What is it?

The economic calculus between buying SaaS and building custom software has fundamentally reversed. Agentic coding tools collapsed development costs by orders of magnitude while enterprise software pricing stayed the same or increased. This is not a cyclical dip — it is a structural market shift. The SaaSpocalypse of 2026 wiped over $2 trillion in software market capitalization between January and February 2026. For the first time in history, SaaS stocks trade at a discount to the S&P 500.

## The Build-Cost Collapse

```
┌───────────────────────────────────────────────────────────────┐
│              What Changed                                      │
│                                                               │
│  Old Economics (Pre-AI):                                      │
│    - Building a platform: 18 months, 8 engineers              │
│    - Rebuilding on different arch: equivalent time/resources   │
│    - Switching cost exceeded tolerating bad software           │
│    - "We already built it" was a rational defense              │
│                                                               │
│  New Economics (AI Era):                                       ���
│    - Two-person teams scaffold replacements in days            │
│    - Proof-of-concept alternatives validate in hours           │
│    - Cloudflare rebuilt Next.js components for $1,100          │
│    - Anthropic built 100K lines of C compiler for $20K         │
│    - The generic 80% of functionality is effectively free      │
│    - The custom 20% takes hours instead of weeks               │
│                                                               │
│  The "buy" side showed no corresponding cost reduction.        │
│  Pricing, complexity, and lock-in persisted.                   │
│  The equation flipped.                                         │
└───────────────────────────────────────────────────────────────┘
```

## The SaaSpocalypse

```
┌────────────────────────────────────────┬────────────────────────────────┐
│ Metric                                 │ Value                          │
├────────────────────────────────────────┼────────────────────────────────┤
│ Software market cap wiped (Jan-Feb 26) │ ~$2 trillion                   │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian stock (from 2021 peak)       │ -80%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian revenue growth (same period) │ +23%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian first-ever enterprise seat   │ Triggered 35% stock drop       │
│ count decline                          │                                │
├────────────────────────────────────────┼────────────────────────────────┤
│ Atlassian layoffs                      │ 1,600 (10% workforce)          │
├────────────────────────────────────────┼────────────────────────────────┤
│ Salesforce YTD                         │ -33%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ Adobe YTD                              │ -27%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ SaaS forward earnings multiples        │ 39x → 21x                     │
├────────────────────────────────────────┼────────────────────────────────┤
│ Thomson Reuters (after Anthropic demo) │ -16%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ LegalZoom (after Anthropic demo)       │ -20%                           │
├────────────────────────────────────────┼────────────────────────────────┤
│ IBM (after COBOL modernization demo)   │ -13% (worst day in 25 years)   │
├────────────────────────────────────────┼────────────────────────────────┤
│ Block (Dorsey) layoffs                 │ 40% workforce, stock +24%      │
├────────────────────────────────────────┼────────────────────────────────┤
│ Enterprises replacing SaaS with custom │ 35% (Retool 2026 report)       │
├────────────────────────────────────────┼────────────────────────────────┤
│ Planning to build more custom in 2026  │ 78%                            │
├────────────────────────────────────────┼────────────────────────────────┤
│ Built software outside IT oversight    │ 60%                            │
└────────────────────────────────────────┴────────────────────────────────┘
```

The per-seat pricing model — the engine of SaaS revenue growth — depends on: more employees = more seats = more revenue. AI agents break this equation. When one agent handles the work of five CRM operators, the customer does not need five seats. Revenue collapses even if work output stays constant.

## The Seat Compression Problem

```
┌─��─────────────────────────────────────────────────────────────┐
│              Per-Seat Revenue Death Spiral                     │
│                                                               │
│  SaaS model:  revenue = seats × price_per_seat               │
│                                                               │
│  AI agents reduce headcount                                   │
│    → fewer employees need fewer seats                         │
│    → revenue shrinks even if work output grows                │
│                                                               │
│  Companies selling collaboration tools are cutting their      │
│  own user base — admission the per-seat model shrinks from    │
│  both directions:                                             │
│    - Customers need fewer seats (agents replace workers)      │
│    - Vendors need fewer people building products              │
│                                                               │
│  Atlassian: 10% layoff, stock +4%                             │
│  Block: 40% layoff, stock +24%                                │
│  Market rewards headcount reduction regardless of cause.      │
│  Dorsey's playbook: frame cuts as "AI pivot," collect stock   ��
│  bump. Others follow.                                         │
└───────────────────────────────────────────────────────────────┘
```

## What "Buying" Actually Meant

What enterprises called "buying" software was never a purchase:

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ What They Called It       │ What It Actually Was                          │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Licensing                │ Recurring rental with annual price increases  │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Implementation           │ Multi-month customization with consultants    │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Integration              │ Expensive glue to connect to existing systems │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Adoption                 │ Forced acceptance of vendor workflows         │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Data migration           │ Complete lock-in to proprietary formats       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Total cost of ownership  │ Vastly exceeds sticker price                  │
└──────────────────────────┴───────────────────────────────────────────────┘
```

The total cost of buying was always higher than advertised. Building was just costlier. That second part is no longer true.

## Categories Most Vulnerable

Narrow workflow tools with per-seat pricing and 80% generic functionality are being replaced first:

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Category                 │ Why It Falls First                            │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Admin panels/dashboards  │ CRUD + views. Agents scaffold in hours.       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Approval flows           │ Linear workflows. Trivial to automate.        │
├──────────────────────────┼───────────────────────────────────────────────┤
│ CRM systems              │ Customer data + pipeline views. Per-seat      │
│                          │ pricing makes replacement math obvious.       │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Project management       │ Boards, ticketing, status tracking.           │
│                          │ Agent-native alternatives emerging (Flux).    │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Support ticketing        │ Templated responses, routing, escalation.     │
│                          │ Agents handle the generic 80%.                │
└──────────────────────────┴───────────────────────────────────────────────┘
```

## The Sunk Cost Fallacy Is Dead

The traditional defense of past technology investments — "we already built it" / "we already paid for it" — lost its rational foundation when rebuild costs collapsed.

```
┌───────────────────────────────────────────────────────────────┐
│              The Sunk Cost Shift                               │
│                                                               │
│  Old world:                                                   │
│    "We invested 18 months in Flutter" = stay in Flutter       │
│    "We migrated to microservices" = architecture is settled   │
│    "We chose Salesforce" = Salesforce forever                 │
│    Rebuilding genuinely cost as much as the original build.   │
│    Sunk cost arguments had economic legitimacy.               │
│                                                               │
│  New world:                                                   │
│    Levelsio built Uptimerobot clone in 5 hours with Claude    │
│    Code, deleted it 2 days later when better options emerged. │
│    Dave Clark (ex-Amazon exec) rebuilt 3 systems in a weekend │
│    that previously required months.                           │
│    Y Combinator: 25% of W25 companies had codebases 95%      │
│    AI-generated.                                              │
│                                                               │
│  The rebuild threshold moved dramatically.                    │
│  A 2-year, 8-person project might now be 2 months with 2     │
│  people. Still challenging — but fundamentally different       │
│  economics.                                                   │
│                                                               │
│  The sunk cost fallacy persists not from stupidity but        │
│  because admitting past decisions were wrong threatens        │
│  careers, budgets, and organizational hierarchies.            │
│  Real lock-in is cultural, not technical.                     │
└───────────────────────────────────────────────────────────────┘
```

Research shows sunk cost bias costs organizations billions annually: 70% of mergers fail, 66% of IT projects end in partial/total failure. Companies like Kodak, Nokia, and Blockbuster exemplify organizations investing in dying models while ignoring disruption.

## Test Suites as Machine-Readable Specifications

The Vinext case demonstrates the most concrete mechanism of how build costs collapsed. Cloudflare reimplemented the Next.js public API surface in 7 days for $1,100.

```
┌───────────────────────────────────────────────────────────────┐
│              The Vinext Method                                  │
│                                                               │
│  Team: 1 engineering manager (not an IC)                      │
│  Tool: Claude Opus 4.6 with maximum thinking                  │
│  Sessions: 800 Claude sessions                                │
│  Cost: $1,100 in API tokens                                   │
│  Time: 7 days                                                 │
│  Coverage: 94% of Next.js 16 API surface                      │
│                                                               │
│  Build time: 1.67s vs 7.38s (4.4x faster)                    │
│  Client bundle: 72.9 KB vs 168.9 KB gzipped (57% smaller)    │
│  Tests: 1,700+ unit, 380 E2E                                  ��
│                                                               │
│  The method:                                                  │
│    1. Two hours upfront architecture planning with Claude     │
│    2. Define task → AI writes implementation + tests          │
│    3. Run test suite                                          │
│    4. Merge if passing, iterate with error output if not      │
│                                                               │
│  The test suite WAS the acceptance criteria.                  │
│  The AI did not need to understand human intent.              │
│  It needed to make assertions pass.                           │
└───────────────────────────────────────────────────────────────┘
```

### The Moat Question

If competitive advantage depends on implementation complexity, and the test suite is publicly available, has the framework author published the blueprint for their own replacement?

```
┌───────────────────────────────────────────────────────────────┐
│              Moat Erosion Pattern                               │
│                                                               │
│  Old moat: internals are complex and unpredictably mutable.   │
│  OpenNext had to reverse-engineer build output each release.  │
│  This worked against human engineers.                         │
│                                                               ��
│  AI moat-break: reimplements public API from scratch in a     │
│  week. Ignores internals entirely.                            │
│                                                               │
│  Comprehensive test suites + capable models =                 │
│  reimplementation costs approaching zero.                     │
│                                                               │
│  The pattern commoditizes whatever it touches.                │
│  If Vinext succeeds, its own test suite becomes a spec.       │
│  Any platform reimplements Vinext using identical method.     │
│                                                               │
│  Will frameworks begin treating test suites as proprietary?   │
│  SQLite already does: closed-source tests, public domain DB.  │
│                                                               │
│  Moats shift from "we built it first" to "we maintain it     │
│  best" and "our ecosystem is stickiest."                      │
└───────────────────────────────────────────────────────────────┘
```

### The Security Bill

Vinext shipped with 45 vulnerabilities (24 validated), including race conditions, cross-request state pollution, and unsafe global fallbacks. Vercel's CEO personally found 7 (two critical). Vercel published a migration guide back to Vercel and collected Cloudflare's bug bounty money.

Test suites rarely encode the absence of vulnerabilities. Passing functional tests proves functional parity, not security parity. The test-suites-as-specs pattern is valid — but building the first 90% is not the same as building production-ready software.

## The 90/90 Rule Still Applies

```
┌───────────────────────────────────────────────────────────────┐
│              What AI Does and Does Not Solve                   │
│                                                               │
│  AI's sweet spot (the first 90%):                             │
│    - Scaffolding, boilerplate, standard patterns              │
│    - CRUD, plumbing, generic workflows                        │
│    - Previously months, now hours                             │
│                                                               │
│  AI's weak spot (the other 90%):                              ���
│    - Edge cases and legacy system integration                 │
���    - Production hardening and performance optimization        │
│    - Compliance requirements (SOC 2, HIPAA, PCI-DSS)         │
│    - Undocumented business rules living in spreadsheets       │
│    - Security vulnerabilities not covered by test suites      │
│                                                               │
│  The "vibe coding hangover":                                  │
│    Teams build rapidly with AI, celebrate success, then       │
│    months later cannot explain how the code works.            │
│    Original prompts are lost. Architecture is mysterious.     │
│    Changes break unexpectedly. Bus factor drops to zero.      │
│                                                               │
│  Maintenance is 60-70% of total cost of ownership.            │
│  Development is only 30-40% of a custom system's 3-year TCO. │
│  AI collapsed the 30-40%. The 60-70% remains.                 │
└───────────────────────────────────────────────────────────────┘
```

## Where "Buy" Still Wins

```
┌──────────────────────────┬───────────────────────────────────────────────┐
│ Domain                   │ Why Building Loses                            │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Compliance-heavy         │ SOC 2, HIPAA, PCI-DSS certifications carry   │
│                          │ genuine value. Audits cost more than code.    │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Network-effect platforms │ Slack, GitHub derive value from user network, │
│                          │ not features. Cannot be replicated by code.   │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Deep domain expertise    │ Accounting (QuickBooks), payments (Stripe)    │
│                          │ contain decades of edge cases. Regulations,   │
│                          │ tax codes, payment processor quirks.          │
├──────────────────────────┼───────────────────────────────────────────────┤
│ Security infrastructure  │ Auth, encryption, identity. Failures are      │
│                          │ catastrophic. The 45 Vinext vulnerabilities   │
│                          │ prove this point.                             │
└──────────────────────────┴───────────────────────────────────────────────┘
```

## The Grass-Is-Greener Trap

Just because rebuilding is cheap does not mean it is wise. Some platforms remain correct choices despite frustration. Constant rewriting costs include context loss, team fatigue, and perpetual "v2" that never ships. The proper framework: evaluate future cost of staying versus future cost of switching with zero weight given to past investment. AI shifted the equation — it did not eliminate the need for judgment.

## The Shadow IT Signal

60% of enterprises built software outside IT oversight in the past year. 51% shipped production tools currently in use. Half report saving 6+ hours weekly. Shadow IT is not a security problem to be stamped out — it is a market signal that official tools inadequately serve organizational needs. When developers build unauthorized replacements that outperform purchased software, the procurement process is broken.

## What This Means

The build-vs-buy equation flipped because AI collapsed build costs while buy costs stayed the same. SaaS vendors face a structural crisis: per-seat pricing dies when agents replace human users, and the generic 80% of functionality that justified buying is now free to build. The sunk cost fallacy lost its economic cover — rebuilding is cheap enough that "we already paid for it" is no longer rational, only emotional. Test suites became machine-readable specs that let AI reimplement entire frameworks for $1,100 in a week. The 90/90 rule still applies — the last 10% of edge cases, compliance, and security still takes real engineering. But the first 90% is no longer a moat, and organizations anchored to past technology investments because "switching is too expensive" are defending a position that no longer exists. Challenge every renewal. Calculate actual replacement costs. Start narrow with admin panels and dashboards. The organizations that recognize this shift first get better tools, lower costs, and faster iteration. The ones that do not will keep paying increasing rents on software their agents could rebuild in a weekend.

## Links

- Buy vs Build Flipped: https://paddo.dev/blog/buy-vs-build-flipped/
- Sunk Cost Fallacy Is Dead: https://paddo.dev/blog/sunk-cost-fallacy-is-dead/
- Vinext and the $1,100 Rewrite: https://paddo.dev/blog/vinext-test-suites-are-specs/
- Retool Build vs Buy Report 2026: https://retool.com/blog/ai-build-vs-buy-report-2026
- SaaSpocalypse (Bloomberg): https://www.bloomberg.com/news/articles/2026-02-04/what-s-behind-the-saaspocalypse-plunge-in-software-stocks
- SaaS Rout 2026 (SaaStr): https://www.saastr.com/the-saas-rout-of-2026-is-even-worse-than-you-think-for-the-first-time-ever-software-now-trades-at-a-discount-to-the-sp-500/
- SaaS Crash Analysis (SaaStr): https://www.saastr.com/the-2026-saas-crash-its-not-what-you-think/
- AI Fears Pummel Software Stocks (CNBC): https://www.cnbc.com/2026/02/06/ai-anthropic-tools-saas-software-stocks-selloff.html
- AI Replace SaaS (The Register): https://www.theregister.com/2026/02/04/ai_replace_saas/
- SaaS Is Dying (Calcalist): https://www.calcalistech.com/ctechnews/article/hjlvyl7lze
- SaaS Stocks Hit 52-Week Lows (Benzinga): https://www.benzinga.com/trading-ideas/movers/26/02/50792310/saas-stocks-buried-in-ai-blizzard-atlassian-salesforce-hit-52-week-lows
- Bain SaaS Analysis: https://www.bain.com/insights/why-saas-stocks-have-dropped-and-what-it-signals-for-softwares-next-chapter/
