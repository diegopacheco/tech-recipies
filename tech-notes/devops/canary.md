# Canary Deployments

## What is it?

A canary deployment is a release strategy where a new version of a service is rolled out to a small subset of users or traffic before being promoted to the entire fleet. The new version (the canary) runs alongside the current stable version. Traffic is gradually shifted — starting at 1-5% — while key metrics (error rate, latency, CPU, business KPIs) are monitored. If the canary performs well, traffic is increased incrementally until it reaches 100%. If metrics degrade, the canary is rolled back immediately with minimal user impact.

The name comes from coal miners who carried canary birds into mines. If the canary died from toxic gases, miners knew to evacuate. Similarly, a canary deployment detects problems with a small blast radius before they affect all users.

## How it works?

### Deployment Flow

```
Step 1: Deploy canary (small % of traffic)

┌──────────────┐     95% traffic     ┌──────────────────┐
│   Load       │────────────────────►│ Stable (v1)      │
│   Balancer   │                     │ 10 pods          │
│              │     5% traffic      ├──────────────────┤
│              │────────────────────►│ Canary (v2)      │
│              │                     │ 1 pod            │
└──────────────┘                     └──────────────────┘
                                            │
                                     Monitor metrics:
                                     - error rate
                                     - latency p99
                                     - CPU/memory
                                     - business KPIs

Step 2: Gradually increase (if healthy)

  5% ──► 10% ──► 25% ──► 50% ──► 75% ──► 100%
                                            │
                                     Canary becomes stable
                                     Old version removed

Step 2 (alt): Rollback (if unhealthy)

  5% ──► metrics degrade ──► 0% (instant rollback)
                              │
                       All traffic back to v1
```

### Traffic Shifting Mechanisms

```
┌────────────────────────┬────────────────────────────────────────────┐
│ Mechanism              │ How it works                                │
├────────────────────────┼────────────────────────────────────────────┤
│ Replica count          │ 1 canary pod out of 10 total = ~10%        │
│ (Kubernetes native)    │ Coarse-grained, depends on pod count       │
├────────────────────────┼────────────────────────────────────────────┤
│ Ingress weight         │ Nginx/Traefik ingress annotations with     │
│                        │ weight-based routing (canary-weight: 5)    │
├────────────────────────┼────────────────────────────────────────────┤
│ Service mesh           │ Istio VirtualService, Linkerd TrafficSplit │
│                        │ Fine-grained percentage-based routing      │
├────────────────────────┼────────────────────────────────────────────┤
│ Load balancer           │ AWS ALB weighted target groups, GCP        │
│                        │ traffic splitting, Cloudflare load balance │
├────────────────────────┼────────────────────────────────────────────┤
│ Feature flags          │ Application-level routing based on user     │
│                        │ attributes (LaunchDarkly, Unleash, Flagd)  │
├────────────────────────┼────────────────────────────────────────────┤
│ DNS weighted routing   │ Route 53 weighted records, low granularity │
└────────────────────────┴────────────────────────────────────────────┘
```

## Canary Automation Tools

### Flagger (CNCF)

Automates canary analysis and promotion for Kubernetes. Works with Istio, Linkerd, Nginx, Contour, Gloo, and AWS App Mesh.

```
┌─────────────────────────────────────────────┐
│                  Flagger                     │
│                                             │
│  Canary CRD ──► Controller ──► Mesh/Ingress │
│                     │                       │
│              ┌──────▼──────┐                │
│              │ Metrics     │                │
│              │ Analysis    │                │
│              │ (Prometheus,│                │
│              │  Datadog,   │                │
│              │  CloudWatch)│                │
│              └──────┬──────┘                │
│                     │                       │
│              pass? ─┼─ fail?                │
│              │      │                       │
│           promote  rollback                 │
└─────────────────────────────────────────────┘
```

### Argo Rollouts

Kubernetes controller that provides advanced deployment strategies (canary, blue-green) as a replacement for Deployments.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 5
        - pause: { duration: 5m }
        - setWeight: 20
        - pause: { duration: 5m }
        - setWeight: 50
        - pause: { duration: 10m }
        - setWeight: 100
      analysis:
        templates:
          - templateName: success-rate
        startingStep: 1
```

### Spinnaker

Netflix's continuous delivery platform. Supports canary analysis via Kayenta (Automated Canary Analysis).

## Key Metrics to Monitor

```
┌───────────────────────┬──────────────────────────────────────────────┐
│ Metric Category       │ What to watch                                │
├───────────────────────┼──────────────────────────────────────────────┤
│ Error rate            │ HTTP 5xx rate, exception rate, panic rate    │
│                       │ Compare canary vs stable                     │
├───────────────────────┼──────────────────────────────────────────────┤
│ Latency               │ p50, p95, p99 response time                 │
│                       │ Regression = fail                            │
├───────────────────────┼──────────────────────────────────────────────┤
│ Saturation            │ CPU, memory, connection pool utilization     │
│                       │ Higher than stable = investigate             │
├───────────────────────┼──────────────────────────────────────────────┤
│ Traffic               │ Request rate reaching the canary             │
│                       │ Verify expected traffic split                │
├───────────────────────┼──────────────────────────────────────────────┤
│ Business KPIs         │ Conversion rate, checkout success, revenue   │
│                       │ per request (domain-specific)                │
├───────────────────────┼──────────────────────────────────────────────┤
│ Custom signals        │ Cache hit rate, queue depth, retry rate      │
│                       │ Application-specific health indicators       │
└───────────────────────┴──────────────────────────────────────────────┘
```

## Pros

- **Small Blast Radius**: only a fraction of users see the new version initially
- **Real Production Validation**: tests with real traffic, real data, real dependencies
- **Fast Rollback**: revert traffic instantly without redeploying
- **Data-Driven Promotion**: metrics determine whether to proceed or abort
- **Continuous Delivery**: enables frequent, safe releases
- **Automated Analysis**: tools like Flagger and Argo Rollouts automate the promote/rollback decision
- **Gradual Confidence**: incremental traffic shift builds confidence before full rollout
- **Compatible with GitOps**: Argo Rollouts and Flagger integrate with ArgoCD and Flux

## Cons

- **Complexity**: requires traffic splitting infrastructure (mesh, ingress, LB)
- **Monitoring Dependency**: meaningless without good observability (metrics, alerting, dashboards)
- **Stateful Services**: database migrations and stateful changes are hard to canary
- **Low Traffic Problem**: 5% of low-traffic services may be too few requests for statistical significance
- **Session Affinity**: users may see different versions across requests without sticky sessions
- **Multiple Versions Running**: two versions running simultaneously complicates debugging and logging
- **Slow Rollout**: gradual traffic shift takes longer than a simple rolling update
- **False Confidence**: canary may pass with 5% traffic but fail at 100% due to load-dependent bugs

## Use Cases

- **API Services**: gradually shifting traffic to a new API version with latency and error rate gates
- **Frontend Applications**: serving a new UI to a percentage of users via CDN or edge routing
- **Database Driver Updates**: testing new connection pool behavior with a small subset of traffic
- **Infrastructure Changes**: new kernel, new runtime, new sidecar version on a few pods first
- **Machine Learning Models**: A/B testing model versions with real traffic and measuring prediction quality
- **Breaking Changes**: validating backward compatibility of API changes with real clients
- **Performance Optimization**: comparing resource usage and latency between optimized and original versions
- **Third-Party Dependency Updates**: testing new SDK versions with production traffic
