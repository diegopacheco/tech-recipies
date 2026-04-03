# WAF (Web Application Firewall)

## What is it?

A Web Application Firewall (WAF) is a security layer that sits between clients and web applications, inspecting HTTP/HTTPS traffic and blocking malicious requests before they reach the application. Unlike traditional network firewalls that operate at layers 3-4 (IP, TCP), a WAF operates at layer 7 (HTTP) and understands application-level protocols. It can inspect request headers, body, URL parameters, cookies, and response content to detect and block attacks like SQL injection, XSS, command injection, and other OWASP Top 10 threats.

## Who created it? When?

The concept of application-layer firewalls emerged in the late 1990s. **Perfecto Technologies** (later acquired by Sanctum, then IBM) released **AppShield** in **1999**, one of the first commercial WAFs. **ModSecurity**, the first widely adopted open source WAF, was created by **Ivan Ristic** in **2002** and became the de facto standard for Apache and later Nginx. The **OWASP ModSecurity Core Rule Set (CRS)** was started in **2006** to provide a standardized set of detection rules. Cloud WAFs emerged in the 2010s with **Cloudflare** (2010), **AWS WAF** (2015), and **Akamai Kona** becoming major players.

## How it works?

### Deployment Modes

```
1. Reverse Proxy (inline):

┌────────┐    HTTPS    ┌─────────┐    HTTP/S   ┌──────────┐
│ Client │────────────►│   WAF   │────────────►│ Web App  │
│        │◄────────────│ (proxy) │◄────────────│          │
└────────┘             └─────────┘             └──────────┘
                       inspects &
                       filters traffic

2. Cloud-based (DNS redirect):

┌────────┐    HTTPS    ┌───────────────┐   HTTPS   ┌──────────┐
│ Client │────────────►│ Cloud WAF     │──────────►│ Origin   │
│        │             │ (Cloudflare,  │           │ Server   │
│        │◄────────────│  AWS, Akamai) │◄──────────│          │
└────────┘             └───────────────┘           └──────────┘
                       DNS points to WAF
                       WAF proxies clean traffic

3. Embedded (module):

┌────────┐    HTTPS    ┌─────────────────────────┐
│ Client │────────────►│ Web Server              │
│        │◄────────────│ ┌─────────┐ ┌─────────┐ │
└────────┘             │ │   WAF   │→│ Web App │ │
                       │ │ Module  │ │         │ │
                       │ │(ModSec) │ │         │ │
                       │ └─────────┘ └─────────┘ │
                       └─────────────────────────┘
```

### Detection Methods

#### 1. Signature-Based (Negative Security Model)

Maintains a database of known attack patterns (signatures/rules). Requests matching a signature are blocked. Fast and effective against known attacks. Cannot detect zero-day or novel attacks.

```
Rule: SecRule ARGS "@rx (?i)(union\s+select|insert\s+into|drop\s+table)" \
      "id:1001,phase:2,deny,status:403,msg:'SQL Injection detected'"

Request: GET /search?q=1' UNION SELECT username,password FROM users--
Match:   ^^^^^^^^^^^^^^^^^ matches SQL injection pattern
Action:  BLOCK (403 Forbidden)
```

#### 2. Anomaly Scoring

Each rule violation adds points to an anomaly score. The request is blocked only if the total score exceeds a threshold. Reduces false positives compared to blocking on any single rule match.

```
Request: POST /login

Rule Violations:
  - Missing Accept header           +2 points
  - SQL characters in body          +5 points
  - Unusual Content-Type            +3 points
                                   ──────────
  Total anomaly score:              10 points
  Threshold:                         5 points
  Action:                           BLOCK
```

#### 3. Positive Security Model (Allowlisting)

Defines what valid requests look like (allowed methods, parameters, content types, value ranges). Everything that does not match the allowed profile is blocked. Very secure but requires detailed application knowledge and maintenance.

```
Allowed Profile for POST /api/users:
  - Method: POST only
  - Content-Type: application/json
  - Body fields: name (string, 1-100 chars), email (email format)
  - No other fields allowed

Request: POST /api/users {"name":"alice","email":"a@b.com","role":"admin"}
Match:   "role" field not in allowed profile
Action:  BLOCK
```

#### 4. Machine Learning / Behavioral

Learns normal traffic patterns and flags anomalies. Can detect novel attacks but produces false positives during training. Used by advanced cloud WAFs (Cloudflare, AWS WAF Bot Control).

### Request Inspection Pipeline

```
┌─────────────────────────────────────────────────────────┐
│                  WAF Processing Pipeline                 │
│                                                         │
│  Request ──► Phase 1: Request Headers                   │
│              - Method, URL, Host, User-Agent            │
│              - Cookie inspection                        │
│              - IP reputation check                      │
│                     │                                   │
│                     ▼                                   │
│              Phase 2: Request Body                      │
│              - POST parameters                         │
│              - JSON/XML body parsing                    │
│              - File upload inspection                   │
│              - SQL/XSS/RCE pattern matching             │
│                     │                                   │
│                     ▼                                   │
│              Phase 3: Response Headers                  │
│              - Information leakage (server headers)     │
│              - Error page detection                     │
│                     │                                   │
│                     ▼                                   │
│              Phase 4: Response Body                     │
│              - Credit card number masking               │
│              - Error message filtering                  │
│              - Data leakage prevention                  │
│                     │                                   │
│                     ▼                                   │
│              Phase 5: Logging                           │
│              - Full request/response audit log          │
│              - Alert generation                        │
└─────────────────────────────────────────────────────────┘
```

## WAF Solutions

### 1. ModSecurity (Open Source)

The original open source WAF. Works as a module for Apache, Nginx, and IIS. Uses the OWASP Core Rule Set (CRS) for detection. ModSecurity 3.x (libmodsecurity) is a standalone library.

- Rule language: SecRule directives with regex and operators
- OWASP CRS: 100+ rules covering OWASP Top 10
- Modes: detection only (log) or blocking (deny)
- Performance: adds ~1-5ms latency per request
- Maintained by: Trustwave SpiderLabs (open source)

### 2. Cloudflare WAF

Cloud-based WAF integrated with Cloudflare's CDN and DDoS protection. Managed rulesets updated by Cloudflare's threat research team.

- Managed rules: Cloudflare Managed Ruleset, OWASP CRS
- Bot management: ML-based bot detection and challenge
- Rate limiting: per-endpoint, per-IP rate controls
- Custom rules: Cloudflare Rules Language (Wireshark-inspired syntax)
- Edge deployment: runs at 300+ PoPs worldwide
- Analytics: real-time dashboards and security events

### 3. AWS WAF

AWS-native WAF integrated with CloudFront, ALB, API Gateway, and AppSync.

- Web ACLs: ordered list of rules evaluated per request
- Managed rule groups: AWS Managed Rules, marketplace rules
- Custom rules: rate-based, IP sets, regex patterns, geo-blocking
- Bot Control: ML-based bot detection (add-on)
- Integration: CloudWatch metrics, Kinesis Firehose logging
- Pricing: per web ACL, per rule, per million requests

### 4. Coraza (Open Source)

Modern, Go-based WAF engine compatible with ModSecurity's SecRule language. Designed as a drop-in replacement for ModSecurity with better performance and maintainability.

- 100% compatible with OWASP CRS
- Written in Go (no C dependencies)
- Embeddable as a library in Go applications
- Caddy plugin, Envoy filter, Traefik middleware
- CNCF project (sandbox)

### 5. NGINX App Protect

NGINX-native WAF based on F5's BIG-IP ASM technology. Runs as a dynamic module within NGINX.

- Advanced bot defense
- JSON/XML/gRPC inspection
- OpenAPI schema enforcement
- Behavioral analysis
- Declarative JSON policies

## What a WAF Protects Against

```
┌───────────────────────┬────────────────────────────────────────────────┐
│ Attack Type           │ How WAF Detects It                             │
├───────────────────────┼────────────────────────────────────────────────┤
│ SQL Injection         │ Pattern matching: UNION SELECT, OR 1=1,        │
│                       │ comment sequences (--), string termination (') │
├───────────────────────┼────────────────────────────────────────────────┤
│ Cross-Site Scripting  │ Pattern matching: <script>, javascript:,       │
│ (XSS)                │ event handlers (onerror=), encoded variants    │
├───────────────────────┼────────────────────────────────────────────────┤
│ Command Injection     │ Pattern matching: ; ls, | cat, $(), backticks │
│ (RCE)                │ command separators, shell metacharacters       │
├───────────────────────┼────────────────────────────────────────────────┤
│ Path Traversal        │ Pattern matching: ../, ....\\, %2e%2e, null   │
│                       │ bytes in file paths                            │
├───────────────────────┼────────────────────────────────────────────────┤
│ File Inclusion        │ Pattern matching: file://, php://, expect://,  │
│ (LFI/RFI)            │ remote URLs in include parameters             │
├───────────────────────┼────────────────────────────────────────────────┤
│ HTTP Request          │ Request size limits, header count limits,      │
│ Smuggling             │ Transfer-Encoding/Content-Length conflicts     │
├───────────────────────┼────────────────────────────────────────────────┤
│ Bot Traffic           │ Rate limiting, JavaScript challenges,          │
│                       │ CAPTCHA, fingerprinting, ML classification    │
├───────────────────────┼────────────────────────────────────────────────┤
│ DDoS (Layer 7)       │ Rate limiting, connection throttling,          │
│                       │ geographic blocking, challenge pages          │
├───────────────────────┼────────────────────────────────────────────────┤
│ Credential Stuffing   │ Rate limiting on login endpoints,             │
│                       │ bot detection, leaked credential checks       │
└───────────────────────┴────────────────────────────────────────────────┘
```

## What a WAF Does NOT Protect Against

- **Logic bugs**: flawed business logic (e.g., IDOR, broken access control) looks like valid requests
- **Zero-day exploits**: novel attacks without known signatures bypass signature-based detection
- **Encrypted payloads**: WAF cannot inspect end-to-end encrypted content it cannot terminate
- **Insider threats**: authenticated users performing authorized but malicious actions
- **API abuse**: valid API calls used for scraping, enumeration, or data harvesting at low rates
- **Client-side attacks**: DOM-based XSS, prototype pollution, and other browser-side vulnerabilities
- **Supply chain attacks**: compromised dependencies loaded by the application itself

## Comparison

```
┌──────────────────┬─────────────┬──────────────┬────────────┬──────────────┐
│ Feature          │ ModSecurity │ Cloudflare   │ AWS WAF    │ Coraza       │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ Deployment       │ On-prem     │ Cloud edge   │ AWS cloud  │ On-prem/edge │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ Rule Engine      │ SecRule     │ Proprietary  │ JSON rules │ SecRule       │
│                  │             │ + managed    │ + managed  │              │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ OWASP CRS        │ Yes         │ Yes          │ Yes        │ Yes          │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ Bot Management   │ Basic       │ Advanced ML  │ ML add-on  │ Basic        │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ DDoS Protection  │ No          │ Yes (L3-L7)  │ Shield     │ No           │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ Cost             │ Free        │ $20+/month   │ Per-use    │ Free         │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ Latency Added    │ 1-5ms       │ <1ms (edge)  │ <1ms       │ 1-3ms        │
├──────────────────┼─────────────┼──────────────┼────────────┼──────────────┤
│ Maintenance      │ Self-manage │ Managed      │ Managed    │ Self-manage  │
└──────────────────┴─────────────┴──────────────┴────────────┴──────────────┘
```

## Pros

- **OWASP Top 10 Protection**: blocks the most common web attacks out of the box
- **Virtual Patching**: block exploitation of known vulnerabilities before application code is fixed
- **No Application Changes**: protects applications without modifying their code
- **Centralized Security**: single enforcement point for all backend applications
- **Compliance**: PCI-DSS 6.6 explicitly requires a WAF or code review for web applications
- **Visibility**: detailed logging of all requests and security events
- **Rate Limiting**: protects against brute force, credential stuffing, and L7 DDoS
- **Bot Management**: distinguishes legitimate users from automated traffic
- **Response Filtering**: prevents information leakage (server headers, stack traces, error details)

## Cons

- **False Positives**: legitimate requests blocked by overly aggressive rules
- **False Negatives**: sophisticated attacks evade signature-based detection
- **Performance Overhead**: request inspection adds latency, especially with large request bodies
- **Maintenance Burden**: rules need ongoing tuning, updating, and testing
- **Bypass Techniques**: encoding tricks, fragmentation, and protocol-level evasion bypass many rules
- **False Sense of Security**: a WAF does not replace secure coding practices
- **Complexity**: advanced configurations (custom rules, exceptions, rate limits) are difficult to get right
- **TLS Termination Required**: WAF must terminate TLS to inspect encrypted traffic, adding a trust point
- **Cost at Scale**: cloud WAF pricing grows with request volume

## Use Cases

- **E-Commerce**: protecting payment forms, login pages, and product APIs from injection and bot attacks
- **API Protection**: inspecting JSON/XML/gRPC payloads for injection and schema violations
- **Virtual Patching**: blocking CVE exploitation while application teams develop and deploy fixes
- **PCI-DSS Compliance**: satisfying requirement 6.6 for web application protection
- **Bot Mitigation**: blocking scrapers, credential stuffers, and inventory hoarding bots
- **Multi-Application Gateway**: single WAF protecting multiple backend applications
- **Rate Limiting**: protecting login endpoints, password reset, and API endpoints from abuse
- **Geographic Blocking**: restricting access from specific countries for regulatory or security reasons
- **Legacy Application Protection**: adding security layer to applications that cannot be easily patched
- **DDoS Mitigation**: absorbing and filtering application-layer DDoS attacks at the edge
