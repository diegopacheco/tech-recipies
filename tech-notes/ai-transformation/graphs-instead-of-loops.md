# Graphs Instead of Loops

## What is it?

**Graphs instead of loops**, also called **graph engineering**, is the emerging practice of designing an AI system as an explicit network of agents, deterministic code, tools, evaluators, human decisions, and durable state. Each unit is a **node**. Each allowed handoff, dependency, branch, retry, or approval is an **edge**. A runtime schedules ready nodes, carries state between them, records what happened, and stops when the graph reaches a terminal condition.

The phrase became a trend in July 2026 after Peter Steinberger asked: *"Are we still talking loops or did we shift to graphs yet?"* Hamel Husain followed with *"Loop Engineering Is Dead. Enter Graph Engineering."* No new model or framework launched with those posts. The label is new; the architecture is not. Workflow engines, state machines, actor systems, DAG schedulers, LangGraph, AutoGen, and multi-agent systems had already used nodes and edges for years.

The useful idea underneath the hype is real:

> A loop makes one agent keep working. A graph makes several bounded workers, checks, tools, and humans work as one governed system.

But **graphs do not replace loops**. A loop is a cycle, and a cycle is a valid path inside a directed graph. The practical architecture is usually a stable graph containing small, budgeted loops where iteration adds value.

This note uses **graph** to mean an execution or control-flow graph. It does not mean a knowledge graph, GraphRAG, a database graph, or a neural network computation graph.

## The trend

```
┌──────────────┬──────────────────────────────────────────────────────────┐
│ Date         │ What happened                                            │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Early 2024   │ LangGraph launches with state, nodes, edges, cycles,     │
│              │ checkpoints, and human interruption.                     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Dec 2024     │ Anthropic documents chaining, routing, parallelization,  │
│              │ orchestrator-workers, and evaluator-optimizer flows.     │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Jun 7, 2026  │ Loop engineering becomes the name for systems that keep  │
│              │ agents working toward a checked outcome.                 │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Jun–Jul 2026 │ Google ADK 2.0 ships a graph-based workflow runtime and  │
│              │ moves beyond fixed sequential, parallel, and loop forms. │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Jul 18, 2026 │ Steinberger's one-line question makes graph engineering  │
│              │ the next term in the agent-engineering vocabulary.       │
├──────────────┼──────────────────────────────────────────────────────────┤
│ Jul 18, 2026 │ Husain publishes the deliberately provocative obituary   │
│              │ for loop engineering.                                    │
└──────────────┴──────────────────────────────────────────────────────────┘
```

The sequence matters because it prevents a false history. Agent graphs were not invented in July 2026. The trend gave an existing coordination problem a memorable name at the moment more builders were hitting it.

## Where it sits in the stack

Each layer remains present inside the next one.

```
┌──────────────────────────────────────────────────────────────────────┐
│ GRAPH ENGINEERING                                                    │
│ Who runs, what may connect, what state crosses an edge, who can      │
│ approve, and how several loops converge on one outcome.              │
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐   │
│   │ LOOP ENGINEERING                                             │   │
│   │ How a bounded worker repeats, verifies, remembers, and stops.│   │
│   │                                                              │   │
│   │   ┌──────────────────────────────────────────────────────┐   │   │
│   │   │ HARNESS + CONTEXT                                    │   │   │
│   │   │ Tools, permissions, isolation, memory, and evidence. │   │   │
│   │   │                                                      │   │   │
│   │   │   PROMPT + MODEL                                     │   │   │
│   │   └──────────────────────────────────────────────────────┘   │   │
│   └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

A prompt shapes one model call. A harness controls one agent's environment. A loop controls repeated work toward one goal. A graph controls relationships among many processing units and their local loops.

## The category correction

The slogan "graphs instead of loops" is technically wrong but directionally useful.

```
Loop

    act ──► observe ──► verify
     ▲                    │
     └────── retry ───────┘

Graph

                         ┌──► specialist A ──┐
    start ──► route ─────┼──► specialist B ──┼──► join ──► verify ──► end
                         └──► policy check ──┘                 │
                                                               │ fail
                                                               ▼
                                                            revise
                                                               │
                                                               └────► verify
```

The second shape contains a loop between `verify` and `revise`. Its advantage is not the absence of repetition. Its advantage is that parallelism, authority, data movement, and failure paths are visible rather than hidden inside one model's conversation.

There are four graph views worth separating:

| View | Nodes represent | Edges represent |
|---|---|---|
| Execution graph | Agents, functions, tools, humans | Allowed next steps |
| Task graph | Units of work | Dependencies and readiness |
| Agent graph | Specialized roles | Delegation and communication |
| Artifact graph | Specs, code, tests, evidence, decisions | Provenance and derivation |

A production system may use all four, but collapsing them into one giant diagram makes ownership harder to reason about. AutoGen makes a similar distinction between the execution graph and the message graph: the order in which agents run is not necessarily the same as the context each agent receives.

## How it works

A graph-engineered system has seven load-bearing parts.

| Part | Responsibility |
|---|---|
| Nodes | Perform one bounded transformation or decision |
| Edges | Define dependencies, routes, retries, and escalation |
| State | Hold typed inputs, artifacts, evidence, budgets, and progress |
| Scheduler | Find ready nodes, enforce concurrency, and advance execution |
| Contracts | Validate what crosses each edge |
| Checkpoints | Persist progress so work can pause, resume, replay, or recover |
| Policy | Limit permissions, side effects, spend, and human approval |

The lifecycle is:

1. An event or user request starts the graph.
2. The runtime creates a run with an identity, budget, and initial state.
3. Entry nodes inspect or normalize the request.
4. Deterministic rules or a constrained router select the next edge.
5. Independent nodes run concurrently when their dependencies are satisfied.
6. Each node writes a structured result or artifact, not an unbounded transcript.
7. Join nodes wait for the required branches and reconcile their outputs.
8. Verifiers compare results against tests, policy, evidence, or human judgment.
9. Failed checks follow a bounded repair edge, a fallback edge, or an escalation edge.
10. The runtime checkpoints every meaningful transition and records the complete path.
11. A terminal node publishes the accepted outcome and execution receipt.

The strongest design keeps **orchestration deterministic and cognition selective**. Code should handle scheduling, schemas, budgets, permissions, retries, and irreversible actions. Models should handle interpretation, synthesis, planning under ambiguity, and other work that benefits from probabilistic reasoning.

## A concrete software graph

```
                                  ┌──► dependency analyst ──┐
                                  │                         │
issue ──► classify ──► plan ──────┼──► code worker ─────────┼──► integrate
                                  │                         │
                                  └──► test designer ───────┘       │
                                                                    ▼
                                                               run checks
                                                              ╱          ╲
                                                          pass            fail
                                                           │               │
                                                           ▼               ▼
                                                     security gate      repair loop
                                                      ╱        ╲           │
                                                  safe          risky       └──► run checks
                                                   │              │
                                                   ▼              ▼
                                                publish       human approval
                                                                  │
                                                                  ▼
                                                               publish
```

The graph states who may do what, which work can happen concurrently, what must join, which checks are mandatory, where retries return, and where a human owns the decision. Each worker may still run its own local act-observe-verify cycle.

## Loops vs. graphs

| Dimension | Loop engineering | Graph engineering |
|---|---|---|
| Primary unit | One recurring goal | A network of bounded units |
| Control flow | Repeat until stop | Sequence, branch, fan-out, join, cycle, interrupt |
| Coordination | Usually one orchestrator or conversation | Explicit topology and scheduler |
| State | Progress file or conversation state | Typed shared state plus per-node artifacts |
| Parallelism | Optional helpers around the loop | First-class dependency-based execution |
| Verification | Stop condition or checker | Multiple gates, vetoes, and independent anchors |
| Failure handling | Retry, stop, or escalate | Route, retry locally, compensate, fall back, or escalate |
| Permissions | Often attached to one agent | Scoped per node and edge |
| Observability | Run history and final result | Path, node state, edge decisions, joins, and lineage |
| Best fit | Bounded repetitive work | Multi-stage work with distinct owners and paths |
| Main risk | Drift or infinite repetition | Topology, state, and coordination complexity |

## When a loop is enough

Use one loop when:

- One agent can hold the relevant problem in focused context.
- Work is mainly sequential.
- There is one clear verifier and one clear stopping condition.
- Parallel work would not reduce the critical path.
- All steps need roughly the same tools and permissions.
- A failure can safely retry the whole unit.
- The result is cheap enough to regenerate.

Good loop-shaped work includes fixing one failing test, improving one document against a rubric, tuning one benchmark, triaging one queue, or polling one external condition.

Forcing these tasks into a graph adds state boundaries and orchestration code without adding useful control.

## When a graph earns its cost

Use a graph when:

- Distinct parts require different skills, models, tools, permissions, or owners.
- Independent branches can run concurrently.
- Some outputs must be joined before later work begins.
- Different outcomes require different next steps.
- A failed branch should retry without repeating successful branches.
- Long-running work must survive process restarts.
- Humans must approve specific transitions.
- Side effects need provenance, idempotency, or compensation.
- The system needs an auditable record of who produced and accepted each artifact.
- One conversation is becoming a hidden workflow language.

The smell is not merely "the task is complex." The smell is **coordination complexity**: several units must exchange state under different rules.

## Use cases

### Software delivery

Route a change through planning, implementation, test design, security review, integration, and release approval. Independent codebase analysis can fan out; checks can join; only the failing branch needs repair. This is where task graphs, worktree isolation, and artifact lineage reinforce each other.

### Deep research

A lead agent decomposes a question into independent search directions, workers gather evidence concurrently, a synthesis node merges claims, and a citation verifier rejects unsupported statements. Anthropic reported a 90.2% improvement over a single-agent baseline on its internal breadth-first research evaluation, but the result is specific to that system and workload rather than a universal multi-agent law.

### Customer support

A router selects billing, identity, safety, logistics, or technical specialists. Policy checks can run beside the specialist. Refunds or account changes cross a human approval edge while low-risk informational responses finish automatically. Lyft describes a router-based LangGraph system with specialized support agents, safety checks, state, and handoffs.

### Incident response

Monitoring starts the graph. Separate nodes inspect logs, metrics, deploy history, and dependency status. A join produces hypotheses; deterministic checks validate them; a remediation node may prepare a change, but production mutation requires policy and human authority. The graph makes partial failure and escalation explicit.

### Regulated document processing

Extraction, classification, policy lookup, risk scoring, citation checks, and approval can be isolated into nodes. Each edge carries structured evidence. A reviewer sees the source, transformation history, and policy decision rather than trusting one opaque final response.

### Data and retrieval systems

Queries can route among SQL, document retrieval, web research, and deterministic calculations. Parallel retrieval branches gather candidates, rankers and evidence gates filter them, and repair cycles handle invalid queries. Graph state makes it possible to resume after a human supplies missing information.

### Commerce and high-impact actions

Discovery and recommendation may be agentic, while budget validation, identity, fraud checks, authorization, and payment remain deterministic or approval-gated nodes. The graph gives each stage a narrow credential and creates a durable audit trail.

## Core patterns

### 1. Sequential pipeline

```
normalize ──► analyze ──► transform ──► verify
```

Use it when order is fixed and each node produces a clean input for the next. The risk is needless fragmentation: a long chain of tiny model calls adds latency and context loss.

### 2. Router and specialists

```
             ┌──► billing
request ──► route ──► identity
             └──► technical
```

Use it when categories need different instructions, tools, or permissions. Prefer deterministic routing for stable rules and a model router only when classification genuinely requires interpretation.

### 3. Fan-out and fan-in

```
           ┌──► worker A ──┐
input ─────┼──► worker B ──┼──► gather
           └──► worker C ──┘
```

Use it for independent research directions, checks, or partitions. Give each branch isolated state and make join semantics explicit: wait for all, a quorum, the first valid result, or a deadline.

### 4. Orchestrator and workers

```
goal ──► planner ──► dynamic work graph ──► workers ──► synthesizer
```

Use it when the subtasks cannot be known before the request arrives. The orchestrator may propose a task graph, but code should validate its schema, maximum width, depth, permissions, and budget before execution.

### 5. Maker and checker

```
make ──► check ──► accept
  ▲        │
  └─ revise┘
```

Use it when feedback can measurably improve the artifact. The checking node should be independent and anchored to tests, sources, or a rubric. Cap iterations and stop on no progress.

### 6. Approval gate

```
prepare ──► policy ──► low risk ──► execute
                       high risk ──► human ──► execute or reject
```

Use it for money, production changes, external communication, access control, or destructive actions. Approval is a durable state transition, not a chat message that can be lost.

### 7. Fallback and circuit breaker

```
primary ──► success
   │
 failure ──► cheaper path, safer path, cached result, or human
```

Use it when a node depends on a model, service, or tool that may fail. After a bounded number of attempts, open the circuit and route elsewhere instead of spinning.

### 8. Hierarchical subgraph

```
portfolio graph ──► project graph ──► bounded worker loop
```

Use it when one graph would otherwise become unreadable. Each subgraph has a clear contract, budget, owner, and terminal result. Avoid recursive delegation without depth limits.

### 9. Compensating action

```
reserve ──► charge ──► fulfill
   ▲          │ fail
   └── release or reverse
```

Use it when an earlier side effect cannot be rolled back by restoring memory. Every external action needs an idempotency key and a defined repair or compensation path.

### 10. Blackboard or artifact graph

Workers communicate by reading and writing versioned artifacts rather than sharing one growing conversation. This reduces context contamination, preserves provenance, and lets later nodes load only what they need.

## Practices that work

- **Deterministic shell, probabilistic islands.** Keep routing, permissions, budgets, schemas, and irreversible effects in code. Put model reasoning only in nodes that benefit from it.
- **Typed edge contracts.** Every node declares accepted input, produced output, errors, and evidence. Reject malformed handoffs before the next model sees them.
- **Artifacts over transcripts.** Pass a brief, test result, patch, citation set, or structured decision. Do not forward the complete history to every node.
- **Bound every cycle.** Set iteration, time, token, spend, and no-progress limits. A backward edge without a guard is an open invoice.
- **Make nodes idempotent.** Checkpoints and retries can re-run work. Use idempotency keys and separate pure computation from side effects.
- **Checkpoint at stable boundaries.** Persist after accepted artifacts and before high-impact actions. Recovery should resume from the last trusted state.
- **Scope authority per node.** A researcher does not need deployment rights. A reviewer does not need write access. A publisher should receive only an approved artifact.
- **Use independent anchors.** Tests, schemas, source citations, production metrics, and humans keep a graph of mutually agreeing agents from producing organized nonsense.
- **Trace paths, not only calls.** Record node inputs, outputs, model and tool versions, edge decisions, retries, cost, latency, and who approved the result.
- **Test the topology.** Verify reachable nodes, terminal paths, join behavior, retry caps, denial paths, partial failures, and state migrations.
- **Version graph and state together.** A paused run may resume after the topology changes. Define compatibility rules and migrations before deployment.
- **Keep the graph boring.** Start with one path. Add a node or edge only when a measured failure, permission boundary, or latency opportunity justifies it.

## Anti-patterns

- **Graph theater.** Drawing many agents without explicit contracts, state, or execution semantics.
- **Agent per job title.** Recreating an organization chart even when one focused worker could do the work.
- **LLM everywhere.** Paying a model to route fixed categories, count retries, enforce policy, or validate JSON.
- **Shared transcript as state.** Giving every node the entire conversation and calling it coordination.
- **Dynamic graph without a governor.** Allowing a planner to create unlimited nodes, edges, recursion, or spend.
- **Checker monoculture.** Several agents using the same model, context, and evidence tend to reproduce the same error.
- **Unspecified joins.** Parallel branches finish, but the system has no rule for missing, late, conflicting, or low-confidence results.
- **Replay without idempotency.** Resuming from a checkpoint repeats an email, payment, ticket update, or deployment.
- **One global credential.** Every node inherits the orchestrator's full authority.
- **Topology as correctness.** A visible graph makes failures inspectable; it does not make outputs true.

## Pros

- **Explicit control flow.** Branches, retries, approvals, and termination are visible and testable.
- **Real parallelism.** Independent work can run concurrently, reducing wall-clock time.
- **Focused context.** Each node sees only the instructions, tools, and state it needs.
- **Fault isolation.** A failed branch can retry or fall back without discarding successful work.
- **Durability.** Checkpoints support long-running work, pauses, process restarts, and human response time.
- **Governance.** Permissions and approval requirements can be attached to exact transitions.
- **Model flexibility.** Different nodes can use different models, deterministic code, or no model at all.
- **Auditability.** The run produces lineage from request through artifacts, decisions, and acceptance.
- **Local evaluation.** Teams can score and improve one weak node without retesting an opaque monolith blindly.
- **Reusable topology.** Proven subgraphs can become shared operational capabilities.

## Cons

- **More system to build.** State schemas, schedulers, joins, retries, migrations, and observability become product code.
- **Graph explosion.** Paths multiply rapidly as branches and recovery edges accumulate.
- **Coordination overhead.** Handoffs can lose nuance, duplicate work, and increase token use.
- **Harder testing.** Node quality and path quality must be tested across probabilistic outputs.
- **State conflicts.** Parallel branches may race or produce incompatible updates.
- **Latency barriers.** Fan-in can wait on the slowest branch; superstep runtimes may block a fast path behind unrelated work.
- **Higher cost.** More agents, verifiers, and retries mean more model calls.
- **False confidence.** Several agents can agree on the same unsupported claim.
- **Versioning risk.** Topology or schema changes can strand paused runs.
- **Framework gravity.** A graph runtime can become a new platform dependency and constrain simpler code.
- **Human bottleneck remains.** Parallel output can grow faster than people can review and own it.

## Who is doing it

### LangChain / LangGraph

LangGraph made state, nodes, edges, conditional routes, parallel supersteps, cycles, persistence, interrupts, and replay first-class agent-runtime concepts beginning in 2024. Its public material names Uber, LinkedIn, Klarna, Elastic, Replit, Lyft, PagerDuty, and others as production users. Uber used a network of agents for unit-test generation and migrations; LinkedIn used a hierarchical agent system; Klarna used it for customer support; Lyft described router-based support orchestration.

### Google ADK 2.0

Google's June–July 2026 ADK 2.0 release is the clearest direct signal behind the trend. Google says fixed sequential, parallel, and loop templates have been superseded in Python and Go by more flexible graph and dynamic workflows. Nodes may be agents, functions, tools, or human input. The runtime supports routes, fan-out, joins, cycles, persistence, pauses, and resume. Google explicitly argues that deterministic code should own orchestration while models handle reasoning nodes.

### Microsoft Agent Framework

Microsoft Agent Framework workflows connect executors with edges in a directed graph. Its runtime uses a modified Pregel bulk-synchronous model: ready executors run concurrently within a superstep, a barrier waits for completion, messages are routed, and the next superstep begins. The framework validates type compatibility, reachability, executor binding, and edges.

### Microsoft AutoGen

AutoGen's GraphFlow provides directed-graph execution across agents with sequential, parallel, conditional, and cyclic behavior. It also separates execution order from message filtering, which is important for context control. GraphFlow is still marked experimental, while AutoGen Core supports broader event-driven and actor-style agent networks.

### Anthropic

Anthropic does not market a graph-engineering product, but its documented workflows map directly onto graph patterns: chaining, routing, parallelization, orchestrator-workers, and evaluator-optimizer. Its multi-agent research system uses a lead agent to create and coordinate parallel subagents, then synthesize their results. Anthropic's guidance remains conservative: begin with the simplest design that works because autonomy trades additional cost and latency for performance.

### OpenAI Agents SDK

OpenAI's SDK provides agent loops, agents-as-tools, handoffs, guardrails, sessions, and tracing. It supports two orchestration styles: a manager retains control while calling specialists, or peer agents hand control to one another. It does not require a graph-specific language; developers can express the control graph in ordinary Python and mix model-decided handoffs with code-decided orchestration.

### Existing workflow systems

Airflow, state-machine libraries, durable workflow engines, build systems, and CI pipelines already model work as tasks and dependencies. Agent graph runtimes extend that old control-plane idea by allowing selected nodes to interpret ambiguous input and choose among constrained actions. The novelty is not the graph. It is putting probabilistic workers inside a durable, inspectable workflow.

## The decision rule

```
One focused goal?
    │
    ├── yes ──► One clear path and verifier?
    │              │
    │              ├── yes ──► Use a bounded loop.
    │              └── no  ──► Add the smallest useful branch or gate.
    │
    └── no ───► Distinct owners, parallel work, or authority boundaries?
                   │
                   ├── yes ──► Use a graph with bounded loops in nodes.
                   └── no  ──► Decompose the goal before choosing a runtime.
```

The progression should be earned:

1. One model call.
2. One tool-using agent.
3. One verified loop.
4. One explicit branch or approval gate.
5. A small graph.
6. Subgraphs only when independent ownership or scale requires them.

## What this means

Graph engineering is a useful name for **the control plane above loop engineering**. Loop engineering asks how one agent keeps working and knows when to stop. Graph engineering asks how many bounded workers, deterministic checks, tools, and humans coordinate without hiding the whole workflow inside an orchestrator's prompt.

The strongest version is not a swarm of agents inventing an organization as they go. It is a **deterministic skeleton with probabilistic nodes**: typed state, explicit edges, isolated authority, durable checkpoints, bounded cycles, independent evidence, and human ownership at consequential transitions.

The shift is therefore from:

```
one model owns the process
              │
              ▼
software owns the process; models perform selected judgments
```

Loops are not dead. They become local. The graph owns coordination; each loop owns convergence within a narrow boundary. That containment is the real architectural improvement.

## Sources

### Origin and debate

- Peter Steinberger — "Are we still talking loops or did we shift to graphs yet?": https://x.com/steipete/status/2078277297791189132
- Hamel Husain — "Loop Engineering Is Dead. Enter Graph Engineering": https://x.com/HamelHusain/article/2078346425621237935
- Addy Osmani — Loop Engineering: https://addyosmani.com/blog/loop-engineering/
- SmartScope — Graph Engineering vs. Loop Engineering: https://smartscope.blog/en/blog/graph-engineering-loop-engineering-logic-review/
- Turing Post — Is Graph Engineering Real?: https://www.turingpost.com/p/is-graph-engineering-real-why-everyone-is-talking-about-it
- From Agent Loops to Structured Graphs: https://arxiv.org/abs/2604.11378

### Frameworks and architecture

- Anthropic — Building Effective AI Agents: https://www.anthropic.com/engineering/building-effective-agents
- Anthropic — Multi-Agent Research System: https://www.anthropic.com/engineering/multi-agent-research-system
- LangGraph — Graph API: https://docs.langchain.com/oss/python/langgraph/graph-api
- LangGraph — Persistence: https://docs.langchain.com/oss/python/langgraph/persistence
- LangGraph — Interrupts: https://docs.langchain.com/oss/python/langgraph/interrupts
- LangChain — Building LangGraph from First Principles: https://www.langchain.com/blog/building-langgraph
- Google ADK — Graph-Based Agent Workflows: https://adk.dev/graphs/
- Google — Why We Built ADK 2.0: https://developers.googleblog.com/why-we-built-adk-20/
- Google — ADK Go 2.0 Graph Workflow Engine: https://developers.googleblog.com/announcing-adk-go-20/
- Google ADK — Multi-Agent Workflow Patterns: https://adk.dev/workflows/patterns/
- Microsoft Agent Framework — Workflows: https://learn.microsoft.com/en-us/agent-framework/workflows/workflows
- Microsoft AutoGen — GraphFlow: https://microsoft.github.io/autogen/dev/user-guide/agentchat-user-guide/graph-flow.html
- OpenAI Agents SDK — Agent Orchestration: https://openai.github.io/openai-agents-python/multi_agent/
- OpenAI Agents SDK — Handoffs: https://openai.github.io/openai-agents-python/handoffs/
- Apache Airflow — DAGs: https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/dags.html

### Production use

- LangChain — Systems Built with LangGraph: https://www.langchain.com/built-with-langgraph
- LangChain — LangGraph in Production: https://www.langchain.com/blog/is-langgraph-used-in-production
- LangChain / Lyft — Router-Based Customer Support Agents: https://www.langchain.com/blog/lyft-built-a-self-serve-ai-agent-platform-for-customer-support-with-langgraph-and-langsmith
