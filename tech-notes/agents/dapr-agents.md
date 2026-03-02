# Dapr Agents

## 1. What is it?

Dapr Agents is a developer framework for building durable and resilient AI agent systems powered by Large Language Models (LLMs). Built on top of the battle-tested Dapr (Distributed Application Runtime) project from Microsoft, it enables developers to create autonomous systems that have identity, reason through problems, make dynamic decisions, and collaborate seamlessly. Dapr Agents originated from Floki, a popular open-source project that extended Dapr for AI agent use cases. It was announced by the CNCF in March 2025. The key insight is that building an agentic system is fundamentally building a distributed system that uses LLMs, so all the classic cloud-native patterns still apply: async messaging, state coordination, API composition, service discovery, and resilience.

- Language: Python (primary), .NET (coming soon), Java/JavaScript/Go (planned)
- License: Apache 2.0
- GitHub: github.com/dapr/dapr-agents
- Governed by: CNCF (Cloud Native Computing Foundation)
- Install: `pip install dapr-agents`

## 2. How it Works?

Dapr Agents represents each agent as a virtual actor, a single unit of compute and state that is thread-safe and natively distributed. Agents combine LLM reasoning with tool integration, memory, and collaboration features. The framework provides two agent types: a standard `Agent` for synchronous conversational use with in-memory state, and a `DurableAgent` backed by Dapr Workflows for long-running, fault-tolerant execution with persistent state and automatic retry mechanisms. Every agent interaction with LLMs and tools is persisted into a durable state store that can recover and continue execution even after the agent restarts. For multi-agent systems, Dapr Agents supports two orchestration approaches: deterministic workflow-based orchestration (predefined sequences and decision points) and event-driven orchestration (async Pub/Sub messaging between specialized agents). Each agent gets a unique cryptographic identity used to authenticate interactions and enforce authorization across services.

## 3. Features

- Agent Identity: unique cryptographic identity per agent for authentication and authorization
- Durable Execution: Dapr Workflow engine persists every LLM and tool interaction into a durable state store with recovery after restarts
- Resilience: automatic retry policies, timeouts, circuit breakers, and durable retries backed by workflow state
- Scale and Efficiency: virtual actor model runs thousands of agents on-demand on a single core with double-digit millisecond boot times, scale-to-zero support
- LLM Integration: unified API via Dapr Conversation API (provider-agnostic), plus native clients for OpenAI, Hugging Face Hub, NVIDIA, and ElevenLabs
- Structured Outputs: JSON Schema and OpenAPI standard outputs via Function Calling
- Tool Calling: dynamic tool selection via `@tool` decorator with Pydantic schema validation
- MCP Support: built-in Model Context Protocol support with stdio, SSE, and streamable HTTP transports
- Memory: in-memory lists, vector databases (semantic search), and Dapr state stores (28+ providers) for persistent memory
- Multi-Agent Orchestration: workflow-based (deterministic) and event-driven (Pub/Sub) orchestration with central orchestrator
- Kubernetes-Native: deploy and manage agents in Kubernetes environments natively
- Observability: distributed tracing, metrics, and logging via OpenTelemetry and Prometheus
- Security: mTLS encryption, access control, secrets management for agent communication
- Data Integration: connect to 50+ enterprise data sources (SQL, NoSQL, documents, PDFs)
- Agent Runner: expose agents over HTTP or subscribe to PubSub for headless/long-running tasks
- Platform-Ready: access scopes and declarative resources for platform team integration

## 4. Pros

- Built on Dapr: inherits a battle-tested distributed systems runtime used in production at scale by large enterprises
- True durability: if a tool call fails mid-workflow, the system resumes without losing context or restarting (unlike most agent frameworks)
- Virtual actor model: thousands of agents on a single core, double-digit ms boot times, scale-to-zero
- Enterprise-grade security out of the box: mTLS, cryptographic agent identity, secrets management, PII obfuscation
- Vendor-neutral and CNCF governed: no lock-in, runs on any cloud or on-prem
- Kubernetes-native: first-class K8s deployment and management
- Event-driven multi-agent: Pub/Sub async messaging enables independent scaling, service isolation, and parallel processing
- 50+ data source connectors: SQL, NoSQL, documents without code changes
- 28+ state store providers for persistent memory
- Observability built-in: OpenTelemetry tracing, Prometheus metrics, structured logging
- Microservices teams can reuse existing Dapr infrastructure for AI agents without duplicating patterns
- Circuit breakers, retries, timeouts as first-class primitives (not bolted on)

## 5. Cons

- Learning curve: requires understanding the Dapr sidecar model, virtual actors, and distributed systems concepts before building agents
- Infrastructure overhead: requires running the Dapr runtime/sidecar alongside your agents, adding operational complexity
- Python-only today: .NET, Java, JS, Go support is planned but not yet available
- Smaller AI-specific community: fewer tutorials and agent-focused resources compared to LangChain or CrewAI
- Less AI-native abstractions: does not include built-in RAG pipelines, eval frameworks, or prompt optimization (unlike LangChain, Mastra, or DSPy)
- No visual debugging/studio tool: no equivalent to Mastra Studio or LangSmith for interactive agent debugging
- Heavier for simple use cases: the distributed systems machinery is overkill for single-agent prototypes
- LLM provider support is narrower: native clients only for OpenAI, HuggingFace, NVIDIA, ElevenLabs (vs 40+ in Mastra or 100+ via LiteLLM)
- Dapr Agents is newer (March 2025): API surface is still evolving
- No A2A protocol support yet

## 6. Comparison

| Aspect | Dapr Agents | Mastra | CrewAI | Strands Agents | LangChain/LangGraph |
|---|---|---|---|---|---|
| Language | Python (.NET soon) | TypeScript | Python | Python, TS | Python, JS |
| Architecture | Virtual actors + workflows + Pub/Sub | Agent loop + graph workflows | Role-based crews | Model-driven (LLM decides) | Graph-based DAGs |
| Distributed | Native (Dapr sidecar, K8s) | No (single process) | No (single process) | Via AWS infra | No (single process) |
| Durability | First-class (workflow state persistence) | Suspend/resume via storage | Limited | Via AWS Lambda | LangGraph checkpoints |
| Multi-Agent | Workflow + event-driven Pub/Sub | Basic (workflow-based) | Crew hierarchies, delegation | Graph, Swarm, Workflow, A2A | LangGraph nodes/edges |
| MCP Support | Built-in (stdio, SSE, HTTP) | Yes | Limited | Native, first-class | Via integration |
| Security | mTLS, crypto identity, secrets, PII | Basic | Basic | IAM-based | Basic |
| Observability | OpenTelemetry + Prometheus | OpenTelemetry | Limited | OpenTelemetry | LangSmith |
| Scale | Virtual actors, scale-to-zero, K8s-native | Serverless deploy | Single process | AWS Lambda/EKS | Single process |
| Ease of Use | Moderate (Dapr knowledge required) | Very high | High | Very high | Moderate to steep |
| Maturity | March 2025 | v1 released 2025 | Early 2024 | May 2025 | Established since 2022 |
| Best For | Enterprise distributed systems, K8s teams | TS/JS web apps, fast prototyping | Role-based team collaboration | Fast agent dev, AWS teams | Complex stateful workflows |

Dapr Agents is unique because it does not reinvent distributed systems patterns. Instead, it brings AI agents into the existing Dapr ecosystem where state management, Pub/Sub, service invocation, and resilience are already solved. This makes it ideal for teams that already run Dapr or Kubernetes and want to add agentic capabilities without duplicating infrastructure.

## 7. Who is Using It?

Dapr (the runtime) is used in production by:
- ZEISS: actor framework for managing order lifecycle in a global-scale production system on Azure
- HDFC Bank: transaction rate limiting, reducing UPI timeout rates
- FICO: complex event-driven systems
- Avelo Airlines: cloud-first, event-driven platform for scalability and agility
- Man Group: modernized trading platform running on-prem VMs
- Grafana Security: vulnerability scanning
- Watts Water Technologies: production Dapr deployment
- Tempestive: tracking billions of IoT messages with Dapr and Kubernetes
- Legentic: Python and FastAPI on AWS with Dapr
- Diagrid: commercial enterprise platform built on Dapr for workflow and agentic AI

Dapr Agents (the AI agent layer) is newer (March 2025) and adoption is growing. Organizations are using phased strategies: Dapr Agents for production customer-facing applications while experimenting with other frameworks for internal tooling.
