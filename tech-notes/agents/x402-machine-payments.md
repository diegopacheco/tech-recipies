# x402 and the Machine Payments Protocol (MPP)

## What is it?

These are the **settlement** layer of agentic commerce — two efforts that revive the long-dormant **HTTP `402 Payment Required`** status code so that software, not a human at a checkout, can pay for things over HTTP.

- **x402** — launched by **Coinbase on May 6, 2025**. An open standard that embeds **stablecoin** payments (USDC) directly into the HTTP request/response cycle. Governance moved to the **x402 Foundation** (announced by Coinbase and **Cloudflare**, with **Stripe**, Sept 23, 2025) and is migrating under the **Linux Foundation**.
- **MPP (Machine Payments Protocol)** — launched by **Stripe and Tempo on March 18, 2026**, the day Tempo's mainnet went live. An open, **rail-agnostic** standard for agents to request, authorize, and settle payments programmatically — stablecoins *and* fiat.

Where [[agentic-commerce-protocol]] runs the checkout and [[agent-payments-protocol]] proves authorization, x402 and MPP are about the raw movement of money between machines — pay-per-call, pay-per-session, micropayments — without an account, a subscription, or a human in the loop.

## The problem they solve

The web never had a native way to pay. Card rails, subscriptions, and API keys were built for humans: to use a paid API today an agent has to create an account, navigate a pricing page, pick a tier, enter card details, and set up billing — every one of those steps assumes a person. That makes true **micropayments** (a tenth of a cent per API call, per GPU-second, per article) economically impossible, and it makes autonomous agents helpless at any paywall. Both protocols make a single HTTP request itself payable, so a machine can pay exactly for what it consumes, instantly, and move on.

## How x402 works

x402 is intentionally thin — it extends native HTTP, so almost any client (browser, SDK, agent) works with no UI changes:

1. Client (agent) requests a protected resource: `GET /api`.
2. Server replies **`402 Payment Required`** with payment details (price, accepted tokens, chain).
3. Client builds a signed payment payload and retries with an **`X-PAYMENT`** header (e.g. USDC).
4. A **facilitator** (such as the Coinbase x402 Facilitator) verifies and **settles the payment on-chain**.
5. Server returns the data plus an **`X-PAYMENT-RESPONSE`** confirmation.

```http
HTTP/1.1 402 Payment Required
Accept-Payment: { "amount": "0.01", "asset": "USDC", "network": "base",
                  "pay_to": "0xMerchant…", "facilitator": "https://x402.org/facilitator" }
```

It draws a direct line back to Balaji's **21.co** machine-payable-API work from the Bitcoin era — the idea is old; what's new is that on an L2 like **Base** on-chain fees dropped to ~1¢, so per-call micropayments finally pencil out. x402 charges **zero protocol fees** and supports **Base, Ethereum, Arbitrum, Polygon, and Solana**. By March 2026 it had processed **119M+ transactions on Base** and 35M on Solana, ~$600M annualized — early traction concentrated in agent-to-infra use cases: paying per GPU inference (Hyperbolic), buying structured web data (Zyte), procuring compute (OpenMind).

## How MPP works (and how it differs)

MPP, co-authored by **Stripe and Tempo**, is the broader, more bank-friendly take on the same HTTP-402 idea. The key difference from x402 is that MPP is **rail-agnostic from day one**: it starts with stablecoins on Tempo but settles equally over **cards (via Stripe/Visa), buy-now-pay-later, and Bitcoin Lightning (via Lightspark)** — using the same **Shared Payment Token (SPT)** primitive that [[agentic-commerce-protocol]] uses, which is what stitches MPP into Stripe's existing stack. A Stripe merchant accepts MPP through the ordinary **PaymentIntents API** in a few lines.

**Tempo** is the substrate: a stablecoin-focused L1 Stripe built with **Paradigm**, with **no native gas token** (fees settle in stablecoins), sub-second finality, and tens-of-thousands TPS — purpose-built for high-frequency machine payments.

| | x402 | MPP |
|---|---|---|
| Backers | Coinbase + Cloudflare + Stripe (x402 Foundation → Linux Foundation) | Stripe + Tempo (+ Paradigm) |
| Launched | May 6, 2025 | March 18, 2026 |
| Settles in | Stablecoins (USDC) on-chain | Stablecoins **+ fiat cards, BNPL, Lightning** |
| Substrate | Base, Ethereum, Arbitrum, Polygon, Solana | Tempo L1 (+ other rails) |
| Mechanism | HTTP 402 + `X-PAYMENT` header + facilitator | HTTP-native + SPT + PaymentIntents |

MPP launched with **100+ services** — including **Anthropic, OpenAI, Shopify, Alchemy, Dune** — and live agent-native businesses: **Browserbase** (agents pay per headless-browser session), **PostalForm** (agents pay to print/mail physical letters), **Prospect Butcher Co.** (agents order sandwiches for NYC delivery). Notably, Stripe supports **both** MPP and x402, treating them as complementary settlement options inside its Agentic Commerce Suite.

## Where they sit in the stack

x402 and MPP are the bottom layer — the actual value transfer. They slot under everything else: an agent proven legitimate by [[trusted-agent-protocol]], carrying an [[agent-payments-protocol]] mandate, completing an [[agentic-commerce-protocol]] checkout, can have the resulting charge settled over x402 or MPP. AP2's **A2A x402 extension** is the explicit bridge that lets an AP2 mandate authorize an x402 settlement. They're plumbing, deliberately invisible.

## Why it matters

This is the layer that makes the **machine-to-machine economy** financially real: when paying for one API call costs a fraction of a cent and clears in seconds with no account, entire business models that were impossible under subscription billing (pay-per-inference, pay-per-crawl, pay-per-article, robots buying their own compute) become trivial. Reviving HTTP 402 is an elegant move — it makes any endpoint a paywall a machine can navigate using infrastructure the web already has. The fact that Anthropic, OpenAI, and Shopify all signed onto MPP at launch, and that x402 is already doing nine-figure transaction counts, says the demand is not hypothetical.

The honest caveats are real and specific. **Crypto-native rails carry crypto-native risk:** on-chain settlement is irreversible, so the chargeback/dispute safety net that protects card buyers doesn't exist — a misfiring agent that overpays or pays the wrong recipient has limited recourse. **Stablecoin and regulatory exposure** (issuer solvency, sanctions, money-transmission rules) rides along with every transaction. And there's a **fragmentation irony**: two overlapping HTTP-402 standards (plus AP2's crypto extension) now exist where the whole pitch was "one native way to pay" — MPP's rail-agnostic, fiat-inclusive design is the more enterprise-palatable bet, while x402 has the head start and the on-chain volume, and it's not yet settled which wins or whether they converge. The primitive — a payable HTTP request — is almost certainly permanent; which brand of it dominates is not.

## Links

* https://www.x402.org/
* https://www.coinbase.com/developer-platform/discover/launches/x402
* https://docs.cdp.coinbase.com/x402/welcome
* https://www.coinbase.com/blog/coinbase-and-cloudflare-will-launch-x402-foundation
* https://stripe.com/blog/machine-payments-protocol
* https://mpp.dev/
* https://docs.stripe.com/payments/machine
* https://tempo.xyz/
* https://github.com/coinbase/x402
