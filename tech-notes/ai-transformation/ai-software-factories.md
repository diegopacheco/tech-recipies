# AI Software Factories

## What Is It?

An AI software factory is a governed production system in which AI agents turn intent into tested, deployable software and learn from the results. It combines specifications, repository context, models, tools, isolated execution, quality gates, delivery automation, telemetry, and policy into one feedback loop.

The factory is not a chat interface, a coding assistant, or a CI pipeline with an LLM call. The defining property is closed-loop execution:

```
intent → specification → agent execution → validation → release → production evidence
   ↑                                                                     │
   └──────────────────────────── improvement ────────────────────────────┘
```

Humans own purpose, constraints, risk, and accountability. Agents perform a growing share of planning, implementation, testing, review, remediation, and maintenance. The level of autonomy can range from supervised task execution to the no-human-code-review model described in [[ai-dark-factory]].

The provocative question is whether this is genuinely new or another turn of the software-industrialization cycle that produced RUP, CMMI, and the Software Factories movement.

The short answer: the ambition is old, but the production mechanism is new.

## The Recurring Dream

Software engineering has repeatedly tried to move from individual craft to repeatable production.

| Period | Movement | Primary concern | Main production asset |
|---|---|---|---|
| 1970s–1980s | Japanese software factories | Standardization, reuse, tools, quality control | Process, components, trained organization |
| 1990s | Software CMM and RUP | Predictability, risk reduction, disciplined delivery | Defined process, roles, artifacts, architecture |
| 2000s | CMMI and Microsoft Software Factories | Enterprise process capability and product-line automation | Practice areas, models, DSLs, frameworks, patterns |
| 2010s | Agile, CI/CD, DevOps, platform engineering | Fast feedback, small batches, team autonomy | Pipelines, tests, APIs, paved roads, telemetry |
| 2020s | AI-native engineering and agentic factories | Automated knowledge work across the lifecycle | Specs, context, tools, policies, evals, trajectories |

Michael Cusumano's 1988 study of Japanese software factories documented the earlier push toward standardized processes, reusable assets, automation, quality control, and organizational learning. The goals sound remarkably current even though the workers and tools were different ([MIT Sloan](https://hdl.handle.net/1721.1/2204)).

## First, Separate the Categories

RUP and CMMI are often grouped together as heavyweight factory methods, but they solve different problems. The Microsoft Software Factories program was closer to a literal production system.

| System | What it is | Question it answers | What it does not provide |
|---|---|---|---|
| RUP | Configurable software delivery process | How should a project manage risk and evolve software iteratively? | Organizational maturity rating |
| CMMI | Capability and process-improvement model | Which capabilities must an organization institutionalize and improve? | A prescribed lifecycle or project method |
| Microsoft Software Factories | Product-line and model-driven development approach | How can a family of applications be assembled from reusable domain assets? | General organizational capability model |
| AI software factory | Agent execution and validation operating system | How can intent flow safely to production with machines doing most execution? | Proof that the resulting software creates value |

Calling all four a methodology hides the most important differences.

## RUP: Industrializing the Project

RUP emerged from Rational's object-oriented methods during the 1990s. Its lifecycle has four phases:

1. Inception defines scope, vision, and the business case.
2. Elaboration stabilizes architecture and attacks the highest risks.
3. Construction builds the product through iterations.
4. Transition moves the product into the user community.

RUP was iterative, not waterfall. Each iteration mixed planning, analysis, design, implementation, and testing in different proportions. Each was expected to produce executable software that could be tested against requirements and use cases. Its milestones were risk and evidence checkpoints, not merely calendar gates ([IBM Rational, 1996](https://public.dhe.ibm.com/software/rational/web/whitepapers/2003/xtalk.pdf), [IBM project planning](https://public.dhe.ibm.com/software/rational/web/whitepapers/2003/tp151.pdf)).

### What RUP Got Right

- Attack architecture and existential risk early.
- Make progress visible through executable increments.
- Trace requirements through design, implementation, and testing.
- Define acceptance criteria before declaring completion.
- Tailor the process to the project rather than applying every artifact.
- Treat roles, activities, artifacts, and milestones as an integrated system.

These principles map directly to agentic work. An agent should resolve high-risk uncertainty early, produce small executable changes, preserve traceability from intent to evidence, and work under explicit completion criteria.

### What Went Wrong in Practice

RUP was a configurable process framework, but many organizations installed it as a universal operating manual. The available catalog of roles, artifacts, disciplines, templates, and tool integrations made over-implementation easy. Teams could become compliant with the process while remaining slow at learning what users needed.

The failure was not iteration or architecture. It was confusing the full process library with the minimum process required for a specific risk profile.

An AI factory can repeat this mistake by replacing RUP roles with agent personas and RUP artifacts with generated Markdown. A pipeline containing analyst, product manager, architect, developer, tester, reviewer, security reviewer, and release-manager agents may recreate the same handoffs at machine speed. More agent activity does not imply more customer value.

## CMMI: Industrializing the Organization

The Software Capability Maturity Model was released in 1991. CMMI followed in 2000 by integrating software and systems engineering in a product suite that also included training and appraisal ([SEI history](https://www.sei.cmu.edu/library/cmmi-a-short-history/)).

The current staged model describes maturity from incomplete and reactive work to managed, defined, quantitatively managed, and continuously optimizing performance. CMMI also supports capability levels for individual practice areas. The official guidance explicitly says improvement should be based on business objectives and performance results, not the pursuit of a rating by itself ([CMMI Institute](https://cmmiinstitute.com/learning/appraisals/levels)).

### What CMMI Got Right

- Reliable delivery requires organizational capability, not isolated heroes.
- Important practices must survive personnel changes and project boundaries.
- Shared assets should be used, tailored, and improved by delivery teams.
- Measurement should progress from project control to quantitative improvement.
- Root causes and process variation deserve systematic attention.
- Improvement must become part of normal work rather than a periodic rescue program.

The 1994 SEI study gathered data from 13 organizations and reported process-improvement results across productivity, defect detection, time to market, and post-release defects. The small sample and measurement difficulties matter, but it shows that disciplined process improvement was not merely paperwork ([SEI study](https://www.sei.cmu.edu/library/benefits-of-cmm-based-software-process-improvement-initial-results/)).

### What Went Wrong in Practice

Appraisals created a powerful proxy: the maturity level. Once procurement, sales, or executive status depended on that number, teams had an incentive to produce appraisal evidence instead of better outcomes. A practice could exist on paper, generate the required records, and still fail to improve delivery.

The same danger exists in AI factories:

- Autonomy percentage can replace maturity level as the prestige metric.
- Tokens consumed can replace effort spent as a false sign of progress.
- Agent-generated records can create unlimited compliance theater.
- Passing agent-visible tests can replace satisfying users.
- A centralized AI platform team can become a process office detached from delivery.

Autonomy is not maturity. The most mature operating point is the least expensive level of autonomy that meets the product's risk, quality, speed, and accountability needs.

CMMI also was never inherently anti-Agile. SEI published guidance in 2008 showing how CMMI practices and Agile methods can reinforce one another. The conflict came from implementations that valued prescribed process over fast feedback ([SEI on CMMI and Agile](https://www.sei.cmu.edu/library/cmmi-or-agile-why-not-embrace-both/)).

## Microsoft Software Factories: Industrializing the Product Line

The 2004 Microsoft Software Factories vision combined software product lines, domain-specific languages, patterns, frameworks, models, guidance, and extensible tools. The goal was to automate repeated work for a bounded business or technical domain rather than build every application from generic tools and custom architecture ([Microsoft, 2004](https://news.microsoft.com/source/2004/10/26/microsoft-grows-partner-ecosystem-around-visual-studio-2005-team-system/)).

This was much closer to manufacturing:

```
domain schema + reusable assets + configuration → product variant
```

The approach worked best when the product family was stable enough to justify creating specialized languages, generators, components, and recipes. Its economic bet was that the cost of building the factory would be recovered across many related products.

### What It Got Right

- A factory must be scoped to a domain.
- Reuse needs executable assets, not a document portal.
- Automation should encode architectural knowledge.
- Variability must be explicit rather than hidden in copied code.
- Factory economics depend on repeated demand.

### Why It Did Not Become the Universal Model

The factory was expensive to build and maintain. Domain models and generators aged with platforms and requirements. Product variation often exceeded the assumptions encoded in the schema. Generic languages, open-source ecosystems, cloud services, and rapidly changing business needs reduced the payoff from elaborate generation systems.

The approach automated known variation. It did not possess a general worker capable of interpreting new intent, navigating an unfamiliar codebase, using tools, and synthesizing a new implementation.

That missing worker is what foundation models changed.

## The Agile and DevOps Correction

The 2001 Agile Manifesto pushed the industry toward individuals, working software, customer collaboration, and response to change while still acknowledging value in process, documentation, contracts, and plans ([Agile Manifesto](https://agilemanifesto.org/)). Continuous integration then made automated builds and tests part of daily work rather than a late integration phase ([Martin Fowler](https://martinfowler.com/articles/continuousIntegration.html)). DevOps and continuous delivery extended that loop into production.

The factory did not disappear. It moved:

| Old factory location | Modern factory location |
|---|---|
| Organizational hierarchy | Delivery platform |
| Specialist handoffs | Cross-functional product team |
| Phase exit documents | Executable quality gates |
| Central process manual | Version-controlled workflow |
| Large planned batch | Small deployable change |
| Project conformance metrics | Delivery and product outcomes |

DORA's current delivery model measures throughput and instability through change lead time, deployment frequency, failed-deployment recovery time, change failure rate, and deployment rework rate. It recommends smaller changes and end-to-end cross-functional ownership ([DORA metrics](https://dora.dev/guides/dora-metrics/)).

This bridge matters. A successful AI factory should automate the continuous flow created by Agile and DevOps, not restore a document-heavy phase model.

## What Changed With AI

Earlier factory movements automated coordination, repeatable process, model transformation, component assembly, builds, tests, and deployment. Humans still performed most semantic work: understanding ambiguous intent, deciding what code should change, producing the change, and interpreting failures.

AI agents can now perform part of that semantic work. They operate tools, inspect repositories, form plans, edit many files, execute tests, read failures, and revise the result. This changes the factory from a deterministic transformation system into a probabilistic search-and-validation system.

```
Earlier factory
known inputs → encoded transformation → predictable artifact

AI factory
intent → many possible trajectories → independent validation → accepted outcome
```

StrongDM describes a factory where humans define intent and scenarios while agents generate and iterate against scenario-based validation and behavioral twins of external systems. Its central claim is that validation can replace human code review for this operating model ([StrongDM](https://www.strongdm.com/blog/the-strongdm-software-factory-building-software-with-ai)).

Factory.ai describes a broader lifecycle system with model routing, persistent execution, quality gates, operations, governance, auditability, cost tracking, and human judgment at policy boundaries ([Factory.ai](https://factory.ai/product/software-factory)).

These are vendor accounts, not neutral proof that the model generalizes across companies, domains, or risk levels. They are useful descriptions of the emerging architecture.

## Side-by-Side Comparison

| Dimension | RUP | CMMI | 2000s Software Factories | AI software factory |
|---|---|---|---|---|
| Primary unit | Project iteration | Organizational practice area | Product-family variant | Goal, task, or change trajectory |
| Main executor | Human team | Human organization | Human using generators and tools | Agent under human governance |
| Core input | Vision, use cases, risks | Business objectives and process evidence | Domain model and configuration | Intent, spec, context, policies, feedback |
| Core asset | Process guidance and artifacts | Standard process and organizational assets | DSLs, frameworks, patterns, generators | Harness, tools, evals, policies, memory |
| Automation | Tool-supported workflow | Measurement and institutionalization | Deterministic generation and assembly | Probabilistic planning and implementation |
| Scope | One system lifecycle | Enterprise capability | Bounded family of related systems | Potentially broad, bounded by context and tools |
| Quality control | Milestones, testing, review | Defined practices, measurement, appraisal | Constraints and generated consistency | Tests, evals, scenarios, policies, telemetry |
| Feedback speed | Iteration or phase | Appraisal and improvement cycle | Build and product-line evolution | Minutes to production feedback, when safe |
| Reuse model | Templates, roles, use cases, architecture | Shared organizational process assets | Components, models, frameworks | Context, skills, tools, prompts, trajectories, evals |
| Variability | Tailored project process | Tailored practices | Pre-modeled feature variability | Model synthesis across weakly modeled variation |
| Main risk | Process weight | Rating pursuit | Factory cost and domain rigidity | False confidence, nondeterminism, unsafe scale |
| Success measure | Risk retired and product delivered | Capability and business performance | Cost and quality across product variants | Product outcomes per unit of time, cost, and risk |

## What Is Genuinely the Same

### Standardization

Every factory movement makes work explicit so it can be repeated. RUP had activities and artifacts. CMMI had practice areas and organizational assets. Software Factories had schemas and reusable components. AI factories have specifications, repository instructions, tool contracts, policies, and evals.

### Reuse

The asset changes, but the economic logic does not. A factory becomes valuable when learning from one unit of work makes later units cheaper, faster, or safer.

### Measurement

Factories need observable flow and quality. Without measurement, industrialization becomes a story told by the platform team.

### Encoded Knowledge

Each movement tries to capture expert judgment in an executable or teachable form. The AI version encodes judgment in context, tool design, policies, evaluators, test environments, and acceptance scenarios.

### Governance

Scaling production requires boundaries. Earlier systems used roles, approvals, milestones, process audits, and architectural standards. AI factories add sandboxes, least privilege, command policies, model routing, budget limits, trace logs, and risk-based human approval.

## What Is Genuinely Different

### The Factory Has a General-Purpose Worker

Earlier automation only handled transformations anticipated by its designers. An agent can reason across a novel task and compose existing tools without a dedicated generator for every variation.

### Production Is Probabilistic

The same input can produce different plans and code. Correctness cannot depend on the agent behaving identically. It depends on independent, repeatable validation of the outcome.

### The Process Can Run Faster Than Human Review

Agents can generate changes, tests, documentation, and review findings faster than people can inspect them. Review capacity becomes the constraint unless automated evidence is strong enough to carry routine decisions.

### Context Is Part of the Production System

Repository instructions, architecture records, tool descriptions, retrieved knowledge, and recent failures directly alter agent behavior. Context quality is now operational infrastructure, not background documentation.

### Marginal Experiment Cost Collapses

Factories can run several trajectories, reject weak outputs, and retain only validated results. This makes search economically useful, but it can also produce enormous cost and noise without budgets and stopping conditions.

### The Factory Can Modify the Factory

Agents can improve tests, tooling, instructions, and automation that govern later agents. This creates a compounding loop, but allowing the producer to rewrite its own acceptance system also creates a serious control problem. Production agents must not freely weaken the evidence used to judge them.

## The Evidence Is Mixed

The current market is rich in velocity claims and poor in independent longitudinal evidence. Factory output must therefore be measured rather than assumed.

DORA reported that a 25% increase in AI adoption was associated with a 1.5% reduction in delivery throughput and a 7.2% reduction in delivery stability. Its interpretation was that faster code generation can create larger batches that are harder to review and integrate. Association is not causation, but the result warns against measuring code production alone ([DORA on generative AI](https://dora.dev/ai/gen-ai-report/report/)).

METR's randomized study of early-2025 tools found that 16 experienced open-source developers working on 246 real tasks took 19% longer when AI use was allowed. The setting was narrow and the tools have since changed. METR's February 2026 update found weak signs of improvement with later tools but concluded that selection effects made the new estimate unreliable ([METR 2025](https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/), [METR 2026](https://metr.org/blog/2026-02-24-uplift-update/)).

The correct conclusion is neither that AI factories already work universally nor that they cannot work. It is that their performance is highly conditional on task shape, repository readiness, verification strength, operating model, and measurement method.

## What To Keep From RUP and CMMI

### 1. Risk-First Iteration

Borrow RUP's strongest idea: use early cycles to retire architecture, security, integration, and requirement risk. Do not spend the first thousand agent-hours generating low-risk code while the core uncertainty remains untouched.

### 2. Executable Evidence

Every cycle should end with a runnable change and evidence tied to acceptance criteria. A generated plan, report, or diff is inventory, not value.

### 3. Tailoring

Use different controls for a documentation change, an internal tool, a payment path, and safety-critical software. One global workflow is either too weak for high risk or too heavy for low risk.

### 4. Institutionalized Assets

Borrow CMMI's organizational learning loop. When a team discovers a recurring failure, improve the shared test, policy, tool, context, or environment so every later run benefits.

### 5. Quantitative Improvement

Track whether changes lead to better delivery and product results. Cost per accepted change, lead time, rollback rate, escaped defects, incident impact, rework, and customer outcomes are more useful than tokens, lines, commits, or agent count.

### 6. Independent Acceptance

The production agent should not control all of its own tests. Holdout scenarios, production telemetry, invariant checks, security policy, and independently maintained evaluators reduce test gaming and correlated blind spots.

### 7. Architecture as a Constraint

RUP treated architecture as the structure that made later construction safe. AI factories need the same principle in machine-readable form: module boundaries, dependency rules, interface contracts, data constraints, and forbidden operations.

## What To Reject From the Old Factory Model

- Do not make process conformance a substitute for product outcomes.
- Do not generate artifacts merely because a framework lists them.
- Do not turn every human role into a separate agent and preserve every handoff.
- Do not equate higher autonomy with higher maturity.
- Do not optimize code volume, PR volume, token use, or agent utilization.
- Do not centralize all factory knowledge in a platform team that does not own production results.
- Do not build a universal factory before proving repeated demand in a bounded domain.
- Do not allow agents to silently change the policies and tests that judge their output.
- Do not create large batches merely because generation is cheap.
- Do not buy a maturity label from a vendor and call the transformation complete.

## A Lean Capability Ladder

If CMMI's staged idea is reused, the levels should measure control and learning rather than raw autonomy.

| Level | Capability | Evidence |
|---|---|---|
| 0. Ad hoc | Individuals prompt tools without shared controls | Anecdotes and local output |
| 1. Repeatable | Common repository context and task patterns | Similar tasks can be rerun consistently |
| 2. Managed | Isolated execution, budgets, audit logs, tests, approvals | Cost, flow, failure, and acceptance are visible |
| 3. Defined | Shared tools, policies, evals, environments, and risk tiers | Teams use and improve common factory assets |
| 4. Measured | Delivery and product outcomes drive decisions | Changes in the factory can be tied to outcomes |
| 5. Optimizing | Production evidence improves routing, context, evals, and tools | The system learns without weakening its controls |

A regulated team with mandatory human approval can be more mature than a fully autonomous team. Maturity is confidence earned through evidence, not the absence of people.

## Where AI Factories Fit

AI factories are strongest when:

- Demand contains many related, well-scoped changes.
- The system has fast builds and reliable automated tests.
- Behavior is observable through APIs, scenarios, or telemetry.
- Environments are reproducible and failures are reversible.
- Architecture and policy boundaries are explicit.
- Teams can measure accepted outcomes and rework.
- The economics justify building reusable context, tools, and evals.

They are weakest when:

- Product intent is novel, political, or deeply ambiguous.
- Critical requirements remain implicit in a few people's heads.
- Correctness depends on tacit judgment that cannot be tested or observed.
- The legacy system is tightly coupled and lacks a reproducible environment.
- Failures are irreversible or carry severe safety consequences.
- The organization rewards visible activity instead of outcomes.
- The factory exists mainly because leadership wants an AI program.

## The Verdict

AI software factories are not simply RUP or CMMI with agents attached.

RUP told human teams how to evolve a system through risk-driven iterations. CMMI told organizations which capabilities to institutionalize and improve. The 2000s Software Factories movement told specialized tools how to assemble known product variants. Agile and DevOps replaced large batches and handoffs with continuous, outcome-oriented flow.

AI software factories combine parts of all four, then add a new actor: a general-purpose, probabilistic worker that can perform variable engineering tasks and iterate against machine-checkable evidence.

The durable factory is therefore not an assembly line of agent personas. It is a learning system:

```
clear intent
    + bounded context
    + capable agents
    + safe tools
    + independent evidence
    + production feedback
    + human accountability
    = scalable software production
```

The old movements underperformed when organizations industrialized ceremony. The new movement will do the same if it industrializes token consumption and generated artifacts. The winning design industrializes feedback, verification, and organizational learning.

This connects directly to [[ai-native-engineering]], [[harness-engineering]], [[eval-driven-development]], [[briefs-as-code]], [[SDLC-death]], and [[ai-dark-factory]].

## Links

- Michael Cusumano, The Software Factory: Origins and Popularity in Japan: https://hdl.handle.net/1721.1/2204
- Philippe Kruchten, A Rational Development Process: https://public.dhe.ibm.com/software/rational/web/whitepapers/2003/xtalk.pdf
- IBM, Planning a Project with the Rational Unified Process: https://public.dhe.ibm.com/software/rational/web/whitepapers/2003/tp151.pdf
- SEI, CMMI: A Short History: https://www.sei.cmu.edu/library/cmmi-a-short-history/
- CMMI Institute, Levels of Capability and Performance: https://cmmiinstitute.com/learning/appraisals/levels
- SEI, Benefits of CMM-Based Software Process Improvement: https://www.sei.cmu.edu/library/benefits-of-cmm-based-software-process-improvement-initial-results/
- SEI, CMMI or Agile: Why Not Embrace Both: https://www.sei.cmu.edu/library/cmmi-or-agile-why-not-embrace-both/
- Microsoft, Software Factories Vision: https://news.microsoft.com/source/2004/10/26/microsoft-grows-partner-ecosystem-around-visual-studio-2005-team-system/
- Agile Manifesto: https://agilemanifesto.org/
- Martin Fowler, Continuous Integration: https://martinfowler.com/articles/continuousIntegration.html
- DORA Software Delivery Performance Metrics: https://dora.dev/guides/dora-metrics/
- DORA, Impact of Generative AI in Software Development: https://dora.dev/ai/gen-ai-report/report/
- StrongDM Software Factory: https://www.strongdm.com/blog/the-strongdm-software-factory-building-software-with-ai
- Factory.ai Software Factory: https://factory.ai/product/software-factory
- METR, Early-2025 AI Developer Productivity Study: https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
- METR, 2026 Productivity Study Update: https://metr.org/blog/2026-02-24-uplift-update/
