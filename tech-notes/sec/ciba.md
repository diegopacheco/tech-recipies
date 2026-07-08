# CIBA (Client-Initiated Backchannel Authentication) in A2A Context

## What is it?

CIBA (Client-Initiated Backchannel Authentication) is a **decoupled** OAuth 2.0 / OpenID Connect flow: the device running the client is **not** the device where the user authenticates and approves. There is **no browser redirect**. Instead the client makes a direct back-channel POST to the authorization server asking it to authenticate a named user, gets back a request id, and the authorization server reaches the user out-of-band — typically a push notification to their phone — to collect authentication and consent. The client waits (polls or is notified) until the user approves, then receives tokens. Classic OAuth is a **redirect flow** built around a human sitting at a browser; CIBA is a **decoupled flow** built for the case where the thing needing access and the human who must approve are separated in device, and often in time.

In an **A2A (Agent-to-Agent) and autonomous-agent** context this is the key primitive: an agent runs with **no human present at call time**, hits an action that needs a real human decision — a payment, a trade, a data deletion, a privileged tool call — and fires a CIBA request. The authorization server pushes "Approve?" with a description of exactly what is being asked to the user's phone; the agent blocks or polls; the human approves with biometrics; the agent gets a **scoped, per-action token** and proceeds. CIBA is the identity-layer mechanism behind "async human-in-the-loop approval" for agents. It turns "the LLM decided to do X" into "a human explicitly authorized X" without collapsing the whole workflow into a synchronous browser login.

## Who created it? When?

CIBA came out of the **OpenID Foundation's MODRNA working group** (Mobile Operator Discovery, Registration & autheNtication), whose original driver was **mobile network operators and banks**: authenticate a caller in a call center, or confirm a bank transfer, by pushing a prompt to the customer's phone instead of sending them to a web page. The first **implementer's draft was approved on February 4, 2019**, and the final **CIBA Core 1.0** specification was published by the OpenID Foundation in **2021**. A hardened **FAPI-CIBA profile** (Financial-grade API) was produced by the **FAPI working group** for open banking, adding signed requests and dropping the least safe delivery mode. The grant type registered for the flow is **`urn:openid:params:grant-type:ciba`**. The design predates the agent era by years — its "the approver is elsewhere and may respond later" shape is exactly what autonomous agents needed, which is why **Auth0 for AI Agents, Okta, Curity, WSO2 Asgardeo, Ping, and WorkOS** now market CIBA as the async-approval mechanism for agentic systems. It builds on the same base as **Token Exchange (RFC 8693, 2020)** and **the Device Authorization Grant (RFC 8628, 2019)** without inventing new cryptography.

## How it works?

### Two Devices, Decoupled

```
┌──────────────────────────┐        ┌──────────────────────────┐
│   Consumption Device      │       │   Authentication Device   │
│   (agent, call center,    │       │   (the user's phone with  │
│    kiosk, backend job)    │       │    an authenticator app)  │
│   initiates the request   │       │   authenticates + approves│
└──────────────────────────┘        └──────────────────────────┘
        the two are DIFFERENT devices — that is the whole point;
        classic OAuth assumes they are the same browser
```

### The CIBA Flow (poll mode)

```
┌────────────┐                                   ┌──────────────────┐
│  Client    │ 1. POST /bc-authorize             │  Authorization   │
│  (agent)   │    (client auth, scope=openid,    │  Server (OP)     │
│            │     login_hint=alice,             │                  │
│            │     binding_message="Buy 100 ACME"│                  │
│            │──────────────────────────────────►│                  │
│            │◄── auth_req_id, expires_in, ──────│                  │
│            │      interval                     └────────┬─────────┘
│            │                                            │ 2. push notification
│            │                                            ▼
│            │                                   ┌──────────────────┐
│            │                                   │  Alice's phone    │
│            │                                   │  "Approve: Buy    │
│            │                                   │   100 ACME @ $42?"│
│            │                                   └────────┬─────────┘
│            │ 3. POST /token  (poll)                     │ Alice taps
│            │    grant_type=...:ciba                     │ Approve (biometric)
│            │    auth_req_id=...                          │
│            │──────────────────────────────────►         │
│            │◄── 400 authorization_pending ─────         │
│            │        ... wait `interval` ...             │
│            │──────────────────────────────────►◄────────┘
│            │◄── access_token, id_token, ───────  (once approved)
│            │      refresh_token
└────────────┘
```

### Backchannel Authentication Request (`/bc-authorize`)

The client authenticates itself (CIBA is for **confidential clients**), then POSTs:

```
POST /bc-authorize
  scope=openid trade:execute            (openid is required)
  login_hint=alice@acme.com             (one hint identifies the user:
  # or login_hint_token=<signed>         login_hint / login_hint_token /
  # or id_token_hint=<prior id_token>    id_token_hint)
  binding_message=Buy 100 ACME @ $42     (shown on the phone, ties request
                                          to approval — max ~few chars)
  user_code=1234                         (optional: user secret to start auth)
  requested_expiry=300                   (how long the request stays valid)
  acr_values=urn:...:mfa                 (required authentication strength)
  client_notification_token=<opaque>     (required for ping/push modes)
```

The OP responds **immediately** with an acknowledgement — it does not wait for the human:

```
{
  "auth_req_id": "1c266114-a1be-4252-8ad1-04986c5b9ac1",
  "expires_in": 300,
  "interval": 5
}
```

`auth_req_id` is the handle for the pending authentication; `interval` is the minimum seconds between polls.

### Three Token Delivery Modes

```
┌──────────┬────────────────────────────────────────────────┬──────────────┐
│ Mode     │ How the client gets the result                 │ Notes        │
├──────────┼────────────────────────────────────────────────┼──────────────┤
│ Poll     │ Client repeatedly POSTs /token with            │ Simplest.    │
│          │ auth_req_id until tokens or error              │ No client    │
│          │                                                │ endpoint     │
├──────────┼────────────────────────────────────────────────┼──────────────┤
│ Ping     │ OP POSTs auth_req_id + client_notification_     │ One poll     │
│          │ token to the client's notification endpoint;   │ after a      │
│          │ client then calls /token once                  │ nudge        │
├──────────┼────────────────────────────────────────────────┼──────────────┤
│ Push     │ OP POSTs the full token set directly to the    │ Forbidden by │
│          │ client's notification endpoint                 │ FAPI-CIBA    │
└──────────┴────────────────────────────────────────────────┴──────────────┘
```

### Polling the Token Endpoint

```
POST /token
  grant_type=urn:openid:params:grant-type:ciba
  auth_req_id=1c266114-a1be-4252-8ad1-04986c5b9ac1
  (+ client authentication)
```

While the user has not yet acted, the OP returns standard OAuth errors:

```
┌──────────────────────┬────────────────────────────────────────────────┐
│ authorization_pending│ Not approved yet — keep polling at `interval`   │
│ slow_down            │ Polling too fast — add 5s to the interval       │
│ expired_token        │ auth_req_id expired before the user acted       │
│ access_denied        │ User (or policy) rejected the request           │
└──────────────────────┴────────────────────────────────────────────────┘
```

### Why This Fits Agents: the `binding_message`

```
Agent decides: "delete production database backup for tenant 42"
      │
      ├─► POST /bc-authorize
      │       login_hint=oncall-engineer
      │       binding_message="Delete backup: tenant-42 (irreversible)"
      │       scope=backup:delete  acr_values=mfa
      │
      │   phone shows the exact sentence, not a generic "approve login"
      │
      ├─► engineer reads it, approves with fingerprint
      │
      └─► token scoped to backup:delete issued; agent does exactly that
```

The `binding_message` is the identity-layer antidote to **prompt injection**: even if a poisoned instruction convinces the model to attempt something, the human sees a plain-language description of the real action and can refuse. The agent's power is capped to the **single approved, scoped** operation.

## CIBA vs Device Grant vs Authorization Code

```
┌────────────────┬──────────────────┬──────────────────┬──────────────────┐
│                │ CIBA             │ Device Grant     │ Auth Code + PKCE │
│                │                  │ (RFC 8628)       │                  │
├────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Who starts     │ Client, back-    │ Device shows a   │ User, via browser│
│                │ channel POST     │ code/URL to user │ redirect         │
├────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ User's job     │ Approve a pushed │ Type a code at a │ Log in on the    │
│                │ prompt on phone  │ URL on 2nd device│ redirected page  │
├────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Browser redir. │ None             │ None             │ Required         │
├────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ User known up  │ Yes (login_hint) │ No               │ Discovered at    │
│ front?         │                  │                  │ login            │
├────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Async / delayed│ Yes, by design   │ Somewhat         │ No, synchronous  │
├────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Best for       │ Agents, call     │ TVs, CLIs, IoT   │ Web, mobile, SPA │
│                │ centers, approval│ with no keyboard │ login            │
└────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

## Anti-Patterns

- **Empty or generic `binding_message`**: "Approve request?" teaches the user to tap yes blindly; the message must name the concrete action so approval means something
- **No `acr_values` on high-risk actions**: accepting a single-tap approval for a payment instead of requiring biometric/MFA on the authentication device
- **Push mode over an unauthenticated client endpoint**: delivering full tokens to a callback with weak verification; FAPI forbids push for exactly this reason
- **Ignoring `slow_down`**: hammering the token endpoint gets the client throttled or blocked
- **Over-broad scope on the issued token**: requesting `admin` when the approved action needs only `backup:delete` — defeats least privilege and the audit story
- **Using CIBA where a synchronous browser login is fine**: the decoupled flow adds latency and a second device; only reach for it when the approver is genuinely elsewhere
- **Long `requested_expiry` with no revocation plan**: a request that stays approvable for hours widens the window for social-engineering the approver
- **Treating approval as identity proof for other actions**: one CIBA approval authorizes one action, not a standing session

## Pros

- **No browser, no redirect**: fits agents, backend jobs, call centers, and kiosks that have no interactive browser at the point of action
- **Human-in-the-loop by construction**: the approver is a real person on a trusted second device, with biometrics available
- **Action-bound consent**: `binding_message` ties the approval to a specific, human-readable operation — strong defense against prompt-injection consequences
- **Asynchronous**: the user can approve seconds or minutes later; the agent workflow survives the wait instead of dying
- **Built on proven standards**: OAuth/OIDC, confidential-client auth, standard token endpoint — mature server support, no new crypto
- **Strong audit trail**: every issuance records the agent, the user, the scope, the `binding_message`, and the approval outcome
- **Step-up ready**: `acr_values` lets you demand MFA exactly on the sensitive actions that warrant it

## Cons

- **Confidential clients only**: needs a client that can authenticate and keep a secret — public SPAs and pure browser apps cannot use it directly
- **User must be identifiable up front**: you need a `login_hint`/`id_token_hint`; CIBA cannot discover an unknown user the way a login page can
- **Latency and friction**: waiting on a human plus polling hops slow the loop; teams get tempted to widen scopes or skip approval
- **Approver fatigue and social engineering**: like any consent prompt, a stream of approvals trains users to tap yes; a well-crafted fake prompt can be dangerous
- **Registered authenticator required**: the user needs an enrolled authentication device and channel — an onboarding and recovery burden
- **Uneven support and interop**: fewer IdPs implement CIBA than authorization code, and delivery-mode and FAPI details vary between vendors
- **Not a full agent-identity answer**: CIBA gates one action; it does not solve delegation, on-behalf-of chains, or preserving the human principal across multiple agent hops (that is token exchange and A2A's job)

## Use Cases

- **Agent async approval**: an autonomous agent pausing for human sign-off on payments, trades, deletions, sends, or privileged tool calls
- **A2A workflows**: a chain of agents escalating a sensitive step to the originating human before any agent proceeds
- **Call center authentication**: an agent verifies a caller by pushing an approval to the caller's phone instead of asking for secrets over the line
- **Open banking / PSD2 SCA**: FAPI-CIBA confirming a payment or account-access consent on the customer's mobile app
- **Backend and batch jobs**: overnight processes that reach a step requiring an explicit human decision
- **Kiosks and shared terminals**: an in-store terminal that pushes authentication to the customer's own device, keeping credentials off shared hardware
- **Step-up authorization**: escalating a normal session to MFA-backed approval for a single high-risk operation

## Links

- OpenID CIBA Core 1.0: https://openid.net/specs/openid-client-initiated-backchannel-authentication-core-1_0.html
- OpenID MODRNA CIBA Profile 1.0: https://openid.net/specs/openid-connect-modrna-client-initiated-backchannel-authentication-profile-1_0.html
- FAPI-CIBA Profile: https://openid.net/specs/openid-financial-api-ciba.html
- Auth0 — CIBA Flow: https://auth0.com/docs/get-started/authentication-and-authorization-flow/client-initiated-backchannel-authentication-flow
- Auth0 for AI Agents — Asynchronous Authorization: https://auth0.com/ai/docs/get-started/asynchronous-authorization
- Okta — Transactional verification using CIBA: https://developer.okta.com/docs/guides/configure-ciba/main/
- Curity — CIBA Flow: https://curity.io/resources/learn/ciba-flow/
- WSO2 Asgardeo — CIBA for AI Agents: https://wso2.com/asgardeo/docs/tutorials/ciba-for-ai-agents/
- WorkOS — CIBA human approval for AI agents: https://workos.com/blog/ciba-human-approval-ai-agents
- RFC 8628 — Device Authorization Grant: https://datatracker.ietf.org/doc/html/rfc8628
- RFC 8693 — Token Exchange: https://datatracker.ietf.org/doc/html/rfc8693
