# AgentDraw

**DRAWN BY AGENTS. OWNED BY YOU.**

AgentDraw is a pixel-art mint on BNB Chain: an AI agent draws original pixel art live on a 32×32 canvas, pixel by pixel, in front of you — and the finished piece becomes your NFT. Every piece is drawn at the moment it is minted; no two draws are pre-made. The live site is [agentdraw.click](https://agentdraw.click).

- **Website:** https://agentdraw.click
- **Owner deploy page:** https://agentdraw.click/deploy.html
- **Metadata:** [`meta/`](meta/) — served at https://agentdraw.click/meta/
- **Chain:** BNB Chain

## Supply & pools

Total supply is **1,444** pieces, split into two separate pools:

| Pool | Supply | Who can draw | Price | Notes |
| --- | --- | --- | --- | --- |
| Free Draw | 1,222 | Binance Agent ID holders only | 0 BNB | Max 2 per wallet. Global queue: 1 free draw every 90 seconds across all wallets. Rolls Doodle / Pixel only. |
| Instant Draw (Paid) | 222 | Every wallet — no Agent ID needed | 0.0012 BNB, stepping up (see Pricing) | Rolls all 7 style tiers. Agent ID holders may also use this pool; using your free draws never blocks a paid draw. |

**No phases.** A single mint-open switch opens both pools at the same time. Neither pool blocks the other: the Paid pool does not wait for the Free pool, the Free pool does not wait for the Paid pool, and there is no phase timer of any kind.

## Pricing

- Instant Draw base price: **0.0012 BNB**.
- The price steps up by **+0.0003 BNB for every 500 total pieces drawn** (free + paid combined): draws 0–499 cost 0.0012 BNB, draws 500–999 cost 0.0015 BNB, and so on.
- Every minted NFT also carries **1,000 $DRAW**.

## Style tiers

Each draw rolls a style tier. The tier is recorded on-chain at mint and decides which metadata template the token serves.

| Tier | Dividend weight | Paid roll odds | Availability |
| --- | --- | --- | --- |
| DOODLE | ×1 | 27% | Free + Paid |
| PIXEL | ×5 | 25% | Free + Paid |
| NEON | ×15 | 20% | Paid only |
| RARE — Prism Foil | ×25 | 12% | Paid only |
| GLITCH | ×40 | 10% | Paid only |
| GOLD FOIL | ×120 | 5% | Paid only |
| MASTERPIECE | ×400 | 1% | Paid only |

Free Draws roll only **Doodle (70%) / Pixel (30%)**. **RARE "Prism Foil"** is its own Paid-only style — iridescent prism shards on dark indigo, with diamond pixel corners — it never comes from a Free Draw.

## Metadata

Metadata uses a **per-tier template scheme — there are no pre-numbered files** (no `1.json` … `1444.json`). Token IDs follow one mint counter in mint order, and the contract's `tokenURI` returns the template matching the tier that token rolled at mint:

- [`meta/doodle.json`](meta/doodle.json)
- [`meta/pixel.json`](meta/pixel.json)
- [`meta/neon.json`](meta/neon.json)
- [`meta/rare.json`](meta/rare.json)
- [`meta/glitch.json`](meta/glitch.json)
- [`meta/gold-foil.json`](meta/gold-foil.json)
- [`meta/masterpiece.json`](meta/masterpiece.json)

The artwork files in [`nft/`](nft/) are **style samples, not minted tokens** — they show what each style looks like. Every real token's artwork is drawn live by the agent at the moment of its mint.

## Contract status

- Source: [`contracts/AgentDraw.sol`](contracts/AgentDraw.sol) — ERC-721 built on OpenZeppelin, compiled with solc 0.8.28. Compiled artifact: [`contracts/AgentDraw.json`](contracts/AgentDraw.json).
- The contract implements the rules above exactly: two independent pools (1,222 Free / 222 Paid), one mint-open switch, the global 90-second free-draw queue, max 2 free draws per wallet, the Agent ID gate checked against the Binance Agent ID registry, stepped pricing, and the per-token tier record behind `tokenURI`.
- It was **fully tested on a local EVM before publication: 63/63 checks passed**, including filling both pools exactly, pool independence in both directions, price steps at 500 / 1,000 total drawn, and owner-withdraw scenarios.
- **The contract is NOT YET DEPLOYED.** The owner deploys it from the deploy page — https://agentdraw.click/deploy.html — which embeds the exact compiled bytecode, opens the mint, checks Agent IDs, and handles withdrawals.
- All mint fees stay in the contract, and the **owner can withdraw the full contract balance at any time** (`withdraw()`, owner-only, no lockup, no conditions).

Until the contract is deployed and the mint is opened, the public website runs as an honest in-page preview: wallet connection and the Agent ID check are real on-chain reads, and the draw itself is a simulation.

## Repository structure

```
index.html            The live website (single-file build served by GitHub Pages)
deploy.html           Owner deploy page (deploy, open mint, Agent ID checker, withdraw)
contracts/            AgentDraw.sol source + compiled AgentDraw.json + build tooling
meta/                 Per-tier metadata templates + README
nft/                  Style-sample artwork (PNG) + README — samples, not minted tokens
favicon.ico           Favicon (16 / 32 / 48)
icon-192.png          App icon 192×192
icon-512.png          App icon 512×512 (also used as the maskable icon)
apple-touch-icon.png  Apple touch icon 180×180
manifest.webmanifest  Web app manifest (installable)
sw.js                 Service worker (installability + same-origin cache)
og-image.png          Social preview image (1200×630)
CNAME                 Custom domain: agentdraw.click
```

## Links

- Website — https://agentdraw.click
- Deploy page — https://agentdraw.click/deploy.html
- Metadata — https://agentdraw.click/meta/doodle.json (one template per tier)
