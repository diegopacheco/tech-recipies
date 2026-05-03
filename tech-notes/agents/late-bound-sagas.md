# Late-Bound Sagas

## What is a Late-Bound Saga?

A Late-Bound Saga is a workflow whose execution graph does not exist when the workflow starts. The LLM synthesizes the graph one edge at a time at runtime, and each edge is committed to a durable ledger at the moment it is proposed - before it executes. The graph is append-only. The LLM does not traverse a pre-built graph; it extends it node by node, with the runtime acting as witness and executor.

The name has two halves and both matter:

- **Late-bound** - the LLM decides the workflow as it goes, instead of following a graph defined at commit time.
- **Saga** - every decision is a transaction with a compensation, written down before it runs.

The pattern is the answer to a simple question: can you keep the LLM's freedom to decide what the workflow looks like and still get durable execution? Yes - that combination is the Late-Bound Saga.

## Agent as a Loop vs Agent as a Saga

The article opens with two snippets that frame the whole argument.

How most agents are written today:

```python
def run_agent(task):
    state = State(task)
    while not state.is_terminal():
        intent = llm.plan(state)
        result = execute_tool(intent.tool)
        state.append(result)
    return state.final_answer()
```

How they should be written:

```python
@agent
def run_agent(task):
    while not done(task):
        intent = yield plan(task)
        result = yield execute(intent)
        task = yield append(task, result)
```

The syntax change is small. The runtime boundary is not. In the first version the process owns the execution state. In the second the runtime does. An agent is a saga the model writes as it runs - not a loop the model sits inside.

## Durability is Not Continuity

The article's central worked example:

> Your agent calls Stripe to charge a customer $4,000. The call succeeds. Before your code can write the row that says "Stripe call complete," the pod gets evicted. Kubernetes restarts the pod. Your agent reads the last checkpoint, which says "about to call Stripe." It calls Stripe again. You've just charged the customer $8,000.

Nothing failed. Postgres saved the checkpoint. Kubernetes restarted the pod. The bug is the gap between durability and continuity:

- **Durability** - your data survives.
- **Continuity** - your program counter survives. The runtime knows which instruction was about to execute, can determine whether the side effect already ran, and avoids running it twice.

A pod plus a database gives you durability. To get continuity, something other than your application code must own the instruction pointer. That something is a real runtime, not a library you import from inside a loop you wrote yourself.

## The Two-Plane Separation

The fix is the strictest possible separation between two planes:

- **The LLM plans.** It is a pure function from state to intent. No file handles, no network, no ability to mutate anything. It emits a description of what it would like to happen next. That description is data, not action.
- **The runtime executes.** It receives intents from the planning plane, writes them to a persistent ledger before doing anything with them, performs the side effect, writes the result back, and only then asks the LLM what to do next. The ledger - not process memory - is the source of truth.

> The LLM proposes; the runtime disposes.

When an agent needs to delegate to another agent, it does not call a function. It yields an intent and returns to the pool. The runtime catches the intent, dispatches the work, and wakes the LLM back up only when there is a result to look at.

## The Four-Write Bracket

Order matters. The wrong order is: LLM decides → tool executes → write down what happened. The right order is:

1. LLM decides
2. Write the intent
3. Tool executes
4. Write the result
5. LLM sees the result

Four ledger writes per step, bracketing the side effect on both sides. This bracket is the only structure that lets a recovering process answer "did this already happen?" without asking the outside world.

## Four Things a Loop Cannot Provide

An agent runtime has to provide at least four things a loop cannot:

| # | Property | What it means |
|---|---|---|
| a | **Intent ledger** | Records every proposed action before it executes, so "did this happen?" is answerable from outside the agent's process |
| b | **Effectively-once execution of side effects** | A crash between proposing an action and recording its result never causes the action to run twice |
| c | **Suspension and resumption across process boundaries** | An agent waiting on a human, a webhook, or another agent consumes zero compute and survives infrastructure churn |
| d | **Out-of-band signal delivery** | Signaling a running or suspended agent so a supervisor, a human, or another agent can inject new context without killing the workflow |

A Kubernetes pod gives you none of these. A Postgres checkpoint gives you a weak version of (a) and nothing else. Durable-execution runtimes such as Conductor, Temporal, and Restate give you all four - but were not designed for an LLM that decides the workflow at runtime. The Late-Bound Saga is the layer on top.

## Signals Are Cache Invalidation for Intent

Suppose on day two of a long-running saga, a supervisor agent tells it to abort. In the loop model there is no agent to tell - the process exited days ago.

In the Late-Bound Saga model the runtime is the inbox. You send a signal to the saga's ID. The runtime writes the signal, wakes the saga, and asks the LLM what to do. The LLM sees the cancellation, proposes a compensation sequence (withdraw pending requests, send polite declines, terminate), and the runtime executes each step.

> The agent's plan is a cache. The world is the source of truth. When the world changes, the cache has to be invalidated and rebuilt.

In a volatile loop you cannot, because the cache is the process and the process is blocked on a `requests.get`. In a Late-Bound Saga the cache is the ledger, the invalidation is a ledger write, and the rebuild is the next call to the LLM. The same primitive handles every other out-of-band event: rate limits, evaluator-flagged hallucinations, budget caps, a human typing "stop, use staging instead." A runtime without a signal primitive is a job queue with extra steps.

## The Monday Morning Test

The article proposes three questions to throw at any agent you have shipped:

1. If the process dies between calling a tool and recording the result, will the tool run twice on restart?
2. If a supervisor or another agent needs to tell the loop to stop and reconsider, how does the message get in?
3. Six months from now, when the agent does something weird at 3:14am on a Tuesday, where do you go to find out exactly what it saw and exactly what it decided - in a form you can replay against a different model?

If any of those make you flinch, that flinch is the gap a Late-Bound Saga is meant to close.

## Why It Matters

- An LLM-in-a-loop agent is fine for a demo. The model decides, your process executes, the state lives in RAM, and crash recovery is whatever the framework happens to do.
- A real agent runs for hours, days, or weeks; touches money or customers or production; can be cancelled, signalled, or supervised; needs an audit trail you can replay against a different model.
- The Late-Bound Saga is the pattern that lets you keep the LLM's runtime freedom and still get durability, continuity, exactly-once side effects, suspension, and signals.

## Pros

- Late-bound: the LLM still chooses the workflow shape at runtime
- Continuity in addition to durability - no double-charged Stripe calls on pod restart
- Effectively-once side effects through the four-write bracket around the tool call
- Suspended agents cost zero compute while waiting on humans, webhooks, or other agents
- Out-of-band signals (cancel, override, inject context) without killing the workflow
- Full replayable audit trail of every LLM input and output, decoupled from the model used at the time
- Compensation logic is first-class - an abort yields an undo sequence, not orphaned state

## Cons

- Requires a real durable-execution runtime (Conductor, Temporal, Restate, or similar) plus an agent layer on top of it
- More moving parts than a `while` loop - ledger, runtime, signals, compensations
- Code style shifts to yielding intents through a runtime, which feels heavier than direct calls
- Tool authors must design idempotent operations and explicit compensations
- Existing durable-execution frameworks were not built for graphs the LLM writes at runtime, so today this often means custom glue
- Operational surface grows: the ledger becomes a system of record you have to manage, back up, and audit

## Reference

- [Late-Bound Sagas: Why Your Agent Is Not an LLM in a Loop - Viren Baraiya, Agentspan](https://medium.com/agentspan/late-bound-sagas-why-your-agent-is-not-an-llm-in-a-loop-a8c50731c551)
- [Conductor - durable-execution runtime open-sourced at Netflix](https://github.com/conductor-oss/conductor)
