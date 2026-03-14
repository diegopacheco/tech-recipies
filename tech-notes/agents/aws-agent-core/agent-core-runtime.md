# Amazon Bedrock AgentCore Runtime

## What It Is

Amazon Bedrock AgentCore Runtime is a secure, serverless runtime for deploying and scaling AI agents and tools as part of the Amazon Bedrock AgentCore platform. It supports any framework (Strands Agents, LangChain, LangGraph, CrewAI, Autogen, custom) and any model (Amazon Bedrock or external). The Python SDK (`bedrock-agentcore`) provides a lightweight wrapper that turns your agent function into an HTTP service compatible with Amazon Bedrock, using a simple `@app.entrypoint` decorator.

- SDK: [https://github.com/aws/bedrock-agentcore-sdk-python](https://github.com/aws/bedrock-agentcore-sdk-python)
- Samples: [https://github.com/awslabs/amazon-bedrock-agentcore-samples](https://github.com/awslabs/amazon-bedrock-agentcore-samples)
- Docs: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/what-is-bedrock-agentcore.html)

## How It Works

1. You write your agent logic using any framework (Strands, LangGraph, CrewAI, custom Python).
2. You wrap it with the `BedrockAgentCoreApp` and decorate the entry function with `@app.entrypoint`.
3. The SDK handles HTTP server details, session management, and streaming.
4. You deploy to AgentCore Runtime using the Starter Toolkit or AWS CDK.
5. Applications invoke the agent via boto3, AWS SDK for JavaScript/Java, or the AgentCore SDK.

The runtime provides session-isolated compute, meaning each agent invocation runs in its own secure sandbox. It supports both request-response and bi-directional streaming patterns.

```python
from strands import Agent
from bedrock_agentcore import BedrockAgentCoreApp

app = BedrockAgentCoreApp()

agent = Agent()

@app.entrypoint
def my_agent(request):
    return agent(request.get("prompt"))

app.run()
```

## Main Features

- **Framework Agnostic** - Deploy agents from Strands, LangChain, LangGraph, CrewAI, Autogen, or custom code
- **Model Agnostic** - Use any model (Amazon Bedrock, OpenAI, Anthropic direct, local models)
- **Serverless** - Zero infrastructure management, auto-scaling
- **Session Isolation** - Each invocation runs in a secure isolated environment
- **Bi-directional Streaming** - Support for real-time streaming between client and agent
- **MCP Server Hosting** - Host Model Context Protocol servers alongside agents
- **MCP Dynamic Client Registration** - Agents can discover and register MCP servers at runtime
- **Integration with AgentCore Services** - Built-in integration with Memory, Gateway, Identity, Observability, Code Interpreter, and Browser
- **Starter Toolkit** - CLI tool for rapid prototyping and deployment ([bedrock-agentcore-starter-toolkit](https://github.com/aws/bedrock-agentcore-starter-toolkit))
- **AWS CDK Support** - Production deployment via Infrastructure as Code

## Pros

- No infrastructure to manage; fully serverless
- Works with any AI framework and any model
- Minimal code changes to go from local prototype to production
- Built-in session isolation and security
- Native integration with other AgentCore services (Memory, Identity, Gateway)
- Supports streaming and long-running workflows
- Apache 2.0 licensed SDK

## Cons

- AWS-only deployment target; vendor lock-in to AWS
- Relatively new service (launched mid-2025), ecosystem still maturing
- Requires AWS account and Bedrock access
- Cold start latency inherent to serverless architectures
- Limited community content and third-party tutorials compared to mature services
- Pricing tied to AWS compute and Bedrock usage

## Alternatives

| Alternative | Description |
|---|---|
| **AWS Lambda** | General serverless compute, not agent-specific |
| **AWS Bedrock Agents** | AWS's managed agent service with built-in orchestration (less flexible than AgentCore) |
| **Azure AI Agent Service** | Microsoft's managed agent hosting on Azure |
| **Google Vertex AI Agent Builder** | Google Cloud's agent deployment platform |
| **Modal** | Serverless GPU/CPU compute for Python, good for ML workloads |
| **Fly.io / Railway** | Container-based deployment platforms |
| **Self-hosted (ECS/EKS)** | Full control with containers on AWS |

## Link to Code

- Hosting Agents Tutorial: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/01-hosting-agent](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/01-hosting-agent)
- Hosting MCP Servers: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/02-hosting-MCP-server](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/02-hosting-MCP-server)
- Bi-directional Streaming: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/06-bi-directional-streaming](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/06-bi-directional-streaming)
- Full MCP Server E2E: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/08-full-mcp-server-e2e](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/01-AgentCore-runtime/08-full-mcp-server-e2e)
