# The Keeper Test

## What is it?

The **keeper test** is Netflix's one-line rule for who stays employed: a manager asks, of each person on the team, *"If this person told me they were leaving for a similar job elsewhere, would I fight to keep them?"* If the honest answer is no, the person should be let go **now** — with a generous severance — to free the seat for someone the manager *would* fight for. It inverts the ordinary logic of employment. The default is not "keep everyone who isn't failing"; the default is that your seat must be continuously *re-earned* against the standard of the best person the company could put in it. Adequate performance, in Netflix's famous phrasing, earns a **generous severance package**.

The keeper test matters because it is the sharpest, most explicit expression of an idea the whole Valley flirts with: that a company is a **high-performance team, not a family**. It comes from the Netflix "Culture Deck" — a 2009 slide presentation Sheryl Sandberg once called "the most important document ever to come out of the Valley" — and it packages a bundle of ideas the industry has been arguing about ever since: "team not a family," "adequate gets a severance," the tolerance (or not) of the **brilliant jerk**, and the trade of ordinary job security for unusually high pay and freedom. Where [[stack-ranking]] culls the bottom of a forced curve, the keeper test culls against a much higher and more personal bar — not "are you in the bottom 10%?" but "would I fight to keep *you*?"

## How it works

The keeper test is one node in a tightly coupled system; it only works because Netflix pairs it with specific commitments that make the harshness survivable and the standard real.

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Paired principle     │ How it supports the keeper test                            │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Team, not family     │ The org is a pro sports team — every position filled by the │
│                      │ best available player, not kept out of loyalty or tenure.   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Top of market pay    │ Pay each person the most a competitor would — so the "would │
│                      │ I fight to keep them?" bar is meaningful, not cost-driven.   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Generous severance   │ Adequate performers exit with months of pay — the humane    │
│                      │ counterweight that makes fast firing tolerable.             │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Freedom & Responsib. │ Few rules, huge autonomy — justified only if everyone on    │
│                      │ the team clears the keeper bar.                             │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

The logic is a **trade**: Netflix gives up ordinary job security and gives you, in exchange, top-of-market cash (famously with no forced [[RSUs]] split — you choose your own mix), extreme autonomy ("Freedom & Responsibility," unlimited vacation, no expense policy beyond "act in Netflix's interest"), and the guarantee that your colleagues are all people who cleared the same bar. The keeper test is the *enforcement mechanism* for that last promise. The autonomy is only safe if everyone is excellent, so the price of everyone's freedom is that anyone who slips to merely "adequate" is paid to leave — quickly, respectfully, and without the drawn-out [[stack-ranking]] apparatus of PIPs and forced curves.

## Where it came from

```
┌────────────────────────────┬────────────────────────────────────────────────────┐
│ Milestone                  │ What it added                                      │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ The Netflix Culture Deck   │ Reed Hastings & Patty McCord publish the 125-slide │
│ (2009)                     │ deck; "team not family," "adequate = severance"    │
│                            │ go viral across the Valley.                         │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Powerful (Patty McCord,    │ The former Netflix CHRO expands the deck into a    │
│ 2018)                      │ book-length HR philosophy.                         │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ No Rules Rules (Hastings   │ Hastings' 2020 book codifies the keeper test,      │
│ & Erin Meyer, 2020)        │ "talent density," and the freedom/responsibility   │
│                            │ trade for a general audience.                       │
├────────────────────────────┼────────────────────────────────────────────────────┤
│ Industry adoption          │ Startups copy the deck's language; the "brilliant  │
│                            │ jerk" line becomes a recurring hiring debate.       │
└────────────────────────────┴────────────────────────────────────────────────────┘
```

The system rests on a single concept Hastings calls **talent density**: the value of a team isn't the sum of its people but is dragged down disproportionately by its weakest members, because mediocrity is contagious and demoralizes the best. From that premise everything follows — if one adequate performer lowers the whole team's ceiling, the rational move is to remove them fast and pay them well on the way out, keeping density high. The deck's most-quoted lines ("we're a team, not a family"; "adequate performance gets a generous severance package") are blunt on purpose: they exist to kill the *family* expectation of tenure-based loyalty before it takes root.

## The brilliant-jerk debate

The keeper test forces a question the rest of the industry keeps re-litigating: what do you do with someone who is *individually* brilliant but *toxic* to the team?

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Position             │ Argument                                                   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Netflix's stance     │ "Do not tolerate brilliant jerks. The cost to teamwork is  │
│                      │ too high." Toxicity *fails* the keeper test regardless of  │
│                      │ raw talent.                                                │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ The [[10x-engineer]] │ Some orgs quietly keep the toxic star, betting the output  │
│ temptation           │ is "worth ten" — the exact tolerance Netflix rejects.      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Talent-density view  │ A brilliant jerk lowers *everyone else's* output, so their │
│                      │ net contribution is negative even if their code is great.  │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

Netflix's answer is unusually explicit and directly at odds with the myth in [[10x-engineer]]: **a brilliant jerk fails the keeper test.** The talent-density logic makes this consistent rather than sentimental — if one toxic star drags down the output of everyone around them, their *net* contribution is negative no matter how impressive their individual work, so the manager should not fight to keep them. This is the productive tension between the two notes: the 10x myth tempts orgs to tolerate the toxic genius on the theory that raw output is worth it; the keeper test says teamwork *is* the output, and refuses the trade.

## Pros and Cons

```
┌────────────────────────────────────────────┬────────────────────────────────────────────┐
│ The case for it                             │ The case against it                         │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Maximizes talent density — keeps teams      │ Fear culture: "am I still a keeper?" anxiety │
│ uniformly excellent                         │ can undermine the trust it needs             │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Honest and fast — generous severance beats  │ Subjective — "would I fight for you?" invites│
│ a slow, dishonest [[stack-ranking]] PIP     │ manager bias and favoritism                  │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Rejects the brilliant jerk — protects the   │ Works only with the full package (top pay,   │
│ team over the toxic individual              │ real severance); copied half-way, it's cruel │
├────────────────────────────────────────────┼────────────────────────────────────────────┤
│ Pairs harshness with top-of-market pay and  │ Punishes reasonable risk-taking and can chill│
│ autonomy — a clear, honest trade            │ the psychological safety innovation needs    │
└────────────────────────────────────────────┴────────────────────────────────────────────┘
```

The critical caveat is that **the keeper test is a system, not a slogan, and copying only the harsh half is the common failure.** Netflix's version is defensible because it's bundled with genuinely top-of-market pay, real months-long severance, and radical autonomy — the harshness *buys* something. Companies that lift "team not a family" and "adequate gets a severance" without the top-of-market pay or the generous exit get the cruelty without the trade, producing a fear culture that erodes exactly the trust and risk-taking the autonomy was supposed to enable. Even at Netflix, critics argue the constant "am I still a keeper?" pressure can chill the psychological safety that hard, uncertain work depends on.

## Who is using it

```
┌──────────────────────┬────────────────────────────────────────────────────────────┐
│ Who                  │ How they use it                                            │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Netflix              │ The core of its talent system — managers apply the keeper  │
│                      │ test continuously, paired with top-of-market cash pay      │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Managers             │ The mental gut-check for every report; the honest bar      │
│                      │ above the [[stack-ranking]] "not in the bottom" question   │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Startups / founders  │ Borrow the Culture Deck language ("talent density," "team  │
│                      │ not family") — with or without the pay to back it          │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ Employees            │ Live under a higher, more personal bar than a forced curve │
│                      │ — the trade is security for pay, freedom, and A-team peers │
├──────────────────────┼────────────────────────────────────────────────────────────┤
│ HR / culture writers │ Cite the deck as the canonical "high-performance, not      │
│                      │ family" model and debate the brilliant-jerk stance         │
└──────────────────────┴────────────────────────────────────────────────────────────┘
```

## What This Means

The keeper test is the cleanest statement of Silicon Valley's "team, not a family" bargain: your seat is re-earned continuously against the standard of the best person who could fill it, and merely adequate performance is paid to leave rather than kept out of loyalty. It's a genuine *trade* — you surrender ordinary job security and receive top-of-market pay, radical autonomy, and colleagues who all cleared the same bar — and it only works honestly when all three halves are present, which is why copying just the harsh slogan produces cruelty instead of excellence. Its most useful stance is the one that pushes directly against the [[10x-engineer]] myth: the **brilliant jerk fails the keeper test**, because on a real team teamwork *is* the output. The practical read for anyone inside such a culture is to see the deal for what it is — security traded for pay, freedom, and A-team peers — and, if you manage, to ask the honest question early and pay generously when the answer is no, rather than letting a slow [[stack-ranking]] process do the dishonest version of the same thing.

## Links

- Netflix Culture Deck (original 2009 slides): https://www.slideshare.net/reed2001/culture-1798664
- Netflix Culture — official page: https://jobs.netflix.com/culture
- No Rules Rules: Netflix and the Culture of Reinvention (Reed Hastings & Erin Meyer): https://www.norulesrules.com/
- Powerful: Building a Culture of Freedom and Responsibility (Patty McCord): https://pattymccord.com/book/
- How Netflix Reinvented HR (Patty McCord, Harvard Business Review): https://hbr.org/2014/01/how-netflix-reinvented-hr
- The keeper test, explained (coverage): https://www.businessinsider.com/netflix-keeper-test-management-culture-2022-5
- Why Netflix says it doesn't tolerate "brilliant jerks": https://www.cnbc.com/2018/09/07/netflix-ceo-reed-hastings-no-brilliant-jerks.html
</content>
