# WebAuthn and Passkeys

## What is it?

WebAuthn (Web Authentication) is a W3C standard that lets websites authenticate users with **public-key cryptography** instead of passwords. During registration the user's device (authenticator) generates a keypair per site; the site stores the public key, the device keeps the private key inside secure hardware. Login is a challenge-response: the site sends a random challenge, the device signs it after the user proves presence (touch) or identity (biometric/PIN), and the site verifies the signature. Because the browser binds every signature to the **origin** that requested it, credentials are unphishable: a fake `okta-login.com` can never obtain a signature valid for `okta.com`. **Passkeys** are the consumer-friendly evolution: discoverable WebAuthn credentials that sync across a user's devices through iCloud Keychain, Google Password Manager, or a password manager — making the model survive lost phones, which was the practical blocker for FIDO adoption. WebAuthn plus CTAP (the protocol between browser and external authenticators like YubiKeys or phones) together form **FIDO2**.

## Who created it? When?

The **FIDO ("Fast IDentity Online") Alliance** was founded in **2012-2013** by PayPal, Lenovo, Nok Nok Labs, and others to kill passwords. The first generation, **U2F**, was developed by **Google and Yubico (2014)** as a second-factor USB key standard. FIDO2 followed: **WebAuthn** was standardized by the **W3C** (Level 1 Recommendation, **March 2019**; editors from Google, Microsoft, Mozilla, Yubico, and PayPal) alongside the FIDO Alliance's **CTAP2**. The breakthrough moment was **May 2022**, when **Apple, Google, and Microsoft jointly announced passkeys** — synced, multi-device FIDO credentials — shipping in **iOS 16 / macOS Ventura (September 2022)**, Android, and Windows 11. Adoption followed fast: GitHub, Google, Amazon, TikTok, and WhatsApp rolled out passkey login through 2023-2024, and Microsoft made passkeys the default for new consumer accounts in **2024**. **Auth0 and Okta** ship passkeys as a first-class factor in their universal login.

## How it works?

### Registration Ceremony

```
┌──────┐        ┌─────────┐          ┌────────────────┐        ┌────────────┐
│ User │        │ Browser │          │ Authenticator  │        │  Server    │
└──┬───┘        └────┬────┘          │ (TouchID, Yubi,│        │ (RP:       │
   │                 │               │  phone)        │        │ acme.com)  │
   │                 │               └───────┬────────┘        └─────┬──────┘
   │  "add passkey"  │  challenge + rp.id=acme.com + user info      │
   │────────────────►│◄──────────────────────────────────────────────│
   │                 │ navigator.credentials.create()                │
   │                 │──────────────────────►│                       │
   │  touch/biometric verification           │                       │
   │─────────────────────────────────────────►                       │
   │                 │                       │ generate keypair      │
   │                 │                       │ scoped to acme.com,   │
   │                 │                       │ private key stays in  │
   │                 │  credential id +      │ secure enclave/TPM    │
   │                 │  PUBLIC key +         │                       │
   │                 │  attestation          │                       │
   │                 │◄──────────────────────│                       │
   │                 │ send to server ──────────────────────────────►│
   │                 │                       │   store public key +  │
   │                 │                       │   credential id + sign│
   │                 │                       │   counter per user    │
```

### Authentication Ceremony

```
   │  "log in"       │  challenge + rp.id                            │
   │────────────────►│◄──────────────────────────────────────────────│
   │                 │ navigator.credentials.get()                   │
   │                 │──────────────────────►│                       │
   │  user presence / user verification      │                       │
   │─────────────────────────────────────────►                       │
   │                 │                       │ sign( authenticatorData
   │                 │   assertion:          │  + hash(clientDataJSON:
   │                 │   signature + data    │    challenge, ORIGIN, │
   │                 │◄──────────────────────│    type) )            │
   │                 │ send to server ──────────────────────────────►│
   │                 │                       │ verify signature with │
   │                 │                       │ stored public key,    │
   │                 │                       │ check origin, rpIdHash│
   │                 │                       │ challenge, UV/UP flags│
   │  session ◄──────────────────────────────────────────────────────│
```

The two properties that make this unphishable: the **browser** writes the origin into `clientDataJSON` (the page's JavaScript cannot lie about it), and the credential is **scoped to rp.id** — an attacker's look-alike domain triggers a different credential scope, so there is simply nothing to steal or replay.

### Synced vs Device-Bound

```
┌──────────────────────┬───────────────────────┬──────────────────────────┐
│                      │ Synced passkey        │ Device-bound key         │
├──────────────────────┼───────────────────────┼──────────────────────────┤
│ Private key lives    │ provider sync fabric  │ one authenticator only   │
│                      │ (iCloud Keychain,     │ (YubiKey, TPM,           │
│                      │ Google PW Manager,    │ platform enclave)        │
│                      │ 1Password, Bitwarden) │                          │
├──────────────────────┼───────────────────────┼──────────────────────────┤
│ Lost device          │ survives — synced     │ credential gone; needs   │
│                      │                       │ backup key enrolled      │
├──────────────────────┼───────────────────────┼──────────────────────────┤
│ Attestation          │ generally none        │ verifiable device model  │
├──────────────────────┼───────────────────────┼──────────────────────────┤
│ Fits                 │ consumer login (CIAM) │ high-assurance workforce,│
│                      │                       │ regulated, admin access  │
└──────────────────────┴───────────────────────┴──────────────────────────┘
```

**Cross-device (hybrid) flow**: logging in on a laptop with the passkey on your phone — the browser shows a QR code, the phone scans it, and proximity is proven over BLE before the phone signs. Proximity check means a remote phisher cannot relay the QR to a victim across the internet.

**Discoverable credentials + conditional UI**: passkeys are resident on the authenticator and surface in the browser's autofill, so login can be a single tap with no username typed.

## Phishing Resistance Compared

```
┌──────────────────────┬───────────┬───────────────┬─────────────────────┐
│ Factor               │ Phishable │ Replayable    │ Breach exposure     │
├──────────────────────┼───────────┼───────────────┼─────────────────────┤
│ Password             │ yes       │ yes           │ hash cracking, reuse│
│ SMS OTP              │ yes       │ yes (60s)     │ + SIM swap          │
│ TOTP app             │ yes       │ yes (30s)     │ seed theft          │
│ Push approval        │ yes (MFA  │ n/a           │ fatigue attacks     │
│                      │ fatigue)  │               │ (Uber 2022)         │
│ Passkey / WebAuthn   │ NO        │ no (challenge │ server stores only  │
│                      │ (origin-  │ + origin      │ PUBLIC keys —       │
│                      │ bound)    │ bound)        │ nothing to crack    │
└──────────────────────┴───────────┴───────────────┴─────────────────────┘
```

Adversary-in-the-middle kits (Evilginx-style) that proxy real login pages defeat every OTP and push factor; they do not defeat WebAuthn, because the proxied origin does not match and the browser never produces a usable signature.

## Anti-Patterns

- **Passkey login, password fallback**: keeping password + SMS reset alongside passkeys leaves the phishable path open — attackers just use the downgrade
- **Weak account recovery**: unphishable login guarded by an email-link recovery flow moves the attack to recovery; recovery must be as strong as the front door
- **Treating passkeys as second factor only**: they are multi-factor in one gesture (possession + biometric/PIN); forcing password-then-passkey doubles friction for no gain
- **Ignoring `userVerification` flags**: accepting UP-only assertions where policy requires UV silently drops to single-factor possession
- **Requiring attestation for consumer passkeys**: synced passkeys mostly ship none; demanding it breaks mainstream users for marginal signal
- **Assuming session safety**: WebAuthn secures login, not the cookie after it — infostealers grab sessions; pair with short sessions, DPoP, or token binding

## Pros

- **Phishing-resistant by construction**: origin binding makes credential-stealing sites and AitM proxies useless
- **Nothing worth breaching server-side**: the relying party stores public keys; a database dump yields no reusable secrets
- **No shared secret, no reuse**: every site gets its own keypair; credential stuffing dies
- **Faster login**: one biometric gesture beats typing a password plus an OTP; conversion measurably improves
- **Platform momentum**: built into every major OS, browser, and password manager; users already have capable devices
- **Regulatory alignment**: satisfies phishing-resistant MFA mandates (US OMB M-22-09 zero-trust memo, PSD2 SCA)
- **CIAM and workforce ready**: Auth0/Okta expose it as a toggle — no crypto code required from app teams

## Cons

- **Account recovery is the new weakest link**: lose all synced devices and providers fall back to flows attackers love
- **Sync fabric trust**: a compromised Apple/Google account (or its recovery path) can pull synced passkeys; device-bound keys avoid this at a usability cost
- **Ecosystem lock-in friction**: moving passkeys between Apple/Google/password-manager ecosystems is still rough; portability specs are young
- **No attestation on synced passkeys**: high-assurance environments cannot verify what hardware holds the key
- **Support burden shifts**: help desks must handle "lost my passkey" and multi-device enrollment instead of password resets
- **Partial coverage reality**: most deployments keep passwords as fallback for years, capping the security win until the legacy path is closed
- **Doesn't protect the session**: post-login token/cookie theft remains, and agent/API flows need OAuth on top

## Use Cases

- **Consumer passwordless login (CIAM)**: one-tap sign-in with conversion gains and stuffing immunity
- **Phishing-resistant workforce MFA**: replacing push/OTP after fatigue-attack incidents; mandated in US federal zero-trust
- **Step-up authentication**: requiring a fresh UV assertion before payments, key export, or admin actions
- **High-assurance admin access**: device-bound keys with attestation for production and privileged consoles
- **Human-in-the-loop agent approval**: the biometric gesture behind CIBA-style "approve this agent action" prompts
- **Re-authentication UX**: replacing "re-enter your password" prompts with a touch
- **Shared/kiosk devices**: cross-device QR flow authenticating with the user's phone without typing anything

## Links

- W3C WebAuthn spec: https://www.w3.org/TR/webauthn-3/
- FIDO Alliance — passkeys: https://fidoalliance.org/passkeys/
- passkeys.dev (implementation hub): https://passkeys.dev/
- webauthn.guide (illustrated intro): https://webauthn.guide/
- webauthn.io (live playground): https://webauthn.io/
- CTAP 2.2 spec: https://fidoalliance.org/specs/fido-v2.2-rd-20230321/fido-client-to-authenticator-protocol-v2.2-rd-20230321.html
- Auth0 docs — Passkeys: https://auth0.com/docs/authenticate/database-connections/passkeys
- Okta — passkeys overview: https://www.okta.com/blog/2023/09/what-are-passkeys/
- Apple/Google/Microsoft joint announcement (May 2022): https://fidoalliance.org/apple-google-and-microsoft-commit-to-expanded-support-for-fido-standard/
- OMB M-22-09 — US federal zero trust strategy: https://www.whitehouse.gov/wp-content/uploads/2022/01/M-22-09.pdf
