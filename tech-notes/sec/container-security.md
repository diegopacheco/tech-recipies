# Container Security

## What is it?

Container security is the practice of protecting containerized applications across the entire lifecycle — from building images to running workloads in production. Containers share the host kernel, which means a vulnerability in the kernel or a misconfigured container can compromise the entire host and all other containers running on it. Container security addresses image supply chain integrity, runtime isolation, orchestrator hardening (Kubernetes), network policies, secrets management, and compliance enforcement.

## Why does it matter?

Containers are the dominant deployment model for modern applications. A single Kubernetes cluster can run thousands of containers from hundreds of different base images, each pulling in dozens of dependencies. The attack surface is massive: vulnerable base images, misconfigured RBAC, exposed APIs, overprivileged containers, unscanned registries, and lateral movement between pods. Sysdig's 2024 Cloud-Native Security Report found that 87% of container images have high or critical vulnerabilities, and 75% of running containers have at least one patchable critical vulnerability.

## How it works?

### Security Across the Container Lifecycle

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│    BUILD     │───►│    STORE     │───►│   DEPLOY     │───►│     RUN      │
│              │    │              │    │              │    │              │
│ - Base image │    │ - Registry   │    │ - Admission  │    │ - Runtime    │
│   selection  │    │   scanning   │    │   control    │    │   monitoring │
│ - Dependency │    │ - Image      │    │ - Pod sec    │    │ - Syscall    │
│   scanning   │    │   signing    │    │   standards  │    │   filtering  │
│ - Dockerfile │    │ - Access     │    │ - RBAC       │    │ - Network    │
│   best prac  │    │   control    │    │ - Resource   │    │   policies   │
│ - SBOM gen   │    │ - Retention  │    │   limits     │    │ - Forensics  │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

## Build-Time Security

### Secure Base Images

Choose minimal base images to reduce attack surface.

```
┌────────────────────┬────────────┬──────────────┬─────────────────────┐
│ Base Image         │ Size       │ Packages     │ CVEs (typical)      │
├────────────────────┼────────────┼──────────────┼─────────────────────┤
│ ubuntu:24.04       │ ~78MB      │ ~100+        │ Medium-High         │
├────────────────────┼────────────┼──────────────┼─────────────────────┤
│ alpine:3.21        │ ~7MB       │ ~15          │ Low                 │
├────────────────────┼────────────┼──────────────┼─────────────────────┤
│ distroless (Google)│ ~2-20MB    │ Runtime only │ Very Low            │
├────────────────────┼────────────┼──────────────┼─────────────────────┤
│ chainguard/static  │ ~2MB       │ None         │ Zero (target)       │
├────────────────────┼────────────┼──────────────┼─────────────────────┤
│ scratch            │ 0MB        │ None         │ Zero                │
└────────────────────┴────────────┴──────────────┴─────────────────────┘
```

### Containerfile Best Practices

- Use multi-stage builds to exclude build tools from the final image
- Run as non-root user (USER directive)
- Pin base image versions by digest, not tag
- Do not install unnecessary packages
- Do not copy secrets into image layers
- Use .dockerignore to exclude sensitive files
- Set read-only filesystem where possible

```dockerfile
FROM golang:1.23 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /server

FROM gcr.io/distroless/static:nonroot
COPY --from=builder /server /server
USER nonroot:nonroot
ENTRYPOINT ["/server"]
```

### Image Scanning

Tools that scan container images for known vulnerabilities (CVEs) in OS packages and application dependencies.

```
┌──────────────────┬────────────┬───────────────┬──────────────────────────┐
│ Tool             │ Type       │ Databases     │ Notes                    │
├──────────────────┼────────────┼───────────────┼──────────────────────────┤
│ Trivy (Aqua)     │ Open source│ NVD, GHSA,    │ Most popular, scans      │
│                  │            │ vendor DBs    │ images, IaC, SBOM        │
├──────────────────┼────────────┼───────────────┼──────────────────────────┤
│ Grype (Anchore)  │ Open source│ NVD, GHSA,    │ Fast CLI scanner,        │
│                  │            │ vendor DBs    │ pairs with Syft (SBOM)   │
├──────────────────┼────────────┼───────────────┼──────────────────────────┤
│ Snyk Container   │ Commercial │ Snyk vuln DB  │ IDE integration,         │
│                  │            │               │ fix recommendations      │
├──────────────────┼────────────┼───────────────┼──────────────────────────┤
│ Clair (Quay)     │ Open source│ NVD, distro   │ Registry-integrated      │
│                  │            │ advisories    │ scanning                 │
├──────────────────┼────────────┼───────────────┼──────────────────────────┤
│ Docker Scout     │ Commercial │ Docker's DB   │ Built into Docker CLI    │
└──────────────────┴────────────┴───────────────┴──────────────────────────┘
```

### Image Signing and Verification

Cryptographically sign images to ensure integrity and provenance. Verify signatures before deployment.

- **Cosign (Sigstore)**: keyless signing using OIDC identity (GitHub Actions, Google, etc.). Signs OCI artifacts and stores signatures in the registry alongside the image.
- **Notary v2 / ORAS**: OCI-native signing specification. Used by Docker Content Trust and Azure Container Registry.

## Registry Security

- Enable vulnerability scanning on push (Harbor, ECR, GCR, ACR all support this)
- Enforce image signing verification before pull
- Use private registries with authentication and RBAC
- Implement image retention policies to remove old, vulnerable images
- Allowlist trusted registries in Kubernetes admission controllers

## Kubernetes Security

### RBAC (Role-Based Access Control)

K8s RBAC controls who can do what on which resources.

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes RBAC                       │
│                                                         │
│  Subject ──── RoleBinding ──── Role                     │
│  (User,       (binds subject   (defines permissions     │
│   Group,       to role in a     on resources in a       │
│   ServiceAcc)  namespace)       namespace)              │
│                                                         │
│  Subject ──── ClusterRoleBinding ──── ClusterRole       │
│  (User,       (binds subject          (defines perms    │
│   Group,       cluster-wide)           cluster-wide)    │
│   ServiceAcc)                                           │
└─────────────────────────────────────────────────────────┘

Role (namespace-scoped):
  apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]

ClusterRole (cluster-scoped):
  apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
```

RBAC best practices:
- Do not use cluster-admin for workloads
- Create namespace-scoped roles with minimum permissions
- Do not bind roles to default service accounts
- Audit RBAC regularly (rakkess, kubectl-who-can)
- Disable automounting of service account tokens when not needed

### Pod Security Standards (PSS)

Replaced the deprecated PodSecurityPolicy (PSP). Three built-in security profiles enforced at the namespace level via Pod Security Admission (PSA).

```
┌──────────────┬───────────────────────────────────────────────────────┐
│ Profile      │ What it enforces                                      │
├──────────────┼───────────────────────────────────────────────────────┤
│ Privileged   │ No restrictions. Full access. Use only for system     │
│              │ components (CNI, storage drivers, logging agents).    │
├──────────────┼───────────────────────────────────────────────────────┤
│ Baseline     │ Blocks known privilege escalations. No hostNetwork,   │
│              │ hostPID, hostIPC, privileged containers, or host path │
│              │ volumes. Allows most workloads.                       │
├──────────────┼───────────────────────────────────────────────────────┤
│ Restricted   │ Maximum security. Requires non-root, read-only root   │
│              │ filesystem, drops ALL capabilities, requires          │
│              │ seccompProfile, disallows privilege escalation.       │
└──────────────┴───────────────────────────────────────────────────────┘

Enforcement modes per namespace:
  enforce: reject pods that violate
  audit:   log violations but allow
  warn:    warn user but allow
```

### Admission Controllers

Intercept requests to the Kubernetes API server before objects are persisted. Used to enforce security policies, mutate resources, and validate configurations.

```
Request ──► Authentication ──► Authorization ──► Admission Controllers ──► etcd
                                                  │
                                          ┌───────┼───────┐
                                          ▼       ▼       ▼
                                     Mutating  Validating  Webhooks
                                     (modify)  (accept/   (external
                                               reject)    policy)
```

**Built-in admission controllers**:
- PodSecurity (enforces PSS profiles)
- LimitRanger (enforces resource limits)
- ResourceQuota (enforces namespace quotas)
- NodeRestriction (limits kubelet permissions)

**External policy engines**:
- **OPA Gatekeeper**: enforces custom policies written in Rego
- **Kyverno**: K8s-native policy engine using YAML (no Rego)
- **Kubewarden**: policy engine using WebAssembly modules

### Network Policies

K8s Network Policies control pod-to-pod communication. By default, all pods can communicate with all other pods. Network Policies restrict traffic based on labels, namespaces, and IP blocks.

```
Default: allow all traffic between pods
With NetworkPolicy: deny all, then allow specific flows

┌──────────┐     allowed      ┌──────────┐
│ Frontend │────────────────►│ Backend  │
│ pods     │                  │ pods     │
└──────────┘                  └────┬─────┘
                                   │ allowed
      ✗ blocked                    ▼
┌──────────┐              ┌──────────────┐
│ Other    │──────✗──────►│  Database    │
│ namespace│              │  pods        │
└──────────┘              └──────────────┘
```

Requires a CNI plugin that supports Network Policies (Calico, Cilium, Weave Net).

## Runtime Security

### Falco (CNCF)

Open source runtime security tool that detects anomalous behavior in containers and Kubernetes using system call monitoring.

```
┌────────────────────────────────────────────────────┐
│                    Falco                            │
│                                                    │
│  Kernel ──► syscall stream ──► Falco Engine        │
│  (eBPF/                        │                   │
│   kernel module)          ┌────┴─────┐             │
│                           │  Rules   │             │
│                           │  Engine  │             │
│                           └────┬─────┘             │
│                                │                   │
│                           ┌────▼─────┐             │
│                           │  Alerts  │             │
│                           │ (stdout, │             │
│                           │  Slack,  │             │
│                           │  webhook)│             │
│                           └──────────┘             │
└────────────────────────────────────────────────────┘

Detection rules (subset):
- Shell spawned in container
- Sensitive file read (/etc/shadow, /etc/passwd)
- Binary written to /tmp or /dev/shm
- Network connection to unexpected destination
- Container escaped to host namespace
- Kubernetes API called from container
- Crypto mining binary executed
- Privileged container started
```

### seccomp Profiles

Restrict which system calls a container can make. K8s supports seccomp profiles via the securityContext.

```
Default Docker profile: blocks ~44 of ~300+ syscalls
RuntimeDefault: K8s applies the container runtime's default seccomp profile
Custom profiles: fine-grained per-workload syscall allowlists
```

### Read-Only Root Filesystem

Mount the container's root filesystem as read-only. Application writes go to explicitly mounted volumes (tmpfs, emptyDir). Prevents attackers from modifying binaries or dropping malware.

### Capability Dropping

Linux capabilities break root privilege into granular units. Drop all capabilities and add back only what is needed.

```
securityContext:
  capabilities:
    drop: ["ALL"]
    add: ["NET_BIND_SERVICE"]
```

## Comparison of Runtime Security Tools

```
┌──────────────────┬────────────┬──────────────┬──────────────┬──────────────┐
│ Tool             │ Detection  │ Prevention   │ Overhead     │ Approach     │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ Falco            │ Yes        │ Alert only   │ Low          │ Syscall      │
│                  │            │              │              │ monitoring   │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ Tetragon (Cilium)│ Yes        │ Yes (kill)   │ Low          │ eBPF-based   │
│                  │            │              │              │ enforcement  │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ Sysdig Secure    │ Yes        │ Yes          │ Low-Medium   │ Syscall +    │
│                  │            │              │              │ Falco-based  │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ KubeArmor        │ Yes        │ Yes (LSM)    │ Low          │ LSM + eBPF   │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ Aqua Runtime     │ Yes        │ Yes          │ Medium       │ Agent-based  │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ seccomp          │ No         │ Yes (block)  │ Very Low     │ Syscall      │
│                  │            │              │              │ filtering    │
├──────────────────┼────────────┼──────────────┼──────────────┼──────────────┤
│ AppArmor/SELinux │ No         │ Yes (MAC)    │ Very Low     │ Mandatory    │
│                  │            │              │              │ access ctrl  │
└──────────────────┴────────────┴──────────────┴──────────────┴──────────────┘
```

## Pros

- **Reduced Attack Surface**: minimal base images and capability dropping limit what attackers can exploit
- **Automated Scanning**: CI/CD-integrated scanning catches vulnerabilities before deployment
- **Policy Enforcement**: admission controllers prevent misconfigured workloads from running
- **Runtime Visibility**: syscall monitoring detects attacks that bypass static analysis
- **Network Segmentation**: Network Policies isolate pods and limit lateral movement
- **Compliance**: container security controls satisfy CIS Benchmarks, SOC 2, PCI-DSS, HIPAA
- **Immutable Infrastructure**: read-only filesystems and image signing ensure runtime matches build
- **Shift Left**: scanning in CI catches issues early when they are cheapest to fix
- **Declarative Security**: policies as code (Kyverno, OPA) are version-controlled and auditable

## Cons

- **Vulnerability Noise**: scanners produce thousands of CVEs, many not exploitable in context
- **Base Image Maintenance**: keeping base images patched requires continuous effort
- **Shared Kernel Risk**: containers share the host kernel, kernel exploits break all isolation
- **RBAC Complexity**: K8s RBAC is verbose and error-prone, over-permissive roles are common
- **Network Policy Gaps**: not all CNI plugins support Network Policies fully
- **Runtime Overhead**: syscall monitoring and policy engines add CPU and memory usage
- **False Positives**: runtime detection tools alert on legitimate behavior (shell in debug containers)
- **Tooling Fragmentation**: many overlapping tools with different policy languages and approaches
- **Operational Burden**: managing scanning, signing, policies, runtime monitoring across clusters is complex

## Use Cases

- **CI/CD Pipeline Gates**: block deployment of images with critical CVEs or missing signatures
- **Multi-Tenant Clusters**: isolating tenant workloads with namespaces, RBAC, Network Policies, and PSS
- **Compliance Enforcement**: enforcing CIS Kubernetes Benchmark controls via admission policies
- **Incident Detection**: Falco alerting on shell access, file modification, or unexpected network connections in production containers
- **Supply Chain Security**: signing images with Cosign, verifying in admission controllers, generating SBOMs
- **Regulatory Workloads**: healthcare, finance, government requiring audit trails and isolation guarantees
- **Edge and IoT**: securing containers on resource-constrained edge nodes with minimal attack surface
- **Platform Engineering**: internal developer platforms enforcing security guardrails transparently
- **Forensics**: capturing syscall traces and container state for post-incident analysis
- **Zero Trust in K8s**: mTLS between pods (service mesh) + Network Policies + RBAC + PSS restricted profile
