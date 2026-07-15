# CLI vs MCP: The Authorization Perspective

## What is it?

An agent that needs to touch a real system has two ways to get there. It can **shell out to a CLI** (`gh`, `aws`, `kubectl`, `psql`) or it can **call an MCP server** over a tool protocol. The choice looks like ergonomics — which one is easier to wire up — but it is first an authorization decision, and the two surfaces have opposite defaults.

A CLI runs with **ambient authority**. The credential already exists on the machine: a file in `~/.aws/credentials`, a `$GITHUB_TOKEN` in the environment, a kubeconfig, a keychain entry. Any process that can read it wields the whole principal. The remote service authenticates the credential and learns *which principal*, never *who invoked it*.

MCP over HTTP runs with **delegated authority**. The client obtains an access token through OAuth 2.1 against an authorization server, bound to a specific user, a specific client, a specific audience, a specific scope set, and a specific expiry. The remote service can distinguish the human from the software acting for them.

The precise gap is not that the CLI lacks authentication. SigV4 and mTLS are strong. The CLI lacks **delegation**: one credential, many possible callers, no per-call narrowing, and no moment where anyone consented to *this* caller having *this* authority.

## Who created it? When?

Command-line credential handling is an accretion, not a design. The conventions in use today — an API key in an environment variable, a long-lived secret in a dotfile, a token in the shell's history — predate any agent that would run them unattended. `~/.aws/credentials` was designed for a human at a terminal who is the only thing on the box.

**Model Context Protocol** was open-sourced by **Anthropic on November 25, 2024**. The original specification had no authorization story at all; it assumed a local `stdio` process. Authorization arrived and then changed shape three times:

- **2025-03-26** added an OAuth 2.1 framework for HTTP transports, but made the MCP server both authorization server and resource server. This was widely criticized: every MCP server author was suddenly expected to implement an OAuth AS correctly.
- **2025-06-18** fixed the role confusion. The MCP server became a plain **OAuth 2.1 Resource Server**; the authorization server is explicitly out of scope and may be a separate entity. This revision made **RFC 9728** Protected Resource Metadata mandatory for servers, **RFC 8707** Resource Indicators mandatory for clients, and **forbade token passthrough** outright.
- **2025-11-25** is the current revision. It adds **Client ID Metadata Documents** (`draft-ietf-oauth-client-id-metadata-document-00`), where a client's `client_id` is an HTTPS URL that the authorization server fetches, plus step-up authorization via `insufficient_scope` challenges.

The direction of travel is clear: MCP keeps moving authorization *out* of the server and onto standard OAuth infrastructure. That is the right direction, and it is also why the guarantees are newer and thinner than the RFC numbers suggest.

## The Core Asymmetry

```
CLI                                    MCP (HTTP transport)

  agent                                  agent
    │                                      │
    │ execve("aws s3 rm ...")              │ tools/call {name, args}
    ▼                                      ▼
  process inherits env                   client holds access token
    │  AWS_ACCESS_KEY_ID                   │  sub    = the human
    │  (or ~/.aws/credentials)             │  azp    = which client
    │                                      │  aud    = which resource
    │  one principal                       │  scope  = which operations
    │  no caller, no scope, no exp         │  exp    = a deadline
    ▼                                      ▼
  API sees: "user/diego"                 API sees: "client X, for user Y,
             (or role/ci-deploy)                    scoped to Z, until T"
```

The CLI credential answers one question: *what principal is this?* The OAuth token answers five. That is the whole argument in one picture — and every honest caveat below is about how often the MCP column silently collapses back into the CLI column.

## Identity Models Compared

```
┌────────────────────┬──────────────────────┬──────────────────────┐
│ Property           │ CLI                  │ MCP over HTTP        │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Credential source  │ Ambient: env, file,  │ OAuth 2.1 flow with  │
│                    │ keychain, IMDS       │ PKCE, per client     │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Who is calling     │ Unknowable. Any      │ Token carries client │
│                    │ process with read    │ id and subject       │
│                    │ access is the user   │                      │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Consent moment     │ None                 │ Once, at connect     │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Audience binding   │ None. Cred works at  │ RFC 8707 resource    │
│                    │ every endpoint       │ param, aud validated │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Scoping            │ Whatever the         │ OAuth scopes, with   │
│                    │ principal can do     │ step-up challenges   │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Expiry             │ Often never (static  │ Token lifetime, with │
│                    │ keys); STS is opt-in │ refresh              │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Revocation         │ Rotate the key, or   │ Revoke at the AS,    │
│                    │ delete the principal │ immediate            │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Model-visible text │ Nothing injected     │ Tool descriptions —  │
│                    │                      │ an injection surface │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Supply chain       │ Pinned, signed       │ Often npx/uvx, fetch │
│                    │ package, versioned   │ latest at every run  │
├────────────────────┼──────────────────────┼──────────────────────┤
│ Maturity           │ Decades of hardening │ Spec is months old   │
└────────────────────┴──────────────────────┴──────────────────────┘
```

## How it works?

### CLI: Ambient Credentials

The AWS CLI resolves credentials through a chain: environment variables, then `~/.aws/credentials` and the SSO cache, then the EC2 instance metadata service. Nothing in that chain asks who is calling. It asks what is reachable.

```
agent ──execve──► aws sts get-caller-identity
                      │
                      ├─ reads $AWS_ACCESS_KEY_ID or ~/.aws/credentials
                      ├─ signs request with SigV4
                      ▼
                  AWS STS
                      │
                      └─► { "Arn": "arn:aws:iam::123:user/diego" }
```

`get-caller-identity` returns the *principal*, not the caller. The same answer comes back whether Diego typed it, a cron job ran it, an agent invoked it, or malware in a postinstall script read the file. The credential is the identity, and the credential is a file.

This is the confused deputy in its plainest form. The CLI is a deputy holding authority it did not earn and cannot attribute.

### MCP: OAuth 2.1 Resource Server

```
┌────────┐  1. tools/call (no token)   ┌────────────┐
│ Client │────────────────────────────►│ MCP server │
│        │◄────────────────────────────│ (RS)       │
└───┬────┘  2. 401 + WWW-Authenticate  └────────────┘
    │          resource_metadata=...
    │
    │ 3. GET /.well-known/oauth-protected-resource   (RFC 9728)
    │    ◄── { authorization_servers: [...], scopes_supported: [...] }
    │
    │ 4. GET /.well-known/oauth-authorization-server (RFC 8414)
    ▼
┌──────────────────┐
│ Authorization    │  5. authorize + PKCE + resource=https://mcp.example
│ server           │     user consents
│                  │  6. token, aud-bound to the MCP server
└──────┬───────────┘
       │
       ▼
┌────────┐  7. tools/call + Bearer     ┌────────────┐
│ Client │────────────────────────────►│ MCP server │
└────────┘                             │ validates  │
                                       │ aud, scope │
                                       └────────────┘
```

The normative requirements that matter for authorization:

1. MCP servers **MUST** implement RFC 9728 Protected Resource Metadata
2. MCP clients **MUST** implement PKCE (OAuth 2.1 §7.5.2)
3. MCP clients **MUST** send the `resource` parameter (RFC 8707) in both authorization and token requests, naming the canonical URI of the MCP server
4. MCP servers **MUST** validate that tokens presented to them were issued *for them* — audience validation, per RFC 9068
5. Token passthrough is **explicitly forbidden**
6. MCP proxy servers with static client IDs **MUST** obtain user consent for each dynamically registered client

Requirement 3 and 4 together are the point. A token minted for `https://mcp.example` is useless at `https://other.example`. A CLI credential has no such boundary — it works everywhere the principal is recognized.

### The stdio Loophole

Here is the part that undoes most of the argument in practice. The specification says, verbatim:

> Implementations using an STDIO transport SHOULD NOT follow this specification, and instead retrieve credentials from the environment.

A local stdio MCP server has **exactly the CLI's authorization model**. Same environment variables, same dotfiles, same ambient authority, same inability to know who is calling.

```
agent ──stdio──► npx -y @vendor/mcp-server
                      │
                      ├─ reads $GITHUB_TOKEN from the environment
                      ▼
                  GitHub API sees: "diego's PAT"
```

And it is worse than the CLI in two ways. The credential is now held by a process fetched from a package registry at launch rather than by a pinned, signed, widely-audited binary. And the server's tool descriptions are fed to the model as trusted instruction text, which `man aws` never was.

So "we moved to MCP, our auth is better now" is **false in the common case**. Most MCP servers people actually run are stdio servers reading the same environment variables the CLI would have read. The OAuth guarantees apply to remote HTTP servers only. If the server is local and stdio, the delegation column of that table is fiction.

### What the Audit Log Sees

CloudTrail records a `userIdentity` block and a `userAgent` string. The first is trustworthy and tells you the principal. The second is **client-supplied and trivially forged** — it is a header, not an attestation.

```
{
  "userIdentity": { "arn": "arn:aws:iam::123:user/diego" },
  "userAgent":    "aws-cli/2.15.0 md/agent#claude-code",
  "eventName":    "DeleteObject"
}
```

The `userAgent` cannot be used for attribution or policy. Anything the agent can set, an attacker who owns the same credential can set. If the audit answer to "was this the human or the agent?" rests on a user-agent string, there is no audit answer.

The CLI's real fix is not a header. It is a **distinct principal per caller**:

```
aws sts assume-role \
  --role-arn arn:aws:iam::123:role/agent-readonly \
  --role-session-name claude-code-run-7e62 \
  --tags Key=caller,Value=agent
```

Now CloudTrail shows `assumed-role/agent-readonly/claude-code-run-7e62`, the session is short-lived, the role's policy is narrow, and the session tag is set by the trusted party at assume time rather than by the caller at request time. That is genuine attribution and genuine least privilege, on the CLI, with no MCP involved.

## Scope and Blast Radius

MCP's theoretical per-call scoping usually collapses to a coarse grant, and the specification says so itself. On scope selection, when the `WWW-Authenticate` header carries no `scope`:

> use all scopes defined in `scopes_supported` from the Protected Resource Metadata document

with the stated rationale that general-purpose MCP clients "typically lack domain-specific knowledge to make informed decisions about individual scope selection." The spec leans on `scopes_supported` being minimal and on step-up challenges for the rest, but the default path is *request everything the server advertises* and let the consent screen sort it out.

Compare the real grants:

```
┌──────────────────────────┬────────────────────────────────────┐
│ Grant                    │ Actual blast radius                │
├──────────────────────────┼────────────────────────────────────┤
│ GitHub OAuth `repo`      │ Every repo the user can read/write │
│ GitHub fine-grained PAT  │ Chosen repos, chosen permissions   │
│ $GITHUB_TOKEN in env     │ Whatever that token was minted for │
│ IAM user access key      │ Everything the user can do, no exp │
│ STS role + session name  │ One role's policy, minutes long    │
└──────────────────────────┴────────────────────────────────────┘
```

A fine-grained PAT handed to a CLI is **narrower** than an MCP server holding a coarse OAuth grant. The surface does not determine the blast radius; the grant does. This is why "CLI vs MCP" is the wrong axis for a security decision taken alone — the right axis is *how narrow is the credential, how short is its life, and can the server tell callers apart*.

## Attacks and Defenses

### The Auth Machinery Is Itself Attack Surface

MCP's authorization code is new, and it has already produced critical RCEs — in the OAuth flow specifically.

**CVE-2025-6514** (CVSS 9.6, JFrog Security Research): `mcp-remote` mishandled the `authorization_endpoint` URL received from the server during OAuth initialization. A malicious MCP server returns a crafted `authorization_endpoint`; passing it to `open()` yields OS command injection. Versions 0.0.5 through 0.1.15, fixed in **0.1.16**. The package had been downloaded over 437,000 times. The attack requires only that a client connect to an untrusted server — the OAuth handshake *is* the exploit path.

**CVE-2025-49596** (CVSS 9.4, Oligo Security): the MCP Inspector's proxy server had no authentication between client and proxy, and could launch MCP commands over stdio. Chained with the `0.0.0.0 day` browser flaw and CSRF, visiting a malicious web page executed code on the developer's machine. Fixed in **0.14.1** by adding origin validation and session-token auth.

Defenses: pin MCP server and proxy versions, never connect to servers you do not trust, require HTTPS, and treat the MCP client's OAuth implementation as security-critical code that needs updating.

### Prompt Injection Through Tool Descriptions

Tool names, descriptions, and parameter docs are fed to the model as instruction text. A server can put directives there. The model then acts with whatever authority the session holds — which, for a stdio server, is your entire environment.

- **Tool poisoning**: the description carries instructions aimed at the model, not the human
- **Rug pull**: the server serves a benign description at approval time and a malicious one later
- **Cross-server shadowing**: one server's description manipulates how the model uses another server's tools

The CLI does not have this class. `man aws` is not injected into the context as trusted instruction.

Defenses: pin server versions and hash tool definitions, re-prompt on definition change, keep untrusted servers in separate sessions from sensitive credentials, and gate tool calls at the harness with the arguments visible.

### Confused Deputy at the Proxy

An MCP server fronting a third-party API with a **static client ID** is a confused deputy. The third-party AS may have already seen consent for that client ID, so an attacker with a stolen authorization code can obtain tokens without the user consenting again. The spec's answer is mandatory: obtain user consent for **each** dynamically registered client before forwarding.

Defenses: consent per client, never forward a token you received to a downstream service (passthrough is forbidden), use RFC 8693 token exchange when a genuine on-behalf-of chain is needed, and validate `aud` on every request.

### Credential Theft from the Environment

Applies to CLI and stdio MCP identically. Static keys in dotfiles do not expire and do not attribute.

Defenses: short-lived STS or SSO sessions instead of static keys, a distinct role per agent, `--role-session-name` for attribution, OS keychain over plaintext files, sandboxing or containers so a compromised process cannot read the whole credential store, and never echo credentials into logs or transcripts.

### SSRF Against the Authorization Server

New in the 2025-11-25 revision. Client ID Metadata Documents make the AS fetch a URL supplied by an unknown client, which can be pointed at private administration endpoints.

Defenses: the spec directs authorization servers fetching metadata documents to consider SSRF — allowlist schemes, block internal address ranges, cap redirects and response size.

## Anti-Patterns

- **Static long-lived keys for agents**: an `AKIA...` key in the environment never expires and attributes to nobody
- **Attribution by user agent**: a client-supplied header is not evidence; anyone with the credential can forge it
- **"We use MCP, so we have OAuth"**: not for stdio servers, which the spec explicitly exempts and points at the environment
- **`npx -y` an MCP server with your credentials**: unpinned code from a registry, fetched at every launch, holding your secrets
- **One principal shared by human and agent**: the audit log can never separate them afterward
- **Token passthrough**: forwarding a received token downstream is forbidden and creates a confused deputy
- **Requesting every advertised scope and calling it least privilege**: the default path is broad; step-up exists for a reason
- **Trusting tool descriptions**: they are model-visible text from the server, not documentation
- **Connect-time consent treated as per-call authorization**: the user consented once; the token then does whatever it is asked
- **Skipping `aud` validation**: without it, a token minted for another service works on yours
- **Agent's shell inheriting the operator's full environment**: the agent gets every credential the human has, not the ones it needs

## Pros

### CLI

- **Mature and audited**: decades of hardening, signed packages, pinned versions, known CVE processes
- **No injection surface**: help text is not fed to the model as instructions
- **Full command visible**: the harness can gate on the exact argv, with allowlists and permission prompts
- **OS-level containment**: sandboxes, containers, seccomp, and filesystem permissions all apply directly
- **Universal coverage**: every system worth calling already has a CLI; no server to write or run
- **Can be made attributable**: role assumption with a session name per agent gives real audit identity
- **No extra network trust**: no proxy, no metadata fetch, no third-party AS in the path

### MCP

- **Real delegation**: the token names the user, the client, the audience, the scopes, and an expiry
- **Audience binding**: RFC 8707 plus `aud` validation stops a token from working at the wrong endpoint
- **A consent moment exists**: a human approved this client having this authority, once, explicitly
- **Revocable centrally**: kill the grant at the authorization server, not by rotating a shared key
- **Expiry by default**: tokens die; access keys do not
- **Structured arguments**: typed parameters are easier to validate and log than a shell string
- **Standards underneath**: OAuth 2.1, RFC 9728, RFC 8707, RFC 8414 — existing IdP infrastructure applies
- **Step-up authorization**: `insufficient_scope` challenges let a session start narrow and widen on demand

## Cons

### CLI

- **Ambient authority**: any process that reads the credential is the principal
- **No caller identity**: the service cannot distinguish human, script, agent, or malware
- **No consent moment**: nobody ever approved the agent having this
- **No per-call narrowing**: the credential carries everything the principal can do
- **Static credentials are common**: no expiry, revocation means rotating a shared secret
- **Shell injection risk**: argument construction from model output is its own hazard
- **Output is unstructured**: parsing text is brittle, and errors are easy to misread as success

### MCP

- **The stdio exemption**: the common deployment has the CLI's model with extra untrusted code
- **Consent is coarse and once**: connect-time approval, not per-call authorization
- **Scope defaults are broad**: request-all-advertised-scopes is the specified fallback
- **New code, critical CVEs**: CVE-2025-6514 and CVE-2025-49596 were both RCEs in the auth path
- **Tool descriptions are injectable**: a model-visible trust boundary the CLI does not have
- **Supply chain exposure**: unpinned servers fetched at launch, holding live credentials
- **Spec churn**: three authorization models in under a year; implementations lag the current revision
- **Moving target for reviewers**: a server can change its tools after approval
- **More infrastructure**: an AS, metadata endpoints, token storage, and refresh logic to get right

## Use Cases

- **Prefer a remote MCP server** when a third party must authorize the agent, when you need central revocation, or when the agent acts for many different users
- **Prefer a CLI with an assumed role** when the system is yours, the operation is narrow, and you want attribution without standing up an authorization server
- **Never share a principal** between a human and an agent, whichever surface you pick
- **Give the agent its own identity**: an IAM role, a fine-grained PAT, a SPIFFE SVID — provisioned for it, scoped to its job, short-lived
- **Treat stdio MCP as a CLI**: sandbox it, pin it, scope its environment, and stop expecting OAuth guarantees
- **Use RFC 8693 token exchange** for real on-behalf-of chains rather than forwarding tokens
- **Audit on the principal, not the user agent**: if the log cannot separate agent from human, fix the credential, not the header

The honest summary: MCP over HTTP is the only one of the two with an answer to "who is calling," and that answer is real — audience-bound, scoped, expiring, revocable. But it applies to remote servers only, its consent is coarse, its scope default is broad, and its own auth code has shipped two critical RCEs. The CLI has no answer by default, and can be given a good one with a per-agent role and short-lived credentials.

So the question is not CLI or MCP. It is whether the thing calling has its own narrow, short-lived, attributable identity — and both surfaces can fail that test, and both can pass it.

## Links

- MCP authorization specification (current, 2025-11-25): https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization
- MCP security best practices: https://modelcontextprotocol.io/specification/2025-11-25/basic/security_best_practices
- MCP specification versioning and revisions: https://modelcontextprotocol.io/specification/versioning
- OAuth 2.1 draft: https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-13
- RFC 8707 Resource Indicators for OAuth 2.0: https://www.rfc-editor.org/rfc/rfc8707.html
- RFC 9728 OAuth 2.0 Protected Resource Metadata: https://datatracker.ietf.org/doc/html/rfc9728
- RFC 8414 OAuth 2.0 Authorization Server Metadata: https://datatracker.ietf.org/doc/html/rfc8414
- RFC 9068 JWT Profile for OAuth 2.0 Access Tokens: https://www.rfc-editor.org/rfc/rfc9068.html
- RFC 8693 OAuth 2.0 Token Exchange: https://www.rfc-editor.org/rfc/rfc8693.html
- OAuth Client ID Metadata Documents draft: https://datatracker.ietf.org/doc/html/draft-ietf-oauth-client-id-metadata-document-00
- JFrog on CVE-2025-6514 in mcp-remote: https://jfrog.com/blog/2025-6514-critical-mcp-remote-rce-vulnerability/
- Oligo Security on CVE-2025-49596 in MCP Inspector: https://www.oligo.security/blog/critical-rce-vulnerability-in-anthropic-mcp-inspector-cve-2025-49596
- AWS STS AssumeRole and session tags: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
- CloudTrail userIdentity element: https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-event-reference-user-identity.html
