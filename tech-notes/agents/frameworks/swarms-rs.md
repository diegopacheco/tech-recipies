# Swarms-rs

## 1. What is it?

Swarms-rs is an enterprise-grade, production-ready multi-agent orchestration framework built in Rust. Created by The Swarm Corporation (Kye Gomez), it leverages Rust's zero-cost abstractions, fearless concurrency, and memory safety guarantees to deliver high-performance multi-agent systems. It is the Rust counterpart of the Python-based Swarms framework, targeting use cases where latency, throughput, and reliability are critical.

- Language: Rust
- License: Apache 2.0
- GitHub: github.com/The-Swarm-Corporation/swarms-rs (123+ stars)
- Crates.io: swarms-rs v0.2.1
- Install: `cargo add swarms-rs`

## 2. Main Features

- ConcurrentWorkflow: runs multiple specialized agents simultaneously on the same task, aggregating results
- SequentialWorkflow: agents execute in sequence, each passing its output to the next agent in the chain
- Agent builder pattern: chainable API for configuring system prompt, name, max loops, temperature, retry attempts, stop words, and autosave
- MCP integration: first-class Model Context Protocol support via both STDIO and SSE server types, giving agents access to external tools
- Multi-provider LLM support: OpenAI, DeepSeek, and Anthropic out of the box via environment variables
- Planning mode: agents can generate execution plans before running tasks via `enable_plan()`
- State persistence: autosave agent state to disk with configurable directory
- Async-first: built on Tokio for non-blocking concurrent execution
- Structured logging: tracing and tracing-subscriber integration with configurable log levels
- Modular architecture: agent layer, LLM provider layer, tool system, MCP integration, and swarm orchestration as separate composable layers

## 3. Pros

- Rust performance: near-zero latency, zero-cost abstractions, multi-core utilization without garbage collection overhead
- Memory safety: Rust ownership model eliminates data races, null pointer dereferences, and memory leaks at compile time
- Simple builder API: creating an agent is straightforward with method chaining
- MCP support: STDIO and SSE server integration gives agents access to the growing MCP tool ecosystem
- Async-native: built on Tokio, designed for high-concurrency workloads from the ground up
- Lightweight: no heavy framework dependencies, just Rust crates
- Scales from single agent to concurrent multi-agent workflows with minimal code changes
- State persistence built in: autosave and restore agent state without external infrastructure

## 4. Cons

- Very early stage: v0.2.1 with only 465 downloads per month, API is still evolving
- Small community: 123 GitHub stars, limited third-party tutorials and resources
- Fewer LLM providers: only OpenAI, DeepSeek, and Anthropic compared to Python frameworks that support dozens
- Rust learning curve: requires Rust proficiency, not accessible to teams without Rust experience
- Limited tool ecosystem: far fewer built-in tools compared to CrewAI (100+) or LangChain (600+)
- No built-in memory system: lacks short-term, long-term, and entity memory that Python frameworks provide
- Documentation is sparse: relies heavily on README and code reading
- No visual builder or studio interface

## 5. Comparison

| Aspect | Swarms-rs | CrewAI | Strands Agents | LangChain/LangGraph | Spring AI |
|---|---|---|---|---|---|
| Language | Rust | Python | Python, TypeScript | Python, JS/TS | Java (Spring Boot) |
| Performance | Native compiled, zero-cost abstractions | Interpreted Python | Interpreted Python | Interpreted Python | JVM-based |
| Architecture | Builder pattern + Concurrent/Sequential workflows | Role-based crews + flows | Model-driven agentic loop | Graph-based DAGs | Spring Boot patterns |
| Multi-Agent | ConcurrentWorkflow, SequentialWorkflow | Crew hierarchies, delegation | Graph, Swarm, Workflow, A2A | LangGraph nodes/edges | Orchestrator-Worker |
| MCP Support | STDIO + SSE | Limited | Native, first-class | Via integration | Limited |
| Memory Safety | Compile-time guaranteed | Runtime (Python GC) | Runtime (Python GC) | Runtime (Python GC) | JVM managed |
| Tool Ecosystem | MCP-based, extensible | 100+ built-in | 20+ built-in + MCP | 600+ integrations | @Tool annotation + MCP |
| Maturity | v0.2.1, early stage | v1.9.3, production GA | Open sourced May 2025 | Established since 2022 | 1.0 GA May 2025 |
| Best For | Performance-critical agent systems | Rapid multi-agent prototyping | AWS-native agent dev | Complex chains with many integrations | Java/Spring enterprise |

## 6. Why is it unique?

Swarms-rs is unique because it is the only production-oriented multi-agent framework written in Rust. While every other major agent framework runs on Python (or JVM in the case of Spring AI), Swarms-rs brings compile-time memory safety, zero-cost abstractions, and native performance to agent orchestration. This makes it the natural choice for latency-sensitive, high-throughput, or resource-constrained environments where Python overhead is unacceptable. The combination of Tokio-based async concurrency, MCP tool integration, and a clean builder API means you get multi-agent orchestration without sacrificing the performance and safety guarantees that Rust provides. It is also one of the few frameworks that supports both concurrent and sequential agent workflows as first-class primitives.

## 7. Simple Usage

```rust
use anyhow::Result;
use swarms_rs::llm::provider::openai::OpenAI;

#[tokio::main]
async fn main() -> Result<()> {
    dotenv::dotenv().ok();

    let client = OpenAI::from_url(
        std::env::var("OPENAI_API_KEY")?,
        "https://api.openai.com/v1",
    );

    let agent = client
        .agent_builder()
        .system_prompt("You are a helpful financial analyst.")
        .agent_name("Financial-Analyst")
        .user_name("User")
        .max_loops(1)
        .temperature(0.5)
        .enable_autosave()
        .retry_attempts(3)
        .build();

    let response = agent.run("What are the top 3 tech stocks to watch?").await?;
    println!("{}", response);

    Ok(())
}
```

ConcurrentWorkflow with multiple agents:

```rust
use anyhow::Result;
use swarms_rs::llm::provider::openai::OpenAI;
use swarms_rs::structs::concurrent_workflow::ConcurrentWorkflow;

#[tokio::main]
async fn main() -> Result<()> {
    dotenv::dotenv().ok();

    let client = OpenAI::from_url(
        std::env::var("OPENAI_API_KEY")?,
        "https://api.openai.com/v1",
    );

    let analyst = client
        .agent_builder()
        .system_prompt("You are a financial analyst.")
        .agent_name("Analyst")
        .max_loops(1)
        .build();

    let researcher = client
        .agent_builder()
        .system_prompt("You are a market researcher.")
        .agent_name("Researcher")
        .max_loops(1)
        .build();

    let workflow = ConcurrentWorkflow::builder()
        .name("Market-Analysis")
        .agents(vec![Box::new(analyst), Box::new(researcher)])
        .build();

    let result = workflow.run("Analyze the current state of the AI industry").await?;
    println!("{}", result);

    Ok(())
}
```

Add to Cargo.toml:
```toml
[dependencies]
swarms-rs = "0.2.1"
tokio = { version = "1", features = ["full"] }
anyhow = "1"
dotenv = "0.15"
```
