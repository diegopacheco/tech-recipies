# AWS Agent Core (Amazon Bedrock AgentCore)

## 1. What is it?

Amazon Bedrock AgentCore is a fully managed, modular platform from AWS for deploying, operating, and scaling AI agents in production. It is not an agent-building framework itself, but rather the infrastructure layer that sits beneath any agent framework. It provides enterprise-grade runtime, memory, identity, observability, gateway, browser automation, code interpretation, policy enforcement, and evaluation services.

It was announced in preview in mid-2025 and reached general availability across nine AWS Regions. The Python SDK has been downloaded over 2 million times.

- SDK: github.com/aws/bedrock-agentcore-sdk-python
- PyPI: bedrock-agentcore

AgentCore is framework-agnostic and model-agnostic. You can build your agent with Strands Agents, CrewAI, LangGraph, OpenAI Agents SDK, Google ADK, or any custom code, then deploy it to AgentCore Runtime without modification. It works with models from Amazon Bedrock, OpenAI, Google Gemini, Anthropic Claude, Amazon Nova, Meta Llama, and others.

## 2. Main Features

- Runtime: secure, serverless runtime with fast cold starts, session isolation, extended execution (up to 8 hours per microVM), and support for multimodal and long-running agents
- Memory: managed session and long-term (episodic) memory so agents retain context across interactions
- Identity: agents can authenticate to AWS services and third-party tools (GitHub, Salesforce, Slack) via OAuth
- Gateway: converts existing APIs, Lambda functions, and MCP servers into agent-compatible tools with semantic search over hundreds of tools
- Observability: OpenTelemetry-compatible tracing, step-by-step execution visualization, token and cost tracking dashboards
- Code Interpreter: agents can generate and execute code in isolated sandboxes
- Browser Tool: agents can navigate websites, fill forms, and perform multi-step web tasks in a managed sandbox
- Policy (Cedar): fine-grained access control using Cedar policies to allow/deny tool invocations based on identity, parameters, and business rules
- Evaluations: quality checks and evaluation pipelines for agent outputs before production deployment
- Protocol Support: native support for MCP (Model Context Protocol) and A2A (Agent-to-Agent) protocol
- Framework-Agnostic: deploy agents built with Strands Agents, CrewAI, LangGraph, LlamaIndex, OpenAI Agents SDK, Google ADK, or custom code
- IaC Support: CloudFormation, CDK, and Terraform support for provisioning infrastructure

## 3. Pros

- Fully managed, consumption-based pricing with no upfront costs; each module billed independently
- Strongest network isolation of any managed agent runtime (VPC, PrivateLink, session isolation)
- Framework-agnostic and model-agnostic -- no vendor lock-in at the agent framework level
- Production-grade from day one: handles scaling, security, and ops that teams otherwise build themselves
- Native MCP and A2A protocol support for multi-agent and multi-tool interoperability
- Unified observability dashboards with OpenTelemetry compatibility
- Rapid adoption: 2M+ SDK downloads, major enterprise customers (PGA TOUR, Sony, Thomson Reuters, Ericsson, Experian)
- Local development supported: run and test agents locally before deploying
- Supports both synchronous and async streaming invocations

## 4. Cons

- AWS ecosystem dependency: best suited for teams already on AWS; unfamiliar teams face friction
- Iteration overhead: every code change requires rebuilding a Docker image and pushing to ECR for cloud testing (local mode mitigates this)
- Some services still in preview: Policy and Evaluations have limited regional availability
- Limited regional availability: GA in 9 regions, but Evaluations only in US East (N. Virginia)
- Limited memory visibility: inspecting and auditing what agents retain across sessions is not fully transparent
- Cedar policy language constraints: no floats, no regex, no date/time comparisons in Gateway policies
- Code-first only: requires Python coding skills; no low-code/no-code interface (use Bedrock Agents for that)
- Complexity vs. simpler alternatives: overkill for prototyping or experimentation

## 5. Comparison

| Aspect | AWS AgentCore | Strands Agents | CrewAI | Spring AI | LangChain/LangGraph |
|---|---|---|---|---|---|
| Type | Managed infrastructure platform | Open-source Python SDK | Open-source Python framework | Open-source Java/Spring library | Open-source Python SDK |
| Purpose | Deploy, operate, scale agents | Build agents (model-driven) | Multi-agent role-based collaboration | AI integration for Java apps | Orchestration, chains, workflows |
| Language | Python (SDK), any (runtime) | Python | Python | Java/Kotlin | Python, JS |
| Framework Agnostic | Yes (runs any framework) | N/A (is a framework) | N/A (is a framework) | N/A (is a framework) | N/A (is a framework) |
| Managed Runtime | Yes (serverless) | No (deploy yourself) | No | No | No |
| Enterprise Security | VPC, IAM, PrivateLink, Cedar policies | Basic | Basic | Spring Security integration | Basic |
| Multi-Agent | A2A protocol native | Basic multi-agent | Core feature (Crews) | Limited | LangGraph supports it |
| MCP Support | Native (Gateway) | Yes | Yes | Developing | Yes |
| Memory Management | Managed service (session + episodic) | Basic | Built-in per agent | Manual | LangGraph checkpointing |
| Observability | Built-in (OpenTelemetry) | Basic | Basic | Spring Actuator | LangSmith (paid) |
| Best For | Production ops at scale | Building agents quickly | Role-based agent teams | Java/Spring enterprise apps | Complex stateful workflows |

AgentCore is not a competitor to Strands Agents, CrewAI, or LangChain. It is the infrastructure layer that hosts agents built with any of those frameworks. Strands Agents is AWS's own open-source framework that pairs naturally with AgentCore (brain + infrastructure).

## 6. Why is it unique?

Amazon Bedrock AgentCore is not another agent framework -- it is the production operations platform for agents built with any framework. No other offering combines a serverless agent runtime with 8-hour persistent microVMs and true session isolation, a managed MCP Gateway that auto-converts APIs/Lambdas into agent-compatible tools, built-in identity management for both AWS and third-party OAuth services, Cedar-based policy enforcement for real-time tool invocation governance, and consumption-based modular billing where you only pay for the services you use. While LangChain, CrewAI, and Strands Agents focus on how to build an agent, AgentCore focuses on how to run an agent safely and reliably at enterprise scale.

## 7. Simple Usage

Install:
```bash
pip install bedrock-agentcore strands-agents strands-agents-builder
```

Minimal agent deployed to AgentCore:
```python
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from strands import Agent

app = BedrockAgentCoreApp()
agent = Agent()

@app.entrypoint
def invoke(payload):
    user_message = payload.get("prompt", "Hello")
    result = agent(user_message)
    return {"result": result.message}

if __name__ == "__main__":
    app.run()
```

Test locally:
```bash
python my_agent.py

curl -X POST http://localhost:8080/invocations \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is the capital of France?"}'
```

Deploy to AWS:
```bash
agentcore launch
```
