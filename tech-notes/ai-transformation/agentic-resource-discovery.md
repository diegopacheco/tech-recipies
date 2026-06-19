# Agentic Resource Discovery (ARD)

## What is it?

**Agentic Resource Discovery (ARD)** is an open specification for *publishing, discovering, and verifying* the capabilities an AI agent can call on — tools, MCP servers, Skills, A2A agents, OpenAPI tools, workflows — across the open web and inside an enterprise. It is the **discovery layer that sits in front of MCP, A2A, and Skills**. Those protocols all assume the agent already knows *which* tool, instruction, or agent it needs; ARD answers the question that comes before invocation: *"What is available for this task, and is it safe to connect to?"*

The spec's own framing: an AI client is no longer limited to what the model knows — it can reach "agentic resources," meaning *any* external capability representable as an AI Catalog entry. The number of those resources is exploding (10,000+ public MCP servers alone by late 2025), they live in fragmented per-vendor registries, and there has been no standard way to find one across an organizational boundary. ARD is the proposed fix: a federated, web-native search layer where publishers describe their capabilities in an `ai-catalog.json` file on their own domain, registries crawl and index those files, and a client searches in plain language and gets back ranked, verifiable matches.

It was published **June 17, 2026** by Google (developers blog) and Hugging Face on the same day, with Microsoft as a co-author. Crucially, ARD is **not a runtime and not a marketplace** — it does not replace MCP or A2A, it does not execute anything, and there is no single central catalog. It is closer to *DNS + a search engine for agent capabilities* than to an app store.

## The Numbers

```
┌────────────────────────────────────────────────┬───────────────────────────┐
│ Fact                                            │ Value                     │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Spec version / status                           │ v0.9 (Draft), "Proposal"  │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Spec dated                                      │ May 28, 2026              │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Public announcement                             │ Jun 17, 2026 (Google +    │
│                                                 │ Hugging Face, same day)   │
├────────────────────────────────────────────────┼───────────────────────────┤
│ License                                         │ Apache 2.0                │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Built on                                        │ the AI Catalog data model │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Contributing organizations                      │ ~11 (Microsoft + Google,  │
│                                                 │ AWS, Cisco, Databricks,   │
│                                                 │ GitHub, GoDaddy, Hugging  │
│                                                 │ Face, NVIDIA, Salesforce, │
│                                                 │ ServiceNow, Snowflake)    │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Named authors                                   │ 3 (Bu/Google,             │
│                                                 │ Guha/Microsoft,           │
│                                                 │ Smith/Hugging Face)       │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Discovery API surface                           │ 2 REST endpoints          │
│                                                 │ (POST /search, GET /agents)│
├────────────────────────────────────────────────┼───────────────────────────┤
│ Manifest location                               │ /.well-known/             │
│                                                 │ ai-catalog.json           │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Relevance score range                           │ 0–100 (informational,     │
│                                                 │ NOT a safety/trust rating)│
├────────────────────────────────────────────────┼───────────────────────────┤
│ Schemas                                         │ JSON Schema 2020-12 +     │
│                                                 │ OpenAPI 3.1.0             │
└────────────────────────────────────────────────┴───────────────────────────┘
```

## The three questions ARD answers

Google's engineers framed the whole spec around three questions an agent cannot currently answer across an organizational boundary:

```
┌──────────────────────────────────────────────────────────────────────┐
│  1. WHERE does the right capability live?                             │
│       → federated registries + ai-catalog.json on the publisher's     │
│         own domain                                                     │
│  ──────────────────────────────────────────────────────────────────   │
│  2. WHICH capability should I actually use?                           │
│       → natural-language search, ranked by semantic relevance          │
│  ──────────────────────────────────────────────────────────────────   │
│  3. HOW do I verify it is safe to connect to?                        │
│       → trust manifest: domain-anchored identity, signatures,         │
│         attestations, provenance — checked BEFORE connecting          │
└──────────────────────────────────────────────────────────────────────┘
```

The motivating case in the announcement: an operations agent debugging a live incident may need to query observability systems, search engineering docs, review deployment history, open tickets, and consult specialist troubleshooting agents — each behind a different siloed registry. ARD is the standard that lets one agent find all of them across boundaries and establish trust in what it finds.

## Where it sits in the stack

ARD is a *pre-invocation* layer. It helps the client pick the resource; the resource is then invoked through its own native protocol. It composes with the existing agent protocols rather than competing with them.

```
┌──────────────────────────────────────────────────────────────────────┐
│  ARD             "what exists & can I trust it?" — find the resource  │
│  (discovery)      before you ever connect (this spec)                 │
│  ──────────────────────────────────────────────────────────────────   │
│  MCP              a standard way for an agent to call a TOOL          │
│  A2A              a standard way for an agent to call ANOTHER agent   │
│  Skills           a standard way for an agent to consume INSTRUCTIONS │
│  (invocation)     OpenAPI / native API runtimes                      │
│  ──────────────────────────────────────────────────────────────────   │
│  AI Catalog       the shared data model ARD reuses to DESCRIBE any    │
│  (description)    resource — what it does, who provides it, how to    │
│                   reach it (ARD v0.9 aligns to this standard)         │
└──────────────────────────────────────────────────────────────────────┘
```

This is the same shape the [[agentic-commerce]] note already drew for payments — MCP as the discovery/catalog primitive, separate protocols for the action — except ARD generalizes "discovery" into a first-class, standalone, searchable layer. Where [[autosearch]] is about agents searching *the web for information*, ARD is agents searching *a registry for capabilities*.

## How it works — catalogs + registries

The architecture rests on two primitives, and that is deliberately the whole protocol.

```
┌──────────────────────────────────────────────────────────────────────┐
│  CATALOG                                                              │
│   A publisher hosts ai-catalog.json at a well-known path on its       │
│   OWN domain (example.com/.well-known/ai-catalog.json).               │
│   It lists MCP servers, A2A agents, OpenAPI tools, or nested          │
│   catalogs. Ownership of the domain IS the cryptographic root of      │
│   trust (you can only publish under a domain you control — same       │
│   model that made schema.org work for the web).                       │
│                                                                      │
│  REGISTRY                                                            │
│   A search engine for the agentic web. It crawls catalogs, indexes   │
│   them, and exposes a REST search endpoint. On a query it returns     │
│   matching capabilities PLUS the metadata needed to verify the        │
│   publisher before any connection is made. Anyone can run one;        │
│   enterprises run private ones over internal inventory.               │
└──────────────────────────────────────────────────────────────────────┘
```

The end-to-end flow runs in four stages (the spec presents it as five steps, "describe → publish → index → search → reach from a chatbot"):

```
┌──────────────────────────────────────────────────────────────────────┐
│  1. PUBLISH    Provider posts ai-catalog.json at the well-known path  │
│                on its domain, describing each capability.             │
│  2. DISCOVER   The agent either queries a registry with a plain-      │
│                language intent, OR bypasses search and fetches a       │
│                catalog directly from a known partner's domain.        │
│  3. VERIFY     Publisher-attached trust metadata lets the agent or    │
│                registry confirm the publisher's cryptographic         │
│                identity BEFORE connecting.                            │
│  4. CONNECT    The agent loads the capability and interacts with it   │
│                through its native protocol/API (A2A, MCP, OpenAPI),   │
│                then returns the result.                               │
└──────────────────────────────────────────────────────────────────────┘
```

A client — Claude, ChatGPT, Copilot, or Gemini — reaches a registry (an "Agent Finder") through a **Skill or a remote MCP connector**: ask it to find a capability for a task, it searches, presents the matches, and the human (or the orchestrator) decides what to install. The spec's own integration walkthrough: a user says *"Book me a flight to Tokyo and file the travel expense report"*; the orchestrator queries the enterprise registry with `federation: "referrals"`, gets back an internal expense agent plus referrals to other registries, follows a referral to a public registry for flight-booking agents, and then invokes each with its own protocol (A2A for booking, MCP for expense filing).

## The data model — `ai-catalog.json`

Each entry in the catalog's `entries` array is an AI Catalog object. Required fields plus the most important optional ones:

```
┌────────────────────┬──────────────────────────────────────────────────────┐
│ Field              │ Meaning                                              │
├────────────────────┼──────────────────────────────────────────────────────┤
│ identifier   (req) │ Globally unique logical ID, domain-anchored URN:     │
│                    │ urn:ai:<publisher>:<namespace>:<agent-name>          │
│ displayName  (req) │ Human-readable name                                  │
│ type         (req) │ Media type of the artifact (e.g.                     │
│                    │ application/a2a-agent-card+json)                     │
│ url / data   (req) │ EXACTLY one: a URL to fetch the artifact, OR the     │
│                    │ full artifact document inline                        │
├────────────────────┼──────────────────────────────────────────────────────┤
│ description        │ Short description                                     │
│ tags               │ Keywords for filtering                                │
│ capabilities       │ Skill/tool strings (e.g. ["WeatherTool"]) for fast   │
│                    │ DB filtering without a full artifact lookup          │
│ representativeQuer.│ 2–5 sample NL queries (e.g. "find me a flight        │
│                    │ booking agent") used to build search embeddings      │
│ version            │ Artifact version                                     │
│ updatedAt          │ ISO 8601 timestamp                                   │
│ metadata           │ Custom key-value pairs                               │
│ trustManifest      │ Verifiable identity + trust metadata (see below)     │
└────────────────────┴──────────────────────────────────────────────────────┘
```

Why a `urn:ai:` URN instead of a plain URL? The spec is explicit: the identifier is an **immutable noun**, not a mutable location. An HTTP URL conflates *what a capability is* with *where it currently runs* — migrate clouds or restructure a gateway and the URL breaks. The URN is a permanent contract; the physical endpoint lives in the separate `url`/`data` field. Anchoring the URN to a domain also gives global uniqueness via the DNS root (no central registration database) and stops a malicious publisher from claiming `urn:ai:google.com:tax-agent` for a namespace it does not own.

## Identity and trust

Trust is a separate object that travels with each entry, decoupled from the discovery handle. This is the part that answers question #3.

```
┌────────────────────┬──────────────────────────────────────────────────────┐
│ trustManifest      │                                                      │
├────────────────────┼──────────────────────────────────────────────────────┤
│ identity     (req) │ Cryptographic workload ID — a SPIFFE ID, DID, or     │
│                    │ HTTPS FQDN. Its trust domain MUST align with the     │
│                    │ authority domain in the discovery identifier.        │
│ identityType       │ Hint: "did", "spiffe", "https"                      │
│ attestations       │ Verifiable claims — e.g. SOC2-Type2, HIPAA-Audit,    │
│                    │ each with a uri and a digest                          │
│ provenance         │ Lineage links — relation ("derivedFrom",            │
│                    │ "publishedFrom"), sourceId, sourceDigest             │
│ signature          │ Detached JWS over the manifest content               │
└────────────────────┴──────────────────────────────────────────────────────┘
```

A hard line the spec draws: the search **relevance score (0–100) is informational only** and "MUST NOT be interpreted by orchestrators as a cryptographic trust, compliance, or safety rating." Relevance and trust are fully decoupled — a result ranking first is *not* a result that is safe. Authentication of the workload itself is delegated to the artifact protocol, not the discovery layer (separation of concerns).

## The ARD API

Discovery requires a universal baseline: any compliant registry **MUST** expose an HTTP REST search interface, regardless of its execution stack.

```
┌──────────────────────────────────────────────────────────────────────┐
│  POST /search                                                         │
│   {                                                                   │
│     "query": { "text": "find me a flight booking agent",             │
│                "filter": { "type": ["application/a2a-agent-card+json"] } }, │
│     "federation": "referrals",     // auto (default) | referrals | none │
│     "pageSize": 5                   // default 10, max 100            │
│   }                                                                   │
│   → ranked catalog entries + score(0-100) + optional referrals        │
│                                                                      │
│  GET /agents          → list / browse entries (paginated)            │
└──────────────────────────────────────────────────────────────────────┘
```

Filters use a small EBNF-like syntax (`displayName`, `type`, `publisherId`, `createdAfter`, `updatedAfter`) — logical AND across parameters, OR within one. Standard error codes mirror HTTP: `400 INVALID_ARGUMENT`, `401 UNAUTHENTICATED`, `404 NOT_FOUND`, `429 RATE_LIMIT_EXCEEDED`, `500 INTERNAL_ERROR`. The manifest is formally defined as JSON Schema (Draft 2020-12), the API as OpenAPI 3.1.0, and the project ships a conformance-testing tool that validates both local manifests and live registry endpoints.

## Federation

Registries are not islands. ARD defines how they crawl and refer to one another:

- **Web ingestion (required):** every registry MUST crawl `ai-catalog.json` files from discovered URIs. Optional pipelines may scan git repos, npm, or OCI registries.
- **Federation modes** on a query: `auto` (default), `referrals` (the registry returns pointers to other registries it cannot answer for), or `none`.
- **Informative advanced resolution:** registries may use an LLM to translate the NL query into structured attributes (`domain: travel, skill: flight_booking`), build dense vector embeddings (matching "foreign exchange" to "forex"), and route across a Distributed Hash Table (an extended IPFS Kademlia DHT) or via DNS-AID to find authoritative registries for a domain.

## Common practices

```
┌──────────────────────────────────────────────────────────────────────┐
│  • Host ai-catalog.json at /.well-known/ on a domain you control —    │
│    the domain IS your identity.                                       │
│  • Add 2–5 representativeQueries per entry; they feed the registry's  │
│    semantic embeddings and decide whether you get found.              │
│  • Use the capabilities array for cheap pre-filtering before a full   │
│    artifact fetch.                                                    │
│  • Attach a trustManifest with attestations (SOC2, HIPAA) for         │
│    anything production-facing.                                        │
│  • Run a private enterprise registry over internal inventory — like  │
│    an intranet search engine for your own agents.                     │
│  • Chain registries with federation: "referrals" instead of one      │
│    monolithic index.                                                  │
│  • Expose the registry to chatbots as a Skill or a remote MCP         │
│    connector ("Agent Finder").                                        │
│  • Validate with the conformance tool / ajv before publishing.        │
└──────────────────────────────────────────────────────────────────────┘
```

## Who is doing what

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Player            │ What they're doing                                   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Google            │ Co-announced (Jun 17, 2026). Author Junjie Bu;       │
│                   │ blog by Bu + Srinivas Krishnan. Frames ARD as "the   │
│                   │ missing layer of the agentic web."                   │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Microsoft         │ "Developing ARD in collaboration with" the partner   │
│                   │ list. Author R.V. Guha — the creator of RSS, RDF,    │
│                   │ and schema.org, i.e. the person who made the web     │
│                   │ machine-readable, now doing it for agents.           │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Hugging Face      │ Shipped a working implementation (Ben Burtenshaw,    │
│                   │ Shaun Smith). Author Shaun Smith. Pitch: move        │
│                   │ capability selection OUTSIDE the LLM context window. │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Cisco (Outshift)  │ Enterprise-scale angle: agents finding each other    │
│                   │ across org boundaries; ties to its agent-naming/     │
│                   │ AGNTCY work.                                         │
├──────────────────┼──────────────────────────────────────────────────────┤
│ GitHub            │ Backing the standard as a discovery host for code-   │
│                   │ adjacent agents and tools.                           │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Snowflake /       │ Published own positioning blogs; data-platform and   │
│ Databricks        │ governed-catalog framing.                            │
├──────────────────┼──────────────────────────────────────────────────────┤
│ GoDaddy           │ "Identity and discovery must work together" — domain │
│                   │ ownership as the trust anchor is squarely its lane.  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ AWS, NVIDIA,      │ Named contributors / acknowledged reviewers in the   │
│ Salesforce,       │ spec.                                                │
│ ServiceNow        │                                                      │
└──────────────────┴──────────────────────────────────────────────────────┘
```

The cross-vendor lineup is the headline: Google, Microsoft, AWS, and Hugging Face agreeing on one spec at launch is rare and is the strongest signal ARD is a serious bid for the standard, not a single-vendor play.

## Pros

- **It fixes the right problem.** Today's model is *install-first, use-later* — a developer hardcodes an MCP URL into a config and reuses it. That works for the handful of tools an agent uses daily; it does not scale to thousands of ad-hoc surfaces. ARD makes discovery dynamic and intent-based.
- **Selection moves out of the LLM context.** The fallback today is dumping every tool description into the context window and letting the model pick — capped by the [[token-maxing|token budget]] and prone to thin descriptions. A registry indexes far richer signals (publisher identity, representative queries, attestations, tags) and returns a short ranked list. This is a direct [[harness-engineering|harness firewall]] move: keep the catalog out of the prompt.
- **Layers cleanly, replaces nothing.** ARD complements MCP/A2A/Skills instead of competing — a sane response to the protocol pile-up.
- **Web-native trust.** Reuses what already works: `/.well-known/`, domain ownership, REST, JSON Schema, OpenAPI, JWS, DID/SPIFFE. Domain-anchored URNs stop namespace squatting without a central registrar.
- **Federated, not a gatekeeper.** No single catalog; enterprises run private registries; public ones can compete on coverage vs. quality. Apache 2.0, any agent or tool can participate.
- **Heavyweight, multi-vendor backing on day one** — the alignment MCP took a year to earn, ARD launched with.
- **The right pedigree.** R.V. Guha already did exactly this for the document web with schema.org; applying the same playbook to agents is a credible bet, not a guess.

## Cons

- **Acronym soup, one more layer.** MCP, A2A, Skills, ACP, AP2, AGNTCY — and now ARD. Even if it composes cleanly, it is another spec to learn, host, and keep in sync, and it depends on the *also-evolving* AI Catalog standard (v0.9 just "aligns" to it).
- **Very early.** v0.9 Draft, status "Proposal." Field names, the API, and the trust model will change; building on it now means tracking a moving target.
- **Discovery ≠ safety.** ARD verifies *who published* a capability (domain identity), not *what the capability does*. A signed catalog from a legitimately-owned domain can still point at a malicious or rug-pull tool that behaves after you connect. The spec explicitly says the relevance score is not a safety rating — so the "is it safe to use" half of question #3 is left to layers ARD does not define.
- **The index is an attack surface.** `representativeQueries`, `description`, and `tags` are publisher-controlled and feed the registry's embeddings — i.e. SEO/ranking gaming, capability spam, and prompt-injection-via-description all become first-class concerns. Whoever ranks results holds real power.
- **Recentralization in practice.** "Many registries" in theory; but search consolidates, and a few big registries (Google, Hugging Face, GitHub, Microsoft) plausibly become the de-facto search engines for the agentic web — the same gatekeeping dynamics ARD's federation is supposed to avoid. See the registry-power critique in [[death-github]].
- **Domain-as-trust-root inherits DNS's weaknesses** — expired domains, takeovers, subdomain abuse, lapsed certs all become agent-trust problems.
- **Chicken-and-egg adoption.** Agents will not query registries until catalogs are rich; orgs will not publish catalogs until agents query them. Needs the big clients (Claude, ChatGPT, Gemini, Copilot) to ship ARD search by default to break the loop.

## What This Means

ARD is the agent ecosystem admitting that a world of millions of MCP servers, A2A agents, and Skills is useless if an agent cannot *find* the right one — and that hardcoding URLs into config files is the install-first dead end. The fix is not novel technology; it is the **web's own discovery playbook** (a well-known file on your domain, a crawler, a search index, structured metadata) pointed at agent capabilities. That R.V. Guha — who wrote that playbook for documents with schema.org — is a co-author is the clearest tell of the intent: make agent capabilities as discoverable as web pages became.

For builders the takeaway mirrors the rest of this folder. ARD pushes capability selection *out of the model's context window* and into an external, searchable index — the same instinct as [[harness-engineering]] and [[12-factor-agents]] (own your context, don't stuff it). It is the discovery sibling of the [[agentic-commerce]] trust stack: both retrofit identity, verification, and audit onto a web that assumed a human was driving. And it is what a self-directed loop ([[loop-engineering]]) or a fleet of [[personal-agents]] needs to grow past its pre-installed toolset — an agent that can *find* a new capability at runtime is qualitatively more autonomous than one limited to what its author wired in.

The open question is the same one that gates [[agentic-commerce]]: trust. ARD nails *discovery* and *publisher identity* but deliberately punts on *is this capability actually safe to run* — leaving the most dangerous step, connecting a freshly-discovered tool to a live agent, to layers that do not exist yet. Expect ARD (or something shaped exactly like it) to win as the discovery standard, and expect the next year's fight to be about the trust and safety layer that has to sit on top of it.

## Links

- ARD specification (official site): https://agenticresourcediscovery.org/
- ARD full spec (v0.9): https://agenticresourcediscovery.org/spec/
- ARD introduction: https://agenticresourcediscovery.org/introduction/
- How ARD works: https://agenticresourcediscovery.org/how_ard_works/
- ARD spec on GitHub (ards-project): https://github.com/ards-project/ard-spec
- Announcing the Agentic Resource Discovery specification (Google Developers Blog): https://developers.googleblog.com/announcing-the-agentic-resource-discovery-specification/
- Agentic Resource Discovery: Let agents search (Hugging Face): https://huggingface.co/blog/agentic-resource-discovery-launch
- Introducing the ARD specification (Microsoft Command Line): https://commandline.microsoft.com/agentic-resource-discovery-specification-ard/
- Google's open standard for AI agents to discover and verify tools (Help Net Security): https://www.helpnetsecurity.com/2026/06/18/google-agentic-resource-discovery/
- How ARD helps agents find each other at enterprise scale (Cisco Outshift): https://outshift.cisco.com/blog/ai-ml/agentic-resource-discover-specification-helps-agents-find-each-other
- Snowflake and the Agentic Resource Discovery Specification: https://www.snowflake.com/en/blog/agentic-resource-discovery-specification/
- Building the Open Agentic Web: Why Identity and Discovery Must Work Together (GoDaddy): https://www.godaddy.com/resources/news/building-the-open-agentic-web-why-identity-and-discovery-must-work-together
- GitHub and Google back ARD standard for AI agent discovery (Developer Tech): https://www.developer-tech.com/news/github-google-ard-ai-agent-discovery/
