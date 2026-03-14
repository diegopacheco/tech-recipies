# Amazon Bedrock AgentCore Gateway

## What It Is

Amazon Bedrock AgentCore Gateway is a managed service that transforms existing REST APIs, OpenAPI specs, Smithy models, and Lambda functions into MCP (Model Context Protocol) tools that AI agents can use. It acts as a bridge between traditional APIs and AI agents, handling schema translation, authentication, and tool discovery. Instead of writing custom tool wrappers for every API, you configure a Gateway target and it automatically exposes the API as MCP-compatible tools.

- SDK: [https://github.com/aws/bedrock-agentcore-sdk-python](https://github.com/aws/bedrock-agentcore-sdk-python)
- Samples: [https://github.com/awslabs/amazon-bedrock-agentcore-samples](https://github.com/awslabs/amazon-bedrock-agentcore-samples)
- Docs: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-quick-start.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-quick-start.html)

## How It Works

AgentCore Gateway has two main resources:

### Gateway
A logical container that groups related API targets. You create a Gateway and then add Targets to it.

### Gateway Target
A specific API endpoint configured with:
- **Target Configuration** - The API schema (OpenAPI spec, Smithy model, or Lambda ARN) provided via S3 URI or inline payload
- **Credential Provider** - How the Gateway authenticates with the target API (OAuth2, API Key, or Gateway IAM Role)

The workflow:
1. Create a Gateway via boto3 or AWS CLI
2. Add one or more Targets pointing to your APIs (OpenAPI, Smithy, or Lambda)
3. Configure authentication for each Target
4. The Gateway automatically generates MCP-compatible tool definitions
5. Agents connect to the Gateway's MCP endpoint to discover and use the tools

```python
import boto3

client = boto3.client("bedrock-agentcore-control")

gateway = client.create_gateway(
    name="my-api-gateway",
    description="Gateway for my internal APIs",
    protocolType="MCP"
)

target = client.create_gateway_target(
    gatewayIdentifier=gateway["gatewayId"],
    name="my-api-target",
    targetConfiguration={
        "mcp": {
            "openApiSchema": {
                "s3": {"uri": "s3://my-bucket/openapi-spec.yaml"}
            }
        }
    },
    credentialProviderConfigurations=[
        {"credentialProviderType": "GATEWAY_IAM_ROLE"}
    ]
)
```

## Main Features

- **API to MCP Translation** - Automatically converts OpenAPI specs, Smithy models, and Lambda functions into MCP tools
- **Multiple Schema Sources** - Supports OpenAPI schemas, Smithy models, Lambda with tool schemas (via S3 or inline)
- **Authentication Options** - OAuth2, API Key, and Gateway IAM Role credential providers
- **Managed Infrastructure** - No servers to manage; AWS handles scaling and availability
- **Tool Discovery** - Agents can dynamically discover available tools via MCP
- **CRUD Operations** - Full lifecycle management of Gateways and Targets via boto3
- **S3 Integration** - Schema files can be stored in and loaded from S3
- **Multi-target Support** - A single Gateway can have multiple Targets (different APIs)

## Pros

- Eliminates boilerplate tool wrapper code for existing APIs
- Supports industry-standard API formats (OpenAPI, Smithy)
- Built-in credential management for target API authentication
- MCP-native, aligning with the emerging standard for AI tool integration
- Managed and serverless
- Centralized API management for agent tools

## Cons

- AWS-only; vendor lock-in
- New service; limited adoption and documentation
- MCP protocol is still evolving
- Schema must be well-defined; poorly documented APIs will produce poor tools
- Configuration via boto3 can be verbose
- Debugging schema translation issues may be challenging
- Limited to supported schema formats (OpenAPI, Smithy, Lambda)

## Alternatives

| Alternative | Description |
|---|---|
| **Custom MCP Servers** | Build your own MCP server with direct API integration |
| **LangChain Tools** | Framework-level tool wrappers for APIs |
| **Composio** | Third-party platform for converting APIs to agent tools |
| **Toolhouse** | Managed tool execution platform for AI agents |
| **Custom function calling** | Manual tool definitions for each LLM provider |
| **Kong AI Gateway** | API gateway with AI-specific features |
| **Portkey** | AI gateway with tool routing capabilities |

## Link to Code

- Gateway Quick Start: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-quick-start.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-quick-start.html)
- Gateway Tutorial Samples: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials)
- Gateway README: [https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/03-AgentCore-gateway](https://github.com/awslabs/amazon-bedrock-agentcore-samples/tree/main/01-tutorials/03-AgentCore-gateway)
