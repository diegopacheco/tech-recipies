# Sandboxing

## What is it?

Sandboxing is a security mechanism that isolates running programs in a restricted environment with limited access to system resources. A sandboxed process cannot freely access the file system, network, other processes, or hardware — it can only use what is explicitly allowed. The goal is to limit the damage a compromised or malicious program can do. If code running inside the sandbox is exploited, the attacker is contained within the sandbox boundaries and cannot reach the host system or other applications.

## Who created it? When?

The concept of sandboxing evolved from multiple sources. Early **chroot** (1979, Unix V7) provided basic filesystem isolation. **Java Applets (1995)** introduced the security sandbox model for running untrusted code in browsers. **FreeBSD Jails (2000)** extended chroot with process and network isolation. **SELinux (2000)**, developed by the **NSA**, brought mandatory access control to Linux. Google's **Chromium sandbox (2008)** became one of the most well-known modern sandbox implementations, isolating each browser tab in a separate process with restricted system calls. **Docker (2013)** popularized OS-level sandboxing via Linux namespaces and cgroups for application deployment.

## How it works?

### Core Mechanisms

```
┌─────────────────────────────────────────────┐
│              Host System                     │
│                                             │
│  ┌────────────────────────────────────────┐  │
│  │           Sandbox Boundary             │  │
│  │                                        │  │
│  │  ┌──────────────┐  ┌───────────────┐   │  │
│  │  │ Sandboxed    │  │ Allowed       │   │  │
│  │  │ Process      │  │ Resources     │   │  │
│  │  │              │──►  - /tmp/app   │   │  │
│  │  │ (untrusted   │  │  - port 8080  │   │  │
│  │  │  code)       │  │  - 256MB RAM  │   │  │
│  │  └──────────────┘  └───────────────┘   │  │
│  │         │                              │  │
│  │         ✗ cannot access:               │  │
│  │           - filesystem outside /tmp    │  │
│  │           - network (other ports)      │  │
│  │           - other processes            │  │
│  │           - hardware devices           │  │
│  │           - kernel (restricted calls)  │  │
│  └────────────────────────────────────────┘  │
│                                             │
│  ┌──────────────┐  ┌──────────────┐         │
│  │ Other App    │  │ System       │         │
│  │ (unaffected) │  │ (protected)  │         │
│  └──────────────┘  └──────────────┘         │
└─────────────────────────────────────────────┘
```

1. A process is launched inside a restricted environment
2. The sandbox runtime or kernel enforces resource access policies
3. System calls from the sandboxed process are intercepted and filtered
4. Only explicitly allowed operations succeed
5. Denied operations return errors or terminate the process
6. The sandboxed process has no way to bypass the restrictions without a kernel or sandbox escape vulnerability

## Sandbox Technologies

### 1. OS-Level Isolation

**Linux Namespaces**: isolate process views of system resources (PID, network, mount, user, IPC, UTS). Each namespace provides independent resource visibility.

**cgroups (Control Groups)**: limit and account for resource usage (CPU, memory, disk I/O, network bandwidth). Prevents resource exhaustion attacks.

**seccomp-BPF**: filters system calls using Berkeley Packet Filter programs. A process can only invoke whitelisted syscalls. Used by Docker, Chrome, Firefox, systemd.

**Capabilities**: break root's monolithic privilege into granular capabilities (CAP_NET_BIND_SERVICE, CAP_SYS_ADMIN, etc). Sandboxed processes run with a minimal capability set.

**AppArmor / SELinux**: mandatory access control systems that confine processes to defined security profiles regardless of user permissions.

### 2. Application-Level Sandboxing

**Chromium Multi-Process Sandbox**: each tab, extension, and plugin runs in a separate process with restricted syscalls. The broker process mediates access to privileged resources.

```
┌─────────────────────────────────────────┐
│            Browser Process              │
│          (privileged broker)            │
│  ┌──────────┬──────────┬──────────┐     │
│  │ Renderer │ Renderer │ Renderer │     │
│  │ (Tab 1)  │ (Tab 2)  │ (Tab 3)  │     │
│  │ seccomp  │ seccomp  │ seccomp  │     │
│  │ no FS    │ no FS    │ no FS    │     │
│  │ no net   │ no net   │ no net   │     │
│  └──────────┴──────────┴──────────┘     │
│  ┌──────────┐  ┌──────────┐             │
│  │ GPU Proc │  │ Network  │             │
│  │ (limited)│  │ Service  │             │
│  └──────────┘  └──────────┘             │
└─────────────────────────────────────────┘
```

**Java Security Manager** (deprecated in Java 17): defined permissions for code based on its origin (codebase, signer). Restricted file, network, and reflection access.

**WebAssembly (Wasm)**: linear memory model with no access to host resources by default. All capabilities must be explicitly passed in. Memory-safe execution of compiled code.

**eBPF Sandboxing**: eBPF programs are verified by the kernel before execution. The verifier ensures programs terminate, do not access out-of-bounds memory, and use only allowed helpers.

### 3. Container Sandboxing

**Docker/Podman**: combines namespaces, cgroups, seccomp, and capabilities to isolate containers. Shares the host kernel (weaker isolation than VMs).

**gVisor (Google)**: an application kernel that intercepts all syscalls from the container and re-implements them in a userspace kernel written in Go. Adds a strong isolation layer without the overhead of a full VM.

**Kata Containers**: runs each container inside a lightweight VM using a stripped-down kernel. Provides hardware-level isolation with container-like ergonomics.

**Firecracker (AWS)**: micro-VM technology that boots in ~125ms with minimal memory overhead. Powers AWS Lambda and Fargate. Strong isolation at near-container performance.

### 4. Hardware-Assisted Sandboxing

**Intel SGX (Software Guard Extensions)**: creates encrypted memory enclaves that even the OS and hypervisor cannot read. Code and data inside the enclave are protected from all software outside it.

**ARM TrustZone**: divides the processor into secure and non-secure worlds. The secure world runs trusted code isolated from the normal OS.

**AMD SEV (Secure Encrypted Virtualization)**: encrypts VM memory so the hypervisor cannot read guest data. Protects tenants from malicious or compromised cloud infrastructure.

## Comparison

```
┌────────────────────┬────────────┬─────────────┬──────────────┬───────────────┐
│ Technology         │ Isolation  │ Performance │ Startup Time │ Attack Surface│
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ chroot             │ Weak       │ Native      │ Instant      │ Large         │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ Namespaces+cgroups │ Medium     │ Near-native │ Milliseconds │ Medium        │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ seccomp-BPF        │ Medium     │ Near-native │ Instant      │ Small         │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ Docker/Podman      │ Medium     │ Near-native │ Seconds      │ Medium        │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ gVisor             │ Strong     │ Moderate    │ Seconds      │ Small         │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ Kata Containers    │ Strong     │ Moderate    │ ~1 second    │ Small         │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ Firecracker        │ Strong     │ Near-native │ ~125ms       │ Very Small    │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ Full VM            │ Very Strong│ Lower       │ Seconds-min  │ Small         │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ WebAssembly        │ Strong     │ Near-native │ Milliseconds │ Very Small    │
├────────────────────┼────────────┼─────────────┼──────────────┼───────────────┤
│ Intel SGX          │ Very Strong│ Moderate    │ Milliseconds │ Minimal       │
└────────────────────┴────────────┴─────────────┴──────────────┴───────────────┘
```

## Pros

- **Blast Radius Reduction**: compromised code cannot affect the host or other sandboxed processes
- **Defense in Depth**: adds an isolation layer even if application-level security fails
- **Untrusted Code Execution**: enables running third-party or user-submitted code safely
- **Principle of Least Privilege**: processes only get access to what they explicitly need
- **Reproducible Environments**: sandboxed environments are consistent and predictable
- **Multi-Tenant Safety**: isolates tenants from each other in shared infrastructure
- **Malware Analysis**: safely execute and observe malicious code behavior
- **Browser Security**: prevents malicious websites from accessing user data or system resources
- **Regulatory Compliance**: isolation boundaries satisfy many compliance requirements for data separation

## Cons

- **Performance Overhead**: syscall interception, memory encryption, and virtualization add latency
- **Escape Vulnerabilities**: sandbox escapes (kernel exploits, hypervisor bugs) break all guarantees
- **Complexity**: configuring sandbox policies correctly is error-prone, overly permissive policies give false confidence
- **Compatibility Issues**: some applications break when system calls or filesystem access is restricted
- **Shared Kernel Risk**: container-based sandboxes share the host kernel, a kernel vulnerability breaks isolation
- **Resource Overhead**: VMs and micro-VMs consume more memory and CPU than bare processes
- **Debugging Difficulty**: restricted environments make debugging and profiling harder
- **Incomplete Coverage**: sandboxing does not protect against logic bugs, data exfiltration through allowed channels, or side-channel attacks
- **Policy Maintenance**: security profiles need ongoing updates as applications evolve

## Use Cases

- **Web Browsers**: isolating tabs, extensions, and plugins from each other and the host (Chrome, Firefox)
- **Cloud Functions**: AWS Lambda (Firecracker), Google Cloud Run (gVisor) run untrusted user code in isolation
- **Container Orchestration**: Kubernetes pods with seccomp, AppArmor, and runtime sandboxes
- **Online Judges**: competitive programming platforms run user-submitted code in sandboxes
- **CI/CD Pipelines**: building and testing untrusted code in isolated environments
- **Mobile Apps**: iOS App Sandbox and Android application sandbox restrict app capabilities
- **Plugin Systems**: running third-party plugins without risking host application stability
- **Malware Analysis**: detonating suspicious files in controlled environments (Cuckoo, Any.Run)
- **Edge Computing**: running multi-tenant workloads on shared edge nodes with strong isolation
- **Email Attachments**: opening attachments in sandboxed viewers to prevent exploitation
