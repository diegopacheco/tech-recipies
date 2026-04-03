# Claude Code 

<!-- START doctoc generated TOC please keep comment here to allow auto update -->

**Table of Contents**  *generated with [DocToc](https://github.com/ktechhub/doctoc)*

<!---toc start-->

* [Claude Code](#claude-code)
  * [1. Global Instructions](#1-global-instructions)
  * [2. Prompt Advice](#2-prompt-advice)
  * [3. Create custom commands](#3-create-custom-commands)
  * [4. Excluding Files from Claude Context](#4-excluding-files-from-claude-context)
  * [5. Non-Obvious Use Cases for Claude Code](#5-non-obvious-use-cases-for-claude-code)
  * [6. Advanced Pipelines](#6-advanced-pipelines)
  * [7. Bash on Asteroids](#7-bash-on-asteroids)
  * [8. Custom Agents](#8-custom-agents)
  * [9. ultrathink](#9-ultrathink)
  * [10. Too many Options? Decision Criteria](#10-too-many-options-decision-criteria)
    * [1. CLAUDE.md - Behavioral Guidelines](#1-claudemd---behavioral-guidelines)
    * [2. Custom Commands - Reusable Prompts](#2-custom-commands---reusable-prompts)
    * [3. Hooks - Event-Driven Automation](#3-hooks---event-driven-automation)
    * [4. Custom Agents - Complex Multi-Step Tasks](#4-custom-agents---complex-multi-step-tasks)

<!---toc end-->

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## 1. Global Instructions

Global instructions will work for all directories, all sessions and all projects you do you in your machine with Claude Code. If I may draw a parallel this feature is the same as `~/.bashrc` or `~/.zshrc` for Claude.

This file must be placed in `~/.claude/CLAUDE.md` it control Claude code guidelines for all projects. Them you can write in any structure or format - instructions you want Claude to follow.

## 2. Prompt Advice

Be Explicit in Prompts

- Claude Code follows instructions literally
- "Fix the bug" vs "Fix the authentication timeout in login.ts:45"
- Reference specific files, functions, line numbers when possible
- Use @filename to reference files in slash commands
- Break large tasks into steps
- Claude tracks context across the session
- Easier to review and iterate on smaller changes

## 3. Create custom commands

Use Slash Commands for Repeated Tasks

- Create .claude/commands/ in your project root
- Common use cases: code review, test generation, refactoring patterns
- Personal commands in ~/.claude/commands/ for all projects
- Name them short and memorable (e.g., /fix, /test, /deploy)

Examples:

Example 1: Code Review Command
```
File: .claude/commands/review.md
Review the changes in this file for:
- Bugs and edge cases
- Performance issues
- Security vulnerabilities
- Code style and best practices
- Missing error handling

Provide specific line numbers for issues found.

Usage: /review @src/auth.js
```

Example 2: Test Generation Command
```
File: .claude/commands/tests.md
Generate comprehensive tests for $1 covering:
- Happy path scenarios
- Edge cases
- Error conditions
- Boundary values

Use the existing test patterns in this project.

Usage: /tests src/utils/validator.js
```

Example 3: Refactor Command
```
File: ~/.claude/commands/clean.md
Refactor $ARGUMENTS to:
- Remove code duplication
- Improve naming and clarity
- Simplify complex logic
- Maintain exact same behavior

Run tests after refactoring to verify nothing broke.

Usage: /clean src/payment/processor.js
```

Example 4: Performance Audit
```
File: .claude/commands/perf.md
Analyze $1 for performance issues:
- Unnecessary loops or iterations
- Database query optimization
- Memory allocations
- Blocking operations
- Caching opportunities

Suggest specific optimizations with code snippets.

Usage: /perf @api/users.ts
```

The key: commands save you from retyping the same instructions repeatedly.

## 4. Excluding Files from Claude Context

Claude Code uses `permissions.deny` in settings.json to exclude files/directories. This reduces:
- Token usage
- Noise from irrelevant files
- Processing time for large codebases
- Risk of Claude reading sensitive files

Global Exclusions: `~/.claude/settings.json`
Project Exclusions: `.claude/settings.json`

```json
{
  "permissions": {
    "deny": [
      "Read(./node_modules/**)",
      "Read(./vendor/**)",
      "Read(./venv/**)",
      "Read(./dist/**)",
      "Read(./build/**)",
      "Read(./out/**)",
      "Read(./**/*.min.js)",
      "Read(./**/*.bundle.js)",
      "Read(./**/*.map)",
      "Read(./package-lock.json)",
      "Read(./yarn.lock)",
      "Read(./pnpm-lock.yaml)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./**/*.key)",
      "Read(./**/*.pem)",
      "Read(./credentials.json)",
      "Read(./coverage/**)",
      "Read(./.nyc_output/**)",
      "Read(./.vscode/**)",
      "Read(./.idea/**)",
      "Read(./**/*.log)",
      "Read(./data/**)"
    ]
  }
}
```

## 5. Non-Obvious Use Cases for Claude Code

1. Git Archaeology - Investigate why code was written a certain way by analyzing git history, blame annotations, and
commit messages together with current code structure
2. Dependency Auditing - Scan package.json/requirements.txt/go.mod across multiple projects to identify version
inconsistencies, security vulnerabilities, and upgrade paths
3. Documentation Reverse Engineering - Generate accurate technical documentation by reading actual implementation
rather than outdated docs, including API contracts, state machines, and data flows
4. Codebase Onboarding Scripts - Create personalized learning paths by analyzing a new repository's structure,
identifying entry points, and generating reading orders for understanding the system
5. Test Data Generation - Analyze schema definitions, database models, and validation rules to generate realistic test
fixtures that respect all constraints and edge cases
6. Configuration Drift Detection - Compare config files across environments (dev/staging/prod) to identify
discrepancies, missing values, or environment-specific bugs
7. Refactoring Impact Analysis - Before making changes, analyze call graphs and dependency trees to predict blast
radius and identify all affected consumers
8. Performance Archaeology - Correlate git history with performance metrics to identify which commits introduced
regressions by analyzing algorithmic complexity changes
9. English Spelling and Grammar Checking - Review technical writing, comments, and documentation for clarity, conciseness.
10. API Evolution Planning - Analyze existing API usage patterns across consumers to design backward-compatible changes and generate migration guides.
11. Build Failure Forensics & Troubleshooting - Analyze build logs, recent commits, and dependency changes together to pinpoint root cause when CI mysteriously breaks.
12. Feature Flag Archaeology - Find stale feature flags by cross-referencing flag definitions with usage, creation
  dates, and A/B test completion to safely remove technical debt.
13. Security Audit Automation - Scan codebases for common security anti-patterns, outdated dependencies, and
  misconfigurations.

## 6. Advanced Pipelines

Here the idea is that you can create a script to automate complex flow, so you do not need to type a huge prompt all the time. This code could run in a jenkins job, or even dirrectly in your terminal.

pipeline.sh
```
#!/bin/bash

claude -p "Write a complete working REST API for user management using Python FastAPI with endpoints for create, read, update, delete users. Include all imports and a main block to run the server. Output executable Python code ONLY - no markdown, no explanations, no code blocks. Start with: from fastapi" >api_draft.py
echo "Step 1 done"

claude -p "Review this Python code for security vulnerabilities:

\`\`\`python
$(cat api_draft.py)
\`\`\`

List all security issues and recommended fixes." >security_review.md
echo "Step 2 done"

claude -p "Fix all security issues in this Python code:

\`\`\`python
$(cat api_draft.py)
\`\`\`

Security issues found:
$(cat security_review.md)

Output the complete fixed Python code with all security improvements applied. Output executable code ONLY - no markdown, no explanations, no code blocks around the code. Start with: from fastapi" >api_secure.py
echo "Step 3 done"

claude -p "Write comprehensive pytest tests for this API:

\`\`\`python
$(cat api_secure.py)
\`\`\`

Output executable Python test code ONLY - no markdown, no explanations, no code blocks. Start with: import pytest" >test_api.py
echo "Step 4 done"

cat > run.sh << 'EOF'
#!/bin/bash
python3 api_secure.py
EOF
chmod +x run.sh
echo "Step 5 done"
```

## 7. Bash on Asteroids

You can use Claude Code to help you write bash scripts for automating complex tasks. You can combine any program with bash + claude being a super powerful orchestrator.
```
#!/bin/bash

curl -s "wttr.in/London?format=3" | \
claude -p "Extract only the temperature number in Celsius from this text, output just the number" | tee weather_celsius.txt | \
xargs -I {} claude -p 'Is {} Celsius HOT or COLD? Output only HOT or COLD followed by the temperature value in Celsius' | tee weather_report.txt
```

Result:
```
COLD 10
```

## 8. Custom Agents

Claude code allow you to create custom agents. The cool thing is that it can generate the agent based in a prompt you give it. For example you can create a custom agent to help you with code reviews. More here: [custom-agents.md](custom-agents-cc/README.md)

## 9. ultrathink

If you want claude code to reason more deeply about a problem you can use ultrathink. 
The main idea is to force claude to think multiple times about the problem before answering. 

Example <br/>
<img src="images/ultrathink.png" width="600"/>

## 10. Too many Options? Decision Criteria

When to Use: Hooks vs Commands vs Agents vs CLAUDE.md?

### 1. CLAUDE.md - Behavioral Guidelines

Use when: You want to change HOW Claude behaves globally or per-project

Criteria:

- ✅ Style preferences (no comments, no emojis, code formatting)
- ✅ Language/framework conventions (always use TypeScript strict mode)
- ✅ Project-specific patterns (our API always returns JSON with snake_case)
- ✅ Quality standards (always write tests, never use any type)
- ✅ Restrictions (never install packages without asking, avoid library X)

Examples:

~/.claude/CLAUDE.md (global)
- Never use comments
- Always use const over let
- Prefer functional programming
- Never use emojis

.claude/CLAUDE.md (project-specific)
- This project uses Redux Toolkit
- API responses are snake_case
- All components must have PropTypes
- Test files go in __tests__ directory

Think of it as: Your .eslintrc or .editorconfig but for Claude's behavior

---
### 2. Custom Commands - Reusable Prompts

Use when: You type the same instructions repeatedly

Criteria:

- ✅ You find yourself copy-pasting the same prompt
- ✅ Task is well-defined and repeatable
- ✅ You want quick access via /command-name
- ✅ Task is single-purpose and focused
- ✅ Works within a single conversation context

Examples:

.claude/commands/review.md
Review $1 for:
- Security vulnerabilities
- Performance issues
- Edge cases
- Code duplication

Usage: /review src/auth.ts

.claude/commands/test.md
Generate comprehensive tests for $ARGUMENTS including:
- Happy path
- Edge cases
- Error handling
- Mocks for external dependencies

Usage: /test src/payment.js

Think of it as: Git aliases or bash aliases for Claude

---
### 3. Hooks - Event-Driven Automation

Use when: You want something to happen automatically on events

Criteria:

- ✅ Needs to run automatically (no manual trigger)
- ✅ Responds to events (file write, tool call, session start)
- ✅ Integrates with external tools (git, linters, formatters)
- ✅ Validation or enforcement (block bad actions)
- ✅ Logging and monitoring

Examples:

Auto-format on save:
```
{
  "hooks": {
    "tool-result": {
      "command": "if [[ '${TOOL_NAME}' == 'Write' ]]; then prettier --write '${TOOL_ARGS}'; fi",
      "enabled": true
    }
  }
}
```

Prevent commits to main:
```
{
  "hooks": {
    "tool-call": {
      "command": "if [[ '${TOOL_NAME}' == 'Bash' ]] && echo '${TOOL_ARGS}' | grep -q 'git push.*main'; then
echo 'Blocked: Cannot push to main'; exit 1; fi",
      "enabled": true,
      "blocking": true
    }
  }
}
```

Think of it as: Git hooks or GitHub Actions for Claude

---
### 4. Custom Agents - Complex Multi-Step Tasks

Use when: Task requires multiple rounds of searching, analysis, and decision-making

Criteria:

- ✅ Task is exploratory (need to search, then decide, then search again)
- ✅ Multiple tool calls required (10+ operations)
- ✅ Requires decision trees (if X found, then do Y, else do Z)
- ✅ Needs to work autonomously without user input
- ✅ Complex context management across many files

Examples:

Refactoring Agent:
- Search for all usages of a function
- Analyze each usage context
- Determine safe refactoring strategy
- Apply changes across multiple files
- Verify nothing broke

Security Audit Agent:
- Scan codebase for patterns
- Analyze dependencies
- Check configuration files
- Cross-reference with CVE databases
- Generate report with severity levels

Migration Agent:
- Find all files using old API
- Understand usage patterns
- Generate migration plan
- Apply transformations
- Update tests

Think of it as: A specialized team member who can work independently on complex tasks

---
Decision Matrix

| Need                                      | Solution       |
|-------------------------------------------|----------------|
| Claude always formats code a certain way  | CLAUDE.md      |
| Run prettier after every file write       | Hook           |
| Quick code review on demand               | Custom Command |
| Audit entire codebase for security issues | Custom Agent   |
| Never use comments                        | CLAUDE.md      |
| Auto-run tests after changes              | Hook           |
| Generate API documentation                | Custom Command |
| Migrate 50 files from old to new API      | Custom Agent   |
| Enforce git commit message format         | Hook           |
| Refactor function with specific pattern   | Custom Command |
| Analyze and fix all TypeScript errors     | Custom Agent   |
| Always use tabs not spaces                | CLAUDE.md      |

---
Practical Combination Example

Scenario: You're building a React app and want comprehensive tooling

CLAUDE.md (Project-wide rules)
- Always use functional components
- Props use TypeScript interfaces
- State management uses Zustand
- Never use `any` type

Custom Commands (Quick actions)
/component - Generate new React component with tests
/hook - Create custom React hook
/test - Generate tests for component

Hooks (Automation)
{
  "tool-result": {
    "command": "prettier --write && eslint --fix",
    "enabled": true
  }
}

Custom Agent (Complex tasks)
- Component refactoring agent
- Accessibility audit agent
- Performance optimization agent

---
Quick Selection Guide

Ask yourself:

1. Is it about HOW Claude should work? → CLAUDE.md
2. Do I type this same prompt often? → Custom Command
3. Should this happen automatically? → Hook
4. Is this a complex multi-step investigation? → Custom Agent