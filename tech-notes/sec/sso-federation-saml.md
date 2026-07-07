# SSO, Federation, and SAML

## What is it?

Single Sign-On (SSO) lets a user authenticate once and access many applications without logging in again. Identity **federation** is the trust machinery underneath: an application (the **Service Provider**, SP) outsources authentication to an external **Identity Provider** (IdP) it trusts, and accepts signed assertions about who the user is. **SAML 2.0** (Security Assertion Markup Language) is the XML-based federation protocol that still dominates enterprise SSO: when you log into Salesforce or Workday through your company's IdP, a SAML assertion is what crosses the wire. The federation stack also includes **SCIM** for provisioning (creating/updating/deactivating accounts across apps automatically) and the workforce-vs-customer split: **workforce identity** (employees, IT-managed) versus **CIAM** (customers signing up to your product). For a B2B SaaS company, "supports SAML SSO + SCIM" is not a feature — it is the toll gate to selling upmarket.

## Who created it? When?

SAML was created by the **OASIS Security Services Technical Committee**: **SAML 1.0 in November 2002**, and the still-current **SAML 2.0 in March 2005**, merging SAML 1.1 with the Liberty Alliance's ID-FF and Shibboleth work — contributors spanned **Sun, IBM, RSA, and Ping Identity**. Microsoft and IBM pushed the rival **WS-Federation (2003)**, which survives mostly in legacy ADFS estates. **SCIM (System for Cross-domain Identity Management)** was standardized as **RFC 7643/7644 in September 2015** (work started at IETF in 2011). Commercial IdPs and developer identity platforms later productized SAML and SCIM for enterprise and customer identity. The modern trajectory: new integrations prefer **OIDC**, but SAML remains entrenched because thousands of enterprise apps and IdPs already speak it.

## How it works?

### The Trust Triangle

```
                 one-time setup: exchange METADATA
                 (entity IDs, endpoints, X.509 signing certs)
   ┌────────────────────────────────────────────────────┐
   │                                                    │
┌──▼──────────────┐                        ┌────────────▼─────────┐
│  Identity        │                        │  Service Provider    │
│  Provider (IdP)  │                        │  (SP: Salesforce,    │
│  Entra / Auth0 / │                        │  Workday, your SaaS) │
│  ADFS / Keycloak │                        │                      │
└──────────┬───────┘                        └───────────┬──────────┘
           │           ┌──────────┐                     │
           └──────────►│  User's  │◄────────────────────┘
             login UI  │ Browser  │  the browser is the
                       └──────────┘  transport between them
```

SAML never has the SP and IdP talk directly during login — signed XML rides through the user's browser via redirects and form POSTs.

### SP-Initiated Flow (the common one)

```
┌──────┐            ┌─────────────┐               ┌─────────────┐
│ User │            │     SP      │               │     IdP     │
└──┬───┘            └──────┬──────┘               └──────┬──────┘
   │ 1. open app.acme.com  │                             │
   │──────────────────────►│                             │
   │ 2. redirect with AuthnRequest (signed, deflated,    │
   │    in query string) to IdP SSO URL                  │
   │◄──────────────────────│                             │
   │ 3. follow redirect ────────────────────────────────►│
   │ 4. authenticate (password + MFA), or already        │
   │    has an IdP session → seamless                    │
   │◄────────────────────────────────────────────────────│
   │ 5. auto-submitting HTML form: SAMLResponse          │
   │    (signed assertion, base64) POSTed to the SP's    │
   │    ACS (Assertion Consumer Service) URL             │
   │───────────────────────►                             │
   │                       │ 6. validate signature, iss, │
   │                       │    audience, timestamps,    │
   │                       │    InResponseTo             │
   │ 7. app session cookie │                             │
   │◄──────────────────────│                             │
```

IdP-initiated flow skips steps 1-3: the user clicks a tile in the IdP portal and an unsolicited assertion is POSTed to the SP. It is convenient but weaker (no `InResponseTo` correlation, larger CSRF/injection surface); SP-initiated is preferred.

### The Assertion

```
<saml:Assertion ID="_8e9f..." IssueInstant="2026-07-06T12:00:00Z">
  <saml:Issuer>https://idp.acme.com/exk1a2b3</saml:Issuer>
  <ds:Signature>...X.509 signed...</ds:Signature>
  <saml:Subject>
    <saml:NameID Format="...emailAddress">alice@acme.com</saml:NameID>
    <saml:SubjectConfirmationData NotOnOrAfter="2026-07-06T12:05:00Z"
        Recipient="https://app.acme.com/saml/acs"/>
  </saml:Subject>
  <saml:Conditions NotBefore="..." NotOnOrAfter="...">
    <saml:AudienceRestriction>
      <saml:Audience>https://app.acme.com/sp</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
  <saml:AuthnStatement AuthnInstant="..."
      SessionIndex="_s1">
    <saml:AuthnContextClassRef>...PasswordProtectedTransport
  </saml:AuthnStatement>
  <saml:AttributeStatement>
    <saml:Attribute Name="email">alice@acme.com</saml:Attribute>
    <saml:Attribute Name="groups">engineering, oncall</saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
```

Everything the SP trusts is here: who (NameID), from whom (Issuer + signature), for whom (Audience), for how long (Conditions), how they logged in (AuthnContext), plus attributes for role mapping.

### SCIM: Provisioning Is the Other Half

SSO answers "can Alice log in?"; SCIM answers "does Alice's account exist, with the right groups, and is it killed the minute she is offboarded?" — the IdP pushes lifecycle changes to a REST API the app exposes:

```
IdP                                     App (SP)
   │  POST /scim/v2/Users {userName: alice@acme.com, ...}
   │──────────────────────────────────────────────────────►
   │  PATCH /scim/v2/Users/42 {active: false}   (offboard!)
   │──────────────────────────────────────────────────────►
   │  PATCH /scim/v2/Groups/eng {add member 42}
   │──────────────────────────────────────────────────────►
```

Deprovisioning is the security payoff: without SCIM, ex-employees keep working accounts in every SaaS app until someone remembers.

## SAML vs OIDC

```
┌────────────────┬──────────────────────────┬──────────────────────────┐
│                │ SAML 2.0                 │ OIDC                     │
├────────────────┼──────────────────────────┼──────────────────────────┤
│ Format         │ XML + XML-DSig           │ JSON + JWT (JWS)         │
│ Year           │ 2005                     │ 2014                     │
│ Transport      │ browser redirect/POST    │ REST + browser redirect  │
│ Mobile/SPA/API │ poor (browser-only)      │ native fit               │
│ Discovery      │ metadata XML exchange    │ /.well-known URL         │
│ Crypto surface │ XML canonicalization —   │ compact JWS — far fewer  │
│                │ rich attack history      │ parsing pitfalls         │
│ Provisioning   │ none (pair with SCIM)    │ none (pair with SCIM)    │
│ Entrenched in  │ enterprise SaaS, ADFS,   │ everything built since   │
│                │ government, education    │ ~2015, mobile, agents    │
└────────────────┴──────────────────────────┴──────────────────────────┘
```

Direction of travel: OIDC for anything new, SAML supported forever because the enterprise install base demands it. Identity platforms translate between them — an app integrated once via OIDC can accept any customer's SAML IdP upstream.

## Attacks and Defenses

- **XML Signature Wrapping (XSW)**: attacker moves the signed assertion and injects a forged one where naive parsers look; signature still "validates". Defense: validate schema first, process only the signed element, use a hardened SAML library — never hand-rolled XML parsing
- **Golden SAML**: attacker who steals the IdP's **signing key** (as in the 2020 SolarWinds/Sunburst campaign against ADFS) mints valid assertions for any user, any app, bypassing MFA entirely. Defense: HSM-protect signing keys, monitor for assertions the IdP has no login record for, rotate on suspicion
- **Comment/entity parsing bugs**: 2018 Duo research — XML comments inside NameID split user identity (`alice@acme.com<!---->.evil.com`) across parsers. Defense: patched libraries, canonical NameID comparison
- **Unsigned or partially signed responses**: accepting assertions where only the response (or nothing) is signed. Defense: require signed assertions, reject `SignatureValue`-less messages
- **Replay**: reusing a captured assertion. Defense: enforce `NotOnOrAfter`, one-time `InResponseTo`, and assertion ID caching
- **IdP-initiated CSRF/login CSRF**: unsolicited assertions logging the victim into an attacker-chosen session. Defense: prefer SP-initiated, RelayState validation

## Pros

- **One login, everything**: fewer passwords, fewer phishing targets, one MFA enrollment point
- **Centralized control**: policy, MFA, session length, and revocation live in one IdP console
- **Instant offboarding**: disable one IdP account (plus SCIM) and every downstream app is cut off
- **Enterprise sales unlock**: SAML + SCIM support is a hard procurement requirement upmarket
- **Battle-tested trust model**: 20 years of signed-assertion federation across vendors that never met
- **App never sees credentials**: passwords and MFA stay at the IdP; the SP only consumes assertions
- **Audit consolidation**: every login for every app lands in one IdP log stream

## Cons

- **IdP is a single point of failure and compromise**: a breach of the central identity provider can ripple to every connected application
- **XML complexity is an attack surface**: canonicalization, signature wrapping, and entity bugs keep recurring; JWT/OIDC has a much smaller parsing story
- **Painful multi-tenant setup**: per-customer metadata exchange, certificate rotations, and clock-skew tickets are a permanent support tax
- **No native API/mobile story**: SAML assumes a browser; APIs and native apps need OIDC/OAuth anyway
- **Session lifetime mismatch**: SP sessions outlive IdP revocation unless Single Logout (which is notoriously unreliable) or short sessions are enforced
- **Certificate expiry outages**: a forgotten signing-cert rollover silently breaks login for a whole customer
- **Golden SAML risk**: the signing key is a skeleton key; protecting it is on you

## Use Cases

- **Workforce SSO**: employees reaching Salesforce, Workday, GitHub, and AWS through an enterprise IdP with one login
- **B2B SaaS enterprise readiness**: letting each customer bring their own IdP (SAML or OIDC) to your product, per-tenant
- **Automated joiner/mover/leaver**: HR-driven SCIM provisioning and same-day deprovisioning across the app estate
- **Education and government federation**: Shibboleth/InCommon academic federations built on SAML
- **Cloud console access**: SAML federation into AWS IAM roles and GCP workforce identity
- **MFA everywhere by policy**: enforcing phishing-resistant MFA once at the IdP for hundreds of apps
- **Merging identity estates**: bridging ADFS/legacy IdPs into modern platforms during M&A integrations

## Links

- SAML 2.0 Core (OASIS): https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf
- SAML technical overview (OASIS): https://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html
- RFC 7643 — SCIM Core Schema: https://datatracker.ietf.org/doc/html/rfc7643
- RFC 7644 — SCIM Protocol: https://datatracker.ietf.org/doc/html/rfc7644
- Auth0 docs — SAML: https://auth0.com/docs/authenticate/protocols/saml
- Duo — Duo Finds SAML Vulnerabilities Affecting Multiple Implementations (2018): https://duo.com/blog/duo-finds-saml-vulnerabilities-affecting-multiple-implementations
- CISA on Golden SAML / detecting abuse: https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-008a
- On Breaking SAML: Be Whoever You Want to Be (USENIX 2012): https://www.usenix.org/conference/usenixsecurity12/technical-sessions/presentation/somorovsky
- SAMLTool (OneLogin utilities): https://www.samltool.com/
