# AWS IAM

## What is IAM?

IAM (Identity and Access Management) is the service that controls **who** can do **what** on **which** AWS resource, and **under which conditions**. It is the front door to every AWS API call. Before any request reaches S3, EC2, DynamoDB, or Lambda, IAM answers a single question: is this specific principal allowed to perform this specific action on this specific resource right now? If the answer is not an explicit allow, the request is denied.

IAM separates two concerns that are easy to conflate. **Authentication** is proving who you are (a credential: a signed request, an access key, a session token). **Authorization** is deciding what an authenticated identity may do (evaluated from policies). IAM does authorization; it leans on credentials and STS for authentication.

IAM is **global** (not region-scoped), **eventually consistent** (a policy change propagates, it is not instantaneous), and **free**. It is also default-deny: an identity with no policies can do nothing.

## Who created it? When?

IAM was launched by **Amazon Web Services** and became **generally available in mid-2011**, growing out of earlier AWS account and access-key mechanisms. The policy language is JSON-based and has been extended continuously since — **roles** (2012), **STS temporary credentials**, **permission boundaries** (2018), **ABAC / tag-based conditions**, and **IAM Access Analyzer** (2019) are all layers added on top of the original allow/deny model.

## Core Concepts

| Concept | What it is |
|---|---|
| Principal | The entity making a request — an IAM user, a role session, an AWS service, a federated identity |
| Root user | The account owner login (email + password). Full power, should be locked away and never used day-to-day |
| IAM User | A long-lived identity for a person or app, with its own credentials (password and/or access keys) |
| Group | A collection of users. Policies attach to the group; membership grants them. Groups cannot be nested and are not principals |
| Role | An identity with **no long-term credentials** that principals *assume* to get temporary credentials. The backbone of secure access |
| Policy | A JSON document listing permissions (allow/deny statements) |
| ARN | Amazon Resource Name — the globally unique id of a resource, e.g. `arn:aws:s3:::my-bucket/*` |
| STS | Security Token Service — issues the short-lived credentials handed out when a role is assumed |

### Policy Types

| Type | Attached to | Purpose |
|---|---|---|
| Identity-based | user / group / role | What this identity can do |
| Resource-based | a resource (S3 bucket, SQS queue, KMS key) | Who (which principal) can touch this resource; includes a `Principal` field |
| Permission boundary | user / role | A ceiling — the max permissions an identity can ever have, even if its policies grant more |
| SCP (Service Control Policy) | an AWS Organizations OU/account | Org-wide guardrail; caps permissions for every principal in the account |
| Session policy | passed at `AssumeRole` time | Further narrows a session's permissions inline |

### Anatomy of a Policy

Every identity-based policy is a JSON document of statements. The five fields that matter:

```
{
  "Version": "2012-10-17",              <- always this date, it is the language version
  "Statement": [
    {
      "Sid": "ReadObjects",             <- optional human label
      "Effect": "Allow",                <- Allow or Deny
      "Action": "s3:GetObject",         <- the API operation(s)
      "Resource": "arn:aws:s3:::bucket/*", <- what it applies to
      "Condition": { ... }              <- optional: when it applies
    }
  ]
}
```

## How authorization is decided

Every request is evaluated against **all** applicable policies (identity, resource, boundary, SCP, session). The logic is a fixed precedence:

```
1. Start from DEFAULT DENY (nothing is allowed).
2. Is there an explicit DENY anywhere that matches?  -> DENY. Stop. (deny always wins)
3. Is there an explicit ALLOW that matches?          -> continue
4. Do the guardrails (SCP, permission boundary,
   session policy) also allow it?                    -> if any is missing -> DENY
5. Otherwise                                          -> ALLOW
```

```
        request
           |
   explicit Deny? --yes--> DENY
           | no
   explicit Allow? --no--> DENY (implicit)
           | yes
   allowed by SCP + boundary + session? --no--> DENY
           | yes
          ALLOW
```

The two rules to internalize: **an explicit `Deny` beats any `Allow`**, and **the absence of an `Allow` is itself a deny**. Permissions are additive across identity policies, then intersected with each guardrail.

---

## 3 Practical Policies

### 1. Read-only access to one S3 bucket

The most common identity policy: let an app list and read one bucket, nothing else. Note that listing the bucket and reading objects need **two different resources** — the bucket ARN and the object ARN (`/*`).

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListTheBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::reports-prod"
    },
    {
      "Sid": "ReadObjects",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::reports-prod/*"
    }
  ]
}
```

### 2. A developers group with scoped DynamoDB access

Attach the policy to a **group** so every developer inherits it and you manage permissions in one place. This grants full item-level access to a single table and its indexes.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DevTableAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": [
        "arn:aws:dynamodb:us-east-1:111122223333:table/Orders",
        "arn:aws:dynamodb:us-east-1:111122223333:table/Orders/index/*"
      ]
    }
  ]
}
```

### 3. An EC2 role that reads from S3 (no keys on the box)

Instead of putting access keys on a server, attach a **role** to the EC2 instance. Two documents are needed: the **trust policy** (who may assume the role — here, the EC2 service) and the **permission policy** (what the role can do once assumed). STS hands the instance rotating temporary credentials automatically.

Trust policy (who can assume it):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Permission policy (what it can do):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::app-assets-prod/*"
    }
  ]
}
```

---

## Complex Functions and Complex Rules

Real access control is rarely "allow action on resource." Four mechanisms turn IAM from a static list into a rule engine:

- **Conditions** — a statement only applies when runtime keys match (source IP, MFA present, time, requested region, resource tags, TLS in use). Conditions use operators (`StringEquals`, `IpAddress`, `Bool`, `DateGreaterThan`, `ForAllValues:*`).
- **Policy variables** — placeholders resolved per request, e.g. `${aws:username}` or `${aws:PrincipalTag/team}`. One policy can serve many identities.
- **ABAC (Attribute-Based Access Control)** — match the principal's tags against the resource's tags, so access scales without writing a new policy per team. This is how large orgs avoid policy sprawl.
- **`NotAction` / `NotResource`** — invert the match ("everything except…"), typically paired with `Deny`.

### One complex policy

This single policy says: *a user may fully manage EC2 instances **only** if the instance's `team` tag equals the user's own `team` tag, **and** the call comes from the corporate network, **and** the session was authenticated with MFA — but they may **never** delete instances tagged `env=prod`, no matter what.*

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ManageOwnTeamInstancesWithGuardrails",
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances",
        "ec2:TerminateInstances"
      ],
      "Resource": "arn:aws:ec2:*:111122223333:instance/*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/team": "${aws:PrincipalTag/team}"
        },
        "IpAddress": {
          "aws:SourceIp": ["203.0.113.0/24", "198.51.100.0/24"]
        },
        "Bool": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    },
    {
      "Sid": "NeverTouchProd",
      "Effect": "Deny",
      "Action": "ec2:TerminateInstances",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/env": "prod"
        }
      }
    }
  ]
}
```

Why each piece matters:

- `${aws:PrincipalTag/team}` is resolved at request time to the caller's own `team` tag, and compared to the instance's `team` tag — one policy correctly scopes every team (ABAC), no per-team copies.
- The `Allow` needs **all three** conditions true at once (conditions within a statement are ANDed): right tag, right network, MFA present. Miss any one and the `Allow` does not match, so the request falls through to the default deny.
- Multiple values in one operator (the two IP ranges) are ORed — either corporate CIDR is accepted.
- The second statement is an explicit `Deny` on production. Because **deny always wins over allow**, even a user whose team owns a prod instance cannot terminate it. This is the correct way to carve out an exception: layer a narrow `Deny` on top of a broad `Allow`.

---

## Best Practices

- **Least privilege** — grant the minimum, widen only when a real access-denied happens. Start from `Deny`, not `*`.
- **Never use the root user** — lock it with a hardware MFA, use it only for the handful of tasks that require it.
- **Roles over long-lived keys** — prefer assumed roles and STS temporary credentials for services, CI, and cross-account access. Rotate anything long-lived.
- **Groups for humans, roles for machines** — attach policies to groups, not individual users.
- **Permission boundaries + SCPs** — set a hard ceiling so a mistaken grant can't escalate beyond the guardrail.
- **Prefer `Condition` over broad `Resource: "*"`** — constrain by tag, region, IP, and MFA.
- **Use IAM Access Analyzer** — it flags resources shared externally and can generate least-privilege policies from CloudTrail history.
- **No wildcards in production `Action`** — avoid `"Action": "*"` and `"s3:*"` on real workloads.

## Pros

- **Fine-grained** — control down to a single action on a single resource under specific conditions
- **Free and global** — no cost, one identity plane across all regions
- **Temporary credentials** — STS-issued short-lived tokens remove the risk of leaked long-term keys
- **Federation** — plug in SAML, OIDC, Google, or AWS Identity Center; no need to mint IAM users per person
- **ABAC scales** — tag-based rules grow with the org without new policies
- **Auditable** — every call is logged in CloudTrail; Access Analyzer reasons about effective access
- **Guardrails** — SCPs and permission boundaries cap blast radius org-wide

## Cons

- **Eventually consistent** — policy changes are not instant; propagation lag can confuse debugging
- **Easy to over-grant** — `*` is tempting and dangerous; least privilege takes discipline
- **Complex evaluation** — allow/deny across identity, resource, boundary, SCP, and session is hard to reason about by hand
- **JSON sprawl** — large environments accumulate hundreds of overlapping policies
- **Silent denies** — an implicit deny gives no reason; troubleshooting needs the IAM Policy Simulator or CloudTrail
- **Region-global mismatch** — IAM is global but resource ARNs are regional, a frequent source of mistakes
- **Quotas** — limits on managed policies per identity, policy size, and inline policy count

## Use Cases

- **Application access** — give a Lambda, EC2, ECS task, or EKS pod a role scoped to exactly the resources it needs
- **Human access** — engineers assume roles (via Identity Center/SSO) instead of holding standing credentials
- **Cross-account access** — a role in account A trusts principals in account B for shared services or centralized logging
- **CI/CD** — pipelines assume a deployment role with OIDC, no stored keys
- **Federated / SSO login** — corporate identity provider federated into AWS
- **Third-party / vendor access** — a role with an `ExternalId` condition lets a SaaS vendor operate in your account safely
- **Guardrails at scale** — SCPs deny whole services or regions across an Organization
- **Break-glass** — a tightly audited, MFA- and alarm-gated emergency role for incidents

## Links

- [AWS IAM User Guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html)
- [IAM policy evaluation logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- [IAM JSON policy elements reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html)
- [Global condition context keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html)
- [IAM security best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Attribute-based access control (ABAC)](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html)
- [Permissions boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
- [Service Control Policies (SCPs)](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [AWS STS — temporary security credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html)
- [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html)
- [IAM Policy Simulator](https://policysim.aws.amazon.com/)
