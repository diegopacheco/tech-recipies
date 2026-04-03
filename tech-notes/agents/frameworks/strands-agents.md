# Strands Agents

## 1. What is it?

Strands Agents is an open-source AI agents SDK developed by AWS, released in May 2025 under the Apache 2.0 license. It takes a model-driven approach to building AI agents, meaning you define agents with just three components: a model, a system prompt, and a set of tools. The LLM itself handles the reasoning, planning, and tool orchestration -- rather than the developer hardcoding workflow logic.

Strands Agents already powers production features inside AWS services like Amazon Q Developer, AWS Glue, and VPC Reachability Analyzer. AWS reports that teams using Strands went from months-long prototype-to-production cycles down to days and weeks.

- Language: Python (primary), TypeScript (preview)
- License: Apache 2.0
- GitHub: github.com/strands-agents (5,100+ stars on the Python SDK)
- Install: `pip install strands-agents strands-agents-tools`

## 2. Main Features

- Model-driven agent loop: the LLM iteratively reads the conversation, plans, calls tools, incorporates results, and repeats until it reaches a final answer
- Model agnostic: supports Amazon Bedrock, Anthropic, OpenAI, Gemini, Ollama, LiteLLM, llama.cpp, and custom providers
- Native MCP support: first-class Model Context Protocol integration gives agents access to thousands of published MCP tool servers
- Multi-agent orchestration: built-in Graph, Swarm, and Workflow patterns, supports A2A protocol for cross-framework interoperability
- 20+ built-in tools: file manipulation, HTTP requests, AWS API access, Python execution, calculators, Slack, image/video processing, web search
- Custom tools via decorator: any Python function becomes a tool with the @tool decorator
- Streaming: async iterators and callback-based streaming, experimental bidirectional real-time audio streaming
- Structured output: can return typed, structured responses
- Observability: built-in OpenTelemetry tracing
- Deployment targets: AWS Lambda, Fargate, EKS, Bedrock AgentCore, standard containers, Kubernetes, Terraform
- Memory: integration with Mem0, Bedrock Knowledge Bases, Elasticsearch, MongoDB Atlas
- Strands Steering (experimental): context-aware "just in time" prompting to reduce token usage
- Strands Evals (preview): evaluation suite for testing agent behavior and detecting regressions

## 3. Pros

- Extremely simple API: an agent can be created in 3 lines of code
- Model-driven philosophy: leverages modern LLM reasoning capabilities rather than requiring developers to build complex orchestration logic
- Truly model agnostic: not locked into AWS Bedrock despite being an AWS project
- Production-proven: already runs inside major AWS services (Q Developer, Glue, VPC Reachability Analyzer)
- Deep AWS integration when desired: native Bedrock, AgentCore, Lambda, and IAM support
- Native MCP support: access to the growing ecosystem of MCP tool servers out of the box
- Apache 2.0 open source with contributions from Anthropic, Meta, Accenture, PwC
- Fast iteration: model-first approach dramatically reduces time from prototype to production
- Concurrent multi-agent execution: agents can run on separate threads/processes for parallel workloads

## 4. Cons

- Heavy reliance on model quality: agent behavior is only as good as the underlying LLM, minimal hardcoded guardrails
- Less deterministic: the model-driven approach means less explicit control over exact execution paths compared to graph-based frameworks
- AWS credential/IAM complexity: deploying on AWS requires careful IAM policy configuration
- Cost scales with token usage: giving agents large inputs can cause costs to spiral quickly
- Experimental features: bidirectional streaming, Steering, and Evals are not yet stable APIs
- Still under active development: API surface and best practices are evolving
- Latency in deep agent graphs: multi-level agent hierarchies add round-trip overhead at each hop
- Newer ecosystem: smaller community and fewer third-party tutorials compared to LangChain or CrewAI

## 5. Comparison

| Aspect | Strands Agents | CrewAI | Spring AI | LangChain/LangGraph | AWS AgentCore |
|---|---|---|---|---|---|
| Language | Python, TypeScript | Python | Java/JVM | Python, JS | Framework-agnostic runtime |
| Architecture | Model-driven (LLM decides) | Role-based crews | Spring Boot patterns | Graph-based DAGs | Infrastructure layer |
| Ease of Use | Very high (3 lines) | High | Moderate | Moderate to steep | Moderate |
| Multi-Agent | Graph, Swarm, Workflow, A2A | Crew hierarchies, delegation | Orchestrator-Worker | LangGraph nodes/edges | Runs any framework's agents |
| MCP Support | Native, first-class | Limited | Limited | Via integration | Supports MCP natively |
| Cloud Affinity | AWS (but runs anywhere) | Cloud-agnostic | Azure / Spring | Cloud-agnostic | AWS only |
| Maturity | Released May 2025 | Released early 2024 | GA 2024 | Established since 2022 | Released mid-2025 |
| Best For | Fast agent dev, AWS teams | Role-based team collaboration | Java/Spring enterprise | Complex stateful workflows | Production infra for any agent |

AgentCore is not a competing framework -- it is the infrastructure/runtime layer that Strands (or LangChain, CrewAI) agents deploy onto. Strands is the brain; AgentCore is the production runtime.

## 6. Why is it unique?

Strands Agents is unique because it is model-first, not workflow-first. Unlike LangGraph (graph-based) or CrewAI (role-based), Strands trusts the LLM to handle orchestration. You define what you want, not how to get there. It was built to power production AWS services (Q Developer, Glue) and was open-sourced after proving itself internally. It has first-class MCP integration as a core primitive, giving it native access to the rapidly growing MCP tool ecosystem. The three-component simplicity (Agent = Model + Prompt + Tools) is intentional and radical compared to other frameworks. It also supports A2A protocol and can interoperate with LangChain, CrewAI, and other frameworks rather than requiring you to pick one.

## 7. Simple Usage

```python
from strands import Agent, tool

@tool
def word_count(text: str) -> int:
    """Count the number of words in a given text."""
    return len(text.split())

agent = Agent(tools=[word_count])
response = agent("How many words are in: The quick brown fox jumps over the lazy dog")
print(response)
```

Using a built-in tool:

```python
from strands import Agent
from strands_tools import calculator

agent = Agent(tools=[calculator])
agent("What is the square root of 1764")
```

Using a different model provider (OpenAI):

```python
from strands import Agent
from strands.models.openai import OpenAIModel

model = OpenAIModel(model_id="gpt-4o")
agent = Agent(model=model)
agent("Explain quantum computing in simple terms")
```
