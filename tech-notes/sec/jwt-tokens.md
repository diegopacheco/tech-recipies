# JWT and Token Security

## What is it?

A JSON Web Token (JWT) is a compact, URL-safe way to transmit signed claims between parties: three base64url segments — header, payload, signature — joined by dots. The receiver verifies the signature with the issuer's key and can then trust the claims inside without a database call. JWTs are the concrete token format behind OIDC ID tokens, most OAuth access tokens, and countless session systems. Token security is the broader discipline around them: choosing signed (JWS) vs encrypted (JWE) vs **opaque** tokens, distributing verification keys (JWK/JWKS), rotating keys and refresh tokens, binding tokens to their holder (DPoP, mTLS) so theft is useless, and avoiding the well-known validation bugs that have generated a decade of CVEs. The core trade JWTs make: **stateless verification** (fast, scalable) in exchange for **hard revocation** (a signed token is valid until it expires, no matter what happened since).

## Who created it? When?

JWT came out of the **IETF JOSE (JSON Object Signing and Encryption) working group**, driven by **Mike Jones (Microsoft)**, **John Bradley**, and **Nat Sakimura** — the same trio behind OIDC. The suite landed in **May 2015**: **RFC 7519 (JWT)**, **RFC 7515 (JWS — signing)**, **RFC 7516 (JWE — encryption)**, **RFC 7517 (JWK — key format)**, **RFC 7518 (JWA — algorithms)**. **RFC 8725 (JWT Best Current Practices, 2020)** codified the lessons from years of implementation flaws, starting with **Tim McLean's 2015 disclosure** of the `alg: none` and RS256→HS256 confusion attacks that hit most JWT libraries at once. Sender-constrained tokens arrived with **RFC 8705 (mTLS-bound tokens, 2020)** and **RFC 9449 (DPoP, 2023)**. **RFC 9068 (2021)** standardized the JWT profile for OAuth access tokens. **PASETO (2018, Scott Arciszewski)** was created as a deliberately less foot-gunned alternative.

## How it works?

### Anatomy

```
eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6ImtleS0yMDI2LTAxIn0
.eyJpc3MiOiJodHRwczovL3RlbmFudC5hdXRoMC5jb20vIiwic3ViIjoi...
.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c

┌─────────── HEADER ───────────┐ ┌───────────── PAYLOAD ─────────────┐
│ {                            │ │ {                                 │
│   "alg": "RS256",            │ │   "iss": "https://tenant.auth0.com/",
│   "typ": "at+jwt",           │ │   "sub": "auth0|507f1f77bcf86",   │
│   "kid": "key-2026-01"       │ │   "aud": "https://api.acme.com",  │
│ }                            │ │   "exp": 1767225600,              │
└──────────────────────────────┘ │   "iat": 1767222000,              │
┌────────── SIGNATURE ─────────┐ │   "jti": "b1946ac9",              │
│ RSASSA-PKCS1-v1_5(           │ │   "scope": "read:invoices",       │
│   SHA256(header.payload),    │ │   "org_id": "org_9f2k"            │
│   private_key )              │ │ }                                 │
└──────────────────────────────┘ └───────────────────────────────────┘
```

base64url is **encoding, not encryption** — anyone can read a JWS payload. Never put secrets in a signed-only token; that is what JWE is for.

### Registered Claims

```
┌───────┬────────────────────────────────────────────────────────────┐
│ iss   │ who issued it — must match the expected issuer exactly     │
│ sub   │ who it is about (stable user/client id)                    │
│ aud   │ who it is FOR — every consumer must reject a foreign aud   │
│ exp   │ expiry (epoch) — hard stop, keep short                     │
│ nbf   │ not valid before                                           │
│ iat   │ issued at                                                  │
│ jti   │ unique token id — enables replay detection and denylists   │
└───────┴────────────────────────────────────────────────────────────┘
```

### Algorithms

```
┌─────────┬───────────────────┬───────────────────────────────────────┐
│ HS256   │ HMAC + shared key │ symmetric: every verifier can also    │
│         │                   │ MINT tokens — only for 1 issuer =     │
│         │                   │ 1 verifier, with a long random key    │
├─────────┼───────────────────┼───────────────────────────────────────┤
│ RS256   │ RSA + SHA-256     │ asymmetric, the OIDC default; public  │
│         │                   │ key verifies, private key signs       │
├─────────┼───────────────────┼───────────────────────────────────────┤
│ ES256   │ ECDSA P-256       │ smaller keys/signatures than RSA      │
├─────────┼───────────────────┼───────────────────────────────────────┤
│ EdDSA   │ Ed25519           │ modern pick: fast, tiny, misuse-      │
│         │                   │ resistant                             │
├─────────┼───────────────────┼───────────────────────────────────────┤
│ none    │ no signature      │ never acceptable on any input path    │
└─────────┴───────────────────┴───────────────────────────────────────┘
```

### JWKS and Key Rotation

Issuers publish public keys at a JWKS endpoint; the `kid` header selects the key:

```
GET https://tenant.auth0.com/.well-known/jwks.json
{ "keys": [
    { "kty": "RSA", "kid": "key-2026-01", "use": "sig",
      "n": "...", "e": "AQAB" },
    { "kty": "RSA", "kid": "key-2025-07", "use": "sig",
      "n": "...", "e": "AQAB" } ] }

Rotation: publish new key → start signing with it → keep old key
published until every token it signed has expired → remove it.
Verifiers cache JWKS with TTL and refetch on unknown kid.
```

### The Validation Checklist

Every consumer, every time — libraries default some of these OFF:

```
1. Pin allowed algorithms server-side (never trust the header's alg)
2. Verify signature against a key fetched from the EXPECTED issuer
3. Check iss is exactly the expected issuer
4. Check aud contains THIS service
5. Check exp / nbf with small clock skew (≤ 60s)
6. Check typ where applicable (at+jwt vs id token confusion)
7. Only then read business claims (scope, org_id, roles)
```

### Classic Attacks

- **`alg: none`**: attacker strips the signature and sets `alg` to none; broken libraries accept it as valid. Fix: allowlist algorithms.
- **RS256 → HS256 confusion**: attacker re-signs the token with HS256 using the issuer's **public** RSA key as the HMAC secret; a library that keys off the header verifies it "correctly". Fix: bind key type to algorithm, pin algorithms.
- **`kid` injection**: `kid` used unsanitized in a file path or SQL lookup (`"kid": "../../public/known-key"`). Fix: treat `kid` as an opaque lookup id into a fixed key set.
- **Missing `aud` check**: a token minted for service A replayed against service B — the cross-service passthrough bug MCP's spec explicitly forbids.
- **Weak HS256 secrets**: short secrets fall to offline cracking (hashcat mode 16500).
- **Trusting an embedded `jwk`/`jku` header**: the token carries its own verification key — attacker signs with their own key and hands it to you.

### JWT vs Opaque Tokens

```
┌────────────────┬─────────────────────────┬─────────────────────────┐
│                │ JWT (self-contained)    │ Opaque (reference)      │
├────────────────┼─────────────────────────┼─────────────────────────┤
│ Validation     │ local: verify signature │ introspection call      │
│                │ zero network hops       │ (RFC 7662) or session DB│
├────────────────┼─────────────────────────┼─────────────────────────┤
│ Revocation     │ hard: valid until exp   │ instant: delete the row │
├────────────────┼─────────────────────────┼─────────────────────────┤
│ Privacy        │ claims readable by      │ nothing leaks; data     │
│                │ anyone holding it       │ stays server-side       │
├────────────────┼─────────────────────────┼─────────────────────────┤
│ Sweet spot     │ service-to-service APIs │ browser sessions,       │
│                │ at scale, short TTLs    │ high-sensitivity tokens │
└────────────────┴─────────────────────────┴─────────────────────────┘

The common hybrid: opaque token at the edge, exchanged at the
gateway for a short-lived internal JWT (phantom token pattern).
```

### Refresh Token Rotation

```
login ──► RT1 issued
use RT1 ─► new AT + RT2 issued, RT1 marked used
use RT2 ─► new AT + RT3 issued, RT2 marked used
use RT1 AGAIN (replay!) ─► reuse detected ─► REVOKE the whole
                            family, force re-login
```

Rotation with reuse detection is what makes long-lived refresh tokens tolerable in browsers and mobile apps; Auth0 ships it as a toggle.

### Sender-Constrained Tokens (DPoP)

Bearer tokens work for whoever holds them. DPoP (RFC 9449) binds the token to a keypair the client proves possession of on every request:

```
client keypair ──► token request carries DPoP proof JWT
authorization server binds token: cnf: { jkt: <thumbprint> }

each API call:
  Authorization: DPoP <access token>
  DPoP: <fresh proof JWT signed by client key,
         covering htm=POST htu=https://api.acme.com/pay + nonce>

stolen token without the private key ──► rejected
```

mTLS-bound tokens (RFC 8705) achieve the same with client certificates; FAPI (open banking) mandates sender-constraining.

## Pros

- **Stateless verification**: any replica validates locally with a cached public key — no session store on the hot path
- **Cross-service by design**: one issuer, many independent verifiers, standard claims
- **Cryptographic integrity**: tampering is detectable; asymmetric signing means verifiers can never mint
- **Rich, structured context**: scopes, tenant, org, and auth-method claims travel with the request
- **Standard tooling everywhere**: JOSE libraries in every language, JWKS support in every gateway and IdP
- **Short-lived by convention**: pairing minutes-long access tokens with rotating refresh tokens caps exposure
- **Upgradeable strength**: DPoP/mTLS binding turns theft-of-token into theft-of-token-plus-private-key

## Cons

- **Revocation gap**: signed tokens stay valid until `exp`; real logout needs short TTLs plus a `jti` denylist or opaque tokens
- **Foot-gun API surface**: a decade of library CVEs (none, confusion, kid) from validation left to caller discretion
- **Readable payloads**: JWS hides nothing; PII in claims leaks through logs, browser storage, and proxies
- **Token bloat**: kitchen-sink claims blow past header limits and add per-request bytes everywhere
- **Key management burden**: JWKS rotation, cache TTLs, and multi-region propagation are on you
- **Clock skew sensitivity**: `exp`/`nbf` checks require sane time sync and tolerances
- **Stale claims**: roles snapshotted at issuance drift from reality until refresh — fine-grained checks belong in an authz service, not the token

## Use Cases

- **OIDC ID tokens**: the signed proof of login every OIDC client validates
- **OAuth access tokens**: RFC 9068 JWT profile validated locally by APIs and gateways
- **Microservice identity propagation**: user context flowing through service meshes without shared sessions
- **Agent and M2M tokens**: short-lived, audience-bound JWTs for MCP servers and service clients
- **Signed one-time links**: email verification and password reset tokens with `exp` and `jti`
- **Webhook signing**: provider-signed payload assertions verifiable with published keys
- **Open banking / FAPI**: DPoP or mTLS-bound JWTs where regulation demands proof-of-possession
- **Federation internals**: SAML-less trust between IdPs via signed assertions (private_key_jwt client auth)

## Links

- RFC 7519 — JSON Web Token: https://datatracker.ietf.org/doc/html/rfc7519
- RFC 7515 — JWS: https://datatracker.ietf.org/doc/html/rfc7515
- RFC 7517 — JWK: https://datatracker.ietf.org/doc/html/rfc7517
- RFC 8725 — JWT Best Current Practices: https://datatracker.ietf.org/doc/html/rfc8725
- RFC 9068 — JWT Profile for OAuth Access Tokens: https://datatracker.ietf.org/doc/html/rfc9068
- RFC 9449 — DPoP: https://datatracker.ietf.org/doc/html/rfc9449
- RFC 8705 — mTLS-Bound Access Tokens: https://datatracker.ietf.org/doc/html/rfc8705
- RFC 7662 — Token Introspection: https://datatracker.ietf.org/doc/html/rfc7662
- jwt.io (Auth0 debugger + library matrix): https://jwt.io/
- Tim McLean — Critical vulnerabilities in JWT libraries (Auth0 blog, 2015): https://auth0.com/blog/critical-vulnerabilities-in-json-web-token-libraries/
- Auth0 docs — Refresh Token Rotation: https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation
- PASETO: https://paseto.io/
