# Generative UI (GenUI)

## What is it?

Generative UI is the pattern where parts of the user interface are produced, selected, or controlled by an LLM or agent at runtime, instead of being fully hand-authored at build time. The agent does not return a wall of markdown — it returns a structured intent ("render `FlightCard` with these props") and the host application turns it into a real, interactive React tree. Buttons, forms, charts, payment widgets, dashboards, and approval flows materialize inline with the conversation or inside the host app's own surface.

The framing that matters: GenUI is **the bridge between a tool call and a component**. Pre-GenUI, an agent that called `searchFlights()` had to summarize the result in text. Post-GenUI, that same tool call mounts an interactive card the user can sort, filter, and book from — without leaving the chat.

This is not "the LLM writes HTML." The defensible production pattern is **constrained component selection**: developers own the component library, the LLM owns which-and-when. Free-form HTML emission exists (ChatGPT Apps SDK, CopilotKit open-ended mode) but always sits behind a sandbox.

## The Three Modes

```
┌──────────────────┬────────────────────┬───────────────────────────────────┐
│ Mode             │ Agent emits        │ Trade                             │
├──────────────────┼────────────────────┼───────────────────────────────────┤
│ Static /         │ Component name +   │ Safest, most consistent.          │
│ Controlled       │ typed props        │ Limited to what you pre-built.    │
│                  │ (Zod-validated)    │                                   │
├──────────────────┼────────────────────┼───────────────────────────────────┤
│ Declarative      │ Structured UI spec │ Wider surface, still bounded by   │
│                  │ (cards/lists/forms │ schema. Google's A2UI is this.    │
│                  │ as JSON/JSONL)     │                                   │
├──────────────────┼────────────────────┼───────────────────────────────────┤
│ Open-ended       │ Raw HTML/JSX,      │ Maximum flexibility, maximum      │
│                  │ usually in a       │ risk. ChatGPT Apps SDK and        │
│                  │ sandboxed iframe   │ CopilotKit "open-ended" use this. │
└──────────────────┴────────────────────┴───────────────────────────────────┘
```

Most production apps in 2026 sit in **Static + Declarative**. Open-ended is reserved for marketplaces (ChatGPT Apps, v0 previews) where the host can sandbox aggressively.

## The Four Frameworks

```
┌───────────────────────┬──────────────────────────────────────────────────┐
│ Framework             │ What it is                                       │
├───────────────────────┼──────────────────────────────────────────────────┤
│ Tambo                 │ Full-stack open-source React SDK. Register       │
│                       │ components with Zod, the agent picks one and     │
│                       │ streams props. Built-in agent — no LangGraph     │
│                       │ required. MCP support. Tambo 1.0 is GA, SOC 2    │
│                       │ + HIPAA. Users: Zapier, Rocket Money, Solink.    │
├───────────────────────┼──────────────────────────────────────────────────┤
│ Vercel AI SDK         │ The library that introduced GenUI to most React  │
│ (streamUI + AI        │ devs (AI SDK 3.0, derived from v0). streamUI     │
│ Elements)             │ streams React Server Components from LLM tool    │
│                       │ calls. NOTE: ai/rsc is officially PAUSED. New    │
│                       │ work goes to AI SDK UI + AI Elements + the new   │
│                       │ JSON-Render framework (announced March 2026).    │
├───────────────────────┼──────────────────────────────────────────────────┤
│ CopilotKit + AG-UI    │ "Frontend stack for agents." React + Angular     │
│                       │ SDK for chat, copilots, canvases, HITL. Makers   │
│                       │ of the AG-UI protocol — open standard for how    │
│                       │ agents stream state, tool progress, and UI       │
│                       │ updates to a frontend. Adopted by Google,        │
│                       │ Microsoft, Amazon (Bedrock AgentCore), Oracle.   │
│                       │ Raised $27M in 2026 to push AG-UI as standard.   │
├───────────────────────┼──────────────────────────────────────────────────┤
│ OpenAI Apps SDK       │ Apps inside ChatGPT itself. Components run in a  │
│                       │ sandboxed iframe inside ChatGPT, talk via the    │
│                       │ MCP Apps bridge (JSON-RPC over postMessage).     │
│                       │ Ships apps-sdk-ui — buttons/cards matching       │
│                       │ ChatGPT styling. Preview Oct 2025; broadened     │
│                       │ Nov 13, 2025. Distribution: 800M+ users.         │
└───────────────────────┴──────────────────────────────────────────────────┘
```

### Tambo

You register components, the agent decides which one to render. Zod schemas define props → schemas become LLM tool definitions → agent calls them like functions → Tambo renders. Two component flavors: *generative components* render once (summary card, chart); *interactable components* maintain state and handle user interactions (drag-drop task board). Best fit: React-only stacks that want an opinionated, batteries-included path without hosting their own orchestration.

### Vercel AI SDK

`streamUI` lets the model pick a tool (e.g. `getFlights`) and Vercel streams the matching React Server Component into the chat. The catch in 2026: `ai/rsc` is paused. New builds should plan for AI SDK UI + AI Elements (client-side primitives) and the new JSON-Render declarative framework. Vercel's **v0** is adjacent but different — it's a design-time tool that generates UI code from prompts (25M UIs generated, 4M users), not a runtime GenUI framework.

### CopilotKit + AG-UI

CopilotKit is the SDK; AG-UI is the protocol they shepherd. The protocol matters more than the library — it standardizes how agents and frontends talk, the same way MCP standardized agents and tools. The three-layer integration jointly released with Oracle and Google:

```
┌────────────────────────────────────────────────────────────────┐
│  Oracle Open Agent Spec  — framework-agnostic agent definition │
│              │                                                 │
│              ▼                                                 │
│  AG-UI                  — live streaming, agent <-> frontend   │
│              │                                                 │
│              ▼                                                 │
│  Google A2UI            — agent describes the UI it needs      │
│                           as structured JSONL; host renders    │
└────────────────────────────────────────────────────────────────┘
```

Best fit: existing LangGraph / CrewAI / Bedrock agent that needs a UI seam bolted on without rewriting the agent. Or any team that wants vendor-neutral protocol bets.

### OpenAI Apps SDK

Lets you ship an app inside the ChatGPT conversation surface, not your own site. An "app" is an MCP server plus an optional web component. The component runs in a sandboxed iframe and communicates with ChatGPT over the MCP Apps bridge (JSON-RPC + postMessage). Apps are discovered by intent — typing "plan a Tokyo trip" can surface Expedia inline.

```
┌─────────────────────────────────────────────────────────────────┐
│                       ChatGPT host                              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  iframe (sandboxed)                                     │    │
│  │  Your component (apps-sdk-ui primitives)                │    │
│  │                                                         │    │
│  │  ─── JSON-RPC over postMessage (MCP Apps bridge) ───▶   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            │                                    │
│                            ▼                                    │
│  Your MCP server (tools + auth + data)                          │
└─────────────────────────────────────────────────────────────────┘
```

Launch partners: Booking.com, Canva, Coursera, Expedia, Figma, Spotify, Zillow. The trade: reach 800M users, give up surface ownership.

## Use Cases

```
┌────────────────────────────────────────────────────────────────┐
│  Search results as components, not links                       │
│    "Show me flights to Tokyo" -> interactive cards with        │
│    sort/filter/book actions, not a markdown table.             │
│                                                                │
│  Form fill-in over chat                                        │
│    Agent renders a real form with validation rather than a     │
│    turn-by-turn Q&A.                                           │
│                                                                │
│  Dashboards generated from a question                          │
│    "Revenue trend last month, by region" -> live drillable     │
│    chart, not an image.                                        │
│                                                                │
│  In-app copilots with side-effects                             │
│    Zapier's GenUI lets users build a Zap from inside the       │
│    copilot. Rocket Money surfaces transaction reviews inline.  │
│                                                                │
│  Human-in-the-loop approvals                                   │
│    Agent runs to a decision point and renders approve/deny;    │
│    user input flows back into the agent's state.               │
│                                                                │
│  ChatGPT-resident apps                                         │
│    Booking, Spotify, Zillow surfacing native UI inside the     │
│    conversation. App is discoverable by intent.                │
│                                                                │
│  AI-native personalized landing pages                          │
│    Vercel/Shopify case studies report 22%+ revenue uplift      │
│    and 76% conversion gains when the page is composed for      │
│    the visitor's intent at request time.                       │
└────────────────────────────────────────────────────────────────┘
```

## Companies and What They Are Building

```
┌──────────────────────┬───────────────────────┬─────────────────────┐
│ Company              │ What they're doing    │ Stack               │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Zapier               │ In-app copilot that   │ Tambo               │
│                      │ builds Zaps via GenUI │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Rocket Money         │ Conversational        │ Tambo               │
│                      │ finance UI, txn cards │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Solink               │ GenUI in retail-ops   │ Tambo               │
│                      │ product               │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Vercel (v0)          │ Design-time UI gen,   │ Own AI SDK + RSC    │
│                      │ 25M UIs, 4M users     │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Shopify              │ Generative product    │ Internal + Vercel   │
│                      │ descriptions, -80%    │                     │
│                      │ content time          │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ PAIGE (apparel)      │ Headless Shopify +    │ Vercel AI SDK       │
│                      │ Next.js + Vercel,     │                     │
│                      │ +22% revenue, +76%    │                     │
│                      │ conversion            │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Thomson Reuters      │ Legal/accounting      │ Internal            │
│ (CoCounsel)          │ copilot, 1,300 firms, │                     │
│                      │ built by 3 devs in    │                     │
│                      │ 2 months              │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Google               │ Gemini Dynamic View,  │ Google internal     │
│                      │ generative interface  │                     │
│                      │ for any prompt        │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Amazon               │ Rufus shopping        │ Internal, now also  │
│                      │ copilot, rich product │ AG-UI compatible    │
│                      │ UI                    │ (Bedrock AgentCore) │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Microsoft            │ Agent Framework with  │ AG-UI               │
│                      │ AG-UI support         │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Oracle               │ Open Agent Spec +     │ AG-UI               │
│                      │ AG-UI integration     │                     │
├──────────────────────┼───────────────────────┼─────────────────────┤
│ Booking.com, Canva,  │ Apps embedded inside  │ OpenAI Apps SDK     │
│ Coursera, Expedia,   │ ChatGPT, surfaced by  │                     │
│ Figma, Spotify,      │ intent                │                     │
│ Zillow               │                       │                     │
└──────────────────────┴───────────────────────┴─────────────────────┘
```

## Trade-offs

### What you gain

- **Higher information density per turn.** One card beats ten lines of markdown.
- **Direct action.** User clicks "Book" instead of copying a confirmation code into a different tab.
- **Streaming UX.** Partial state visible immediately; perceived latency drops sharply.
- **Agent state becomes visible.** Tool progress, intermediate state, and HITL approvals all render natively.
- **Better grounding.** Typed component props force the model to commit to a schema, reducing hallucination on numbers, dates, and IDs.

### What you pay

```
┌────────────────────────────────────────────────────────────────┐
│  Prompt injection becomes a UI problem                         │
│    Tool results can now shape what gets rendered and what      │
│    gets clicked. Studies cite injection affecting 73% of       │
│    LLM deployments. Mitigation: validate props at the          │
│    boundary (Zod), sandbox open-ended HTML, never give the     │
│    model unscoped action permissions, separate rendering       │
│    from executing.                                             │
│                                                                │
│  Code/data boundary erodes                                     │
│    LLMs treat text as both instructions and content. A         │
│    flight result containing "ignore previous instructions"     │
│    is a real attack vector if model output ever reaches        │
│    dangerouslySetInnerHTML.                                    │
│                                                                │
│  Sandbox vs. utility tension                                   │
│    Tighter sandboxes (iframes, CSP, allow-listed components)   │
│    cut attack surface but limit what GenUI can express.        │
│    ChatGPT Apps SDK = one extreme (full iframe isolation);     │
│    Tambo/CopilotKit controlled-mode = the other (no iframe     │
│    but tight component allowlist).                             │
│                                                                │
│  Design system fragmentation                                   │
│    Open-ended GenUI breaks your design system. Controlled      │
│    mode preserves it but limits the agent.                     │
│                                                                │
│  Vendor lock-in risk                                           │
│    streamUI (Vercel) is paused; Apps SDK only lives inside     │
│    ChatGPT; A2UI is Google's. AG-UI is the only neutral        │
│    protocol with cross-vendor adoption right now.              │
│                                                                │
│  Eval is hard                                                  │
│    "Did the agent pick the right component, with the right     │
│    props, at the right moment?" is a multi-axis evaluation     │
│    problem. No standard benchmark exists.                      │
│                                                                │
│  Cost                                                          │
│    Structured outputs that include UI plans are more tokens    │
│    per turn than plain text replies.                           │
└────────────────────────────────────────────────────────────────┘
```

## When to Use Which

```
┌──────────────────────────────────────┬───────────────────────────┐
│ Situation                            │ Pick                      │
├──────────────────────────────────────┼───────────────────────────┤
│ React-only, want opinionated SDK     │ Tambo                     │
│ with batteries included              │                           │
├──────────────────────────────────────┼───────────────────────────┤
│ Already on Next.js + RSC,            │ Vercel AI SDK             │
│ comfortable with Vercel's roadmap    │ (lean to AI SDK UI +      │
│ shifts                               │ AI Elements, not          │
│                                      │ paused ai/rsc)            │
├──────────────────────────────────────┼───────────────────────────┤
│ Existing LangGraph / CrewAI /        │ CopilotKit + AG-UI        │
│ Bedrock agent, need to add a UI seam │                           │
├──────────────────────────────────────┼───────────────────────────┤
│ Want distribution inside ChatGPT,    │ OpenAI Apps SDK           │
│ willing to give up surface ownership │                           │
├──────────────────────────────────────┼───────────────────────────┤
│ Need cross-vendor / future-proof     │ AG-UI as the protocol;    │
│                                      │ pick any AG-UI-speaking   │
│                                      │ framework                 │
└──────────────────────────────────────┴───────────────────────────┘
```

Hybrid is normal: an internal product on CopilotKit/Tambo for the in-app copilot, plus an Apps SDK entry point for ChatGPT discovery.

## Recommendation

Start in Controlled mode. Hand-build the 10-20 components your agent can possibly need, register them, let the LLM pick. Do not start with open-ended HTML. Use Zod (or equivalent) at the prop boundary — reject malformed props loudly. This is the cheapest prompt-injection defense available.

Treat tool results as untrusted. Anything the agent retrieved (web, RAG, MCP tool) should not be able to render arbitrary UI or auto-trigger an action. Stream by default — skeleton → partial → final beats a four-second blank wait every time. Bet on a protocol, not a library. AG-UI + MCP are the parts most likely to survive a vendor pivot; `streamUI` being paused is the cautionary tale.

Evaluate with real tasks, not toy chats. Track: component-pick accuracy, prop-validation failure rate, time-to-first-meaningful-render, and "did the user need to fall back to plain chat."

Generative UI is now table stakes for any serious agent product — chat-only is the new "command line." But the value is in **constrained** generation, not free-form HTML emission. Pick a framework whose default mode matches that.

## References

### What is Generative UI

- [The Developer's Guide to Generative UI in 2026 — CopilotKit](https://www.copilotkit.ai/blog/the-developer-s-guide-to-generative-ui-in-2026)
- [The Complete Guide to Generative UI Frameworks in 2026 — Medium](https://medium.com/@akshaychame2/the-complete-guide-to-generative-ui-frameworks-in-2026-fde71c4fa8cc)
- [Generative UI: A rich, custom, visual interactive user experience for any prompt — Google Research](https://research.google/blog/generative-ui-a-rich-custom-visual-interactive-user-experience-for-any-prompt/)
- [awesome-generative-ui — curated list](https://github.com/narrowin/awesome-generative-ui)
- [Generative UI Case Studies — awesomegenerativeui.com](https://awesomegenerativeui.com/cases)

### Tambo

- [Tambo homepage](https://tambo.co/)
- [tambo-ai/tambo on GitHub](https://github.com/tambo-ai/tambo)
- [Tambo Docs — Generative UI toolkit for React](https://docs.tambo.co/)
- [Introducing Tambo 1.0](https://tambo.co/blog/posts/introducing-tambo-generative-ui)
- [Generative Components — Tambo Docs](https://docs.tambo.co/concepts/generative-interfaces/generative-components)
- [Tambo AI: React SDK for Generative UI with AI Agents — YUV.AI](https://www.yuv.ai/blog/tambo-ai)

### Vercel AI SDK

- [AI SDK by Vercel — Docs](https://ai-sdk.dev/docs/introduction)
- [AI SDK UI: Generative User Interfaces](https://ai-sdk.dev/docs/ai-sdk-ui/generative-user-interfaces)
- [Introducing AI SDK 3.0 with Generative UI support — Vercel Blog](https://vercel.com/blog/ai-sdk-3-generative-ui)
- [Generative UI Chatbot with React Server Components — Vercel template](https://vercel.com/templates/next.js/rsc-genui)
- [vercel-labs/ai-sdk-preview-rsc-genui on GitHub](https://github.com/vercel-labs/ai-sdk-preview-rsc-genui)
- [Vercel Releases JSON-Render: a Generative UI Framework — InfoQ (March 2026)](https://www.infoq.com/news/2026/03/vercel-json-render/)
- [AI-powered prototyping with design systems — Vercel Blog](https://vercel.com/blog/ai-powered-prototyping-with-design-systems)

### CopilotKit + AG-UI

- [CopilotKit homepage](https://www.copilotkit.ai/)
- [CopilotKit on GitHub — Frontend Stack for Agents & Generative UI](https://github.com/CopilotKit/CopilotKit)
- [CopilotKit/generative-ui — examples for AG-UI, A2UI, MCP Apps](https://github.com/CopilotKit/generative-ui)
- [CopilotKit Docs — Generative UI guide](https://docs.copilotkit.ai/direct-to-llm/guides/generative-ui)
- [AG-UI Protocol — overview](https://www.copilotkit.ai/ag-ui)
- [AG-UI Docs](https://docs.ag-ui.com/)
- [ag-ui-protocol/ag-ui on GitHub](https://github.com/ag-ui-protocol/ag-ui)
- [Oracle adopts AG-UI protocol for Agent Spec — CopilotKit](https://www.copilotkit.ai/blog/oracle-adopts-ag-ui-protocol-for-agent-spec)
- [CopilotKit raises $27M to make AG-UI the standard — GeekWire (2026)](https://www.geekwire.com/2026/seattles-copilotkit-raises-27m-as-some-of-the-biggest-names-in-tech-adopt-its-ai-agent-protocol/)
- [AG-UI Integration with Microsoft Agent Framework](https://learn.microsoft.com/en-us/agent-framework/integrations/ag-ui/)
- [Announcing Agent Spec for A2UI through CopilotKit AG-UI — Oracle Blog](https://blogs.oracle.com/ai-and-datascience/announcing-agent-spec-for-a2ui-copilotkit-ag-ui)

### OpenAI Apps SDK (apps inside ChatGPT)

- [Introducing apps in ChatGPT and the new Apps SDK — OpenAI](https://openai.com/index/introducing-apps-in-chatgpt/)
- [Apps SDK — OpenAI Developers](https://developers.openai.com/apps-sdk)
- [Apps SDK Quickstart](https://developers.openai.com/apps-sdk/quickstart)
- [Build your ChatGPT UI — Apps SDK](https://developers.openai.com/apps-sdk/build/chatgpt-ui)
- [openai/apps-sdk-ui on GitHub](https://github.com/openai/apps-sdk-ui)
- [Apps in ChatGPT and the Apps SDK — Help Center](https://help.openai.com/en/articles/12503483-apps-in-chatgpt-and-the-apps-sdk)
- [OpenAI launches ChatGPT Apps with Canva, Spotify, Expedia, Coursera — Storyboard18](https://www.storyboard18.com/how-it-works/openai-chatgpt-apps-chatgpt-apps-sdk-chatgpt-developers-canva-chatgpt-app-spotify-chatgpt-integration-expedia-chatgpt-app-coursera-chatgpt-zillow-chatgpt-figma-chatgpt-booking-com-chatgpt-op-82081.htm)
- [OpenAI announces Apps SDK — VentureBeat](https://venturebeat.com/ai/openai-announces-apps-sdk-allowing-chatgpt-to-launch-and-run-third-party)
- [Building with the OpenAI Apps SDK: A Field Guide — Render Blog](https://render.com/blog/building-with-the-openai-apps-sdk-a-field-guide)

### Security and trade-offs

- [LLM Security Risks in 2026: Prompt Injection, RAG, and Shadow AI — Sombra](https://sombrainc.com/blog/llm-security-risks-2026)
- [Design Patterns for Securing LLM Agents against Prompt Injections — arXiv](https://arxiv.org/html/2506.08837v2)
- [Multimodal Prompt Injection Attacks: Risks and Defenses — arXiv](https://arxiv.org/html/2509.05883v1)
- [Prompt Injection attack against LLM-integrated Applications — arXiv](https://arxiv.org/pdf/2306.05499)
- [Prompt Injection and LLM Jailbreaks in Production — Blockchain Council](https://www.blockchain-council.org/ai/prompt-injection-llm-jailbreaks-securing-generative-ai-applications-production/)
- [Mitigate prompt injection attacks — Android Developers](https://developer.android.com/privacy-and-security/risks/ai-risks/prompt-injection)

### Case studies and adoption

- [How PAIGE grew revenue by 22% with Shopify, Next.js, and Vercel](https://vercel.com/blog/how-paige-grew-revenue-by-22-with-shopify-next-js-and-vercel)
- [v0 by Vercel](https://v0.app/)
- [AI UI Generator: How Businesses Can Leverage Vercel's v0.dev — Baytech](https://www.baytechconsulting.com/blog/ai-ui-generator-how-businesses-can-leverage-vercels-v0-dev)
- [25 Generative AI Case Studies — DigitalDefynd](https://digitaldefynd.com/IQ/generative-ai-case-studies/)

All evidence gathered May 2026. Landscape current as of that point. Two moving pieces to watch: Vercel's JSON-Render rollout (March 2026) and the EU rollout of ChatGPT Apps.
