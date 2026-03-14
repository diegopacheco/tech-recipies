# AgentKit

There are two distinct projects named "AgentKit". This document covers both.

---

## 1. Inngest AgentKit

### What It Is

Inngest AgentKit is a TypeScript framework for building multi-agent networks with deterministic routing and MCP (Model Context Protocol) tooling. Built by Inngest, it enables networks of AI agents that collaborate, share state, and route tasks using code-based or LLM-based routing strategies.

- Repository: [https://github.com/inngest/agent-kit](https://github.com/inngest/agent-kit)
- Docs: [https://agentkit.inngest.com/overview](https://agentkit.inngest.com/overview)
- Language: TypeScript
- License: Apache 2.0

### How It Works

Five core concepts:

- **Agents** - LLM calls with prompts, tools, and MCP servers
- **Networks** - Container for agents sharing state and message history
- **State** - Typed key-value store shared between all agents in a network
- **Routers** - Orchestration layer (code-based or LLM-based) deciding which agent runs next
- **Tracing** - Built-in debugging via Inngest Dev Server

Execution flow:
1. Network receives input prompt
2. Router evaluates state and history
3. Router selects next agent
4. Agent executes, tools update shared state
5. Router evaluates again or terminates

### Main Features

- Deterministic state-based routing
- Code-based routing (full programmatic control)
- Agent-based routing (supervisor pattern with LLM)
- First-class MCP server integration
- Multi-model support (Anthropic, OpenAI, etc.)
- Typed shared state machine
- Lifecycle callbacks
- Fault tolerance with Inngest orchestration
- Human-in-the-loop via `waitForEvent()`
- Built-in dev server with tracing
- `maxIter` safety for runaway loops

### Code Usage

```typescript
import { anthropic, createAgent, createNetwork, createTool } from "@inngest/agent-kit";
import { z } from "zod";

const analysisAgent = createAgent({
  name: "analysis_agent",
  system: "You are an expert at analyzing code",
  tools: [saveSuggestions],
});

const docAgent = createAgent({
  name: "doc_agent",
  system: "You are an expert at writing documentation",
  tools: [saveSuggestions],
});

const network = createNetwork({
  name: "code-assistant",
  agents: [analysisAgent, docAgent],
  router: ({ network }) => {
    if (!network?.state.kv.has("plan")) return analysisAgent;
    return undefined;
  },
  defaultModel: anthropic({
    model: "claude-3-5-sonnet-latest",
    defaultParameters: { max_tokens: 4096 },
  }),
});
```

### Pros / Cons

**Pros**: Deterministic routing, state-based architecture, MCP support, built-in tracing, TypeScript-native, fault-tolerant with Inngest

**Cons**: TypeScript only, pre-1.0, coupled with Inngest ecosystem, smaller community, requires `inngest` peer dependency

---

## 2. Coinbase AgentKit

### What It Is

Coinbase AgentKit gives AI agents a crypto wallet and onchain interactions. Framework-agnostic and wallet-agnostic, it enables blockchain transactions, wallet management, DeFi interactions, and stablecoin payments.

- Repository: [https://github.com/coinbase/agentkit](https://github.com/coinbase/agentkit)
- Docs: [https://docs.cdp.coinbase.com/agentkit/docs/welcome](https://docs.cdp.coinbase.com/agentkit/docs/welcome)
- Languages: TypeScript, Python
- License: Apache 2.0

### How It Works

Provides action providers and wallet providers pluggable into any AI framework:

- **Action Providers** - 50+ onchain actions (transfer, swap, stake, deploy contracts)
- **Wallet Providers** - Coinbase CDP, Privy, Viem connectors
- **Framework Extensions** - LangChain, Vercel AI SDK, OpenAI Agents SDK, Autogen, Pydantic AI, MCP, Strands

### Main Features

- Wallet management across multiple providers
- 50+ onchain actions (TypeScript), 30+ (Python)
- Multi-chain: Base, Ethereum, Solana, all EVM/SVM networks
- Protocol integrations: Compound, Morpho, Moonwell, Farcaster, Jupiter, OpenSea, Zora
- Fee-free stablecoin payments
- Quickstart scaffolding: `npm create onchain-agent@latest`

### Pros / Cons

**Pros**: Comprehensive onchain actions, framework-agnostic, dual language (TS/Python), large protocol ecosystem, multi-chain, Coinbase-backed

**Cons**: Blockchain/crypto only, requires CDP API keys, financial risk inherent, experimental/AS-IS

---

## Alternatives

| Framework | Focus | Language |
|---|---|---|
| **LangGraph** | General agent orchestration | Python, TypeScript |
| **CrewAI** | Multi-agent collaboration | Python |
| **AutoGen** | Multi-agent conversations | Python |
| **Mastra** | TypeScript agent framework | TypeScript |
| **OpenAI Agents SDK** | Agent orchestration | Python |
| **Strands Agents** | General agent SDK | Python |
| **Pydantic AI** | Type-safe agents | Python |

## Link to Code

### Inngest AgentKit
- MCP Neon Agent: [https://github.com/inngest/agent-kit/tree/main/examples/mcp-neon-agent](https://github.com/inngest/agent-kit/tree/main/examples/mcp-neon-agent)
- Code Assistant: [https://github.com/inngest/agent-kit/blob/main/examples/code-assistant-agentic/src/index.ts](https://github.com/inngest/agent-kit/blob/main/examples/code-assistant-agentic/src/index.ts)
- SWE-bench Agent: [https://github.com/inngest/agent-kit/tree/main/examples/swebench](https://github.com/inngest/agent-kit/tree/main/examples/swebench)

### Coinbase AgentKit
- LangChain CDP Chatbot (TS): [https://github.com/coinbase/agentkit/tree/master/typescript/examples/langchain-cdp-chatbot](https://github.com/coinbase/agentkit/tree/master/typescript/examples/langchain-cdp-chatbot)
- LangChain CDP Chatbot (Python): [https://github.com/coinbase/agentkit/tree/master/python/examples/langchain-cdp-chatbot](https://github.com/coinbase/agentkit/tree/master/python/examples/langchain-cdp-chatbot)
