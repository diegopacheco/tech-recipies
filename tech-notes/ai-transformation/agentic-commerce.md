# Agentic Commerce & Agent Payments

## What is it?

**Agentic commerce** is the shift from AI agents that *recommend* purchases to agents that *execute* them — discovering products, building carts, and moving money end-to-end on a human's behalf. The hard problem is not the shopping; it is the payment. A card network's entire fraud model assumes a human cardholder is present. An autonomous agent breaks that assumption, so 2025–2026 became a land-grab to build the missing trust layer: how does a merchant know *which* agent is calling, that it is *authorized* to spend, and *how much*, with an audit trail that survives a chargeback dispute?

The answer is a stack of new open protocols — ACP, AP2, TAP, UCP — plus an identity discipline the industry is already calling **"Know Your Agent."** None of these existed in stable form two years ago. By early 2026 OpenAI, Stripe, Google, Visa, Mastercard, and the FIDO Alliance are all shipping pieces of it at once, which is why this is one of the loudest infrastructure races in AI right now.

## The Numbers

```
┌────────────────────────────────────────────────┬───────────────────────────┐
│ Metric                                          │ Value                     │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Agentic commerce market (Prove estimate)        │ ~$1.7 trillion            │
├────────────────────────────────────────────────┼───────────────────────────┤
│ AI browser-agent market 2026 (a16z)             │ ~$12B, +200% YoY          │
├────────────────────────────────────────────────┼───────────────────────────┤
│ AP2 partner organizations by Q1 2026            │ 60+ (incl. Adyen,         │
│                                                 │ Worldpay)                 │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Public MCP servers deployed (late 2025)         │ 10,000+                   │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Enterprise apps embedding agents by end 2026    │ 40% (Gartner), up from    │
│                                                 │ <5% in 2025               │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Visa Trusted Agent Protocol launch              │ Oct 14, 2025 (w/          │
│                                                 │ Cloudflare)               │
├────────────────────────────────────────────────┼───────────────────────────┤
│ Stage of adoption (Forrester)                   │ Earliest part of the      │
│                                                 │ curve — infra being built │
└────────────────────────────────────────────────┴───────────────────────────┘
```

## The Protocol Stack

No single protocol does the whole job. A real agentic purchase composes several layers, each owned by a different incumbent racing to be the standard:

```
┌──────────────────┬─────────────────────────────────────────────────────────┐
│ Layer            │ Protocol(s) / who owns it                               │
├──────────────────┼─────────────────────────────────────────────────────────┤
│ Discovery        │ MCP — agent finds products, queries catalogs            │
│                  │ (Anthropic-originated, now 10k+ servers)                │
├──────────────────┼─────────────────────────────────────────────────────────┤
│ Checkout call    │ ACP (OpenAI + Stripe) or UCP — the structured           │
│                  │ "buy this" request to the merchant                      │
├──────────────────┼─────────────────────────────────────────────────────────┤
│ Authorization    │ AP2 (Google) cryptographic mandates, or                 │
│ signature        │ TAP (Visa) agent identity signed into HTTP headers      │
├──────────────────┼─────────────────────────────────────────────────────────┤
│ Settlement rail  │ Card network, Stripe, or x402 (HTTP-402 crypto rail)    │
│                  │ — where the money actually moves                        │
└──────────────────┴─────────────────────────────────────────────────────────┘
```

## How the Trust Layer Works

The two leading checkout/authorization designs solve the "agent can't hold a raw card" problem differently:

```
┌──────────────────────────────────────────────────────────────────────┐
│   ACP — Shared Payment Token (OpenAI + Stripe)                        │
│                                                                      │
│   User approves intent ──► Stripe issues a Shared Payment Token       │
│                            (SPT): bound to ONE merchant,              │
│                            ONE dollar amount, time-bounded,           │
│                            single-use.                               │
│                            ──► Agent presents SPT at checkout.        │
│                            Powers Instant Checkout in ChatGPT.        │
│                                                                      │
│   AP2 — Cryptographic Mandates (Google)                              │
│                                                                      │
│   User attests intent ──► signed digital "mandate" (a receipt        │
│                           the user cryptographically signs for a      │
│                           specific transaction).                     │
│                           ──► Merchant verifies the signature;        │
│                           non-repudiable proof of authorization.      │
└──────────────────────────────────────────────────────────────────────┘
```

The common requirements across every design: **tokenized credentials** (agents never touch raw card data, static credentials, or brittle vaults), and a full audit trail — *every agent decision logged, time-stamped, attributable, and reconstructable* — because chargeback disputes now need to answer "did a human authorize this, or did an agent go rogue?"

## Who Is Doing What

```
┌──────────────────┬──────────────────────────────────────────────────────┐
│ Player            │ What they're shipping                                │
├──────────────────┼──────────────────────────────────────────────────────┤
│ OpenAI + Stripe   │ Agentic Commerce Protocol (ACP), open standard, in   │
│                   │ beta. Shared Payment Token. Instant Checkout inside  │
│                   │ ChatGPT — the consumer entry point.                  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Google            │ Agent Payments Protocol (AP2). Cryptographic         │
│                   │ mandates. 60+ partners by Q1 2026 incl. Adyen,       │
│                   │ Worldpay. Contributing AP2 to FIDO.                  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Visa              │ Trusted Agent Protocol (TAP), launched Oct 14 2025   │
│                   │ with Cloudflare. Signs agent identity into HTTP      │
│                   │ headers; merchants verify against Visa's directory.  │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Mastercard        │ "Verifiable Intent" + "Know Your Agent." CDO        │
│                   │ confirmed Jan 2026 it participates in ALL major      │
│                   │ protocols (UCP, AP2, A2A, ACP) — betting on a        │
│                   │ multi-protocol future.                               │
├──────────────────┼──────────────────────────────────────────────────────┤
│ FIDO Alliance     │ Formed an Agentic Authentication Technical Working   │
│                   │ Group; drafting specs for agent-initiated commerce   │
│                   │ from Google (AP2) and Mastercard (Verifiable Intent).│
├──────────────────┼──────────────────────────────────────────────────────┤
│ Visa/Mastercard   │ Partnered with FIS so issuing banks can identify and │
│ + FIS             │ authorize agent-initiated transactions ("Know Your   │
│                   │ Agent") with payment-credential tokenization.        │
├──────────────────┼──────────────────────────────────────────────────────┤
│ Prove             │ Verified Agent solution pitched at the ~$1.7T        │
│                   │ agentic-commerce opportunity.                        │
└──────────────────┴──────────────────────────────────────────────────────┘
```

## Pros

- **Closes the loop on [[personal-agents|personal agents]].** An assistant that can research *and* buy is qualitatively more useful than one that hands you a link. This is the missing action layer.
- **Open standards, not walled gardens.** ACP and AP2 are published specs with multi-vendor buy-in, so merchants integrate once rather than per-agent.
- **Stronger audit trail than human checkout.** Mandates and SPTs make every purchase non-repudiable and reconstructable — arguably *more* accountable than a human typing a card number.
- **Scoped, single-use credentials.** A token bound to one merchant and one amount limits blast radius if an agent misbehaves or is compromised.

## Cons

- **Protocol fragmentation.** ACP vs AP2 vs TAP vs UCP — a "three-horse race" (Mastercard bets on all of them). Merchants may have to support several, which slows real adoption.
- **Disclosure is unsolved.** Bank of America flags that current protocols don't make clear what data is shared or how agent involvement is disclosed to the user or merchant.
- **New fraud surface.** AI **swarm attacks** and agent-impersonation are now a named security category — the same identity layer that enables agents can be spoofed.
- **Liability is murky.** When a hallucinating agent buys the wrong thing (or fabricates a price — see [[one-person-unicorn|the Medvi case]]), who eats the cost? Chargeback rules predate autonomous buyers.
- **Earliest-stage hype.** Forrester is blunt: agent-*assisted* shopping is real today; fully agentic payments are still very early. The market sizes are projections, not revenue.

## What This Means

Agentic commerce is the payments industry scrambling to retrofit a human-centric trust model for a world where the buyer is software. The technical pattern mirrors what the [[12-factor-agents|agent-engineering]] and [[harness-engineering]] communities already learned: never give an agent ambient, unlimited authority — give it a **scoped, revocable, audited credential** for one task. The SPT (one merchant, one amount, single-use, time-bounded) is exactly a [[harness-engineering|harness firewall]] applied to money.

The winners will not necessarily be the best protocol but the ones with distribution — OpenAI owns the consumer surface (ChatGPT checkout), the card networks own the rails, and FIDO owns the identity standard. Expect a messy multi-protocol period where, like MCP for tools, one or two standards eventually absorb the rest. The open question that gates everything is trust: until disclosure and liability are settled, agents will keep *recommending* far more than they *spend*.

## Links

- Agentic Commerce Protocol (ACP) — OpenAI + Stripe (GitHub): https://github.com/agentic-commerce-protocol/agentic-commerce-protocol
- Stripe powers Instant Checkout in ChatGPT, releases ACP: https://stripe.com/newsroom/news/stripe-openai-instant-checkout
- Agent Payments Protocol (AP2) explained (Paz.ai): https://www.paz.ai/glossary/agent-payments-protocol-ap2
- Agentic Payments: AP2 vs ACP (Grid Dynamics): https://www.griddynamics.com/blog/agentic-payments
- Agentic commerce's three-horse race (Metacircuits): https://metacircuits.substack.com/p/agentic-commerce-three-horse-race
- Visa & Mastercard launch agentic AI payments tools (Digital Commerce 360): https://www.digitalcommerce360.com/2025/10/16/visa-mastercard-both-launch-agentic-ai-payments-tools/
- FIDO Alliance to develop standards for trusted AI agent interactions: https://fidoalliance.org/fido-alliance-to-develop-standards-for-trusted-ai-agent-interactions/
- Authenticating the Autonomous Buyer (TrustSphere): https://www.trustsphere.ai/post/authenticating-the-autonomous-buyer-identity-mandate-and-audit-trail-for-agentic-payments
- Prove Verified Agent — securing the $1.7T agentic commerce revolution: https://www.prove.com/blog/prove-verified-agent-secure-agentic-commerce
- Agentic Payments in B2C Commerce: Where We Are Now (Forrester): https://www.forrester.com/blogs/agentic-payments-in-b2c-commerce-where-we-are-now/
- Agent Identity Verification: How AI Agents Authenticate Purchases in 2026 (Eco): https://eco.com/support/en/articles/15192005-agent-identity-verification-how-ai-agents-authenticate-purchases-in-2026
- AI Agent Payments / agentic commerce payment processing (Inyo): https://www.inyoglobal.com/news/ai-agent-commerce-payment-processing
