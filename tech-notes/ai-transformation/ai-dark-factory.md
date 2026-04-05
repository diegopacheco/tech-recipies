# AI Dark Factory

## What is it?

The Dark Factory is the highest level (Level 5) of AI-assisted software development where coding agents produce software autonomously with no human writing code and no human reviewing code. The term was coined by Dan Shapiro in January 2026, borrowing from manufacturing's "lights-out factories" where robots operate without human workers present. Simon Willison popularized the concept after visiting StrongDM's engineering team and calling their approach "very convincing."

The core idea: specs go in, software comes out. Humans define the what and why. Machines handle the how.

## The Five Levels of AI Coding

```
┌───────┬─────────────────┬──────────────────────────────────────────────┐
│ Level │ Name            │ Description                                  │
├───────┼─────────────────┼──────────────────────────────────────────────┤
│   0   │ Manual          │ Traditional hand-written code                │
├───────┼─────────────────┼──────────────────────────────────────────────┤
│   1   │ Task Delegation │ Dev commands AI for discrete tasks           │
├───────┼─────────────────┼──────────────────────────────────────────────┤
│   2   │ Pair Programming│ AI works alongside devs in real-time         │
├───────┼─────────────────┼──────────────────────────────────────────────┤
│   3   │ Code Review     │ AI generates code, humans review             │
├───────┼─────────────────┼──────────────────────────────────────────────┤
│   4   │ Spec-Driven     │ Detailed specs drive autonomous agents       │
├───────┼─────────────────┼──────────────────────────────────────────────┤
│   5   │ Dark Factory    │ No human writes or reviews code              │
│       │                 │ Humans design specs and curate scenarios      │
└───────┴─────────────────┴──────────────────────────────────────────────┘
```

## How StrongDM Does It

StrongDM published the first public description of a working Dark Factory in early 2026. Their team operates under three radical rules:

1. Code must not be written by humans
2. Code must not be reviewed by humans
3. Spend at least $1,000/day on tokens per engineer

### Specification-Driven Development

Engineers write extremely detailed specifications in prose, not code. These cover requirements, edge cases, and acceptance criteria. AI agents then generate, review, and test code iteratively without human intervention in implementation.

### Scenario Testing (Holdout Sets)

Instead of traditional tests, StrongDM adapted Cem Kaner's 2003 scenario testing framework. End-to-end user stories are stored outside the codebase as "holdout sets" that agents cannot access during development. This prevents agents from gaming the tests.

### Digital Twin Universe (DTU)

Agents build behavioral clones of third-party services (Okta, Jira, Slack) as self-contained binaries. This enables:
- Testing at massive scale without rate limits
- Simulating dangerous failure modes safely
- Running thousands of scenarios per hour

### Satisfaction Over Pass/Fail

Rather than boolean pass/fail, StrongDM measures "satisfaction" — what fraction of observed trajectories through scenarios likely satisfy users. This probabilistic approach mimics external QA rigor while remaining automatable.

## The Flow

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Human      │     │   AI Agent   │     │   Validation │
│              │     │              │     │              │
│ Write specs  │────►│ Generate     │────►│ Scenario     │
│ Define       │     │ code         │     │ testing      │
│ scenarios    │     │ Review code  │     │ (holdout)    │
│ Set criteria │     │ Fix issues   │     │ DTU clones   │
│              │     │ Iterate      │     │ Satisfaction │
│              │     │              │     │ scoring      │
└──────────────┘     └──────────────┘     └──────────────┘
       │                                         │
       │              ┌──────────────┐           │
       └─────────────►│  Production  │◄──────────┘
                      │  Software    │
                      └──────────────┘
```

## Simon Willison's Take

Willison identified November 2025 as the inflection point when Claude Opus 4.5 and GPT 5.2 became reliable enough for complex agentic coding. He noted that "we've passed the inflection point and dark factories are coming." His key observations:

- The approach works because of obsessive investment in specification quality and test coverage
- The $1,000/day per engineer cost raises sustainability questions
- Reusable patterns for lower-budget teams are the next frontier
- Most teams in 2026 are somewhere between Level 2 and Level 3

## Risks

- **Quality unproven at scale** — AI code shows materially higher defect rates than human-written code
- **Specification debt** — Flawed specs produce flawed software faster and more confidently
- **Trust and compliance** — Enterprise buyers fear "no human ever looked at this code"
- **Cost** — $1,000/day/engineer is not sustainable for most organizations
- **Single implementation** — Only one major public case study exists (StrongDM)
- **Security blind spots** — Agents may introduce vulnerabilities that no human catches
- **Debugging black box** — When things break in production, understanding AI-generated code is harder

## What Changes

```
┌────────────────────────┬────────────────────────────────────────────┐
│ Before (Level 0-3)     │ After (Level 5 Dark Factory)               │
├────────────────────────┼────────────────────────────────────────────┤
│ Humans write code      │ Agents write code                          │
├────────────────────────┼────────────────────────────────────────────┤
│ Humans review PRs      │ Agents review + validate via scenarios     │
├────────────────────────┼────────────────────────────────────────────┤
│ Tests are pass/fail    │ Satisfaction scoring (probabilistic)       │
├────────────────────────┼────────────────────────────────────────────┤
│ Mock external services │ Digital Twin Universe (behavioral clones)  │
├────────────────────────┼────────────────────────────────────────────┤
│ Skill = implementation │ Skill = specification + architecture       │
├────────────────────────┼────────────────────────────────────────────┤
│ Senior = writes better │ Senior = specifies better                  │
│ code                   │                                            │
├────────────────────────┼────────────────────────────────────────────┤
│ Junior translates      │ Junior role most at risk (agents do        │
│ specs to code          │ translation)                               │
└────────────────────────┴────────────────────────────────────────────┘
```

## Links

- Simon Willison on StrongDM: https://simonwillison.net/2026/Feb/7/software-factory/
- Dark Factory Dev: https://darkfactory.dev/blog/what-is-dark-factory-software-development
- Willison's AI State of the Union: https://www.lennysnewsletter.com/p/an-ai-state-of-the-union
- Stanford Law on Agent Trust: https://law.stanford.edu/2026/02/08/built-by-agents-tested-by-agents-trusted-by-whom/
