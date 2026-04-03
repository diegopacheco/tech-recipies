# Zero Trust

## What is it?

Zero Trust is a security model based on the principle "never trust, always verify." It eliminates the concept of a trusted internal network perimeter. Every request — whether from inside or outside the network — must be authenticated, authorized, and continuously validated before access is granted. Trust is never implicit based on network location, device, or prior authentication. Every access decision is made dynamically based on identity, context, device health, and risk signals.

## Who created it? When?

The term "Zero Trust" was coined by **John Kindervag** at **Forrester Research** in **2010** in his paper "No More Chewy Centers: Introducing the Zero Trust Model of Information Security." The concept built on earlier work by the **Jericho Forum (2004)** which advocated for de-perimeterization. **Google** popularized the approach with their **BeyondCorp** initiative starting in **2011**, which was published in a series of papers from 2014 to 2017. In 2020, **NIST** formalized the architecture in **SP 800-207 "Zero Trust Architecture."**

## How it works?

### Core Principles

1. **Verify Explicitly**: authenticate and authorize every request based on all available data points (identity, location, device, service, data classification, anomalies)
2. **Least Privilege Access**: limit access to only what is needed, for only as long as needed, using just-in-time and just-enough-access (JIT/JEA)
3. **Assume Breach**: design systems assuming attackers are already inside the network, minimize blast radius, segment access, verify end-to-end encryption, use analytics to detect threats

### Architecture

```
                         ┌───────────────────────┐
                         │    Policy Engine       │
                         │  (decision point)      │
                         │  - identity context    │
                         │  - device posture      │
                         │  - risk score          │
                         │  - data classification │
                         └──────────┬────────────┘
                                    │
                                    │ allow/deny
                                    │
┌──────────┐    request     ┌───────▼──────────┐      ┌──────────────┐
│  Subject  │──────────────►│  Policy          │─────►│  Resource    │
│ (user,    │               │  Enforcement     │      │  (app, data, │
│  device,  │◄──────────────│  Point (PEP)     │◄─────│   service)   │
│  service) │   response    └──────────────────┘      └──────────────┘
└──────────┘                        │
                                    │
                         ┌──────────▼────────────┐
                         │   Continuous          │
                         │   Monitoring          │
                         │  - behavior analytics │
                         │  - session risk       │
                         │  - threat intelligence│
                         └───────────────────────┘
```

### Request Flow

1. Subject (user, device, or service) initiates a request to access a resource
2. Request is intercepted by the Policy Enforcement Point (PEP)
3. PEP sends context to the Policy Engine (identity, device health, location, time, behavior)
4. Policy Engine evaluates the request against policies and risk signals
5. Access is granted with minimum required privileges or denied
6. Session is continuously monitored and can be revoked in real time if risk changes

### Key Components

**Identity Provider (IdP)**: authenticates users and services, issues tokens, manages credentials. Supports MFA, passwordless, certificate-based auth.

**Device Trust**: evaluates device posture (OS patched, disk encrypted, EDR running, compliant with policy). Untrusted devices get restricted access or no access.

**Micro-Segmentation**: network is divided into small zones. Each workload-to-workload communication requires explicit authorization. No lateral movement by default.

**Software Defined Perimeter (SDP)**: creates one-to-one network connections between user and resource. Resources are invisible to unauthorized users (dark cloud).

**Continuous Authentication**: session risk is re-evaluated continuously, not just at login. Changes in behavior, location, or device state can trigger step-up auth or session termination.

## Implementation Approaches

### 1. BeyondCorp (Google)

Google's implementation after the 2009 Operation Aurora attack. Moved access controls from the network perimeter to individual users and devices. All Google employees access internal applications through an identity-aware proxy without a VPN.

- Access proxy authenticates every request
- Device inventory tracks every device's trust level
- Access control engine makes per-request decisions
- No privileged network segments

### 2. NIST SP 800-207

The formal reference architecture with three deployment approaches:

- **Enhanced Identity Governance**: uses identity as the primary policy component
- **Micro-Segmentation**: uses network segmentation as the primary control
- **Software Defined Perimeters**: uses overlay networks and proxy-based access

### 3. SASE (Secure Access Service Edge)

Converges networking (SD-WAN) and security (CASB, FWaaS, ZTNA) into a cloud-delivered service. Applies zero trust principles at the network edge.

- Cloud-native architecture
- Identity-driven access
- Per-session trust evaluation
- Global points of presence

### 4. Zero Trust Network Access (ZTNA)

Replaces VPN with per-application tunnels. Users only see and access applications they are authorized for. The network itself is never exposed.

- Application-level access, not network-level
- Broker-based or agent-based models
- Invisible infrastructure (resources hidden until authorized)

## Comparison with Traditional Security

```
┌───────────────────────┬─────────────────────────┬─────────────────────────┐
│ Aspect                │ Perimeter Security      │ Zero Trust              │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Trust model           │ Trust inside, block     │ Trust nothing, verify   │
│                       │ outside                 │ everything              │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Network assumption    │ Internal = safe         │ All networks hostile    │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Access control        │ VPN + firewall          │ Identity + context +    │
│                       │                         │ per-request             │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Lateral movement      │ Easy once inside        │ Blocked by default      │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Authentication        │ Once at VPN login       │ Continuous              │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Segmentation          │ Broad network zones     │ Micro-segmentation      │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Remote access         │ VPN required            │ Native, no VPN needed   │
├───────────────────────┼─────────────────────────┼─────────────────────────┤
│ Breach impact         │ Entire network exposed  │ Single resource scoped  │
└───────────────────────┴─────────────────────────┴─────────────────────────┘
```

## Pros

- **Reduced Blast Radius**: a compromised credential or device cannot move laterally across the network
- **Works Anywhere**: same security model whether users are in the office, at home, or on mobile
- **Eliminates VPN**: no more VPN bottlenecks, split tunneling issues, or VPN credential theft
- **Granular Access Control**: per-resource, per-session, per-user access decisions
- **Better Visibility**: every access request is logged and evaluated, improving audit and forensics
- **Insider Threat Mitigation**: internal users face the same verification as external users
- **Cloud Native**: designed for modern cloud, multi-cloud, and hybrid environments
- **Continuous Verification**: risk is re-evaluated throughout the session, not just at login
- **Compliance Friendly**: detailed access logs and policy enforcement simplify regulatory compliance

## Cons

- **Implementation Complexity**: requires overhauling identity, network, and access systems simultaneously
- **Legacy System Challenges**: older applications may not support modern authentication and authorization protocols
- **User Friction**: continuous verification can slow down workflows if not implemented carefully
- **High Upfront Cost**: requires investment in identity infrastructure, device management, and monitoring tools
- **Cultural Resistance**: organizations used to "trusted network" mindset resist the change
- **Policy Explosion**: fine-grained policies for every resource can become difficult to manage at scale
- **Performance Overhead**: per-request policy evaluation adds latency if not optimized
- **Dependency on Identity Provider**: IdP becomes a critical single point of failure
- **Incomplete Adoption Risk**: partial zero trust (only some apps, some users) gives false confidence

## Use Cases

- **Remote Workforce**: securing access for distributed employees without VPN infrastructure
- **Cloud Migration**: protecting workloads across AWS, GCP, Azure without relying on network perimeters
- **Multi-Cloud Environments**: consistent security policy across multiple cloud providers
- **Mergers and Acquisitions**: integrating networks without extending implicit trust
- **Contractor and Third-Party Access**: granting limited, audited access to external partners
- **Regulated Industries**: healthcare, finance, government where audit trails and least privilege are mandated
- **Micro-Services Architectures**: service-to-service authentication and authorization (mTLS, SPIFFE/SPIRE)
- **IoT and OT Networks**: securing devices that cannot run traditional agents
- **Preventing Lateral Movement**: containing attackers who breach a single endpoint
- **Supply Chain Security**: verifying every component and connection in the software delivery pipeline
