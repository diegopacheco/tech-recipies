# Agent Identity Trends and the Identity Market Landscape

## What is it?

This note is a map, not a protocol: who the players are in identity, where the money and M&A are moving, and where agent identity — the newest and fastest-moving front — is heading. Identity has split into distinct markets that get conflated: **workforce IAM** (employees logging into SaaS through enterprise identity providers such as Microsoft Entra), **CIAM** (customers logging into your product through developer-first identity platforms such as Auth0), **authorization** (what a logged-in identity may do — the FGA/policy-engine space), **non-human identity (NHI)** (service accounts, API keys, workloads — the category analysts started naming in 2024), and now **agent identity** (AI agents acting on behalf of humans across all of the above). The strategic thesis driving the whole space: every company deploying agents multiplies its identity count by orders of magnitude — agents outnumber employees the way containers outnumber servers — and whoever owns the identity control plane for agents owns the choke point of the agent economy.

## Why does it matter?

Knowing the protocols is table stakes; the differentiator is reading the board. Workforce identity platforms have moved into developer CIAM, identity security posture, privileged access, and agent authorization. Meanwhile Palo Alto Networks agreed to buy CyberArk (**announced July 2025, ~$25B**) largely for machine and agent identity — the loudest possible market signal that identity is consolidating into the security platforms.

## The Landscape

### Platforms and Incumbents

```
┌────────────────┬──────────────────────────────────────────────────────┐
│ Workforce +    │ Enterprise IdP + developer CIAM + FGA + Auth for     │
│ CIAM platforms │ GenAI. Betting identity is the agent control plane   │
├────────────────┼──────────────────────────────────────────────────────┤
│ Microsoft      │ Entra ID: bundled with M365, the gravity well of     │
│ Entra          │ workforce identity; Entra Agent ID (2025) extends    │
│                │ directory identities to AI agents                    │
├────────────────┼──────────────────────────────────────────────────────┤
│ Ping Identity  │ Ping + ForgeRock merged under Thoma Bravo (2023);    │
│                │ large-enterprise, hybrid, federal                    │
├────────────────┼──────────────────────────────────────────────────────┤
│ CyberArk       │ PAM leader → machine identity (bought Venafi 2024,   │
│                │ $1.54B) → being absorbed by Palo Alto Networks       │
├────────────────┼──────────────────────────────────────────────────────┤
│ SailPoint      │ Identity governance (IGA); re-IPO'd Feb 2025;        │
│                │ pushing governance of agent identities               │
├────────────────┼──────────────────────────────────────────────────────┤
│ AWS / Google   │ Cognito / Firebase Auth + Cloud IAM: good-enough     │
│                │ bundled identity that caps startup pricing power     │
└────────────────┴──────────────────────────────────────────────────────┘
```

### Developer-First CIAM Startups (the Auth0 challengers)

```
┌─────────────┬──────┬──────────────────────────────────────────────────┐
│ Company     │ Est. │ Angle                                            │
├─────────────┼──────┼──────────────────────────────────────────────────┤
│ Clerk       │ 2019 │ React-native components: <SignIn/> as a product; │
│             │      │ owns the frontend layer Auth0 never did; B2B     │
│             │      │ orgs, billing, and MCP/agent toolkit additions   │
├─────────────┼──────┼──────────────────────────────────────────────────┤
│ Stytch      │ 2020 │ API-first passwordless → B2B auth platform;      │
│             │      │ Connected Apps: turn your SaaS into an OAuth/MCP │
│             │      │ identity provider for agents                     │
├─────────────┼──────┼──────────────────────────────────────────────────┤
│ WorkOS      │ 2019 │ "Enterprise-ready in days": SSO/SCIM/audit APIs  │
│             │      │ + AuthKit; bought Warrant (FGA, 2024); heavy     │
│             │      │ push into MCP auth and agent tooling             │
├─────────────┼──────┼──────────────────────────────────────────────────┤
│ Descope     │ 2022 │ No/low-code auth flows, passkey-first; founders  │
│             │      │ sold their SOAR startup to Palo Alto; launched   │
│             │      │ an Agentic Identity Hub (2025) for MCP/agents    │
├─────────────┼──────┼──────────────────────────────────────────────────┤
│ Kinde,      │      │ The long tail: SMB-friendly pricing, framework   │
│ Frontegg,   │      │ SDKs, self-host options (SuperTokens, FusionAuth)│
│ SuperTokens │      │                                                  │
├─────────────┼──────┼──────────────────────────────────────────────────┤
│ Keycloak,   │      │ Open source: Keycloak (CNCF, Red Hat lineage),   │
│ Ory, Zitadel│      │ Ory (API-first), Zitadel — the build-vs-buy floor│
└─────────────┴──────┴──────────────────────────────────────────────────┘
```

The pattern: each attacks Auth0's weak flank at its founding moment — Clerk on frontend DX, Stytch on passwordless APIs, WorkOS on enterprise-readiness, Descope on visual flows — and every one of them pivoted hard to agent/MCP auth in 2025 because that is where new budgets are.

### Authorization and Policy

```
┌──────────────┬────────────────────────────────────────────────────────┐
│ OpenFGA /    │ Auth0Lab's Zanzibar, CNCF; hosted as Auth0 FGA         │
│ Auth0 FGA    │                                                        │
│ Authzed      │ SpiceDB, closest to the Zanzibar paper, strong OSS pull│
│ Oso          │ Polar policy language, authz-as-a-service              │
│ Permit.io /  │ Policy management UIs over OPA/Cedar-style engines     │
│ Cerbos       │                                                        │
│ AWS Cedar    │ Formally verified policy language, Verified Permissions│
└──────────────┴────────────────────────────────────────────────────────┘
```

### Non-Human and Agent Identity Startups

```
┌──────────────────┬────────────────────────────────────────────────────┐
│ Aembit           │ Workload IAM: policy-based, secretless auth between│
│                  │ workloads and agents — enterprise IdP for machines │
│ Astrix, Oasis,   │ NHI security posture: discover, govern, and rotate │
│ Entro, Token     │ the service accounts and API keys nobody owns      │
│ Security, Clutch │ (several acquired or acquiring through 2025)       │
│ Natoma           │ NHI management → hosted MCP/agent access platform  │
│ Arcade.dev       │ Tool-calling auth for agents: brokered OAuth to    │
│                  │ Gmail/Slack/GitHub so agents never hold raw tokens │
│ Composio, Nango, │ Integration/token-management layers agents use to  │
│ Paragon          │ reach hundreds of SaaS APIs                        │
│ SGNL             │ Continuous, context-based access (CAEP co-authors) │
│ humanprincipal.ai│ Auth0Lab exploration: binding agent actions to the │
│                  │ human principal behind them                        │
└──────────────────┴────────────────────────────────────────────────────┘
```

## Where Agent Identity Is Heading

- **From API keys to delegated identity**: the current mess (agents holding long-lived keys) is recapitulating 2005-era auth; the correction is OAuth-shaped — token exchange, audience binding, short TTLs. The MCP authorization spec is the beachhead
- **The human principal problem**: the frontier question is preserving "which human is behind this agent, with what consent" across multi-hop agent chains — IETF **OAuth identity chaining / Identity Assertion Authorization Grant** drafts and Auth0Lab's humanprincipal.ai both aim here
- **Workload identity converges with agent identity**: **SPIFFE/SPIRE**-style attested workload IDs and the IETF **WIMSE** working group provide the "who is this process" layer under "who is this agent for"
- **Continuous access over session-based access**: agents run for days; **Shared Signals Framework / CAEP** (revoke and signal in real time) fits agents better than login-time checks
- **Agentic commerce forces the issue**: Visa Intelligent Commerce, Mastercard Agent Pay, and Google's **AP2 (Agent Payments Protocol, 2025)** need cryptographic proof a human authorized a purchase — payments will drag agent identity into regulation
- **Agent registries and reputation**: expect "app store" style trust: signed agent manifests, verifiable credentials for agents, and per-agent risk scoring — the space startups and platforms are racing to own
- **Consolidation**: NHI startups are being absorbed into platforms (CyberArk→Palo Alto being the tone-setter); prediction: the standalone winners will be the ones owning protocol leverage (MCP/A2A ecosystems), not a dashboard

## Notable M&A and Signals

```
┌──────┬────────────────────────────────────────────────────────────────┐
│ 2021 │ Auth0 acquired ($6.5B) — workforce identity moves into CIAM    │
│ 2022 │ Thoma Bravo takes Ping ($2.8B), ForgeRock ($2.3B), SailPoint   │
│      │ ($6.9B) private — PE consolidation wave                        │
│ 2023 │ Identity security posture acquisitions heat up                 │
│ 2024 │ CyberArk buys Venafi ($1.54B) — machine identity land grab;    │
│      │ WorkOS buys Warrant — CIAM absorbs FGA                         │
│ 2025 │ Palo Alto to buy CyberArk (~$25B) — security platforms decide  │
│      │ identity IS the platform; SailPoint re-IPOs; NHI startups      │
│      │ consolidate; every CIAM vendor ships an MCP/agent auth story   │
└──────┴────────────────────────────────────────────────────────────────┘
```

## How to Stay Current

- **Specs in motion**: MCP authorization changelog, A2A releases, IETF OAuth WG drafts (identity chaining, transaction tokens), WIMSE, OpenID Foundation's AI/agent identity work and Shared Signals (CAEP)
- **Vendor labs**: Auth0 blog + auth0-lab GitHub, WorkOS/Stytch/Clerk/Descope changelogs (watch what they ship for agents, not what they post), Microsoft Entra Agent ID announcements
- **Conferences**: Identiverse, Internet Identity Workshop (IIW — where passkeys and OAuth extensions actually get hashed out), Authenticate (FIDO), Gartner IAM Summit for the buyer view
- **Money flow**: identity venture portfolios, a16z/YC identity investments, and NHI acquisition announcements — funding maps the perceived gaps

## Links

- Auth0 — Auth for GenAI: https://auth0.com/ai
- auth0-lab on GitHub: https://github.com/auth0-lab
- MCP authorization spec: https://modelcontextprotocol.io/specification/2025-06-18/basic/authorization
- A2A project: https://a2a-protocol.org/
- IETF OAuth WG documents: https://datatracker.ietf.org/wg/oauth/documents/
- IETF WIMSE WG: https://datatracker.ietf.org/wg/wimse/about/
- OpenID Shared Signals / CAEP: https://openid.net/wg/sharedsignals/
- Google AP2 — Agent Payments Protocol: https://github.com/google-agentic-commerce/AP2
- SPIFFE: https://spiffe.io/
- Internet Identity Workshop: https://internetidentityworkshop.com/
- Identiverse: https://identiverse.com/
