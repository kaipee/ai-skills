# Quote Capture — `<Provider Name>`

> Phase 3 artifact. **One file per provider** quoted, stored at `reports/<engagement-folder>/04-quotes/<provider-slug>.md`. Captures real, user-supplied quote figures only — the agent never runs the quote tool and never asks for full PII. Replace every `<...>` placeholder. If the quote screen does not show a value, write `not shown` (do not guess).

**Captured at:** `<UTC ISO 8601 timestamp>`
**Captured by skill:** `canadian-dog-insurance-research v<version>` (Phase 3)

---

## 1. Provider & quote identity

| Field | Value |
|---|---|
| Provider name | `<brand name as marketed in Canada>` |
| Plan / tier selected | `<e.g. Complete, Plus, Accident-only>` |
| Quote date (user ran the tool) | `<YYYY-MM-DD>` |
| Quote reference / ID | `<as shown on quote screen, or "not shown">` |
| Quote expiry date | `<YYYY-MM-DD, or "not shown">` |
| Postal code (FSA only) | `<3-character FSA, e.g. M5V — never the full postal code>` |
| Quote tool URL | `<URL>` |
| Screenshot path (optional) | `<relative path within engagement folder, or n/a>` |

> **Privacy guardrail:** if the user pasted a full postal code, DOB, full name, email, phone, or payment details, redact before saving and remind them only the figures and FSA prefix are needed.

## 2. Per-dog premium breakdown

> One row per dog on the policy. Use the same dog identifiers used elsewhere in the engagement folder.

| Dog | Breed | Age | Sex | Base monthly premium (CAD) | Wellness add-on monthly (CAD) | Discounts applied (line items, CAD) | Taxes (Ontario RST 8% line item, CAD) | Final monthly total (CAD) | Final annual total (CAD) |
|---|---|---|---|---|---|---|---|---|---|
| `<dog 1>` | | | | `$<x.xx>` | `$<x.xx or n/a>` | `<line items>` | `$<x.xx or n/a>` | `$<x.xx>` | `$<x.xx>` |
| `<dog 2>` | | | | | | | | | |

**Policy-level monthly total (CAD):** `$<x.xx>`
**Policy-level annual total (CAD):** `$<x.xx>`

## 3. Selected coverage parameters

| Parameter | Selected value |
|---|---|
| Deductible (CAD) | `<e.g. $250 annual>` |
| Reimbursement % | `<e.g. 80%>` |
| Annual limit (CAD) | `<e.g. $10,000 / unlimited>` |
| Wellness add-on cap (CAD, if applicable) | `<e.g. $400/year, or n/a>` |
| Per-condition / lifetime limits (if shown) | `<...>` |

## 4. Discount lines

| Discount | % or amount | Notes |
|---|---|---|
| Multi-pet | `<e.g. 5%>` | |
| Loyalty | | |
| Bundle (with home/auto) | | |
| Promo code | | |
| Other | | |

## 5. Notes & caveats from the quote screen

- `<verbatim caveats from the quote tool, e.g. "rates subject to underwriting at bind">`
- `<...>`

## 6. Validation status

Phase 3 quote files MUST satisfy all three before being incorporated into `02-` and `03-`:

- [ ] **(a)** Quote reference present (or explicitly `not shown`).
- [ ] **(b)** Expiry date present (or explicitly `not shown`).
- [ ] **(c)** Postal code is the **FSA only** (3 characters), not the full postal code.

If any item is unchecked, the agent must flag the gap to the user before using this quote in the comparison.

## 7. Disclaimer

These figures are user-reported live quotes obtained from the provider's own quote tool at the date above. They are **not binding**. The provider's underwriting at bind time may change the final premium. Quote references typically expire on the date shown; re-quote if expired before purchase.
