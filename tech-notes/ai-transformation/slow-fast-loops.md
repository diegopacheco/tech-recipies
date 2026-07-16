# Slow / Fast Loops

## Fast loops
A fast loop happens while the developer is actively working with the agent:
1. Ask the agent to make a change.
2. Run the tests.
3. Inspect the result.
4. Give feedback.
5. Repeat within seconds or minutes.
Examples include:
* Interactive Claude Code or Codex sessions
* Test-fix-test cycles
* Compiler and linter feedback
* Small refactorings
* Local debugging
Fast loops are good when the developer needs immediate control and the task benefits from rapid steering.
Their weakness is that they can become reactive and trajectory-poisoned. The human keeps correcting the agent inside the same increasingly noisy conversation.

## Slow loops
A slow loop runs over hours—often asynchronously from the developer’s immediate coding session.
Dex’s example:
1. A nightly agent selects one bounded code-quality problem.
2. It investigates the codebase.
3. It implements a change.
4. It runs verification.
5. It opens a pull request.
6. A human reviews the PR the following morning.
HumanLayer eventually ran four agents that produced four morning PRs, but humans still reviewed them.
Slow loops have several advantages:
* The agent has enough time to research before changing code.
* Each loop can start with a fresh context.
* Work can be isolated in branches or worktrees.
* The output is a reviewable artifact rather than an endless conversation.
* Failures do not constantly interrupt developers.
* The system can use stronger verification gates.
The key distinction is:
A fast loop optimizes interaction latency. A slow loop optimizes the quality and reviewability of a completed unit of work.
Slow does not mean inefficient. Waiting eight hours for a well-researched PR may be better than spending two hours repeatedly correcting an agent.
