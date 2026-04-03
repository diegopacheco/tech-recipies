# Split Traffic Patterns

## What is it?

Traffic splitting is the practice of routing different portions of incoming requests to different versions, instances, or backends of a service. It is the underlying mechanism that enables canary deployments, A/B testing, blue-green releases, feature flags, and progressive rollouts. Traffic can be split by percentage (weight), user attributes (headers, cookies, geo), or deterministic hashing (consistent user experience). The split can happen at the DNS, load balancer, ingress, service mesh, or application layer.

## How it works?

### Splitting Layers

```
                    Request
                       │
          ┌────────────┼────────────┐
          ▼            ▼            ▼
     ┌─────────┐ ┌──────────┐ ┌──────────┐
     │  DNS    │ │   CDN /  │ │   App    │
     │ Routing │ │  Edge    │ │  Layer   │
     │         │ │  (L7)   │ │  Flags   │
     └────┬────┘ └────┬─────┘ └────┬─────┘
          │           │            │
     Route 53    Cloudflare    Feature
     weighted    Workers /     Flags
     records     Fastly VCL    (LaunchDarkly,
                               Unleash)
          │           │            │
          ▼           ▼            ▼
     ┌──────────────────────────────────┐
     │         Load Balancer            │
     │    (ALB, NLB, HAProxy, Envoy)    │
     │    weighted target groups        │
     └──────────────┬───────────────────┘
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
     ┌─────────┐ ┌─────────┐ ┌─────────┐
     │ Ingress │ │ Service │ │ Sidecar │
     │ Ctrl    │ │  Mesh   │ │  Proxy  │
     │ (Nginx) │ │ (Istio) │ │ (Envoy) │
     └─────────┘ └─────────┘ └─────────┘
```

## Split Methods

### 1. Weight-Based (Percentage)

Route a percentage of all traffic to each version. The simplest and most common form.

```
100 requests incoming:
  ├── 95 requests ──► v1 (stable)
  └──  5 requests ──► v2 (canary)

No user affinity — same user may hit different versions on different requests.
```

**Istio VirtualService**:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  hosts:
    - my-service
  http:
    - route:
        - destination:
            host: my-service
            subset: stable
          weight: 95
        - destination:
            host: my-service
            subset: canary
          weight: 5
```

**Nginx Ingress**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "5"
```

**AWS ALB**:
```
Target Group 1 (v1): weight 95
Target Group 2 (v2): weight 5
```

### 2. Header-Based

Route based on HTTP headers. Used for internal testing, partner traffic, or opt-in canary.

```
Request with header "x-canary: true" ──► v2
Request without header                ──► v1

Common headers:
  x-canary: true/false
  x-version: v2
  x-debug: enabled
  x-internal: true
```

**Istio**:
```yaml
http:
  - match:
      - headers:
          x-canary:
            exact: "true"
    route:
      - destination:
          host: my-service
          subset: canary
  - route:
      - destination:
          host: my-service
          subset: stable
```

### 3. Cookie-Based

Route based on a cookie value. Provides session affinity — once a user gets the canary, they stay on it.

```
First request: no cookie
  ├── 5% chance: set cookie "version=canary", route to v2
  └── 95% chance: set cookie "version=stable", route to v1

Subsequent requests: follow cookie
  cookie "version=canary" ──► v2 (always)
  cookie "version=stable" ──► v1 (always)
```

### 4. User/Account-Based

Route based on user identity. Deterministic — same user always gets the same version.

```
hash(user_id) % 100:
  0-4   ──► v2 (canary, 5%)
  5-99  ──► v1 (stable, 95%)

Consistent hashing ensures the same user always lands on the same version.
Used for A/B testing where user experience must be consistent.
```

### 5. Geographic

Route based on client location (IP geolocation, CloudFront geo headers, or explicit region selection).

```
US-East traffic     ──► v2 (canary region)
All other traffic   ──► v1 (stable)

Use cases:
  - Test in one region before global rollout
  - Comply with data residency requirements
  - Reduce blast radius to a single geography
```

### 6. Device/Client-Based

Route based on User-Agent, client version, or platform.

```
iOS app v4.2+          ──► v2 (new API)
iOS app v4.1 and below ──► v1 (old API)
Android                ──► v1 (stable)
Web browser            ──► v2 (canary)
```

## Comparison of Splitting Mechanisms

```
┌──────────────────┬────────────┬──────────────┬──────────────┬────────────┐
│ Mechanism        │ Layer      │ Granularity  │ Affinity     │ Complexity │
├──────────────────┼────────────┼──────────────┼──────────────┼────────────┤
│ DNS weighted     │ L3/L4      │ Coarse       │ TTL-based    │ Low        │
│ (Route 53)       │            │ (no < 1%)    │              │            │
├──────────────────┼────────────┼──────────────┼──────────────┼────────────┤
│ Load balancer    │ L4/L7      │ Medium       │ Sticky       │ Low        │
│ (ALB, NLB)       │            │ (1% min)     │ sessions     │            │
├──────────────────┼────────────┼──────────────┼──────────────┼────────────┤
│ Ingress weight   │ L7         │ Medium       │ None/Cookie  │ Low        │
│ (Nginx, Traefik) │            │ (1% steps)   │              │            │
├──────────────────┼────────────┼──────────────┼──────────────┼────────────┤
│ Service mesh     │ L7         │ Fine         │ Header/hash  │ High       │
│ (Istio, Linkerd) │            │ (0.1% steps) │              │            │
├──────────────────┼────────────┼──────────────┼──────────────┼────────────┤
│ Edge/CDN         │ L7 (edge)  │ Fine         │ Cookie/geo   │ Medium     │
│ (Cloudflare, CF) │            │              │              │            │
├──────────────────┼────────────┼──────────────┼──────────────┼────────────┤
│ Feature flags    │ App layer  │ Very Fine    │ User-level   │ Medium     │
│ (LaunchDarkly)   │            │ (per-user)   │ (deterministic)│          │
└──────────────────┴────────────┴──────────────┴──────────────┴────────────┘
```

## Traffic Mirroring (Shadow Traffic)

A special case: send a copy of production traffic to a new version without affecting users. The mirror receives real requests but its responses are discarded.

```
Request ──► v1 (stable) ──► Response to user
   │
   └──► v2 (mirror) ──► Response discarded
                         Metrics collected
```

Useful for load testing, validating new versions, and comparing behavior without any user impact. Istio supports this via `mirror` and `mirrorPercentage` in VirtualService.

## Pros

- **Granular Control**: route by percentage, user, geo, header, cookie, or any combination
- **Risk Reduction**: limit exposure of new code to a controllable subset
- **Real Traffic Testing**: validate with production traffic patterns, not synthetic loads
- **User-Level Targeting**: feature flags enable per-user, per-account, per-org targeting
- **Instant Switching**: most mechanisms switch traffic in seconds (no redeploy needed)
- **Composable**: combine weight + header + geo splits for complex rollout strategies
- **Observable**: each split can be monitored independently for comparison

## Cons

- **Session Consistency**: weight-based splits without affinity cause users to bounce between versions
- **Cache Pollution**: CDN and browser caches may serve wrong version to wrong users
- **Database Compatibility**: both versions must work with the same database schema
- **Debugging Complexity**: reproducing bugs requires knowing which version the user was routed to
- **Infrastructure Cost**: running multiple versions simultaneously uses more resources
- **DNS Propagation**: DNS-based splitting is slow to change (TTL delays)
- **Testing Matrix**: N versions x M split criteria = combinatorial explosion of test scenarios
- **Metric Dilution**: small traffic percentages produce noisy metrics that are hard to interpret

## Use Cases

- **Canary Deployments**: 5% traffic to new version, monitor, gradually increase
- **A/B Testing**: 50/50 split with user affinity for measuring feature impact on business KPIs
- **Blue-Green Releases**: 0/100 instant switch with rollback capability
- **Regional Rollouts**: deploy to EU first, validate, then expand to US and APAC
- **Internal Testing**: header-based routing for QA and staging in production
- **Partner Traffic**: route specific API clients to a dedicated version via API key or header
- **Shadow Testing**: mirror production traffic to a new version for comparison without user impact
- **Gradual Migration**: route increasing traffic from legacy to new system during migration
- **Load Shedding**: route overflow traffic to a degraded but functional version during incidents
- **Compliance**: route PII-containing requests to a specific version deployed in a compliant region
