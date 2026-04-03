# GitOps

## What is it?

GitOps is an operational model where the desired state of infrastructure and applications is declared in Git, and automated agents continuously reconcile the actual state of the system to match what is in Git. Git becomes the single source of truth for what should be running. Changes are made via pull requests, reviewed by humans, and applied automatically by a controller that watches the repository. If someone manually changes the running system, the controller detects the drift and reverts it back to what Git says.

## Who created it? When?

The term "GitOps" was coined by **Alexis Richardson**, CEO of **Weaveworks**, in **2017** in a blog post describing how Weaveworks operated their Kubernetes clusters. The concept built on earlier infrastructure-as-code practices but added the continuous reconciliation loop as the defining characteristic. **ArgoCD** (created by **Intuit** in **2018**) and **Flux** (created by **Weaveworks** in **2016**, later donated to **CNCF**) became the dominant GitOps controllers. The **OpenGitOps** project under CNCF formalized the principles in **2021**.

## How it works?

### Core Principles (OpenGitOps)

1. **Declarative**: the entire system is described declaratively (YAML, HCL, JSON)
2. **Versioned and Immutable**: desired state is stored in Git with full history
3. **Pulled Automatically**: agents pull the desired state and apply it (no CI pushing to clusters)
4. **Continuously Reconciled**: agents monitor for drift and correct it automatically

### Push vs Pull Model

```
Traditional CI/CD (Push):

Developer ──► Git ──► CI Pipeline ──► kubectl apply ──► Cluster
                                      (CI has cluster credentials)

GitOps (Pull):

Developer ──► Git (desired state)
                    │
                    │ watches
                    ▼
              ┌──────────────┐
              │ GitOps Agent │ (runs inside cluster)
              │ (Argo/Flux)  │
              │              │
              │ compares Git  │
              │ vs cluster   │
              │              │
              │ applies diff │──► Cluster (actual state)
              └──────────────┘
                    │
                    │ detects drift
                    ▼
              reverts manual changes
```

### Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Git Repository                         │
│                                                          │
│  ├── apps/                                               │
│  │   ├── frontend/                                       │
│  │   │   ├── deployment.yaml                             │
│  │   │   ├── service.yaml                                │
│  │   │   └── ingress.yaml                                │
│  │   └── backend/                                        │
│  │       ├── deployment.yaml                             │
│  │       └── service.yaml                                │
│  ├── infrastructure/                                     │
│  │   ├── monitoring/                                     │
│  │   ├── cert-manager/                                   │
│  │   └── ingress-controller/                             │
│  └── clusters/                                           │
│      ├── production/                                     │
│      │   └── kustomization.yaml                          │
│      └── staging/                                        │
│          └── kustomization.yaml                          │
└──────────────┬───────────────────────────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐
│Staging │ │  Prod  │ │  Prod  │
│Cluster │ │Cluster1│ │Cluster2│
│(Flux)  │ │(Argo)  │ │(Argo)  │
└────────┘ └────────┘ └────────┘
```

## GitOps Controllers

### ArgoCD

The most popular GitOps controller. Provides a web UI, CLI, and API for managing applications.

```
┌─────────────────────────────────────────┐
│              ArgoCD                      │
│                                         │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ Application  │  │ App Controller   │  │
│  │ CRD          │  │                  │  │
│  │              │  │ - watches Git    │  │
│  │ source: git  │  │ - compares state │  │
│  │ dest: cluster│  │ - syncs diff     │  │
│  └─────────────┘  └──────────────────┘  │
│                                         │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ Web UI       │  │ Repo Server      │  │
│  │ (dashboard)  │  │ (renders         │  │
│  │              │  │  manifests from  │  │
│  │              │  │  Helm, Kustomize)│  │
│  └─────────────┘  └──────────────────┘  │
└─────────────────────────────────────────┘
```

- Application CRD points to a Git repo path and a target cluster/namespace
- Sync policies: manual, auto-sync, auto-prune, self-heal
- Supports Helm, Kustomize, Jsonnet, plain YAML
- Multi-cluster management from a single ArgoCD instance
- SSO integration, RBAC, audit logs
- ApplicationSets for templating many applications from one definition

### Flux (CNCF)

A set of composable controllers that each handle one concern.

```
┌──────────────────────────────────────────┐
│              Flux Controllers             │
│                                          │
│  Source Controller ──► fetches Git/Helm   │
│  Kustomize Controller ──► applies YAML   │
│  Helm Controller ──► manages Helm charts │
│  Notification Controller ──► alerts      │
│  Image Automation ──► updates image tags │
└──────────────────────────────────────────┘
```

- GitRepository, HelmRepository, Bucket as source types
- Kustomization CRD for applying manifests with dependencies
- Health checks and dependency ordering between resources
- Image reflector scans registries and updates Git with new tags
- Multi-tenancy via namespaced sources and RBAC

## Repository Strategies

```
┌──────────────────────┬──────────────────────────────────────────────┐
│ Strategy             │ Description                                   │
├──────────────────────┼──────────────────────────────────────────────┤
│ Mono-repo            │ All apps and infra in one repo. Simple but   │
│                      │ permissions and blast radius are broad.       │
├──────────────────────┼──────────────────────────────────────────────┤
│ Repo per app         │ Each application has its own config repo.    │
│                      │ Better isolation, more repos to manage.       │
├──────────────────────┼──────────────────────────────────────────────┤
│ Repo per environment │ Separate repos for staging, prod. Clear      │
│                      │ promotion path, some duplication.             │
├──────────────────────┼──────────────────────────────────────────────┤
│ Repo per team        │ Each team owns their config repo.            │
│                      │ Team autonomy, harder to enforce standards.   │
├──────────────────────┼──────────────────────────────────────────────┤
│ App repo + config    │ Source code and config in separate repos.    │
│ repo (recommended)   │ CI builds image, updates config repo with   │
│                      │ new tag. GitOps agent applies config repo.   │
└──────────────────────┴──────────────────────────────────────────────┘
```

## Comparison

```
┌──────────────────┬──────────────┬──────────────┬──────────────────────┐
│ Feature          │ ArgoCD       │ Flux         │ Jenkins X            │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ UI               │ Rich web UI  │ CLI + Weave  │ CLI                  │
│                  │              │ GitOps       │                      │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Multi-cluster    │ Yes (hub)    │ Yes (per     │ Yes                  │
│                  │              │ cluster)     │                      │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Manifest tools   │ Helm, Kust,  │ Helm, Kust   │ Helm                 │
│                  │ Jsonnet, YAML│ YAML         │                      │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Image automation │ Argo Image   │ Built-in     │ Built-in             │
│                  │ Updater      │ image reflec │                      │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ CNCF status      │ Graduated    │ Graduated    │ Archived             │
├──────────────────┼──────────────┼──────────────┼──────────────────────┤
│ Architecture     │ Centralized  │ Distributed  │ Centralized          │
│                  │ server       │ controllers  │                      │
└──────────────────┴──────────────┴──────────────┴──────────────────────┘
```

## Pros

- **Git as Source of Truth**: complete audit trail of every change (who, what, when, why)
- **Automatic Drift Detection**: manual changes are detected and reverted
- **Pull Request Workflow**: infrastructure changes go through code review
- **Rollback**: revert a Git commit to rollback any change
- **Security**: cluster credentials never leave the cluster (pull model)
- **Declarative**: desired state is explicit and version-controlled
- **Multi-Cluster**: manage hundreds of clusters from Git
- **Disaster Recovery**: rebuild a cluster from scratch by pointing the agent at Git

## Cons

- **Secret Management**: secrets cannot be stored in Git plaintext (need Sealed Secrets, SOPS, Vault)
- **Learning Curve**: ArgoCD and Flux have their own CRDs, patterns, and failure modes
- **Slow Feedback Loop**: changes go through Git → PR → merge → sync (slower than kubectl apply)
- **Git as Bottleneck**: Git repo availability becomes critical infrastructure
- **Manifest Generation**: Helm/Kustomize rendering adds complexity and debugging difficulty
- **Drift Noise**: legitimate temporary state (scaling events, pod restarts) can trigger false drift alerts
- **Stateful Resources**: databases, queues, and stateful systems are hard to manage declaratively
- **Multi-Tenancy**: isolating teams in a shared GitOps repo requires careful RBAC

## Use Cases

- **Kubernetes Fleet Management**: managing 10-1000+ clusters with consistent configuration
- **Environment Promotion**: promoting changes from dev → staging → prod via Git merges or PRs
- **Compliance**: audit trail of every infrastructure change for SOC 2, PCI-DSS, HIPAA
- **Disaster Recovery**: rebuilding clusters from Git after outages
- **Platform Engineering**: internal developer platforms with self-service namespace provisioning
- **Multi-Cloud**: consistent deployments across AWS, GCP, Azure Kubernetes clusters
- **Edge Computing**: managing hundreds of edge clusters from a central Git repository
- **Configuration Management**: managing ConfigMaps, network policies, RBAC across clusters
