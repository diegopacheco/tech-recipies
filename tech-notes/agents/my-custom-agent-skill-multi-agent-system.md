# My Custom Agent Skill Multi-Agent System

I wrote a simple tool in Rust, capable of deploying agents into Claude code, I called it RAD (Rust Agent Deployer).
https://github.com/diegopacheco/ai-playground/tree/main/pocs/claude-agents-deployer

## Agents

```
Core Build Agents (3)
1. Java Backend Developer — Spring Boot 4.x, Java 25
2. Go Backend Developer — Go 1.25+, Gin Gonic
3. Rust Backend Developer — Rust 1.93+, Axum/Actix-web
4. React Developer — React 19, TypeScript, TanStack, Bun, Vite, Tailwind CSS
5. Relational DBA — PostgreSQL/MySQL/SQLite, schema design, migrations

Testing Agents (5)
6. Unit Testers — JUnit 5 (Java), Jest (TS), Rust built-in tests
7. Integration Tester — End-to-end API testing, Testcontainers
8. UI Testing Playwright — E2E UI tests, page object models
9. K6 Stress Test — Performance/load testing, ramp-up/ramp-down
10. Testing Agent (meta-orchestrator) — Coordinates all 4 test types

Review & Documentation Agents (6)
11. Code Reviewer — Code quality, bugs, smells, performance
12. Security Reviewer — OWASP Top 10, auth/authz, injection
13. Design Doc Syncer — Keeps design-doc.md aligned with implementation
14. Feature Documenter — API docs, workflows, configuration
15. Changes Summarizer — Release notes, git diff analysis, changelog
16. Reviewer Agent (meta-orchestrator) — Coordinates all review activities
```

## The Original Agent Skill

```
---
  name: deployer-workflow
  description: Full-stack development workflow that orchestrates all deployer agents (backend, frontend, database, testing, review,
   documentation) in a phased pipeline. Asks which backend language (Java/Go/Rust) then runs all agents.
  allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskList]
  ---

  # Deployer Workflow Skill

  Orchestrate all deployer agents in a structured, phased development pipeline.

  ## Instructions

  When this skill is invoked, follow this exact workflow:

  ### Step 0 - Read the user prompt

  The user will provide a prompt describing what they want to build: $ARGUMENTS

  If no arguments are provided, use AskUserQuestion to ask: "What do you want to build? Describe the feature or application."

  ### Step 1 - Pick Backend Language

  Use AskUserQuestion to ask which backend language to use. The options are:
  - **Java** - Spring Boot 4.x, Java 25
  - **Go** - Go 1.25+, Gin Gonic
  - **Rust** - Rust 1.93+, Axum/Actix-web

  ### Step 2 - Read Agent Definitions

  Read all agent definition files from the project's `agents/` directory. These files contain the instructions for each agent role.
   The agents directory is at the project root.

  ### Step 3 - Phase 1: Build (parallel)

  Spawn 3 Task subagents in parallel using `subagent_type: "general-purpose"`. Each subagent receives the user's feature
  description plus the corresponding agent definition as context:

  1. **Backend Developer** - Use the chosen language agent (java-backend-developer-agent.md, go-backend-developer-agent.md, or
  rust-backend-developer-agent.md). Tell it to implement the backend for the user's request.
  2. **React Developer** - Use react-developer-agent.md. Tell it to implement the frontend for the user's request.
  3. **Relational DBA** - Use relational-dba-agent.md. Tell it to design and create the database schema for the user's request.

  Wait for all 3 to complete before moving to Phase 2.

  ### Step 4 - Phase 2: Test (parallel)

  Spawn 4 Task subagents in parallel:

  1. **Unit Testers** - Use unit-testers-agent.md. Tell it to write unit tests for all the code written in Phase 1.
  2. **Integration Tester** - Use integration-tester-agent.md. Tell it to write integration tests covering the API and database
  interactions.
  3. **UI Testing Playwright** - Use ui-testing-playwright-agent.md. Tell it to write Playwright end-to-end tests for the React
  frontend.
  4. **K6 Stress Test** - Use k6-stress-test-agent.md. Tell it to write k6 performance tests for the API endpoints.

  Wait for all 4 to complete before moving to Phase 3.

  ### Step 5 - Phase 3: Review (parallel)

  Spawn 2 Task subagents in parallel:

  1. **Code Reviewer** - Use code-reviewer-agent.md. Tell it to review all code written in Phases 1 and 2 for quality, bugs, and
  best practices.
  2. **Security Reviewer** - Use security-reviewer-agent.md. Tell it to review all code for security vulnerabilities, OWASP Top 10,
   and security best practices.

  Wait for both to complete. If either reviewer finds critical issues, fix them before moving to Phase 4.

  ### Step 6 - Phase 4: Document (parallel)

  Spawn 3 Task subagents in parallel:

  1. **Design Doc Syncer** - Use design-doc-syncer-agent.md. Tell it to sync the design document with the implemented code,
  updating it to reflect what was built.
  2. **Feature Documenter** - Use feature-documenter-agent.md. Tell it to document the feature including API docs, configuration,
  and usage.
  3. **Changes Summarizer** - Use changes-sumarizer-agent.md. Tell it to summarize all changes made, categorize them, and generate
  a changelog entry.

  ### Step 7 - Summary

  After all phases complete, provide a final summary to the user:
  - What was built (backend, frontend, database)
  - Test coverage (unit, integration, UI, stress)
  - Review findings and fixes applied
  - Documentation generated
  - Any remaining issues or recommendations

  ## Agent Definition Location

  The agent definitions are markdown files in the `agents/` directory at the project root. Each file contains the role description,
   capabilities, and guidelines for that agent. Always read the actual file content and pass it as context to the Task subagent.

  ## Task Subagent Pattern

  When spawning each Task subagent, use this pattern:
  - `subagent_type: "general-purpose"`
  - Include the full agent definition markdown in the prompt
  - Include the user's feature description
  - Include relevant context from previous phases (file paths created, schemas designed, etc.)
  - Tell the subagent to write actual code, not just describe what to do

  ## Phase Dependencies

  - Phase 2 depends on Phase 1 (tests need code to test)
  - Phase 3 depends on Phase 1 and Phase 2 (reviews need all code)
  - Phase 4 depends on all previous phases (docs need final code)

  Within each phase, all subagents run in parallel since they are independent of each other.
```

## The Final Version of the Skill

```
---
  name: deployer-workflow
  description: Full-stack development workflow that orchestrates deployer agents (backend, frontend, database, testing, review) in
  a phased pipeline. Asks which backend language (Java/Go/Rust) then runs all agents.
  allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Task, AskUserQuestion, TaskCreate, TaskUpdate, TaskList]
  ---

  # Deployer Workflow Skill V5

  On the very first message, display: `Deployer Workflow Skill V5`

  ## Global Context
  - User request: $ARGUMENTS
  - Agents directory: `agents/`
  - Agent definition files: all markdown files in `agents/`
  - Design doc: `design-doc.md` (project root)
  - Progress file: `todo.md` (project root)
  - Mistakes file: `mistakes.md` (project root)
  - Review folder: `review/{yyyy-MM-dd}/`
  - Changelog: `changelog.md` (project root)
  - README: `README.md` (project root)

  ## Agents

  There are 5 agents total:
  1. **Backend Developer** (java-backend-developer-agent.md / go-backend-developer-agent.md / rust-backend-developer-agent.md)
  2. **React Developer** (react-developer-agent.md)
  3. **Relational DBA** (relational-dba-agent.md)
  4. **Testing Agent** (testing-agent.md) - handles unit tests, integration tests, UI tests (Playwright), stress tests (K6)
  5. **Reviewer Agent** (reviewer-agent.md) - handles code review, security review, design doc sync, feature docs, changes summary

  ## Rules
  - If $ARGUMENTS is empty, ask: "What do you want to build? Describe the feature or application."
  - Ask backend language using AskUserQuestion with options:
    - Java: Spring Boot 4.x, Java 25
    - Go: Go 1.25+, Gin Gonic
    - Rust: Rust 1.93+, Axum/Actix-web
  - Read all agent definitions from `agents/` and pass them as context to subagents.
  - Use Task subagents with `subagent_type: "general-purpose"`.
  - Include user request, relevant files, and the full agent definition in each subagent prompt.
  - Phase order: Build -> Test -> Review (includes Changelog and README).
  - Phase dependencies: Test depends on Build. Review depends on Build + Test.
  - After each phase, update `todo.md` by marking completed items with `[x]`.

  ## Mistakes Tracking

  - `mistakes.md` in the project root tracks all build failures, test failures, and issues across all phases.
  - Every agent MUST read `mistakes.md` before starting work to avoid repeating past mistakes.
  - Every agent MUST append new mistakes/issues they encounter to `mistakes.md` with the phase name and a short description.
  - At the start of the workflow, create `mistakes.md` if it does not exist with a header `# Mistakes Log`.
  - Format: `- [Phase N: Name] description of the mistake or issue and how it was fixed`

  ## Build and Test Enforcement

  - The build MUST compile and pass before moving to Phase 2 (Test).
  - ALL tests (unit, integration, UI, stress) MUST pass before moving to Phase 3 (Review).
  - If the build fails, fix it immediately. Do not proceed until the build is green.
  - If any test fails, debug and fix the root cause. Re-run all tests until they all pass.
  - After fixing build or test failures, record what went wrong and how it was fixed in `mistakes.md`.
  - At the end of Phase 1, run the full build and verify it succeeds.
  - At the end of Phase 2, run all tests and verify they all pass.

  ## Step 1: Review Plan
  Use AskUserQuestion with checkboxes (all checked by default) and allow unchecking. Store selections and skip unchecked items:
  - Phase 1: Build
    - Build Components (Backend, Frontend, Database)
    - Verify Build (compile, run, connectivity)
  - Phase 2: Test
    - All Tests (Unit, Integration, UI Playwright, K6 Stress)
  - Phase 3: Review
    - Full Review (Code, Security, Design Doc Sync, Feature Docs, Changes Summary)
    - Changelog & README Update

  Initialize `todo.md` with current date (yyyy-MM-dd) and all selected items as `[ ]`.

  ## Step 2: Design Doc
  Create `design-doc.md` with:
  - Architecture overview
  - Backend API endpoints and responsibilities
  - Frontend components and interactions
  - Database schema design
  - Integration points between frontend, backend, database

  ## Phase 1: Build
  ### Build Components (parallel)
  Spawn 3 subagents in parallel:
  1. **Backend Developer**: use chosen language agent (java/go/rust backend agent). Implement backend per `design-doc.md`. Agent
  MUST read `mistakes.md` first.
  2. **React Developer**: use react-developer-agent.md. Implement frontend per `design-doc.md`. Agent MUST generate frontend unit
  tests (e.g. component tests using Vitest/Jest + React Testing Library). Agent MUST read `mistakes.md` first.
  3. **Relational DBA**: use relational-dba-agent.md. Design and create DB schema per `design-doc.md`. Agent MUST read
  `mistakes.md` first.

  ### Verify Build
  After all 3 subagents complete:
  - Verify DB schema/migrations apply successfully.
  - Verify backend compiles, builds, and runs with DB connection.
  - Verify frontend builds and can be served and connects to backend.
  - Run `build.sh` and check stdout/stderr for both backend and frontend. There MUST be zero errors AND zero warnings. If there are
   any errors or warnings, fix the root cause and re-run `build.sh` in a loop until the output is 100% clean (no errors, no
  warnings).
  - Create `run.sh` that starts the database, backend, and frontend. The script MUST log the default user/pass credentials for the
  application to stdout on startup.
  - Run `run.sh` and verify that the database, backend, and frontend all start successfully and are reachable. If any component
  fails to start, fix the issue, record it in `mistakes.md`, and re-run `run.sh`.
  - If ANY build step fails: fix the issue, record it in `mistakes.md`, and re-verify.
  - Do NOT proceed to Phase 2 until the full build is green, `build.sh` produces zero errors and zero warnings, and `run.sh` starts
   all components successfully.

  ## Phase 2: Test
  Spawn 1 subagent:
  1. **Testing Agent**: use testing-agent.md. Run all tests (unit, integration, UI Playwright, K6 stress) for both backend AND
  frontend code from Phase 1. Frontend unit tests MUST be included. Agent MUST read `mistakes.md` first.

  After the testing agent completes:
  - Verify ALL tests pass by running the full test suite.
  - If ANY test fails: fix the issue, record it in `mistakes.md`, re-run all tests.
  - Do NOT proceed to Phase 3 until all tests are green.

  ### Verify Tests
  - Verify that a dedicated script exists for each test type: `run-unit-tests.sh`, `run-integration-tests.sh`, `run-e2e-tests.sh`,
  `run-stress-tests.sh`. If any script is missing, create it.
  - Run every test script and check stdout/stderr for both backend and frontend. There MUST be zero errors AND zero warnings. If
  there are any errors or warnings, fix the root cause and re-run the failing script in a loop until the output is 100% clean (no
  errors, no warnings).
  - ALL test scripts MUST pass before proceeding. Do NOT move to Phase 3 until every test script exits with code 0 and produces
  zero errors and zero warnings.

  ## Phase 3: Review
  Create `review/{current-date}/`.
  Spawn 1 subagent:
  1. **Reviewer Agent**: use reviewer-agent.md. Perform code review, security review, sync design doc, write feature docs, and
  summarize changes. Agent MUST read `mistakes.md` first. Outputs:
     - `review/{current-date}/code-review.md`
     - `review/{current-date}/sec-review.md`
     - `review/{current-date}/features.md`
     - `review/{current-date}/summary.md`
     - Updates `design-doc.md`

  If critical issues are found, fix them and record in `mistakes.md`.

  ### Changelog
  Create `changelog.md` using git info:
  - Use `git status`, `git diff`, `git log`.
  - Include current date, what was built, files created/modified, test coverage summary, review findings and fixes, docs generated,
   remaining issues or recommendations.

  ### README
  Update/create `README.md` with:
  - Overview
  - Links to: `design-doc.md`, `review/{current-date}/code-review.md`, `review/{current-date}/sec-review.md`,
  `review/{current-date}/features.md`, `review/{current-date}/summary.md`, `changelog.md`
  - Summary highlights from `review/{current-date}/summary.md`
  - Quick start (backend, frontend, database)
```

## The evolution in waves

```
V1 (97 lines, ~1,400 tokens) - "Fire and Pray"

  Spawns 12 agents across 4 phases. Prose tutorial format explaining to the LLM how its own tools work. No design doc, no
  verification, no progress tracking, no mistake tracking. Agents build without a shared plan. If the build breaks, nobody knows.
  Insight: You don't need to teach the LLM how subagent_type: "general-purpose" works - it already knows. 20 lines of boilerplate
  wasted.

  V2 (101 lines, ~1,500 tokens) - "Plan Before You Build"

  Killed the prose, switched to declarative Global Context + Rules format. Added design-doc.md before building, user checkboxes to
  skip phases, todo.md progress tracking, and a Verify Components gate. Same 12 agents. Insight: Compression doesn't mean less
  functionality. The skill does MORE in 4 extra lines than V1 did in 97 because every line is an instruction, not an explanation.

  V3 (127 lines, ~1,900 tokens) - "Learn From Mistakes"

  The architecture shift. Consolidated 12 agents down to 5 (1 Testing Agent replaces 4, 1 Reviewer Agent replaces 5). Added
  mistakes.md cross-phase learning and Build and Test Enforcement rules. Insight: Fewer agents with full context outperform many
  agents with fragmented context. A single testing agent that sees all code writes better tests than 4 isolated agents. The
  mistakes file was the breakthrough - agents stop repeating the same failures.

  V4 (134 lines, ~2,000 tokens) - "Zero Tolerance"

  Added build.sh verification loop (zero errors AND zero warnings, re-run until clean). Added Verify Tests with dedicated scripts
  (run-unit-tests.sh, etc.) that must exit 0. Made frontend unit tests mandatory. Merged Changelog/README into Phase 3. Insight:
  "Verify it works" is vague. "Run build.sh in a loop until stdout has zero errors and zero warnings" is not. Explicit exit-code
  checking and script-per-test-type made the difference between "tests exist" and "tests pass".

  V5 (137 lines, ~2,100 tokens) - "Prove It Runs"

  Added run.sh creation with credential logging and runtime verification (start DB + backend + frontend, verify all reachable).
  Triple gate: build clean + run.sh succeeds + all components reachable. Insight: Code that compiles is not code that works. V4
  proved the build was clean, V5 proved the app actually starts and connects end-to-end. Only 3 lines added but it closed the last
  gap - you could run the app immediately after the workflow finishes.

  ---
  The Arc

  V1 -> V2: Stop explaining, start instructing (format compression)
  V2 -> V3: Fewer agents, shared memory (architecture change)
  V3 -> V4: Demand proof, not promises (verification loops)
  V4 -> V5: Compiles != Runs (runtime verification)
```

## Result

https://github.com/diegopacheco/ai-playground/tree/main/pocs/adwf-twitter-like-opus-4-6-v5-skill