# claude-flow

## 1. What is it?

claude-flow is an open-source multi-agent orchestration platform built for Claude Code, created by Reuven Cohen (GitHub: ruvnet). Distributed as an npm package and CLI tool, it transforms Claude Code from a single AI assistant into a coordinated multi-agent platform. It enables deployment of 60+ specialized agents in swarms, backed by shared memory, consensus mechanisms, and continuous learning. It uses MCP (Model Context Protocol) for native Claude Code integration. Currently in alpha (v3), also published under the name "ruflo".

- GitHub: github.com/ruvnet/claude-flow (~12.9k stars)
- npm: npmjs.com/package/claude-flow
- Website: claude-flow.ruv.io

## 2. Main Features

- 60+ specialized agents organized across 8 categories (coding, research, review, security, etc.)
- 6 swarm topologies for coordinating agents (hierarchical, mesh, pipeline, etc.)
- Hive Mind system with queen-led hierarchical coordination where strategic queen agents direct specialized workers
- SONA self-learning -- learns from every task execution and prevents catastrophic forgetting of successful patterns
- RuVector -- built-in vector database for persistent memory and retrieval
- WASM execution engine -- 352x faster execution for certain transforms, can skip the LLM entirely for simple code transforms
- Intelligent 3-tier model routing that can save up to 75% on API costs by routing requests to the cheapest capable handler
- Dual-mode orchestration -- runs Claude Code and OpenAI Codex workers in parallel with shared memory
- Agent Teams integration -- spawns and coordinates multiple Claude Code instances working in parallel
- 13 GitHub-specialized agents for repository management, code review, and release coordination
- SQLite-based persistent memory so agents retain context across sessions
- Plugin system with domain-specific plugins (healthcare, finance, legal, code intelligence)
- Can run fully offline using local models and RuVector-backed retrieval

## 3. Pros

- Comprehensive scope covering orchestration, memory, routing, learning, and execution in a single platform
- Large community with ~12.9k GitHub stars and reportedly ~500k downloads
- Active development with frequent releases
- Native Claude Code and MCP protocol support
- Cost optimization through intelligent model routing (claims up to 75% savings)
- Self-learning capabilities that improve over time without manual configuration
- Supports offline/local model execution, reducing dependency on API calls
- Extensible plugin ecosystem for domain-specific use cases
- Dual-mode support (Claude + Codex) for cross-platform orchestration

## 4. Cons

- Alpha status -- expect breaking changes, instability, and incomplete features
- Architectural mismatch with official Claude Code hook documentation -- hook implementation diverges from official docs
- Missing advanced hook functionality -- lacks support for documented control-flow mechanisms like JSON output for approving/blocking tool usage
- Scaling performance issues with vector search and memory systems at scale
- Complexity -- 60+ agents, swarm topologies, queen/worker hierarchies, WASM, vector DBs, and plugins create a steep learning curve
- Marketing-heavy claims -- self-described as "Ranked #1" without clear independent verification
- Rebranding confusion -- also published under the name "ruflo"
- Missing critical hook features -- prompt validation, security, and context injection hooks are not implemented
- Heavy dependency footprint -- pulls in WASM runtimes, vector databases, SQLite, and more

## 5. Comparison

| Tool | Key Difference vs claude-flow |
|------|-------------------------------|
| BMAD | BMAD is a development methodology, not a runtime orchestration platform. It uses document-based handoffs. claude-flow is a runtime engine that manages agent swarms programmatically. |
| Ralph | Ralph is radically simple -- a loop script that reruns Claude Code. claude-flow is the opposite: a full platform with dozens of agents, vector DBs, and swarm topologies. |
| SuperClaude | SuperClaude agents are context configurations, not runtime processes. SuperClaude is lightweight (just config files); claude-flow is heavyweight (runtime engine, DBs, WASM). |
| ContinuousClaude | ContinuousClaude is focused on GitHub PR automation or context management. claude-flow manages multiple concurrent agents with swarm intelligence. |
| GasTown | Both do multi-agent orchestration. GasTown uses git-backed hooks (simpler); claude-flow uses SQLite + vector DB (heavier). claude-flow has more features but more complexity. A GasTown Bridge plugin exists. |
| GetShitDone | GSD is focused on context engineering and preventing context rot. claude-flow focuses on agent coordination and swarm intelligence. GSD is more practical/minimal. |

## 6. Why is it unique?

claude-flow is the only Claude Code tool that combines swarm intelligence with topology control (hierarchical, mesh, pipeline), self-learning neural capabilities (SONA), a WASM execution layer that can bypass the LLM entirely for deterministic transforms at 352x speed, dual-mode orchestration running Claude Code and OpenAI Codex in parallel with shared memory, and a built-in vector database (RuVector) for persistent semantic memory. Most other tools solve one problem well; claude-flow attempts to be a comprehensive platform handling orchestration, memory, learning, execution, and cost optimization all at once.

## 7. Simple Usage

```bash
npx claude-flow@v3alpha init

npx claude-flow@v3alpha daemon start

npx claude-flow@v3alpha agent spawn -t coder --name my-coder

npx claude-flow@v3alpha swarm init --topology hierarchical --max-agents 8

npx claude-flow@v3alpha orchestrate "Build a REST API with authentication"
```

Or with the wizard for guided setup:

```bash
npx claude-flow@v3alpha init --wizard
```
