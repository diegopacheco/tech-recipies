# LiteLLM Agent Platform

## What is it?

LiteLLM Agent Platform (LAP) is self-hosted infrastructure for running coding agents - Claude Code, Codex, Hermes, anything - inside **isolated Kubernetes sandboxes** fronted by a **credential vault**. From BerriAI (the team behind the LiteLLM AI gateway), open-sourced in May 2026 as an alpha public preview under the MIT license.

The headline idea: an agent can run with **bypass-permissions on** (full autonomy, no approval prompts) **without ever seeing your real keys**. The sandbox's environment holds only stub credentials; the vault swaps them for real keys on every outbound connection. You get the speed of an unsupervised agent with the blast radius of a locked box. Use it from the `lap` CLI, a web UI, or the API directly.

BerriAI's framing: "we wanted a managed agent solution, but fully self-hosted." It manages two things teams otherwise build themselves - different sandboxes for different teams/contexts, and session continuity across pod restarts and upgrades.

## The core trick: vault proxy

This is what makes LAP distinctive. When you open a sandbox, the pod's environment contains only **stub credentials** - e.g. `GITHUB_TOKEN=stub_github_a8f1`. The agent uses those stubs normally. On every outbound TLS connection, the **vault intercepts and swaps the stub for the real key**. So:

- The agent (and anything it executes, including injected/malicious code) never has the real secret in its environment or memory.
- You can run with `--dangerously-skip-permissions` / bypass-permissions on, because a leaked or exfiltrated credential is just a useless stub.
- Secrets, tools, and access scopes are isolated *between teams* at the infrastructure layer.

This is a different safety philosophy from [[claude-auto-mode]]. Auto mode keeps a classifier *gate* between the agent and dangerous actions (judge intent, then allow/block). LAP removes the gate entirely and instead makes the *environment* safe - the agent can do anything, but it has nothing real to leak and runs in a disposable box. They are complementary layers of defense in depth, not competitors.

## Architecture

| Component | Role |
|---|---|
| **agent-sandbox CRD** | Sandboxes run on Kubernetes via the [`kubernetes-sigs/agent-sandbox`](https://github.com/kubernetes-sigs/agent-sandbox) CRD - each agent environment is a native Kubernetes resource with its own lifecycle |
| **Credential vault** | Proxies outbound TLS, swapping stub credentials for real keys so the agent never holds them |
| **Postgres** | Persistent store backing session state, so work survives container restarts/upgrades |
| **Worker** | Dedicated process for async tasks |
| **Web (`:3000`)** | Next.js dashboard to create agents, chat with them, check status |
| **`lap` CLI** | Terminal client that opens a sandbox and attaches your local TTY to it |
| **LiteLLM gateway** | Model access - LAP requires a LiteLLM gateway URL, giving it 100+ providers (Bedrock, Azure, OpenAI, Vertex, Anthropic, etc.) |

Session continuity is the operational selling point: because state lives in Postgres rather than in the pod, an agent picks up where it left off if its container restarts.

## How you use it

### `lap` CLI

```
git clone https://github.com/BerriAI/litellm-agent-platform.git
cd litellm-agent-platform/cli && npm install
ln -sf "$PWD/bin/lap.mjs" ~/.local/bin/lap

lap login
lap claude-code-cli1
```

`lap claude-code-cli1` spins up a fresh Kubernetes pod running Claude Code, attaches your local terminal to its TTY over a WebSocket, and drops you straight into the agent. The pod has only stub credentials; the vault swaps real keys on every outbound TLS call. Press `Ctrl-D` to detach - the session stays alive for **24h**.

### Self-hosting (local dev)

```
bin/kind-up.sh
docker compose up
```

`bin/kind-up.sh` is idempotent: it provisions a `kind` cluster named `agent-sbx`, installs the agent-sandbox controller, and loads the harness image. `docker compose up` boots Postgres, runs the schema migration, and starts the web (`:3000`) and worker processes. Prereqs: Docker Desktop, `kind`, `kubectl`, `helm`, and a LiteLLM gateway URL. Open `localhost:3000` to create an agent, then point `lap` at it.

### Other surfaces

- **Web UI** - create agents, chat, monitor status.
- **Developer API** - create an agent, open a session, send a message, read the reply, all via `curl`.
- **Slack channel** - a `channels/slack` integration to drive agents from Slack.

## Supported harnesses

LAP runs the agent [[harness]] of your choice inside the sandbox; the platform is the operational shell around it. Quickstarts ship for:

- **[[claude-code]]** - Anthropic's CLI coding agent
- **Codex** - OpenAI's coding agent
- **[[hermes-agent]]** - Nous Research's self-hosted agent

The README is explicit that it's harness-agnostic ("Claude Code, Codex, Hermes anything"), so the three are starting points rather than a closed list.

## Why it matters

Running coding agents in production has a credential problem that nobody solves cleanly: to be useful an agent needs real GitHub tokens, cloud keys, and API secrets, but the moment it has them, an autonomous (or prompt-injected) agent can leak or misuse them. The usual answers are either heavy human-in-the-loop approval (slow) or trusting the agent (reckless). LAP's vault-proxy approach is a genuinely different answer: **give the agent stubs, swap at the network edge, and isolate the whole thing in a disposable Kubernetes pod.** That lets you run agents with full autonomy *and* keep secrets out of their reach - and do it on your own infrastructure rather than a vendor's cloud.

It pairs naturally with BerriAI's existing LiteLLM gateway (model access + cost/observability) the way an LLM gateway like [[merge-ai-agent-gateway]] sits under application traffic - LAP is the *agent execution* layer, the gateway is the *model access* layer.

The honest caveats: it's **alpha**, Kubernetes-centric (real activation energy - you need kind/kubectl/helm and a running LiteLLM gateway just to start), and the vault only protects what flows over outbound TLS - it's not a substitute for least-privilege scoping of the stubbed credentials themselves. The self-hosting burden (cluster, Postgres, vault, worker) is yours to operate. It's aimed squarely at technical teams that want managed-agent ergonomics without giving up self-hosting or handing real keys to an autonomous agent.

## Links

* https://github.com/BerriAI/litellm-agent-platform
* https://docs.litellm-agent-platform.ai/
* https://docs.litellm.ai/blog/agent-platform-alpha
* https://github.com/kubernetes-sigs/agent-sandbox
* https://github.com/BerriAI/litellm
* https://www.marktechpost.com/2026/05/16/meet-litellm-agent-platform-a-kubernetes-based-self-hosted-infrastructure-layer-for-isolated-agent-sandboxes-and-persistent-session-management-in-production/
