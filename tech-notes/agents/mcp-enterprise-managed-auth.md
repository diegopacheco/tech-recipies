# MCP Enterprise-Managed Authorization (EMA)

## What is it?

Enterprise-Managed Authorization (EMA) is an extension to the Model Context Protocol that lets an organization decide centrally which MCP servers its people can reach - through the identity provider (IdP) it already runs - instead of every employee separately clicking through an OAuth consent screen for every server. It went **stable on June 18, 2026**, after first landing in the [2025-11-25 MCP spec](https://modelcontextprotocol.io/specification/2025-11-25). The MCP team's framing is "zero-touch OAuth for MCP": the servers an employee is entitled to are simply connected on first login, with no per-app authorization and nothing to wire up one-off.

The extension id is `io.modelcontextprotocol/enterprise-managed-authorization`. It was standardized as **SEP-990**, lives in the [`ext-auth`](https://github.com/modelcontextprotocol/ext-auth) repository, and is the MCP packaging of **Cross App Access (XAA)** - which is itself built on the IETF **Identity Assertion Authorization Grant (ID-JAG)** draft. Anthropic, Microsoft, and Okta are driving it. The primary announcement is the MCP blog's [Enterprise-Managed Authorization: Zero-touch OAuth for MCP](https://blog.modelcontextprotocol.io/posts/enterprise-managed-auth/).

## The problem it solves

Standard MCP authorization was designed to be **user-scoped and interactive** - each person decides, per server, what touches their data. That's the right default for a consumer connecting their own accounts. It falls apart inside a company:

- **Per-user authorization tax.** Onboarding means each employee manually connecting service after service; the friction means most useful servers just stay switched off.
- **No central policy or audit.** Access is whatever each user happened to authorize, with no consistent rule and no single trail for security to inspect.
- **Work and personal blur.** Nothing forces a corporate identity, so someone can connect a personal account to a work tool by accident or by compromise.

Okta's Aaron Parecki sharpens the security angle: when a client like Claude or ChatGPT does a direct OAuth flow to, say, the Asana MCP server, the enterprise IdP only sees a login to Asana - it never sees the *connection* the agent established. Those are effectively **unmanaged "shadow IT" connections** that bypass enterprise policy. EMA exists to put the IdP back in the driver's seat.

## How it works

EMA establishes a **delegated authorization flow** where the enterprise IdP sits as the intermediary between the MCP client and the MCP server. The key move is that the user is **never redirected through a per-server consent screen** - the IdP vouches for them instead.

1. **Single sign-on.** The user logs into the MCP client (Claude, Claude Code, VS Code) with their corporate identity over **OpenID Connect or SAML**. The client keeps the resulting **Identity Assertion** (an OIDC ID Token or SAML assertion).
2. **Server signals EMA.** When a server declares enterprise-managed auth in its authorization metadata, the client knows not to start a normal interactive OAuth flow.
3. **Mint an ID-JAG.** The client presents the saved Identity Assertion plus the target server's identifier to the IdP's authorization endpoint and asks for an **Identity Assertion JWT Authorization Grant (ID-JAG)**.
4. **IdP enforces policy.** The IdP evaluates group membership, role, and conditional-access rules. If the user isn't entitled, it returns an error and the client **never receives a token** for that server.
5. **Exchange for an access token.** The client exchanges the ID-JAG at the MCP server's Authorization Server, which validates the JWT (signature against the IdP's JWKS, plus audience/issuer/expiry), maps its claims (scope, resource, subject, email) to permissions, and links the account.

A client advertises support in its `initialize` handshake:

```json
{
  "capabilities": {
    "extensions": {
      "io.modelcontextprotocol/enterprise-managed-authorization": {}
    }
  }
}
```

The four properties that fall out of the flow:

| Property | What it means |
|---|---|
| **Centralized policy** | The IdP holds the registry of approved servers and their access rules; admins configure them in tooling they already run. |
| **Single sign-on** | Corporate credentials once; no per-server prompts after that. |
| **Policy enforcement** | The IdP decides *before* issuing a token, so unauthorized users get an error rather than a usable grant. |
| **Centralized revocation** | Revoke at the IdP and it takes effect immediately across every client - no per-client, per-server cleanup. |

This is the same lineage as the [[claude-finance-agents]] "governed connector" story: EMA is the identity layer that makes those governed MCP connections enterprise-safe in the first place.

## Pros

- **Authorize once, inherit everywhere.** An admin enables a server for the org; users get it automatically, scoped to the groups and roles they already hold. Zero-touch for the employee.
- **One policy, one audit trail.** Access decisions live in the IdP admin console, governed by the same workflow as the rest of the stack - not a separate surface to monitor.
- **Fast offboarding.** Because checking with the IdP is frictionless, admins can shorten token lifetimes; when someone is deprovisioned, connector access expires fast instead of lingering on a stale token.
- **No personal/enterprise mixups.** Admins can require a connector to only ever connect through the IdP, keeping work and personal accounts cleanly separated.
- **Open standard, not a vendor lock.** Any connector - including custom ones a company builds - can implement it, and it works the same way for every host. It also kills the **Dynamic Client Registration** headache (unbounded client-registration growth, abuse-prone public endpoints) that had been a real barrier to enterprise MCP.

## Cons

- **Okta-gated today.** Okta is the only IdP supported at launch (via Cross App Access). Azure AD and others are "coming soon," but right now the practical prerequisite is a specific IdP.
- **Three-party coordination.** It only works where the **IdP, the client, and the server** all implement the extension. That's a network effect - a server outside the supported set still falls back to per-user OAuth.
- **It governs access, not behavior.** EMA decides *who* may connect and *that* the connection is managed; it does nothing to constrain what the agent does once connected. You still need least-privilege scopes and action-level guardrails - it pairs with, rather than replaces, an approval gate like [[claude-auto-mode]].
- **Young standards underneath.** ID-JAG and the related Client ID Metadata Documents are recent IETF drafts; betting core enterprise auth on still-moving specs carries some standards risk.
- **The IdP becomes the chokepoint.** Concentrating every connector decision in one identity plane is the whole point, but it also makes that plane a high-value single point of failure and attack target.
- **Server-side lift.** Authorization servers must validate ID-JAGs, map claims to permissions, and handle account linking - and clients must handle the fact that IdP-issued token scopes can differ from standard MCP scopes.

## Who is doing it

| Role | Who |
|---|---|
| **Identity providers** | **Okta** at launch (via Cross App Access / XAA); more coming. |
| **Clients** | **Anthropic** - Claude, Claude Code, and Cowork share one MCP layer; **Microsoft** - Visual Studio Code added EMA in the IDE. |
| **Servers** | **Asana, Atlassian (Rovo - Jira/Confluence), Canva, Figma, Granola, Linear, Supabase**; **Slack** and more in progress. |
| **Customers rolling it out** | **HubSpot, Ramp, Webflow** among the early Claude Enterprise deployments. |
| **Authors / contributors** | The SEP-990 authors and `ext-auth` maintainers, incl. **Aaron Parecki** (Okta, Director of Identity Standards), **Den Delimarsky** (Microsoft), **David Soria Parra, Nick Cooper, Tyler Leonhardt, Paul Carleton**. |

The standard arrived as one of two big authorization changes in the MCP one-year-anniversary spec: EMA/XAA and **CIMD** (Client ID Metadata Documents, which replaces Dynamic Client Registration). Both were aimed squarely at the criticism - voiced bluntly in Solo.io's "[MCP Authorization is a Non-Starter for Enterprise](https://www.solo.io/blog/mcp-authorization-is-a-non-starter-for-enterprise)" - that the earlier MCP auth model couldn't be governed at enterprise scale. EMA is a direct answer to that.

## Why it matters

For agents, this is the difference between a pilot and a deployment. The moment a company wants dozens of MCP servers reachable by Claude, VS Code, or any other host, the per-user OAuth model becomes both an adoption blocker (nobody clicks through forty consent screens) and a security liability (unmanaged shadow connections with no audit trail). EMA folds MCP access into the identity plane companies already trust, so provisioning, scoping, and revocation work the same as for every other corporate app.

It sits one layer over from the other "make agents safe in production" approaches in these notes. An LLM gateway like [[merge-ai-agent-gateway]] is the chokepoint for *model* access; the [[litellm-agent-platform]] credential vault keeps *real secrets* out of the agent by swapping them at the network edge; EMA is the chokepoint for *tool and connector* access at the **identity** layer, issuing short-lived IdP-governed tokens instead of letting each user hand over a long-lived grant. They're complementary layers of defense in depth.

The honest caveat is that EMA is necessary but not sufficient. It answers "should this person's agent be allowed to connect to this server at all," cleanly and centrally - and that was the missing primitive. It says nothing about what the agent then does with that access, so least-privilege scoping and action-level controls still matter. And the value is real only once you're past the launch constraints: an Okta shop connecting Claude to Atlassian and Linear gets the full payoff today; a team on a different IdP or a server that hasn't adopted the extension is still waiting for the network to fill in.

## Links

* https://blog.modelcontextprotocol.io/posts/enterprise-managed-auth/
* https://modelcontextprotocol.io/extensions/auth/enterprise-managed-authorization
* https://github.com/modelcontextprotocol/ext-auth/blob/main/specification/draft/enterprise-managed-authorization.mdx
* https://claude.com/blog/enterprise-managed-auth
* https://aaronparecki.com/2025/11/25/1/mcp-authorization-spec-update
* https://aaronparecki.com/2025/05/12/27/enterprise-ready-mcp
* https://oauth.net/cross-app-access/
* https://datatracker.ietf.org/doc/draft-parecki-oauth-identity-assertion-authz-grant/
* https://blog.modelcontextprotocol.io/posts/2025-11-25-first-mcp-anniversary/
* https://www.solo.io/blog/mcp-authorization-is-a-non-starter-for-enterprise
