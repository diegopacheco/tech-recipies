# Micro Frontends

## What is it?

Micro frontends extend the microservices concept to the frontend. Instead of a single monolithic frontend application, the UI is composed of independently developed, tested, and deployed fragments owned by different teams. Each micro frontend encapsulates a vertical slice of the application — from the UI components down to the API calls — and can be built with different frameworks, deployed on different schedules, and maintained by autonomous teams.

## Who created it? When?

The term "micro frontends" was coined in the **ThoughtWorks Technology Radar** in **November 2016**. The concept builds on earlier patterns like portlets (Java, 2003) and composite UI. **Cam Jackson** wrote the definitive article on martinfowler.com in **2019**. **Webpack Module Federation** was introduced by **Zack Jackson** in **Webpack 5 (2020)**, becoming the most popular technical implementation. **single-spa** was created by **Joel Denning** in **2015** as a meta-framework for composing multiple SPA frameworks.

## How it works?

### Composition Approaches

```
1. Build-Time Composition (npm packages):

┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Team A       │  │ Team B       │  │ Team C       │
│ @app/header  │  │ @app/catalog │  │ @app/cart    │
│ (npm pkg)    │  │ (npm pkg)    │  │ (npm pkg)    │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └────────┬────────┴────────┬────────┘
                ▼                 ▼
         ┌──────────────────────────┐
         │   Shell App (builds all) │
         │   Single deploy unit     │
         └──────────────────────────┘

2. Runtime Composition (Module Federation / dynamic import):

┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Team A       │  │ Team B       │  │ Team C       │
│ header.js    │  │ catalog.js   │  │ cart.js      │
│ (CDN)        │  │ (CDN)        │  │ (CDN)        │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └────────┬────────┴────────┬────────┘
                ▼ (loaded at runtime)
         ┌──────────────────────────┐
         │   Shell App (thin host)  │
         │   Loads remotes on demand│
         └──────────────────────────┘

3. Server-Side Composition (SSI / Edge-Side Includes):

Browser Request ──► Edge/Server ──► Assembles fragments from:
                                      ├── header-service.internal/fragment
                                      ├── catalog-service.internal/fragment
                                      └── cart-service.internal/fragment
                  ◄── Composed HTML page
```

### Integration Patterns

```
┌────────────────────┬────────────┬──────────────┬───────────┬──────────────┐
│ Pattern            │ Isolation  │ Independence │ Perf Cost │ Complexity   │
├────────────────────┼────────────┼──────────────┼───────────┼──────────────┤
│ npm packages       │ None       │ Low (coupled │ None      │ Low          │
│ (build-time)       │            │ deploy)      │           │              │
├────────────────────┼────────────┼──────────────┼───────────┼──────────────┤
│ Module Federation  │ JS scope   │ High         │ Low       │ Medium       │
│ (Webpack/Vite)     │            │              │           │              │
├────────────────────┼────────────┼──────────────┼───────────┼──────────────┤
│ single-spa         │ JS scope   │ High         │ Medium    │ Medium-High  │
├────────────────────┼────────────┼──────────────┼───────────┼──────────────┤
│ iframes            │ Full       │ Very High    │ High      │ Low          │
│                    │ (process)  │              │           │              │
├────────────────────┼────────────┼──────────────┼───────────┼──────────────┤
│ Web Components     │ Shadow DOM │ High         │ Low       │ Medium       │
├────────────────────┼────────────┼──────────────┼───────────┼──────────────┤
│ Server-Side (ESI)  │ Full       │ Very High    │ Low       │ Medium       │
└────────────────────┴────────────┴──────────────┴───────────┴──────────────┘
```

## Webpack Module Federation

Introduced in Webpack 5. Allows a JavaScript application to dynamically load code from another application at runtime. Each app can expose modules and consume modules from others.

```
Host App (shell):
  - Loads remotes at runtime via remoteEntry.js
  - Declares shared dependencies (React, React DOM)
  - Routes to remote components

Remote App (micro frontend):
  - Exposes specific components/modules
  - Declares shared dependencies
  - Deployed independently with its own CI/CD

Shared dependencies:
  - React, React DOM loaded once (singleton)
  - Version negotiation at runtime
  - Fallback to local version if incompatible
```

**Vite** supports Module Federation via the `@module-federation/vite` plugin. **Rspack** has native Module Federation support.

## single-spa

A meta-framework that orchestrates multiple SPA frameworks on the same page. Each micro frontend registers as an "application" with lifecycle hooks (bootstrap, mount, unmount).

- Supports React, Vue, Angular, Svelte, and vanilla JS in the same page
- Route-based activation (each micro frontend owns URL paths)
- Shared dependencies via import maps or SystemJS
- Layout engine for composing apps into page regions

## Communication Between Micro Frontends

```
┌────────────────────┬──────────────────────────────────────────────┐
│ Method             │ How it works                                  │
├────────────────────┼──────────────────────────────────────────────┤
│ Custom Events      │ window.dispatchEvent / addEventListener       │
│                    │ Loosely coupled, browser-native               │
├────────────────────┼──────────────────────────────────────────────┤
│ Shared State       │ Shared Redux/Zustand store or pub/sub bus    │
│                    │ Tighter coupling but consistent state         │
├────────────────────┼──────────────────────────────────────────────┤
│ URL / Query Params │ Shared state via the URL bar                 │
│                    │ Bookmarkable, simple, limited capacity       │
├────────────────────┼──────────────────────────────────────────────┤
│ Props Down         │ Parent shell passes props to children        │
│                    │ Works with Module Federation and Web Components│
├────────────────────┼──────────────────────────────────────────────┤
│ postMessage        │ For iframe-based micro frontends              │
│                    │ Full isolation, serialization overhead         │
└────────────────────┴──────────────────────────────────────────────┘
```

## Who Uses It?

- **IKEA**: Module Federation for independently deployed product pages
- **Spotify**: iframes for embedded widgets, independent squad ownership
- **Zalando**: Project Mosaic for server-side composed micro frontends
- **DAZN**: single-spa with multiple React apps
- **SAP**: Luigi framework for enterprise micro frontends
- **Bit.dev**: component-driven micro frontends with independent versioning

## Pros

- **Independent Deployment**: teams deploy without coordinating with other teams
- **Team Autonomy**: each team owns a vertical slice end-to-end
- **Technology Freedom**: teams can choose different frameworks (React, Vue, Svelte)
- **Incremental Migration**: migrate from legacy frontend piece by piece, not all at once
- **Scalable Teams**: multiple teams work on the same product without merge conflicts
- **Fault Isolation**: one micro frontend crashing does not take down the entire page
- **Independent Scaling**: each fragment can be cached and scaled separately

## Cons

- **Payload Duplication**: multiple frameworks or duplicate dependencies increase bundle size
- **Shared State Complexity**: cross-micro-frontend state management is harder than single-app state
- **Inconsistent UX**: different teams can drift on design, behavior, and accessibility
- **Operational Overhead**: more repos, more CI/CD pipelines, more deployments to manage
- **Performance Cost**: loading multiple entry points, style isolation, and runtime composition add overhead
- **Debugging Difficulty**: tracing bugs across independently deployed fragments is harder
- **Dependency Versioning**: shared library version mismatches cause runtime errors
- **Over-Engineering Risk**: most teams do not need micro frontends, a well-structured monolith is simpler

## Use Cases

- **Large Organizations**: 5+ frontend teams working on the same product (e-commerce, banking, SaaS platforms)
- **Legacy Migration**: incrementally replacing a legacy frontend (jQuery, Angular.js) with a modern framework
- **Multi-Brand Platforms**: shared shell with brand-specific micro frontends
- **Marketplace Platforms**: seller dashboards, buyer pages, and admin panels as independent micro frontends
- **Enterprise Portals**: composing widgets from different business units into a unified dashboard
- **A/B Testing at Scale**: deploying experimental UIs independently without risking the full application
