# Trusted Agent Protocol (TAP)

## What is it?

Trusted Agent Protocol (TAP) is an open specification that lets a merchant cryptographically answer one question on every incoming request: **is this AI agent a known, accountable agent acting for a real consumer, or just another anonymous bot?** Visa unveiled it on **October 14, 2025**, developed in collaboration with **Cloudflare**, and shipped it the same day in the Visa Developer Center and on GitHub (`github.com/visa/trusted-agent-protocol`). Visa's framing is "an ecosystem-led framework for AI commerce."

The key thing to hold onto: **no money moves over TAP itself.** It is an *identity and trust wrapper* that sits in front of whatever payment rail the merchant already runs. An agent attaches signed headers to its HTTPS requests; the merchant verifies the signature against a Visa-operated directory of agent public keys, and now knows *who* is knocking before it decides whether to let the transaction through. It layers cleanly on top of the checkout/payment protocols ([[trusted-agent-protocol]] is the recognition layer, not the charge), which is why Visa calls it "no-code for merchants."

## The problem it solves

Over the past year AI-driven traffic to U.S. retail sites surged **over 4,700%** (Adobe), and 85% of shoppers who have used AI to shop say it improved the experience. That growth breaks the merchant's existing defenses, which were built to keep bots *out*. Visa lists three concrete merchant pains:

- **Bot detection blocks the good agents.** WAFs and anti-bot systems can't tell a legitimate shopping agent from a scraper, so they reject real, consumer-authorized purchases.
- **No way to recognize a returning customer behind the agent.** The agent is opaque, so loyalty, saved addresses, and risk history don't carry over.
- **No standard channel to receive the consumer's intent and payment context** the agent is carrying on the shopper's behalf.

The structural risk Visa is actually defending is its own: if agents become the buyers by 2030, whoever owns the *agent-verification standard* owns the trust layer of commerce. TAP is Visa's bid to stay the "plumbing" even when a human is no longer the one clicking buy. This is the same identity-chokepoint logic as [[mcp-enterprise-managed-auth]], pointed at commerce instead of tool access.

## How it works

TAP adds a proof-of-identity to every agent-initiated request using **HTTP Message Signatures (RFC 9421)**, built on the emerging **Web Bot Auth** standard, with **Ed25519** signatures. The agent signs; the merchant (or its CDN) verifies against Visa's public-key directory.

```http
GET /checkout HTTP/1.1
Host: shop.example.com
Signature-Agent: "https://agent.example"
Signature-Input: sig=("@authority" "@path" "signature-agent");created=1760000000;keyid="...";alg="ed25519"
Signature: sig=:Base64Ed25519Signature==:
```

The reference implementation in the repo is a full working ecosystem across five components:

| Component | Role |
|---|---|
| **TAP Agent** (Streamlit) | Generates RFC 9421-compliant signatures on outbound requests |
| **Merchant Frontend** (React) | The e-commerce storefront the agent shops |
| **CDN Proxy** (Node.js) | Intercepts requests and verifies the agent signature at the edge |
| **Merchant Backend** (FastAPI) | Processes already-verified requests |
| **Agent Registry** | The public-key registry that maps an agent to its keys and metadata |

The four properties the spec guarantees, straight from the README's "Key Benefits":

- **Differentiate from malicious actors** — a definitive way to separate authorized agents from other automated traffic.
- **Context-bound security** — each request is cryptographically locked to the merchant's specific site *and the exact page* the agent is on, so an authorization can't be replayed elsewhere.
- **Replay protection** — signatures carry unique, time-sensitive elements; each is valid for a single use.
- **Securely receive customer & payment identifiers** — a standardized way for a verified agent to pass trusted consumer data (to pre-fill forms or recognize the customer) and payment context.

## Who is using it

TAP launched with a deliberately broad coalition spanning processors, networks, and agent platforms — the network effect is the whole strategy:

| Role | Partners at launch |
|---|---|
| **Co-developer** | Visa + **Cloudflare** (edge verification) |
| **Processors / acquirers** | **Adyen, Stripe, Worldpay, CyberSource, Elavon, Nuvei, Fiserv, Checkout.com** |
| **Agent / platform side** | **Microsoft** (Copilot), **Shopify**, **OpenAI** (via Stripe), **Ant International**, **Coinbase** |

> "We believe the entire payments ecosystem has a responsibility to ensure sellers can trust AI agents as much as they trust their best customers... focused on creating no-code functionality for merchants." — **Jack Forestell**, Chief Product & Strategy Officer, Visa.

It's early: the repo had ~180 stars and 6 commits a few weeks after launch — a published spec plus a sample, not yet a battle-tested production network.

## The landscape — alternatives and how they fit

TAP is one piece of a fragmenting stack, not a monolith. Most of these compose rather than compete:

| Protocol | Backers | Layer it owns |
|---|---|---|
| **TAP** | Visa + Cloudflare | Agent **identity / trust** at the HTTP edge |
| **ACP** (Agentic Commerce Protocol) | OpenAI + Stripe | **Checkout flow** between agent and merchant (ChatGPT Instant Checkout) |
| **AP2** (Agent Payments Protocol) | Google → donated to **FIDO Alliance** (v0.2, Apr 28 2026) | **Payment authorization** via cryptographically signed mandates |
| **MPP** (Machine Payments Protocol) | Stripe + Tempo (Mar 18 2026) | Machine-to-machine **stablecoin/fiat micropayments** |
| **x402** | Coinbase | HTTP 402 **stablecoin settlement** |
| **Agent Pay** | Mastercard | Rival **network-led** agent-payment scheme |

The clean mental model: the [[agentic-commerce-protocol]] (ACP) standardizes *how the agent checks out*, the [[agent-payments-protocol]] (AP2) provides the *signed buyer mandate proving authority*, [[x402-machine-payments]] (x402/MPP) handles *raw settlement* — and TAP is the *identity wrapper* that tells the merchant the agent is real before any of that runs. An agent can carry an AP2 mandate into an ACP checkout behind a TAP-signed request. Visa's bet is that everyone needs the recognition layer regardless of which checkout/settlement rail wins.

## Why it matters

Agentic commerce has a trust gap that nothing in the pre-agent web fills: the merchant's entire fraud and identity stack assumed a human in a browser, and now a non-human is the buyer. TAP is the first network-backed attempt to give that non-human a verifiable, accountable identity at the HTTP layer — using boring, real standards (RFC 9421, Ed25519, Web Bot Auth) rather than a proprietary black box, which is what makes "no-code for merchants" plausible: a Cloudflare-style edge already speaks this. It's the commerce-side analogue of the chokepoint pattern these notes keep returning to — the way [[merge-ai-agent-gateway]] is the chokepoint for *model* access and [[mcp-enterprise-managed-auth]] is the chokepoint for *tool/connector* access, TAP is the chokepoint for *who-is-this-agent* at the storefront.

The honest caveats are real. **First, TAP proves identity, not good behavior** — it tells you the agent is registered and authorized for this page, not that it won't do something harmful with that access, so you still need the risk and fraud layer on top (which is exactly the seam vendors like Oscilar are selling into). **Second, it re-centralizes trust on Visa.** The directory of agent public keys is Visa-operated; "open spec" does not mean "open root of trust," and a competitor running on Mastercard's Agent Pay has every reason not to defer to Visa's registry. **Third, it's a coalition announcement, not yet a deployed network** — a young repo, overlapping-and-still-shifting sibling protocols (ACP, AP2, MPP, x402), and adoption that only pays off once enough agents *and* enough merchants both implement it. The value is genuinely large if it becomes the default recognition layer; today it's a credible, well-backed standard still racing the rest of the stack to ubiquity.

## Links

* https://github.com/visa/trusted-agent-protocol
* https://usa.visa.com/about-visa/newsroom/press-releases.releaseId.21716.html
* https://investor.visa.com/news/news-details/2025/Visa-Introduces-Trusted-Agent-Protocol-An-Ecosystem-Led-Framework-for-AI-Commerce/default.aspx
* https://developer.visa.com/capabilities/trusted-agent-protocol
* https://corporate.visa.com/en/sites/visa-perspectives/newsroom/visa-partners-complete-secure-agentic-transactions.html
* https://oscilar.com/blog/visatap
* https://www.finextra.com/blogposting/29617/deep-dive-the-role-of-visas-trusted-agent-protocol-in-agentic-commerce
* https://www.crossmint.com/learn/agentic-payments-protocols-compared
* https://www.digitaltransactions.net/visa-launches-trusted-agent-an-agentic-commerce-protocol/
* https://datatracker.ietf.org/doc/html/rfc9421
