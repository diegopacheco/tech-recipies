# AWS Identity and Access Management (IAM)

## What is it?

AWS Identity and Access Management (IAM) is the service that controls **who** can do **what** on **which** AWS resources, **under which conditions**. Every request to an AWS API is authenticated to a principal and then authorized by evaluating the policies that apply to that principal, the target resource, and the surrounding context. If no policy allows the action, the request is denied; if any policy explicitly denies it, the request is denied regardless of any allow.

IAM separates **identities** from **permissions**. Identities are users, groups, roles, and the AWS account root. Permissions are JSON policy documents attached to those identities or to resources. A **role** is the central construct for good practice: it is an identity with no long-lived credentials that a trusted principal assumes to receive short-lived, automatically rotated credentials for a bounded session.

IAM is a **global** service, not regional. It is the authorization boundary for almost every other AWS service, so an IAM mistake is rarely local: an over-broad policy can expose storage, compute, networking, and billing at once.

## Who created it? When?

IAM is an Amazon Web Services product. AWS launched its first public services in **2006** (S3 and EC2), where access was controlled by account-level access keys. **IAM became generally available in 2011**, introducing users, groups, and policies so an account no longer had to share one set of root credentials.

Key milestones followed: **roles for EC2** instance profiles, **cross-account roles**, **identity federation** through SAML and OpenID Connect, **IAM Roles Anywhere** for workloads outside AWS, and **IAM Identity Center** (formerly AWS SSO) for workforce access across many accounts. Guardrail and analysis tooling arrived over time: **Service Control Policies** in AWS Organizations, **permissions boundaries**, **IAM Access Analyzer**, and **last-accessed** data for right-sizing permissions. The direction of travel has been consistent: away from long-lived keys and toward short-lived, federated, least-privilege credentials.

## Core Identities

```
┌──────────────────┬───────────────────────────────────────────────────┐
│ Root user        │ the account owner; unrestricted; use almost never │
├──────────────────┼───────────────────────────────────────────────────┤
│ IAM user         │ long-lived identity with password and/or access   │
│                  │ keys; avoid for humans and workloads              │
├──────────────────┼───────────────────────────────────────────────────┤
│ IAM group        │ a collection of users sharing attached policies;  │
│                  │ not a principal, cannot be assumed                │
├──────────────────┼───────────────────────────────────────────────────┤
│ IAM role         │ identity with no static credentials; assumed to   │
│                  │ get temporary credentials via STS                 │
├──────────────────┼───────────────────────────────────────────────────┤
│ Federated user   │ external identity (SAML, OIDC, Identity Center)   │
│                  │ mapped to a role at sign-in                        │
└──────────────────┴───────────────────────────────────────────────────┘
```

The root user is created with the account and can do anything, including closing the account and changing billing. Secure it with a strong password and hardware MFA, remove its access keys, and use it only for the few tasks that require it. Prefer roles and federation over IAM users so credentials are short-lived and centrally managed.

## Policy Types Compared

```
┌────────────────────────┬──────────────────┬─────────────────────────┐
│ Policy type            │ Attached to      │ Effect                  │
├────────────────────────┼──────────────────┼─────────────────────────┤
│ Identity-based         │ user, group,     │ grants permissions to   │
│                        │ role             │ that identity           │
├────────────────────────┼──────────────────┼─────────────────────────┤
│ Resource-based         │ a resource       │ grants access to named  │
│                        │ (S3, KMS, SQS…)  │ principals; enables     │
│                        │                  │ cross-account access    │
├────────────────────────┼──────────────────┼─────────────────────────┤
│ Permissions boundary   │ user or role     │ caps the maximum        │
│                        │                  │ permissions, never adds │
├────────────────────────┼──────────────────┼─────────────────────────┤
│ Service Control Policy  │ Organizations   │ caps permissions for    │
│                        │ account/OU       │ every principal in the  │
│                        │                  │ account, root included  │
├────────────────────────┼──────────────────┼─────────────────────────┤
│ Session policy         │ passed at        │ narrows a session's     │
│                        │ AssumeRole time  │ permissions inline      │
├────────────────────────┼──────────────────┼─────────────────────────┤
│ Trust policy           │ a role           │ defines who may assume  │
│                        │                  │ the role                │
└────────────────────────┴──────────────────┴─────────────────────────┘
```

Boundaries, SCPs, and session policies **restrict**; they never grant on their own. A principal's effective permissions are the intersection of what is granted and what every applicable guardrail allows, minus any explicit deny.

## Policy Document Structure

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadOneBucketPrefix",
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::reports-bucket/team-a/*",
      "Condition": {
        "StringEquals": { "aws:PrincipalTag/team": "a" },
        "Bool": { "aws:SecureTransport": "true" }
      }
    }
  ]
}
```

A statement is `Effect` (Allow or Deny) over `Action` on `Resource`, optionally gated by `Condition`. Conditions turn coarse grants into precise ones: they can require encryption in transit, restrict a source VPC or IP range, match resource and principal tags for attribute-based access control, or bound the request to a specific organization with `aws:PrincipalOrgID`. Prefer specific resource ARNs and conditions over wildcards.

## How it works?

### Policy Evaluation Order

```
request (principal, action, resource, context)
   │
   ▼
explicit Deny anywhere?  ── yes ─────────────► DENY
   │ no
   ▼
SCP / boundary / session allow the action? ── no ─► DENY (implicit)
   │ yes
   ▼
identity-based or resource-based Allow? ── no ───► DENY (implicit default)
   │ yes
   ▼
                                                   ALLOW
```

Evaluation is deny-by-default. AWS gathers every applicable policy, and a single explicit `Deny` wins over any number of allows. For access to succeed, an allow must exist **and** survive every guardrail (SCP, permissions boundary, session policy). Cross-account access additionally requires both sides to allow it: the resource policy in the owning account and an identity policy in the caller's account.

### Assuming a Role

```
Principal            AWS STS                 Target account/role
 │                      │                            │
 │ AssumeRole(roleArn)  │                            │
 │─────────────────────►│ check role trust policy    │
 │                      │───────────────────────────►│
 │                      │ trust allows this principal│
 │                      │◄───────────────────────────│
 │ temp credentials     │ issue short-lived key,     │
 │ (key, secret, token) │ secret, session token      │
 │◄─────────────────────│                            │
 │ call APIs with       │                            │
 │ session credentials  │                            │
```

The Security Token Service (STS) issues temporary credentials after checking the role's **trust policy**, which names who may assume it. Sessions expire (commonly 1 hour, up to 12), so leaked credentials have a short blast radius. This is how EC2 instance profiles, Lambda execution roles, ECS task roles, and cross-account access all work under the hood.

### Federation and Workload Identity

```
Workload / user          Identity provider        AWS STS
 │                            │                       │
 │ authenticate              │                       │
 │──────────────────────────►│ issue OIDC/SAML token │
 │◄──────────────────────────│                       │
 │ AssumeRoleWithWebIdentity / AssumeRoleWithSAML     │
 │───────────────────────────────────────────────────►│
 │                            │ validate token,       │
 │                            │ match role trust      │
 │ temporary AWS credentials  │                       │
 │◄───────────────────────────────────────────────────│
```

External identities never get IAM users. A trusted provider authenticates them, and STS exchanges the provider's token for a role session. This covers GitHub Actions and Kubernetes via OIDC, corporate SSO via SAML or IAM Identity Center, and non-AWS servers via IAM Roles Anywhere with X.509 certificates. The trust policy pins the provider and constrains claims (repository, subject, audience) so only the intended workload can assume the role.

## Permission Guardrails

```
┌──────────────────────┬──────────────────────────────────────────────┐
│ SCP                  │ organization-wide ceiling; even root in a    │
│                      │ member account cannot exceed it              │
├──────────────────────┼──────────────────────────────────────────────┤
│ Permissions boundary │ per-identity ceiling; a delegated admin can  │
│                      │ create roles only within this cap            │
├──────────────────────┼──────────────────────────────────────────────┤
│ Session policy       │ per-session narrowing at AssumeRole time     │
├──────────────────────┼──────────────────────────────────────────────┤
│ Identity/resource    │ the actual grants that must survive every    │
│ policy               │ ceiling above                                │
└──────────────────────┴──────────────────────────────────────────────┘
```

Guardrails let a central team delegate safely. A platform team sets SCPs and boundaries; application teams manage their own roles inside those limits and cannot escalate beyond them. This is how large organizations grant autonomy without granting account takeover.

## Attacks and Defenses

- **Leaked long-lived access keys**: keys committed to code, logs, or laptops grant durable access; replace users with roles, use short-lived credentials, scan repositories, and rotate or disable keys promptly
- **Privilege escalation via `iam:*`**: a principal allowed to edit policies, attach admin policies, or create keys can grant itself anything; withhold IAM-mutating actions and constrain them with permissions boundaries
- **`PassRole` abuse**: a caller passes a powerful role to a service it controls; scope `iam:PassRole` to specific role ARNs and restrict the target service with conditions
- **Over-broad trust policies**: a role trusting `"AWS": "*"` or an entire account can be assumed by unintended principals; pin exact principals, external IDs, and OIDC claims
- **Confused-deputy across accounts**: a third party assumes a role on your behalf without proof it acts for you; require a unique `sts:ExternalId` or `aws:SourceArn`/`aws:SourceAccount` conditions
- **Wildcard resource policies**: an S3 bucket or KMS key open to `Principal: "*"` exposes data publicly; use Access Analyzer, Block Public Access, and `aws:PrincipalOrgID` conditions
- **Token theft from metadata service**: SSRF against IMDSv1 steals instance role credentials; enforce IMDSv2, limit hop count, and scope instance roles tightly
- **Root account misuse**: root bypasses IAM policies within its account; enable hardware MFA, remove root keys, and monitor root sign-in with alerts
- **Permission creep**: unused grants accumulate silently; use last-accessed data and Access Analyzer to remove what is never exercised
- **Federation misconfiguration**: a loose OIDC subject match lets any repository or workload assume a role; pin `sub`, `aud`, and repository conditions exactly

## Anti-Patterns

- Using the root user for daily operations or automation
- Creating IAM users with long-lived access keys for humans or CI instead of roles and federation
- Attaching `AdministratorAccess` or `Action: "*"` when a narrow policy would do
- Trust policies that allow an entire account or `*` to assume a role
- Granting `iam:PassRole` on `Resource: "*"`
- Embedding access keys in code, container images, environment files, or user data
- Sharing one role across unrelated workloads so blast radius and audit trail blur
- Relying only on identity policies while leaving resource policies public
- Skipping SCPs and permissions boundaries in a multi-account organization
- Treating MFA as optional for privileged principals
- Never reviewing last-accessed data, so unused permissions live forever

## Pros

- **Fine-grained control**: actions, resources, and conditions express precise least-privilege intent
- **Short-lived credentials by default**: roles and STS remove the need to store and rotate long-lived keys
- **Federation-first**: SAML, OIDC, and Identity Center let existing corporate and workload identities map to AWS roles
- **Organization-wide guardrails**: SCPs and permissions boundaries cap permissions even for account admins
- **Attribute-based access**: tags on principals and resources scale permissions without exploding policy counts
- **Strong analysis tooling**: Access Analyzer, last-accessed data, and policy simulation help right-size and validate access
- **No additional cost**: IAM itself is free and integrated into every AWS service

## Cons

- **Steep evaluation model**: the interaction of identity, resource, boundary, SCP, and session policies is hard to reason about
- **Easy to over-grant**: wildcards are convenient, and least privilege takes deliberate effort
- **Global blast radius**: one broad policy can expose many services and regions at once
- **Legacy long-lived keys**: IAM users and access keys still exist and remain a leading source of compromise
- **PassRole and escalation traps**: subtle permissions can chain into full account takeover
- **Multi-account complexity**: organizations, SCPs, and cross-account trust require disciplined design
- **Cross-account debugging pain**: a denial can originate in either account's policy, complicating diagnosis

## Use Cases

- Workforce sign-in to many accounts through IAM Identity Center with role-based permission sets
- EC2, Lambda, ECS, and EKS workloads receiving scoped roles instead of stored keys
- CI/CD pipelines (GitHub Actions, GitLab) assuming roles via OIDC with no static secrets
- Cross-account access for shared services, logging, and security tooling with pinned trust
- On-premises and other-cloud servers using IAM Roles Anywhere with certificates
- Attribute-based access control using principal and resource tags for multi-tenant isolation
- Central guardrails via SCPs and permissions boundaries so teams self-serve safely
- Continuous least-privilege review with Access Analyzer and last-accessed reporting

## Links

- AWS IAM User Guide: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html
- IAM Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html
- Policy Evaluation Logic: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- AWS STS API Reference: https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html
- IAM Roles Anywhere: https://docs.aws.amazon.com/rolesanywhere/latest/userguide/introduction.html
- AWS IAM Identity Center: https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html
- Service Control Policies: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html
- Permissions Boundaries: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html
- IAM Access Analyzer: https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html
- Confused Deputy Prevention: https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html
- Companion note — Multi-Factor Authentication: mfa.md
- Companion note — Single Sign-On: sso.md
- Companion note — RBAC and ABAC: rbac-abac.md
