# Model Context Protocol (MCP)

https://modelcontextprotocol.io/

## 1. What is MCP?

MCP (Model Context Protocol) is an open protocol created by Anthropic in November 2024 that standardizes how AI applications connect to external data sources, tools, and services. Think of MCP as a USB-C port for AI -- a universal interface that lets any AI model plug into any tool or data source without custom integration code for each combination. MCP follows a client-server architecture where AI applications (hosts) connect to MCP servers that expose tools, resources, and prompts. The protocol uses JSON-RPC 2.0 over stdio or HTTP with SSE (Server-Sent Events) for transport. MCP was open-sourced under the MIT license and has been widely adopted across the AI ecosystem, becoming the de facto standard for tool integration.

## 2. How it Works?

MCP has three core concepts:

**Tools**: Functions that the AI model can call to perform actions. A tool has a name, description, and JSON Schema for its parameters. The model decides when to call a tool based on the conversation context. Tools are the most commonly used MCP primitive.

**Resources**: Data sources that provide context to the model. Unlike tools (which do things), resources expose information (files, database records, API responses) that get loaded into the model's context. Resources are identified by URIs.

**Prompts**: Reusable prompt templates that servers can expose. These are pre-built instructions that guide the model for specific tasks, with optional arguments for customization.

The architecture has three layers:

```
┌──────────────────────────────────────────────────────┐
│                    Host (AI App)                      │
│  Claude Code, Cursor, Windsurf, VS Code, Custom App  │
├──────────────────────────────────────────────────────┤
│                   MCP Client                          │
│  Maintains 1:1 connection with each MCP server        │
├──────────┬──────────┬──────────┬─────────────────────┤
│ Server A │ Server B │ Server C │ Server D ...         │
│ (GitHub) │ (Slack)  │ (DB)     │ (Files)              │
└──────────┴──────────┴──────────┴─────────────────────┘
```

The typical flow:
1. Host application starts and initializes MCP client connections to configured servers
2. Client performs capability negotiation with each server (protocol version, supported features)
3. Server advertises its tools, resources, and prompts to the client
4. When the model needs to use a tool, the client sends a JSON-RPC request to the appropriate server
5. Server executes the tool and returns the result
6. Client feeds the result back to the model for continued reasoning

Transport options:
- **stdio**: Server runs as a subprocess, communicates over stdin/stdout. Best for local tools.
- **Streamable HTTP**: Server runs as a web service, communicates over HTTP with SSE for streaming. Best for remote/shared servers.

## 3. PROS

- **Universal Standard**: One protocol to connect any model to any tool, eliminating the N x M integration problem
- **Simple to Implement**: A basic MCP server can be built in under 50 lines of code
- **Model Agnostic**: Works with Claude, GPT, Gemini, Llama, or any model that supports tool calling
- **Growing Ecosystem**: Thousands of MCP servers available for databases, APIs, cloud services, dev tools, and more
- **Security Model**: Servers run in their own process with explicit capability boundaries, the model never gets direct access to underlying systems
- **Composable**: A host can connect to multiple servers simultaneously, mixing and matching capabilities
- **Official SDKs**: First-party SDKs for Python, TypeScript, Java, Kotlin, C#, Swift, and Go
- **Industry Adoption**: Supported by Anthropic, OpenAI, Google, Microsoft, AWS, and most AI IDE tools
- **Open Source**: MIT licensed, open governance, community-driven development
- **Streaming**: Built-in support for streaming responses via SSE

## 4. CONS

- **Security Surface**: MCP servers can be vectors for prompt injection, tool poisoning, or data exfiltration if not carefully vetted
- **Server Quality Varies**: Community servers range from production-grade to barely functional prototypes
- **No Built-in Auth Standard**: Authentication between client and server is not standardized yet, each server handles it differently
- **Discovery Problem**: Finding the right MCP server for a task requires manual search, no centralized trusted registry exists
- **Overhead for Simple Cases**: For a single tool integration, MCP adds protocol ceremony that a direct API call wouldn't need
- **Debugging Complexity**: When something fails in the model -> client -> server chain, tracing the issue requires understanding all three layers
- **Still Evolving**: The protocol is actively being updated, breaking changes are possible between versions
- **Resource Consumption**: Each MCP server is a separate process (in stdio mode), running many servers consumes system resources
- **Tool Sprawl**: Easy to add tools but hard to manage which tools are available to which agents in production

## 5. Use Cases

- **IDE Integration**: Code editors like Cursor, Windsurf, and VS Code use MCP to give AI assistants access to file systems, git, terminals, and language servers
- **Database Access**: Connect AI agents to PostgreSQL, MySQL, SQLite, MongoDB, or Redis for querying and data manipulation
- **Cloud Operations**: Manage AWS, GCP, or Azure resources through AI agents using cloud-specific MCP servers
- **API Integration**: Connect to Slack, GitHub, Jira, Linear, Notion, and other SaaS tools without custom code
- **Knowledge Bases**: Expose internal documentation, wikis, or vector databases as MCP resources for RAG
- **DevOps Automation**: AI agents can manage containers, Kubernetes clusters, CI/CD pipelines through MCP tools
- **Browser Automation**: Playwright and Puppeteer MCP servers enable AI-driven web scraping and testing
- **File Processing**: Read, write, and transform files across local and cloud storage

## 6. Who is Using it?

**AI Companies**: Anthropic (Claude), OpenAI (ChatGPT, Codex), Google (Gemini), Cohere

**IDE/Dev Tools**: Cursor, Windsurf, VS Code (GitHub Copilot), JetBrains, Zed, Replit, Cline, Claude Code

**Cloud Providers**: AWS (Bedrock, Q Developer), Google Cloud (Vertex AI), Microsoft (Azure AI)

**Frameworks**: LangChain, CrewAI, Strands Agents, Spring AI, Mastra, Vercel AI SDK

**Enterprises**: Shopify, Block, Apollo, Notion, Sourcegraph, Sentry

## 7. Code Sample - Building an MCP Server (TypeScript)

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "weather-server",
  version: "1.0.0",
});

server.tool(
  "get_weather",
  "Get current weather for a city",
  { city: z.string().describe("City name") },
  async ({ city }) => {
    const response = await fetch(
      `https://wttr.in/${encodeURIComponent(city)}?format=j1`
    );
    const data = await response.json();
    const current = data.current_condition[0];
    return {
      content: [
        {
          type: "text",
          text: `${city}: ${current.temp_C}°C, ${current.weatherDesc[0].value}`,
        },
      ],
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

## 8. Code Sample - Building an MCP Server (Python)

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("weather-server")

@mcp.tool()
async def get_weather(city: str) -> str:
    """Get current weather for a city."""
    import httpx
    async with httpx.AsyncClient() as client:
        response = await client.get(f"https://wttr.in/{city}?format=j1")
        data = response.json()
        current = data["current_condition"][0]
        return f"{city}: {current['temp_C']}°C, {current['weatherDesc'][0]['value']}"

@mcp.resource("config://settings")
def get_settings() -> str:
    """Expose application settings as a resource."""
    return '{"units": "celsius", "language": "en"}'

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

## 9. Client Configuration

In Claude Code (`~/.claude/settings.json`):

```json
{
  "mcpServers": {
    "weather": {
      "command": "node",
      "args": ["weather-server.js"]
    },
    "database": {
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "./data.db"]
    }
  }
}
```

## 10. MCP vs Direct API Calls vs A2A

```
┌────────────┬──────────────────────────┬─────────────────────────┬──────────────────────────┐
│  Aspect    │          MCP             │     Direct API Call     │          A2A             │
├────────────┼──────────────────────────┼─────────────────────────┼──────────────────────────┤
│ Purpose    │ Connect model to tools   │ App-to-service call     │ Agent-to-agent comms     │
├────────────┼──────────────────────────┼─────────────────────────┼──────────────────────────┤
│ Who calls  │ AI model decides         │ Developer hardcodes     │ Agent decides            │
├────────────┼──────────────────────────┼─────────────────────────┼──────────────────────────┤
│ Discovery  │ Server advertises tools  │ Read docs, write code   │ Agent Cards              │
├────────────┼──────────────────────────┼─────────────────────────┼──────────────────────────┤
│ Best for   │ Tool integration         │ Deterministic flows     │ Multi-agent workflows    │
├────────────┼──────────────────────────┼─────────────────────────┼──────────────────────────┤
│ Complexity │ Low (SDK handles it)     │ Low (direct HTTP)       │ Medium (protocol + tasks)│
└────────────┴──────────────────────────┴─────────────────────────┴──────────────────────────┘
```

MCP and A2A are complementary. MCP gives an agent its tools. A2A lets agents talk to each other. In practice, an agent uses MCP to access databases and APIs, and A2A to delegate work to other agents.
