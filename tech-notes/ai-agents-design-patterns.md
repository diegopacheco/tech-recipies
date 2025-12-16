# AI Agents Design Patterns

1. ReAct (Reasoning + Acting) - Agents alternate between reasoning about the task and taking actions, documenting their thought process before each action.

2. Chain-of-Thought (CoT) - Breaking down complex problems into intermediate reasoning steps before arriving at a final answer.

3. Tree of Thoughts - Exploring multiple reasoning paths simultaneously and selecting the most promising branches, enabling backtracking and strategic exploration.

4. Reflection/Self-Critique - Agents review their own outputs and reasoning to identify errors, improve quality, and refine responses iteratively.

5. Tool Use/Function Calling - Equipping agents with external tools (APIs, databases, calculators) they can invoke to extend their capabilities beyond text generation.

6. Multi-Agent Collaboration - Multiple specialized agents work together, each handling different aspects of a task (e.g., researcher, writer, critic).

7. Retrieval-Augmented Generation (RAG) - Agents retrieve relevant information from external knowledge bases before generating responses to ground outputs in facts.

8. Memory Systems - Implementing short-term, long-term, and episodic memory to maintain context across conversations and learn from past interactions.

9. Planning and Decomposition - Breaking complex goals into smaller sub-tasks and creating execution plans before taking action.

10. Iterative Refinement - Agents generate initial outputs, then progressively improve them through multiple revision cycles.

11. Constitutional AI - Embedding principles and rules that guide agent behavior, enabling self-correction against defined values.

12. Prompt Chaining - Linking multiple prompts in sequence where each step's output becomes the next step's input, creating complex workflows.

13. Router Pattern - Using a classifier or routing agent to direct queries to the most appropriate specialized agent or tool.

14. Evaluator-Optimizer Loop - One component evaluates outputs while another optimizes them, creating a feedback cycle for continuous improvement.

15. Human-in-the-Loop (HITL) - Incorporating human feedback at critical decision points to guide, correct, or approve agent actions.

16. Orchestrator-Worker - A central orchestrator delegates tasks to specialized worker agents and synthesizes their outputs.

17. Finite State Machines - Agents transition through defined states based on conditions, providing structured control flow for complex processes.

18. Goal-Driven/OODA Loop - Agents operate in observe-orient-decide-act cycles, continuously adjusting behavior based on goal progress.

19. Feedback Loops - Incorporating output quality metrics and user feedback to adjust agent behavior and improve over time.

20. Context Window Management - Strategies for handling limited context (summarization, semantic compression, selective retention) to maintain relevant information.