# Agent Payments Protocol (AP2)

## What is it?

The Agent Payments Protocol (AP2) is Google's open standard for the **authorization** layer of agentic commerce — the part that proves a user actually gave an agent the authority to make a specific purchase. Google announced it on **September 16, 2025** with **60+ partners** (Adyen, American Express, Ant International, Coinbase, Etsy, Forter, Intuit, JCB, Mastercard, Mysten Labs, PayPal, Revolut, Salesforce, ServiceNow, UnionPay, Worldpay…). It is built as an **extension of the Agent2Agent ([[a2a]]) protocol and [[mcp]]**, not a standalone rail.

The defining property: **AP2 is a trust and authorization framework, not a settlement rail.** No money moves over AP2. It captures a cryptographically verifiable chain of *user intent* that a merchant or bank can later inspect to answer "was this purchase really authorized by a human, and by whom." In April 2026 Google **donated AP2 to the FIDO Alliance** for community governance (more below), releasing **v0.2** at the same time — a deliberate move to make it a neutral multi-vendor standard rather than a Google roadmap.

## The problem it solves

Today's payment systems assume a human is clicking "buy" on a trusted surface. An autonomous agent breaks that assumption and raises three questions the existing rails can't answer, which AP2 is built around:

- **Authorization** — proving the user gave the agent authority to make *this particular* purchase.
- **Authenticity** — letting the merchant be sure the agent's request reflects the user's true intent, not a hallucinated or injected one.
- **Accountability** — determining who is liable when a transaction is fraudulent or wrong.

Without a shared answer, every wallet, network, and agent would invent its own scheme and the ecosystem fragments. AP2 is the common language so a bank can price the risk of an agent-initiated charge the way it prices a card-present one.

## How it works

AP2 builds trust out of **Mandates** — tamper-proof, cryptographically signed digital contracts carried as **W3C Verifiable Credentials (VCs)** — that form a non-repudiable audit trail from intent to payment.

| Mandate | What it captures |
|---|---|
| **Intent Mandate** | The user's instruction and its rules (what to buy, price caps, timing, conditions) |
| **Cart Mandate** | The exact items and final price the user approved — "what you see is what you pay" |
| **Payment Mandate** | The chosen payment method securely linked to the verified cart |

It handles the two ways people actually shop with agents:

- **Human present** — you say "find me white running shoes," which is captured as an Intent Mandate; the agent shows a cart, and your approval signs the **Cart Mandate**, freezing items and price.
- **Human not present** (added/hardened in v0.2) — you sign a detailed Intent Mandate *upfront* ("buy these concert tickets the moment they go on sale, up to $400"), and the agent can later generate a Cart Mandate on your behalf **only when your signed conditions are met.**

Participation is advertised the A2A way: a participant lists the AP2 extension URI in its **A2A Agent Card** under `capabilities.extensions`, and mandates are exchanged inside the live A2A conversation.

```jsonc
// A2A Agent Card fragment
"capabilities": {
  "extensions": [
    { "uri": "https://ap2-protocol.org/extensions/payments/v0.2" }
  ]
}
```

## Payment-agnostic, including crypto

AP2 is deliberately rail-neutral — cards, debit, real-time bank transfer, and **stablecoins** are all first-class. For the web3 path, Google worked with **Coinbase, the Ethereum Foundation, and MetaMask** on the **A2A x402 extension**, a production path for agent crypto payments that ties AP2's mandates to [[x402-machine-payments]] settlement. So AP2 carries the *authorization*; x402 (or cards, or MPP) carries the *money*.

## Governance: handed to the FIDO Alliance

On **April 28, 2026** Google donated AP2 to the **FIDO Alliance**, which stood up two working groups to evolve it as an open, multi-stakeholder standard:

- **Agentic Authentication TWG** — chaired by CVS Health, Google, and OpenAI (vice-chairs include Amazon and Okta).
- **Payments TWG** — chaired by **Mastercard and Visa**.

Alongside, Google and **Mastercard** contributed **Verifiable Intent**, a tamper-proof log of user-authorized agent actions, also donated to FIDO. Handing the spec to the same standards body that governs passkeys is the strongest signal that AP2 wants to be infrastructure, not a Google product.

## Where it sits versus the others

AP2 is the authorization spine; it pairs rather than competes. The clean division of labor across these notes: [[agentic-commerce-protocol]] runs the *checkout*, [[trusted-agent-protocol]] proves the *agent's identity* at the merchant edge, [[x402-machine-payments]] does *machine-native settlement*, and AP2 supplies the *signed mandate proving the buyer authorized it.* An agent can carry an AP2 mandate into an ACP checkout, giving the merchant a pre-authorization plus a scoped transaction.

## Why it matters

AP2 is the most *conceptually load-bearing* of the agentic-commerce protocols, because the question it answers — "did the human actually authorize this, and can we prove it later" — is the one that determines who eats the loss when an agent buys the wrong thing. By encoding intent as signed, verifiable credentials with a non-repudiable trail, it gives banks and networks something they can underwrite, which is why Mastercard, Visa, Amex, and PayPal all showed up. Donating it to FIDO is what turns "Google's protocol" into a plausible industry default.

The honest caveat is that AP2 is mandates on paper until the surrounding machinery is real: it depends on widely deployed verifiable-credential issuance, agents that reliably capture true intent (a signed Cart Mandate is only as honest as the agent that built the cart — prompt injection that poisons the cart still produces a "valid" mandate), and merchants/banks actually verifying the chain rather than rubber-stamping it. It also still rides on A2A/MCP adoption. And the governance win comes with a coordination cost — a FIDO multi-vendor process is slower and more political than a single-vendor sprint, so the spec's pace now depends on Mastercard, Visa, Google, and OpenAI agreeing. The primitive is the right one; the ecosystem has to grow into it.

## Links

* https://cloud.google.com/blog/products/ai-machine-learning/announcing-agents-to-payments-ap2-protocol
* https://ap2-protocol.org/
* https://github.com/google-agentic-commerce/AP2
* https://github.com/google-a2a/a2a-x402
* https://blog.google/products-and-platforms/platforms/google-pay/agent-payments-protocol-fido-alliance/
* https://fidoalliance.org/google-donates-agent-payments-protocol-to-fido-alliance/
* https://a2a-protocol.org
