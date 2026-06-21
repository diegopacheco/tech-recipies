# htmx

## What is it?

htmx is a small, dependency-free JavaScript library that **extends HTML so that any element can issue an HTTP request, in response to any event, using any HTTP verb, and swap the returned HTML into any part of the page**. The server replies with HTML fragments, not JSON, and htmx places them into the DOM — no client-side rendering, no virtual DOM, no JSON-to-component mapping.

The core insight is that HTML already has two hypermedia controls — the anchor (`<a>`) and the form (`<form>`) — but they are deliberately limited: they only fire on click or submit, only do GET and POST, and always replace the entire screen. htmx removes those four arbitrary restrictions and generalizes hypermedia back into the language. The result is a **Hypermedia-Driven Application (HDA)**: an interactive app whose interactivity is expressed in HTML attributes and driven by HTML exchanged over the wire.

It is a concrete **library** (~14 kB minified+gzipped, no dependencies, BSD 0-clause / public-domain-equivalent license), and it is the most prominent tool in the [HTML First](html-first.md) and [server-driven UI](server-driver-ui.md) movements.

## Who created it? When?

htmx was created by **Carson Gross**, a software engineer and professor at Montana State University. It descends from **intercooler.js**, a library he started in **2013** that added similar attribute-driven AJAX to HTML but depended on jQuery.

During COVID, Gross rewrote intercooler from scratch in vanilla JavaScript — dropping the jQuery dependency now that the browser runtime had caught up — and released **htmx 1.0.0 on November 24, 2020**. **htmx 2.0.0** followed on **June 17, 2024**, with the current stable line at **2.0.x** (2.0.9, April 2026).

Gross also wrote the companion scripting language **_hyperscript** and co-authored the free book **"Hypermedia Systems"** (with Adam Stepinski and Deniz Akşimşek, at hypermedia.systems), which lays out the theory: REST as Roy Fielding actually described it, and **HATEOAS** (Hypermedia As The Engine Of Application State).

## How it works?

1. Put `hx-*` attributes on ordinary HTML elements
2. An event (`hx-trigger`) on that element fires an AJAX request to a URL (`hx-get`, `hx-post`, …)
3. The server renders and returns an **HTML fragment**
4. htmx swaps that fragment into a target element (`hx-target`) using a swap strategy (`hx-swap`)
5. No JSON, no client re-render, no manual DOM code

```
HTML's native hypermedia (the limits htmx removes)

   <a href>      ── click only ── GET only ── replace whole page
   <form>        ── submit only ─ GET/POST ── replace whole page

htmx generalizes all four axes:

   ANY element ── ANY event ── ANY verb ── swap into ANY target

Request flow

  ┌──────────┐  click/keyup/load/poll   ┌─────────────────────┐
  │ <button  │ ───────hx-get──────────► │  Server renders an   │
  │  hx-get  │                          │  HTML fragment       │
  │  hx-target hx-swap ◄────HTML────────┤  (not JSON)          │
  └──────────┘   swap into the DOM      └─────────────────────┘
        no virtual DOM, no client templating, no JSON mapping
```

```html
<button hx-get="/messages" hx-target="#out" hx-swap="innerHTML">
  Load messages
</button>
<div id="out"></div>
```

## Core Attributes

- **`hx-get` / `hx-post` / `hx-put` / `hx-patch` / `hx-delete`**: issue a request with that HTTP verb to a URL
- **`hx-trigger`**: which event fires the request (`click`, `keyup changed delay:500ms`, `load`, `every 2s` polling, …)
- **`hx-target`**: which element receives the response (a CSS selector, `this`, `closest`, `next`, `find`)
- **`hx-swap`**: how to place the response — `innerHTML` (default), `outerHTML`, `beforebegin`, `afterbegin`, `beforeend`, `afterend`, `delete`, `none`
- **`hx-swap-oob`**: "out of band" — let a response update several disjoint parts of the page at once
- **`hx-boost`**: progressively enhance normal links/forms into AJAX requests (graceful fallback if JS is off)
- **`hx-push-url`**: push the new URL into browser history so back/forward and bookmarking work
- **`hx-select`, `hx-vals`, `hx-indicator`, `hx-confirm`**: pick part of the response, add request params, show a loading indicator, confirm before sending

## The Hypermedia Idea

htmx is a tool, but it carries a philosophy:

- **HATEOAS** — the server sends back hypermedia (HTML) that already encodes the available next actions; the client needs no out-of-band knowledge of the API. This is REST as Roy Fielding defined it, not "REST = JSON over HTTP."
- **Locality of Behaviour (LoB)** — Gross's design principle that an element's behaviour should be obvious from looking at it. `hx-*` attributes sit right on the element they affect, the opposite of behaviour scattered across separate JS files.
- **Server owns state** — application state and logic live on the server; the client is a thin hypermedia renderer. This is the same pillar [HTML First](html-first.md) leans on.

## htmx 2.0

The 2.0 release (June 2024) was mostly about cleanup, not new surface area:

- **Dropped Internet Explorer support**
- **Extensions moved out of core** into their own repositories, each versioned and installed separately (SSE, WebSockets, idiomorph morphing swaps, preload, response-targets, …)
- **`hx-delete` now uses query parameters** instead of a form-encoded body, to comply with the HTTP spec
- **Removed deprecated attributes** and improved **Web Components** integration (see [web components](web-components.md))

The maintainers have stated htmx is intended to be **"finished"/stable software** — small, done, and slow-changing — rather than a constantly churning framework.

## Pros

- **Tiny and dependency-free**: ~14 kB vs ~45 kB+ for a React runtime; nothing to keep upgrading
- **No build step**: drop in a `<script>` tag; no bundler, transpiler, or toolchain required
- **Less code**: server-rendered HTML deletes whole categories of client code (real ports report 60–78% smaller codebases — see below)
- **One mental model**: it is just HTML and HTTP; the learning curve is shallow
- **Backend-agnostic**: works with any server that can return HTML — Django, Rails, Go, Spring, PHP, Node
- **Accessibility, SEO, and View-Source** come for free because the page is real HTML
- **Locality of Behaviour**: behaviour is visible on the element, easy to read and debug
- **Plays well with AI agents and crawlers**: semantic HTML is legible to them

## Cons

- **Assumes the server returns HTML**: bolting htmx onto an existing JSON API means either templating on the client or building HTML-returning endpoints
- **More server round-trips**: every interaction is a request; latency-sensitive UIs can feel less instant than optimistic client updates
- **Not for thick clients**: rich, app-like UIs with deep client-side state (editors, design tools, real-time canvases) still want a framework — Gumroad evaluated htmx and rejected it as too limited for their interactivity
- **Smaller ecosystem and hiring pool** than React/Vue; fewer off-the-shelf components and answers
- **"Magic" criticism**: some developers dislike attribute-driven, string-based behaviour and find it harder to reason about at scale
- **Complexity shifts to the backend**: the client gets simpler, but state, validation, and fragment composition now live on the server

## Real-World Case Studies

The most-cited port is **Contexte** (David Guillot, presented at DjangoCon Europe 2022). They replaced a 2-year-old React UI with Django templates + htmx in about **two months**:

| Metric | Result |
|---|---|
| Codebase | **−67%** (21,500 → 7,200 LOC) |
| Python code | **+140%** (500 → 1,200 LOC) — logic moved server-side |
| JS dependencies | **−96%** (255 → 9) |
| Web build time | **−88%** (40s → 5s) |
| First load time-to-interactive | **−50–60%** |
| Web app memory | **−46%** (75 MB → 45 MB) |
| Large data sets | Now possible — React couldn't handle them |

Gross notes these numbers are "eye-popping" because Contexte is a **content-focused** app (lots of text and images) that is unusually amenable to hypermedia — most apps would see smaller, but still real, gains, at least for part of the system. The counter-example is **Gumroad**, which chose a heavier framework because its interactivity and ecosystem needs made htmx a poor fit.

## Comparison with Similar Approaches

### htmx vs SPA (React/Vue)

| Aspect | htmx | SPA |
|---|---|---|
| Data over the wire | HTML fragments | JSON |
| Where state lives | Server | Client |
| Rendering | Server renders, htmx swaps | Client renders (virtual DOM) |
| Build step | None | Required |
| Runtime size | ~14 kB | ~45 kB+ before app code |
| Best for | Content/form/CRUD apps | Highly interactive thick clients |

### htmx vs Hotwire (Turbo + Stimulus)

| Aspect | htmx | Hotwire |
|---|---|---|
| Size | ~14 kB | Turbo ~22 kB (+ Stimulus) |
| Style | Explicit `hx-*` attributes anywhere | Convention-driven frames/streams |
| Backend coupling | Backend-agnostic | Rails-first; needs status/header conventions |
| Granularity | Fine-grained, per-element | Frame- and stream-oriented |

### htmx vs Alpine.js

| Aspect | htmx | [Alpine.js](html-first.md) |
|---|---|---|
| Job | Server exchange (hypermedia) | Client-side state and reactivity |
| Relationship | **Complementary** — often used together | Sprinkled into markup for local interactivity |
| Note | htmx community often prefers `_hyperscript` for client behaviour | |

### htmx vs Unpoly vs Datastar

| Aspect | htmx | Unpoly | Datastar |
|---|---|---|---|
| Maturity | Mature, stable | Very mature (10+ yrs) | Newer |
| Batteries | Minimal core + extensions | Layers, advanced form validation, PE | Combines htmx + Alpine in one package |
| Approach | Request/swap | Declarative progressive enhancement | SSE-oriented, signal-based |
| Size | ~14 kB | Larger | Smaller than htmx |

### htmx vs HTML First / Resumability

- **[HTML First](html-first.md)** is the *philosophy*; htmx is the *tool* it reaches for when native HTML+CSS can't express the interaction. htmx is HTML First's flagship library.
- **[Resumability](resumability.md)** (Qwik) keeps a framework and serializes client state into HTML; htmx avoids client state entirely by going back to the server. Both aim to ship very little JS, by opposite routes — htmx also sidesteps [hydration](hydration-frontend.md) by shipping almost no JS to begin with.

## When to Use What

- **Form-driven CRUD apps, dashboards, admin tools with server-owned state**: htmx is an excellent fit
- **Content-heavy sites (text, media, listings)**: htmx, as the Contexte numbers show
- **Teams wanting to delete a build step and shrink the dependency tree**: htmx
- **A few interactive widgets on an otherwise server-rendered page**: htmx + Alpine, or [island architecture](island-architecture.md)
- **Highly interactive, app-like UIs with rich client state**: a mature SPA, or [resumability](resumability.md) for startup cost
- **Already have a JSON API you can't change**: htmx fights you here — keep the SPA, or add HTML-returning endpoints
