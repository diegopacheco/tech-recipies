# Fine-Grained Authorization (ReBAC, Zanzibar, OpenFGA)

## What is it?

Fine-grained authorization (FGA) answers the question "can **this user** perform **this action** on **this specific object**?" — per document, per folder, per row — instead of the coarse "does this user have the admin role?". The dominant model is **ReBAC (Relationship-Based Access Control)**: permissions are derived from a graph of relationships between users, groups, and objects. "Alice can edit doc:readme" not because of a role, but because Alice **is owner of** the folder **that contains** the doc. This is how Google Docs sharing works, and it is the model Google formalized in its **Zanzibar** paper. ReBAC subsumes RBAC (a role is just a relation) and handles what ABAC struggles with: permissions that depend on structure (ownership, hierarchy, group nesting, sharing) rather than attributes. FGA typically ships as a dedicated centralized service that applications query with a single question: `check(user, relation, object) → yes/no`.

## Who created it? When?

Google built **Zanzibar** internally starting around **2013** and published the paper "**Zanzibar: Google's Consistent, Global Authorization System**" at **USENIX ATC 2019** (Ruoming Pang et al.). Zanzibar serves authorization for **Google Docs, Drive, YouTube, Photos, and Cloud IAM** — millions of authorization checks per second at 95th percentile latency under 10ms with 99.999% availability. The paper triggered a wave of open-source implementations: **SpiceDB** by **Authzed (2021, Jake Moshenko)**, **Ory Keto (2021)**, **Permify**, and **OpenFGA**, created by the **Auth0Lab team** and open-sourced in **2022**, then donated to the **CNCF** (sandbox 2022, incubating 2025). Auth0 sells the hosted version as **Auth0 FGA**. The policy-engine cousins are **OPA/Rego (Styra, 2016, CNCF graduated)** and **Cedar (AWS, 2023)**, which evaluate policies over inputs rather than storing a relationship graph.

## How it works?

### Relationship Tuples

The entire system state is a set of tuples: `object # relation @ user`.

```
doc:readme  # owner  @ user:alice
doc:readme  # parent @ folder:eng
folder:eng  # viewer @ group:engineering#member
group:engineering # member @ user:bob
```

Read as facts: Alice owns the readme; the readme lives in folder eng; members of the engineering group can view folder eng; Bob is a member of engineering. A tuple's user can itself be a **userset** (`group:engineering#member`), which is what makes the model a graph, not a table.

### The Authorization Model

The model (Zanzibar: namespace config; OpenFGA: type definitions) declares which relations exist and how they derive from each other:

```
model
  schema 1.1

type user

type group
  relations
    define member: [user]

type folder
  relations
    define owner: [user]
    define viewer: [user, group#member] or owner

type doc
  relations
    define parent: [folder]
    define owner: [user]
    define editor: [user] or owner
    define viewer: [user] or editor or viewer from parent
```

The expressive power lives in three operators: **union** (`or`), **computed relations** (owner implies editor implies viewer), and **tuple-to-userset** (`viewer from parent` — inherit viewers from the containing folder). Intersection and exclusion (`and`, `but not`) cover deny-style rules.

### Answering a Check

```
check(user:bob, viewer, doc:readme)?

                     doc:readme
                    /          \
        viewer? direct       viewer from parent
              │                     │
             no              folder:eng viewer?
                              /            \
                     direct user?      group:engineering#member?
                          no                    │
                                        member @ user:bob ✓
                                                │
                                              ALLOW
```

The engine walks the graph, expanding usersets, following parent links, memoizing subproblems. Core API surface:

```
┌──────────────┬───────────────────────────────────────────────────────┐
│ check        │ can user U do relation R on object O? → bool          │
│ expand       │ who can do R on O? → full userset tree                │
│ list-objects │ which objects can U do R on? (drives UI lists/search) │
│ list-users   │ which users have R on O? (drives sharing dialogs)     │
│ write/delete │ add or remove tuples (sharing = writing a tuple)      │
└──────────────┴───────────────────────────────────────────────────────┘
```

### Consistency: the New Enemy Problem

Zanzibar's deepest contribution is not the model — it is doing this **globally consistently**. The failure it prevents:

```
t1: Alice removes Bob from folder:eng          (revoke)
t2: Alice adds secret-plan.doc to folder:eng   (new content)
t3: Bob's check evaluates against a STALE replica
    that still has Bob in folder:eng           → Bob reads the
                                                 secret plan
```

A permission check using old ACLs against new content lets a "new enemy" see things they were revoked from. Zanzibar fixes this with **zookies**: opaque tokens encoding a (Spanner TrueTime) snapshot timestamp. Content writes store the zookie; checks pass it back, forcing evaluation at-or-after that snapshot — external consistency without paying full linearizability on every check. OpenFGA and SpiceDB carry the same idea as consistency tokens/modes.

## RBAC vs ABAC vs ReBAC

```
┌──────────────┬──────────────────────┬──────────────────────┬──────────────────────┐
│              │ RBAC                 │ ABAC                 │ ReBAC                │
├──────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Question     │ what roles do        │ what attributes do   │ how is the user      │
│ answered by  │ you hold?            │ user/resource/env    │ connected to this    │
│              │                      │ have right now?      │ object?              │
├──────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Granularity  │ coarse (per role)    │ fine (per rule)      │ fine (per object)    │
├──────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Great at     │ org-wide job         │ context: time, IP,   │ sharing, ownership,  │
│              │ functions            │ clearance, tenant    │ hierarchy, nesting   │
├──────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Weak at      │ per-object sharing   │ structural relations,│ pure attribute rules │
│              │ (role explosion)     │ "who can see what"   │ (needs contextual    │
│              │                      │ listing              │ tuples/conditions)   │
├──────────────┼──────────────────────┼──────────────────────┼──────────────────────┤
│ Reverse query│ easy                 │ nearly impossible    │ built-in             │
│ (list what   │                      │ (must evaluate every │ (list-objects)       │
│  U can see)  │                      │ policy per object)   │                      │
└──────────────┴──────────────────────┴──────────────────────┴──────────────────────┘
```

The classic tell that you have outgrown RBAC: roles named `project_42_viewer` multiplying per resource — that is a relationship graph screaming to exist. Modern engines blend models: OpenFGA supports **conditions** on tuples (ABAC-style constraints such as expiry or IP range) on top of the graph.

## Comparison of Engines

```
┌─────────────┬───────────────┬──────────────────┬────────────────────────┐
│ Engine      │ Origin        │ Model            │ Notable                │
├─────────────┼───────────────┼──────────────────┼────────────────────────┤
│ Zanzibar    │ Google 2019   │ ReBAC, Spanner   │ the paper; internal    │
│             │ (paper)       │ + zookies        │ only, powers Docs etc  │
├─────────────┼───────────────┼──────────────────┼────────────────────────┤
│ OpenFGA     │ Auth0Lab 2022 │ ReBAC + condit.  │ CNCF, DSL + Playground,│
│ / Auth0 FGA │               │                  │ hosted service         │
├─────────────┼───────────────┼──────────────────┼────────────────────────┤
│ SpiceDB     │ Authzed 2021  │ ReBAC, closest   │ caveats, watch API,    │
│             │               │ to the paper     │ strong consistency knbs│
├─────────────┼───────────────┼──────────────────┼────────────────────────┤
│ OPA / Rego  │ Styra 2016    │ policy-as-code   │ general-purpose (K8s   │
│             │               │ (no stored graph)│ admission, infra)      │
├─────────────┼───────────────┼──────────────────┼────────────────────────┤
│ Cedar       │ AWS 2023      │ policy language  │ formally verified,     │
│             │               │ RBAC+ABAC style  │ powers Verified Perms  │
└─────────────┴───────────────┴──────────────────┴────────────────────────┘
```

## Anti-Patterns

- **Authorization logic scattered through app code**: `if user.id == doc.owner_id or user.is_admin` copied into every handler, drifting per service
- **Role explosion**: minting a role per project/tenant/resource instead of modeling the relationship
- **Syncing permissions into JWT claims**: tokens go stale the moment someone is revoked; FGA checks are live
- **Ignoring the reverse query**: shipping check() but rendering lists by loading every object and filtering — list-objects exists for this
- **Skipping consistency thinking**: caching check results without a token/TTL strategy reintroduces the new enemy problem
- **Modeling everything as ReBAC**: pure environmental rules (business hours, IP allowlists) belong in conditions or a policy engine

## Pros

- **Per-object permissions at scale**: the Google Docs sharing model without role explosion
- **Centralized and consistent**: one service, one model, one audit point across all applications
- **Declarative and reviewable**: the authorization model is a small versionable text artifact security can actually read
- **Reverse queries built in**: "what can Alice see?" powers UI filtering and permission-aware search/RAG
- **Proven scale**: Zanzibar's published numbers (millions of QPS, <10ms p95, five nines) set the ceiling
- **Composable with RBAC/ABAC**: roles become relations; conditions add attributes — one engine covers the spectrum
- **Perfect fit for agent-era needs**: permission-aware RAG and scoped agent actions both reduce to fast check() calls

## Cons

- **New critical dependency**: the FGA service is on the hot path of every request — its latency and availability bound yours
- **Dual-write problem**: application data and relationship tuples must stay in sync (outbox/CDC patterns needed)
- **Modeling is genuinely hard**: recursive folders, nested groups, and exclusions take design iterations; a wrong model is a security bug
- **Consistency is subtle**: zookies/consistency tokens must be threaded through write paths or the guarantees quietly vanish
- **Migration cost**: retrofitting scattered inline checks into a central model is a long, risky refactor
- **Not ideal for pure policy rules**: heavy environmental/attribute logic fits OPA/Cedar better than tuples

## Use Cases

- **Document and file sharing**: Drive/Notion-style per-item sharing with folder inheritance
- **B2B multi-tenant SaaS**: org → team → project → resource hierarchies with per-tenant admins
- **Permission-aware RAG**: filtering vector-search results by what the asking user may read before the LLM sees them
- **Developer platforms**: repo/package/pipeline permissions with group nesting (GitHub-style)
- **Healthcare and finance**: per-record access where "role = doctor" is nowhere near enough
- **Social products**: audience controls ("friends of friends can comment") are literally graph relations
- **Cloud IAM**: resource-hierarchy permissions (organization/folder/project) — the Google Cloud IAM case itself

## Links

- Zanzibar paper (USENIX ATC 2019): https://www.usenix.org/conference/atc19/presentation/pang
- Zanzibar paper, annotated: https://zanzibar.tech/
- OpenFGA: https://openfga.dev/
- OpenFGA GitHub: https://github.com/openfga/openfga
- Auth0 FGA: https://auth0.com/fine-grained-authorization
- Auth0 FGA docs: https://docs.fga.dev/
- SpiceDB: https://authzed.com/spicedb
- Ory Keto: https://www.ory.sh/keto/
- OPA: https://www.openpolicyagent.org/
- Cedar: https://www.cedarpolicy.com/
- Google Cloud blog — Zanzibar overview: https://cloud.google.com/blog/topics/developers-practitioners/zanzibar-googles-consistent-global-authorization-system
