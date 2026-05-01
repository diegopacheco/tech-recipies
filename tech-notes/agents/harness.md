# Harness

## What is a Harness?

In the context of AI agents and LLMs, a harness is the runtime scaffolding that wraps a model and turns it into an agent. The model itself only produces tokens; the harness is what gives those tokens consequences in the real world. It is the loop, the tool runner, the context manager, the permission gate, and the I/O bridge that sits between the user, the model, and the system the agent operates on.

Claude Code, Codex CLI, Cursor, Aider, and OpenAI's Agents SDK are all harnesses. Two harnesses pointed at the same model can behave very differently because the harness decides what the model can see, what it can do, and how its output is interpreted.

## How it Works

A harness runs an agent loop. On each turn it:

1. Builds a prompt from the system instructions, the conversation history, tool results, and any injected context (files, memory, environment data).
2. Sends the prompt to the model and receives a response containing text and/or tool calls.
3. Validates each tool call against the configured permissions.
4. Executes the approved tool calls (shell commands, file edits, web fetches, MCP servers, sub-agents).
5. Feeds the tool results back into the conversation and loops until the model stops calling tools or the user interrupts.

Around that core loop the harness manages:

- **Context window** - truncation, compaction, summarization, prompt caching
- **Tools** - the catalog of callable functions and their schemas
- **Permissions** - allow/deny rules, prompts for approval, sandboxing
- **Hooks** - shell commands triggered on lifecycle events (PreToolUse, PostToolUse, Stop)
- **Memory** - persistent files like `CLAUDE.md`, `AGENTS.md`, or the user's memory directory
- **Sub-agents** - spawning isolated agent instances for delegated work
- **Output rendering** - terminal UI, diffs, streaming, markdown
- **Telemetry** - logs, traces, token accounting

## What a Harness Provides

| Concern | Role of the Harness |
|---|---|
| Tool execution | Runs Bash, Read, Edit, Write, WebFetch, MCP tools |
| Safety | Sandboxing, permission prompts, deny lists, hooks |
| Context | Loads CLAUDE.md, project files, git status, environment |
| Persistence | Memory files, session resumption, task lists |
| Orchestration | Sub-agents, background tasks, scheduled runs, worktrees |
| Integration | IDE plugins, MCP servers, GitHub, Slack |
| UX | Terminal rendering, slash commands, keybindings |

## Harness vs Model vs Agent

These three terms are often confused:

- **Model** - the LLM weights (e.g., `claude-opus-4-7`). Stateless, just maps tokens to tokens.
- **Harness** - the program around the model that runs the loop, executes tools, and manages state.
- **Agent** - the combination of a model plus a harness plus a task. The agent is what actually does work.

You can swap models inside the same harness, or run the same model in different harnesses, and get very different agents.

## Examples of Harnesses

- **Claude Code** - terminal-first harness for Claude with hooks, slash commands, sub-agents, MCP, and worktrees
- **Codex CLI** - OpenAI's terminal harness for their models
- **Cursor / Windsurf** - IDE-embedded harnesses
- **Aider** - git-aware terminal coding harness
- **Continue / Cline** - open-source IDE harnesses
- **OpenAI Agents SDK / Anthropic Agent SDK** - libraries for building your own harness
- **AutoGPT, LangGraph, CrewAI** - higher-level agent frameworks that are themselves harnesses

## Configuring a Harness

Most harnesses expose configuration through a settings file. For Claude Code that file is `~/.claude/settings.json` (global) or `.claude/settings.json` (project). Typical levers:

- **Permissions** - which tools and paths are auto-allowed or denied
- **Hooks** - shell scripts that run on tool events (the harness executes these, not the model)
- **Environment variables** - passed into tool calls
- **Model selection** - which model the loop calls
- **MCP servers** - external tool providers wired into the harness

Important: behaviors like "always run prettier after a write" or "block git push to main" cannot live in the model's memory or in CLAUDE.md - the model cannot reliably enforce them. They belong in the harness as hooks or permissions, because the harness is what actually runs.

## Why Harnesses Matter

The same model can feel brilliant or useless depending on the harness around it. A harness with strong tool integration, good context management, and the right permissions makes the model effective on real work. A weak harness wastes context, prompts for approval on everything, or fails to feed tool results back correctly, and the agent stalls.

When evaluating an AI coding assistant, you are mostly evaluating its harness. Token-for-token the underlying models are similar; the harness is where the product lives.

## Pros

- Decouples model choice from agent capabilities
- Centralizes safety controls (permissions, sandboxing, hooks)
- Enables persistence across sessions through memory and settings
- Makes tool ecosystems portable via MCP and similar protocols
- Lets teams enforce policy without retraining the model

## Cons

- Harness lock-in - settings, hooks, and memory rarely port between harnesses
- Debugging is harder because behavior depends on harness internals you do not see
- Different harnesses interpret the same model differently, so reproducibility suffers
- Updating the harness can change agent behavior even when the model is unchanged
- Misconfigured permissions or hooks can silently degrade the agent
