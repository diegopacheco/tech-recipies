# Agent Identity (Auth for MCP, A2A, and GenAI Apps)

## What is it?

Agent identity is the discipline of giving AI agents a real place in the identity system: who is this agent, who does it act for, what is it allowed to do, and how does a human stay in control. Traditional auth assumes a human in front of a browser doing a redirect dance, or a static machine with a client secret. Agents break both assumptions: they are autonomous and long-running (no browser, no human present at call time), they act **on behalf of** a user (delegation, not impersonation), they call many third-party APIs (each with its own tokens), and they talk to other agents. The emerging answer is not a new protocol but a careful mapping of OAuth 2.1, token exchange, and CIBA onto three surfaces: **MCP** (agents calling tools), **A2A** (agents calling agents), and **first-party GenAI apps** (agents calling APIs for a user). Getting this wrong produces the classic **confused deputy**: an over-privileged agent tricked by prompt injection into using its powers against its own user.

## Who created it? When?

**MCP (Model Context Protocol)** was released by **Anthropic in November 2024** as an open standard for connecting AI applications to tools and data. Its **authorization specification** landed in the **2025-03-26 revision** (OAuth 2.1 based) and was significantly reworked in the **2025-06-18 revision**, which made MCP servers plain OAuth **resource servers** (using RFC 9728 Protected Resource Metadata) after industry feedback — **Auth0/Okta engineers were among the main contributors** to that redesign. **A2A (Agent2Agent)** was announced by **Google in April 2025** with 50+ partners and donated to the **Linux Foundation in June 2025**; Auth0 published joint guidance with Google on securing it. **Auth for GenAI** was incubated by the **Auth0Lab team** and launched in **2025**, packaging user authentication, token vault, async human approval, and fine-grained authorization for RAG into SDKs for agent frameworks (LangChain, LlamaIndex, Vercel AI). The underlying standards are older: **Token Exchange (RFC 8693, 2020)**, **CIBA (OpenID Foundation, 2021)**, **Dynamic Client Registration (RFC 7591, 2015)**.

## How it works?

### Why Agents Break Classic Auth

```
Classic web app                     AI agent
┌─────────────────────┐            ┌─────────────────────────────┐
│ human present       │            │ runs at 3am, human asleep   │
│ browser redirects   │            │ no browser, no redirect     │
│ one API, one token  │            │ N APIs, N tokens per user   │
│ short session       │            │ days-long workflows         │
│ deterministic code  │            │ LLM can be prompt-injected  │
│ acts as itself      │            │ acts on behalf of a user    │
└─────────────────────┘            └─────────────────────────────┘
```

Rule zero: **the agent must never have more power than the user it acts for**, and ideally far less — scoped to the task at hand.

### The Four Patterns of Auth for GenAI

```
┌──────────────────────┬───────────────────────────────────────────────┐
│ Pattern              │ Mechanism                                     │
├──────────────────────┼───────────────────────────────────────────────┤
│ 1. User → App login  │ Standard OIDC. The human authenticates to     │
│                      │ the GenAI app; agent sessions bind to sub     │
├──────────────────────┼───────────────────────────────────────────────┤
│ 2. Agent → 3rd-party │ Token Vault: user links Google/GitHub/Slack   │
│    API on behalf of  │ once; vault stores + refreshes those tokens;  │
│    user              │ agent requests them just-in-time, scoped      │
├──────────────────────┼───────────────────────────────────────────────┤
│ 3. Async human       │ CIBA: agent hits a sensitive action, auth     │
│    approval          │ server pushes "Approve?" to the user's phone, │
│    (human-in-loop)   │ agent blocks/polls until approved             │
├──────────────────────┼───────────────────────────────────────────────┤
│ 4. FGA for RAG       │ Filter retrieved documents by what THIS user  │
│                      │ may see, so the LLM cannot leak documents the │
│                      │ user could never open themselves              │
└──────────────────────┴───────────────────────────────────────────────┘
```

### MCP Authorization (2025-06-18 spec)

The key architectural decision: the MCP server is **just an OAuth 2.1 resource server**. It does not issue tokens; it points clients at an external authorization server (Auth0, Okta, Keycloak) and validates the access tokens it receives.

```
┌────────────┐                                   ┌─────────────────┐
│ MCP Client │ 1. request without token          │   MCP Server    │
│ (Claude,   │──────────────────────────────────►│ (resource srv)  │
│  IDE, app) │◄──────────────────────────────────│                 │
│            │ 2. 401 + WWW-Authenticate:        └────────┬────────┘
│            │    resource_metadata URL                   │
│            │                                            │
│            │ 3. GET /.well-known/oauth-protected-resource
│            │───────────────────────────────────────────►│
│            │◄─── authorization_servers: [https://as]────│
│            │                                   ┌─────────────────┐
│            │ 4. discovery + dynamic client reg │  Authorization  │
│            │──────────────────────────────────►│  Server (Auth0) │
│            │ 5. OAuth 2.1 auth code + PKCE     │                 │
│            │    (resource indicator RFC 8707)  │                 │
│            │◄────────── access token ──────────│                 │
│            │                                   └─────────────────┘
│            │ 6. request + Bearer token (aud = this MCP server)
│            │──────────────────────────────────►┌─────────────────┐
│            │◄───────────── result ─────────────│   MCP Server    │
└────────────┘                                   └─────────────────┘
```

Critical details: **PKCE is mandatory**, **Dynamic Client Registration (RFC 7591)** lets unknown clients onboard automatically, **Resource Indicators (RFC 8707)** bind the token's audience to one specific MCP server, and the spec forbids **token passthrough** — an MCP server must never forward the token it received to an upstream API (audience mismatch = confused deputy). For upstream calls it must obtain its own token, typically via token exchange.

### A2A: Agent-to-Agent Auth

A2A agents publish an **Agent Card** (JSON at `/.well-known/agent.json`) declaring capabilities and accepted security schemes, mirroring OpenAPI security:

```
{
  "name": "expense-approver",
  "url": "https://agents.acme.com/expense",
  "capabilities": { "streaming": true },
  "securitySchemes": {
    "oauth": {
      "type": "oauth2",
      "flows": { "clientCredentials": {
        "tokenUrl": "https://as.acme.com/oauth/token",
        "scopes": { "expense:approve": "approve expenses" } } }
  } },
  "security": [ { "oauth": ["expense:approve"] } ]
}
```

The client agent authenticates out-of-band (client credentials for its own identity, or token exchange to carry the end user's identity through the agent chain) and calls the remote agent over HTTPS with the resulting token. The hard open problem A2A + identity work is chasing: preserving **who the original human principal is** across a chain of agents, instead of each hop laundering identity into a service account.

### Token Vault: Calling Third-Party APIs

```
        user links accounts once (OAuth to each provider)
                            │
                            ▼
┌─────────┐  exchange own  ┌─────────────────────┐   stores/refreshes
│  Agent  │  token, scoped │     Token Vault     │   per-user tokens
│         │───────────────►│  (Auth0 federated   │  ┌───────────────┐
│         │◄───────────────│   connections)      │  │ Google  token │
│         │  google token  └─────────────────────┘  │ GitHub  token │
│         │                                         │ Slack   token │
│         │  GET /calendar  Bearer <google token>   └───────────────┘
│         │──────────────────────────────────────► Google API
└─────────┘
```

The agent never stores provider refresh tokens, never sees credentials, and each retrieval is auditable and scoped to the requesting user.

### Async Human Approval (CIBA)

```
Agent: "Buy 100 shares of ACME for Alice"
  │
  ├─► POST /bc-authorize (login_hint=alice, scope=trade:execute,
  │        binding_message="Buy 100 ACME @ $42")
  │
  │        Auth server pushes to Alice's phone: "Approve trade?"
  │
  ├─► agent polls /token with auth_req_id ... pending ... pending
  │
  │        Alice taps Approve (with biometrics)
  │
  └─► token issued, agent executes exactly the approved action
```

The `binding_message` shows the human precisely what they authorize — the identity-layer antidote to prompt injection escalating into real-world actions.

## Comparison of the Three Surfaces

```
┌────────────────┬─────────────────────┬─────────────────────┬────────────────────┐
│                │ MCP                 │ A2A                 │ Auth for GenAI     │
├────────────────┼─────────────────────┼─────────────────────┼────────────────────┤
│ Connects       │ agent ↔ tools/data  │ agent ↔ agent       │ agent ↔ user + APIs│
├────────────────┼─────────────────────┼─────────────────────┼────────────────────┤
│ Auth model     │ OAuth 2.1 resource  │ Agent Card declares │ OIDC login, token  │
│                │ server + PKCE + DCR │ OpenAPI-style       │ vault, CIBA, FGA   │
│                │ + resource indicator│ security schemes    │                    │
├────────────────┼─────────────────────┼─────────────────────┼────────────────────┤
│ Steward        │ Anthropic (open)    │ Linux Foundation    │ Auth0/Okta product │
├────────────────┼─────────────────────┼─────────────────────┼────────────────────┤
│ Hard problem   │ no token            │ user identity across│ least privilege for│
│                │ passthrough         │ agent chains        │ autonomous actions │
└────────────────┴─────────────────────┴─────────────────────┴────────────────────┘
```

## Anti-Patterns

- **God-mode service account**: one static API key with admin rights shared by all agent runs for all users
- **Token passthrough**: an MCP server forwarding the client's token upstream, destroying audience restriction and audit
- **Impersonation instead of delegation**: agent logs in AS the user rather than carrying "agent X acting for user Y" (the `act` claim in RFC 8693 exists for this)
- **Secrets in prompts or agent memory**: credentials pasted into context are one injection away from exfiltration
- **No human checkpoint on irreversible actions**: payments, deletions, and sends need CIBA-style approval, not just an LLM guardrail
- **Unfiltered RAG**: retrieving with a privileged indexer identity and letting any user query the result leaks documents across permission boundaries

## Pros

- **Builds on proven standards**: OAuth 2.1, RFC 8693, CIBA — no new crypto, mature server support from day one
- **Least privilege for autonomy**: scoped, expiring, audience-bound tokens per task instead of standing credentials
- **Human sovereignty**: async approval keeps irreversible actions behind a real human decision with a clear description
- **Auditability**: every token issuance names the agent, the user, the scope, and the approval — answerable "who did this and why"
- **Defense against prompt injection consequences**: injection may fool the model, but the identity layer caps the blast radius
- **Per-user third-party access**: token vault gives each user's agent exactly that user's reach into Google/Slack/GitHub, nothing more
- **Interoperability**: any compliant MCP client works with any compliant server behind any standard authorization server

## Cons

- **Rapidly moving specs**: MCP auth changed shape twice in 2025; A2A is younger still — build against revisions, expect churn
- **Identity across agent chains is unsolved**: multi-hop delegation (user → agent → agent → API) has patterns but no settled standard
- **Latency and friction**: human approval and token exchange hops slow down agent loops; teams get tempted to widen scopes
- **Dynamic client registration risk**: auto-onboarding unknown clients enlarges attack surface if the AS applies no policy
- **Consent comprehension**: users approving `binding_message` prompts can be fatigued or socially engineered like any consent screen
- **Ecosystem immaturity**: many MCP servers in the wild still ship with no auth or homemade API keys
- **Doesn't fix model behavior**: identity bounds what an injected agent CAN do, not what it TRIES to do — still needs sandboxing and monitoring

## Use Cases

- **Enterprise agent assistants**: an agent reading a user's email and calendar with vault-issued, user-scoped tokens
- **Autonomous background workflows**: overnight jobs acting for users, escalating to CIBA approval on sensitive steps
- **Authenticated MCP tool servers**: exposing internal APIs to Claude and IDE agents behind OAuth 2.1 instead of shared keys
- **Cross-company agent commerce**: purchasing or negotiation agents authenticating to counterpart agents via A2A
- **Permission-aware RAG**: chatbots over corporate documents that answer only from what the asking user may read
- **Consumer agent products**: personal assistants linking a user's SaaS accounts once, then acting under revocable delegation
- **Regulated industries**: trading, healthcare, and payments agents that need signed, per-action human authorization trails

## Links

- MCP Authorization spec: https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization
- MCP security best practices: https://modelcontextprotocol.io/specification/2025-06-18/basic/security_best_practices
- A2A protocol: https://a2a-protocol.org/
- A2A GitHub: https://github.com/a2aproject/A2A
- Auth0 — Auth for GenAI: https://auth0.com/ai
- Auth0 docs — Token Vault: https://auth0.com/docs/secure/tokens/token-vault
- Auth0 blog — Auth0 and Google A2A: https://auth0.com/blog/auth0-google-a2a/
- Auth0 blog — An Introduction to MCP and Authorization: https://auth0.com/blog/an-introduction-to-mcp-and-authorization/
- RFC 8693 — Token Exchange: https://datatracker.ietf.org/doc/html/rfc8693
- RFC 9728 — OAuth Protected Resource Metadata: https://datatracker.ietf.org/doc/html/rfc9728
- RFC 7591 — Dynamic Client Registration: https://datatracker.ietf.org/doc/html/rfc7591
- OpenID CIBA Core: https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html
