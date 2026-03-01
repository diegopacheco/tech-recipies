# RouteLLM

## 1. What is it?

RouteLLM is an open-source framework for intelligently routing LLM queries between a strong (expensive) model and a weak (cheap) model based on query complexity. Rather than sending every query to GPT-4 or any single model, RouteLLM uses trained ML classifiers to predict whether a given query actually needs the stronger model, cutting costs significantly while preserving response quality. Created by researchers at UC Berkeley (LMSYS), Anyscale, and Canva, the routers are trained on 55k+ real human comparisons from the Chatbot Arena dataset.

- GitHub: github.com/lm-sys/RouteLLM -- 4,600+ stars, 359 forks
- Language: Python
- Created by: Isaac Ong, Amjad Almahairi, Vincent Wu, Wei-Lin Chiang, Tianhao Wu, Joseph E. Gonzalez, M Waleed Kadous, Ion Stoica (UC Berkeley, Anyscale, Canva)
- License: Apache 2.0
- Paper: arXiv:2406.18665 (accepted at ICLR 2025)
- Install: `pip install "routellm[serve,eval]"`

## 2. Main Features

- Drop-in replacement for the OpenAI Python client with minimal code changes
- Four pre-trained router models available out of the box, trained on public Chatbot Arena preference data
- Standalone OpenAI-compatible HTTP server for use with any OpenAI client
- Threshold calibration tool to control the exact percentage of queries routed to the strong model
- Routers generalize across model pairs without retraining when switching strong/weak model combinations
- Built-in evaluation framework for benchmarking routers against MT Bench, MMLU, GSM8K
- Supports a wide range of providers via LiteLLM (Anthropic, Gemini, Bedrock, Together AI, Anyscale, Ollama)
- Extensible: implement your own router by subclassing and defining a single `calculate_strong_win_rate` method
- Pre-trained models and datasets released on HuggingFace
- Data augmentation techniques supported: golden-label datasets + LLM-judge labeling

## 3. Pros

- Reduces LLM API costs by up to 85% on MT Bench, 45% on MMLU, and 35% on GSM8K vs always using GPT-4
- Maintains ~95% of GPT-4-level performance despite the large cost savings
- Outperforms commercial LLM routing products (Martian, Unify AI) by over 40% cheaper for the same quality
- Backed by peer-reviewed academic research (ICLR 2025 paper) with rigorous benchmarking
- Fully open-source (Apache 2.0) with no vendor lock-in
- Minimal integration friction: acts as a drop-in for the OpenAI client
- Trained routers generalize across unseen model pairs (trained on GPT-4/Mixtral, works on Claude/Llama)
- Threshold is user-controllable: you decide what percentage of queries go to the strong model
- Multiple distinct routing strategies with different speed/accuracy tradeoffs
- Released datasets and models publicly on HuggingFace

## 4. Cons

- Binary routing only: routes between exactly two models (strong vs weak), does not support multi-model pools
- Requires OpenAI API key even when not using GPT-4, because some routers use OpenAI embeddings
- Threshold must be calibrated manually or via a calibration script
- Performance degrades when training data distribution differs significantly from deployment queries
- LLM-judge data augmentation is expensive and requires GPT-4 calls at scale
- The `causal_llm` router introduces additional inference latency as it runs a small LLM at routing time
- Primarily designed for chat completion tasks, not designed for streaming, tool use, or agentic workflows
- Limited to research-grade deployment, not production-hardened with enterprise features
- Community activity has slowed since the initial July 2024 release

## 5. Comparison

| Feature | RouteLLM | LiteLLM | Portkey | OpenRouter |
|---|---|---|---|---|
| Primary Purpose | ML-based query routing (cost vs quality) | OpenAI-compatible multi-provider proxy | AI gateway with observability and guardrails | Managed SaaS marketplace for 400+ models |
| Routing Mechanism | Trained ML classifiers (BERT, matrix factorization, causal LLM) | Rule-based fallbacks, load balancing, cost routing | Rule-based with fallbacks, retry, load balancing | Marketplace-driven, manual model selection |
| Open Source | Yes (Apache 2.0) | Yes (MIT) | Yes (MIT, gateway) | No (SaaS) |
| Self-hosted | Yes | Yes | Yes (OSS gateway) | No |
| Multi-model Pool | No (binary: strong/weak only) | Yes (many models) | Yes (1,600+ LLMs) | Yes (400+ models) |
| Cost Optimization | ML-driven, up to 85% savings | Manual rules and budgets | Manual rules and fallbacks | Manual selection |
| OpenAI Compatible | Yes (drop-in client) | Yes (proxy server) | Yes (proxy) | Yes (API) |
| Observability | Minimal | Basic logging, Admin UI | Full (traces, metrics, dashboards) | Basic |
| Enterprise Features | None | Rate limits, budgets, Admin UI | RBAC, audit logs, guardrails, prompt management | Billing abstraction |
| Backed by Research | Yes (ICLR 2025 paper) | No | No | No |
| Best For | Cost optimization between 2 models | Self-hosted enterprise gateway | Production enterprise GenAI | Zero-infra multi-model access |

## 6. Why is it unique?

RouteLLM is the only open-source framework that treats LLM routing as a machine learning problem trained on human preference data, rather than a rule-based or heuristic system. Human preference data from Chatbot Arena (55k+ real comparisons) encodes implicit knowledge about which queries require a stronger model. By learning from this data, a lightweight classifier can predict before sending a query whether the cheap model will produce a good-enough answer. This is fundamentally different from LiteLLM, Portkey, and OpenRouter which all use static rules, cost thresholds, or simple fallbacks. It was the first work to formally define and benchmark the LLM routing problem, accepted at ICLR 2025. The generalization result is especially notable: routers trained on GPT-4/Mixtral transfer to completely different model pairs without retraining.

## 7. Simple Usage

```python
import os
from routellm.controller import Controller

os.environ["OPENAI_API_KEY"] = "sk-XXXXXX"
os.environ["ANYSCALE_API_KEY"] = "esecret_XXXXXX"

client = Controller(
    routers=["mf"],
    strong_model="gpt-4-1106-preview",
    weak_model="anyscale/mistralai/Mixtral-8x7B-Instruct-v0.1",
)

response = client.chat.completions.create(
    model="router-mf-0.11593",
    messages=[{"role": "user", "content": "What is the capital of France?"}]
)

print(response.choices[0].message.content)
```

The model string `"router-mf-0.11593"` means:
- `mf` = matrix factorization router (recommended)
- `0.11593` = threshold (calibrated so ~50% of queries go to the strong model)

To calibrate the threshold:

```bash
python -m routellm.calibrate_threshold \
  --routers mf \
  --strong-model-pct 0.5 \
  --config config.yaml
```

To launch as a standalone OpenAI-compatible server:

```bash
python -m routellm.openai_server \
  --routers mf \
  --strong-model gpt-4-1106-preview \
  --weak-model anyscale/mistralai/Mixtral-8x7B-Instruct-v0.1
```

Install and run:
```bash
pip install "routellm[serve,eval]"
python main.py
```
