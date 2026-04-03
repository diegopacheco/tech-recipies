# Google Agent Development Kit (ADK)

https://google.github.io/adk-docs/

## 1. What is Google ADK?

Google ADK (Agent Development Kit) is an open-source framework released by Google in April 2025 for building, deploying, and orchestrating AI agents. ADK provides a code-first, modular approach to agent development with built-in support for multi-agent systems, tool integration, and deployment to Google Cloud (Vertex AI Agent Engine) or any other environment. ADK is designed to work with any LLM but has first-class integration with Google's Gemini models. It supports both Python and Java, and was built to interoperate with the A2A protocol and MCP.

- Language: Python (primary), Java
- License: Apache 2.0
- GitHub: github.com/google/adk-python, github.com/google/adk-java
- Install: `pip install google-adk`

## 2. How it Works?

ADK organizes agents into a tree-based hierarchy with four core concepts:

**Agents**: The central building block. ADK provides three types:
- `LlmAgent` (aliased as `Agent`): Uses an LLM for reasoning and tool calling
- `SequentialAgent`: Runs sub-agents one after another in order
- `LoopAgent`: Repeats sub-agents in a loop until an exit condition is met
- `ParallelAgent`: Runs sub-agents concurrently

**Tools**: Functions the agent can call. ADK supports Python functions as tools, MCP servers, OpenAPI specs, and built-in tools (Google Search, code execution, RAG).

**Sessions**: Manage conversation state and history. Each session tracks messages, agent state, and tool results. Sessions can be stored in memory or persisted to databases.

**Callbacks**: Hooks into the agent lifecycle (before/after model calls, before/after tool execution) for guardrails, logging, and custom behavior.

```
┌─────────────────────────────────────────────┐
│              Root Agent (LLM)               │
│  ┌───────────┬───────────┬───────────┐      │
│  │ Sub-Agent │ Sub-Agent │ Sub-Agent │      │
│  │ (Research)│ (Code)    │ (Review)  │      │
│  └───────────┴───────────┴───────────┘      │
│                                             │
│  Tools: [search, execute, file_read]        │
│  State: Session + Memory                    │
└─────────────────────────────────────────────┘
```

The typical flow:
1. Define agents with their instructions, tools, and sub-agents
2. Create a Runner that manages execution
3. Runner sends user input to the root agent
4. Agent reasons, calls tools, delegates to sub-agents as needed
5. Events stream back through the runner to the caller

## 3. PROS

- **Multi-Agent Native**: Built-in orchestration agents (Sequential, Loop, Parallel) make multi-agent systems easy without custom graph logic
- **MCP First-Class**: Native support for connecting to MCP servers as tool sources
- **A2A Ready**: Designed to interoperate with other agent frameworks via the A2A protocol
- **Code-First**: Agents are defined in Python/Java code, not YAML or config files
- **Flexible LLM Support**: Works with Gemini, Claude, GPT, Llama via LiteLLM integration
- **Built-in Dev UI**: `adk web` launches a local development UI for testing and debugging agents interactively
- **Google Cloud Integration**: One-command deployment to Vertex AI Agent Engine for production workloads
- **Evaluation Framework**: Built-in eval tools to test agent responses against expected outcomes
- **Callback System**: Fine-grained lifecycle hooks for guardrails, logging, and custom middleware
- **Session Management**: Built-in state management with in-memory and database-backed session stores

## 4. CONS

- **Google-Centric**: Best experience is with Gemini models and Google Cloud, other providers work but with less polish
- **Early Stage**: Released April 2025, APIs and patterns are still stabilizing
- **Documentation Gaps**: Some advanced features lack detailed documentation and real-world usage patterns
- **Agent Tree Limitation**: Hierarchical tree structure can be restrictive compared to arbitrary graph topologies (LangGraph)
- **Java SDK Lags**: Java version is behind the Python SDK in features and community support
- **Vertex AI Lock-in**: Production deployment features are tightly coupled to Google Cloud
- **Smaller Community**: Fewer third-party tutorials, plugins, and integrations compared to LangChain
- **Tool Ecosystem**: Smaller built-in tool library compared to Strands Agents or LangChain

## 5. Comparison

| Aspect | Google ADK | LangGraph | Strands Agents | CrewAI |
|---|---|---|---|---|
| Architecture | Agent tree hierarchy | Graph-based DAGs | Model-driven | Role-based crews |
| Multi-Agent | Sequential, Loop, Parallel | Supervisor, Swarm | Graph, Swarm | Crew hierarchies |
| MCP Support | Native, first-class | Via integration | Native, first-class | Limited |
| A2A Support | Native | Not built-in | Supported | Not built-in |
| Cloud Target | Google Cloud / Vertex AI | LangGraph Cloud | AWS | Cloud-agnostic |
| Dev UI | Built-in (`adk web`) | LangGraph Studio | None | None |
| Language | Python, Java | Python, JS | Python, TS | Python |
| Best For | Google Cloud teams | Complex workflows | AWS teams, fast dev | Team simulation |

## 6. Use Cases

- **Customer Support**: Multi-agent system where a router agent delegates to billing, technical, and shipping specialist agents
- **Research Pipelines**: Sequential agent that searches, extracts, summarizes, and writes reports
- **Code Generation**: Loop agent that generates code, runs tests, fixes errors, and repeats until passing
- **Data Analysis**: Parallel agent that queries multiple data sources simultaneously, then a synthesis agent combines results
- **Enterprise Workflows**: Orchestrate agents that interact with internal tools via MCP and external agents via A2A
- **Content Creation**: Pipeline of agents for research, drafting, editing, and fact-checking
- **DevOps Automation**: Agents that monitor, diagnose, and remediate infrastructure issues with Google Cloud tools

## 7. Who is Using it?

**Built by**: Google

**Cloud Integration**: Google Cloud Vertex AI, Agent Engine

**Ecosystem**: Works alongside A2A protocol partners (Salesforce, SAP, Atlassian, etc.)

**Framework Interop**: Can call LangChain agents, CrewAI agents, and Strands agents via A2A

## 8. Code Sample - Simple Agent

```python
from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService

def get_weather(city: str) -> dict:
    """Get the current weather for a city."""
    return {"city": city, "temp_c": 22, "condition": "Sunny"}

agent = Agent(
    name="weather_agent",
    model="gemini-2.0-flash",
    instruction="You are a helpful weather assistant.",
    tools=[get_weather],
)

session_service = InMemorySessionService()
runner = Runner(agent=agent, app_name="weather_app", session_service=session_service)

session = session_service.create_session(app_name="weather_app", user_id="user1")

from google.genai import types

user_msg = types.Content(
    role="user",
    parts=[types.Part(text="What is the weather in Tokyo?")]
)

for event in runner.run(user_id="user1", session_id=session.id, new_message=user_msg):
    if event.is_final_response():
        print(event.content.parts[0].text)
```

## 9. Code Sample - Multi-Agent Pipeline

```python
from google.adk.agents import Agent, SequentialAgent, LoopAgent

researcher = Agent(
    name="researcher",
    model="gemini-2.0-flash",
    instruction="Research the given topic and provide key facts.",
    tools=[web_search],
)

writer = Agent(
    name="writer",
    model="gemini-2.0-flash",
    instruction="Write a concise summary based on the research provided.",
)

reviewer = Agent(
    name="reviewer",
    model="gemini-2.0-flash",
    instruction="""Review the summary for accuracy.
    If good, respond with 'APPROVED'.
    If not, provide specific feedback for improvement.""",
)

pipeline = SequentialAgent(
    name="research_pipeline",
    sub_agents=[researcher, writer, reviewer],
)

review_loop = LoopAgent(
    name="review_loop",
    sub_agents=[writer, reviewer],
    max_iterations=3,
)
```

## 10. Code Sample - Using MCP Tools

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import MCPToolset, StdioServerParameters

agent = Agent(
    name="db_agent",
    model="gemini-2.0-flash",
    instruction="You are a database assistant. Query the database to answer questions.",
    tools=[
        MCPToolset(
            connection_params=StdioServerParameters(
                command="uvx",
                args=["mcp-server-sqlite", "--db-path", "./data.db"],
            )
        )
    ],
)
```
