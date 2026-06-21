# WebAssembly (WASM)

## What is it?

WebAssembly (WASM) is a binary instruction format that runs in the browser at near-native speed. It is a compact, low-level bytecode that the browser compiles and executes inside the same sandbox as JavaScript, but without the parsing and JIT-warmup overhead of shipping source text. Code written in languages like Rust, C, C++, Go, or AssemblyScript is compiled ahead of time into a `.wasm` module that the page loads and calls from JavaScript.

WASM is not a replacement for JavaScript. It is a complement: JavaScript stays in charge of the DOM and UI, while WASM handles compute-heavy work (image processing, compression, cryptography, simulation, parsing) where raw throughput matters. In December 2019 the W3C made WebAssembly an official web standard alongside HTML, CSS, and JavaScript, often called the **"fourth language of the web."**

## Who created it? When?

WebAssembly grew out of two precursors: **asm.js** (Mozilla, a strict JavaScript subset that could be heavily optimized) and **Google Native Client (NaCl)**. In **April 2015**, **Luke Wagner** at Mozilla made the first commits to the `WebAssembly/design` repository, proposing a binary compilation target for the web. **Brendan Eich** (creator of JavaScript) helped frame the move from asm.js to WASM.

It was unusual in being a cross-vendor effort from day one — **Mozilla, Google, Microsoft, and Apple** all collaborated through the W3C WebAssembly Community Group. The first cross-browser MVP shipped in **March 2017**, and WASM reached W3C Recommendation status in **December 2019**. The standard continues to evolve, with later contributions from Fastly, Intel, and Red Hat through the Bytecode Alliance.

## How it works?

1. Source code (Rust, C/C++, Go, etc.) is compiled ahead of time to a `.wasm` binary module
2. The page fetches the module and JavaScript instantiates it via the WebAssembly JS API
3. The browser compiles the bytecode to machine code (streaming compilation as it downloads)
4. JavaScript and WASM share a linear memory buffer (an `ArrayBuffer`) to pass data
5. JavaScript calls exported WASM functions; WASM calls imported JS functions for DOM/host access
6. Compute-heavy work runs in WASM at near-native speed; the UI stays in JavaScript

```
Build Time                         Browser Runtime

┌──────────────┐                  ┌────────────────────────────┐
│ Rust / C /   │   compile        │  JavaScript (UI, DOM)       │
│ C++ / Go     │ ───────────────► │     │            ▲          │
│ source       │   to .wasm       │     │ call       │ result   │
└──────────────┘                  │     ▼            │          │
                                  │  ┌──────────────────────┐   │
        app.wasm  ──── fetch ───► │  │  WASM Module          │   │
                                  │  │  (near-native speed)  │   │
                                  │  └──────────┬───────────┘   │
                                  │             │ shared         │
                                  │     ┌───────▼────────┐       │
                                  │     │ Linear Memory   │       │
                                  │     │ (ArrayBuffer)   │       │
                                  │     └────────────────┘       │
                                  └────────────────────────────┘
```

## Languages That Compile to WASM

- **Rust**: the most recommended language for WASM, with first-class tooling (`wasm-pack`, `wasm-bindgen`)
- **C / C++**: compiled via Emscripten, the original and most mature toolchain
- **Go**: official WASM target, though binaries tend to be large
- **AssemblyScript**: a TypeScript-like language designed to compile directly to WASM
- **C# / .NET**: powers Blazor WebAssembly
- **Kotlin**: Kotlin/Wasm target for Compose Multiplatform
- **Swift, Zig, Python (Pyodide)**: growing support across the ecosystem

## Pros

- **Near-native performance**: runs at roughly 80-90% of native speed, often 5-10x faster than JS for compute-heavy tasks
- **Language choice**: bring existing Rust, C, C++, or Go codebases to the browser without a rewrite
- **Predictable performance**: no JIT warmup or garbage-collection pauses for the hot path
- **Secure sandbox**: runs in the same sandboxed environment as JS with no extra OS access
- **Compact and fast to load**: binary format is smaller than equivalent JS and supports streaming compilation
- **Complements JavaScript**: keeps the familiar JS/DOM stack for UI while offloading heavy work
- **Portable beyond the browser**: the same modules run on servers, edge, and plugins via WASI

## Cons

- **No direct DOM access**: WASM cannot touch the DOM; every UI interaction must round-trip through JavaScript
- **JS<->WASM boundary cost**: passing complex data across the boundary requires serialization and can negate gains for small tasks
- **Larger toolchain**: requires a compiler toolchain (Emscripten, wasm-pack) and a build step
- **Debugging is harder**: source maps and debugging support lag behind native JavaScript tooling
- **Binary size**: runtimes for GC languages (Go, C#) can ship megabytes of WASM
- **Not for everything**: simple UI logic gains nothing and is simpler in plain JavaScript
- **Memory management**: linear memory must be managed manually for low-level languages

## Who Uses It?

- **Figma**: compiles its C++ rendering engine to WASM for a fast, native-feeling design tool in the browser
- **Adobe Photoshop (web)**: uses Rust-to-WASM for image processing at near-native performance
- **Google (Squoosh)**: image compression and format conversion entirely client-side via WASM
- **Photopea**: full browser-based image editor powered by WASM
- **AutoCAD Web**: brought the C++ desktop CAD engine to the browser
- **Unity / Unreal**: export games to the browser via WASM (formerly asm.js)
- **1Password, Cloudflare, Fastly**: use WASM for crypto and edge compute (Cloudflare Workers, Fastly Compute@Edge)

## WASM Beyond the Browser (WASI & the Component Model)

WASM has expanded past the browser. **WASI** (the WebAssembly System Interface) gives modules a portable, capability-based way to access files, networking, and the clock outside a browser, making WASM a lightweight, secure alternative to containers for serverless and plugin systems. **WebAssembly 3.0** introduced the **Component Model**, which lets modules written in different languages compose together through a typed interface language called **WIT** (WebAssembly Interface Types). By 2026, the State of WebAssembly survey reported a majority of respondents running WASM in production.

## Comparison with Similar Approaches

### WASM vs JavaScript

| Aspect | WASM | JavaScript |
|---|---|---|
| Execution speed | Near-native (80-90%) | Slower (JIT, 20-50% of native) |
| DOM access | None (via JS) | Direct |
| Source languages | Rust, C/C++, Go, etc. | JavaScript/TypeScript |
| Load format | Compact binary | Text source |
| Best for | Compute-heavy work | UI, DOM, app logic |
| Debugging | Harder | Mature tooling |

### WASM vs asm.js (its predecessor)

| Aspect | WASM | asm.js |
|---|---|---|
| Format | Binary bytecode | JavaScript subset (text) |
| Parse/load time | Fast (streaming compile) | Slow (parsed as JS) |
| Size | Compact | Larger (text) |
| Status | W3C standard | Legacy, superseded |

### WASM vs Native Apps

| Aspect | WASM | Native App |
|---|---|---|
| Distribution | Via URL, no install | Install / app store |
| Performance | Near-native | Native |
| Hardware access | Sandboxed, limited | Full OS access |
| Reach | Any modern browser | Per-platform builds |
| Best for | Portable heavy compute | Max performance / OS integration |

## When to Use What

- **Heavy client-side compute** (image/video/audio, crypto, parsing, simulation): WASM
- **Porting an existing C/C++/Rust engine to the web**: WASM
- **Standard UI, forms, DOM manipulation, app logic**: plain JavaScript/TypeScript
- **Small, frequent operations**: JavaScript (the boundary cost can outweigh WASM's speed)
- **Secure server-side plugins or edge compute**: WASM + WASI
- **Multi-language composition on the server**: WASM Component Model
