# LangGraph

https://langchain-ai.github.io/langgraph/

## 1. What is LangGraph?

LangGraph is a framework by LangChain for building stateful, multi-agent applications using a graph-based architecture. Instead of linear chains, you define your agent logic as a directed graph where nodes are functions (LLM calls, tool executions, custom logic) and edges define the flow between them. LangGraph gives you fine-grained control over both the flow and the state of your agent application. It is separate from the core LangChain library and can be used independently. LangGraph was released in January 2024 and has become the primary way to build complex agent workflows in the LangChain ecosystem.

- Language: Python (primary), JavaScript/TypeScript
- License: MIT
- GitHub: github.com/langchain-ai/langgraph (12,000+ stars)
- Install: `pip install langgraph`

## 2. How it Works?

LangGraph applications are built around three core concepts:

**State**: A shared data structure (typically a TypedDict or Pydantic model) that gets passed through the graph. Every node reads from and writes to this state. State is the single source of truth for the entire workflow.

**Nodes**: Functions that perform work. Each node takes the current state, does something (calls an LLM, executes a tool, runs custom logic), and returns state updates. Nodes are where the actual computation happens.

**Edges**: Connections between nodes that define execution flow. Edges can be static (always go from A to B) or conditional (go to B or C based on state). Conditional edges are what enable dynamic agent behavior.

```
┌─────────────────────────────────────────────────┐
│                  StateGraph                      │
│                                                  │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐     │
│  │  START   │───>│  Agent  │───>│  Tools  │     │
│  └─────────┘    └────┬────┘    └────┬────┘     │
│                      │              │           │
│                      │   ┌──────────┘           │
│                      v   v                      │
│                 ┌─────────┐                     │
│                 │   END   │                     │
│                 └─────────┘                     │
└─────────────────────────────────────────────────┘
```

The typical flow:
1. Define a State schema with all data your workflow needs
2. Create nodes as functions that process and update state
3. Connect nodes with edges (static or conditional)
4. Compile the graph into a runnable application
5. Invoke with initial state, the graph executes nodes following edges until it reaches END

Key mechanisms:
- **Checkpointing**: Every state transition is saved, enabling time-travel debugging, human-in-the-loop, and recovery from failures
- **Persistence**: Built-in support for persisting state across conversations using memory stores
- **Streaming**: Stream tokens, node outputs, and state updates in real-time
- **Subgraphs**: Nest graphs inside graphs for modular, reusable agent components

## 3. PROS

- **Full Control**: Unlike model-driven frameworks, you explicitly define execution paths and decision points
- **Cycles Support**: First-class support for loops and cycles, essential for agent retry logic and iterative refinement
- **Checkpointing**: Built-in state persistence at every step enables human-in-the-loop, time-travel debugging, and fault recovery
- **Streaming**: Fine-grained streaming of tokens, node outputs, and state updates
- **Multi-Agent**: Native support for supervisor, swarm, and hierarchical multi-agent patterns
- **Debuggable**: Graph structure makes it easy to visualize, test, and reason about agent behavior
- **LangChain Integration**: Seamless use of LangChain's model providers, tools, and retrievers
- **Model Agnostic**: Works with any LLM provider (OpenAI, Anthropic, Google, local models)
- **LangGraph Platform**: Optional managed deployment with LangGraph Cloud, Studio for visualization, and LangSmith for observability
- **Mature Ecosystem**: Large community, extensive documentation, and many reference implementations

## 4. CONS

- **Complexity**: Graph-based thinking is harder to reason about than simple sequential code for basic use cases
- **Verbose**: Even simple agents require significant boilerplate compared to model-driven frameworks like Strands
- **LangChain Coupling**: While usable standalone, many features work best within the LangChain ecosystem
- **Learning Curve**: Understanding state management, conditional edges, checkpointing, and subgraphs takes time
- **Over-Engineering Risk**: Developers tend to build complex graphs when a simple prompt-and-tools approach would suffice
- **Performance Overhead**: Graph traversal, state serialization, and checkpointing add latency compared to direct LLM calls
- **State Management Complexity**: As state grows, managing state schema changes and migrations becomes difficult
- **Debugging Deep Graphs**: While the structure helps, deeply nested subgraphs with many conditional edges can be hard to trace
- **Vendor Lock-in Risk**: LangGraph Platform and LangSmith create dependency on LangChain's commercial offerings

## 5. Comparison

| Aspect | LangGraph | Strands Agents | CrewAI | Spring AI |
|---|---|---|---|---|
| Architecture | Graph-based DAGs | Model-driven | Role-based crews | Spring Boot patterns |
| Control Style | Explicit edges | LLM decides | Task delegation | Orchestrator config |
| State Management | Built-in checkpointing | Conversation memory | Shared crew memory | Spring state |
| Best For | Complex workflows | Fast agent dev | Team simulation | Java enterprise |
| Learning Curve | Steep | Low | Moderate | Moderate |
| Cycles/Loops | First-class | LLM loop | Limited | Limited |
| Multi-Agent | Supervisor, Swarm | Graph, Swarm | Hierarchical crews | Orchestrator-Worker |
| Language | Python, JS | Python, TS | Python | Java/JVM |

## 6. Use Cases

- **ReAct Agents**: Build agents that reason, act, observe, and loop until they reach an answer
- **Multi-Step Research**: Orchestrate search, retrieval, analysis, and synthesis in a controlled pipeline
- **Human-in-the-Loop**: Pause execution at any node for human review or approval before continuing
- **Code Generation Pipelines**: Generate code -> test -> fix errors -> re-test in a loop until tests pass
- **Customer Support Bots**: Route conversations through classification, retrieval, response generation, and escalation nodes
- **Data Processing Pipelines**: Extract, transform, validate, and load data with LLM-powered steps and error handling
- **Multi-Agent Debate**: Multiple agents argue different perspectives, a judge agent synthesizes the conclusion
- **Document Processing**: Parse, classify, extract entities, validate, and store documents with conditional routing

## 7. Who is Using it?

**Built by**: LangChain Inc.

**Companies**: LinkedIn, Elastic, Replit, Uber, McKinsey, Deloitte, Rakuten

**Frameworks that integrate**: CrewAI (uses LangGraph internally), Flowise, LangFlow

**Cloud Platforms**: AWS Bedrock (via LangChain integration), Google Vertex AI, Azure AI

## 8. Code Sample - Basic ReAct Agent

```python
from typing import Annotated
from typing_extensions import TypedDict

from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode, tools_condition
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

@tool
def search(query: str) -> str:
    """Search the web for information."""
    return f"Results for: {query} - Python was created by Guido van Rossum in 1991"

class State(TypedDict):
    messages: Annotated[list, add_messages]

model = ChatAnthropic(model="claude-sonnet-4-20250514").bind_tools([search])

def agent(state: State) -> State:
    response = model.invoke(state["messages"])
    return {"messages": [response]}

graph = StateGraph(State)
graph.add_node("agent", agent)
graph.add_node("tools", ToolNode([search]))
graph.add_edge(START, "agent")
graph.add_conditional_edges("agent", tools_condition)
graph.add_edge("tools", "agent")

app = graph.compile()
result = app.invoke({"messages": [("user", "Who created Python?")]})
print(result["messages"][-1].content)
```

## 9. Code Sample - Multi-Agent with Supervisor

```python
from typing import Annotated
from typing_extensions import TypedDict

from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage, SystemMessage

class State(TypedDict):
    messages: Annotated[list, add_messages]
    next_agent: str

model = ChatAnthropic(model="claude-sonnet-4-20250514")

def supervisor(state: State) -> State:
    system = SystemMessage(content="""You are a supervisor routing tasks.
    Respond with ONLY one of: researcher, coder, FINISH""")
    response = model.invoke([system] + state["messages"])
    return {"next_agent": response.content.strip(), "messages": [response]}

def researcher(state: State) -> State:
    system = SystemMessage(content="You are a research assistant. Provide factual answers.")
    response = model.invoke([system] + state["messages"])
    return {"messages": [response]}

def coder(state: State) -> State:
    system = SystemMessage(content="You are a coding assistant. Write clean code.")
    response = model.invoke([system] + state["messages"])
    return {"messages": [response]}

def route(state: State) -> str:
    next_agent = state.get("next_agent", "FINISH")
    if next_agent == "FINISH":
        return END
    return next_agent

graph = StateGraph(State)
graph.add_node("supervisor", supervisor)
graph.add_node("researcher", researcher)
graph.add_node("coder", coder)

graph.add_edge(START, "supervisor")
graph.add_conditional_edges("supervisor", route, ["researcher", "coder", END])
graph.add_edge("researcher", "supervisor")
graph.add_edge("coder", "supervisor")

app = graph.compile()
result = app.invoke({"messages": [HumanMessage(content="Write a fibonacci function in Python")]})
```

## 10. Code Sample - With Checkpointing (Human-in-the-Loop)

```python
from langgraph.checkpoint.memory import MemorySaver

memory = MemorySaver()
app = graph.compile(checkpointer=memory, interrupt_before=["tools"])

config = {"configurable": {"thread_id": "session-1"}}
result = app.invoke({"messages": [("user", "Search for LangGraph docs")]}, config)

state = app.get_state(config)
print(f"Paused before: {state.next}")

app.invoke(None, config)
```
