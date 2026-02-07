# Amazon Bedrock AgentCore Identity

## What It Is

Amazon Bedrock AgentCore Identity is a service that provides authentication and authorization capabilities for AI agents. It enables agents to securely authenticate with AWS services and third-party APIs using OAuth2 flows, API keys, and AWS IAM JWT tokens. The Identity service handles credential management, token exchange, and secure secret storage so agents can interact with external services on behalf of users without exposing credentials.

- SDK: [https://github.com/aws/bedrock-agentcore-sdk-python](https://github.com/aws/bedrock-agentcore-sdk-python) (identity module)
- Docs: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-getting-started-cognito.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-getting-started-cognito.html)

## How It Works

AgentCore Identity provides Python decorators that fetch credentials before executing agent tool functions. The three main patterns are:

### OAuth2 Access Token (`@requires_access_token`)
For third-party services that use OAuth2 (GitHub, Google, Salesforce, etc.). Supports both M2M (machine-to-machine) and USER_FEDERATION flows. The decorator handles the full OAuth2 flow including authorization URL generation, token polling, and token refresh.

### API Key (`@requires_api_key`)
For services that use static API keys. Keys are securely stored in AgentCore and fetched at runtime.

### AWS IAM JWT (`@requires_iam_access_token`)
For services that accept AWS-signed JWTs. Uses AWS STS `GetWebIdentityToken` to issue signed JWTs without client secrets.

```python
from bedrock_agentcore.identity import requires_access_token, requires_api_key

@requires_access_token(
    provider_name="github",
    scopes=["repo", "user"],
    auth_flow="USER_FEDERATION"
)
def list_repos(query: str, *, access_token: str) -> str:
    import requests
    response = requests.get(
        "https://api.github.com/user/repos",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    return response.json()

@requires_api_key(provider_name="my-api-service")
def call_api(query: str, *, api_key: str) -> str:
    import requests
    response = requests.get(
        "https://api.service.com/data",
        headers={"X-API-Key": api_key}
    )
    return response.json()
```

### Architecture

1. Credential providers are configured in AgentCore (OAuth2 configs, API keys)
2. At runtime, the `@requires_access_token` or `@requires_api_key` decorator intercepts the function call
3. The Identity SDK communicates with the AgentCore Identity service to fetch/exchange tokens
4. The token or key is injected into the decorated function as a keyword argument
5. The function executes with valid credentials

The service also handles local development by setting up workload identity tokens via `.agentcore.json` config files.

## Main Features

- **OAuth2 Support** - Full OAuth2 flow with M2M and User Federation authentication patterns
- **API Key Management** - Secure storage and runtime retrieval of API keys
- **AWS IAM JWT** - Issue AWS-signed JWTs for services that accept OIDC tokens
- **Decorator-based API** - Simple Python decorators (`@requires_access_token`, `@requires_api_key`) for credential injection
- **Async and Sync Support** - Works with both async and synchronous Python functions
- **Token Refresh** - Automatic token refresh for OAuth2 flows
- **Local Development** - Local dev mode with workload identity simulation
- **Custom OAuth2 Parameters** - Support for custom state and parameters in authorization requests
- **Callback URL Handling** - Automatic OAuth2 callback URL management in AgentCore Runtime
- **Force Re-authentication** - Option to force users to re-authenticate

## Pros

- Eliminates credential management complexity from agent code
- Secure secret storage; no API keys in source code or environment variables
- Clean decorator-based API that separates auth concerns from business logic
- Supports both OAuth2 and API key patterns
- Works transparently in both local dev and deployed environments
- AWS IAM JWT support enables M2M auth without client secrets
- Handles token refresh automatically

## Cons

- AWS-only; requires AgentCore infrastructure
- Limited to Python SDK currently
- Requires upfront configuration of credential providers in AgentCore
- OAuth2 USER_FEDERATION flow requires user interaction (authorization URL)
- New service with limited adoption and documentation
- Debugging auth issues can be complex due to the abstraction layer
- Dependency on AWS STS for IAM JWT functionality

## Alternatives

| Alternative | Description |
|---|---|
| **AWS Secrets Manager** | General-purpose secret storage, manual integration |
| **HashiCorp Vault** | Open-source secret management with dynamic credentials |
| **AWS IAM Roles** | Native AWS auth for AWS services |
| **Auth0 / Okta** | Third-party identity providers with OAuth2 support |
| **AWS Cognito** | AWS user pool and identity management |
| **Environment Variables** | Simple but insecure credential management |
| **Composite AI Identity (custom)** | Custom OAuth2 middleware for agent auth |

## Link to Code

- Identity Quick Start: [https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-getting-started-cognito.html](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-getting-started-cognito.html)
- Python SDK Identity Module: [https://github.com/aws/bedrock-agentcore-sdk-python/tree/main/src/bedrock_agentcore/identity](https://github.com/aws/bedrock-agentcore-sdk-python/tree/main/src/bedrock_agentcore/identity)
- Identity Auth Source: [https://github.com/aws/bedrock-agentcore-sdk-python/blob/main/src/bedrock_agentcore/identity/auth.py](https://github.com/aws/bedrock-agentcore-sdk-python/blob/main/src/bedrock_agentcore/identity/auth.py)
