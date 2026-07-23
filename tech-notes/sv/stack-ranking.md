# Stack Ranking

## What is it?

**Stack ranking** — also called forced ranking, forced distribution, or "rank and yank" — is a performance-management system that sorts every employee against their peers and fits them to a **predetermined curve**: a fixed share must land at the top, a fixed share in the middle, and a fixed share at the bottom, regardless of how the group actually performed. It converts the annual review from an *absolute* judgment ("did this person do good work?") into a *relative* one ("where does this person rank against everyone else?"), and then attaches consequences to the position: the top of the curve gets the big [[bonus]] and [[RSUs]] refresh, the middle gets a standard package, and the bottom gets managed out. It is the dark counterpart to the sunny language of comp — the machine that decides whose multiplier goes up and whose goes to zero.

Stack ranking matters because it is where the pleasant abstractions of a comp package meet a **zero-sum reality**. Your target [[bonus]] and equity refresh aren't funded from an open pool; they're funded from a fixed budget divided by a forced curve, which means your rating depends not only on your work but on how you were ranked *against your colleagues* in a closed-door **calibration** meeting you never see. The system is famous because Jack Welch's GE made it corporate gospel in the 1980s–90s, infamous because Microsoft's version is widely blamed for a "lost decade," and still quietly alive — in softened forms — across much of Big Tech. Understanding it is understanding the actual mechanism behind "your individual multiplier," the number that decides what your [[stock-options]] and bonus are really worth.

## How it works

The engine has three parts: a **rating scale**, a **forced distribution** the ratings must fit, and a **calibration** process that reconciles managers' proposed ratings against that distribution. The forced distribution is the defining feature — without it, this is just normal performance review; with it, a manager who leads an all-star team is *required* to rate some of them low.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Component            │ What it does                                               │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Forced distribution  │ Fixed quotas per bucket, e.g. 20% top / 70% middle /        │
│                      │ 10% bottom (Welch's "vitality curve"). Ratings must fit it. │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Calibration          │ Managers meet behind closed doors to compare reports across │
│                      │ teams and force the org-wide curve. Where ratings are set.  │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Up-or-out            │ Advance or exit — sustained low rank (or failure to promote │
│                      │ within a window) leads to being managed out.               │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ PIP                  │ Performance Improvement Plan — the formal, time-boxed       │
│                      │ (30/60/90-day) process the bottom bucket is placed on;      │
│                      │ often a documented off-ramp more than a real rescue.       │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

**Calibration** is the heart of it and the part employees rarely see. Managers gather and defend their reports' ratings against each other; because the curve is fixed, elevating one person mathematically pushes another down. Your rating is therefore partly a function of your manager's *advocacy* and *political capital* in that room — a well-argued case beats quiet good work. The bottom of the curve then flows into the **PIP**: nominally a chance to improve, in practice frequently a **documented off-ramp** that creates the paper trail for a low-liability exit. "**Up-or-out**" closes the loop — in the harshest versions, staying flat is itself a failing state.

## How it plays out

The system's effects are not incidental; they follow mechanically from forcing a curve onto reality.

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Consequence                │ Why it happens                                     │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Internal competition       │ Zero-sum ratings make your peers your rivals — a   │
│                            │ direct incentive *against* helping teammates.       │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Punishes strong teams      │ A team of all-stars must still send someone to the │
│                            │ bottom bucket; a weak team's median is "safe."      │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Hire-to-fire / dead seats  │ Managers hire weak "buffer" reports to protect      │
│                            │ strong ones from the bottom quota.                  │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Politics over output       │ Rating tracks manager advocacy and visibility, not │
│                            │ just work — gaming calibration becomes rational.    │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

The signature pathology is that **a forced curve punishes being on a good team.** If your five-person team is all excellent, the curve still demands a bottom performer, so someone excellent gets rated poorly and loses their [[bonus]] and equity refresh for being *slightly less* excellent than four other outstanding people. This inverts the incentive to work with the best — you're now safer surrounded by weaker peers — and it corrodes collaboration, because every peer you help climb is a peer who might push *you* down a fixed curve. This is the exact opposite of the "10x team" leverage described in [[10x-engineer]]: stack ranking makes helping your teammates a threat to your own rating.

## What companies and startups usually do

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Setting              │ Typical practice                                           │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech (classic)   │ Calibration + a soft forced curve driving [[bonus]] and    │
│                      │ [[RSUs]] refresh. Amazon's "URA" unregretted-attrition     │
│                      │ target is the modern hard-edged version.                   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ The cautionary tale  │ Microsoft ran hard stack ranking for ~a decade, blamed for │
│                      │ toxic internal competition; scrapped it in 2013. GE (its   │
│                      │ inventor) dropped the vitality curve in 2015.              │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups             │ Rarely formal stack ranking early — too small — but adopt  │
│                      │ calibration and PIPs as they scale past ~100–200 people.   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Modern "softened"    │ Many firms dropped explicit quotas but kept calibration    │
│ version              │ and de-facto distributions — the curve without the name.   │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The industry arc is **adopt, regret, soften — but rarely abandon.** GE invented the vitality curve and dropped it in 2015; Microsoft ran a brutal version, was widely blamed for a decade of stagnation, and killed it publicly in 2013. Yet the underlying machinery survives almost everywhere in gentler dress: explicit percentage quotas removed, but **calibration meetings and de-facto distributions** retained, because the budget for [[bonus]] and equity is still finite and someone has to decide who gets what. Amazon's much-discussed "**URA**" (unregretted attrition) target — a planned annual percentage of exits — is the clearest modern survival of the hard-edged version. The name is out of fashion; the mechanism is not.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ The case for it                             │ The case against it                         │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Forces managers to differentiate — kills    │ Zero-sum ratings turn peers into rivals and  │
│ rating inflation where everyone is "great"  │ actively discourage collaboration            │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Concentrates [[bonus]]/equity on genuine    │ Punishes strong teams — someone excellent    │
│ top performers instead of spreading thin    │ must still fill the bottom quota             │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Creates a defensible paper trail for        │ Breeds politics: rating tracks manager       │
│ removing genuine low performers             │ advocacy and visibility over real output     │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Simple, budget-friendly — a fixed curve     │ Fear-driven culture; hire-to-fire buffers,   │
│ maps cleanly onto a fixed comp pool         │ sandbagging, and short-termism               │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The defining critique is that stack ranking **optimizes the wrong thing**: it's built to sort and cull individuals on a curve, but software is built by teams, and the system's central incentive — don't let a peer outrank you — is a direct tax on the collaboration that actually produces results. It also assumes performance is truly normally distributed within every small group, which it isn't; forcing a curve onto a team of ten manufactures a "bottom performer" who may be excellent in absolute terms. The kindest defense — that it prevents the rating inflation where every review says "exceeds expectations" — is real, but calibration can achieve that without the forced *cull* that does the cultural damage.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use it                                            │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Big Tech HR / mgmt   │ Calibration + soft distributions to allocate a fixed        │
│                      │ [[bonus]]/[[RSUs]] pool and drive planned attrition        │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Managers             │ Advocate for reports in calibration; the room where an      │
│                      │ individual's real multiplier is decided                    │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Employees            │ Live under it — rank drives comp, promotion, and PIP risk; │
│                      │ visibility and manager advocacy matter as much as output   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Finance orgs / banks │ Among the most aggressive users — sharp forced curves tied │
│                      │ to large discretionary bonus pools                         │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Reformers            │ Companies (GE, Microsoft, Adobe's "check-ins") that dropped │
│                      │ or replaced it with continuous feedback                    │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

Stack ranking is the hidden machinery behind the friendly word "multiplier" in your [[bonus]] and equity math — a forced curve, set in a closed-door calibration meeting, that decides whose rating (and pay) goes up and whose goes to zero, funded from a fixed pool that makes the whole thing zero-sum. Its intent is defensible (force real differentiation, concentrate rewards on genuine top performers) but its central incentive is corrosive: on a forced curve, your peers are your rivals and helping them is a threat to yourself — the exact inverse of the team leverage the Valley claims to want. The industry has learned this the hard way (GE and Microsoft both killed their versions) and mostly kept the mechanism under a softer name. The practical read is to know the system you're in: your review is *relative*, decided by advocacy in a room you can't see, so understand who's arguing for you in calibration — and treat the PIP for what it usually is, an off-ramp, not a rescue.

## Links

- Forced ranking / vitality curve (Wikipedia): https://en.wikipedia.org/wiki/Vitality_curve
- Microsoft's Lost Decade (Vanity Fair, Kurt Eichenwald) — the stack-ranking critique: https://www.vanityfair.com/news/business/2012/08/microsoft-lost-mojo-steve-ballmer
- Microsoft Axes Its Controversial Employee-Ranking System (The Verge, 2013): https://www.theverge.com/2013/11/12/5094864/microsoft-kills-stack-ranking-internal-structure
- GE Scraps the Vitality Curve / annual ratings (2015) — coverage: https://qz.com/428813/ge-performance-review-strategy-shift
- The Performance Management Revolution (Harvard Business Review): https://hbr.org/2016/10/the-performance-management-revolution
- Performance Improvement Plan (PIP) — what it really means: https://www.shrm.org/topics-tools/tools/hr-answers/how-to-create-performance-improvement-plan
- Amazon and unregretted attrition (URA) — coverage: https://www.businessinsider.com/amazon-management-strategy-unregretted-attrition-2021-6
</content>
