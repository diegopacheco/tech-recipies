# Secrets Management

## What is it?

Secrets management is the practice of securely storing, accessing, distributing, and rotating sensitive credentials — API keys, database passwords, TLS certificates, encryption keys, tokens, and SSH keys. Instead of hardcoding secrets in source code, config files, or environment variables, a secrets management system provides a centralized, audited, access-controlled vault that applications query at runtime. The goal is to ensure secrets are never exposed in plaintext outside of the moment they are used, and that every access is authenticated, authorized, and logged.

## Why does it matter?

Leaked secrets are one of the most common attack vectors. GitGuardian's 2024 report found over 12.8 million secrets exposed in public GitHub repositories in a single year. A single leaked AWS key can result in cryptomining bills in the hundreds of thousands. A leaked database password gives direct access to customer data. Secrets sprawl — hardcoded in code, stored in .env files, pasted in Slack, embedded in CI configs — creates an unmanageable attack surface.

## How it works?

### Core Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    Secrets Vault                          │
│                                                          │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ Secret Store│  │ Access       │  │ Audit Log      │  │
│  │             │  │ Policies     │  │                │  │
│  │ db/prod/pw  │  │              │  │ who accessed   │  │
│  │ api/stripe  │  │ app-A → read │  │ what, when     │  │
│  │ tls/cert    │  │ app-B → none │  │                │  │
│  │ ssh/deploy  │  │ admin → r/w  │  │ 2026-04-03     │  │
│  └─────────────┘  └──────────────┘  │ app-A read     │  │
│                                     │ db/prod/pw     │  │
│  ┌──────────────────────────────┐   └────────────────┘  │
│  │ Encryption                   │                        │
│  │ - at rest (AES-256-GCM)     │                        │
│  │ - in transit (TLS)          │                        │
│  │ - master key (HSM/KMS)      │                        │
│  └──────────────────────────────┘                        │
└──────────────┬───────────────────────────────────────────┘
               │
    ┌──────────┼──────────────┐
    ▼          ▼              ▼
┌────────┐ ┌────────┐   ┌────────┐
│ App A  │ │ App B  │   │ CI/CD  │
│ (auth) │ │ (auth) │   │ (auth) │
│ reads  │ │ reads  │   │ reads  │
│ secret │ │ secret │   │ secret │
└────────┘ └────────┘   └────────┘
```

### Request Flow

1. Application authenticates to the vault (token, IAM role, K8s service account, mTLS cert)
2. Vault checks access policy — is this identity allowed to read this secret path?
3. If authorized, vault decrypts the secret and returns it over TLS
4. Application uses the secret in memory, never writes it to disk
5. Access is logged with identity, secret path, timestamp, and source IP
6. Secret is rotated automatically on a schedule or triggered rotation

## Secrets Management Solutions

### 1. HashiCorp Vault

The most widely adopted dedicated secrets management system. Supports dynamic secrets, encryption as a service, identity-based access, and pluggable backends.

```
Key Features:
- Dynamic secrets (generates on-demand, time-limited credentials)
- Secret engines: KV, database, AWS, PKI, SSH, transit
- Auth methods: token, AppRole, K8s, AWS IAM, LDAP, OIDC
- Lease-based: every secret has a TTL and is auto-revoked
- Seal/Unseal: master key split via Shamir's secret sharing
- Namespaces: multi-tenant isolation (Enterprise)
- Replication: cross-datacenter replication (Enterprise)

Secret Engines:

┌──────────────────────────────────────────────────────┐
│ KV (v2)     │ Static key-value secrets with          │
│             │ versioning and soft delete              │
├─────────────┼────────────────────────────────────────┤
│ Database    │ Generates temporary DB credentials      │
│             │ (PostgreSQL, MySQL, MongoDB, etc.)      │
├─────────────┼────────────────────────────────────────┤
│ AWS         │ Generates temporary IAM credentials     │
│             │ with scoped policies                    │
├─────────────┼────────────────────────────────────────┤
│ PKI         │ Issues X.509 certificates on demand     │
│             │ (internal CA)                           │
├─────────────┼────────────────────────────────────────┤
│ Transit     │ Encryption as a service (encrypt/       │
│             │ decrypt without exposing keys)          │
├─────────────┼────────────────────────────────────────┤
│ SSH         │ Issues signed SSH certificates or       │
│             │ OTP for SSH access                      │
└─────────────┴────────────────────────────────────────┘
```

### 2. AWS Secrets Manager

AWS-native service. Integrates with RDS, Redshift, and DocumentDB for automatic credential rotation. Supports cross-account and cross-region replication.

- Automatic rotation with Lambda functions
- Native RDS integration (rotates DB passwords automatically)
- Versioning with staging labels (AWSCURRENT, AWSPENDING, AWSPREVIOUS)
- Resource-based policies for cross-account access
- $0.40/secret/month + $0.05/10,000 API calls

### 3. AWS Systems Manager Parameter Store

Simpler, cheaper alternative to Secrets Manager for basic secret storage. Supports SecureString parameters encrypted with KMS.

- Free tier for standard parameters (up to 10,000)
- Hierarchical paths (/prod/db/password, /staging/db/password)
- No built-in rotation (requires custom Lambda)
- Integrates with ECS, Lambda, EC2 via IAM

### 4. Google Cloud Secret Manager

GCP-native solution. Automatic replication, IAM-based access, audit logging via Cloud Audit Logs.

- Automatic replication (regional or multi-regional)
- Version management with enable/disable/destroy states
- IAM integration for access control
- Pub/Sub notifications on secret changes

### 5. Azure Key Vault

Azure-native. Stores secrets, keys, and certificates. HSM-backed key storage available.

- RBAC and access policies for fine-grained control
- HSM-backed keys (FIPS 140-2 Level 2/3)
- Certificate management with auto-renewal
- Soft delete and purge protection

### 6. Kubernetes Secrets

Built-in K8s mechanism. Base64-encoded by default (not encrypted). Should be combined with external solutions for production use.

- Mounted as files or environment variables in pods
- Base64-encoded, not encrypted at rest by default
- Enable etcd encryption at rest for security
- Use External Secrets Operator to sync from Vault, AWS, GCP, Azure

```
External Secrets Operator:

┌────────────┐    sync    ┌──────────────┐    fetch    ┌─────────────┐
│ K8s Secret │◄───────────│ External     │────────────►│ Vault / AWS │
│ (auto-     │            │ Secret       │             │ / GCP / Az  │
│  created)  │            │ Operator     │             │             │
└────────────┘            └──────────────┘             └─────────────┘
```

## Secret Types and Rotation Strategies

```
┌──────────────────┬──────────────────┬────────────────────────────────┐
│ Secret Type      │ Rotation Period  │ Strategy                       │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ Database         │ 24-72 hours      │ Dynamic secrets (Vault) or     │
│ passwords        │                  │ dual-credential rotation       │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ API keys         │ 30-90 days       │ Issue new key, update          │
│                  │                  │ consumers, revoke old key      │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ TLS certificates │ 90 days or less  │ Auto-renewal via cert-manager, │
│                  │                  │ Vault PKI, or Let's Encrypt    │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ SSH keys         │ Per session      │ Signed SSH certs via Vault     │
│                  │                  │ (minutes to hours TTL)         │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ Encryption keys  │ Annually         │ Key versioning, re-encryption  │
│                  │                  │ of data with new key version   │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ OAuth tokens     │ Minutes-hours    │ Refresh token flow,            │
│                  │                  │ auto-renewal                   │
├──────────────────┼──────────────────┼────────────────────────────────┤
│ Cloud IAM creds  │ Per request      │ Assume role, instance          │
│                  │                  │ profiles, workload identity    │
└──────────────────┴──────────────────┴────────────────────────────────┘
```

## Anti-Patterns

### 1. Secrets in Source Code

Hardcoded passwords, API keys, or connection strings in application code committed to version control. Even if removed later, they persist in git history.

### 2. Secrets in Environment Variables

Better than hardcoding but still problematic. Environment variables are visible in process listings, crash dumps, debug logs, and container inspection. They do not support rotation, auditing, or access control.

### 3. Secrets in CI/CD Config Files

Encrypted secrets in .travis.yml, GitHub Actions secrets without rotation policies, Jenkins credentials stored in XML. These are better than plaintext but still lack proper lifecycle management.

### 4. Shared Service Accounts

Multiple applications sharing the same database password or API key. Impossible to audit which application accessed what, and revoking the key breaks all consumers.

### 5. Long-Lived Credentials

API keys or database passwords that never expire. A leaked long-lived credential provides permanent access until manually discovered and rotated.

## Comparison

```
┌──────────────────┬──────────┬───────────┬──────────┬───────────┬───────────┐
│ Feature          │ Vault    │ AWS SM    │ GCP SM   │ Azure KV  │ K8s       │
│                  │          │           │          │           │ Secrets   │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Dynamic Secrets  │ Yes      │ Rotation  │ No       │ No        │ No        │
│                  │          │ only      │          │           │           │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Auto Rotation    │ Yes      │ Yes       │ Manual   │ Yes       │ No        │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Audit Logging    │ Yes      │ CloudTrail│ Cloud    │ Yes       │ K8s audit │
│                  │          │           │ Audit    │           │ logs      │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Encryption       │ AES-256  │ KMS       │ KMS      │ HSM/KMS   │ etcd      │
│                  │ + Shamir │           │          │           │ (opt-in)  │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Multi-Cloud      │ Yes      │ AWS only  │ GCP only │ Azure only│ K8s only  │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Self-Hosted      │ Yes      │ No        │ No       │ No        │ Yes       │
├──────────────────┼──────────┼───────────┼──────────┼───────────┼───────────┤
│ Cost             │ Free/Ent │ Per-secret│ Per-op   │ Per-op    │ Free      │
└──────────────────┴──────────┴───────────┴──────────┴───────────┴───────────┘
```

## Pros

- **Eliminates Secret Sprawl**: centralized store replaces secrets scattered across code, configs, and CI/CD
- **Audit Trail**: every secret access is logged with identity, timestamp, and context
- **Automated Rotation**: reduces the window of exposure for compromised credentials
- **Dynamic Secrets**: on-demand, short-lived credentials minimize standing access
- **Access Control**: fine-grained policies control which applications can read which secrets
- **Encryption at Rest**: secrets are encrypted in storage, not stored as plaintext
- **Revocation**: compromised secrets can be revoked instantly from a single location
- **Compliance**: audit logs and access controls satisfy SOC 2, PCI-DSS, HIPAA requirements
- **Multi-Environment**: same system manages dev, staging, and production secrets with isolation

## Cons

- **Operational Complexity**: running and maintaining a secrets vault (especially Vault) requires expertise
- **Availability Dependency**: if the vault is down, applications cannot retrieve secrets
- **Bootstrapping Problem**: the first secret (how does the app authenticate to the vault?) requires careful design
- **Migration Effort**: moving from hardcoded secrets to a vault across many services is time-consuming
- **Cost**: managed services charge per secret and per API call, costs scale with usage
- **Latency**: fetching secrets over the network adds latency compared to local config files
- **Key Management**: the vault's master key / root key must itself be securely managed (turtles all the way down)
- **Team Adoption**: developers must learn new patterns for accessing secrets
- **Over-Engineering Risk**: simple applications with few secrets may not need a full vault

## Use Cases

- **Microservices**: each service authenticates to the vault and retrieves its database credentials, API keys, and certificates
- **CI/CD Pipelines**: build and deployment pipelines retrieve deployment keys, cloud credentials, and signing keys at runtime
- **Database Credential Rotation**: automatic rotation of database passwords without application downtime
- **TLS Certificate Management**: issuing and renewing internal TLS certificates via Vault PKI or cert-manager
- **Multi-Cloud Deployments**: centralized secret management across AWS, GCP, and Azure
- **Kubernetes Workloads**: External Secrets Operator syncing secrets from Vault or cloud providers into K8s
- **Encryption as a Service**: applications call Vault Transit to encrypt/decrypt data without managing keys
- **SSH Access Management**: issuing short-lived SSH certificates instead of distributing SSH keys
- **Compliance and Audit**: demonstrating secret access controls and rotation for auditors
- **Incident Response**: rapidly revoking and rotating all secrets of a compromised service
