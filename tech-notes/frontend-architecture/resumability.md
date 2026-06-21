# Resumability

## What is it?

Resumability is a frontend rendering technique that lets an application **pause execution on the server and resume it on the client without re-running any of the application code**. Instead of replaying the component tree in the browser to wire up event listeners and rebuild state (which is what [hydration](hydration-frontend.md) does), a resumable framework serializes everything the app needs — state, the reactivity graph, component boundaries, and the location of every event handler — directly into the HTML. The browser can then "resume" exactly where the server stopped.

The mental model is that a resumable app can be serialized at any point in its lifecycle and moved to a different VM (server to browser), where it simply continues. The result is near-zero JavaScript execution on page load: a fully interactive page can become live with as little as ~1KB of JavaScript, regardless of how large the application is.

## Who created it? When?

Resumability was popularized by **Qwik**, created by **Misko Hevery** (the original creator of Angular) at **Builder.io**. Hevery started exploring the idea of delaying client-side code execution in **January 2021**; it became a full-time effort when he joined Builder.io in **June 2022**, working alongside Adam Bradley and Manu Martinez-Almeida.

Qwik's first public release (**v0.1.0**) landed in **October 2022**, introducing resumability, fine-grained reactivity, and isomorphic rendering. **Qwik 1.0** was released in **May 2023**. While the underlying idea of serializing state into HTML had appeared in earlier research, Qwik was the first mainstream framework to make resumability its core architecture and to eliminate the hydration step entirely.

## How it works?

1. Server renders the full HTML and serializes app state into it (often in a trailing `<script type="qwik/json">`)
2. Event listeners are not attached; instead, their **location** is encoded as HTML attributes like `on:click="./chunk-abc.js#handler"`
3. Component boundaries and the reactivity graph are serialized inline with special attributes/comments
4. The browser displays the HTML and downloads a tiny (~1KB) loader, not the application code
5. The loader attaches a single global event listener and waits — no eager execution, no tree walk
6. On the first user interaction, the loader reads the attribute, lazily downloads just that handler's chunk, and runs it
7. Only the code actually needed for that interaction is ever downloaded and executed

```
Server                              Browser

┌────────────────┐                 ┌──────────────────────────────┐
│ Render HTML +  │   HTML w/        │ Display HTML (interactive,    │
│ serialize:     │   serialized     │ ~1KB loader only)             │
│  - state       │ ───────────────► │                               │
│  - listeners   │   state          │   no tree walk                │
│  - boundaries  │                  │   no eager JS execution       │
└────────────────┘                 └───────────────┬──────────────┘
                                                    │ user clicks
                                    ┌───────────────▼──────────────┐
                                    │ Loader reads on:click attr,   │
                                    │ lazy-loads ONLY that chunk     │
                                    │ ./chunk-abc.js#handler         │
                                    └───────────────┬──────────────┘
                                    ┌───────────────▼──────────────┐
                                    │ Run handler, resume state     │
                                    └──────────────────────────────┘
```

## Serialization

Serialization is the heart of resumability — it is what makes the server-to-browser handoff possible without re-execution. A resumable framework serializes three things into the HTML:

- **State**: application and component state is written directly into the HTML and referenced in place, including handling of cyclic references and shared objects in the reactivity graph
- **Listener locations**: instead of attaching handlers, the framework records *where* each handler lives as an attribute (e.g. `on:click="./chunk-abc.js#handler"`) so it can be fetched on demand
- **Component boundaries**: special comments/attributes mark where components start and end, so any component can resume independently of its parents

A key advantage is that **any component can be resumed without its parent's code being present** — unlike traditional hydration, where restoring a child requires restoring the whole ancestor chain first. The framework serializes only the necessary parts of the reactivity graph, so unused state never costs anything on the client.

## Pros

- **Near-zero startup JS**: a page becomes interactive with ~1KB of JavaScript regardless of app size
- **Constant startup cost**: time-to-interactive does not grow with application complexity
- **No hydration**: skips the expensive tree walk, listener re-attachment, and state reconstruction
- **Fine-grained lazy loading**: only the code for the exact interaction is downloaded, on demand
- **Excellent Core Web Vitals**: very low TBT (Total Blocking Time) and fast TTI
- **Resume any component independently**: no need to load parent components to make a child interactive
- **Great for large apps**: the bigger the app, the larger the win versus hydration

## Cons

- **Larger HTML payload**: serialized state and listener metadata inflate the HTML document
- **Serialization limits**: not everything serializes cleanly (functions, class instances, closures need care)
- **Newer paradigm**: smaller ecosystem and fewer learning resources than React/Vue
- **Mental model shift**: developers must think about what crosses the serialization boundary
- **Framework lock-in**: resumability is tied to frameworks built around it (primarily Qwik)
- **Network waterfalls**: many tiny lazy chunks can mean extra requests (mitigated by preloading/prefetch)
- **Debugging**: the lazy, code-on-demand model can be harder to reason about and trace

## Frameworks That Implement It

- **Qwik**: the reference implementation and the framework that defined the approach; Qwik City adds routing/meta-framework features
- **Qwik 2.0**: in progress, focused on a lighter core, faster serialization, and better DX
- **Astro (via `@qwikdev/astro`)**: brings resumability into Astro using **Qwik containers** instead of Astro's usual islands (see below)
- **React Server Components (partial overlap)**: server components ship no client JS, a related but distinct idea (no resume of interactivity)
- **Research / experimental**: several frameworks explore "resumability without serialization" and partial-resume strategies, but Qwik remains the production-ready option

### Resumability in Astro: Qwik Containers vs Islands

[Astro](island-architecture.md) is normally an **island architecture** framework — interactive components are hydrated islands wrapped in `<astro-island>` elements, each marked with a `client:*` directive (`client:load`, `client:visible`, etc.). The `@qwikdev/astro` integration changes this: Qwik components in Astro use **Qwik containers** rather than islands, and need **no client directives at all** because there is no hydration to schedule.

The practical differences:

- **No `client:*` directives**: Qwik components are resumable by default, so there is nothing to "turn on"
- **No `<astro-island>` elements**: to Astro, a Qwik container looks like static data; resumability is driven entirely by the serialized HTML
- **Fine-grained lazy loading everywhere**: instead of loading an island's full bundle, only the code for the triggered interaction is fetched
- **Same authoring DX**: components are written like normal Qwik components inside `.astro` pages

This makes Astro a way to get **resumable islands** — keeping Astro's static-first, content-focused output while replacing hydrated islands with zero-hydration Qwik containers. (The integration is still young; `@qwikdev/astro` was in alpha as of its early releases.)

## Who Uses It?

- **Builder.io**: the company behind Qwik, uses it for its visual headless CMS and marketing sites
- **Cloudflare** and **AWS**: noted among companies running Qwik in production
- Tracking tools (Wappalyzer) report on the order of a few thousand live sites using Qwik, concentrated in performance-sensitive, content-heavy, and edge-deployed apps
- Common adoption pattern: marketing pages, e-commerce storefronts, and edge-rendered sites where startup performance and Core Web Vitals directly affect conversion

## Comparison with Similar Approaches

### Resumability vs Hydration

| Aspect | Resumability | Hydration |
|---|---|---|
| Client work on load | Near zero | Re-execute component tree |
| JS shipped on load | ~1KB loader | Full framework + app code |
| Listeners | Lazy, on interaction | Attached eagerly on load |
| State | Serialized in HTML | Rebuilt by re-running code |
| Startup cost | Constant | Grows with app size |
| HTML payload | Larger (serialized state) | Smaller |
| Maturity | Newer | Established |

### Resumability vs Partial Hydration / Islands

| Aspect | Resumability | Island Architecture |
|---|---|---|
| Unit of laziness | Per event handler | Per island component |
| JS for interactive parts | Loaded on interaction | Loaded per island (eager or on visible) |
| Static content | Zero JS | Zero JS |
| Inter-component state | Shared reactivity graph | Isolated, needs coordination |
| Best for | Whole apps that must be cheap to start | Mostly-static pages with a few widgets |

### Resumability vs SPA (Client-Side Rendering)

| Aspect | Resumability | SPA |
|---|---|---|
| Initial load | Fast (HTML first, ~1KB JS) | Slow (download + run full bundle) |
| Time to Interactive | Near instant | Delayed by bundle execution |
| SEO | Built-in (server HTML) | Needs SSR/prerender |
| State on load | Resumed from HTML | Built fresh in browser |
| Best for | Performance-critical, content-rich apps | Highly interactive app-like UIs |

## When to Use What

- **Content-heavy or e-commerce sites where startup speed drives conversion**: resumability (Qwik)
- **Large apps where hydration cost has become the bottleneck**: resumability
- **Edge-rendered sites needing minimal client JS**: resumability
- **Mostly-static pages with a few interactive widgets**: [island architecture](island-architecture.md) is often simpler
- **Highly interactive, app-like dashboards with rich shared state**: a mature SPA/SSR stack may have a smoother ecosystem
- **Teams that need the largest ecosystem and hiring pool today**: React/Vue with selective or progressive [hydration](hydration-frontend.md)
