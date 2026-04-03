# Web Components

## What is it?

Web Components is a set of browser-native APIs that let you create reusable, encapsulated custom HTML elements. A web component looks and behaves like a built-in HTML element (`<my-button>`, `<user-card>`) but is defined entirely in JavaScript with its own HTML, CSS, and behavior encapsulated from the rest of the page. No framework required — web components work in any browser and with any framework or no framework at all.

## Who created it? When?

The Web Components specifications were proposed by **Alex Russell** at **Google** starting in **2011**. The specs went through several iterations at the W3C. **Custom Elements v1** and **Shadow DOM v1** reached broad browser support by **2018-2019**. **Polymer** (Google, 2013) was the first library built on web components. **Lit** (Google, 2019, rewrite of Polymer) is the current recommended library. All major browsers now support web components natively without polyfills.

## Core APIs

### 1. Custom Elements

Register new HTML tags with their own behavior.

```javascript
class MyCounter extends HTMLElement {
  constructor() {
    super()
    this.count = 0
  }

  connectedCallback() {
    this.render()
    this.querySelector('button').addEventListener('click', () => {
      this.count++
      this.render()
    })
  }

  render() {
    this.innerHTML = `
      <div>
        <span>${this.count}</span>
        <button>+1</button>
      </div>
    `
  }
}

customElements.define('my-counter', MyCounter)
```

```html
<my-counter></my-counter>
```

**Lifecycle callbacks**:

```
┌────────────────────────┬────────────────────────────────────────┐
│ Callback               │ When it fires                          │
├────────────────────────┼────────────────────────────────────────┤
│ constructor()          │ Element created (before DOM attachment)│
├────────────────────────┼────────────────────────────────────────┤
│ connectedCallback()    │ Element added to the DOM               │
├────────────────────────┼────────────────────────────────────────┤
│ disconnectedCallback() │ Element removed from the DOM           │
├────────────────────────┼────────────────────────────────────────┤
│ attributeChangedCallback│ Observed attribute changed            │
│ (name, oldVal, newVal) │                                       │
├────────────────────────┼────────────────────────────────────────┤
│ adoptedCallback()      │ Element moved to a new document        │
└────────────────────────┴────────────────────────────────────────┘
```

### 2. Shadow DOM

Creates an encapsulated DOM subtree attached to an element. Styles inside the shadow DOM do not leak out. Styles outside do not leak in (with some exceptions like inherited properties).

```
Regular DOM:                   Shadow DOM:
┌──────────────────┐          ┌──────────────────┐
│ <my-card>        │          │ <my-card>        │
│   <h1>Title</h1> │          │   #shadow-root   │
│   <p>Text</p>    │          │   ├── <style>    │
│ </my-card>       │          │   │   h1 { ... } │ ← scoped
│                  │          │   ├── <h1>Title  │
│ h1 { color: red }│← global │   └── <p>Text    │
│ affects this h1  │          │                  │
└──────────────────┘          │ h1 { color: red }│← does NOT
                              │ has no effect    │  affect shadow
                              └──────────────────┘
```

```javascript
class MyCard extends HTMLElement {
  constructor() {
    super()
    const shadow = this.attachShadow({ mode: 'open' })
    shadow.innerHTML = `
      <style>
        :host {
          display: block;
          border: 1px solid #ccc;
          padding: 16px;
        }
        h1 { color: blue; }
      </style>
      <h1><slot name="title">Default Title</slot></h1>
      <p><slot>Default content</slot></p>
    `
  }
}
customElements.define('my-card', MyCard)
```

```html
<my-card>
  <span slot="title">Custom Title</span>
  Some content here
</my-card>
```

### 3. HTML Templates and Slots

`<template>` defines reusable HTML that is not rendered until cloned. `<slot>` defines insertion points for consumer-provided content.

```html
<template id="user-template">
  <style>
    .card { border: 1px solid #ddd; padding: 12px; }
    .name { font-weight: bold; }
  </style>
  <div class="card">
    <span class="name"><slot name="name">Unknown</slot></span>
    <div><slot>No bio provided</slot></div>
  </div>
</template>
```

## Libraries and Frameworks

### 1. Lit (Google)

The recommended library for building web components. Adds reactive properties, declarative templates (tagged template literals), and efficient re-rendering on top of native APIs.

```javascript
import { LitElement, html, css } from 'lit'

class MyCounter extends LitElement {
  static styles = css`
    button { padding: 8px 16px; }
    span { font-size: 24px; }
  `

  static properties = {
    count: { type: Number }
  }

  constructor() {
    super()
    this.count = 0
  }

  render() {
    return html`
      <span>${this.count}</span>
      <button @click=${() => this.count++}>+1</button>
    `
  }
}
customElements.define('my-counter', MyCounter)
```

- ~5KB (minified + gzipped)
- Reactive properties with automatic re-rendering
- SSR support via @lit-labs/ssr
- Decorators for TypeScript

### 2. Stencil (Ionic)

A compiler that generates standard web components from a TypeScript + JSX authoring experience. Outputs vanilla web components with no runtime dependency.

```typescript
import { Component, Prop, h } from '@stencil/core'

@Component({
  tag: 'my-counter',
  styleUrl: 'my-counter.css',
  shadow: true,
})
export class MyCounter {
  @Prop() count: number = 0

  render() {
    return (
      <div>
        <span>{this.count}</span>
        <button onClick={() => this.count++}>+1</button>
      </div>
    )
  }
}
```

- Compiles to zero-runtime web components
- Lazy loading of components
- JSX authoring familiar to React developers
- Used by Ionic Framework for cross-framework UI components

### 3. FAST (Microsoft)

Microsoft's web component library. Powers Fluent UI Web Components.

- Design system infrastructure (design tokens, adaptive UI)
- High-performance rendering engine
- Accessibility built-in
- Used in VS Code, Microsoft 365 web experiences

### 4. Shoelace / Web Awesome

A UI component library built entirely on web components with Lit. Works with React, Vue, Angular, or vanilla HTML.

## Framework Interoperability

```
┌──────────────────┬────────────────────────────────────────────────┐
│ Framework        │ Web Component Support                          │
├──────────────────┼────────────────────────────────────────────────┤
│ Vanilla HTML/JS  │ Full native support, no wrappers needed       │
├──────────────────┼────────────────────────────────────────────────┤
│ Vue              │ Excellent. Passes props and events natively.   │
│                  │ Can also compile Vue components as WCs         │
├──────────────────┼────────────────────────────────────────────────┤
│ Angular          │ Excellent. Angular Elements wraps Angular      │
│                  │ components as web components for export         │
├──────────────────┼────────────────────────────────────────────────┤
│ Svelte           │ Excellent. Svelte can compile to custom        │
│                  │ elements natively (customElement: true)         │
├──────────────────┼────────────────────────────────────────────────┤
│ React            │ Partial. React does not pass complex props     │
│                  │ (objects, arrays) to WCs correctly. Events     │
│                  │ require addEventListener. React 19 improves    │
│                  │ WC support. Wrappers like @lit/react help.     │
└──────────────────┴────────────────────────────────────────────────┘
```

## Comparison

```
┌──────────────────┬───────────┬───────────┬───────────┬──────────────────┐
│ Feature          │ Lit       │ Stencil   │ FAST      │ Vanilla WC       │
├──────────────────┼───────────┼───────────┼───────────┼──────────────────┤
│ Runtime size     │ ~5KB      │ 0KB       │ ~10KB     │ 0KB              │
│                  │           │ (compiled)│           │                  │
├──────────────────┼───────────┼───────────┼───────────┼──────────────────┤
│ Authoring        │ Tagged    │ TSX/JSX   │ Templates │ innerHTML/DOM    │
│                  │ templates │           │           │ API              │
├──────────────────┼───────────┼───────────┼───────────┼──────────────────┤
│ Reactivity       │ Properties│ Decorators│ Observable│ Manual           │
├──────────────────┼───────────┼───────────┼───────────┼──────────────────┤
│ SSR              │ Yes       │ Yes       │ No        │ No               │
├──────────────────┼───────────┼───────────┼───────────┼──────────────────┤
│ TypeScript       │ Optional  │ Required  │ Required  │ Optional         │
├──────────────────┼───────────┼───────────┼───────────┼──────────────────┤
│ Learning curve   │ Low       │ Medium    │ Medium    │ Low-Medium       │
└──────────────────┴───────────┴───────────┴───────────┴──────────────────┘
```

## Pros

- **Framework Agnostic**: works with React, Vue, Angular, Svelte, or no framework
- **Browser Native**: built on web standards, no framework lock-in
- **Encapsulation**: Shadow DOM prevents style and DOM leaks
- **Reusable Across Projects**: same component works in any web application
- **Future Proof**: browser standards evolve slower but last longer than frameworks
- **Design Systems**: ideal for shared component libraries across teams with different stacks
- **Interoperability**: can be used inside any framework or consumed from plain HTML
- **No Build Step Required**: vanilla web components work without bundlers (Lit adds optional build)

## Cons

- **React Compatibility**: React has poor web component interop (improving in React 19)
- **SSR Limitations**: Shadow DOM and Declarative Shadow DOM SSR support is still maturing
- **Styling Complexity**: Shadow DOM encapsulation makes global theming harder (CSS custom properties work)
- **No Built-in State Management**: no equivalent of React hooks or Vue reactivity without a library
- **Bundle Size of Libraries**: while Lit is small, design system libraries can be large
- **Form Participation**: custom elements do not natively participate in form submission (ElementInternals API fixes this)
- **SEO Challenges**: search engine crawlers may not execute Shadow DOM content
- **Ecosystem Size**: fewer ready-made component libraries compared to React or Vue ecosystems
- **Verbose Vanilla API**: without Lit or Stencil, the raw API requires significant boilerplate

## Use Cases

- **Design Systems**: shared component libraries consumed by teams using React, Vue, Angular, or vanilla JS (Adobe Spectrum, SAP UI5, Shoelace)
- **Micro Frontends**: framework-agnostic fragments composed into a shell application
- **Widget Embedding**: embeddable widgets (chat, forms, players) that work on any website without framework dependencies
- **CMS Integration**: custom components for WordPress, Drupal, or headless CMS rendered in any template
- **Legacy Migration**: introducing modern interactive components into legacy jQuery or server-rendered pages
- **Email Templates**: interactive components in AMP emails
- **Cross-Platform**: Ionic uses Stencil web components as the foundation for iOS, Android, and web
- **Enterprise**: standardized UI components across large organizations with diverse tech stacks
