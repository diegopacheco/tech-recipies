# Workflows and Skills

## 1. Best Practices for Skills

### Keep Skills Small and Focused

A skill should do one thing well. When a skill tries to handle too many concerns it becomes fragile and hard to maintain. A skill that creates a backend API endpoint should not also handle frontend components, database migrations, and deployment. Split responsibilities into separate skills.

### Minimize Context Window Consumption

The 200K token context window is your most precious resource. Skills that consume too much of it defeat their own purpose. Frameworks like GSD consume 141.9% of the context window before you even start working. Keep skill prompts lean — under 5% of the context window is ideal, under 10% is acceptable. The Diego Pacheco CLAUDE.md at 354 tokens (0.18%) is an effective reference for how small instructions can be while remaining powerful.

### Use Explicit Completion Criteria

Every skill must have clear, unambiguous criteria for when it is done. Without explicit exit conditions, Claude tends to stop prematurely or loop indefinitely. Ralph's dual-gate exit pattern (completion indicators + explicit signal) is a proven approach. Define what "done" looks like: tests pass, file exists, output matches expected format.

### Ground Skills in Real File Paths and Patterns

Skills work best when they reference concrete file paths, naming conventions, and project structure rather than abstract descriptions. Instead of "create a service file", say "create a file at `src/services/{name}.ts` following the pattern in `src/services/user.ts`". Concrete references reduce hallucination.

### Design for Fresh Context

Skills should assume they start with a clean context. Do not rely on prior conversation state or assume the user has already loaded specific files. Each skill invocation should be self-contained — read what you need, do the work, produce the output.

### Include Validation Steps

A skill should verify its own output. If it generates code, it should run the compiler or linter. If it creates a file, it should verify the file exists. If it modifies a config, it should validate the config format. Self-validation catches errors before the user sees them.

### Use Model Routing When Possible

Not every task needs Opus. Use Haiku for lookups, file reads, and simple transformations. Use Sonnet for standard code generation. Reserve Opus for complex reasoning, architectural decisions, and multi-step planning. This can save 30-50% on token costs.

### Document the Partition Key

Every skill should clearly state what input it expects. What is the minimum information needed to invoke it? A backend developer skill needs: language, framework, endpoint spec. A test skill needs: test framework, target file, test type. Make these inputs explicit in the skill definition.

## 2. Anti-Patterns for Skills

### The Kitchen Sink Skill

A single skill that tries to handle everything: scaffolding, implementation, testing, documentation, deployment. These skills are fragile, consume massive context, and fail in unpredictable ways. Split them into focused, composable skills.

### Context Vampire

Skills that load enormous system prompts, persona definitions, backstories, and elaborate instructions. BMAD loads 684K tokens when fully activated (342% of context). SuperClaude consumes 40%. By the time the skill starts working, there is no room left for actual code. Keep instructions minimal and load additional context only when needed.

### The Assumption Skill

Skills that assume project structure, framework, or conventions without checking. A skill that blindly writes to `src/components/` without verifying the directory exists or that the project uses React. Always read before writing, verify before assuming.

### Premature Exit

Claude stops before the task is truly complete. The skill says "done" but tests are not running, imports are missing, or the code does not compile. This happens when completion criteria are vague or absent. Always define explicit done conditions and verify them.

### The Hallucination Trap

Skills that generate URLs, API references, library versions, or statistics without grounding them in real data. A skill should never invent a package name or assume a library version. Read `package.json`, check the docs, verify the import path exists.

### Over-Engineered Orchestration

Building elaborate multi-step pipelines with dependency graphs, state machines, and handoff protocols for tasks that a simple sequential execution would handle. A while-true loop (Ralph pattern) outperforms complex orchestration for many real-world tasks. Start simple, add complexity only when simple fails.

### No Error Recovery

Skills that crash on the first unexpected condition without any fallback. A file does not exist — skill fails. A test fails — skill stops. Build resilience: if a file does not exist, check alternative paths. If a test fails, read the error and attempt a fix.

### Copy-Paste Persona Bloat

Defining elaborate agent personas with backstories, personality traits, and communication styles. "You are a senior architect with 20 years of experience who speaks in a formal tone..." These instructions waste tokens and do not improve output quality. Tell the agent what to do, not who to be.

## 3. Workflows

### Best Practices for Workflows

**Phase-Based Execution**: break workflows into clear phases (plan, implement, verify, fix). Each phase should have explicit entry and exit criteria. OMC's staged pipeline (plan → PRD → exec → verify → fix) is a good reference model.

**Fresh Context Per Phase**: do not carry one context window across the entire workflow. Start fresh for each major phase, passing only structured summaries and artifacts between phases. This prevents context rot — the gradual degradation of output quality as the context window fills with stale information.

**Human-in-the-Loop at Checkpoints**: insert approval gates between critical phases. Let the human review the plan before implementation starts. Let them review the code before tests run. Fully autonomous workflows without checkpoints produce catastrophic hallucinations that cascade through subsequent phases.

**Structured Handoffs Between Agents**: when one agent hands off to another, use structured formats (YAML, markdown with headers, task lists). Do not rely on prose summaries — they lose critical details. A handoff document should contain: what was done, what files were changed, what decisions were made, what remains to be done.

**Limit Parallelism to 5-7 Agents**: theoretical limits suggest 20-30 parallel agents, but practical experience shows merge conflicts, coordination overhead, and context confusion scale exponentially. 5-7 agents is the sweet spot for most workflows.

**External State Over Context State**: store workflow state in git, files, or databases — not in the context window. Context gets compacted, compressed, and eventually lost. Git history, markdown files, and task lists survive across sessions and can be audited.

**Monitor Token Usage**: track how many tokens each phase consumes. If a phase burns through 50% of the context window, it needs to be split. OMC's HUD pattern (showing token usage in real-time) helps teams understand where their budget goes.

### Anti-Patterns for Workflows

**The Infinite Context Session**: running a single Claude session for hours expecting it to remember everything. Context compaction kicks in, early instructions get compressed, and output quality degrades. Break long workflows into discrete sessions with file-based state.

**Lead Does the Work**: the orchestrator agent starts implementing instead of delegating. The lead should coordinate, assign tasks, review output, and make decisions — not write code. Claude Agent Teams' "delegate mode" restricts the lead to coordination-only tools for this reason.

**No Completion Gates**: workflows that run to "completion" without verifying each step. Tests pass but the UI is broken. Code compiles but the feature does not work. Every workflow phase needs explicit verification: run tests, check output, validate behavior.

**Synchronous Blocking**: agents waiting for each other in tight synchronous loops. Agent A calls Agent B, waits for response, then calls Agent C. Use asynchronous message passing with shared state (task lists) instead. Agents should work independently and coordinate through shared artifacts.

**Over-Specified Workflows**: defining every possible edge case, error condition, and recovery path upfront. This produces workflows with 80% error handling and 20% actual work. Start with the happy path, add error handling for observed failures.

**Token-Unaware Orchestration**: launching 10 agents with large system prompts without calculating total token cost. 10 agents × 80K tokens each = 800K tokens consumed before any work starts. Budget your tokens across agents and use model routing to reduce cost.

### Lessons Learned from the Agents Directory

**Simplicity Wins Over Sophistication**: Ralph's while-true bash loop produces reliable results with 7,000 tokens of overhead. GSD's elaborate orchestration needs 283,800 tokens (exceeds context window). The simpler tool often outperforms the complex one. Start simple, measure, add complexity only when you can prove it helps.

**Context is the Real Bottleneck**: every framework in the agents directory is solving the same fundamental problem — how to work within a finite context window. The solutions differ (fresh context, vector DBs, file-based memory, structured handoffs) but the constraint is universal. Optimize for context coherence, not for model intelligence.

**Framework Overhead Matters More Than Features**: the agents directory documents framework sizes ranging from 354 tokens to 283,800 tokens. The frameworks with the most features are often the least practical because they consume the resource they need most. Evaluate frameworks by overhead-to-value ratio, not feature count.

**Git is the Best Memory System**: across all frameworks studied, git-backed state (file changes, commit history, branch isolation) is the most reliable persistence mechanism. It is auditable, versioned, conflict-resolvable, and survives context compaction. Vector DBs are useful for semantic search but git is the foundation.

**Parallel Agents Create Merge Conflicts**: every framework that supports parallel agents (GasTown, claude-flow, Claude Teams) reports merge conflicts as the primary operational challenge. Worktree isolation helps but does not eliminate the problem. Design workflows to minimize concurrent edits to the same files.

**Visual and UI Bugs Are Invisible to Agents**: functional tests pass but the rendered output is wrong. Agents cannot see CSS rendering, layout issues, or visual regressions. Human review of rendered output remains essential. Add visual regression testing (screenshot comparison) where possible.

**The Premature Exit Problem is Universal**: every framework documents the problem of Claude stopping before truly finishing. The most effective solution is Ralph's dual-gate pattern: (1) look for completion indicators in the output AND (2) require an explicit completion signal. Single-condition exits fail consistently.

**Cost Scales with Agent Count, Not Quality**: running more agents does not proportionally improve output quality. There is a point of diminishing returns around 5-7 agents where coordination overhead exceeds the benefit of additional parallelism. A well-configured 3-agent workflow often outperforms a 10-agent swarm.

## 4. How to Keep Improving Prompts, Skills, and Workflows

### Measure Everything

Track metrics for every skill and workflow execution:
- **Token consumption per phase**: identify which phases are too expensive
- **Completion rate**: how often does the skill finish without human intervention
- **Error rate**: how often does the skill produce incorrect output
- **Time to completion**: how long does each phase take
- **Rework rate**: how often does output need to be redone

Without measurement, improvement is guesswork.

### Iterate on Real Failures

When a skill or workflow fails, do not just fix the output — fix the prompt. Read the full context of the failure: what did the agent see, what did it decide, why did it go wrong? Common root causes:
- Ambiguous instructions (agent interpreted differently than intended)
- Missing context (agent did not have the information it needed)
- Context rot (early instructions were compressed away)
- Hallucination (agent fabricated data instead of reading it)

Each failure pattern maps to a specific prompt fix.

### A/B Test Prompt Variations

When improving a skill prompt, keep the old version and test both on the same task. Compare:
- Did the new prompt produce better output?
- Did it consume fewer tokens?
- Did it complete more reliably?

Do not assume a longer or more detailed prompt is better. Often, removing instructions improves output by reducing confusion and saving context.

### Build a Prompt Changelog

Track every change to your skills and workflows in a changelog. Record what changed, why it changed, and what the measured impact was. This prevents circular improvements (changing A to B, then B back to A three months later) and builds institutional knowledge about what works.

### Extract Patterns from Success

When a skill works exceptionally well, analyze why:
- Was the prompt unusually clear?
- Did it reference concrete files and patterns?
- Was the context window clean?
- Did it use the right model for the task?

Codify these success factors into reusable patterns that other skills can adopt.

### Prune Relentlessly

Remove instructions that do not contribute to output quality. Every token in a system prompt is a token not available for actual work. Review skills quarterly:
- Remove instructions the agent already follows by default
- Consolidate redundant instructions
- Delete persona and style instructions that do not change behavior
- Replace verbose explanations with concrete references

### Version Your Skills

Treat skills as code. Version them, review changes, and test them before deploying. A breaking change to a skill prompt can silently degrade output quality across all workflows that use it. Use git branches to test skill changes in isolation.

### Learn from the Ecosystem

The agents directory documents 16+ frameworks and tools. Each one solves a real problem someone encountered. Study their approaches:
- Ralph teaches that simplicity and fresh context beat complexity
- OMC teaches that phased pipelines with handoffs prevent context rot
- GasTown teaches that git-backed state outlasts everything else
- SuperClaude teaches that framework overhead can consume your most valuable resource
- Claude Teams teaches that native coordination beats third-party orchestration

### Close the Feedback Loop

The most important practice is closing the loop between execution and improvement. After every significant workflow run:
1. Review what worked and what did not
2. Identify the root cause of failures
3. Update the skill or workflow prompt
4. Test the updated version
5. Measure the improvement
6. Record the change in the changelog

Continuous improvement requires continuous measurement. The teams that improve fastest are the ones that treat their prompts, skills, and workflows as living systems that evolve based on observed behavior, not as static configurations written once and forgotten.
