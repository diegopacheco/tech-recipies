# Agent Sandboxing

## 1. What is Agent Sandboxing?

Agent sandboxing is the practice of running AI agent code execution in isolated environments that prevent the agent from accessing or modifying the host system. When an agent generates and runs code, it needs a place to execute it safely. Without sandboxing, a compromised or buggy agent can read sensitive files, install malware, make unauthorized network calls, or destroy data. Sandboxing contains the blast radius -- even if the agent does something dangerous, the damage stays inside the sandbox.

## 2. Why is it Needed?

AI agents that generate and execute code are fundamentally different from traditional applications. A traditional app runs deterministic code written by developers. An agent generates code at runtime based on LLM output, which is non-deterministic and susceptible to prompt injection. This means:

- The code being executed has never been reviewed by a human
- The LLM can be manipulated into generating malicious code
- Tool outputs can contain injection payloads that trigger dangerous code generation
- Iterative loops (generate -> run -> fix -> repeat) amplify risk with each iteration

```
Without Sandbox:
┌─────────┐     generates     ┌──────────┐     runs on     ┌─────────────┐
│  Agent   │────────────────>│   Code    │───────────────>│ Host System │ DANGER
└─────────┘                  └──────────┘                 └─────────────┘

With Sandbox:
┌─────────┐     generates     ┌──────────┐     runs in     ┌─────────────┐
│  Agent   │────────────────>│   Code    │───────────────>│  Sandbox    │ SAFE
└─────────┘                  └──────────┘                 │ (isolated)  │
                                                          └─────────────┘
```

## 3. Sandboxing Approaches

```
┌───────────────────┬──────────────────┬───────────────┬────────────┬───────────────┐
│    Approach       │    Isolation     │   Startup     │    Cost    │   Best For    │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ Docker/Podman     │ Container-level  │ Seconds       │ Low        │ Self-hosted   │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ microVM (Firecracker)│ VM-level      │ ~125ms        │ Low        │ Multi-tenant  │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ E2B              │ microVM (cloud)   │ ~150ms        │ Pay-per-use│ Cloud agents  │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ Daytona          │ Container/VM      │ Seconds       │ Pay-per-use│ Dev envs      │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ Modal            │ Container (cloud) │ ~100ms        │ Pay-per-use│ Compute tasks │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ gVisor           │ Kernel-level      │ Milliseconds  │ Low        │ GKE/K8s       │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ WebAssembly (Wasm)│ Language-level   │ Milliseconds  │ Very low   │ Lightweight   │
├───────────────────┼──────────────────┼───────────────┼────────────┼───────────────┤
│ Subprocess + seccomp│ Process-level  │ Milliseconds  │ Very low   │ Linux agents  │
└───────────────────┴──────────────────┴───────────────┴────────────┴───────────────┘
```

## 4. E2B (Environment to Binary)

https://e2b.dev/

E2B is a cloud platform that provides sandboxed environments for AI agents. Each sandbox is a Firecracker microVM that boots in ~150ms and provides a full Linux environment. Agents can execute code, install packages, read/write files, and run processes inside the sandbox without any risk to the host. E2B is designed specifically for AI code execution use cases.

### Key Features
- Firecracker microVMs with ~150ms cold start
- Full Linux environment (Ubuntu) with filesystem, networking, process management
- Pre-built templates for Python, Node.js, and custom environments
- SDKs for Python and TypeScript
- Persistent sandboxes that can run for hours
- Built-in code interpreter for Jupyter-style execution
- File upload/download to/from sandbox

### PROS
- Purpose-built for AI agent code execution
- Very fast startup (microVMs, not full VMs)
- Strong isolation (VM-level, not just container-level)
- Easy to integrate (few lines of code)
- Custom templates for pre-configured environments
- Growing ecosystem, supported by LangChain, CrewAI, Vercel AI SDK

### CONS
- Cloud-only (can't self-host, depends on E2B infrastructure)
- Cost scales with usage (compute time billing)
- Network latency for remote execution
- Limited GPU support
- Vendor lock-in for the sandbox runtime

### Code Sample

```python
from e2b_code_interpreter import Sandbox

sandbox = Sandbox()

execution = sandbox.run_code("print('Hello from sandbox!')")
print(execution.text)

execution = sandbox.run_code("""
import pandas as pd
import numpy as np

data = pd.DataFrame({
    'x': np.random.randn(100),
    'y': np.random.randn(100)
})
print(data.describe())
""")
print(execution.text)

sandbox.close()
```

## 5. Daytona

https://daytona.io/

Daytona is an open-source infrastructure platform for running AI-generated code in secure, standardized development environments. Unlike E2B which focuses on lightweight code execution, Daytona provides full development environments with IDE support, git integration, and persistent workspaces. Daytona targets both human developers and AI agents that need rich environments to write, test, and debug code.

### Key Features
- Full development environments (not just code execution)
- Git integration (clone, commit, push from sandbox)
- IDE support (VS Code, JetBrains via remote connection)
- Multiple infrastructure backends (Docker, Podman, AWS, GCP, Azure, Kubernetes)
- Workspace templates (devcontainer.json, Nix)
- SDK for programmatic environment management (Python, TypeScript, Go)
- Self-hostable (open-source core)

### PROS
- Full dev environment, not just code execution
- Self-hostable (no vendor lock-in for infrastructure)
- Multiple backend providers (Docker, K8s, cloud VMs)
- Git-native (agents can clone, branch, commit, push)
- Persistent workspaces that survive restarts
- Open source (Apache 2.0)
- Strong isolation with configurable backends

### CONS
- Heavier than E2B for simple code execution tasks
- Slower startup compared to microVMs (full dev env setup)
- More complex to configure and manage than E2B
- Self-hosting requires infrastructure expertise
- Newer project, smaller community

### Code Sample

```python
from daytona_sdk import Daytona

daytona = Daytona()

workspace = daytona.create()

response = workspace.process.code_run('print("Hello from Daytona!")')
print(response.result)

response = workspace.process.code_run("""
import os
files = os.listdir('/')
print(files)
""")
print(response.result)

workspace.process.exec('pip install requests')

response = workspace.process.code_run("""
import requests
r = requests.get('https://httpbin.org/get')
print(r.status_code)
""")
print(response.result)

daytona.remove(workspace)
```

## 6. Container-Based Sandboxing (Podman)

For self-hosted sandboxing, containers provide a practical balance of isolation and performance. Each agent execution runs in a fresh container with restricted capabilities.

```python
import subprocess
import json

class PodmanSandbox:
    def __init__(self, image: str = "python:3.12-slim"):
        self.image = image
        self.container_id = None

    def start(self):
        result = subprocess.run(
            ["podman", "run", "-d",
             "--network=none",
             "--memory=512m",
             "--cpus=1",
             "--read-only",
             "--tmpfs", "/tmp:rw,size=100m",
             "--security-opt=no-new-privileges",
             self.image, "sleep", "300"],
            capture_output=True, text=True
        )
        self.container_id = result.stdout.strip()

    def run_code(self, code: str) -> str:
        result = subprocess.run(
            ["podman", "exec", self.container_id,
             "python", "-c", code],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            return f"Error: {result.stderr}"
        return result.stdout

    def stop(self):
        if self.container_id:
            subprocess.run(["podman", "rm", "-f", self.container_id],
                         capture_output=True)

sandbox = PodmanSandbox()
sandbox.start()
print(sandbox.run_code("print(2 + 2)"))
sandbox.stop()
```

## 7. Comparison

```
┌──────────────┬─────────────┬──────────────┬──────────────┬───────────────┐
│   Feature    │     E2B     │   Daytona    │ Podman/Docker│    Modal      │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Isolation    │ microVM     │ Container/VM │ Container    │ Container     │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Self-host    │ No          │ Yes          │ Yes          │ No            │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Startup time │ ~150ms      │ Seconds      │ Seconds      │ ~100ms        │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Best for     │ Code exec   │ Full dev env │ Self-hosted  │ Compute tasks │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ GPU support  │ Limited     │ Yes          │ Yes (NVIDIA) │ Yes           │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Persistence  │ Session     │ Workspace    │ Volume mount │ Volume        │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Git native   │ No          │ Yes          │ Manual       │ No            │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Open source  │ Partial     │ Yes          │ Yes          │ No            │
├──────────────┼─────────────┼──────────────┼──────────────┼───────────────┤
│ Pricing      │ Per-second  │ Per-workspace│ Infra cost   │ Per-second    │
└──────────────┴─────────────┴──────────────┴──────────────┴───────────────┘
```

## 8. Security Hardening Checklist for Sandboxed Agents

```
[ ] Network access disabled or restricted to allowlisted domains
[ ] Filesystem is read-only except for designated temp directories
[ ] Memory and CPU limits enforced
[ ] Execution timeout enforced (kill runaway processes)
[ ] No access to host filesystem, environment variables, or secrets
[ ] No privilege escalation (no-new-privileges flag)
[ ] Fresh sandbox per execution (no state leakage between runs)
[ ] Output size limited (prevent memory exhaustion via large outputs)
[ ] Sandbox destroyed after execution completes
[ ] All executions logged for audit
```
