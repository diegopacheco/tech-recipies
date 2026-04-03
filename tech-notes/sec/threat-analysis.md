# Threat Analysis

## What is it?

Threat analysis (also called threat modeling) is a structured process for identifying, categorizing, and prioritizing potential threats to a system. It answers four fundamental questions: What are we building? What can go wrong? What are we going to do about it? Did we do a good enough job? The goal is to find security issues before attackers do, so they can be addressed during design and development rather than after a breach.

## Who created it? When?

Threat modeling has multiple origins. **Microsoft** formalized the practice in the early 2000s with the **STRIDE** model, developed by **Loren Kohnfelder and Praerit Garg** in **1999**. **Adam Shostack** at Microsoft published "Threat Modeling: Designing for Security" in **2014**, which became the standard reference. **MITRE** created the **ATT&CK** framework starting in **2013** to catalog real-world adversary techniques. The **OWASP** community contributed threat modeling methodologies and the Top 10 lists. **Bruce Schneier** introduced attack trees in **1999** as a formal method for describing security threats.

## How it works?

### Process Overview

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ 1. Decompose │───►│ 2. Identify  │───►│ 3. Rank      │───►│ 4. Mitigate  │
│    System    │    │    Threats   │    │    Threats   │    │    Threats   │
│              │    │              │    │              │    │              │
│ - Data flows │    │ - STRIDE     │    │ - DREAD      │    │ - Controls   │
│ - Trust      │    │ - Attack     │    │ - CVSS       │    │ - Accept     │
│   boundaries │    │   trees      │    │ - Risk       │    │ - Transfer   │
│ - Entry      │    │ - Kill       │    │   matrix     │    │ - Avoid      │
│   points     │    │   chains     │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
         │                                                         │
         └─────────────────────────────────────────────────────────┘
                              Iterate
```

### Step 1: Decompose the System

Create a Data Flow Diagram (DFD) that shows:

```
┌─────────┐        ┌─────────────┐        ┌──────────┐
│ External │  HTTP  │             │  SQL   │          │
│ User     │───────►│  Web App    │───────►│ Database │
│          │        │             │        │          │
└─────────┘        └──────┬──────┘        └──────────┘
                          │
                   ═══════╪═══════  Trust Boundary
                          │
                   ┌──────▼──────┐
                   │  Internal   │
                   │  API        │
                   └─────────────┘

Elements:
  □  Process (web app, API, service)
  ═  Data Store (database, file system, cache)
  ○  External Entity (user, third-party service)
  →  Data Flow (HTTP, gRPC, SQL, file I/O)
  ═══ Trust Boundary (network zone, privilege level)
```

Identify:
- All entry points (APIs, UI, file uploads, message queues)
- Trust boundaries (where privilege levels change)
- Data stores (databases, caches, file systems, secrets)
- External dependencies (third-party APIs, CDNs, auth providers)

### Step 2: Identify Threats

Apply a systematic methodology to find threats at each element and data flow.

### Step 3: Rank Threats

Prioritize threats by impact and likelihood. Focus resources on the most critical threats first.

### Step 4: Mitigate

For each threat, choose a response: mitigate (add controls), accept (risk is low enough), transfer (insurance, SLA), or avoid (remove the feature).

## Threat Identification Methodologies

### STRIDE (Microsoft)

Categorizes threats by the type of violation:

```
┌───────────────────────┬──────────────────────────────┬────────────────────────┐
│ Threat                │ Definition                   │ Security Property      │
│                       │                              │ Violated               │
├───────────────────────┼──────────────────────────────┼────────────────────────┤
│ Spoofing              │ Pretending to be someone     │ Authentication         │
│                       │ or something else            │                        │
├───────────────────────┼──────────────────────────────┼────────────────────────┤
│ Tampering             │ Modifying data or code       │ Integrity              │
│                       │ without authorization        │                        │
├───────────────────────┼──────────────────────────────┼────────────────────────┤
│ Repudiation           │ Claiming you did not         │ Non-repudiation        │
│                       │ perform an action            │                        │
├───────────────────────┼──────────────────────────────┼────────────────────────┤
│ Information           │ Exposing data to             │ Confidentiality        │
│ Disclosure            │ unauthorized parties         │                        │
├───────────────────────┼──────────────────────────────┼────────────────────────┤
│ Denial of Service     │ Making the system            │ Availability           │
│                       │ unavailable                  │                        │
├───────────────────────┼──────────────────────────────┼────────────────────────┤
│ Elevation of          │ Gaining privileges           │ Authorization          │
│ Privilege             │ beyond what is granted       │                        │
└───────────────────────┴──────────────────────────────┴────────────────────────┘
```

### Attack Trees (Schneier)

A tree structure where the root is the attacker's goal and leaves are the methods to achieve it.

```
                    Steal User Data
                    /              \
                   /                \
          SQL Injection         Compromise Admin
          /          \          /              \
     Union-based   Blind    Phish Admin     Brute Force
                   SQLi     Credentials     Admin Password
                              |                |
                          Spear phish      Credential
                          with fake        stuffing from
                          SSO page         leaked DB
```

### MITRE ATT&CK

A knowledge base of adversary tactics, techniques, and procedures (TTPs) based on real-world observations.

```
Tactic (WHY)          │ Techniques (HOW)
──────────────────────┼──────────────────────────────────
Initial Access        │ Phishing, exploit public app, supply chain
Execution             │ Command line, scripting, scheduled tasks
Persistence           │ Registry keys, scheduled tasks, implants
Privilege Escalation  │ Exploit vulnerability, token manipulation
Defense Evasion       │ Obfuscation, disable logging, rootkits
Credential Access     │ Keylogging, credential dumping, brute force
Discovery             │ Network scanning, account enumeration
Lateral Movement      │ Pass-the-hash, RDP, SSH hijacking
Collection            │ Screen capture, keylogging, clipboard
Exfiltration          │ Encrypted channel, cloud storage, DNS
Impact                │ Encryption (ransomware), wiper, defacement
```

### PASTA (Process for Attack Simulation and Threat Analysis)

A seven-stage risk-centric methodology:

1. Define objectives
2. Define technical scope
3. Application decomposition
4. Threat analysis
5. Vulnerability analysis
6. Attack modeling
7. Risk and impact analysis

### LINDDUN

Focused specifically on privacy threats:

- **L**inking: connecting data to an individual
- **I**dentifying: learning the identity of a data subject
- **N**on-repudiation: inability to deny an action (privacy violation)
- **D**etecting: noticing a user performed an action
- **D**ata Disclosure: exposing personal data
- **U**nawareness: processing data without user knowledge
- **N**on-compliance: violating data protection regulations

## Risk Scoring

### DREAD (Microsoft, deprecated but still referenced)

```
┌─────────────────────────┬───────────────────────────────────────┐
│ Factor                  │ Score (1-10)                          │
├─────────────────────────┼───────────────────────────────────────┤
│ Damage potential        │ How bad is it if exploited?           │
├─────────────────────────┼───────────────────────────────────────┤
│ Reproducibility         │ How easy to reproduce?                │
├─────────────────────────┼───────────────────────────────────────┤
│ Exploitability          │ How much skill to exploit?            │
├─────────────────────────┼───────────────────────────────────────┤
│ Affected users          │ How many users impacted?              │
├─────────────────────────┼───────────────────────────────────────┤
│ Discoverability         │ How easy to find?                     │
└─────────────────────────┴───────────────────────────────────────┘
Risk = (D + R + E + A + D) / 5
```

### CVSS (Common Vulnerability Scoring System)

Industry standard for scoring vulnerability severity (0.0-10.0). Considers attack vector, complexity, privileges required, user interaction, scope, and impact on confidentiality, integrity, and availability.

```
Score Range    │ Severity
───────────────┼──────────
0.0            │ None
0.1 - 3.9      │ Low
4.0 - 6.9      │ Medium
7.0 - 8.9      │ High
9.0 - 10.0     │ Critical
```

### Risk Matrix

```
              │ Negligible │   Low    │  Medium  │   High   │ Critical │
──────────────┼────────────┼──────────┼──────────┼──────────┼──────────┤
Almost        │   Medium   │   High   │   High   │ Critical │ Critical │
Certain       │            │          │          │          │          │
──────────────┼────────────┼──────────┼──────────┼──────────┼──────────┤
Likely        │    Low     │  Medium  │   High   │   High   │ Critical │
──────────────┼────────────┼──────────┼──────────┼──────────┼──────────┤
Possible      │    Low     │   Low    │  Medium  │   High   │   High   │
──────────────┼────────────┼──────────┼──────────┼──────────┼──────────┤
Unlikely      │ Negligible │   Low    │   Low    │  Medium  │   High   │
──────────────┼────────────┼──────────┼──────────┼──────────┼──────────┤
Rare          │ Negligible │Negligible│   Low    │   Low    │  Medium  │
──────────────┴────────────┴──────────┴──────────┴──────────┴──────────┘
    Likelihood ▲                                    Impact ►
```

## Comparison of Methodologies

```
┌──────────────┬─────────────────┬──────────────┬──────────────────────────┐
│ Methodology  │ Focus           │ Complexity   │ Best For                 │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ STRIDE       │ Threat types    │ Medium       │ Application design phase │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ Attack Trees │ Attack paths    │ Medium       │ Specific asset defense   │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ MITRE ATT&CK │ Real-world TTPs │ High         │ Detection engineering    │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ PASTA        │ Risk-centric    │ High         │ Enterprise risk mgmt     │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ LINDDUN      │ Privacy         │ Medium       │ GDPR/privacy compliance  │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ DREAD        │ Risk scoring    │ Low          │ Quick prioritization     │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ CVSS         │ Vuln severity   │ Medium       │ Vulnerability mgmt       │
├──────────────┼─────────────────┼──────────────┼──────────────────────────┤
│ Kill Chain   │ Attack stages   │ Medium       │ Incident response        │
└──────────────┴─────────────────┴──────────────┴──────────────────────────┘
```

## Pros

- **Proactive Security**: finds vulnerabilities during design, before they reach production
- **Structured Approach**: systematic methodologies ensure comprehensive coverage
- **Cost Effective**: fixing threats in design is 10-100x cheaper than fixing in production
- **Shared Understanding**: creates a common security vocabulary across teams
- **Prioritized Remediation**: risk scoring focuses resources on the highest-impact threats
- **Compliance Support**: threat models satisfy requirements in SOC 2, ISO 27001, PCI-DSS, HIPAA
- **Living Documentation**: threat models document security assumptions and decisions
- **Cross-Functional Engagement**: involves developers, architects, and security together

## Cons

- **Time Intensive**: thorough threat modeling requires significant effort and expertise
- **Requires Security Knowledge**: identifying realistic threats requires adversarial thinking skills
- **Scope Creep**: without discipline, threat modeling can expand to cover improbable scenarios
- **False Sense of Completeness**: a threat model only covers what was considered, novel attacks are missed
- **Stale Models**: threat models become outdated as the system evolves if not maintained
- **Subjectivity**: risk scoring involves judgment calls that can vary between analysts
- **Tooling Gaps**: few tools automate threat modeling effectively, most is manual work
- **Analysis Paralysis**: teams can get stuck debating severity scores instead of fixing issues
- **Hard to Validate**: difficult to measure whether a threat model actually reduced real-world risk

## Use Cases

- **New System Design**: identifying security requirements before writing code
- **Architecture Review**: evaluating security implications of architectural decisions
- **Cloud Migration**: identifying new threats when moving from on-premises to cloud
- **API Design**: finding authentication, authorization, and data exposure risks in API contracts
- **Third-Party Integration**: assessing risk of integrating external services and dependencies
- **Compliance Audits**: demonstrating due diligence in security planning for auditors
- **Incident Post-Mortems**: using threat models to understand what was missed and update defenses
- **Red Team Planning**: using threat models to guide penetration testing and adversary simulation
- **DevSecOps**: integrating threat modeling into CI/CD pipelines with automated checks
- **AI/ML Systems**: identifying threats specific to model poisoning, prompt injection, and data leakage
