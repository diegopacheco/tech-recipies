# Single Sign-On (SSO)

## What is it?

Single Sign-On (SSO) lets a person authenticate once and reach multiple independent applications without entering credentials again at each one. The applications do not share passwords. They trust a central **Identity Provider (IdP)** that authenticates the user and sends each application a short-lived, signed assertion. The application, called a **Relying Party (RP)** in OpenID Connect or a **Service Provider (SP)** in SAML, validates that assertion and creates its own local session.

SSO is the user-facing result; **identity federation** is the trust model that makes it work. SSO centralizes authentication, while authorization remains local unless a separate authorization system is used. A successful login proves who the IdP authenticated and how; it does not automatically prove what the user may do inside every application.

SSO is also separate from provisioning. **SCIM** creates, updates, groups, and deactivates accounts. SSO opens the door; SCIM decides whether the account exists and should remain active. Enterprise identity normally needs both.

## Who created it? When?

SSO is an architectural pattern rather than one invention. Early enterprise SSO grew from **Kerberos**, designed at MIT in the 1980s and published as Version 5 in RFC 1510 in **1993**, then RFC 4120 in **2005**. Web federation arrived with **SAML 1.0 in 2002** and **SAML 2.0 in 2005**, standardized by OASIS. Microsoft and IBM introduced **WS-Federation** in the early 2000s. The OpenID community created decentralized web identity, and the OpenID Foundation standardized **OpenID Connect 1.0 in 2014** as an identity layer over OAuth 2.0.

Modern SSO commonly uses SAML for established enterprise integrations, OpenID Connect for web, mobile, and cloud-native systems, and Kerberos inside Windows and Unix domains. Identity platforms hide much of this protocol variety behind one application integration.

## How it works?

### The Trust Model

```
                         trust configuration
                    client ID, endpoints, keys
                 ┌─────────────────────────────┐
                 │                             │
          ┌──────▼──────┐               ┌──────▼──────┐
          │ Identity    │ signed         │ Application │
          │ Provider    │ assertion      │ RP or SP    │
          │             │───────────────►│             │
          └──────┬──────┘               └──────┬──────┘
                 │                             │
                 │ authenticate                │ local session
                 │                             │
                 └──────────────┬──────────────┘
                                │
                           ┌────▼────┐
                           │ Browser │
                           └─────────┘
```

The IdP and application establish trust before login by exchanging identifiers, redirect locations, supported algorithms, and verification keys. During login, the browser moves between them, but the application accepts identity only after cryptographically validating the expected issuer and assertion.

### OIDC Authorization Code Flow

```
User             Application                  IdP
 │                    │                        │
 │ open application   │                        │
 │───────────────────►│                        │
 │                    │ create state, nonce,   │
 │                    │ PKCE verifier          │
 │ redirect to /authorize                      │
 │◄───────────────────│                        │
 │────────────────────────────────────────────►│
 │ authenticate, MFA, consent                  │
 │◄───────────────────────────────────────────►│
 │ redirect with one-time code                 │
 │◄────────────────────────────────────────────│
 │ code + PKCE verifier                        │
 │───────────────────►│                        │
 │                    │ exchange code at       │
 │                    │ token endpoint         │
 │                    │───────────────────────►│
 │                    │ ID token               │
 │                    │◄───────────────────────│
 │                    │ validate issuer,       │
 │                    │ audience, signature,   │
 │                    │ nonce, time claims     │
 │ application cookie │                        │
 │◄───────────────────│                        │
```

When the user opens a second application, it redirects to the same IdP. The IdP already has a valid session cookie, so it can issue a new assertion without asking for credentials again. That reuse of the IdP session is the single sign-on moment.

### Three Different Sessions

```
┌───────────────────┬──────────────────────────────────────────────┐
│ IdP session       │ proves the browser recently authenticated   │
│                   │ to the central identity provider            │
├───────────────────┼──────────────────────────────────────────────┤
│ RP session        │ application cookie created after assertion  │
│                   │ validation; controlled by that application  │
├───────────────────┼──────────────────────────────────────────────┤
│ API token         │ grants scoped access to an API; it is not   │
│                   │ the browser session or the ID token         │
└───────────────────┴──────────────────────────────────────────────┘
```

These lifetimes are independent. Ending the IdP session does not inherently delete every RP cookie, and revoking an API token does not necessarily end the browser session. Secure SSO requires an explicit lifetime, revocation, and logout policy for all three.

### Tenant Discovery

Before redirecting, a multi-tenant application must determine which IdP owns the user. Common methods are:

- **Email-domain discovery**: map `alice@acme.com` to Acme's IdP without treating the typed address as authenticated identity
- **Organization-specific URL**: `acme.application.com` selects a preconfigured connection
- **Invitation or organization context**: the tenant is fixed before login begins
- **IdP discovery service**: present the approved IdPs and let the user select one

The final identity key should be the immutable pair `(issuer, subject)`, not an email address. Emails can change, be recycled, or collide across issuers.

## SSO Patterns and Protocols

```
┌──────────────────┬─────────────────────┬────────────────────────────┐
│ Pattern          │ Best fit            │ Main property              │
├──────────────────┼─────────────────────┼────────────────────────────┤
│ OIDC             │ modern web, mobile, │ JSON/JWT identity layer    │
│                  │ cloud applications  │ over OAuth 2.0             │
├──────────────────┼─────────────────────┼────────────────────────────┤
│ SAML 2.0         │ enterprise SaaS and │ signed XML assertions      │
│                  │ established estates │ through the browser        │
├──────────────────┼─────────────────────┼────────────────────────────┤
│ Kerberos         │ managed workforce   │ ticket-based network SSO   │
│                  │ devices and domains │ with a trusted KDC         │
├──────────────────┼─────────────────────┼────────────────────────────┤
│ Reverse proxy    │ older applications  │ gateway authenticates and  │
│ or identity proxy│ with no federation  │ injects trusted identity   │
├──────────────────┼─────────────────────┼────────────────────────────┤
│ Password vaulting│ last-resort legacy  │ central service submits a  │
│                  │ applications        │ stored application secret  │
└──────────────────┴─────────────────────┴────────────────────────────┘
```

OIDC and SAML are true federation. A reverse proxy can safely bridge older software when it strips all incoming identity headers and injects them only after authentication. Password vaulting improves convenience but still depends on reusable passwords and should be treated as a migration bridge.

## Logout and Revocation

Logout is harder than login because several independent sessions may exist across several domains:

- **Local logout** deletes only the current application's session
- **RP-initiated logout** asks the IdP to end its session, then returns the browser to the application
- **Front-channel logout** loads participating applications in the browser so each can clear its cookie
- **Back-channel logout** sends signed server-to-server logout notifications and does not depend on browser behavior
- **SAML Single Logout** coordinates logout through protocol messages but is unevenly implemented

Global logout is best-effort unless every RP participates correctly. High-risk applications should use short local sessions, reauthentication for sensitive actions, event-driven revocation, and rapid deprovisioning rather than trusting logout alone.

## Attacks and Defenses

- **Login CSRF and authorization response injection**: bind the response to the initiating browser with unpredictable `state`, OIDC `nonce`, PKCE, exact redirect URI matching, and a hardened library
- **Open redirectors**: allow only registered redirect URIs with exact matching; never accept arbitrary post-login destinations
- **Issuer confusion**: key accounts by `(issuer, subject)` and validate the issuer against the tenant selected before login
- **Token substitution**: validate token type, signature, issuer, audience, authorized party, nonce, and time claims; never use an access token as an ID token
- **Session fixation**: rotate the application session identifier after successful federation and privilege elevation
- **Assertion replay**: use short validity windows, nonce or request correlation, one-time code redemption, and replay detection
- **Stolen signing keys**: store IdP keys in protected hardware, publish controlled rotations, monitor unexpected issuance, and rehearse emergency rollover
- **Stale access after offboarding**: combine IdP disablement with SCIM deprovisioning, token revocation, short application sessions, and continuous access signals where supported
- **Weak fallback login**: recovery, local administrator access, and support bypasses must meet the same assurance as the primary SSO path
- **Identity-header spoofing**: a proxy integration must remove client-supplied identity headers and restrict direct network access to the application

## Anti-Patterns

- Treating SSO as authorization and granting application roles solely because authentication succeeded
- Matching accounts by mutable email address instead of the issuer and stable subject identifier
- Sharing one signing key, client secret, or redirect URI across unrelated environments and tenants
- Creating permanent local sessions from a short-lived assertion with no reauthentication policy
- Supporting IdP-initiated login when request correlation is required but adding no compensating protection
- Leaving local password login enabled for every user after enforcing workforce SSO
- Assuming IdP logout instantly revokes all application sessions and access tokens
- Hand-writing SAML, OIDC, XML signature, JWT validation, or session-management code

## Pros

- **Less credential exposure**: applications do not receive workforce passwords or MFA secrets
- **Central policy**: authentication strength, device posture, risk checks, and access hours can be enforced in one place
- **Faster access**: one strong authentication event unlocks many approved applications
- **Rapid containment**: disabling one central identity can stop new sessions across the application estate
- **Consistent audit trail**: the IdP records authentication events and applications record the resulting local sessions
- **Lower support cost**: fewer application-specific passwords and reset flows
- **Enterprise federation**: organizations can use their chosen IdP without sharing credential databases

## Cons

- **Large blast radius**: compromise of the IdP, its signing key, or a privileged administrator can affect every connected application
- **Central availability dependency**: an IdP outage can block new logins across the organization
- **Protocol and tenant complexity**: discovery, metadata, redirect URIs, key rotation, claim mapping, and clock skew create operational work
- **Incomplete logout**: independent application sessions can survive central logout or account disablement
- **Legacy gaps**: older applications may require proxies or password vaulting
- **Privacy concentration**: the IdP can observe where and when users authenticate, and assertions may disclose excessive attributes
- **Recovery risk**: a weak help-desk or break-glass path can bypass the controls gained from centralization

## Use Cases

- Workforce access to SaaS, internal web applications, cloud consoles, and developer platforms
- B2B SaaS allowing each customer organization to connect its own identity provider
- Consumer identity across a family of products under one organization
- Managed-device SSO using Kerberos or platform-bound credentials
- Identity-aware proxies protecting older applications without native OIDC or SAML
- Central phishing-resistant MFA enforcement across hundreds of relying parties
- Merger and acquisition integration where separate identity domains need controlled federation

## Links

- NIST SP 800-63C-4 — Federation and Assertions: https://pages.nist.gov/800-63-4/sp800-63c.html
- OpenID Connect Core 1.0: https://openid.net/specs/openid-connect-core-1_0.html
- OpenID Connect Session Management 1.0: https://openid.net/specs/openid-connect-session-1_0.html
- OpenID Connect RP-Initiated Logout 1.0: https://openid.net/specs/openid-connect-rpinitiated-1_0.html
- OpenID Connect Back-Channel Logout 1.0: https://openid.net/specs/openid-connect-backchannel-1_0.html
- RFC 9700 — OAuth 2.0 Security Best Current Practice: https://datatracker.ietf.org/doc/html/rfc9700
- RFC 4120 — Kerberos V5: https://datatracker.ietf.org/doc/html/rfc4120
- SAML 2.0 Core: https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf
- RFC 7644 — SCIM Protocol: https://datatracker.ietf.org/doc/html/rfc7644
- Companion note — SSO, Federation, and SAML: sso-federation-saml.md
- Companion note — OAuth 2.0 and OpenID Connect: oauth2-oidc.md
