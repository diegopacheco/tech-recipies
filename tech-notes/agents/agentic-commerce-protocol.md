# Agentic Commerce Protocol (ACP)

## What is it?

The Agentic Commerce Protocol (ACP) is an open standard for the **checkout** itself — the interaction model that connects a buyer, their AI agent, and a business so a purchase can complete inside the agent's surface instead of on the merchant's website. It is co-developed and jointly maintained by **OpenAI and Stripe** as Founding Maintainers, first released **September 29, 2025**, and is what powers **Instant Checkout in ChatGPT** ("buy it in ChatGPT"). The spec lives at `agenticcommerce.dev` and on GitHub (~1.4k stars, 100+ commits), and is explicitly still in **`beta`**.

The single most important design choice: ACP standardizes how an agent drives a merchant's cart and payment **over plain HTTPS REST/JSON**, while the **merchant stays the merchant of record** and keeps its existing commerce infrastructure. The agent is a sales channel, not the seller. If a merchant already takes payments with Stripe, enabling agentic checkout is "as little as one line of code." This is the checkout layer that the identity layer ([[trusted-agent-protocol]]) and the authorization layer ([[agent-payments-protocol]]) wrap around.

## The problem it solves

Agents can already browse and compare; the wall is the buy button. Every merchant's checkout is bespoke, and the only way an agent could complete one was to either screen-scrape a human checkout flow or be handed the user's raw card details — both fragile and unsafe. ACP makes the checkout itself a documented API so an agent can manage a cart, choose fulfillment, and submit payment the same way at any participating merchant, and it does so **without the agent ever becoming the merchant of record or seeing real card credentials.** That last part is the unlock: it lets a merchant accept agent-driven sales without surrendering the customer relationship, tax/refund obligations, or PCI exposure that being merchant-of-record implies.

## How it works

ACP defines three roles and two HTTP API surfaces. The agent calls endpoints the merchant exposes; everything is ordinary REST with JSON Schema-defined payloads.

| Role | What they get |
|---|---|
| **Business / merchant** | Reach high-intent buyers through agents using existing infra; stays merchant of record |
| **AI agent** (ChatGPT, etc.) | Embeds commerce in its app; transacts *without* being merchant of record |
| **Payment provider** (Stripe) | Grows volume by passing secure payment tokens between buyer and business through the agent |

The two specs:

- **Agentic Checkout API** — create and update a checkout session: line items, fulfillment options, totals, then completion. The agent POSTs cart state to the merchant and gets back a fully priced, fulfillable order.
- **Delegate Payment API** — how a payment credential is handed over safely.

The payment primitive that makes it safe is Stripe's **Shared Payment Token (SPT)**: the buyer authorizes once, and Stripe issues a token that lets the agent (ChatGPT) initiate *this* payment **without exposing the buyer's card number** to the agent or the merchant.

```http
POST /agentic_checkout/checkout_sessions HTTP/1.1
Host: merchant.example.com
Authorization: Bearer <merchant-scoped-key>
Content-Type: application/json

{ "items": [{ "id": "sku_123", "quantity": 1 }],
  "fulfillment_address": { "country": "US", "postal_code": "94016" } }
```

The merchant replies with the priced session (taxes, shipping options, totals); the agent later completes it by attaching an SPT rather than a PAN.

## The spec is moving fast

ACP ships dated, versioned releases — a good signal of how live it is:

| Version | Added |
|---|---|
| 2025-09-29 | Initial release (agentic checkout) |
| 2025-12-12 | Fulfillment enhancements |
| 2026-01-16 | Capability negotiation |
| 2026-01-30 | Extensions, discounts, payment handlers |
| 2026-04-17 | Cart, feed, orders, authentication, **MCP** integration |

Governance is consensus-based between OpenAI and Stripe today, with a stated path toward "neutral foundation stewardship as the ecosystem matures" — the same trajectory [[x402-machine-payments]] and [[agent-payments-protocol]] have already taken.

## Who is using it

ChatGPT is the flagship surface. **Etsy** sellers were live in the US at launch; **Shopify's** million-plus merchants — named examples **Glossier, Vuori, Spanx, SKIMS** — followed. Stripe is the reference payment provider, and **PayPal** and others have since aligned. Because the merchant keeps its stack, adoption is mostly a matter of exposing the endpoints rather than re-platforming.

## Where it sits versus the others

ACP owns the **moment of checkout** and nothing else. It composes cleanly with the rest of the agentic-commerce stack rather than competing with it: an agent can carry an [[agent-payments-protocol]] mandate (proof the user authorized this purchase) into an ACP checkout, run behind a [[trusted-agent-protocol]] signed request (proof the agent is who it claims), and settle the charge over cards, [[x402-machine-payments]], or anything Stripe supports. ACP answers "how does the agent complete the cart"; it does not, by itself, prove the buyer's intent or the agent's identity.

## Why it matters

ACP is the most *commercially deployed* of the agentic-commerce protocols because it solved the least glamorous, most blocking problem first: a standard checkout an agent can actually drive, with a payment token that keeps the merchant as merchant of record and the card number out of the agent. That combination is why a million Shopify merchants could switch it on without re-architecting, and why "buy it in ChatGPT" became real product rather than a slide.

The honest caveat is scope and neutrality. ACP is still `beta` and governed by exactly two companies — OpenAI and Stripe — both of which have an obvious commercial interest in where agent-driven sales and the payments behind them flow; "open standard, two-vendor control" is a real tension until the promised neutral foundation materializes. And ACP deliberately does *not* cover agent identity or buyer authorization, so on its own it can't tell a merchant whether the agent is legitimate or whether the human truly approved this cart — it needs TAP and AP2 alongside it to be safe at scale. It's the checkout rail, not the trust model.

## Links

* https://github.com/agentic-commerce-protocol/agentic-commerce-protocol
* https://www.agenticcommerce.dev/
* https://openai.com/index/buy-it-in-chatgpt/
* https://stripe.com/blog/developing-an-open-standard-for-agentic-commerce
* https://stripe.com/newsroom/news/stripe-openai-instant-checkout
* https://docs.stripe.com/agentic-commerce/acp
* https://docs.stripe.com/agentic-commerce/concepts/shared-payment-tokens
