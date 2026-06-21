# HTML First

## What is it?

HTML First is a style of building web software that **favours the native capabilities and languages of the browser and reduces the layers of abstraction (extra languages and toolchains) stacked on top of them**. Instead of starting from JavaScript and a framework like React, you start from HTML, reach for CSS next, and only drop down to JavaScript when the platform genuinely cannot do the job natively.

The core observation is that while the industry spent a decade adopting heavy client-side frameworks, the standards bodies (W3C, WHATWG, IETF, TC39) quietly shipped thousands of improvements to HTML, CSS, and the browser itself. Many of those additions solved the exact problems frameworks were originally invented to paper over (async requests, DOM updates, dialogs, form validation, lazy loading). HTML First asks the question: *"Is all of the extra machinery still necessary today?"* — and answers that you can build beautiful, fast, accessible web software using primarily the native languages of the web, complemented by small libraries only where needed.

It is a **philosophy / set of principles**, not a framework. It overlaps heavily with hypermedia-driven development ([server-driven UI](server-driver-ui.md)), progressive enhancement, and "the principle of least power."

## Who created it? When?

The **HTML First Manifesto** was published by **Tony Ennis** at **html-first.com in 2023**. The site is written as a personal argument: it exists as "an accelerant for those who are already html-curious but lacking the language or concepts to harden their own thinking or communicate with their colleagues" — explicitly not as an attempt to convert people who are happy with the React way.

The ideas were given academic treatment by **Juho Vepsäläinen** (Aalto University, creator of Sidewind and author of *SurviveJS*) in the paper **"The Case for HTML First Web Development" (2026)**, submitted to the *Journal of Web Engineering*. That paper restates the manifesto's six principles, connects them to progressive enhancement (Gustafson, 2003) and the Progressive Complexity Manifesto (2025), and backs them with case studies. HTML First also draws on much older lineage: graceful degradation, progressive enhancement, and Berners-Lee's original vision of the web as a hypermedia document system.

## How it works?

1. Reach for **HTML** first — structure, semantics, and as much behaviour as the platform now provides natively
2. Reach for **CSS** next — styling, and increasingly interaction (`:target`, `:has()`, transitions) without scripting
3. Reach for **JavaScript** last — only for what HTML and CSS genuinely cannot express
4. Move application logic and state to the **server**; let the server return HTML, not JSON
5. Keep client-side state minimal; persist and validate on the server
6. When you do need a library, prefer **light ones that extend HTML's own vocabulary** (attributes) over frameworks that introduce their own lexicon and build step

```
The principle of least power (climb only when you must)

        ┌─────────────────────────────┐
        │        JavaScript            │  ← last resort
        │   (only what the platform    │     small libs, on demand
        │    cannot do natively)       │
        ├─────────────────────────────┤
        │            CSS               │  ← styling + much interaction
        │   :has() :target popover     │
        ├─────────────────────────────┤
        │            HTML              │  ← start here, do as much
        │  <details> <dialog> forms    │     as possible
        │  semantic elements, links    │
        └─────────────────────────────┘

Request flow (hypermedia style)

  Browser ──(click/submit)──► Server renders HTML fragment
     ▲                             │
     └────── swap fragment into DOM (htmx) ◄──┘
            no JSON, no client re-render
```

## The Six Principles

1. **Apply the principle of least power** — favour technologies from simple to complex: HTML → CSS → JavaScript. Prefer the simpler tool, while accepting more complex ones may still be needed.
2. **Prefer "vanilla" approaches over external frameworks** — many tasks, even dynamic ones (e.g. a "show more" button), can be done with plain HTML, so they should be.
3. **Avoid build steps where possible** — modern tooling introduced a compile step; skipping it simplifies development and deployment.
4. **Minimise unnecessary client-side state** — push state to the server, persist and validate there, instead of recreating complex SPA state in the browser.
5. **Retain the View-Source affordance** — SPAs obscure what actually runs in the browser; staying close to web standards keeps pages debuggable directly in the browser.
6. **If you must use libraries, prefer ones that re-purpose existing concepts over those that invent their own lexicon** — e.g. state/behaviour libraries that extend HTML attribute semantics rather than replacing them.

## Native HTML Patterns It Leans On

- **Foldable containers**: `<details>` / `<summary>` for accordions and "show more" with zero JS
- **Semantic elements**: `<nav>`, `<article>`, `<section>`, `<main>` for structure and accessibility
- **Form validation**: native constraint validation (`required`, `pattern`, `type=email`, `:invalid`) instead of JS validators
- **Dialogs and popovers**: the `<dialog>` element and the Popover API for modals and menus
- **Custom attributes / data attributes**: hooks for light behaviour, and Web Components for reusable encapsulated widgets (see [web components](web-components.md))
- **Light libraries**: when HTML alone falls short, complement it with **Alpine.js** (state via `x-data`/`x-show` attributes) or **htmx** (hypermedia: `hx-get`/`hx-post` swap server HTML into the DOM)

## Complementary Libraries / Tools

- **htmx**: extends HTML attributes to do AJAX, swaps, and hypermedia exchanges — server returns HTML, not JSON
- **Alpine.js**: minimal, attribute-based state and reactivity sprinkled directly into markup
- **Hotwire (Turbo + Stimulus)**: Rails' HTML-over-the-wire stack, the same philosophy in a fuller package
- **Unpoly**: progressive-enhancement library for server-rendered apps
- **Sidewind**: tiny reactive state via HTML attributes (Vepsäläinen)
- **Web Components / Lit**: native custom elements for encapsulated, framework-agnostic widgets
- **Datastar, fixi, and other micro hypermedia libraries**: newer entrants in the same space

## Pros

- **Less code**: real-world htmx ports report 17–78% smaller codebases (see case studies below)
- **Fewer dependencies and no build step**: less tooling, faster builds, simpler deploys
- **Better performance**: less JavaScript to ship, parse, and execute → better Core Web Vitals
- **Accessibility by default**: semantic HTML and native controls are accessible out of the box
- **Debuggability**: View-Source still means something; what you see is what runs
- **SEO friendly**: full HTML is present immediately for crawlers
- **Longevity**: standards-based code rots more slowly than framework-coupled code
- **Lower cognitive load**: one mental model (HTML) instead of a framework's many concepts
- **Great for AI agents**: semantic HTML is more legible to crawlers, screen readers, and LLM agents

## Cons

- **Not a fit for highly interactive apps**: rich, app-like UIs with deep client state still benefit from a framework — Gumroad evaluated htmx and rejected it for being too limited for their interactivity needs
- **Server round-trips**: hypermedia swaps mean more requests; latency-sensitive UIs may feel less instant than optimistic client updates
- **Smaller ecosystem**: fewer ready-made components and hiring pool than React/Vue
- **Logic moves to the backend**: simplifies the client but shifts complexity (and a language change) to the server
- **Browser support edges**: a few native features (Popover API, some CSS) still need fallbacks
- **Mental-model shift**: developers trained "JavaScript first" must re-learn what the platform now does natively
- **Minority position**: still a small fraction of the industry, with less institutional momentum

## Real-World Case Studies

Documented htmx ports (collected in Vepsäläinen's paper):

| Port | Result |
|---|---|
| React → htmx (SaaS) | Codebase **−67%**, JS dependencies **−96%**, build time **−88%** (40s→5s), TTI roughly halved, memory ~halved |
| React → htmx (SaaS) | Codebase **−61%**, files **−72%**; team dropped Figma and built UIs directly in HTML |
| Next.js → htmx (URL shortener) | Dependencies **−87%** (24→3), codebase **−17%**, build step removed, page weight **−85%+** |
| WebAssembly → htmx (SaaS) | Codebase **−78%**, Rust packages 8→1, weekly bug reports ~5→1, faster feature work |

**Yle benchmark** (Finnish public broadcaster landing page, rebuilt HTML First and measured with Lighthouse):

| Metric | Original | Modified |
|---|---|---|
| Performance score | 58 | 90 |
| LCP | 10.2s | 3.4s |
| TBT | 310ms | 0ms |
| FCP | 4.4s | 2.0s |

The counter-example: **Gumroad** considered htmx and chose against it, because their high interactivity demands and need for ecosystem support made a heavier framework the better fit.

## Comparison with Similar Approaches

### HTML First vs SPA (React/Vue)

| Aspect | HTML First | SPA |
|---|---|---|
| Starting language | HTML, then CSS, then JS | JavaScript + framework |
| Where state lives | Mostly server | Mostly client |
| Data over the wire | HTML fragments | JSON |
| Build step | Avoided where possible | Required |
| Initial load | Fast (HTML first) | Slow (download + run bundle) |
| Best for | Content-rich, form-driven, mostly-static apps | Highly interactive, app-like UIs |

### HTML First vs Island Architecture

| Aspect | HTML First | [Island Architecture](island-architecture.md) |
|---|---|---|
| Default | Plain HTML, enhance as needed | Static HTML with hydrated islands |
| Interactivity | Native HTML + light libs/hypermedia | Per-island framework components |
| Framework | Optional / minimal | Usually required (Astro, Fresh) |
| Build step | Often none | Yes |
| Overlap | Both minimise JavaScript; islands are one way to do HTML First selectively |

### HTML First vs Resumability

| Aspect | HTML First | [Resumability](resumability.md) |
|---|---|---|
| How interactivity arrives | Native HTML + server round-trips | Serialized state resumed on the client |
| Client JS on load | Tiny light libs (htmx/Alpine) | ~1KB loader |
| Framework | Optional | Required (Qwik) |
| State | On the server | Serialized into HTML, resumed |
| Best for | Content/form apps, minimal tooling | Large apps that must be cheap to start |

### HTML First vs Progressive Enhancement

| Aspect | HTML First | Progressive Enhancement |
|---|---|---|
| Origin | Manifesto, 2023 | Gustafson, 2003 |
| Emphasis | "Use HTML first; the platform caught up" | Content → presentation → behaviour layers |
| Relationship | A modern restatement; principle 1–2 are essentially progressive enhancement |

## When to Use What

- **Content-heavy or media sites where startup speed and hosting cost matter**: HTML First (see Yle results)
- **Form-driven CRUD apps, dashboards with server-owned state**: HTML First with htmx / Hotwire
- **Teams wanting to delete a build step and shrink the dependency tree**: HTML First
- **A few interactive widgets on an otherwise static page**: native HTML + Alpine, or [island architecture](island-architecture.md)
- **Highly interactive, app-like UIs with rich client state**: a mature SPA, or [resumability](resumability.md) for startup cost
- **Avoiding the cost of [hydration](hydration-frontend.md) altogether**: HTML First sidesteps it by shipping little JS in the first place
