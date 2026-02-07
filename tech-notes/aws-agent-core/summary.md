# Summary

## 4 AgentCore Services

1 - agent-core-runtime.md - Serverless runtime for deploying/scaling AI agents. Framework-agnostic (Strands,
LangChain, CrewAI, etc.), supports streaming, MCP server hosting, session isolation.

2 - agent-core-memory.md - Managed persistent memory for agents. Semantic memory (facts/preferences) + Episodic
memory (conversation history), with semantic search.

3 - agent-core-identity.md - Auth for AI agents. OAuth2, API Key, and AWS IAM JWT via Python decorators (@requires_access_token, @requires_api_key).

4 - agent-core-gateway.md - Converts REST APIs / OpenAPI specs / Smithy models / Lambda functions into MCP tools for agents.

## 3 Related LLM Infrastructure Tools

5 - litellm.md - Open-source unified proxy for 100+ LLM providers (OpenAI-compatible).

6 - openrouter.md - Hosted API gateway for 200+ models from 30+ providers.

7 - lang-fuse.md - Open-source LLM observability, tracing, evaluation, and prompt management.