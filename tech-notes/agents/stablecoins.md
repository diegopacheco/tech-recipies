# Stablecoins

## What is a Stablecoin?

A stablecoin is a cryptocurrency designed to hold a steady value by pegging itself to an external reference asset - usually the US dollar, sometimes another fiat currency, a basket of currencies, or a commodity like gold. Most stablecoins target a 1:1 peg with the US dollar, so one token is meant to always be worth $1.00.

Unlike Bitcoin or Ether, whose price is whatever the market decides minute by minute, a stablecoin tries to absorb volatility. That makes it usable as money: a unit of account, a medium of exchange, and a short-term store of value, while still living on a public blockchain with the speed, programmability, and global reach that comes with it.

By early 2026 the total stablecoin market sits around **$317 billion** in circulation, with more than **$2 trillion** moved on-chain every month. Stablecoins are no longer just a trading tool - they have become a payments layer that Visa, Mastercard, Stripe, PayPal, Western Union, Klarna, Cloudflare, and Fiserv have all integrated or announced support for.

## How it Works

Every stablecoin has the same core problem: how to keep the on-chain token worth exactly $1 when the market wants to push it away from the peg. The mechanism splits into four families.

### 1. Fiat-backed (off-chain reserves)

The issuer holds cash, bank deposits, and short-term US Treasuries in custody. For every token in circulation, there is supposed to be one dollar of reserves.

- **Mint**: a regulated user wires USD to the issuer, the issuer mints an equal amount of tokens on-chain
- **Burn / redeem**: the user sends tokens back to the issuer, the issuer burns them and wires USD back
- **Peg defense**: arbitrage - if the token trades below $1, someone buys cheap tokens, redeems for $1 each, pockets the difference; this buying pressure pushes the price back up

Examples: USDT, USDC, PYUSD, FDUSD.

### 2. Crypto-collateralized (on-chain reserves)

The peg is backed by other crypto assets locked in smart contracts. Because crypto is volatile, the system requires **over-collateralization** - users typically lock $150-$200 of ETH or similar to mint $100 of stablecoin.

- **Mint**: deposit ETH, wBTC, or other approved collateral; smart contract mints stablecoin against it
- **Liquidation**: if collateral value drops below a threshold, the contract automatically sells it to keep the system solvent
- **Peg defense**: stability fees, liquidation penalties, and savings rates that contract or expand supply

Example: DAI (MakerDAO / Sky), LUSD, crvUSD.

### 3. Commodity-backed

Each token represents a claim on a physical commodity, usually gold, held by a custodian. Same minting/redemption pattern as fiat-backed but with a non-currency reference.

Examples: PAXG (Paxos Gold), XAUT (Tether Gold).

### 4. Algorithmic

No collateral, or only partial collateral. Algorithms expand and contract supply to defend the peg.

- If price > $1, mint more tokens (sell pressure pushes price down)
- If price < $1, burn tokens or buy them back (reduces supply, pushes price up)

This category has a poor track record. **TerraUSD (UST)** collapsed in May 2022, wiping out tens of billions of dollars in days, and it remains the cautionary tale for purely algorithmic designs.

## Main Stablecoins and Platforms

| Stablecoin | Issuer | Type | Approx. Market Cap (2026) | Notes |
|---|---|---|---|---|
| **USDT** (Tether) | Tether | Fiat-backed | ~$184B | Market leader, ~60% share, deepest liquidity, multi-chain |
| **USDC** | Circle | Fiat-backed | ~$77B | Monthly attestations, US-regulated, favored by institutions |
| **DAI / USDS** | Sky (MakerDAO) | Crypto-collateralized | ~$5B | Decentralized, on-chain governance, DeFi staple |
| **PYUSD** | PayPal / Paxos | Fiat-backed | ~$1B+ | PayPal-issued, integrated with PayPal/Venmo rails |
| **FDUSD** | First Digital | Fiat-backed | ~$2-3B | Hong Kong-based, popular on Binance |
| **PAXG** | Paxos | Commodity-backed | ~$1B | Each token = 1 oz of LBMA-certified gold |
| **USDe** | Ethena | Synthetic / delta-neutral | ~$5B | Backed by hedged ETH positions, yield-bearing |

USDT and USDC together hold more than 80% of the market and provide the deepest liquidity across exchanges and DeFi.

### Networks

Stablecoins are issued natively across many chains. The biggest hosts:

- **Ethereum** - the original home, most institutional usage, highest fees
- **Tron** - dominant for USDT retail transfers in emerging markets, low fees
- **Solana** - fast and cheap, growing fast for payments
- **Base, Arbitrum, Optimism** - Ethereum L2s, cheap and EVM-compatible
- **BNB Chain, Avalanche, Polygon** - other major hosts
- **Stellar** - used by MoneyGram and Circle for cross-border settlement

## Use Cases

### 1. Trading and crypto-native finance
The original use case. Traders park funds in stablecoins between trades to avoid volatility, and stablecoins are the dominant quote currency on every major exchange. Stablecoins now account for nearly 70% of DeFi transaction volume.

### 2. Cross-border payments and remittances
Send dollars to anyone in the world in minutes for under $1, versus 3-7 days and 6%+ fees through traditional rails. Workers in countries with capital controls or weak currencies (Argentina, Nigeria, Turkey, Venezuela) use USDT and USDC as a digital dollar savings account.

### 3. B2B payments
The largest stablecoin payment category by volume - around 63% of payment activity. Companies use stablecoins for supplier payments, payroll for international contractors, and treasury movement between subsidiaries. Walmart and Amazon have publicly explored stablecoin vendor payments.

### 4. DeFi primitive
Lending, borrowing, yield farming, AMM liquidity, and basis trading all run on stablecoins. Aave, Compound, Curve, Morpho, and Uniswap depend on stablecoin liquidity to function.

### 5. Dollar access in emerging markets
In countries with restricted dollar access or hyperinflation, stablecoins are a way for households and small businesses to hold dollars without a US bank account. Adoption in Latin America, Sub-Saharan Africa, and Southeast Asia continues to accelerate.

### 6. Merchant payments and e-commerce
Stripe, Shopify, Visa, and Mastercard now settle stablecoin payments. Cloudflare, Klarna, and PayPal accept or settle in stablecoins. Costs are lower than card interchange and settlement is near-instant.

### 7. Tokenized cash for institutions
Banks and asset managers use stablecoins (and tokenized deposits) for 24/7 instant settlement of repo, FX, and securities trades that traditionally settle T+1 or T+2.

### 8. Programmable money
Smart contracts can hold and move stablecoins automatically: subscriptions, escrow, streaming payroll, conditional payments, and on-chain treasury automation that legacy banking cannot replicate.

## Pros

- **Price stability** - usable as money without crypto volatility
- **24/7 settlement** - no banking hours, no weekends, no holidays
- **Speed** - confirmations in seconds to minutes versus days
- **Low cost** - cents to a few dollars versus percentage-based wire and card fees
- **Global reach** - same token works the same way in every country with internet
- **Programmability** - smart contracts can move and hold stablecoins automatically
- **Dollar access** - effective digital USD account for users without one
- **Transparency** - on-chain supply is publicly auditable in real time
- **Composability** - plug into the entire DeFi stack as collateral or liquidity

## Cons

- **Issuer risk** - fiat-backed stablecoins depend on the issuer actually holding the reserves they claim; bank failures or fraud can break the peg (USDC briefly depegged in March 2023 during the Silicon Valley Bank failure)
- **Centralization** - issuers like Circle and Tether can freeze addresses and blacklist tokens at law enforcement request
- **Regulatory uncertainty** - rules differ between US, EU (MiCA), UK, Singapore, UAE, and elsewhere; some stablecoins are unavailable in some jurisdictions
- **Smart contract risk** - bugs in the issuing contracts or DeFi integrations can lose funds
- **Algorithmic failure** - undercollateralized designs have a history of catastrophic failure (Terra/UST)
- **Custody risk** - self-custody requires managing keys; custodial wallets create counterparty risk
- **Off-ramp friction** - converting stablecoins back to fiat still depends on banks and exchanges
- **Limited yield** - holding raw stablecoins earns nothing; yield-bearing variants reintroduce risk
- **Chain fragmentation** - the same nominal token (e.g., USDC) on different chains is technically different assets and bridges have been hacked many times
- **Surveillance** - public blockchains mean every transfer is traceable forever

## Regulation

Regulation matured significantly in 2024-2026:

- **EU - MiCA** - Markets in Crypto-Assets regulation requires stablecoin issuers to be licensed, hold full reserves, and publish whitepapers
- **US - GENIUS Act / payment stablecoin frameworks** - federal-level frameworks for payment stablecoin issuers, including reserve, audit, and redemption requirements
- **UK, Singapore, UAE, Hong Kong, Japan** - each has issued or is finalizing stablecoin issuer licensing regimes
- **Travel Rule and AML/KYC** - apply to stablecoin transfers above thresholds at regulated VASPs

The trend is clear: regulated, fully-reserved, audited stablecoins (USDC, PYUSD, regulated USDT variants) are gaining institutional share, while unregulated or opaque issuers are being squeezed out of major markets.

Sources:
- [Stablecoins (2026): Types, Regulation & Use Cases - Chainlink](https://chain.link/education-hub/stablecoins)
- [What is a Stablecoin: types, trade-offs - Chainstack](https://chainstack.com/what-is-a-stablecoin/)
- [Stablecoin - Wikipedia](https://en.wikipedia.org/wiki/Stablecoin)
- [Stablecoin Market Cap Chart, Supply & Peg Data - DefiLlama](https://defillama.com/stablecoins)
- [Top Stablecoin Tokens by Market Capitalization - CoinMarketCap](https://coinmarketcap.com/view/stablecoin/)
- [Stablecoin Market Tops $317 Billion - MEXC News](https://www.mexc.co/news/421705)
- [Stablecoins: from DeFi primitive to global financial infrastructure - Bessemer](https://www.bvp.com/atlas/stablecoins-from-defi-primitive-to-global-financial-infrastructure)
- [What Are Stablecoins Used for Today - Federal Reserve Bank of Kansas City](https://www.kansascityfed.org/research/payments-system-research-briefings/what-are-stablecoins-used-for-today-estimating-the-distribution-of-stablecoins/)
- [Stablecoin Utility and the Future of Payments - Chainalysis](https://www.chainalysis.com/blog/stablecoin-utility-future-of-payments/)
- [Stablecoins payments infrastructure for modern finance - McKinsey](https://www.mckinsey.com/industries/financial-services/our-insights/the-stable-door-opens-how-tokenized-cash-enables-next-gen-payments)
- [What are stablecoins, and how are they regulated - Brookings](https://www.brookings.edu/articles/what-are-stablecoins-and-how-are-they-regulated/)
- [10 Incredible Stablecoin Use Cases Beyond Trading in 2026 - Transak](https://transak.com/blog/stablecoin-use-cases-beyond-trading-in-2026)
- [Best Dollar Stablecoins in 2026: USDC vs USDT vs DAI - Bleap](https://www.bleap.finance/en-us/blog/best-stablecoins-which-one-should-you-hold)
