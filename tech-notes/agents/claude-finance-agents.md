# Claude Finance Agents

## What is it?

On May 5, 2026 Anthropic released **ten ready-to-run agent templates for financial services** - pre-built Claude agents for the most time-consuming work in finance: building pitchbooks, screening KYC files, closing the books at month-end, and more. The pitch is time-to-value: each template is a reference architecture you adapt to your firm's conventions, so a team can "put Claude on real financial work in days rather than months" instead of building agents from scratch.

The release bundles three things together: the ten agent templates, **Claude across Microsoft 365** (Excel, PowerPoint, Word, Outlook) via add-ins, and an expanded **partner connector/MCP ecosystem** so the agents can reach the data financial professionals already use. It pairs best with **Claude Opus 4.7**, which leads Vals AI's Finance Agent benchmark at **64.37%**.

## What an agent template actually is

Each template is not a single prompt - it's a reference architecture that packages three layers:

- **Skills** - the instructions and domain knowledge for the task (how a pitchbook is built, what a KYC file needs).
- **Connectors** - governed, real-time access to the data the task runs on (market data, filings, internal systems).
- **Subagents** - additional Claude models the main agent calls for specific sub-tasks, such as comparables selection or methodology checks.

Firms adapt any of them to their own modeling conventions, risk policies, and approval flows. This is the same harness pattern as [[claude-code]] - a main agent orchestrating subagents - applied to finance workflows, and it leans on the same subagent machinery that powers [[claude-dynamic-workflows]].

## The ten agents

### Research and client coverage

| Agent | What it does |
|---|---|
| Pitch builder | Creates target lists, runs comparables, drafts pitchbooks for client meetings |
| Meeting preparer | Assembles client and counterparty briefs ahead of calls |
| Earnings reviewer | Reads transcripts and filings, updates models, flags thesis-relevant changes |
| Model builder | Creates and maintains financial models from filings, data feeds, and analyst inputs |
| Market researcher | Tracks sector/issuer developments, synthesizes news, filings, and broker research, flags items for credit and risk review |

### Finance and operations

| Agent | What it does |
|---|---|
| Valuation reviewer | Checks valuations against comparables, methodology, and the firm's review standards |
| General ledger reconciler | Reconciles GL accounts and runs net asset value calculations against the books of record |
| Month-end closer | Runs the close checklist and produces close reports |
| Statement auditor | Reviews financial statements for consistency, completeness, and audit-readiness |
| KYC screener | Assembles entity files, reviews source documents, packages escalations for compliance review |

## Two ways to deploy

The templates live in a [financial services marketplace](https://github.com/anthropics/financial-services), in two forms:

1. **As a plugin in Claude Cowork or Claude Code** - the template runs alongside the analyst, using the software already on their desktop. You hand the agent a task and it works locally.
2. **As a cookbook for Claude Managed Agents** - the same architecture deployed as a managed, hosted agent for production/team use.

The plugin form is for an analyst working interactively; the cookbook form is for a firm standing up the agent as infrastructure.

## Claude across Microsoft 365

Claude now works directly inside **Excel, PowerPoint, Word, and Outlook** (Outlook coming soon) through Microsoft 365 add-ins. The key property is that **context carries automatically between applications** - an analyst who starts a model in Excel doesn't re-explain it when the work moves to PowerPoint.

| App | What Claude does there |
|---|---|
| Excel | Builds financial models from filings and data feeds, audits formulas across linked workbooks, runs sensitivity analyses |
| PowerPoint | Drafts decks that update automatically when the underlying numbers change |
| Word | Edits credit memos against the firm's own templates |
| Outlook | Acts as a chief of staff - triages the inbox, arranges meetings, drafts responses in your voice |

In Claude Cowork, analysts can also assign work by text or voice through **Dispatch** (see [[claude-dispatch]]) - Claude keeps working on local files while they're away from their desk, with finished work ready for review when they return.

## The data ecosystem

An agent is only as good as the data it can reach. Claude already connects, under governed access controls, to dozens of market-data and research platforms - **FactSet, S&P Capital IQ, MSCI, PitchBook, Morningstar, Chronograph, LSEG, Daloopa** - plus firms' own data warehouses, research repositories, and CRMs.

This release adds new connectors and an MCP app:

- **Connectors** give Claude governed, real-time access to a provider's data.
- **MCP apps** go further - they embed the provider's own tools and surface custom, interactive UI directly inside Claude.

New connectors: **Dun & Bradstreet** (verified business identity), **Fiscal AI** (real-time equity fundamentals), **Financial Modeling Prep** (quotes, fundamentals, statements, filings, transcripts across asset classes), **Guidepoint** (100,000+ compliance-reviewed expert interview transcripts with linked excerpts), **IBISWorld** (industry-level financials, risk scores, forecasts), **SS&C Intralinks** (DealCenter AI data rooms for diligence Q&A), **Third Bridge** (primary-source expert interviews), and **Verisk** (property/casualty/specialty insurance data).

## The model behind it

These updates pair best with **Claude Opus 4.7**, which Anthropic calls state-of-the-art on financial tasks and the industry leader on **Vals AI's Finance Agent benchmark at 64.37%**. The benchmark scores agents on realistic finance workflows, so the number is the closest public proxy for how well these templates perform on the actual jobs they target.

## Why it matters

This is Anthropic moving from "a model that's good at finance" to "deployable workers for specific finance jobs." Three things make that shift real rather than cosmetic:

1. **Templates, not prompts.** Packaging skills + connectors + subagents as an editable reference architecture is what compresses the build from months to days - the hard part (data access, sub-task decomposition, domain knowledge) is pre-assembled.
2. **Governed data access is the unlock.** Finance work fails without authoritative, real-time, permissioned data. The connector/MCP ecosystem - FactSet, S&P, Moody's-tier providers - is arguably more decisive than the agents themselves.
3. **Microsoft 365 is where the work actually lives.** Meeting analysts in Excel/PowerPoint/Word/Outlook with context that carries between them removes the copy-paste tax that usually kills AI adoption in finance.

The honest caveats are the ones that always apply to high-stakes domains: a 64.37% benchmark score means roughly a third of agent attempts still miss, so these are assistants operating inside firm review and approval flows, not autonomous deciders. The reference architectures explicitly preserve "risk policies and approval flows" for exactly this reason. The value is leverage on the labor-intensive 80% (assembling files, reconciling accounts, drafting decks), with a human owning the judgment and sign-off.

## Links

* https://www.anthropic.com/news/finance-agents
* https://www.anthropic.com/news/advancing-claude-for-financial-services
* https://github.com/anthropics/financial-services
* https://www.vals.ai/benchmarks/finance_agent
* https://platform.claude.com/docs/en/managed-agents/overview
* https://claude.com/claude-for-excel
* https://fortune.com/2026/05/05/anthropic-wall-street-financial-services-agents-jamie-dimon/
* https://cfotech.news/story/anthropic-launches-ai-agents-for-financial-services
