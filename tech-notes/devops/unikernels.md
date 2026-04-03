# Unikernels

## What is it?

A unikernel is a specialized, single-address-space machine image constructed by compiling an application together with only the OS library functions it needs, linked directly against a library operating system. The result is a single-purpose appliance image that runs directly on a hypervisor or bare metal — no general-purpose OS, no shell, no unnecessary drivers, no userspace/kernel boundary. The application IS the kernel. Unikernels are measured in megabytes (often single digits), boot in milliseconds, and have an attack surface orders of magnitude smaller than a Linux VM or container.

## Who created it? When?

The concept originated from the **Nemesis** operating system research at Cambridge in the late 1990s. The modern unikernel movement was catalyzed by **Anil Madhavapeddy** and the **MirageOS** project at the **University of Cambridge** in **2013**, which demonstrated a full TCP/IP stack and web server compiled into a Xen image under 1MB. The term "unikernel" was popularized by the MirageOS team. **Docker acquired Unikernel Systems** in **2016**. Other notable projects include **IncludeOS** (2015, C++), **OSv** (2014, Cloudius Systems), **Nanos** (NanoVMs), and **Unikraft** (2017, now a CNCF project and the most active unikernel framework as of 2025).

## How it works?

### Traditional OS vs Container vs Unikernel

```
Traditional VM:                Container:                 Unikernel:

┌──────────────┐          ┌──────────────┐          ┌──────────────┐
│ Application  │          │ Application  │          │ Application  │
├──────────────┤          ├──────────────┤          │ +            │
│ Libraries    │          │ Libraries    │          │ Library OS   │
├──────────────┤          ├──────────────┤          │ (only needed │
│ Language     │          │ Minimal      │          │  components) │
│ Runtime      │          │ Userspace    │          │              │
├──────────────┤          ├──────────────┤          │ Single       │
│ Shell, Utils │          │ Container    │          │ address      │
│ sshd, cron   │          │ Runtime      │          │ space        │
├──────────────┤          ├──────────────┤          ├──────────────┤
│ Full Linux   │          │ Host Linux   │          │ Hypervisor   │
│ Kernel       │          │ Kernel       │          │ (Xen, KVM,   │
├──────────────┤          ├──────────────┤          │  QEMU, bhyve)│
│ Hypervisor   │          │ Hypervisor   │          │ or bare metal│
│ or bare metal│          │ or bare metal│          └──────────────┘
└──────────────┘          └──────────────┘
  ~GB image                 ~100s MB image             ~1-10 MB image
  ~30s boot                 ~1s boot                   ~10-50ms boot
  Large attack surface      Medium attack surface      Minimal attack surface
```

### Build Process

```
┌────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│ Application    │     │ Library OS       │     │ Build Tool       │
│ Source Code    │────►│ Components       │────►│ (compiler +      │
│                │     │                  │     │  linker)         │
└────────────────┘     │ - network stack  │     └────────┬─────────┘
                       │ - filesystem     │              │
                       │ - TLS            │              ▼
                       │ - scheduler      │     ┌──────────────────┐
                       │ - memory mgmt   │     │ Unikernel Image  │
                       └──────────────────┘     │ (.img / .iso)    │
                                                │                  │
                         Only the components    │ Runs on:         │
                         actually used by the   │ - Xen            │
                         application are        │ - KVM/QEMU       │
                         included (dead code    │ - VMware         │
                         elimination)           │ - AWS Firecracker│
                                                │ - bhyve          │
                                                │ - bare metal     │
                                                └──────────────────┘
```

### Library OS Architecture

```
Traditional OS:                    Library OS (Unikernel):

  User Space                         Single Address Space
  ┌─────────────────┐                ┌─────────────────────┐
  │  Application    │                │  Application        │
  │                 │                │  │                   │
  │  syscall ───────┼── boundary    │  ▼ (direct call)    │
  └─────────────────┘                │  Network Stack      │
  Kernel Space                       │  │                   │
  ┌─────────────────┐                │  ▼                   │
  │  VFS            │                │  Block Device        │
  │  Network Stack  │                │  │                   │
  │  Scheduler      │                │  ▼                   │
  │  Drivers        │                │  Scheduler           │
  │  Memory Mgmt    │                │  │                   │
  └─────────────────┘                │  ▼                   │
                                     │  Hypervisor Calls    │
  Context switches between           └─────────────────────┘
  user/kernel space on
  every syscall                      No context switches.
                                     Direct function calls.
                                     No syscall overhead.
```

## Unikernel Projects

### Unikraft (CNCF)

The most actively developed unikernel framework. Modular library OS with a build system (kraftkit) that lets you pick components.

```
kraft build --plat qemu --arch x86_64
kraft run

Supported languages:
  - C / C++
  - Go
  - Python (via micropython)
  - Rust
  - Node.js
  - Ruby
  - Lua
  - WASM

Architecture:
  ┌─────────────────────────────────────┐
  │            Application              │
  ├─────────────────────────────────────┤
  │     Micro-libraries (pick & mix)    │
  │  ┌────────┐ ┌──────┐ ┌───────────┐ │
  │  │ lwIP   │ │ 9pfs │ │ vfscore   │ │
  │  │(network)│ │(fs)  │ │           │ │
  │  └────────┘ └──────┘ └───────────┘ │
  ├─────────────────────────────────────┤
  │     Platform Abstraction            │
  │     (Xen, KVM, Firecracker, Linux)  │
  └─────────────────────────────────────┘
```

### MirageOS

OCaml-based unikernel. The original modern unikernel project. Applications are written in OCaml and compiled to Xen or Unix targets.

```
Application (OCaml) ──► MirageOS libraries ──► Solo5/Xen image

Key property: type-safe from application down to the network stack.
The OCaml type system catches errors that would be runtime bugs in C.

Use cases:
  - TLS termination (btls)
  - DNS server (ocaml-dns)
  - Firewall appliances
  - VPN endpoints
```

### Other Projects

```
┌──────────────────┬────────────┬────────────────────────────────────┐
│ Project          │ Language   │ Notes                               │
├──────────────────┼────────────┼────────────────────────────────────┤
│ Unikraft         │ C (core), │ CNCF project. Most active. Modular │
│                  │ multi-lang │ library OS with kraftkit CLI.       │
├──────────────────┼────────────┼────────────────────────────────────┤
│ MirageOS         │ OCaml      │ Type-safe. Xen-native. Research    │
│                  │            │ origin of modern unikernels.       │
├──────────────────┼────────────┼────────────────────────────────────┤
│ IncludeOS        │ C++        │ x86 unikernel. Boots in ~300ms.   │
│                  │            │ Single-threaded event loop.        │
├──────────────────┼────────────┼────────────────────────────────────┤
│ OSv              │ Java, C    │ Runs unmodified Linux binaries.    │
│                  │            │ JVM-optimized. Cloudius Systems.   │
├──────────────────┼────────────┼────────────────────────────────────┤
│ Nanos (NanoVMs)  │ Any (ELF)  │ Runs unmodified Linux binaries.   │
│                  │            │ Commercial company (NanoVMs).      │
├──────────────────┼────────────┼────────────────────────────────────┤
│ HermiTux         │ Any (ELF)  │ Binary-compatible. Runs unmodified│
│                  │            │ Linux apps via syscall layer.      │
├──────────────────┼────────────┼────────────────────────────────────┤
│ RustyHermit      │ Rust       │ Rust unikernel. Hermit kernel     │
│                  │            │ rewritten in Rust.                 │
└──────────────────┴────────────┴────────────────────────────────────┘
```

## Comparison: Unikernels vs Containers vs VMs

```
┌──────────────────┬──────────────┬──────────────┬──────────────────┐
│ Property         │ VM           │ Container    │ Unikernel        │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Image size       │ GBs          │ 10s-100s MB  │ 1-10 MB          │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Boot time        │ 10-60 sec    │ 0.5-2 sec    │ 10-50 ms         │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Isolation        │ Hardware     │ Kernel       │ Hardware          │
│                  │ (hypervisor) │ (namespaces) │ (hypervisor)     │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Attack surface   │ Large        │ Medium       │ Minimal          │
│                  │ (full OS)    │ (shared      │ (no shell, no    │
│                  │              │  kernel)     │  unused syscalls)│
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Debugging        │ SSH, gdb,    │ docker exec, │ Serial console,  │
│                  │ full tools   │ logs         │ limited tooling  │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Multi-process    │ Yes          │ Yes          │ No (single app)  │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Ecosystem        │ Mature       │ Massive      │ Small            │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Density          │ 10s per host │ 100s per host│ 1000s per host   │
├──────────────────┼──────────────┼──────────────┼──────────────────┤
│ Operations       │ Standard     │ Standard     │ Specialized      │
│                  │ ops tooling  │ ops tooling  │ (rebuild to      │
│                  │              │              │  change config)  │
└──────────────────┴──────────────┴──────────────┴──────────────────┘
```

## Deployment

### Running on KVM/QEMU

```
Build (Unikraft):
  kraft build --plat qemu --arch x86_64

Run:
  kraft run -p qemu

Manual QEMU:
  qemu-system-x86_64 \
    -kernel unikernel.img \
    -nographic \
    -m 64M \
    -netdev user,id=net0,hostfwd=tcp::8080-:8080 \
    -device virtio-net-pci,netdev=net0
```

### Running on AWS (Firecracker)

```
Firecracker is a microVM monitor built by AWS for Lambda and Fargate.
Unikernels run well on Firecracker due to its minimal overhead.

┌────────────────┐
│  Unikernel     │  ~5 MB image
│  (application  │  ~5 ms boot
│   + library OS)│
├────────────────┤
│  Firecracker   │  microVM
│  (KVM-based)   │  125 ms VM creation
└────────────────┘
```

### Cloud Deployment

```
┌─────────────────┬──────────────────────────────────────────────┐
│ Platform        │ How to run unikernels                         │
├─────────────────┼──────────────────────────────────────────────┤
│ AWS             │ Custom AMI from unikernel image. Or           │
│                 │ Firecracker via Lambda/Fargate internals.     │
├─────────────────┼──────────────────────────────────────────────┤
│ GCP             │ Custom image uploaded to Compute Engine.      │
├─────────────────┼──────────────────────────────────────────────┤
│ Azure           │ Custom VHD uploaded to Azure VMs.             │
├─────────────────┼──────────────────────────────────────────────┤
│ NanoVMs (Nanos) │ ops CLI deploys unikernels to any cloud.     │
│                 │ ops run / ops image create / ops deploy       │
├─────────────────┼──────────────────────────────────────────────┤
│ Kubernetes      │ Kubevirt or Kata Containers can run           │
│                 │ unikernel images as VM-backed pods.           │
├─────────────────┼──────────────────────────────────────────────┤
│ Bare metal      │ PXE boot or write image to disk directly.    │
└─────────────────┴──────────────────────────────────────────────┘
```

## Pros

- **Minimal Attack Surface**: no shell, no SSH, no unused syscalls, no package manager — nothing to exploit
- **Tiny Images**: 1-10 MB images vs hundreds of MB for containers, GBs for VMs
- **Fast Boot**: millisecond boot times enable serverless-like scaling from zero
- **Hardware Isolation**: runs on a hypervisor like a VM, stronger isolation than containers
- **Performance**: no syscall overhead (direct function calls), no context switches between user/kernel space
- **High Density**: thousands of unikernels per host due to small memory footprint
- **Immutable**: no patching, no config drift — rebuild and redeploy the entire image
- **Reduced CVE Surface**: no general-purpose OS means most Linux CVEs do not apply

## Cons

- **Debugging Difficulty**: no shell, no SSH, no strace, no gdb in production — debugging is hard
- **Single Application**: one unikernel runs one application — no multi-process, no sidecar pattern
- **Ecosystem Maturity**: small community, limited library support, fewer production deployments
- **Build Complexity**: requires recompiling the application with the library OS — not just packaging a binary
- **No Standard Tooling**: no equivalent of docker/kubectl ecosystem for orchestration and management
- **Language Restrictions**: some unikernel projects only support specific languages (MirageOS → OCaml)
- **Monitoring Gap**: standard monitoring agents (Datadog, Prometheus node exporter) cannot run inside
- **Networking Limitations**: some unikernels have incomplete network stack implementations

## Use Cases

- **Network Functions**: DNS servers, firewalls, load balancers, VPN endpoints — single-purpose appliances
- **Edge Computing**: tiny images and fast boot for resource-constrained edge nodes
- **IoT Gateways**: minimal footprint devices running protocol translation or data aggregation
- **Serverless Functions**: millisecond cold start for function-as-a-service platforms
- **Security-Critical Services**: TLS terminators, key management, auth services with minimal attack surface
- **CDN Edge Nodes**: lightweight HTTP servers at thousands of PoPs
- **Embedded Systems**: replacing RTOS with a unikernel for deterministic, single-purpose devices
- **Telco / NFV**: network function virtualization replacing hardware appliances with unikernel VNFs
- **High-Frequency Trading**: low-latency, deterministic performance with no OS jitter
- **Satellite / Space**: radiation-tolerant, minimal software stack for space computing
