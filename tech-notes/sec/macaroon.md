# Macaroons: Attenuable Authorization Credentials

## What is it?

A **Macaroon** is a bearer authorization credential that carries restrictions called **caveats**. It starts with authority granted by an issuer, but any holder can make that authority narrower before passing the credential to another party. A holder may add limits such as `operation = read`, `path = /reports/2026`, or `time < 2026-07-15T00:00:00Z` without contacting the issuer and without knowing its secret key.

This one-way reduction of authority is called **attenuation**. Caveats are combined with logical AND, so each new caveat can only preserve or reduce what the credential permits. A holder cannot remove or alter an existing caveat without invalidating the cryptographic signature.

Macaroons are capabilities, not identity documents. Possession grants the authority encoded by the credential when every caveat is satisfied. They do not prove who the holder is unless a caveat explicitly requires an identity, device, key, or third-party authentication fact.

## Who created it? When?

Macaroons were introduced by **Arnar Birgisson, Joe Gibbs Politz, Úlfar Erlingsson, Ankur Taly, Michael Vrable, and Mark Lentczner** in the paper **“Macaroons: Cookies with Contextual Caveats for Decentralized Authorization in the Cloud,”** published at the **Network and Distributed System Security Symposium in 2014**.

The work combined the deployability of bearer cookies with decentralized delegation and contextual restrictions. Its cryptographic construction uses chained message authentication codes, normally HMAC. Macaroons are implemented by multiple libraries and production systems, but they are not an IETF standard. The core design does not define one universal caveat language, wire encoding, HTTP authentication scheme, or revocation protocol.

## How it works?

### Core Structure

```
┌────────────────────────────────────────────────────────────┐
│ Macaroon                                                   │
├────────────────────────────────────────────────────────────┤
│ location    Routing hint for the issuing service           │
│ identifier  Opaque reference used to find the root key     │
│ caveats     Restrictions that must all be satisfied        │
│ signature   Final value of the chained MAC                 │
└────────────────────────────────────────────────────────────┘
```

The location is a routing hint and is not necessarily protected by the signature. It must never be treated as an authorization decision. The identifier should be opaque, unique, and sufficient for the issuer to select the correct root key and policy context. Caveat contents are normally visible to the holder, so secrets must not be placed in them.

### Minting and the HMAC Chain

The issuer starts with a secret root key and an identifier:

```
signature₀ = HMAC(root_key, identifier)
```

Adding a first-party caveat uses the current signature as the key for the next link:

```
signature₁ = HMAC(signature₀, "operation = read")
signature₂ = HMAC(signature₁, "path = /reports/2026")
signature₃ = HMAC(signature₂, "time < 2026-07-15T00:00:00Z")
```

```
root key
   │
   ▼
identifier ──HMAC──► signature₀
                         │
operation = read ──HMAC──► signature₁
                              │
path = /reports/2026 ──HMAC──► signature₂
                                   │
time < deadline ───────HMAC────────► final signature
```

The final signature proves the exact order and content of the identifier and caveats. The holder knows the current signature, so it can append another caveat. It does not know an earlier signature or the root key, so it cannot remove a restriction and produce a valid chain.

### First-Party Caveats

A **first-party caveat** is evaluated directly by the service that verifies the Macaroon.

Common predicates include:

- `operation = read`
- `resource = invoice-781`
- `path starts-with /team-a/`
- `time < 2026-07-15T00:00:00Z`
- `source-ip = 203.0.113.10`
- `request-id = 7e62...`

```
Client                         Resource service
   │                                  │
   │ Macaroon + request               │
   ├─────────────────────────────────►│
   │                                  ├─ verify HMAC chain
   │                                  ├─ operation is read?
   │                                  ├─ path is allowed?
   │                                  ├─ current time is before limit?
   │                                  └─ apply current resource policy
   │                                  │
   │ resource or denial               │
   │◄─────────────────────────────────┤
```

Cryptographic validity is only half of verification. The service must also understand and satisfy every caveat from trusted request context. An unknown, malformed, or unevaluable caveat must cause denial.

### Delegation by Attenuation

```
Issuer
  │ full authority: read and write account 42
  ▼
Service A
  │ adds: operation = read
  ▼
Service B
  │ adds: path = /monthly
  ▼
Worker
  │ adds: time < 12:05Z
  ▼
Final credential: read-only, one path, short lifetime
```

Each hop can reduce authority locally. No hop can restore `write`, widen the path, or extend the deadline because all restrictions remain in the signature chain. This is useful when a service receives broad authority but only needs to give a worker one narrow capability.

### Third-Party Caveats and Discharge Macaroons

A **third-party caveat** requires another service to confirm a condition. The original issuer creates a random caveat key, encrypts it into a verification identifier, and adds the third party’s location and caveat identifier to the Macaroon. The chained signature covers the protected caveat data.

```
┌────────┐ 1. request root Macaroon  ┌──────────────────┐
│ Client │◄──────────────────────────│ Resource service │
│        │   caveat: SSO approved    │                  │
└───┬────┘                           └────────┬─────────┘
    │ 2. send caveat identifier               │
    ▼                                          │
┌──────────────┐                               │
│ Identity     │                               │
│ provider     │                               │
└──────┬───────┘                               │
       │ 3. authenticate user                  │
       │ 4. issue discharge Macaroon           │
       ▼                                       │
┌────────┐ 5. root + bound discharge           │
│ Client │────────────────────────────────────►│
└────────┘                                     │
                                    6. verify both
```

The third party issues a **discharge Macaroon** only after satisfying its condition. The discharge may carry its own caveats, including a short expiration or further third-party requirements. Before presentation, it is bound to the primary Macaroon so it cannot be replayed with an unrelated primary credential.

Third-party caveats separate concerns. A storage service can require a current corporate login, payment approval, device posture check, or age assertion without implementing those systems itself and without sharing its root key with the third party.

### Verification

The verifier performs all of these checks:

1. Select the root key using the identifier and trusted issuer context
2. Recompute the entire chained signature in order
3. Reject malformed structures, unsupported versions, and excessive nesting
4. Evaluate every first-party caveat from trusted server-side context
5. Match every third-party caveat with one valid discharge Macaroon
6. Verify discharge binding to the primary Macaroon
7. Apply current authorization policy for the requested resource
8. Deny unless every check succeeds

The last policy check matters. A correctly signed capability should not override resource deletion, account suspension, ownership changes, legal holds, or an explicit server-side denial.

## Macaroons vs Other Token Forms

```
┌──────────────────┬─────────────────┬─────────────────┬─────────────────┐
│ Property         │ Macaroon        │ JWT/JWS         │ Opaque token    │
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Integrity        │ Chained HMAC    │ Signature or MAC│ Server lookup   │
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Holder can narrow│ Yes, append     │ No              │ No              │
│ authority        │ caveats         │                 │                 │
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Public verify    │ Usually no      │ Yes with JWS    │ No              │
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ External facts   │ Third-party     │ Custom protocol │ Introspection or│
│                  │ discharges      │                 │ custom protocol │
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Policy language  │ Application     │ Claims schema   │ Server-side     │
│                  │ defined         │ defined         │                 │
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Standardization  │ De facto format │ IETF RFCs       │ Protocol-defined│
├──────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ Revocation       │ Application     │ Application     │ Immediate delete│
│                  │ defined         │ defined         │ from token store│
└──────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

OAuth describes how clients obtain and use access tokens; it does not require a particular token format. A Macaroon can serve as an OAuth access token, but caveat syntax, client behavior, discharge transport, and resource-server validation must be defined by the deployment.

JWT is a better fit when many independent verifiers need public-key validation and the holder does not need to delegate narrower authority. An opaque token is simpler when the authorization server can be consulted for every decision. Macaroons are strongest when local attenuation and decentralized external conditions are central requirements.

## Security Properties

- **Integrity**: changing the identifier, protected caveat data, order, or signature breaks verification
- **Attenuation**: holders can add conjunctive restrictions without access to the root key
- **Decentralized delegation**: an attenuated credential can be passed through multiple services without issuer involvement
- **Contextual confinement**: caveats can bind authority to a resource, action, time, request, device, or authenticated fact
- **Third-party authorization**: external services can discharge conditions without receiving the issuer’s root key
- **Efficient verification**: HMAC is fast and avoids public-key work for the primary chain

Macaroons do not provide confidentiality, proof of possession, automatic revocation, standardized policy semantics, or protection after a valid bearer credential is stolen. Those properties require additional controls.

## Threats and Defenses

### Token Theft and Replay

A Macaroon is normally a bearer credential. Anyone who steals it can use it within its caveats.

- Use TLS for every transport
- Store credentials like passwords or API keys
- Add short expiration, narrow resource, and narrow operation caveats
- Bind sensitive authority to a session, device key, or one-time request when the verifier supports it
- Never write complete credentials, signatures, or discharge tokens to logs

### Caveat Parsing and Semantic Bugs

The HMAC only protects bytes. It does not make the verifier’s interpretation correct.

- Define one canonical encoding and strict grammar
- Version caveat types and semantics
- Reject unknown fields, unknown operators, invalid Unicode, ambiguous paths, and malformed timestamps
- Evaluate all caveats as conjunctions and fail closed
- Test equivalent paths, clock boundaries, integer limits, duplicate values, and encoding edge cases

### Untrusted Context

An IP, hostname, user, method, or tenant caveat is only as strong as the source used to satisfy it.

- Derive request properties after trusted proxy normalization
- Do not trust client-supplied forwarding or identity headers
- Bind tenant and audience to server-owned routing context
- Recheck the requested operation after all middleware rewrites

### Root-Key Compromise

The root key can mint credentials with any authority in its domain.

- Keep root keys in a KMS, HSM, or isolated secret store
- Use separate keys per service, tenant, environment, and purpose
- Put a key version in the opaque identifier
- Rotate keys while retaining only the verification window required by active credentials
- Revoke the affected key family after compromise

### Discharge Confusion and Replay

- Bind every discharge to the exact primary Macaroon
- Verify the intended third-party caveat identifier and location through configured trust, not the location hint alone
- Give discharges a short lifetime and a narrow purpose
- Prevent one discharge from satisfying multiple caveats unless policy explicitly permits it
- Limit recursive discharge depth, total caveats, and serialized size

### Revocation

Offline attenuation does not provide immediate revocation by itself.

- Prefer short-lived credentials
- Maintain a deny list for high-risk identifiers when online checks are acceptable
- Rotate or retire root keys to revoke a class of credentials
- Include current account or resource state in the final authorization decision
- Use opaque server-side tokens when immediate individual revocation is the dominant requirement

## Anti-Patterns

- **No expiration caveat**: a leaked capability remains useful indefinitely
- **Broad root credential everywhere**: attenuation has no value if every worker also receives the unrestricted credential
- **Unknown caveats ignored**: an attacker can rely on a restriction that the verifier silently skips
- **Caveats built from raw strings**: inconsistent parsers can disagree about paths, times, tenants, or operations
- **Authorization from location hints**: locations assist routing but are not trusted policy
- **Secrets inside caveats**: caveat text is generally visible to credential holders and intermediaries
- **Root key shared across domains**: one compromise becomes authority over every service and tenant
- **Unbound discharges**: a valid third-party proof may be replayed with another primary credential
- **Client headers treated as facts**: bearer-controlled input must not satisfy trusted contextual restrictions
- **Macaroon validity treated as sufficient**: current resource policy still needs enforcement

## Pros

- **Least-privilege delegation**: every recipient can receive less authority than its caller
- **Offline attenuation**: narrowing a credential does not require an issuer round trip
- **Fast cryptography**: the primary construction uses efficient symmetric primitives
- **Flexible context**: deployments can define restrictions suited to their resources and threat model
- **External authorization facts**: discharge Macaroons compose identity, payment, approval, and posture services
- **Unregistered delegates**: a recipient can exercise a shared capability without having a local account
- **Incremental deployment**: a Macaroon can fit into systems that already accept bearer credentials

## Cons

- **Bearer-token exposure**: theft permits replay within the remaining caveats
- **No universal policy language**: interoperability requires agreement on caveat syntax and meaning
- **Symmetric verification trust**: a verifier with the root key can also mint credentials unless keys and roles are separated by a higher-level design
- **Complex third-party flow**: discharge discovery, acquisition, refresh, binding, and error handling add protocol work
- **Difficult immediate revocation**: short lifetimes or online state are still needed
- **Growing credentials**: delegation, caveats, and discharges increase request size and verification work
- **Parser security boundary**: inconsistent normalization or permissive caveat checking can destroy attenuation guarantees
- **Smaller ecosystem**: libraries and operational tooling are less widespread than OAuth and JWT tooling

## Use Cases

- **Capability links**: share one object with read-only access for a short period
- **Service delegation**: pass a narrowly attenuated credential from an API to a worker or downstream service
- **Agent tool access**: reduce a user-granted capability to one tool, resource, action, and task lifetime
- **Object storage**: authorize a path, operation set, byte range, or transfer window
- **Build and package systems**: grant a pipeline permission to upload one artifact to one channel
- **Cross-controller operations**: authorize a limited relationship between independently managed control planes
- **Third-party identity**: require an identity provider to discharge a login or MFA caveat
- **Payment approval**: require a transaction service to discharge a caveat tied to one amount and request
- **Disconnected verification**: validate constrained authority locally when symmetric key distribution is acceptable

## Production Uses

- **Ubuntu Snap Store and Enterprise Store** use root and discharge Macaroons with Ubuntu SSO
- **Juju and JAAS** use Macaroons for authorization across controllers and application offers
- **dCache** supports constrained bearer tokens for controlled storage access and sharing

## Links

- Google Research publication: https://research.google/pubs/macaroons-cookies-with-contextual-caveats-for-decentralized-authorization-in-the-cloud/
- Original NDSS paper: https://research.google.com/pubs/archive/41892.pdf
- Go Macaroon package: https://pkg.go.dev/gopkg.in/macaroon.v2
- Go Macaroon Bakery: https://pkg.go.dev/gopkg.in/macaroon-bakery.v2/bakery
- libmacaroons: https://github.com/rescrv/libmacaroons
- Ubuntu Enterprise Store authentication: https://ubuntu.com/enterprise-store/docs/reference/api-authentication/
- JAAS security and Macaroons: https://canonical.com/juju/docs/jaas/v3/explanation/jaas-security/
- dCache Macaroons guide: https://dcache.org/manuals/UserGuide-9.0/macaroons.shtml
