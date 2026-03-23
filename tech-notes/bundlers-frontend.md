# Frontend Bundlers

## What is a Bundler?

A bundler is a build tool that takes multiple source files (JavaScript, TypeScript, CSS, images, etc.) and combines them into optimized output files for the browser. Bundlers resolve module dependencies, transform code (transpilation, minification), split code into chunks, and produce production-ready assets. They solve the problem of shipping modular source code to browsers that historically only understood single script files.

## How Bundlers Work

1. **Entry point**: the bundler starts from one or more entry files
2. **Dependency resolution**: it follows all import/require statements to build a dependency graph
3. **Transformation**: plugins/loaders transform files (TypeScript to JS, JSX to JS, Sass to CSS)
4. **Tree shaking**: unused exports are removed from the final bundle
5. **Code splitting**: the bundler creates separate chunks for lazy-loaded routes or dynamic imports
6. **Minification**: variable names are shortened, whitespace removed, dead code eliminated
7. **Output**: optimized files are written to the output directory

```
Source Files                  Bundler                    Output

index.ts     ─┐
App.tsx       ─┤         ┌──────────────┐          main.js (hash)
utils.ts     ─┤────────►│   Bundler    │────────► vendor.js (hash)
styles.css   ─┤         │              │          lazy-route.js (hash)
logo.png     ─┤         │  - resolve   │          styles.css (hash)
package.json ─┘         │  - transform │          assets/logo.png
                         │  - tree shake│          index.html
                         │  - split     │
                         │  - minify    │
                         └──────────────┘
```

## Major Bundlers

### Webpack
The most established bundler in the JavaScript ecosystem. Created by **Tobias Koppers** in 2012. Webpack pioneered concepts like code splitting, hot module replacement, and loader-based transformations. It is highly configurable with a large plugin ecosystem but has a reputation for complex configuration and slower builds.

### Vite
Created by **Evan You** (creator of Vue) in 2020. Vite uses native ES modules during development for instant server start and fast HMR. For production, it uses Rollup under the hood. Vite is fast because it skips bundling during development and only transforms files on demand.

### esbuild
Created by **Evan Wallace** (co-founder of Figma) in 2020. Written in Go, esbuild is 10-100x faster than JavaScript-based bundlers. It handles bundling, minification, and TypeScript/JSX transformation. It is intentionally minimal and does not support HMR or complex plugin APIs by default.

### Rollup
Created by **Rich Harris** (creator of Svelte) in 2015. Rollup pioneered tree shaking in the JavaScript ecosystem. It produces clean, efficient bundles and is the preferred bundler for libraries. Vite uses Rollup for production builds.

### Turbopack
Created by **Vercel** in 2022. Written in Rust, Turbopack is designed as the successor to Webpack. It uses incremental computation to achieve fast rebuilds. Currently integrated into Next.js as the default dev server bundler.

### Rspack
Created by **ByteDance** in 2023. Written in Rust, Rspack is a drop-in replacement for Webpack with compatible configuration and plugin API. It provides Webpack compatibility with Rust-level performance.

### Parcel
Created by **Devon Govett** in 2017. Parcel is a zero-configuration bundler that automatically detects and configures transformations. It uses a multi-threaded architecture for fast builds and supports all file types out of the box.

### Bun Bundler
Built into **Bun** (the JavaScript runtime) by **Jarred Sumner**. Written in Zig, it provides bundling as part of the Bun runtime with extremely fast performance. Still maturing but aims to be an all-in-one solution.

## Comparison

| Feature | Webpack | Vite | esbuild | Rollup | Turbopack | Rspack | Parcel |
|---|---|---|---|---|---|---|---|
| Language | JS | JS (Rollup) | Go | JS | Rust | Rust | JS |
| Dev server speed | Slow | Very fast | Fast | N/A | Very fast | Fast | Fast |
| Production build | Moderate | Fast (Rollup) | Very fast | Fast | Fast | Fast | Fast |
| Configuration | Complex | Minimal | Minimal | Moderate | Minimal | Webpack-compatible | Zero config |
| Tree shaking | Yes | Yes (Rollup) | Yes | Best | Yes | Yes | Yes |
| Code splitting | Yes | Yes | Limited | Yes | Yes | Yes | Yes |
| HMR | Yes | Yes (fast) | No | No | Yes | Yes | Yes |
| Plugin ecosystem | Largest | Growing | Small | Large | Small | Webpack-compatible | Moderate |
| TypeScript | Via loader | Built-in | Built-in | Via plugin | Built-in | Built-in | Built-in |
| Best for | Legacy/complex apps | Modern apps | Libraries, speed | Libraries | Next.js | Webpack migration | Quick prototyping |

## Pros and Cons by Bundler

### Webpack
**Pros**: massive ecosystem, handles any use case, battle-tested at scale, extensive documentation
**Cons**: slow builds, complex configuration, steep learning curve, large config files

### Vite
**Pros**: instant dev server start, fast HMR, simple config, framework agnostic, great DX
**Cons**: Rollup-based production can differ from dev behavior, less mature plugin ecosystem than Webpack

### esbuild
**Pros**: extremely fast, simple API, great for CI/CD pipelines, small binary
**Cons**: no HMR, limited plugin API, not suitable as a full dev server alone

### Rollup
**Pros**: cleanest output bundles, best tree shaking, ideal for libraries, predictable output
**Cons**: not designed for applications, no built-in dev server, slower than Go/Rust bundlers

### Turbopack
**Pros**: Rust performance, incremental builds, tight Next.js integration
**Cons**: early stage, limited standalone use outside Next.js, smaller community

### Rspack
**Pros**: Webpack-compatible config, Rust speed, easy migration from Webpack
**Cons**: newer project, not 100% Webpack feature parity, smaller community

## Evolution Timeline

```
2012 ─── Webpack (pioneered bundling for SPAs)
2015 ─── Rollup (pioneered tree shaking)
2017 ─── Parcel (zero config)
2020 ─── esbuild (Go, 100x faster)
2020 ─── Vite (native ESM dev, Rollup prod)
2022 ─── Turbopack (Rust, incremental)
2023 ─── Rspack (Rust, Webpack-compatible)
2023 ─── Bun Bundler (Zig, all-in-one runtime)
```

## When to Use What

- **New web application**: Vite (fast, simple, framework support)
- **New library/package**: Rollup or esbuild (clean output, tree shaking)
- **Existing Webpack project**: Rspack (drop-in Rust replacement)
- **Next.js application**: Turbopack (native integration)
- **Maximum build speed**: esbuild (fastest raw bundling)
- **Zero configuration**: Parcel (auto-detection)
- **Complex enterprise app**: Webpack (handles everything, mature ecosystem)
