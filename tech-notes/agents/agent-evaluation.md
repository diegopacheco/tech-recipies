# Agent Evaluation

## 1. What is Agent Evaluation?

Agent evaluation is the practice of systematically measuring how well an AI agent performs its intended tasks. Unlike evaluating a simple LLM (where you check if the output text is correct), evaluating agents requires assessing multi-step reasoning, tool usage, decision-making, error recovery, and end-to-end task completion. Agent evaluation is harder than model evaluation because the same task can be completed through different valid paths, and the quality of intermediate steps matters as much as the final result.

## 2. Why is it Hard?

```
┌────────────────────────┬─────────────────────────────────────────────────────────┐
│      Challenge         │                      Why it's Hard                      │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Non-determinism        │ Same input can produce different valid outputs each run  │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Multiple valid paths   │ Agent can solve the same task in many correct ways       │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Tool interactions      │ Must evaluate not just the answer but which tools used   │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Stateful behavior      │ Later steps depend on earlier steps, errors compound     │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Subjective quality     │ "Good enough" is hard to define for open-ended tasks     │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Environment dependency │ Results depend on external APIs, databases, file systems │
├────────────────────────┼─────────────────────────────────────────────────────────┤
│ Cost                   │ Running full agent evaluations is expensive (many LLM    │
│                        │ calls per test case)                                     │
└────────────────────────┴─────────────────────────────────────────────────────────┘
```

## 3. What to Evaluate

### Task Completion
Did the agent accomplish the goal? This is the most important metric. Measured as pass/fail or a completion percentage.

### Tool Usage
Did the agent use the right tools? Did it call them with correct parameters? Did it use them efficiently (minimal unnecessary calls)?

### Reasoning Quality
Did the agent follow a logical path? Did it recover from errors? Did it avoid hallucinating tool results?

### Cost Efficiency
How many tokens did the agent consume? How many LLM calls and tool calls did it make? Could the same task be done cheaper?

### Latency
How long did the agent take? Where are the bottlenecks (LLM calls, tool execution, reasoning loops)?

### Safety
Did the agent stay within its boundaries? Did it avoid harmful actions, data leaks, or unauthorized operations?

### Robustness
How does the agent handle edge cases, ambiguous inputs, tool failures, and adversarial prompts?

## 4. Evaluation Methods

### Human Evaluation
Have humans judge agent outputs on criteria like correctness, helpfulness, and safety. Gold standard for quality but expensive, slow, and doesn't scale.

### LLM-as-Judge
Use another LLM to evaluate agent outputs. Fast and scalable but introduces its own biases. Works well when the evaluation criteria are clear and can be described in a prompt.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Agent Output │────>│  Judge LLM   │────>│  Score 1-5   │
│              │     │ + Rubric     │     │  + Reasoning │
└──────────────┘     └──────────────┘     └──────────────┘
```

### Automated Test Suites
Pre-defined test cases with expected outcomes. Agent runs the task, output is compared against the expected result. Best for deterministic tasks (code generation, data extraction).

### Trajectory Evaluation
Evaluate the entire sequence of agent actions, not just the final output. Check that each step was reasonable, tools were called correctly, and the agent didn't take unnecessary detours.

### A/B Testing
Run two versions of an agent on the same tasks and compare results. Useful for measuring the impact of prompt changes, model swaps, or tool additions.

### Benchmarks
Standardized task suites that allow comparison across agents and models:

```
┌───────────────────┬───────────────────────────────────────────────────────────┐
│    Benchmark      │                     What it Tests                         │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ SWE-bench         │ Real GitHub issues - can the agent fix actual bugs?        │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ HumanEval         │ Code generation from docstrings                           │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ GAIA              │ General AI assistants on real-world multi-step tasks       │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ WebArena          │ Web navigation and task completion in realistic websites   │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ ToolBench         │ Tool selection and usage across 16K+ real-world APIs       │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ AgentBench        │ Multi-domain agent tasks (OS, DB, web, games)              │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ TAU-bench         │ Real-world agent tasks in airline and retail domains       │
├───────────────────┼───────────────────────────────────────────────────────────┤
│ METR              │ Autonomy evaluations for frontier AI safety                │
└───────────────────┴───────────────────────────────────────────────────────────┘
```

## 5. Evaluation Frameworks and Tools

```
┌─────────────────┬────────────────────────────────────┬──────────────────────────┐
│     Tool        │           What it Does             │     Best For             │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ LangSmith       │ Tracing, datasets, LLM-as-judge    │ LangChain/LangGraph apps │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Braintrust      │ Evals, logging, prompt playground   │ General agent eval       │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Arize Phoenix   │ Traces, evals, retrieval metrics    │ RAG + agent observability│
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Patronus AI     │ Hallucination detection, evals      │ Safety and correctness   │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ DeepEval        │ Open-source eval framework          │ CI/CD integration        │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Ragas           │ RAG evaluation metrics              │ Retrieval quality        │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Strands Evals   │ AWS Strands agent evaluation        │ Strands Agents           │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Google ADK Eval │ Built-in eval for ADK agents        │ Google ADK              │
├─────────────────┼────────────────────────────────────┼──────────────────────────┤
│ Inspect AI      │ Open-source eval framework by AISI  │ Safety evaluations       │
└─────────────────┴────────────────────────────────────┴──────────────────────────┘
```

## 6. Key Metrics

### Quantitative Metrics

- **Task Success Rate**: % of tasks completed correctly
- **Tool Accuracy**: % of tool calls with correct parameters
- **Token Efficiency**: Average tokens consumed per task
- **Latency (P50/P95)**: Time to complete tasks
- **Cost per Task**: Dollar cost per completed task
- **Error Recovery Rate**: % of errors the agent recovers from without human intervention
- **Hallucination Rate**: % of responses containing fabricated information

### Quality Metrics (LLM-as-Judge or Human)

- **Correctness**: Is the answer factually right?
- **Completeness**: Did the agent address all parts of the request?
- **Relevance**: Did the agent stay on topic?
- **Safety**: Did the agent avoid harmful outputs?
- **Helpfulness**: Would the user be satisfied with this response?

## 7. Code Sample - Simple Agent Eval Framework (Python)

```python
import json
from dataclasses import dataclass
from typing import Callable

@dataclass
class TestCase:
    name: str
    input: str
    expected: str
    check: Callable[[str, str], bool]

@dataclass
class EvalResult:
    name: str
    passed: bool
    actual: str
    expected: str

def exact_match(actual: str, expected: str) -> bool:
    return actual.strip().lower() == expected.strip().lower()

def contains_match(actual: str, expected: str) -> bool:
    return expected.strip().lower() in actual.strip().lower()

def run_eval(agent_fn: Callable[[str], str], tests: list[TestCase]) -> list[EvalResult]:
    results = []
    for test in tests:
        actual = agent_fn(test.input)
        passed = test.check(actual, test.expected)
        results.append(EvalResult(
            name=test.name,
            passed=passed,
            actual=actual,
            expected=test.expected,
        ))
    return results

def print_results(results: list[EvalResult]):
    passed = sum(1 for r in results if r.passed)
    total = len(results)
    print(f"\nResults: {passed}/{total} passed ({100*passed/total:.0f}%)\n")
    for r in results:
        status = "PASS" if r.passed else "FAIL"
        print(f"  [{status}] {r.name}")
        if not r.passed:
            print(f"         Expected: {r.expected}")
            print(f"         Actual:   {r.actual}")

tests = [
    TestCase("capital", "What is the capital of France?", "paris", contains_match),
    TestCase("math", "What is 2+2?", "4", contains_match),
    TestCase("code", "Write a Python hello world", "print", contains_match),
]

def my_agent(query: str) -> str:
    return "The capital of France is Paris"

results = run_eval(my_agent, tests)
print_results(results)
```

## 8. Code Sample - LLM-as-Judge (Python)

```python
from anthropic import Anthropic

client = Anthropic()

def llm_judge(task: str, agent_output: str, criteria: str) -> dict:
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=500,
        messages=[{
            "role": "user",
            "content": f"""Evaluate the following agent output.

Task: {task}
Agent Output: {agent_output}
Criteria: {criteria}

Respond with JSON only:
{{"score": 1-5, "reasoning": "brief explanation"}}"""
        }]
    )
    import json
    return json.loads(response.content[0].text)

result = llm_judge(
    task="Explain what a Python decorator is",
    agent_output="A decorator is a function that wraps another function to extend its behavior without modifying it. You use the @syntax above the function definition.",
    criteria="correctness, completeness, clarity"
)
print(f"Score: {result['score']}/5")
print(f"Reasoning: {result['reasoning']}")
```

## 9. Best Practices

- **Start simple**: Begin with pass/fail task completion tests before adding nuanced metrics
- **Test the trajectory**: Don't just check the final answer, verify the agent took reasonable steps
- **Use multiple judge models**: If using LLM-as-judge, cross-validate with different models to reduce bias
- **Regression testing**: Run evals after every prompt or tool change to catch regressions early
- **Cost tracking**: Always track cost per eval run, agent evals can get expensive fast
- **Separate unit and integration**: Test individual tools in isolation, then test the full agent workflow
- **Version everything**: Pin model versions, prompts, and tool configs so eval results are reproducible
- **Real-world data**: Supplement synthetic test cases with real user interactions when possible
