# Island Architecture

## What is Island Architecture?

Island Architecture is a frontend rendering pattern where a page is mostly static HTML with isolated interactive regions called **islands**. Each island is an independently hydrated component that loads its own JavaScript, while the rest of the page remains pure HTML with zero JavaScript. The term was coined by **Katie Sylor-Miller** in 2019 and later popularized by **Jason Miller** (creator of Preact) in 2020.

The key idea is that most of a web page does not need JavaScript. A blog post, a product description, or a marketing page is mostly static content. Only specific parts like a search bar, a shopping cart, or a comment section need interactivity. Island Architecture sends static HTML for the entire page and only ships JavaScript for those interactive pieces.

## How it Works

1. Server renders the full page as static HTML
2. Interactive regions are marked as islands in the template
3. Each island has its own JavaScript bundle that loads independently
4. Islands hydrate on their own schedule (on load, on visible, on interaction)
5. Static regions never load any JavaScript

```
┌──────────────────────────────────────────────┐
│  Static HTML (no JS)                         │
│                                              │
│  ┌─────────────────┐   ┌──────────────────┐  │
│  │  Island: Search  │   │  Island: Cart    │  │
│  │  (hydrated, JS)  │   │  (hydrated, JS)  │  │
│  └─────────────────┘   └──────────────────┘  │
│                                              │
│  Static HTML (no JS)                         │
│  Static HTML (no JS)                         │
│  Static HTML (no JS)                         │
│                                              │
│  ┌──────────────────────────────────────┐    │
│  │  Island: Comments (hydrated, JS)      │    │
│  └──────────────────────────────────────┘    │
│                                              │
│  Static HTML (no JS)                         │
└──────────────────────────────────────────────┘
```

## Pros

- **Minimal JavaScript**: only interactive parts ship JS, drastically reducing bundle size
- **Fast page loads**: static HTML renders instantly, no waiting for JS to parse and execute
- **Independent hydration**: each island loads and becomes interactive on its own schedule
- **Progressive enhancement**: page is usable even before JavaScript loads
- **Better Core Web Vitals**: lower TTI (Time to Interactive), better LCP, lower TBT
- **SEO friendly**: full HTML is available immediately for crawlers
- **Parallel loading**: islands can hydrate in parallel without blocking each other
- **Granular caching**: static parts and islands can be cached separately

## Cons

- **Limited shared state**: islands are isolated, sharing state between them requires extra coordination
- **Framework lock-in**: most implementations are tied to specific frameworks (Astro, Fresh)
- **Not ideal for highly interactive apps**: apps where everything is interactive gain little from this pattern
- **Mental model shift**: developers used to SPA thinking need to rethink component boundaries
- **Inter-island communication**: passing data between islands requires pub/sub, events, or shared stores
- **Tooling maturity**: newer pattern with fewer established patterns for complex scenarios

## Frameworks That Implement It

- **Astro**: the most popular island architecture framework, supports React, Vue, Svelte, and Solid islands
- **Fresh** (Deno): built-in island architecture for Deno with Preact
- **Marko**: eBay's framework with partial hydration capabilities
- **Eleventy + is-land**: web component-based islands for static sites
- **Qwik**: takes a related approach with resumability instead of hydration

## Who Uses It?

- **Astro** sites: used by companies like Google (Firebase docs), Porsche, NordVPN, The Guardian
- **eBay**: uses Marko's partial hydration for product pages
- **Deno**: Fresh framework used for deno.land and Deno Deploy dashboard
- **IKEA**: uses island-like patterns for product catalog pages
- **Shopify Hydrogen**: adopts partial hydration concepts for storefront rendering

## Comparison with Similar Approaches

### Island Architecture vs Single Page Application (SPA)

| Aspect | Island Architecture | SPA |
|---|---|---|
| Initial load | Fast (static HTML) | Slow (full JS bundle) |
| JavaScript shipped | Only for islands | Entire application |
| Navigation | Full page or partial | Client-side routing |
| SEO | Built-in (HTML first) | Requires SSR/prerender |
| Interactivity | Per-island | Full page |
| Best for | Content-heavy sites | Highly interactive apps |

### Island Architecture vs Server-Side Rendering (SSR)

| Aspect | Island Architecture | SSR |
|---|---|---|
| Hydration | Partial (islands only) | Full page hydration |
| JavaScript sent | Minimal (per island) | Full framework + app code |
| Time to Interactive | Fast (small JS) | Slower (full hydration) |
| Server load | Low (mostly static) | Higher (renders every request) |
| Best for | Mostly static + some interactivity | Dynamic content-heavy apps |

### Island Architecture vs Static Site Generation (SSG)

| Aspect | Island Architecture | SSG |
|---|---|---|
| Interactivity | Islands provide rich interactivity | Limited without JS |
| JavaScript | Only for islands | None or manually added |
| Build output | HTML + island bundles | Pure HTML/CSS |
| Complexity | Moderate | Low |
| Best for | Static content with interactive widgets | Fully static content |
