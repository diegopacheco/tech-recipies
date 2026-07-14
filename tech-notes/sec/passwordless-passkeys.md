# Passwordless Authentication and Passkeys

## What is it?

Passwordless authentication verifies a user without asking for a reusable password. The strongest form uses a **passkey**: a FIDO public-key credential scoped to one relying party. The user's authenticator generates a private/public key pair, the service stores only the public key, and each sign-in proves control of the private key by signing a fresh challenge. The private key is never sent to the service.

A passkey can be **synced** through a credential provider so it is available across the user's devices, or **device-bound** so it remains on one authenticator such as a hardware security key. The user unlocks the credential locally with a device PIN, fingerprint, face recognition, or another activation method. Biometric data stays on the device and is not sent to the relying party.

Not every passwordless method has the same security. Email magic links, SMS codes, and one-time passwords remove the password from the screen but remain vulnerable to phishing, mailbox or phone takeover, relay attacks, and recovery abuse. Passkeys are phishing-resistant because the browser and authenticator bind the signed response to the real relying-party domain.

## Who created it? When?

The **FIDO Alliance**, founded in **2012**, developed standards intended to reduce dependence on passwords. Google and Yubico created **Universal 2nd Factor (U2F)** in **2014**. The FIDO Alliance then developed CTAP while the W3C Web Authentication Working Group standardized **WebAuthn**. WebAuthn Level 1 became a W3C Recommendation in **March 2019**; WebAuthn and CTAP together are called **FIDO2**.

Apple, Google, and Microsoft announced broad support for the consumer term **passkey** in **May 2022**. Platform support followed across major operating systems, browsers, and password managers. WebAuthn Level 3 reached Candidate Recommendation Snapshot status in **May 2026**, adding and refining capabilities around credential discovery, cross-origin use, JSON serialization, signals, and related-origin validation.

## Passwordless Methods Compared

```
┌────────────────────┬────────────────┬──────────────┬─────────────────────┐
│ Method             │ Main proof     │ Phishing-   │ Main weakness       │
│                    │                │ resistant    │                     │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ Synced passkey     │ private key +  │ yes          │ provider account or │
│                    │ local unlock   │              │ device recovery     │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ Device-bound       │ hardware-held  │ yes          │ loss unless another │
│ passkey            │ key + unlock   │              │ credential exists   │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ Email magic link   │ mailbox access │ no           │ mailbox takeover,   │
│                    │                │              │ forwarding, relay   │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ SMS or voice OTP   │ phone channel  │ no           │ SIM swap, rerouting,│
│                    │                │              │ real-time phishing  │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ Authenticator OTP  │ shared seed    │ no           │ real-time phishing  │
│                    │ + typed code   │              │ and seed theft      │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ Push approval      │ enrolled device│ no           │ fatigue and session │
│                    │                │              │ relay               │
├────────────────────┼────────────────┼──────────────┼─────────────────────┤
│ Federated login    │ upstream IdP   │ depends      │ inherits the IdP's  │
│                    │ assertion      │ on IdP        │ login and recovery  │
└────────────────────┴────────────────┴──────────────┴─────────────────────┘
```

Passwordless describes the user interaction. Phishing resistance describes the protocol. The two are not interchangeable.

## How Passkeys Work

### Registration

```
User             Browser or App       Authenticator          Service
 │                     │                    │                    │
 │ choose add passkey  │                    │                    │
 │────────────────────►│ request options: challenge, RP ID,     │
 │                     │ user handle, algorithms                │
 │                     │◄───────────────────────────────────────│
 │                     │ create credential │                    │
 │                     │───────────────────►│                    │
 │ local verification                       │                    │
 │─────────────────────────────────────────►│                    │
 │                     │                    │ generate scoped   │
 │                     │                    │ key pair           │
 │                     │ public key, credential ID, signed data │
 │                     │◄───────────────────│                    │
 │                     │────────────────────────────────────────►│
 │                     │                    │ store public key, │
 │                     │                    │ credential ID,    │
 │                     │                    │ user handle       │
```

The service supplies a cryptographically random, single-use challenge and identifies itself with an RP ID. The authenticator creates a unique credential for that RP ID. Registration must happen inside an authenticated, protected account session; otherwise an attacker could attach the attacker's passkey to the victim's account.

### Authentication

```
User             Browser or App       Authenticator          Service
 │                     │                    │                    │
 │ sign in             │ challenge + RP ID │                    │
 │────────────────────►│◄───────────────────────────────────────│
 │                     │ get assertion     │                    │
 │                     │───────────────────►│                    │
 │ local verification                       │                    │
 │─────────────────────────────────────────►│                    │
 │                     │ signature over challenge, origin,      │
 │                     │ RP-bound authenticator data             │
 │                     │◄───────────────────│                    │
 │                     │────────────────────────────────────────►│
 │                     │                    │ verify challenge, │
 │                     │                    │ origin, RP ID,    │
 │ session established │                    │ flags, signature  │
 │◄────────────────────│                    │                    │
```

The browser supplies the real origin to the authenticator. A phishing site has a different origin and cannot request a signature valid for the legitimate RP ID. This verifier-name binding is what typed OTPs and push approvals lack.

### Discoverable Credentials

A passkey is normally a **discoverable credential**. The authenticator stores enough account information to find the credential from the RP ID, so the service does not need the username first. This supports account selection and true usernameless sign-in.

Web applications can use **conditional mediation** to show passkeys inside the familiar username field through browser autofill. This lets an account support passwords and passkeys during migration without forcing the user through two competing login pages.

### Cross-Device Authentication

When the passkey is on a phone but sign-in begins on another device, the devices can establish a cross-device flow:

```
Computer browser        Phone authenticator             Service
       │ show QR / hybrid transport │                      │
       │◄───────────────────────────►│                      │
       │ verify proximity over BLE  │                      │
       │                             │ local unlock         │
       │                             │ sign RP challenge    │
       │ assertion─────────────────────────────────────────►│
```

The QR code bootstraps an encrypted channel, and Bluetooth Low Energy helps establish physical proximity. The phone does not copy the passkey to the computer; it signs the computer's challenge remotely.

## Synced vs Device-Bound Passkeys

```
┌──────────────────┬──────────────────────────┬──────────────────────────┐
│                  │ Synced passkey           │ Device-bound passkey     │
├──────────────────┼──────────────────────────┼──────────────────────────┤
│ Availability     │ user's provider devices  │ one authenticator        │
│ Recovery         │ provider recovery        │ spare key or separate    │
│                  │ and device restore       │ account recovery         │
│ Key export       │ protected provider sync  │ designed as non-exportable│
│ Assurance fit    │ broad consumer and AAL2  │ workforce admin and AAL3 │
│ Main tradeoff    │ provider account becomes │ hardware loss and        │
│                  │ part of trust boundary   │ enrollment overhead      │
└──────────────────┴──────────────────────────┴──────────────────────────┘
```

NIST SP 800-63B-4 recognizes syncable authenticators at AAL2 when its requirements are met. AAL3 requires a phishing-resistant public-key authenticator with a non-exportable key and stronger hardware protection, so synced passkeys do not meet AAL3.

## Account Lifecycle

### Enrollment

- Require a recently authenticated session and step-up authentication before adding a passkey
- Display which account and relying party will receive the credential
- Give each credential a recognizable name and record creation time, last use, transport, and backup state
- Encourage at least two independent ways back into high-value accounts
- Send an out-of-band notification when a credential is added or removed

### Recovery

Recovery determines the real security ceiling. A passkey-protected account with SMS-only recovery is still vulnerable to phone-number takeover. Recovery choices include another enrolled passkey, a device-bound security key, verified enterprise help desk, offline recovery codes, or a carefully governed identity reproofing process.

Recovery should invalidate relevant sessions, rotate recovery artifacts, notify the account owner, and create a high-signal audit event. High-risk changes can use a delay or require approval from an already trusted device.

### Deletion and Replacement

Users need a credential-management page that lists passkeys and lets them revoke one without destroying the account. Server-side deletion stops that credential immediately even if a synced copy remains in a provider. Use WebAuthn signal APIs where supported to help providers reconcile stale credentials, while treating the server as the authority.

## Migration Strategy

```
password account
      │
      ▼
offer passkey after a successful strong login
      │
      ▼
show passkey through conditional UI on later visits
      │
      ▼
measure successful use and enroll recovery coverage
      │
      ▼
make passkey primary; retain controlled fallback
      │
      ▼
remove reusable password when recovery is ready
```

Start with existing authenticated users, not only the registration page. Avoid declaring an account passwordless while password reset can silently recreate a password. Track enrollment, sign-in success, fallback use, recovery, and credential removal by platform without collecting unnecessary biometric or device data.

## Attacks and Defenses

- **Passkey injection**: require recent strong authentication before enrollment and alert the owner after any credential change
- **Session theft**: passkeys protect sign-in, not an already authenticated cookie; use secure cookies, short sensitive-session lifetimes, device and risk signals, and reauthentication
- **Malicious browser or endpoint**: code running with user privileges may alter transactions or steal sessions; use transaction confirmation for critical actions and managed-device controls where warranted
- **Provider account takeover**: synced passkeys inherit part of the credential provider's recovery risk; protect the provider account strongly and offer device-bound credentials for privileged roles
- **Weak recovery bypass**: make fallback assurance match the primary path and monitor every recovery event
- **Credential enumeration**: return uniform errors and avoid exposing whether a username or credential exists
- **Registration CSRF**: bind enrollment to the current account and session with anti-CSRF controls and a fresh challenge
- **Challenge replay**: challenges must be unpredictable, single-use, bound to the ceremony, and expire quickly
- **Origin or RP ID mistakes**: validate the exact expected origin and RP ID server-side; configure related origins narrowly
- **Attestation overcollection**: request attestation only when policy needs authenticator provenance because it can add privacy and compatibility costs

## Anti-Patterns

- Calling an email link or SMS code equivalent to a phishing-resistant passkey
- Requiring only one passkey and providing no safe recovery or secondary authenticator
- Letting an active session add a passkey without recent authentication
- Treating biometric matching as server-side identity proof when it only unlocks a local authenticator
- Storing credential IDs as global user identifiers or assuming they are human-readable
- Rejecting synced passkeys everywhere when the actual assurance target is AAL2
- Forcing users to type a username before every passkey sign-in when discoverable credentials are available
- Building WebAuthn parsing and cryptographic validation without a mature server library

## Pros

- **Phishing-resistant**: the credential is bound to the relying-party domain
- **No reusable server secret**: a database breach exposes public keys, not passwords that can authenticate elsewhere
- **No credential reuse**: every relying party receives a distinct key pair
- **Fast interaction**: local unlock replaces typing and remembering secrets
- **Strong privacy**: services cannot correlate users through a shared passkey, and biometrics stay local
- **Usernameless option**: discoverable credentials can identify and authenticate the account in one ceremony
- **Flexible assurance**: synced credentials favor reach and recovery; hardware-bound credentials favor stronger key protection

## Cons

- **Recovery remains difficult**: device loss and provider-account recovery need careful design
- **Ecosystem behavior varies**: browsers, embedded web views, operating systems, and credential providers differ in user experience
- **Shared-device complexity**: account selection and credential cleanup require deliberate handling
- **Migration takes time**: mixed password and passkey accounts preserve password risk until fallback is retired
- **Endpoint compromise still matters**: malware can steal sessions or manipulate actions after authentication
- **Provider trust for sync**: synced passkeys extend the trust boundary to the credential provider and its account recovery
- **Operational metadata**: multiple credentials per user, backup state, revocation, and support flows add lifecycle work

## Use Cases

- Consumer applications replacing passwords with synced passkeys
- Workforce SSO authentication at the central identity provider
- Privileged administrator access using device-bound security keys
- Mobile applications using platform credential APIs
- Shared web and native accounts where one credential should work across approved related origins
- Step-up authentication before payments, key rotation, account recovery, or security-setting changes
- Regulated environments combining device-bound authenticators with managed endpoints and strong identity proofing

## Links

- FIDO Alliance — Passkeys: https://fidoalliance.org/passkeys/
- FIDO Alliance — User Authentication Specifications: https://fidoalliance.org/specifications-overview/
- W3C WebAuthn Level 3: https://www.w3.org/TR/webauthn-3/
- W3C WebAuthn Level 2: https://www.w3.org/TR/webauthn-2/
- FIDO CTAP 2.2: https://fidoalliance.org/specs/fido-v2.2-ps-20250714/fido-client-to-authenticator-protocol-v2.2-ps-20250714.html
- NIST SP 800-63B-4 — Authentication and Authenticator Management: https://pages.nist.gov/800-63-4/sp800-63b.html
- FIDO Credential Exchange Specifications: https://fidoalliance.org/fido-alliance-credential-exchange-specifications-overview/
- Companion note — WebAuthn and Passkeys: webauthn-passkeys.md
- Companion note — Multi-Factor Authentication: mfa.md
