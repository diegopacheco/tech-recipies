# Multi-Factor Authentication (MFA)

## What is it?

Multi-Factor Authentication (MFA) requires a user to prove control of at least two **different factor types** during one authentication event. The classic factors are something the user **knows**, something the user **has**, and something the user **is**. A password plus a phone-held cryptographic key is MFA; a password plus a PIN is not, because both are knowledge factors.

MFA reduces account takeover when one factor is stolen, guessed, phished, leaked, or reused. Its strength depends on the complete protocol, not the number of screens. A typed one-time code can be relayed by a phishing proxy in real time. A push notification can be approved through fatigue or confusion. A FIDO passkey with local biometric or PIN activation can satisfy two factors in one authenticator while binding the response to the legitimate service.

MFA is not the same as **two-step verification**. Two steps may use the same factor type. MFA specifically requires factor independence so one failure does not directly compromise both proofs.

## Who created it? When?

MFA has no single creator. Physical keys, passwords, signatures, and personal recognition have been combined for centuries. Modern electronic use became familiar through payment cards plus PINs and enterprise hardware tokens. **SecurID** time-based tokens appeared in the 1980s. Bellcore's one-time-password work became **S/KEY** and RFC 1760 in **1995**. The IETF standardized **HOTP** in RFC 4226 in **2005** and **TOTP** in RFC 6238 in **2011**.

The FIDO Alliance began in **2012** and shifted strong MFA from manually typed shared-secret codes toward origin-bound public-key authentication. U2F arrived in **2014**, followed by FIDO2 and WebAuthn. NIST formalized authentication assurance levels in its Digital Identity Guidelines and finalized **SP 800-63B-4 in 2025**, recognizing phishing-resistant cryptographic authentication as the direction for higher-assurance access.

## Authentication Factors

```
┌────────────────┬──────────────────────────┬───────────────────────────┐
│ Factor type    │ Common authenticators    │ Typical compromise       │
├────────────────┼──────────────────────────┼───────────────────────────┤
│ Knowledge      │ password, memorized PIN, │ phishing, guessing, reuse,│
│ something known│ recovery answer          │ database cracking         │
├────────────────┼──────────────────────────┼───────────────────────────┤
│ Possession     │ security key, phone key, │ device theft, SIM swap,   │
│ something held │ smart card, OTP token    │ token cloning, malware    │
├────────────────┼──────────────────────────┼───────────────────────────┤
│ Inherence      │ fingerprint, face, iris  │ sensor spoofing, false    │
│ something you  │                          │ match, coerced use        │
│ are            │                          │                           │
└────────────────┴──────────────────────────┴───────────────────────────┘
```

Location, IP address, device posture, behavior, time, and risk score are useful **signals**, but they are not normally independent authentication factors. They can decide when to require MFA or whether to deny access.

Biometrics are not secret and cannot be replaced after exposure. NIST treats a biometric as an activation factor used with a physical authenticator, not as a standalone remote authenticator. The biometric comparison should happen locally, with rate limits and an alternative activation method.

## Authenticator Types Compared

```
┌─────────────────────┬───────────┬──────────┬────────────┬──────────────┐
│ Authenticator       │ Phishing- │ Shared   │ User types │ Relative     │
│                     │ resistant │ secret   │ a value    │ strength     │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ FIDO passkey or key │ yes       │ no       │ no         │ strongest    │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ PIV/smart card      │ yes when  │ no       │ PIN only   │ strongest    │
│                     │ protocol  │          │ locally    │              │
│                     │ is bound  │          │            │              │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ Authenticator TOTP  │ no        │ yes      │ yes        │ moderate     │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ Push with number    │ no        │ often    │ match or   │ moderate     │
│ matching            │           │          │ approve    │              │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ Push approve/deny   │ no        │ often    │ approve    │ weak         │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ SMS or voice OTP    │ no        │ channel  │ yes        │ weakest      │
│                     │           │ dependent│            │ restricted   │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ Email OTP           │ no        │ mailbox  │ yes        │ depends on   │
│                     │           │ dependent│            │ same account │
├─────────────────────┼───────────┼──────────┼────────────┼──────────────┤
│ Recovery questions  │ no        │ yes      │ yes        │ not suitable │
│                     │           │          │            │ as MFA       │
└─────────────────────┴───────────┴──────────┴────────────┴──────────────┘
```

Any MFA is not automatically strong MFA. Prefer public-key authenticators that cryptographically bind each response to the intended verifier. Use typed OTP or hardened push only as a transition or fallback when passkeys and security keys cannot be deployed.

## How it works?

### Password and TOTP Flow

```
User                 Application                  TOTP Authenticator
 │                        │                              │
 │ username + password   │                              │
 │──────────────────────►│ verify password              │
 │                        │                              │
 │ ask for current code  │                              │
 │◄──────────────────────│                              │
 │ read six-digit code                                  │
 │─────────────────────────────────────────────────────►│
 │ code              │                                  │
 │──────────────────►│ compute HOTP(secret, time step)  │
 │                   │ accept current narrow window     │
 │ session cookie    │ reject replayed code             │
 │◄──────────────────│                                  │
```

The service and authenticator share a secret established during enrollment, usually through a QR code. Both calculate a short code from that secret and the current time step. The server should encrypt seeds at rest, tightly restrict access, accept a narrow clock window, rate-limit attempts, and reject reuse within the accepted period.

### Passkey as MFA

```
User             Authenticator                 Service
 │                    │                           │
 │ local PIN or       │                           │
 │ biometric          │                           │
 │───────────────────►│ unlock private key        │
 │                    │ sign fresh RP-bound       │
 │                    │ challenge                 │
 │                    │──────────────────────────►│
 │                    │ possession + local user   │
 │                    │ verification confirmed    │
```

The authenticator represents possession of a private key. Its PIN or biometric supplies the activation factor. The service verifies WebAuthn's user-verification flag and signature. This is multi-factor cryptographic authentication even though the user completes one compact interaction.

### Adaptive and Step-Up Authentication

```
request
   │
   ▼
evaluate session, action, device, network, behavior
   │
   ├── low risk and sufficient assurance ──► allow
   │
   ├── more assurance required ─────────────► step-up MFA
   │
   └── unacceptable risk ───────────────────► deny and investigate
```

Adaptive authentication should reduce unnecessary prompts, not silently replace strong controls. High-impact actions such as changing recovery data, adding an authenticator, exporting data, creating credentials, or sending funds should require recent authentication at a defined assurance level even when the initial login looked low-risk.

## Authentication Assurance Levels

NIST SP 800-63B-4 defines three Authentication Assurance Levels:

```
┌──────┬─────────────────────────────────────────────────────────────┐
│ AAL1 │ single-factor allowed; MFA should be offered                │
├──────┼─────────────────────────────────────────────────────────────┤
│ AAL2 │ two distinct factors required; a phishing-resistant option │
│      │ must be offered                                            │
├──────┼─────────────────────────────────────────────────────────────┤
│ AAL3 │ phishing-resistant public-key authentication with a        │
│      │ non-exportable key, verifier compromise resistance, and    │
│      │ stronger authenticator and verifier requirements           │
└──────┴─────────────────────────────────────────────────────────────┘
```

An assurance level covers the entire process: authenticator binding, authentication protocol, session controls, reauthentication, recovery, records, and verifier behavior. Buying a security key does not make an application AAL3 by itself.

## Enrollment, Recovery, and Removal

### Enrollment

- Bind authenticators only after recent authentication at the account's required assurance level
- Present the account, authenticator type, and security impact clearly
- Protect TOTP seeds and QR codes from logs, analytics, screenshots, browser extensions, and support tools
- Require user verification on FIDO credentials when the credential must count as MFA
- Notify the user through an already trusted channel when any authenticator is added
- Encourage two independent phishing-resistant authenticators for privileged accounts

### Recovery

- Treat recovery as authentication, not customer-service convenience
- Prefer another enrolled strong authenticator or offline single-use recovery codes
- Protect recovery-code display and regeneration with recent step-up authentication
- Do not let a new phone number immediately recover a high-value account
- Apply delays, trusted-device approval, or identity reproofing to high-risk recovery
- Revoke active sessions and notify the owner when recovery indicates possible compromise

### Removal and Reset

- Require recent strong authentication before removing the last strong authenticator
- Record who initiated the change, the method used, and the affected credential
- Notify through channels that were not changed in the same operation
- Let administrators revoke a lost authenticator without learning its secrets
- Reevaluate all sessions after factor reset, account recovery, or privilege change

## Attacks and Defenses

- **Adversary-in-the-middle phishing**: a reverse proxy relays passwords and OTPs, then steals the session; require FIDO/WebAuthn or another verifier-bound cryptographic protocol
- **MFA fatigue**: repeated push requests pressure a user to approve; remove blind approve/deny flows, use number matching and context, rate-limit prompts, and investigate bursts
- **SIM swap and number porting**: an attacker takes control of SMS or voice delivery; avoid phone channels for sensitive accounts and never use them as the only recovery route
- **SS7 and telecom rerouting**: messages are redirected or intercepted; migrate from SMS and voice to cryptographic authenticators
- **TOTP seed theft**: compromise of the shared seed permits code generation; encrypt seeds under separated keys, restrict reads, rotate on exposure, and prefer public-key credentials
- **Real-time OTP relay**: a valid code is entered into an attacker page and immediately forwarded; typed codes cannot provide phishing resistance
- **Push context manipulation**: the user approves a request without understanding it; display the application, location, action, and number while recognizing this still does not equal verifier binding
- **Session-cookie theft**: the attacker bypasses MFA by stealing the resulting session; protect cookies, endpoints, browsers, and tokens, then reauthenticate sensitive actions
- **Help-desk takeover**: social engineering resets the factor; use documented verification, separation of duties, strong audit, delays, and no knowledge-based questions
- **Factor replacement**: an attacker with a stolen session enrolls a new authenticator; require recent step-up and send immediate alerts
- **Fallback downgrade**: the attacker selects a weaker alternate method; make policy evaluate the weakest accepted path and restrict fallback by role and risk
- **Recovery-code theft**: codes stored in email, cloud notes, or screenshots become reusable bypasses; generate high-entropy single-use codes and encourage offline protected storage

## Anti-Patterns

- Counting two passwords, a password plus PIN, or two security questions as MFA
- Treating device recognition, geolocation, or an IP allowlist as a second factor
- Requiring strong MFA for login while allowing weak recovery to disable it
- Sending unlimited push notifications with no rate limit or fraud signal
- Using SMS for privileged administrators when phishing-resistant authenticators are available
- Storing TOTP seeds in plaintext or exposing them in application logs
- Trusting an MFA claim without validating which method, assurance, and authentication time it represents
- Creating long-lived sessions that never require step-up for sensitive changes
- Making one enrolled phone the only route into an account
- Measuring enrollment while ignoring fallback usage, recovery volume, and attack-resistant sign-in coverage

## Pros

- **Limits password damage**: a stolen or reused password alone is insufficient
- **Supports risk-based assurance**: stronger proof can be required for privileged roles and sensitive actions
- **Blocks common automation**: credential-stuffing lists lose much of their value when a second independent proof is required
- **Central enforcement through SSO**: one IdP can apply consistent MFA policy across many applications
- **Strong audit signal**: authenticator type, authentication time, and assurance can inform access decisions and incident response
- **Passwordless path**: multi-factor cryptographic authenticators can remove the password while increasing security
- **Flexible deployment**: organizations can migrate from SMS and OTP toward passkeys and hardware security keys

## Cons

- **Not all methods stop phishing**: OTP, SMS, voice, and push remain relayable
- **Recovery burden**: lost devices and replaced phones create support work and high-risk reset paths
- **User friction**: excessive prompts cause abandonment, workarounds, and approval fatigue
- **Lifecycle complexity**: enrollment, replacement, revocation, inventory, and assurance policy require continuous operations
- **Accessibility and availability needs**: no single authenticator works for every user, device, or environment
- **Central dependency**: an MFA service outage can block access across the organization
- **Session attacks remain**: strong login cannot protect a session already stolen from the endpoint
- **Cost for high assurance**: hardware authenticators, spare keys, device management, and support processes require investment

## Use Cases

- Workforce SSO with phishing-resistant authentication at the central IdP
- Privileged administrators using two registered hardware security keys
- Consumer accounts offering synced passkeys with controlled recovery
- Step-up before payments, credential changes, data export, and destructive actions
- Remote access, VPN, cloud consoles, source control, and production operations
- Regulated systems selecting assurance according to documented risk
- Help-desk and account-recovery operations requiring independent approval
- Legacy applications using TOTP during a planned migration to FIDO authentication

## Links

- NIST SP 800-63B-4 — Authentication and Authenticator Management: https://pages.nist.gov/800-63-4/sp800-63b.html
- NIST SP 800-63-4 — Digital Identity Guidelines: https://pages.nist.gov/800-63-4/
- CISA — Implementing Phishing-Resistant MFA: https://www.cisa.gov/sites/default/files/2023-01/fact-sheet-implementing-phishing-resistant-mfa-508c.pdf
- CISA — Implementing Number Matching in MFA Applications: https://www.cisa.gov/sites/default/files/publications/fact-sheet-implement-number-matching-in-mfa-applications-508c.pdf
- RFC 4226 — HOTP: https://datatracker.ietf.org/doc/html/rfc4226
- RFC 6238 — TOTP: https://datatracker.ietf.org/doc/html/rfc6238
- W3C WebAuthn Level 3: https://www.w3.org/TR/webauthn-3/
- FIDO Alliance — Passkeys: https://fidoalliance.org/passkeys/
- OWASP Multifactor Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- Companion note — Passwordless Authentication and Passkeys: passwordless-passkeys.md
- Companion note — Single Sign-On: sso.md
