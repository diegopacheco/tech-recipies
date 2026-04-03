# Claude Agent Teams

## 1. What is it?

Claude Agent Teams is a built-in experimental feature in Claude Code CLI that lets you coordinate multiple Claude Code instances working together as a team. One session acts as the team lead, coordinating work, assigning tasks, and synthesizing results. Teammates work independently, each in its own context window, and communicate directly with each other through a shared task list and messaging system.

Unlike subagents (which run within a single session and can only report back to the main agent), teammates are full independent Claude Code sessions. You can interact with individual teammates directly without going through the lead. The feature is disabled by default and must be enabled via the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` environment variable or `settings.json`.

Agent teams are a first-party Anthropic feature shipped directly in Claude Code, not a third-party plugin or framework.

## 2. Main Features

- Team lead + N teammates architecture where each teammate is a fully independent Claude Code session with its own context window
- Shared task list with three states (pending, in-progress, completed) and dependency tracking between tasks
- Direct inter-agent messaging: teammates send messages to each other, not just back to the lead
- Broadcast messaging to all teammates simultaneously (costs scale linearly with team size)
- Two display modes: in-process (all teammates in one terminal, navigate with Shift+Up/Down) and split-pane (each teammate in its own tmux/iTerm2 pane)
- Delegate mode restricts the lead to coordination-only tools (spawning, messaging, shutdown, task management) preventing it from implementing directly
- Plan approval mode: teammates work in read-only plan mode until the lead approves their approach before implementation begins
- File-lock-based task claiming prevents race conditions when multiple teammates try to claim the same task
- Automatic dependency resolution: when a teammate completes a task, blocked downstream tasks unblock automatically
- Hook-based quality gates: `TeammateIdle` (exit code 2 sends feedback and keeps teammate working) and `TaskCompleted` (exit code 2 prevents completion with feedback)
- Graceful shutdown protocol: lead sends shutdown request, teammate can approve or reject with explanation
- Natural language control: tell the lead what you want and it handles team creation, task assignment, and delegation
- Per-teammate model selection: specify which Claude model each teammate should use
- Team config stored at `~/.claude/teams/{team-name}/config.json`, task list at `~/.claude/tasks/{team-name}/`

## 3. Pros

- Native first-party feature: no plugins, no npm packages, no external dependencies beyond Claude Code itself
- True parallel execution: each teammate is a separate Claude Code instance working concurrently on independent tasks
- Self-coordination: teammates claim unassigned tasks, complete them, and pick up the next one without constant lead intervention
- Direct teammate communication enables debate, challenge, and synthesis patterns that subagents cannot do
- Split-pane mode gives full visibility into every teammate's progress simultaneously
- Delegate mode prevents the common problem of the lead implementing tasks itself instead of delegating
- Plan approval gives control over risky changes: the lead reviews and approves teammate plans before they touch code
- Hook integration enables automated quality enforcement without manual intervention
- Works with existing CLAUDE.md, MCP servers, and skills: teammates load the same project context as a regular session
- Natural language interface: no API calls or config files needed to create teams, assign tasks, or manage work

## 4. Cons

- Experimental and disabled by default: must opt-in via environment variable, behavior may change across releases
- High token cost: each teammate is a separate Claude instance, token usage scales linearly with team count
- No session resumption: `/resume` and `/rewind` do not restore in-process teammates, requiring new spawns after resume
- Task status can lag: teammates sometimes fail to mark tasks as completed, blocking dependent tasks
- Slow shutdown: teammates finish their current request or tool call before shutting down
- One team per session: cannot manage multiple teams concurrently from a single lead
- No nested teams: teammates cannot spawn their own teams, only the lead manages the team
- Fixed lead: the session that creates the team is the lead for its lifetime, no leadership transfer
- Permissions locked at spawn: all teammates start with the lead's permission mode, no per-teammate modes at spawn time
- Split-pane mode requires tmux or iTerm2, not supported in VS Code terminal, Windows Terminal, or Ghostty
- File conflict risk: two teammates editing the same file leads to overwrites, requires manual file ownership partitioning
- Lead behavior issues: the lead sometimes starts implementing tasks itself or shuts down before teammates finish

## 5. Comparison

| Tool | Key Difference vs Claude Agent Teams |
|------|--------------------------------------|
| oh-my-claudecode (OMC) | OMC wraps Agent Teams with a staged pipeline (plan->PRD->exec->verify->fix), 32 specialized agent definitions, magic keyword activation, and multi-AI routing to Gemini/Codex. Agent Teams is the raw coordination primitive that OMC builds on top of. |
| Ralph | Ralph is a single-agent bash loop that re-runs one prompt until completion. Agent Teams runs N agents in parallel with inter-agent communication. Ralph is sequential brute-force; Agent Teams is parallel coordination. |
| claude-flow | claude-flow is a full external platform with vector DBs, swarm topologies, and dozens of agents. Agent Teams is built into Claude Code with no external dependencies but has fewer orchestration features. |
| Subagents | Subagents run within a single session and only report results back to the caller. Agent Teams gives each worker its own context window and lets workers message each other directly. Subagents are cheaper; Agent Teams enables richer collaboration. |
| Git Worktrees | Manual parallel sessions using git worktrees give you full control but no automated coordination. Agent Teams adds shared task lists, messaging, and automatic dependency resolution on top of parallel sessions. |
| GasTown | GasTown uses a Mayor/Polecat/Gopher architecture with cost tracking. Agent Teams uses a simpler lead/teammate model with shared task lists but no built-in cost management. |

## 6. Why is it unique?

Claude Agent Teams is the first and only first-party multi-agent coordination feature built directly into Claude Code by Anthropic. Every other multi-agent approach (OMC, claude-flow, GasTown, Ralph) is a community tool, plugin, or external framework. Agent Teams is part of the Claude Code binary itself.

The key architectural differentiator is inter-agent communication. Subagents (the prior art in Claude Code) are fire-and-forget workers that report results back. Agent Teams introduces peer-to-peer messaging, shared task lists with dependency tracking, and self-coordination where teammates autonomously claim and complete work. This enables patterns like competing hypothesis investigation (teammates debate and disprove each other's theories) and parallel code review (each reviewer applies a different lens to the same PR) that are impossible with subagents.

The delegate mode is also distinctive: it enforces a clean separation between coordination and implementation by restricting the lead to orchestration-only tools, solving the common problem in AI agent systems where the orchestrator starts doing the work itself.

## 7. Simple Usage

Enable agent teams:

```json
// ~/.claude/settings.json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Start a team with natural language:

```
claude

> Create an agent team to refactor the auth module. Spawn three teammates:
  - One for the JWT token handler at src/auth/jwt.ts
  - One for session management at src/auth/session.ts
  - One for writing integration tests in tests/auth/
  Use Sonnet for each teammate.
```

Parallel code review:

```
> Create an agent team to review PR #142. Spawn three reviewers:
  - One focused on security implications
  - One checking performance impact
  - One validating test coverage
  Have them each review and report findings.
```

Competing hypothesis debugging:

```
> Users report the app exits after one message instead of staying connected.
  Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
  each other to try to disprove each other's theories, like a scientific
  debate. Update the findings doc with whatever consensus emerges.
```

Force display mode:

```bash
claude --teammate-mode in-process
```

Navigate teammates in-process mode:
- Shift+Up/Down: select a teammate
- Enter: view a teammate's session
- Escape: interrupt their current turn
- Ctrl+T: toggle the task list
