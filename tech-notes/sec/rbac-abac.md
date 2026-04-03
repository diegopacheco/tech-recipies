# RBAC, ABAC, and Policy-Based Access Control

## What is it?

Access control determines who can do what on which resources. There are three major models for making access decisions: **RBAC (Role-Based Access Control)** assigns permissions to roles and assigns roles to users. **ABAC (Attribute-Based Access Control)** evaluates policies against attributes of the user, resource, action, and environment at request time. **Policy-Based Access Control (PBAC)** externalizes authorization logic into a dedicated policy engine that applications query for access decisions. These models can be combined — most production systems use a mix.

## Who created them? When?

RBAC was formalized by **David Ferraiolo and Richard Kuhn** at **NIST** in **1992** in the paper "Role-Based Access Controls." The NIST RBAC standard (INCITS 359) was published in **2004**. ABAC was formalized by NIST in **SP 800-162** in **2014** as a more flexible alternative. **XACML (eXtensible Access Control Markup Language)** was standardized by **OASIS** in **2003** as the first policy language for ABAC. **OPA (Open Policy Agent)** was created by **Styra** in **2016** and became a **CNCF graduated project** in **2021**. **AWS Cedar** was released in **2023** as a new policy language designed for verifiable, analyzable authorization. Google's **Zanzibar** paper (**2019**) described the relationship-based access control system powering Google Drive, YouTube, and Cloud IAM.

## RBAC (Role-Based Access Control)

### How it works

Users are assigned to roles. Roles are granted permissions. Users inherit all permissions of their assigned roles.

```
┌──────────┐     assigned to     ┌──────────┐     has      ┌──────────────┐
│  User    │────────────────────►│  Role    │────────────►│ Permission   │
│          │                     │          │             │              │
│  alice   │──► developer ──────►│developer │──►read:code │              │
│  bob     │──► admin ──────────►│admin     │──►read:code │              │
│  carol   │──► viewer ─────────►│viewer    │──►read:logs │              │
└──────────┘                     └──────────┘             └──────────────┘

alice (developer): read:code, write:code, run:tests
bob (admin):       read:code, write:code, run:tests, manage:users, manage:infra
carol (viewer):    read:code, read:logs
```

### RBAC Components (NIST Model)

```
┌────────────────────────────────────────────────────────────┐
│                       RBAC Model                           │
│                                                            │
│  Core RBAC:                                                │
│    Users ──► Roles ──► Permissions                         │
│    Sessions (user activates subset of assigned roles)      │
│                                                            │
│  Hierarchical RBAC:                                        │
│    Role inheritance (senior_dev inherits from dev)          │
│                                                            │
│    admin                                                   │
│      └── senior_dev                                        │
│            └── dev                                         │
│                  └── viewer                                │
│                                                            │
│  Constrained RBAC:                                         │
│    Separation of Duty (SoD):                               │
│    - Static SoD: user cannot hold conflicting roles        │
│      (e.g., cannot be both "approver" and "requester")     │
│    - Dynamic SoD: user cannot activate conflicting roles   │
│      in the same session                                   │
└────────────────────────────────────────────────────────────┘
```

### RBAC in Practice

**Kubernetes RBAC**: Role/ClusterRole define permissions on K8s resources. RoleBinding/ClusterRoleBinding bind subjects (users, groups, service accounts) to roles.

**AWS IAM**: policies attached to IAM roles. EC2 instances, Lambda functions, and ECS tasks assume roles to get temporary credentials.

**Database RBAC**: PostgreSQL roles with GRANT/REVOKE on tables, schemas, functions. MySQL users with privileges on databases and tables.

**Application RBAC**: frameworks like Spring Security, Django, Rails provide role-based authorization decorators and middleware.

## ABAC (Attribute-Based Access Control)

### How it works

Access decisions are made by evaluating policies against attributes at request time. No predefined role assignments — the policy engine considers all relevant attributes dynamically.

```
┌─────────────────────────────────────────────────────────────────┐
│                      ABAC Decision                              │
│                                                                 │
│  Subject Attributes    Resource Attributes    Environment       │
│  - user.role           - resource.type        - time            │
│  - user.department     - resource.owner       - ip_address      │
│  - user.clearance      - resource.class       - location        │
│  - user.training       - resource.sensitivity - device_posture  │
│           │                    │                     │           │
│           └────────────┬───────┘                     │           │
│                        ▼                             │           │
│                ┌───────────────┐                     │           │
│                │ Policy Engine │◄────────────────────┘           │
│                │               │                                │
│                │ IF subject.dept == resource.dept                │
│                │ AND subject.clearance >= resource.sensitivity   │
│                │ AND environment.time IN working_hours           │
│                │ THEN allow                                      │
│                │ ELSE deny                                       │
│                └───────┬───────┘                                │
│                        │                                        │
│                   allow / deny                                  │
└─────────────────────────────────────────────────────────────────┘
```

### ABAC Attribute Categories

```
┌──────────────────┬──────────────────────────────────────────────┐
│ Category         │ Attributes                                   │
├──────────────────┼──────────────────────────────────────────────┤
│ Subject          │ user ID, role, department, clearance level,   │
│                  │ group membership, training status, manager    │
├──────────────────┼──────────────────────────────────────────────┤
│ Resource         │ type, owner, classification, sensitivity,     │
│                  │ department, creation date, tags               │
├──────────────────┼──────────────────────────────────────────────┤
│ Action           │ read, write, delete, approve, transfer,       │
│                  │ export, admin                                 │
├──────────────────┼──────────────────────────────────────────────┤
│ Environment      │ time of day, IP address, location, device     │
│                  │ type, network zone, threat level              │
└──────────────────┴──────────────────────────────────────────────┘
```

### XACML (eXtensible Access Control Markup Language)

The original ABAC policy standard (OASIS, 2003). XML-based policy language with a formal architecture.

```
┌────────────────────────────────────────────────────────────┐
│                    XACML Architecture                       │
│                                                            │
│  App ──► PEP ──► PDP ──► PIP                               │
│          (enforcement) (decision) (attribute lookup)        │
│                    │                                       │
│                    ▼                                       │
│                  PAP (policy administration point)          │
│                  (where policies are authored)              │
└────────────────────────────────────────────────────────────┘
```

Powerful but complex. XML verbosity made it unpopular for modern systems. Replaced in practice by OPA/Rego, Cedar, and custom solutions.

## Policy-Based Access Control (PBAC)

### OPA (Open Policy Agent)

A general-purpose policy engine (CNCF graduated). Decouples policy from application code. Policies are written in **Rego**, a declarative query language. Applications send structured JSON requests to OPA and receive allow/deny decisions.

```
┌──────────┐   {input}    ┌──────────┐
│   App    │─────────────►│   OPA    │
│          │◄─────────────│          │
│          │  {allow:T/F} │  ┌─────┐ │
└──────────┘              │  │Rego │ │
                          │  │Rules│ │
                          │  └─────┘ │
                          │  ┌─────┐ │
                          │  │Data │ │
                          │  └─────┘ │
                          └──────────┘

Rego policy:

package authz

default allow := false

allow if {
    input.method == "GET"
    input.path == ["api", "public"]
}

allow if {
    input.method == "GET"
    input.user.role == "developer"
    input.path[0] == "api"
}

allow if {
    input.user.role == "admin"
}
```

OPA use cases:
- **Kubernetes admission control** (OPA Gatekeeper): enforce policies on K8s resources
- **API authorization**: microservices query OPA for per-request authorization
- **Terraform policy** (Conftest): validate infrastructure-as-code before apply
- **Data filtering**: OPA can return partial results (which rows/fields a user can see)

### AWS Cedar

A policy language created by AWS (2023) designed specifically for authorization. Used internally by AWS Verified Permissions and Amazon Verified Access. Designed to be analyzable — policies can be formally verified for correctness.

```
Cedar policy:

permit (
    principal in Group::"developers",
    action in [Action::"read", Action::"list"],
    resource in Folder::"src"
);

forbid (
    principal,
    action in [Action::"delete"],
    resource
) unless {
    principal in Group::"admin"
};

permit (
    principal,
    action in [Action::"read"],
    resource
) when {
    resource.classification == "public"
};
```

Cedar features:
- **Formal verification**: Cedar policies can be mathematically proven to not conflict
- **Fast evaluation**: designed for sub-millisecond authorization decisions
- **Entity-based**: models principals, actions, and resources as typed entities with hierarchies
- **Analyzable**: tooling can answer "can user X ever access resource Y?" without running the system
- **Open source**: available on GitHub (cedar-policy/cedar)

### Google Zanzibar

Google's global authorization system (2019 paper). Powers Google Drive, YouTube, Google Cloud IAM, and more. Uses relationship-based access control (ReBAC) — access is determined by the relationships between objects.

```
Zanzibar relationship tuples:

doc:readme#viewer@user:alice
doc:readme#owner@user:bob
folder:src#viewer@group:developers#member
group:developers#member@user:alice
group:developers#member@user:carol

Check: can alice view doc:readme?
  → alice is a member of group:developers
  → group:developers has viewer on folder:src
  → doc:readme is in folder:src
  → YES (transitive relationship)
```

Open source implementations:
- **SpiceDB (AuthZed)**: most mature Zanzibar-inspired system
- **OpenFGA (Auth0/Okta)**: CNCF sandbox project
- **Keto (Ory)**: Go-based Zanzibar implementation

## Comparison

```
┌──────────────────┬──────────────┬──────────────┬──────────────┬──────────────┐
│ Aspect           │ RBAC         │ ABAC         │ OPA/Rego     │ Cedar        │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Decision basis   │ Role         │ Attributes   │ Policy rules │ Policy rules │
│                  │ membership   │ of subject,  │ on structured│ on typed     │
│                  │              │ resource,    │ JSON input   │ entities     │
│                  │              │ environment  │              │              │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Granularity      │ Coarse       │ Fine         │ Fine         │ Fine         │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Scalability      │ Role         │ Scales well  │ Scales well  │ Scales well  │
│                  │ explosion    │              │              │              │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Policy language  │ Config/DB    │ XACML/custom │ Rego         │ Cedar        │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Formal verify    │ No           │ No           │ Partial      │ Yes          │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Learning curve   │ Low          │ Medium       │ Medium-High  │ Medium       │
├──────────────────┼──────────────┼──────────────┼──────────────┼──────────────┤
│ Best for         │ Simple org   │ Complex,     │ K8s, APIs,   │ AWS-native,  │
│                  │ hierarchies  │ context-     │ infra-as-    │ verifiable   │
│                  │              │ dependent    │ code policy  │ authz        │
└──────────────────┴──────────────┴──────────────┴──────────────┴──────────────┘
```

```
┌──────────────────┬──────────────┬──────────────┬──────────────┐
│ Aspect           │ Zanzibar/    │ Kyverno      │ Casbin       │
│                  │ SpiceDB      │              │              │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Decision basis   │ Relationship │ K8s resource │ Model-based  │
│                  │ graphs       │ matching     │ (pluggable)  │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Granularity      │ Very Fine    │ K8s-scoped   │ Fine         │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Policy language  │ Schema +     │ YAML         │ PERM model   │
│                  │ tuples       │              │ + policy file│
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Best for         │ Google-scale │ K8s-native   │ App-level    │
│                  │ multi-tenant │ policy       │ RBAC/ABAC    │
│                  │ authz        │ enforcement  │ in any lang  │
└──────────────────┴──────────────┴──────────────┴──────────────┘
```

## Pros

### RBAC
- **Simple to understand**: roles map naturally to organizational structure
- **Easy to audit**: list users in a role to see who has what access
- **Widely supported**: built into every major system (K8s, AWS, databases, frameworks)
- **Low overhead**: role checks are simple lookups
- **Compliance friendly**: auditors understand role-based models

### ABAC
- **Fine-grained control**: decisions based on any combination of attributes
- **No role explosion**: scales to complex scenarios without creating hundreds of roles
- **Context-aware**: considers time, location, device, risk level in decisions
- **Dynamic**: policies adapt to changing conditions without reassigning roles
- **Privacy-aware**: can enforce data classification and handling rules

### Policy Engines (OPA, Cedar)
- **Decoupled authorization**: policy logic is separate from application code
- **Testable**: policies can be unit tested independently
- **Version controlled**: policies stored as code in git
- **Consistent**: same policy engine enforces rules across multiple services
- **Auditable**: centralized policy decisions with logging

## Cons

### RBAC
- **Role explosion**: fine-grained access requires many roles, becoming unmanageable
- **Static**: cannot consider context (time, location, device) in decisions
- **Coarse-grained**: same role applies everywhere, no resource-level conditions
- **Over-permissioning**: users accumulate roles over time (role creep)
- **Poor fit for dynamic environments**: cloud-native, microservices need more flexibility

### ABAC
- **Complexity**: defining and maintaining attribute-based policies is harder than role assignment
- **Performance**: evaluating multiple attributes per request adds latency
- **Debugging difficulty**: tracing why a request was denied across many attributes is hard
- **Attribute management**: ensuring consistent, accurate attributes across systems is challenging
- **Visibility**: harder to answer "who has access to what" compared to RBAC

### Policy Engines (OPA, Cedar)
- **Learning curve**: Rego is a non-trivial language to learn and debug
- **Operational overhead**: running and scaling a policy engine is another infrastructure component
- **Latency**: network round-trip to policy engine for every authorization decision
- **Policy sprawl**: without governance, policies accumulate and conflict
- **Testing burden**: policies need comprehensive test coverage to avoid unintended access

## Use Cases

- **Kubernetes Authorization**: RBAC for API access, OPA Gatekeeper/Kyverno for admission policies
- **Multi-Tenant SaaS**: Zanzibar/SpiceDB for tenant isolation with relationship-based access
- **Healthcare**: ABAC for HIPAA compliance (access based on role + patient relationship + data sensitivity)
- **Financial Services**: RBAC + ABAC for separation of duties and transaction limits
- **Cloud Infrastructure**: AWS IAM policies, GCP IAM, Azure RBAC for resource access control
- **API Authorization**: OPA sidecar evaluating per-request policies for microservices
- **Data Access**: ABAC policies controlling which columns/rows a user can query based on classification
- **CI/CD Security**: OPA/Conftest validating Terraform plans and Kubernetes manifests before apply
- **Document Management**: Zanzibar-style sharing (viewer, editor, owner) with transitive permissions
- **Regulatory Compliance**: Cedar for formally verifiable authorization in regulated industries
