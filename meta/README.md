# AgentDraw — metadata templates

One template per style tier. There is NO pre-numbering: token IDs are assigned
in mint order by the contract, and the contract's tokenURI returns the template
matching the style rolled inside that mint transaction (the same locked scheme
as the owner's other collections).

| File | Style | Weight | Paid roll | Availability |
|---|---|---|---|---|
| doodle.json | DOODLE | x1 | 27% | Free + Paid |
| pixel.json | PIXEL | x5 | 25% | Free + Paid |
| neon.json | NEON | x15 | 20% | Paid only |
| rare.json | RARE — Prism Foil | x25 | 12% | Paid only |
| glitch.json | GLITCH | x40 | 10% | Paid only |
| gold-foil.json | GOLD FOIL | x120 | 5% | Paid only |
| masterpiece.json | MASTERPIECE | x400 | 1% | Paid only |

Free Draw rolls DOODLE 70% / PIXEL 30% only. Paid roll totals 100%.
Each template's image is that style's representative sample in ../nft/.
