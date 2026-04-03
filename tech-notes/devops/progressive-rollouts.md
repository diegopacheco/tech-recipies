# Progressive Rollouts

## What is it?

A progressive rollout is a deployment strategy that gradually exposes a new version to increasing percentages of traffic or users, with automated health checks and gates at each stage. Unlike a simple canary (which is one form of progressive rollout), progressive rollouts encompass the full spectrum of incremental release strategies — canary, blue-green, linear, exponential, and stepped — with automated analysis, manual approval gates, and rollback triggers integrated into a single workflow.

## How it works?

### Rollout Progression

```
┌─────┐    ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐    ┌───────┐
│ 1%  │───►│ 5%   │───►│ 20%  │───►│ 50%  │───►│ 80%  │───►│ 100%  │
│     │    │      │    │      │    │      │    │      │    │       │
│gate │    │gate  │    │gate  │    │gate  │    │gate  │    │stable │
└─────┘    └──────┘    └──────┘    └──────┘    └──────┘    └───────┘
  │           │           │           │           │
  ▼           ▼           ▼           ▼           ▼
analyze    analyze    analyze    analyze    analyze
metrics    metrics    metrics    metrics    metrics
  │           │           │           │           │
pass/fail  pass/fail  pass/fail  pass/fail  pass/fail

At any gate: fail ──► automatic rollback to 0%
```

### Rollout Strategies

```
┌──────────────────┬──────────────────────────────────────────────────┐
│ Strategy         │ How it works                                      │
├──────────────────┼──────────────────────────────────────────────────┤
│ Stepped          │ Fixed increments: 5% → 20% → 50% → 100%         │
│ (most common)    │ Pause and analyze at each step                    │
├──────────────────┼──────────────────────────────────────────────────┤
│ Linear           │ Steady increase: +10% every 5 minutes             │
│                  │ Continuous analysis, rollback on failure           │
├──────────────────┼──────────────────────────────────────────────────┤
│ Exponential      │ Doubling: 1% → 2% → 4% → 8% → 16% → 32% → 64% │
│                  │ Slow start, fast finish once confidence is high   │
├──────────────────┼──────────────────────────────────────────────────┤
│ Blue-Green       │ 0% → 100% instant switch with rollback ready     │
│                  │ Both versions running, switch at the LB/mesh      │
├──────────────────┼──────────────────────────────────────────────────┤
│ Header/Cookie    │ Route by header (x-canary: true) or cookie       │
│ based            │ Internal testing before any public traffic        │
├──────────────────┼──────────────────────────────────────────────────┤
│ Ring-based       │ Ring 0: team → Ring 1: org → Ring 2: 10% users   │
│ (Microsoft)      │ → Ring 3: 50% → Ring 4: 100%                     │
└──────────────────┴──────────────────────────────────────────────────┘
```

### Gate Types

```
┌──────────────────────┬──────────────────────────────────────────────┐
│ Gate Type            │ Description                                   │
├──────────────────────┼──────────────────────────────────────────────┤
│ Metric analysis      │ Automated comparison of canary vs baseline   │
│                      │ metrics (error rate, latency, saturation)     │
├──────────────────────┼──────────────────────────────────────────────┤
│ Timed pause          │ Wait N minutes at each weight to collect     │
│                      │ enough data for statistical significance      │
├──────────────────────┼──────────────────────────────────────────────┤
│ Manual approval      │ Human approves promotion at critical steps   │
│                      │ (e.g., before going above 50%)                │
├──────────────────────┼──────────────────────────────────────────────┤
│ Webhook gate         │ External system (test suite, chaos test,     │
│                      │ compliance check) must return success         │
├──────────────────────┼──────────────────────────────────────────────┤
│ Integration test     │ Run smoke tests against the canary before    │
│                      │ advancing traffic                             │
├──────────────────────┼──────────────────────────────────────────────┤
│ SLO-based            │ Promote only if the canary meets the         │
│                      │ service's SLO targets                         │
└──────────────────────┴──────────────────────────────────────────────┘
```

## Argo Rollouts

Kubernetes controller for progressive delivery. Replaces the built-in Deployment resource with a Rollout resource that supports canary and blue-green strategies.

```
┌─────────────────────────────────────────────────┐
│                Argo Rollouts                     │
│                                                 │
│  Rollout CRD ──► Rollout Controller             │
│                       │                         │
│               ┌───────┼───────┐                 │
│               ▼       ▼       ▼                 │
│          ReplicaSet ReplicaSet AnalysisRun       │
│          (stable)   (canary)   (metrics check)   │
│               │       │                         │
│               ▼       ▼                         │
│          ┌──────────────────┐                   │
│          │ Traffic Manager  │                   │
│          │ (Istio, Nginx,   │                   │
│          │  ALB, SMI, etc.) │                   │
│          └──────────────────┘                   │
└─────────────────────────────────────────────────┘
```

### AnalysisTemplate

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
spec:
  args:
    - name: service-name
  metrics:
    - name: success-rate
      interval: 60s
      successCondition: result[0] >= 0.99
      provider:
        prometheus:
          address: http://prometheus:9090
          query: |
            sum(rate(http_requests_total{
              service="{{args.service-name}}",
              status=~"2.."
            }[5m])) /
            sum(rate(http_requests_total{
              service="{{args.service-name}}"
            }[5m]))
```

## Flagger

CNCF project for progressive delivery on Kubernetes. Works with Istio, Linkerd, Nginx, Contour, Gloo, Kuma, and AWS App Mesh.

```
Flagger workflow:

1. Detects new version (image tag change)
2. Scales up canary deployment
3. Runs integration tests (webhook)
4. Shifts traffic incrementally
5. Analyzes metrics at each step
6. Promotes or rolls back
7. Scales down old version

Canary CRD:
  stepWeight: 5          (increase 5% each step)
  maxWeight: 50          (max canary weight before full promotion)
  interval: 1m           (time between steps)
  threshold: 5           (max failed checks before rollback)
  metrics:
    - name: request-success-rate
      thresholdRange:
        min: 99
    - name: request-duration
      thresholdRange:
        max: 500
```

## Comparison of Progressive Delivery Tools

```
┌──────────────────┬──────────────┬──────────────┬──────────────┐
│ Feature          │ Argo Rollouts│ Flagger      │ Spinnaker    │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Strategies       │ Canary, B/G  │ Canary, B/G, │ Canary, B/G, │
│                  │              │ A/B testing  │ Rolling      │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ K8s native       │ Yes (CRD)    │ Yes (CRD)    │ No (platform)│
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Traffic managers │ Istio, Nginx,│ Istio, Link, │ AWS, GCP, K8s│
│                  │ ALB, SMI     │ Nginx, App   │              │
│                  │              │ Mesh, Contour│              │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ Metric providers │ Prometheus,  │ Prometheus,  │ Kayenta      │
│                  │ Datadog, NR, │ Datadog,     │ (Prometheus, │
│                  │ CloudWatch   │ CloudWatch   │ Datadog, etc)│
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ GitOps compat    │ ArgoCD       │ Flux, ArgoCD │ Limited      │
├──────────────────┼──────────────┼──────────────┼──────────────┤
│ UI               │ Argo UI      │ Grafana      │ Full UI      │
│                  │ (plugin)     │ dashboards   │              │
└──────────────────┴──────────────┴──────────────┴──────────────┘
```

## Pros

- **Automated Safety**: metrics-driven promotion removes human error from release decisions
- **Flexible Strategies**: stepped, linear, exponential, and custom progressions fit different risk profiles
- **Multi-Signal Analysis**: combine latency, errors, saturation, and business KPIs for holistic health checks
- **GitOps Compatible**: Argo Rollouts and Flagger integrate natively with ArgoCD and Flux
- **Instant Rollback**: traffic shift reversal happens in seconds, not minutes
- **Composable Gates**: mix automated metrics, manual approvals, webhooks, and test suites
- **Platform Agnostic**: works with any traffic manager (Istio, Nginx, ALB, Linkerd)
- **Audit Trail**: every step, analysis result, and decision is recorded

## Cons

- **Infrastructure Requirements**: needs a traffic manager, metrics system, and rollout controller
- **Complexity**: more moving parts than a simple rolling update
- **Metric Quality**: garbage metrics lead to garbage decisions (false promotions or false rollbacks)
- **Statistical Significance**: low-traffic services need longer soak times at each step
- **Database Compatibility**: schema migrations must be compatible across both versions simultaneously
- **Configuration Sprawl**: AnalysisTemplates, Rollout specs, and metric queries add YAML overhead
- **Debugging Difficulty**: when a rollback happens, understanding why requires metric investigation
- **Cold Start**: first deployment has no baseline to compare against

## Use Cases

- **Mission-Critical Services**: payment processing, auth, and checkout services that cannot afford a bad deploy
- **High-Traffic APIs**: gradually shifting millions of requests with per-step validation
- **Platform Teams**: providing safe deployment primitives to application teams
- **Regulated Environments**: compliance requirements for controlled, auditable releases
- **Multi-Region Rollouts**: deploying to one region first, validating, then expanding
- **ML Model Serving**: gradually routing inference traffic to a new model version
- **Infrastructure Updates**: rolling out new sidecars, proxies, or runtime versions progressively
- **Dependency Upgrades**: validating new library versions with real production traffic
