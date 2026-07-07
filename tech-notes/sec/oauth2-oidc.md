# OAuth 2.0 and OIDC (OpenID Connect)

## What is it?

OAuth 2.0 is a delegated **authorization** framework: it lets a user grant an application limited access to resources hosted by another service, without ever sharing their password with that application. Instead of credentials, the application receives a scoped, expiring **access token**. OpenID Connect (OIDC) is a thin **authentication** layer built on top of OAuth 2.0: it adds an **ID token** (a signed JWT describing who the user is), standard identity claims, and a discovery mechanism, turning OAuth's "can this app access this API?" into "who is this user and how did they log in?". Together they are the backbone of modern login: "Sign in with Google", enterprise SSO, mobile app auth, API-to-API access, and increasingly, auth for AI agents. The distinction matters and is a classic interview trap: OAuth by itself is not a login protocol — using a bare access token as proof of identity is a known vulnerability pattern; OIDC exists precisely to fix that.

## Who created it? When?

OAuth 1.0 emerged in **2007** from a group including **Blaine Cook (Twitter)** and **Chris Messina**, formalized as **RFC 5849 (2010)**. OAuth 2.0 was standardized by the **IETF OAuth Working Group** as **RFC 6749 and RFC 6750 in October 2012**, edited by **Dick Hardt**; original lead author **Eran Hammer** famously resigned and removed his name, calling the result too loose a framework. The ecosystem hardened it over the following decade: **PKCE (RFC 7636, 2015)**, **Device Authorization Grant (RFC 8628, 2019)**, **Token Exchange (RFC 8693, 2020)**, **Security Best Current Practice (RFC 9700, 2025)**, and the consolidating **OAuth 2.1 draft** which deletes the insecure legacy grants. **OpenID Connect 1.0** was published by the **OpenID Foundation in February 2014**, authored by **Nat Sakimura, John Bradley, Mike Jones, Breno de Medeiros, and Chuck Mortimore**, replacing SAML-era OpenID 2.0. **CIBA (Client-Initiated Backchannel Authentication)** was finalized by the OpenID Foundation in **2021**. **Auth0 (founded 2013 by Eugenio Pace and Matias Woloski, acquired by Okta in 2021 for $6.5B)** built its entire business on making these protocols easy for developers.

## How it works?

### The Four Roles

```
┌────────────────┐        ┌────────────────────────┐
│ Resource Owner │        │  Authorization Server  │
│   (the user)   │        │ (Auth0, Okta, Google)  │
│ owns the data  │        │ authenticates the user,│
│                │        │ issues tokens          │
└────────────────┘        └────────────────────────┘
┌────────────────┐        ┌────────────────────────┐
│     Client     │        │    Resource Server     │
│  (web/mobile/  │        │   (the API holding     │
│   SPA/agent)   │        │    the user's data)    │
│ wants access   │        │ validates tokens       │
└────────────────┘        └────────────────────────┘
```

### Authorization Code Flow with PKCE

This is the one flow to know cold. OAuth 2.1 makes PKCE mandatory for all clients, not just mobile.

```
┌──────┐          ┌────────┐            ┌───────────────┐          ┌──────────┐
│ User │          │ Client │            │  Auth Server  │          │   API    │
└──┬───┘          └───┬────┘            └───────┬───────┘          └────┬─────┘
   │  click login     │                         │                       │
   │─────────────────►│ generate code_verifier  │                       │
   │                  │ hash it: code_challenge │                       │
   │                  │                         │                       │
   │   redirect to /authorize?response_type=code│                       │
   │◄─────────────────│  &client_id=...&scope=..&code_challenge=...     │
   │                  │                         │                       │
   │  authenticate + consent screen             │                       │
   │───────────────────────────────────────────►│                       │
   │                  │                         │                       │
   │  redirect back with ?code=AUTH_CODE        │                       │
   │◄────────────────────────────────────────── │                       │
   │─────────────────►│                         │                       │
   │                  │ POST /token             │                       │
   │                  │  code + code_verifier   │                       │
   │                  │────────────────────────►│                       │
   │                  │                         │ verify hash(verifier) │
   │                  │  access_token,          │ == code_challenge     │
   │                  │  refresh_token,         │                       │
   │                  │  id_token (OIDC)        │                       │
   │                  │◄────────────────────────│                       │
   │                  │                         │                       │
   │                  │ GET /resource  Authorization: Bearer <token>    │
   │                  │────────────────────────────────────────────────►│
   │                  │◄────────────────────────────────────────────────│
```

PKCE (Proof Key for Code Exchange) defeats authorization code interception: even if an attacker steals the code from the redirect, they cannot exchange it without the original `code_verifier`, which never left the client.

### The Three Tokens

```
┌───────────────┬────────────────────┬─────────────────────────────────┐
│ Token         │ Audience           │ Purpose                         │
├───────────────┼────────────────────┼─────────────────────────────────┤
│ Access Token  │ Resource Server    │ Call APIs. Short-lived (min-hrs)│
│               │ (the API)          │ Scoped. Client treats as opaque │
├───────────────┼────────────────────┼─────────────────────────────────┤
│ Refresh Token │ Authorization      │ Get new access tokens without   │
│               │ Server only        │ re-login. Long-lived. Must be   │
│               │                    │ rotated and stored securely     │
├───────────────┼────────────────────┼─────────────────────────────────┤
│ ID Token      │ The Client itself  │ OIDC only. Signed JWT proving   │
│ (OIDC)        │ (aud = client_id)  │ WHO logged in, WHEN, HOW.       │
│               │                    │ Never send it to APIs           │
└───────────────┴────────────────────┴─────────────────────────────────┘
```

### Grant Types

```
┌──────────────────────┬──────────────────────────────┬─────────────────┐
│ Grant                │ Use When                     │ Status          │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Authorization Code   │ Any app with a user present  │ THE default     │
│ + PKCE               │ (web, SPA, mobile, desktop)  │ (OAuth 2.1)     │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Client Credentials   │ Machine-to-machine, no user  │ Standard        │
│                      │ (service calling an API)     │                 │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Device Authorization │ Input-constrained devices    │ Standard        │
│ (RFC 8628)           │ (TV: "go to url, enter code")│                 │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Refresh Token        │ Renew access silently        │ Standard        │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Token Exchange       │ Delegation, impersonation,   │ Standard, key   │
│ (RFC 8693)           │ on-behalf-of chains, agents  │ for AI agents   │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ CIBA (backchannel)   │ Auth on a separate device;   │ Standard, key   │
│                      │ async human approval         │ for AI agents   │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Implicit             │ Never. Tokens leaked in URL  │ REMOVED in 2.1  │
├──────────────────────┼──────────────────────────────┼─────────────────┤
│ Password (ROPC)      │ Never. Defeats the point     │ REMOVED in 2.1  │
└──────────────────────┴──────────────────────────────┴─────────────────┘
```

### OIDC on Top: Discovery, ID Token, UserInfo

OIDC standardizes what OAuth left open. A single well-known URL describes the whole provider:

```
GET https://tenant.auth0.com/.well-known/openid-configuration

{
  "issuer": "https://tenant.auth0.com/",
  "authorization_endpoint": ".../authorize",
  "token_endpoint": ".../oauth/token",
  "userinfo_endpoint": ".../userinfo",
  "jwks_uri": ".../.well-known/jwks.json",
  "scopes_supported": ["openid", "profile", "email"],
  "response_types_supported": ["code"],
  "id_token_signing_alg_values_supported": ["RS256"]
}
```

Requesting the `openid` scope turns an OAuth flow into an OIDC flow and yields an ID token:

```
{
  "iss": "https://tenant.auth0.com/",
  "sub": "auth0|507f1f77bcf86cd799439011",
  "aud": "my_client_id",
  "exp": 1767225600,
  "iat": 1767222000,
  "nonce": "n-0S6_WzA2Mj",
  "email": "user@acme.com",
  "amr": ["mfa", "pwd"],
  "auth_time": 1767221990
}
```

The client validates signature (via `jwks_uri`), `iss`, `aud`, `exp`, and `nonce` (replay protection). `amr`/`acr` claims tell you how strongly the user authenticated.

### CIBA: Decoupled Authentication

CIBA reverses the flow: the client asks the authorization server to reach out to the user on another device. There is no browser redirect.

```
┌────────┐  POST /bc-authorize (login_hint, scope)  ┌─────────────┐
│ Client │─────────────────────────────────────────►│ Auth Server │
│(agent, │◄─────────────────────────────────────────│             │
│ kiosk, │        auth_req_id                       └──────┬──────┘
│callctr)│                                                 │ push notification
│        │  poll /token with auth_req_id                   ▼
│        │────────────────────────────────►        ┌──────────────┐
│        │◄────────────────────────────────        │ User's phone │
└────────┘  tokens (once user approves)            │ "Approve?"   │
                                                   └──────────────┘
```

This is the pattern Auth0's Auth for GenAI uses for **async human-in-the-loop approval**: an autonomous agent hits a sensitive action, fires a CIBA request, the human approves on their phone, the agent gets a token and continues.

### Token Exchange (RFC 8693): On-Behalf-Of

A service holding a token for user Alice exchanges it for a new token to call a downstream API, preserving Alice's identity through the chain instead of escalating to a god-mode service account:

```
POST /oauth/token
  grant_type=urn:ietf:params:oauth:grant-type:token-exchange
  subject_token=<alice's access token>
  subject_token_type=urn:ietf:params:oauth:token-type:access_token
  audience=downstream-api
  scope=read:reports
```

## OAuth 2.0 vs OIDC vs SAML

```
┌────────────────┬───────────────────┬───────────────────┬────────────────┐
│                │ OAuth 2.0         │ OIDC              │ SAML 2.0       │
├────────────────┼───────────────────┼───────────────────┼────────────────┤
│ Solves         │ Authorization     │ Authentication    │ Authentication │
│                │ (delegated access)│ (login) + authz   │ (enterprise)   │
├────────────────┼───────────────────┼───────────────────┼────────────────┤
│ Token format   │ Unspecified       │ JWT (ID token)    │ XML assertion  │
├────────────────┼───────────────────┼───────────────────┼────────────────┤
│ Transport      │ JSON over HTTPS   │ JSON over HTTPS   │ XML, browser   │
│                │                   │                   │ POST/redirect  │
├────────────────┼───────────────────┼───────────────────┼────────────────┤
│ Best for       │ API access, M2M   │ Web/mobile login, │ Legacy         │
│                │                   │ modern SSO        │ enterprise SSO │
└────────────────┴───────────────────┴───────────────────┴────────────────┘
```

## Anti-Patterns

- **Using an access token as proof of identity**: access tokens are for APIs; only ID tokens (with validated `aud` and `nonce`) prove who logged in
- **Sending the ID token to an API**: its audience is the client; APIs must reject it
- **Implicit flow in new systems**: tokens in URL fragments leak via history, logs, and referrers
- **Password grant**: teaches users to type credentials into third-party apps — the exact thing OAuth exists to kill
- **Long-lived access tokens instead of refresh tokens**: no revocation story
- **Skipping `state`/`nonce`**: opens CSRF and replay on the callback
- **Wildcard or overly broad redirect URIs**: turns the authorization server into an open redirector and enables code theft
- **Putting secrets in SPAs or mobile apps**: public clients cannot keep secrets; PKCE exists for them

## Pros

- **No password sharing**: third parties get scoped tokens, never credentials
- **Granular scopes**: `read:invoices` instead of full account access
- **Revocable and expiring**: compromised tokens die fast; refresh tokens can be revoked server-side
- **Separation of concerns**: authentication is centralized at the authorization server; APIs just validate tokens
- **Massive ecosystem**: every language, every provider, battle-tested libraries and hosted services (Auth0, Okta, Cognito, Entra)
- **Extensible for new worlds**: token exchange, CIBA, and device grant map cleanly onto AI-agent and IoT scenarios
- **OIDC discovery**: one URL bootstraps full interoperability between independent implementations

## Cons

- **A framework, not a protocol**: RFC 6749 leaves so much optional that two compliant implementations may not interoperate; OIDC and OAuth 2.1 exist to close the gaps
- **Complexity and foot-guns**: redirect URI validation, state, nonce, PKCE, token storage — each one skipped is a CVE
- **Bearer tokens**: whoever holds the token wins; without DPoP/mTLS binding, a stolen token is fully usable
- **Browser redirect dance**: awkward for CLIs, agents, and devices (hence device grant and CIBA)
- **Consent fatigue**: users click "allow" without reading scopes
- **Phishing surface**: fake consent screens and malicious clients (the 2017 Google Docs OAuth worm hit ~1M accounts)
- **Token bloat and chattiness**: multi-audience architectures need many tokens and exchanges

## Use Cases

- **Social and enterprise login**: "Sign in with Google/GitHub/Okta" via OIDC
- **First-party app login**: mobile and SPA authentication against your own identity provider
- **Third-party API delegation**: a scheduling app reading your calendar with `calendar.read` only
- **Machine-to-machine**: microservices authenticating with client credentials
- **Smart devices**: TVs and consoles logging in via device code
- **AI agents**: agents obtaining delegated, scoped, human-approved access via token exchange and CIBA
- **API gateways**: centralized token validation and scope enforcement at the edge
- **B2B SaaS**: each customer federating their own IdP into your product

## Links

- RFC 6749 — OAuth 2.0 Authorization Framework: https://datatracker.ietf.org/doc/html/rfc6749
- RFC 6750 — Bearer Token Usage: https://datatracker.ietf.org/doc/html/rfc6750
- RFC 7636 — PKCE: https://datatracker.ietf.org/doc/html/rfc7636
- RFC 8628 — Device Authorization Grant: https://datatracker.ietf.org/doc/html/rfc8628
- RFC 8693 — Token Exchange: https://datatracker.ietf.org/doc/html/rfc8693
- RFC 9700 — OAuth 2.0 Security Best Current Practice: https://datatracker.ietf.org/doc/html/rfc9700
- OAuth 2.1 draft: https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1
- OpenID Connect Core 1.0: https://openid.net/specs/openid-connect-core-1_0.html
- OpenID CIBA Core: https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html
- Auth0 docs — Authentication and Authorization Flows: https://auth0.com/docs/get-started/authentication-and-authorization-flow
- oauth.net (Aaron Parecki): https://oauth.net/2/
