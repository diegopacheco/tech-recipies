# Mastra

## 1. What is it?

Mastra is an open-source TypeScript framework for building AI-powered applications and agents. It was created by the team behind Gatsby (Abhi Aiyer, Sam Bhagwat, and Shane Thomas) and is backed by Y Combinator with a $13M seed round. Mastra is purpose-built for the TypeScript/Node.js ecosystem, integrating with React, Next.js, and Node, or deployable as a standalone server. It is built on top of Vercel's AI SDK and provides a complete, opinionated toolkit for building, tuning, and scaling AI agents and workflows.

- Language: TypeScript/JavaScript
- License: Open Source (Apache 2.0 / Elastic License)
- GitHub: github.com/mastra-ai/mastra (21,600+ stars, 1,600+ forks)
- Install: `npm create mastra@latest`
- NPM Downloads: 220k+ weekly

## 2. How it Works?

Mastra follows an agent-loop architecture where agents use LLMs and tools to solve open-ended tasks. An agent reasons about goals, decides which tools to use, calls them, incorporates results, and iterates until it reaches a final answer or a stopping condition is met. For deterministic multi-step processes, Mastra provides a graph-based workflow engine with explicit control flow using `.then()`, `.branch()`, and `.parallel()` syntax. All model interactions go through a unified model routing layer that connects to 40+ providers (OpenAI, Anthropic, Gemini, etc.) through one standard interface. Execution state is persisted in storage, enabling suspend/resume patterns for human-in-the-loop workflows.

## 3. Features

- Model routing: connect to 40+ providers (OpenAI, Anthropic, Gemini, and more) through one interface
- Agents: autonomous agents that reason, plan, use tools, and iterate to completion
- Graph-based workflows: orchestrate multi-step processes with `.then()`, `.branch()`, `.parallel()`
- Human-in-the-loop: suspend/resume agents or workflows awaiting user input or approval
- Memory: conversation history, working memory, and semantic memory for coherent agent behavior
- RAG: built-in retrieval-augmented generation with vector store support (Pinecone, pgvector)
- Evals: built-in scorers for measuring and refining agent quality
- Observability: OpenTelemetry tracing built-in
- Mastra Studio: local visual playground for debugging agents and workflows in real-time
- MCP support: Model Context Protocol integration for tool servers
- Auto-generated OpenAPI docs and Swagger interface for every agent
- Integrations: React, Next.js, Node.js, Vercel AI SDK UI, CopilotKit
- Deploy: Vercel, Cloudflare, Netlify, or any Node.js runtime in one command
- Structured output: typed, schema-validated responses via Zod
- Tools: define custom tools as TypeScript functions with schema validation

## 4. Pros

- TypeScript-native: first-class DX for the largest web developer ecosystem
- Very fast to prototype: reported 40% reduction in agent build time, 65% of users launch agents in under a week
- Opinionated and batteries-included: agents, workflows, RAG, evals, memory, observability all in one package
- Visual debugging: Mastra Studio lets you watch agents think and debug workflows step by step without deploying
- Built on Vercel AI SDK: inherits a solid foundation and streaming primitives
- Graph-based workflows with intuitive chaining syntax (`.then()`, `.branch()`, `.parallel()`)
- Human-in-the-loop with persistent execution state and indefinite pause/resume
- Strong community: 21k+ GitHub stars, 220k+ weekly npm downloads
- Production-proven at large companies (SoftBank, Adobe, Marsh McLennan, PayPal, Replit)
- Y Combinator backed with $13M seed funding
- From the Gatsby team: proven track record building developer tools at scale
- Auto-generated API docs and Swagger for every agent endpoint

## 5. Cons

- TypeScript/JavaScript only: no Python, Java, Rust, or Go support
- Opinionated: less flexibility compared to lower-level frameworks like LangGraph for custom orchestration patterns
- Limited multi-agent orchestration: not as mature as CrewAI or Claude Agent Teams for complex role-based team collaboration
- Tied to Vercel AI SDK: adds a dependency layer and couples you to that abstraction
- Younger ecosystem: fewer third-party tutorials and integrations compared to LangChain
- No native A2A protocol support (unlike Strands Agents)
- Vector store options are more limited compared to Spring AI or LangChain
- Mastra Studio is a local dev tool, not a production monitoring dashboard
- Node.js runtime constraints: not ideal for CPU-intensive workloads or low-latency edge scenarios
- Rapidly evolving API surface: breaking changes between versions as the framework matures

## 6. Comparison

| Aspect | Mastra | LangChain/LangGraph | CrewAI | Strands Agents | Spring AI |
|---|---|---|---|---|---|
| Language | TypeScript | Python, JS | Python | Python, TS | Java/JVM |
| Architecture | Agent loop + graph workflows | Graph-based DAGs | Role-based crews | Model-driven (LLM decides) | Spring Boot patterns |
| Ease of Use | Very high (plug and play) | Moderate to steep | High | Very high (3 lines) | Moderate |
| Multi-Agent | Basic (workflow-based) | LangGraph nodes/edges | Crew hierarchies, delegation | Graph, Swarm, Workflow, A2A | Orchestrator-Worker |
| MCP Support | Yes | Via integration | Limited | Native, first-class | Limited |
| RAG | Built-in | Built-in | Built-in | Via integrations | Built-in |
| Evals | Built-in scorers | LangSmith | Limited | Strands Evals (preview) | Limited |
| Visual Tooling | Mastra Studio | LangSmith | CrewAI Studio | None built-in | None built-in |
| Human-in-the-loop | Native suspend/resume | LangGraph interrupts | Limited | Limited | Limited |
| Deploy | Vercel, Cloudflare, Netlify | Any | Any | AWS Lambda, Fargate, EKS | Spring Boot containers |
| Maturity | v1 released 2025 | Established since 2022 | Released early 2024 | Released May 2025 | GA 2024 |
| Best For | TS/JS teams, web apps, fast prototyping | Complex stateful workflows | Role-based team collaboration | Fast agent dev, AWS teams | Java/Spring enterprise |

Mastra is more opinionated and batteries-included than LangGraph (which gives you primitives to build with), but less flexible for exotic orchestration patterns. Compared to CrewAI, Mastra is stronger on workflows and single-agent tooling but weaker on multi-agent team coordination. Compared to Strands, Mastra targets the web/JS ecosystem while Strands targets the AWS/Python ecosystem.

## 7. Who is Using It?

- SoftBank: running Mastra agents in production
- Adobe: production agent deployments
- Marsh McLennan: deployed agentic search tool to 75,000 employees
- PayPal: production use
- Replit: Agent 3 builds Mastra agents at scale
- Elastic: production or public implementation
- Docker: production or public implementation
- WorkOS: production use
- Y Combinator portfolio companies: automating support, building CAD diagrams, web scraping, medical transcriptions, financial document generation, and code generation products
