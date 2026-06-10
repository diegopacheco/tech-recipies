# Claude Code Sandboxing

## What is it?

"Sandbox for Claude" is not one product or one setting. It is a spectrum of containment that decides how much damage an agent can do when it runs commands, writes files, and calls the network on your behalf. As coding agents moved from chat into autonomous loops that execute shell, edit repos, and hit APIs, the core trade-off became: how much autonomy do you grant versus how much blast radius do you accept.

The spectrum, from weakest to strongest:

| Layer | Mechanism | Protects against | Main weakness |
|---|---|---|---|
| Permission prompts | Claude asks before risky actions | Obvious mistakes | Approval fatigue: users approve 93% and stop reading |
| Intent classification | Model-based gate judges each action (Auto Mode) | Overeager/misaligned actions, prompt injection | ~17% of dangerous actions still slip through |
| Local OS sandbox | macOS Seatbelt / Linux bubblewrap | Filesystem + network blast radius of subprocesses | Mostly Bash; MCP, hooks, mounted secrets can leak |
| Container / devcontainer | Docker boundary | Whole-environment separation | Docker socket, mounted creds, writable bind mounts |
| VM / microVM | Hardware-level isolation (Firecracker, gVisor, Apple VZ) | Untrusted repos, unattended agents | Ops cost, network/secret policy still on you |
| Cloud sandbox | Provider-managed isolated environment + snapshots + egress proxy + credential proxy | Customer code, parallel agents, exfiltration | Privacy/compliance, lock-in, cost |

The biggest practical win for Claude Code is that strong containment makes `--dangerously-skip-permissions` ("YOLO mode") survivable: the model runs build/test/edit loops with fewer interruptions while the environment caps what a mistake or a malicious prompt injection can touch. This is a different axis from [[claude-auto-mode]], which does not isolate at all — it judges intent. Sandboxing and intent classification are complementary layers of defense in depth, not substitutes. Anthropic's own framing pairs OS-level isolation with real-time classification.

## Starting point: Simon Willison on Fly Sprites.dev

Simon Willison's January 9, 2026 post frames the problem sharply. He predicted "we're due a Challenger disaster with respect to coding agent security" because of how casually people run agents in YOLO mode. His conclusion: "The safe way to run YOLO mode is in a robust sandbox, where the worst thing that can happen is the sandbox gets messed up and you have to throw it away and get another one."

Fly.io's **Sprites.dev** is interesting because it solves both of Willison's pet problems at once: a safe development environment for coding agents, and a JSON API for executing untrusted code. Verified details:

- **Persistent Linux microVMs** built on AWS Firecracker. Fly CEO Kurt Mackey argues that "ephemeral sandboxes are obsolete" — the state of the art was a read-only sandbox, and Fly is betting on a permanent, mutable workspace instead.
- **Checkpoint / restore in ~300ms** using copy-on-write storage. The agent or developer can checkpoint, run untrusted code, then roll back to a clean state. The last 5 checkpoints mount at `/.sprite/checkpoints`; restore is async and restarts the environment.
- **Preinstalled agents**: Claude Code, Codex CLI, Gemini CLI, Python 3.13, Node.js 22.20. The first `claude` run signs you into your existing Anthropic account.
- **Port forwarding**: a server on the Sprite is reachable at `localhost:8080` on your machine; each Sprite also exposes a public URL.
- **Scale-to-zero billing**: Sprites sleep after 30 seconds of inactivity, wake in 1–12 seconds, and bill only for CPU-hours, RAM-hours, and GB-hours of storage while awake.
- **Sandbox API**: `PUT /v1/sprites/{name}` to create, `POST .../exec` to run commands, plus checkpoint/rollback over the API.
- Clever touch: the in-VM docs are shipped as Claude **Skills**, so Claude on the machine can talk you through opening ports or managing checkpoints.

## What Anthropic does

Anthropic's own write-up "How we contain Claude across products" describes **three isolation patterns, one per surface** — and a hard-won lesson: "the weakest layer is the one you built yourself." Across deployments, standard primitives (gVisor, seccomp, hypervisors) held firm while Anthropic's custom proxy code was where bugs appeared.

### Claude Code local `/sandbox`

A sandboxed Bash tool built into Claude Code (shipped Nov 2025), designed to reduce permission prompts while restricting what commands can do.

- Runs on macOS, Linux, and WSL2.
- **macOS** uses the built-in **Seatbelt** framework (`sandbox-exec`) — nothing to install.
- **Linux / WSL2** use **bubblewrap** (unprivileged filesystem isolation) plus **socat** (relays network through the proxy).
- Filesystem isolation allows read/write to the current working directory, blocks modification outside it. Network isolation routes all egress through a Unix domain socket to a proxy outside the sandbox, with domain allowlists.
- Enterprise settings can require the sandbox and forbid unsandboxed fallback.
- **Limitation**: it is primarily a *Bash* boundary. File tools, hooks, MCP servers, browser/computer-use tools, and host-mounted secrets are not automatically contained.

### Anthropic Sandbox Runtime (`srt`)

Open-source research preview: `anthropic-experimental/sandbox-runtime` on GitHub, published as `@anthropic-ai/sandbox-runtime` on npm (Python build on PyPI). It enforces filesystem and network restrictions on **arbitrary processes** at the OS level without a container, using the same primitives (`sandbox-exec` on macOS, bubblewrap on Linux) plus proxy-based network filtering and Unix-socket restrictions.

Why it matters: it is broader than `/sandbox`. It can wrap an entire process tree — agents, **local MCP servers**, bash commands, custom tools — not just Claude Code's Bash tool. (It is early: a known issue, #139, reported `srt` leaking dotfiles while running commands and on SIGKILL — treat it as a preview, not a hardened boundary.)

### Devcontainers

Anthropic documents running Claude Code inside a Docker devcontainer for whole-environment isolation: standardized setup, a container boundary, and optional egress firewall. Risks: mounting `~/.claude`, SSH keys, cloud creds, or the Docker socket re-opens the escape paths a container was meant to close.

### Claude Code on the web

Hosted coding sessions run in an Anthropic-managed isolated VM: clone a GitHub repo, run setup, do the task, push a branch / open a PR. Git credentials are scoped and proxied rather than placed in the sandbox; network is allowlisted; branch/repo restrictions cap blast radius.

### claude.ai code execution

When Claude runs code inside claude.ai, it runs in a **gVisor container** on isolated server-side infrastructure — gVisor is a userspace Go "kernel" that intercepts syscalls. No code touches your machine; the filesystem is **ephemeral per session**. Egress goes through a proxy that validates a JWT carrying a host allowlist (package registries, GitHub, Anthropic API) and expires in ~4 hours. Safe, but it is not a persistent dev workstation and cannot see your real repo.

### Auto Mode (the classification layer)

Separate from isolation, Anthropic shipped **Auto Mode** (Mar 25, 2026): a Sonnet-4.6 transcript classifier plus an input-side prompt-injection probe that gate each Tier-3 action against user intent, replacing the human approval click without removing the gate. It exists because users approve 93% of prompts and stop reading. It does not isolate — it judges — so it complements a sandbox rather than replacing it. Full detail in [[claude-auto-mode]]. Note: input docs that frame "a hardened sandbox lets Claude run in Auto Mode safely" conflate two different mechanisms — isolation bounds *what can happen*, the classifier decides *whether to allow it*.

## Sandbox for the Claude CLI (Claude Code)

Claude Code runs with your shell's privileges by default. Containment options, weakest to strongest: built-in `/sandbox` (Bash boundary) → `srt` (process-tree boundary, including MCP) → devcontainer / Docker Sandbox → local VM (Lima/Colima with no home mount and tight egress) → cloud sandbox (Sprites, E2B, Vercel, Cloudflare, Modal, Daytona, Runloop). For an untrusted repo, clone it inside a disposable VM or cloud sandbox — never on your host with real credentials present.

## Sandbox for Claude Desktop (Cowork)

**Claude Cowork** (research preview Jan 2026, GA Apr 2026) brings agentic computer-use to the desktop app for non-technical users. Its containment is stronger than plain MCP:

- Runs inside a **full hypervisor VM** — Apple's Virtualization.framework (`VZVirtualMachine`) on macOS, HCS on Windows — booting a custom Linux root filesystem with its own kernel, filesystem, and process table.
- File access uses **mount modes**: read-only, read-write, and read-write-no-delete, so you choose how much the agent can touch.
- An **egress MITM proxy** inside the VM intercepts traffic to Anthropic's API and only passes requests carrying the VM's provisioned session token. Host keychain stays separate.
- A later "host-mode" architecture moved the agent loop *outside* the VM (keeping code execution inside) so Claude keeps responding even if the VM crashes — trading some isolation for reliability.

Plain Claude Desktop + MCP is a different risk surface: local MCP servers are programs that run with your user permissions. Treat installing one like installing a CLI tool, not enabling a prompt feature. Prefer verified Desktop Extensions (`.mcpb` bundles, secrets in the OS keychain), MDM/allowlist governance, and container/VM isolation for risky servers. Computer-use that drives the real desktop/browser is the hardest thing to sandbox.

## Sandbox for claude.ai (web)

Covered above: server-side **gVisor** containers, ephemeral per-session filesystem, JWT-gated egress proxy, zero blast radius on your host — but no persistent workspace and no access to your local repo or services.

## Pros of sandboxing Claude Code

1. **Lower blast radius** — a bad command, hallucinated script, or prompt injection has fewer places to write and fewer hosts to reach.
2. **Safer autonomous loops** — build/test/fix loops become practical with fewer interruptions.
3. **A boundary for YOLO mode** — `--dangerously-skip-permissions` stops being reckless when the environment is disposable.
4. **Rapid recovery** — checkpoint/restore (Sprites ~300ms) gives an undo button that encourages experimentation.
5. **Reproducibility** — containers/VMs pin dependencies, images, and setup.
6. **Parallel agents** — isolated clones run different hypotheses without colliding (pairs well with [[git-worktrees]]).
7. **Enterprise controls** — standardized egress, writable paths, credential handling, logs, and audit.
8. **Safe evaluation of untrusted code** — open-source repos, benchmarks, user-submitted code.

## Cons

1. **False sense of security** — a sandbox with broad reads, `~/.ssh` mounted, open egress, or a Docker socket is barely a sandbox.
2. **Network exfiltration stays hard** — broad allowlists (`github.com`, `api.anthropic.com`) become exfil channels; egress is where Anthropic's own custom proxy bugs appeared.
3. **Secrets are the hardest problem** — API keys, SSH keys, OAuth tokens, `.env` files, and inherited env vars must be kept out or proxied.
4. **Docker-in-sandbox breaks** — nested namespaces fail; punching a hole for the host Docker socket usually invalidates the whole model.
5. **MCP / network friction** — allowlisting every internal API and token inside a rigid layer is complex; agents lean heavily on MCP.
6. **Lost unattended context** — a hard violation can drop a background agent with no escape hatch, stalling the workflow until a human returns (this is exactly the gap [[claude-auto-mode]] and [[claude-dispatch]] try to close).
7. **Uneven coverage** — Bash, file tools, hooks, MCP, browser, and computer-use all sandbox differently.
8. **Mounted workspaces still corruptible** — a writable project dir can still be deleted or rewritten.
9. **Privacy/compliance** — cloud sandboxes may need self-hosting/VPC for regulated data.
10. **Reduced EDR visibility** — strong isolation can blind endpoint tooling unless logs/traces/OTLP are built in.

## What companies are doing

- **Anthropic** — pairing OS isolation primitives with model-based intent classification, one isolation pattern per surface (gVisor for claude.ai, OS sandbox for Claude Code, hypervisor VM for Cowork), plus Auto Mode and Managed Agents (Anthropic-managed or self-hosted execution).
- **OpenAI** — server-side ChatGPT containers (Code Interpreter / Advanced Data Analysis) running bash and pip/npm installs in transient cloud walls.
- **Fly.io** — Sprites.dev: persistent Firecracker microVMs with sub-second checkpoints, betting against ephemeral sandboxes.
- **Cloudflare** — Sandboxes + Containers reached GA (Apr 13, 2026); Sandbox SDK with preview URLs, persistent code interpreters, PTY terminals, backup/restore, and a Managed-Agents self-host path.
- **Docker** — Docker Sandboxes (`sbx run claude`): each agent gets its own Docker daemon, filesystem, and network inside a microVM; supports Claude Code, Codex, Copilot, Gemini, Kiro, OpenCode.
- **Vercel** — Vercel Sandbox GA: Firecracker microVMs, millisecond startup, root access, auto-saving persistent state.

## Startups and products — comparison matrix

| Tool / environment | Isolation mechanism | State / persistence | Network & credentials | Claude fit | Best for | Watch-out |
|---|---|---|---|---|---|---|
| **Claude Code `/sandbox`** | Seatbelt (macOS) / bubblewrap + socat (Linux) | Local workspace, no VM snapshot | Egress proxy + domain allowlist | Native Bash sandbox | Fewer prompts for everyday local work | Bash-only; doesn't cover MCP/hooks/secrets |
| **Anthropic `srt`** | OS process sandbox (process tree) | Local / process-level | FS + network + Unix-socket policy | Wraps agents, MCP servers, bash | Isolating local MCP servers | Early preview; known leak issues |
| **Devcontainer** | Docker container | Container volumes/images | Optional egress firewall | Run Claude Code in a dev env | Trusted-repo team setup | Socket/secrets/mounts re-open escapes |
| **Claude Code web** | Anthropic-managed VM | Session cloud workspace | Scoped/proxied git creds, allowlist | Hosted GitHub PR workflow | Branch/PR tasks, no local setup | Less customizable; cloud-dependent |
| **claude.ai code exec** | Google gVisor container | None (ephemeral per session) | JWT egress proxy, ~4h token | In-chat code/data analysis | Zero local blast radius | No repo/workstation access |
| **Claude Cowork** | Apple VZ / Windows HCS hypervisor VM | Local VM workspace | Egress MITM proxy + mount modes | Desktop agent for general work | Non-technical knowledge workers | Computer-use not fully sandboxed; RAM-heavy |
| **Managed Agents** | Anthropic-managed or self-hosted | Stateful agent sessions | Cloud or BYOC boundary | Long-running async agents | Brain/hands split, data residency | Self-host adds ops burden |
| **Fly Sprites.dev** | AWS Firecracker microVM | **Persistent + ~300ms COW checkpoints** | Public URL + port fwd, sandbox API | Claude Code preinstalled | Disposable-but-persistent workstation; untrusted code API | Tied to Fly infra; new |
| **E2B** | Firecracker microVM | Pause/resume; 24h (Pro) / 1h sessions | Sandbox API, self-host option | LLM-agnostic code exec | Security-first, scale, multi-agent | Egress/secrets design is on you |
| **Modal** | gVisor sandboxes | Volumes, FS/memory snapshots | Short-lived connect tokens | Claude Agent SDK examples | GPU/bursty serverless compute | Modal-specific deploy model |
| **Northflank** | Kata / Firecracker / gVisor | Ephemeral or persistent, no time limit | BYOC across AWS/GCP/Azure/bare-metal | Self-host Claude execution | Enterprise compliance / VPC | Platform breadth = more to learn |
| **Vercel Sandbox** | Firecracker microVM | Auto-save persist; ~45min sessions | Isolated FS/network/process | Agent code-gen | Vercel ecosystem, fast startup | Short session cap |
| **Cloudflare Sandboxes** | Cloudflare Containers (GA Apr 2026) | Named persistent sandboxes, snapshots | Egress proxy, credential injection, private connectivity | Managed-Agents self-host + custom | Workers/Agents/Browser ecosystem | Cloudflare-specific architecture |
| **Daytona** | Docker containers (shared kernel) | Stateful sandboxes | Customer-controlled options | Claude Code / Agent SDK guides | Fastest cold start (~27–90ms) | Container, not microVM, isolation |
| **Runloop** | microVM + container devboxes | Snapshots, branches, suspend/resume | VPC/secret/tooling options | Production coding agents | Agent evals (built-in SWE-bench) | Enterprise-oriented; cost/lock-in |
| **Docker Sandboxes** | microVM per sandbox, own Docker daemon | Workspace/project config | Anthropic OAuth proxy, secrets API | `sbx run claude` | Local/remote Docker-native wrapper | Docker dependency |

Cold-start and isolation trade-off in one line: containers (Daytona ~27–90ms) start fastest but share the host kernel; microVMs (E2B ~150ms, Sprites, Vercel, Firecracker family) boot a real kernel for hardware-level isolation; gVisor (claude.ai, Modal) sits in between with a userspace kernel.

## The horizon

1. **Secret-injecting / tokenization proxies** — the sandbox talks to an intermediary that injects GitHub/cloud tokens on outbound traffic, so the agent makes authenticated calls but can never read or exfiltrate the credential. Capabilities ("can push to this branch"), not raw secrets.
2. **Hybrid classifier + OS-primitive enforcement** — isolation alone makes agents dumb; loose bounds make them dangerous. The future is a local intent classifier (Auto Mode) coordinating with an OS sandbox (`srt`) that adjusts permissions based on what the agent claimed it would do.
3. **Network egress as a first-class capability** — path-level policies, request inspection, per-tool egress, and exfiltration detection, beyond domain allowlists.
4. **Snapshot-first workflows** — checkpoint before migrations, dependency upgrades, and risky refactors becomes default behavior.
5. **Pervasive ephemeral hardware** — development shifts off the laptop into instant-on remote microVM arrays; the laptop becomes a terminal.
6. **Self-hosted / BYOC** — regulated orgs want Anthropic orchestration with execution inside their own VPC.
7. **MCP / tool sandboxing** — the next big surface: local tool servers, browser tools, DB connectors need their own permission models.
8. **Red-team standards** — benchmarks for prompt-injection containment, credential leakage, filesystem escape, and network exfiltration.
9. **Persistence as a risk** — long-lived sandboxes need memory/file provenance, reset modes, and trust tiers against poisoning.

## One-line takeaway

For Claude Code, sandboxing is the difference between "the model can do anything my laptop can do" and "the model can only do what this disposable, policy-controlled environment permits" — and the durable design is isolation (sandbox) plus intent judgment ([[claude-auto-mode]]) layered together, never one alone.

Related notes: [[claude-code]] · [[claude-auto-mode]] · [[harness]] · [[claude-dispatch]] · [[git-worktrees]] · [[claude-dynamic-workflows]]

## Links

### Anthropic / Claude
- https://www.anthropic.com/engineering/how-we-contain-claude
- https://www.anthropic.com/engineering/claude-code-sandboxing
- https://www.anthropic.com/engineering/claude-code-auto-mode
- https://code.claude.com/docs/en/sandboxing
- https://code.claude.com/docs/en/devcontainer
- https://code.claude.com/docs/en/web-quickstart
- https://code.claude.com/docs/en/security
- https://github.com/anthropic-experimental/sandbox-runtime
- https://www.npmjs.com/package/@anthropic-ai/sandbox-runtime
- https://platform.claude.com/docs/en/managed-agents/overview
- https://platform.claude.com/docs/en/managed-agents/self-hosted-sandboxes
- https://www.anthropic.com/news/desktop-extensions
- https://support.anthropic.com/en/articles/12633545-use-claude-cowork-safely

### Sprites / Simon Willison
- https://simonwillison.net/2026/Jan/9/sprites-dev/
- https://sprites.dev/
- https://devclass.com/2026/01/13/fly-io-introduces-sprites-lightweight-persistent-vms-to-isolate-agentic-ai/
- https://news.ycombinator.com/item?id=46561089

### Sandbox / startup ecosystem
- https://docs.docker.com/ai/sandboxes/agents/claude-code/
- https://blog.cloudflare.com/sandbox-ga/
- https://developers.cloudflare.com/sandbox/
- https://modal.com/blog/introducing-claude-managed-agents-with-modal-sandboxes
- https://e2b.dev/
- https://github.com/e2b-dev/e2b
- https://vercel.com/docs/sandbox
- https://www.daytona.io/docs/en/guides/claude/
- https://runloop.ai/
- https://northflank.com/blog/best-code-execution-sandbox-for-ai-agents

### Analysis / security write-ups
- https://www.anthropic.com/engineering/claude-code-sandboxing
- https://the-agent-report.com/2026/05/anthropic-contains-claude-sandbox-vm-agent-security/
- https://pluto.security/blog/inside-claude-cowork-how-anthropics-autonomous-agent-actually-works/
- https://www.rbtsec.com/blog/exploring-claude-ais-code-execution-sandbox-a-fun-dive-into-infrastructure-and-prompt-injection/
- https://www.infoq.com/news/2025/11/anthropic-claude-code-sandbox/
