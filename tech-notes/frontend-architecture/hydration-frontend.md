# Hydration in Frontend

## What is Hydration?

Hydration is the process of attaching JavaScript behavior to server-rendered HTML in the browser. When a server sends pre-rendered HTML to the client, the page is visible but not interactive. Hydration takes that static HTML and "wakes it up" by attaching event listeners, restoring component state, and making the page fully interactive. The term comes from the idea of adding "water" (JavaScript logic) to "dry" (static) HTML.

## How it Works

1. Server renders the full HTML for the page (SSR or SSG)
2. Browser receives and displays the HTML immediately (fast First Contentful Paint)
3. Browser downloads the JavaScript bundle
4. Framework walks the existing DOM, matches it to the component tree
5. Event listeners are attached, state is initialized, and the page becomes interactive
6. The page is now fully hydrated and behaves like a client-side application

```
Server                          Browser

┌──────────┐                   ┌──────────────────────┐
│ Render   │  HTML Response    │ Display HTML          │
│ HTML     │ ────────────────► │ (visible, not         │
│          │                   │  interactive)         │
└──────────┘                   └──────────┬───────────┘
                                          │
                               ┌──────────▼───────────┐
                               │ Download JS Bundle    │
                               └──────────┬───────────┘
                                          │
                               ┌──────────▼───────────┐
                               │ Hydration:            │
                               │  - Walk DOM           │
                               │  - Attach listeners   │
                               │  - Restore state      │
                               └──────────┬───────────┘
                                          │
                               ┌──────────▼───────────┐
                               │ Fully Interactive     │
                               └──────────────────────┘
```

## Types of Hydration

### Full Hydration
The entire page is hydrated at once. The framework re-processes the whole component tree, attaches all event listeners, and initializes all state. This is the default in React, Vue, and Angular with SSR. Simple but expensive for large pages.

### Progressive Hydration
Components are hydrated incrementally based on priority. Critical above-the-fold components hydrate first, while below-the-fold components hydrate later (on scroll, on idle, or on interaction). Reduces Time to Interactive by spreading the work over time.

### Partial Hydration
Only interactive components are hydrated. Static parts of the page never receive JavaScript. This is the approach used by Island Architecture (Astro, Fresh). The most efficient approach for content-heavy pages.

### Selective Hydration (React 18+)
React can prioritize which parts of the page to hydrate first based on user interaction. If a user clicks on a component that is not yet hydrated, React prioritizes hydrating that component. Uses `Suspense` boundaries to define hydration units.

### Resumability (Qwik)
Instead of replaying the component tree, the framework serializes the application state and event listener locations into the HTML. The browser can resume where the server left off without re-executing component code. No hydration step at all, achieving near-zero JavaScript execution on page load.

## Pros

- **Fast visual render**: users see content immediately from server HTML
- **SEO friendly**: search engines index the pre-rendered HTML
- **Works with any SSR framework**: React, Vue, Angular, Svelte all support it
- **Progressive enhancement**: page is readable before JavaScript loads
- **Familiar mental model**: developers write components normally, hydration is handled by the framework

## Cons

- **Uncanny valley**: page looks interactive but is not until hydration completes (buttons that don't respond)
- **Double work**: the framework re-executes component logic on the client to reconstruct the tree
- **TTI delay**: Time to Interactive can be significantly delayed on large pages
- **Bundle size**: full hydration requires shipping the entire framework and component code
- **Memory overhead**: the entire component tree exists in memory after hydration
- **Hydration mismatch errors**: if server and client render different HTML, the framework throws errors

## Hydration Strategies by Framework

| Framework | Default Hydration | Advanced Options |
|---|---|---|
| React 18+ | Full hydration | Selective hydration with Suspense |
| Next.js | Full hydration | React Server Components (no hydration for server components) |
| Vue / Nuxt | Full hydration | Lazy hydration via plugins |
| Angular | Full hydration | Deferred views (@defer) |
| Svelte / SvelteKit | Full hydration | Partial hydration planned |
| Astro | Partial (islands) | client:load, client:visible, client:idle, client:media |
| Qwik | Resumability (no hydration) | Fine-grained lazy loading |
| Fresh (Deno) | Partial (islands) | Islands hydrate independently |
| Solid / SolidStart | Full hydration | Fine-grained reactivity reduces hydration cost |

## Comparison of Hydration Approaches

### Full Hydration vs Partial Hydration

| Aspect | Full Hydration | Partial Hydration |
|---|---|---|
| JavaScript shipped | Entire app | Only interactive parts |
| TTI | Slower (processes all components) | Faster (fewer components) |
| Complexity | Simple (default behavior) | Requires marking interactive boundaries |
| State sharing | Easy (single tree) | Harder (isolated islands) |
| Best for | Interactive apps | Content-heavy sites |

### Full Hydration vs Resumability

| Aspect | Full Hydration | Resumability (Qwik) |
|---|---|---|
| Client work on load | Re-execute component tree | Near zero |
| JavaScript execution | Eager (all at once) | Lazy (on interaction) |
| Startup cost | High | Minimal |
| HTML payload size | Normal | Larger (serialized state) |
| Framework maturity | Established | Newer |
| Best for | SPAs and dynamic apps | Performance-critical pages |

### Progressive Hydration vs Selective Hydration

| Aspect | Progressive Hydration | Selective Hydration |
|---|---|---|
| Trigger | Developer-defined (scroll, idle) | User interaction |
| Priority | Static priority order | Dynamic based on user behavior |
| Framework | Multiple (via libraries) | React 18+ with Suspense |
| Granularity | Component or route level | Suspense boundary level |
| Best for | Predictable load patterns | Unpredictable user interactions |
