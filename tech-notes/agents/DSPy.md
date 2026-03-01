# DSPy

## 1. What is it?

DSPy (Declarative Self-improving Python) is an open-source framework from Stanford NLP for programming -- not prompting -- language models. Instead of manually writing and tuning prompt strings, you define typed input/output signatures and let DSPy compile and optimize the prompts (or fine-tune weights) automatically. It shifts LLM development from string engineering to structured, modular programming with built-in optimization.

- GitHub: github.com/stanfordnlp/dspy -- 23,000+ stars
- Language: Python
- Latest version: 3.1.3
- License: MIT
- Website: dspy.ai
- Install: `pip install dspy`
- Monthly pip downloads: 160,000+

## 2. Main Features

- Signatures: declarative input/output specs (e.g., `"question -> answer"`) that replace hand-crafted prompts
- Modules: composable building blocks -- dspy.Predict, dspy.ChainOfThought, dspy.ReAct, dspy.ProgramOfThought
- Optimizers (Teleprompters): algorithms that automatically tune prompts and few-shot examples -- MIPROv2, BootstrapFewShot, BetterTogether, LeReT
- Assertions: runtime constraints on LM outputs (type checks, format validation, semantic guards)
- dspy.Reasoning: captures native reasoning from reasoning models (o1, DeepSeek-R1, etc.)
- Multi-provider: OpenAI, Anthropic, Google, Azure, Bedrock, Ollama, vLLM, llama.cpp, Together AI
- Structured output: typed fields with automatic parsing and validation
- LM usage tracking: built-in token/cost tracking across all module calls (since 2.6.16)
- RAG support: retrievers for Qdrant, Weaviate, Pinecone, ChromaDB, ColBERTv2
- Agent loops: dspy.ReAct module for tool-using agent patterns
- Evaluation-driven: optimize against metrics on labeled data, not gut feeling
- Serialization: save/load optimized programs as JSON for deployment

## 3. Pros

- Eliminates prompt engineering: define what you want, not how to ask for it
- Reproducible: optimized programs are serializable and version-controllable
- Composable: modules snap together like functions, enabling complex pipelines from simple parts
- Automatic optimization: MIPROv2 jointly optimizes instructions + few-shot examples using Bayesian search
- Model-agnostic: switch LLM providers without rewriting prompts
- Evaluation-first: forces you to define metrics, leading to measurable quality improvements
- Small core: four concepts (LMs, Signatures, Modules, Optimizers) cover the entire framework
- Academic rigor: backed by peer-reviewed research from Stanford NLP
- Growing ecosystem: STORM, IReRa, DSPy Assertions built on top by the community

## 4. Cons

- Not a production framework: focused on prompt optimization, not deployment infrastructure
- Learning curve: the compile/optimize paradigm is unfamiliar to most developers
- Requires labeled data: optimizers need training examples with ground truth to work well
- Python-only: no Java, TypeScript, Go, or Rust SDK
- Research-oriented: API changes between major versions (2.x to 3.x had breaking changes)
- Limited tool ecosystem: fewer pre-built integrations compared to LangChain or CrewAI
- Optimization cost: running MIPROv2 consumes significant tokens during the compilation phase
- Not for simple tasks: overkill for single-shot prompts or simple Q&A
- Smaller community: 23K stars vs LangChain's 95K or CrewAI's 44K

## 5. Comparison

| Aspect | DSPy | CrewAI | Strands Agents | LangChain/LangGraph | Spring AI |
|---|---|---|---|---|---|
| Language | Python | Python | Python, TypeScript | Python, JS/TS | Java (Spring Boot) |
| Paradigm | Declarative signatures + optimization | Role-based agent teams | Model-driven agentic loop | Chain/graph-based workflows | Spring-native AI integration |
| Core Idea | Program, don't prompt | Agents with roles collaborate | LLM decides tool orchestration | Composable chains and graphs | AI as Spring integration |
| Prompt Engineering | Automated by optimizers | Manual (role/goal/backstory) | Manual (system prompt) | Manual (prompt templates) | Manual (prompt templates) |
| Multi-Agent | Basic (module composition) | First-class (crews + delegation) | Graph, Swarm, Workflow | LangGraph multi-agent | Orchestrator pattern |
| Optimization | MIPROv2, BootstrapFewShot, etc. | None built-in | None built-in | None built-in | None built-in |
| Tool Ecosystem | Small (retrievers, basic tools) | 100+ built-in tools | 20+ built-in + MCP | 600+ integrations | Spring ecosystem |
| Best For | Optimizing LM pipelines for quality | Multi-agent team orchestration | AWS-native agent dev | Complex workflow orchestration | Java enterprise AI apps |

## 6. Why is it unique?

DSPy is the only framework that treats prompt engineering as a compilation problem. While every other framework (LangChain, CrewAI, Strands) requires you to manually write and iterate on prompts, DSPy lets you define typed signatures and then compiles optimized prompts automatically using your data and metrics. The MIPROv2 optimizer uses Bayesian search to jointly optimize instructions and few-shot examples -- something no other framework does. This means your prompts improve systematically rather than through trial and error. DSPy modules compose like functions in a programming language, enabling pipelines where each step is independently optimizable. The framework forces evaluation-driven development: you must define what "good" looks like (a metric), and the optimizer finds the prompt configuration that maximizes it. This is a fundamentally different paradigm from the rest of the AI framework ecosystem.

## 7. Simple Usage

Basic prediction with a signature:
```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

classify = dspy.Predict("sentence -> sentiment: str")
result = classify(sentence="DSPy is a great framework")
print(result.sentiment)
```

Using ChainOfThought for better reasoning:
```python
import dspy

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

cot = dspy.ChainOfThought("question -> answer")
result = cot(question="What is the capital of France?")
print(result.reasoning)
print(result.answer)
```

Optimizing with MIPROv2:
```python
import dspy
from dspy.teleprompt import MIPROv2

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

trainset = [
    dspy.Example(question="2+2", answer="4").with_inputs("question"),
    dspy.Example(question="3*5", answer="15").with_inputs("question"),
]

def exact_match(example, pred, trace=None):
    return example.answer.strip() == pred.answer.strip()

program = dspy.ChainOfThought("question -> answer")
optimizer = MIPROv2(metric=exact_match, auto="light")
optimized = optimizer.compile(program, trainset=trainset)

optimized.save("optimized_math.json")

result = optimized(question="7*8")
print(result.answer)
```

Custom module with typed signature:
```python
import dspy

class Summarizer(dspy.Module):
    def __init__(self):
        self.summarize = dspy.ChainOfThought("document -> summary: str")
        self.assess = dspy.Predict("summary -> quality_score: float")

    def forward(self, document):
        summary = self.summarize(document=document)
        score = self.assess(summary=summary.summary)
        return dspy.Prediction(summary=summary.summary, score=score.quality_score)

lm = dspy.LM("openai/gpt-4o-mini")
dspy.configure(lm=lm)

summarizer = Summarizer()
result = summarizer(document="DSPy is a framework from Stanford...")
print(result.summary)
print(result.score)
```
