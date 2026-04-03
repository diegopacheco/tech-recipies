# mTLS (Mutual TLS)

## What is it?

Mutual TLS (mTLS) is an extension of standard TLS where both the client and the server authenticate each other using X.509 certificates. In regular TLS, only the server presents a certificate to prove its identity — the client verifies the server but the server does not verify the client. In mTLS, the client also presents a certificate, and the server validates it. This creates a two-way authenticated, encrypted connection where both parties cryptographically prove their identity before any data is exchanged.

## Who created it? When?

mTLS is built on top of TLS, which evolved from **SSL** created by **Netscape** in **1994**. The client authentication mechanism has been part of the TLS specification since **TLS 1.0 (RFC 2246, 1999)**. The practice of using mutual certificate authentication for service-to-service communication became widespread with the rise of microservices and service meshes around **2016-2018**. **Google's BeyondCorp** (2014) and **Istio** (2017, Google/Lyft/IBM) popularized mTLS as a default for internal service communication. **SPIFFE** (Secure Production Identity Framework for Everyone) was created in **2017** to standardize workload identity for mTLS at scale.

## How it works?

### Standard TLS vs mTLS

```
Standard TLS (one-way):
┌────────┐                          ┌────────┐
│ Client │───── ClientHello ───────►│ Server │
│        │◄──── ServerHello ────────│        │
│        │◄──── Server Certificate ─│        │
│        │  (client verifies server)│        │
│        │───── Key Exchange ──────►│        │
│        │◄════ Encrypted Channel ══│        │
└────────┘                          └────────┘

mTLS (two-way):
┌────────┐                          ┌────────┐
│ Client │───── ClientHello ───────►│ Server │
│        │◄──── ServerHello ────────│        │
│        │◄──── Server Certificate ─│        │
│        │  (client verifies server)│        │
│        │◄──── CertificateRequest ─│        │
│        │───── Client Certificate ►│        │
│        │  (server verifies client)│        │
│        │───── Key Exchange ──────►│        │
│        │◄════ Encrypted Channel ══│        │
└────────┘                          └────────┘
```

### Handshake Steps (TLS 1.3 with mTLS)

1. **ClientHello**: client sends supported cipher suites, TLS version, and a random value
2. **ServerHello**: server selects cipher suite, sends its random value
3. **Server Certificate**: server sends its X.509 certificate chain
4. **CertificateRequest**: server requests the client's certificate (this is the mTLS addition)
5. **Client Verification**: client validates server certificate against its trusted CA store
6. **Client Certificate**: client sends its X.509 certificate chain
7. **Server Verification**: server validates client certificate against its trusted CA store
8. **Key Exchange**: both parties derive session keys using ECDHE
9. **Encrypted Channel**: all subsequent communication is encrypted and both identities are verified

### Certificate Infrastructure

```
┌──────────────────────────────────────────────┐
│              Root CA                          │
│         (offline, air-gapped)                │
│              │                               │
│     ┌────────┴────────┐                      │
│     ▼                 ▼                      │
│ ┌──────────┐   ┌──────────┐                  │
│ │Intermediate│ │Intermediate│                │
│ │ CA (Infra)│  │ CA (Apps) │                 │
│ └─────┬─────┘  └─────┬─────┘                │
│       │               │                      │
│  ┌────┴────┐    ┌─────┴─────┐                │
│  ▼         ▼    ▼           ▼                │
│ ┌───┐   ┌───┐ ┌───┐     ┌───┐               │
│ │Svc│   │Svc│ │Svc│     │Svc│               │
│ │ A │   │ B │ │ C │     │ D │               │
│ └───┘   └───┘ └───┘     └───┘               │
│                                              │
│ Each service gets its own certificate        │
│ signed by an intermediate CA                 │
└──────────────────────────────────────────────┘
```

### Certificate Fields That Matter

```
Subject:     CN=payment-service.prod.internal
SAN (Subject Alternative Names):
  DNS: payment-service.prod.internal
  DNS: payment-service.prod.svc.cluster.local
  URI: spiffe://cluster.local/ns/prod/sa/payment-service
Issuer:      CN=Internal Apps CA
Valid:       2026-04-03 to 2026-04-04 (short-lived, auto-rotated)
Key Usage:   Digital Signature, Key Encipherment
Ext Key Usage: TLS Client Auth, TLS Server Auth
```

## SPIFFE and SPIRE

### SPIFFE (Secure Production Identity Framework for Everyone)

A standard for identifying workloads in distributed systems. Defines a universal identity format (SPIFFE ID) and a document format (SVID) for presenting that identity.

```
SPIFFE ID format:
  spiffe://trust-domain/path

  spiffe://production.mycompany.com/payments/processor
  spiffe://production.mycompany.com/orders/api
  spiffe://staging.mycompany.com/payments/processor
```

### SPIRE (SPIFFE Runtime Environment)

The reference implementation of SPIFFE. Automatically issues and rotates short-lived X.509 certificates (SVIDs) to workloads.

```
┌─────────────────────────────────────────┐
│              SPIRE Server               │
│  - identity registry                    │
│  - CA (signs SVIDs)                     │
│  - attestation policies                 │
└──────────────┬──────────────────────────┘
               │
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌────────┐ ┌────────┐ ┌────────┐
│ SPIRE  │ │ SPIRE  │ │ SPIRE  │
│ Agent  │ │ Agent  │ │ Agent  │
│(node 1)│ │(node 2)│ │(node 3)│
└───┬────┘ └───┬────┘ └───┬────┘
    │          │          │
┌───▼──┐  ┌───▼──┐  ┌───▼──┐
│Wrkld │  │Wrkld │  │Wrkld │
│  A   │  │  B   │  │  C   │
│(SVID)│  │(SVID)│  │(SVID)│
└──────┘  └──────┘  └──────┘

Workflow:
1. Agent attests node identity (AWS instance ID, K8s node token)
2. Workload requests identity from local agent (Unix socket)
3. Agent attests workload (PID, K8s pod, Docker container)
4. Server issues short-lived SVID (X.509 cert, 1-24 hour TTL)
5. Workload uses SVID for mTLS connections
6. Certificates auto-rotate before expiry
```

## Service Mesh mTLS

### Istio

Istio injects an Envoy sidecar proxy into every pod. The sidecar handles mTLS transparently — application code does not need to manage certificates.

```
┌─────────────────────────────────────────┐
│              Istio Control Plane         │
│  istiod (CA, config, discovery)         │
└──────────────┬──────────────────────────┘
               │ pushes certs
    ┌──────────┼──────────┐
    ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Pod A   │ │ Pod B   │ │ Pod C   │
│┌───────┐│ │┌───────┐│ │┌───────┐│
││ App A ││ ││ App B ││ ││ App C ││
│└───┬───┘│ │└───┬───┘│ │└───┬───┘│
│    │    │ │    │    │ │    │    │
│┌───▼───┐│ │┌───▼───┐│ │┌───▼───┐│
││ Envoy ││ ││ Envoy ││ ││ Envoy ││
││(proxy)│├─┤│(proxy)│├─┤│(proxy)││
│└───────┘│ │└───────┘│ │└───────┘│
└─────────┘ └─────────┘ └─────────┘
     mTLS ◄────────────────► mTLS

App A calls App B on localhost (plaintext)
Envoy A encrypts with mTLS to Envoy B
Envoy B decrypts and forwards to App B on localhost
```

### Linkerd

Similar sidecar approach but uses its own lightweight proxy (linkerd2-proxy, written in Rust). Automatically enables mTLS for all meshed traffic with zero configuration.

### Consul Connect

HashiCorp's service mesh. Uses its own CA or integrates with Vault. Supports both sidecar (Envoy) and native library-based mTLS.

## Comparison

```
┌────────────────────┬───────────────┬───────────────┬───────────────────────┐
│ Approach           │ Cert Mgmt     │ App Changes   │ Best For              │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ Manual certs       │ Manual        │ Yes           │ Small, static infra   │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ cert-manager (K8s) │ Automated     │ Yes           │ K8s native apps       │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ SPIRE              │ Automated     │ Minimal (SDK) │ Multi-platform, any   │
│                    │               │               │ workload              │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ Istio              │ Automated     │ None          │ K8s with full mesh    │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ Linkerd            │ Automated     │ None          │ K8s, lightweight mesh │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ Consul Connect     │ Automated     │ None/Minimal  │ Multi-platform mesh   │
├────────────────────┼───────────────┼───────────────┼───────────────────────┤
│ AWS ACM + ALB      │ AWS managed   │ None          │ AWS-native services   │
└────────────────────┴───────────────┴───────────────┴───────────────────────┘
```

## Pros

- **Strong Identity**: both parties prove identity cryptographically, not via tokens or passwords
- **Encryption in Transit**: all communication is encrypted, preventing eavesdropping and MITM
- **No Shared Secrets**: unlike API keys or tokens, certificates use asymmetric cryptography
- **Automatic with Service Meshes**: Istio, Linkerd, Consul handle mTLS transparently
- **Zero Trust Enabler**: foundational building block for zero trust architectures
- **Fine-Grained Authorization**: certificate identity (SPIFFE ID, CN, SAN) can drive access policies
- **Short-Lived Certificates**: auto-rotated certs reduce the impact of compromise
- **Network-Level Security**: protects against network-level attacks without application changes
- **Replay Protection**: TLS session keys prevent replay attacks

## Cons

- **Certificate Management Complexity**: issuing, rotating, revoking, and distributing certificates at scale is hard
- **CA as Single Point of Failure**: if the CA is compromised, all identities are compromised
- **Debugging Difficulty**: encrypted traffic is harder to inspect for troubleshooting
- **Performance Overhead**: TLS handshake adds latency, especially without session resumption
- **Clock Skew Sensitivity**: certificate validation requires synchronized clocks across all systems
- **Revocation Challenges**: CRL and OCSP have availability and freshness problems, short-lived certs are preferred
- **Sidecar Overhead**: service mesh proxies consume CPU and memory on every pod
- **Non-Mesh Services**: services outside the mesh require separate certificate management
- **Operational Learning Curve**: teams unfamiliar with PKI face a steep learning curve

## Use Cases

- **Microservice-to-Microservice Communication**: authenticating and encrypting all internal service calls
- **Zero Trust Networks**: replacing network-based trust with identity-based trust
- **Kubernetes Service Mesh**: Istio, Linkerd, Consul Connect for automatic mTLS across pods
- **API Gateway Authentication**: clients authenticate to API gateways with client certificates
- **Database Connections**: securing connections to databases (PostgreSQL, MySQL, MongoDB support mTLS)
- **IoT Device Authentication**: devices authenticate to cloud backends with embedded certificates
- **Financial Services**: PCI-DSS and regulatory requirements for encrypted, authenticated communication
- **Multi-Cloud Communication**: securing cross-cloud service calls where network trust is impossible
- **CI/CD Pipeline Security**: build agents authenticate to artifact registries and deployment targets
- **Edge Computing**: authenticating edge nodes to central control planes
