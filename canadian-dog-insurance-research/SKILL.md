---
name: canadian-dog-insurance-research
description: Researches and compares Canadian dog/pet insurance policies and writes a structured report set to disk under a per-engagement reports/ folder, then captures user-supplied live CAD quotes to finalize a real-figures recommendation. Use when the user asks about Canadian pet or dog insurance, wants a policy comparison, evaluates coverage, premiums, deductibles, exclusions, waiting periods, reimbursement, or annual limits, mentions Trupanion, Petsecure, Pets Plus Us, Fetch, OVMA, Furkin, Sonnet, Desjardins, or CAA, asks which insurer is best for their dog, wants a sample policy wording read, or needs province-specific (ON, BC, AB, QC, MB, SK, NS, NB, PE, NL) availability. Auto-discovers providers, fetches live provider pages and PDFs, cross-references regulators (OSFI, AMF, FSRA, IBC, CVMA), tags anecdotal sources, embeds UTC timestamps, prompts the user to run quote tools themselves (agent never asks for full PII — FSA only), and outputs briefs, comparison, and final recommendation with citations.
license: MIT
compatibility: Requires curl and internet access for live provider lookups. WebFetch (or equivalent agent-side rendering) recommended for JS-rendered quote tools. PDF reader helpful when extracting from sample policy wordings. No API keys required.
metadata:
  author: Keith Patton
  author_id: github.com/kaipee
  version: "0.2.0"
  scope: canada
  domain: pet-insurance
---

# Canadian Dog Insurance Research

Produces structured, citation-backed comparison reports of Canadian dog insurance policies. The skill auto-discovers current providers (rather than relying on a hardcoded list), fetches live data from each provider's own materials, normalizes findings into a consistent schema, then captures **real, user-supplied quote figures** to finalize a recommendation grounded in actual CAD premiums.

## When to use this skill

Activate when the user:

- Asks for a comparison of Canadian dog/pet insurance providers.
- Names a specific Canadian insurer (Trupanion, Petsecure, Pets Plus Us, Fetch, OVMA Pet HealthCare Plan, Furkin, Sonnet, Desjardins, CAA, President's Choice, etc.) and wants policy detail.
- Wants help understanding coverage, exclusions, deductibles, waiting periods, reimbursement rates, annual or lifetime limits, hereditary/congenital coverage, dental coverage, alternative therapies, or claims process.
- Needs province-specific availability or pricing context (Quebec is regulated separately by AMF and may have French-only wordings).
- Provides a sample policy PDF or URL and asks for it to be summarized or compared.
- Is choosing an insurer for a specific dog (age, breed, pre-existing conditions, postal code).

## Critical operating principles

1. **Live fetch, never fabricate.** Numeric figures (premiums, deductibles, limits) MUST come from a fetched source with a recorded URL and retrieval timestamp. Never estimate or recall figures from training data.
2. **As-of timestamps are mandatory.** Every figure carries a UTC date. Reports include a top-level "Data captured at" header and a footer disclaimer.
3. **Desk-research premiums are RANGES; final premiums are USER-CAPTURED LIVE QUOTES.** Phase 2 reports ranges drawn from provider materials; Phase 3 replaces them with actual CAD figures the user obtained from the quote tools themselves.
4. **Cite everything.** Every claim links to its source. Anecdotal sources (Reddit, BBB, review aggregators) are clearly tagged and never used for numeric figures.
5. **Auto-discover, don't hardcode.** Query for current Canadian providers each run. Validate Canadian eligibility before including a provider.
6. **Privacy guardrail — the agent never asks for full PII.** The agent must never request the user's full postal code, date of birth, email, phone number, payment details, or other personal identifiers. The user runs the quote tool on their own machine; the agent only ingests the resulting **figures** (premium amounts, deductible/reimbursement/limit selections, quote reference, expiry, FSA-only postal-code prefix). Flag and refuse if the user attempts to paste full PII.

## Reports output convention

All artifacts produced by this skill are **written to disk** — never returned only inline.

- **Base directory:** `canadian-dog-insurance-research/reports/`
- **Per-engagement folder:** `reports/<YYYY-MM-DD>-<short-slug>/`
- **Required files inside each engagement folder:**

  | File | Purpose | Source template |
  |---|---|---|
  | `README.md` | Index: user profile, file list, status, phase reached | (free-form) |
  | `01-provider-briefs.md` | One section per researched provider | [`assets/provider-brief-template.md`](assets/provider-brief-template.md) |
  | `02-comparison-and-recommendation.md` | Side-by-side comparison + trade-off framing | [`assets/comparison-template.md`](assets/comparison-template.md) |
  | `03-final-recommendation.md` | User-facing executive summary, shortlist, confirm-at-quote checklist | (free-form, derived from `02-`) |
  | `04-quotes/` | One file per provider quoted in Phase 3 | [`assets/quote-capture-template.md`](assets/quote-capture-template.md) |

- **Worked example:** see [`reports/2026-05-08-toronto-cockapoo-schnauzer/`](reports/2026-05-08-toronto-cockapoo-schnauzer/) for a fully-populated engagement.

### Naming conventions

- **Date:** ISO date `YYYY-MM-DD` in UTC, taken at the moment the engagement starts.
- **Slug:** lowercase kebab-case, derived from the user's location + pet summary. Format: `<city-or-region>-<dog1-breed>[-<dog2-breed>...]`. Examples: `toronto-cockapoo-schnauzer`, `vancouver-mixed-senior`, `montreal-frenchie`. Keep ≤60 chars; drop articles and qualifiers.
- **Per-provider quote files:** `04-quotes/<provider-slug>.md` where `<provider-slug>` is the lowercase kebab-case provider brand name (e.g., `trupanion.md`, `pets-plus-us.md`).
- **Immutability:** an engagement folder is **immutable once final** (Phase 3 complete and the user has accepted `03-final-recommendation.md`). Re-running the skill — for new pets, a new postal code, or a refreshed market scan — creates a **new** dated folder. Never overwrite a finalized engagement; supersede it.

## Workflow

The skill runs in three phases. Phases 1–2 are desk research; Phase 3 captures real CAD quotes from the user.

### Phase 1 — Scope & desk research

#### 1. Capture user scope

Ask, in one consolidated turn, for any missing values. **Do not request full PII** (full postal code, DOB, email, phone). FSA prefix only (e.g., `M5V`).

- Provinces of interest (default: all 10).
- Dog details: age, breed, known pre-existing conditions, spayed/neutered status.
- Owner priorities: budget ceiling, coverage focus (accident-only vs. comprehensive), interest in alternative/dental/behavioral coverage.
- Output mode: comparison report (default) or single-provider deep-dive brief.
- Whether the user has a sample policy PDF or URL to include.

Then **create the engagement folder** under `reports/<YYYY-MM-DD>-<short-slug>/` and seed `README.md` with the captured profile and a "Status: Phase 1 — scope captured" line.

#### 2. Discover current providers

Use web search to enumerate active Canadian dog insurance providers. Validate each by:

- Confirming Canadian operations on the provider's own site (Canadian domain or explicit Canada page; underwriter licensed in Canada).
- Confirming province availability (drop or flag providers unavailable in the user's provinces).

Pass: providers with a live Canadian site and disclosed underwriter. Fail: US-only sites, defunct operations, brokerages that resell other underwriters without disclosing terms.

#### 3. Fetch primary sources

For each provider, fetch:

1. The plan/coverage page.
2. The pricing/quote page (note SPA quote tools may not render via plain `curl` — fall back to WebFetch / agent-side rendering, and if no public ranges are available, record "quote tool only — request a personalized quote").
3. Sample policy wording PDF(s) where linked publicly. Wordings are the authoritative source for exclusions and waiting periods.
4. The FAQ/claims page.

The helper [`scripts/fetch-provider-page.sh`](scripts/fetch-provider-page.sh) caches HTML and PDFs into a timestamped directory and emits an index file (URL, HTTP status, SHA256, retrieval UTC) for traceability.

#### 4. Cross-reference

After provider materials are captured:

- Check Canadian regulator/industry sources for context: OSFI (federal solvency), provincial regulators (AMF Quebec; FSRA Ontario; BCFSA BC; AIRB Alberta; FCAA Saskatchewan; etc.), Insurance Bureau of Canada (IBC), and the Canadian Veterinary Medical Association (CVMA) for veterinary cost framing.
- Sample independent reviews and forums (Reddit r/PersonalFinanceCanada, BBB Canada, reputable consumer review sites). Treat strictly as anecdotal signal; never as a source for numeric coverage figures. Tag every such citation as "anecdotal".

#### 5. Extract fields

Populate the schema defined in [`references/data-fields.md`](references/data-fields.md). Every field has a normalization rule and a source-priority order. Missing fields are recorded as `unknown` with a one-line reason.

#### 6. Apply Canadian context

Read [`references/canadian-context.md`](references/canadian-context.md) for: provincial regulatory differences, sales-tax treatment of premiums, Quebec-specific items (AMF, French-language wordings), USD-denominated providers (Trupanion historically), and structural model differences (per-condition vs. annual deductibles).

### Phase 2 — Render desk-research artifacts

Write the following files into the engagement folder:

1. `01-provider-briefs.md` — one section per provider, each filled from [`assets/provider-brief-template.md`](assets/provider-brief-template.md). In Phase 2 the **Sample premium ranges** section uses the desk-research placeholder state (premium = "quote required — Phase 3").
2. `02-comparison-and-recommendation.md` — filled from [`assets/comparison-template.md`](assets/comparison-template.md). The template is a **wide multi-column master table** (insurers as rows, ~33 numbered attribute columns spanning identity, geography, coverage scope, exclusions/waits, cost structure, and live quotes), modelled on the public US comparison doc archived at [`references/source-pet-insurance-comparison.txt`](references/source-pet-insurance-comparison.txt) and adapted to Canada (CAD figures, provincial availability, AMF/Quebec language, billing currency, direct vet pay, underwriter disclosure). Each column maps 1:1 to a field in [`references/data-fields.md`](references/data-fields.md). The **Live monthly CAD** and **Quote ref / expiry** columns are left as `quote required — Phase 3` until Phase 3 runs. The master table is the canonical artifact; section views (A–D) are derived projections for narrow rendering — never drop columns from the master.
3. `03-final-recommendation.md` — preliminary executive summary identifying a **shortlist (typically 2–3 providers)** worth quoting. Include the provider quote-tool URLs verbatim — the user will use them in Phase 3.

Update `README.md` status to "Phase 2 — desk research complete; awaiting user quote capture."

### Phase 3 — Live quote capture (user-supplied)

After Phase 2 produces the shortlist, **pause and prompt the user** to run the quote tools themselves and report back the figures. The agent does not run the quote tools and never asks for full PII (see operating principle 6).

#### 1. Prompt the user (use this template verbatim)

> *"To finalize a real recommendation, please run the quote tools for each shortlisted provider using your own postal code and the dogs' details. For each provider, paste back: monthly premium (CAD, before and after Ontario RST if shown separately); the deductible, reimbursement %, and annual limit you selected; any multi-pet discount applied; the wellness add-on monthly cost (if added); and the quote reference number / expiry date if shown. Provider quote URLs to use are listed in `03-final-recommendation.md`."*

#### 2. Capture each quote to disk

For every provider the user quotes, create `reports/<engagement-folder>/04-quotes/<provider-slug>.md` from [`assets/quote-capture-template.md`](assets/quote-capture-template.md). One file per provider. Capture (per template):

- Provider name, plan/tier selected, quote date, quote reference, quote expiry.
- **FSA-only** postal code (e.g., `M5V`) — never the full postal code.
- Per-dog premium breakdown: identifier, breed, age, sex, base monthly premium (CAD), wellness add-on monthly (CAD), discounts applied with line-item amounts, taxes (Ontario RST 8% line item if applicable), final monthly total (CAD), final annual total (CAD).
- Selected coverage parameters: deductible, reimbursement %, annual limit, wellness add-on cap if applicable.
- Discount lines: multi-pet %, loyalty %, bundle %, promo code.
- Notes / caveats from the quote screen.
- Source: quote tool URL + (optional) screenshot path supplied by the user.

#### 3. Validate each captured quote

Before incorporating a captured quote into the comparison, verify it includes:

- (a) a **quote reference** (or explicit "no reference shown"),
- (b) an **expiry date** (or explicit "no expiry shown"),
- (c) the **FSA-only** postal code (refuse / strip if the user pasted a full postal code).

If any of (a), (b), or (c) is missing, flag the gap back to the user and ask them to re-check the quote screen before proceeding. Do not silently fill in.

#### 4. Re-generate downstream artifacts

Once one or more quotes are validated, **re-generate** in place:

- `02-comparison-and-recommendation.md` — populate the **Live Monthly Premium (CAD)** column from the `04-quotes/` files; reorder the recommendation framing based on the actual price-vs-coverage trade-offs (not desk ranges).
- `03-final-recommendation.md` — update the shortlist ordering, executive summary, and confirm-at-quote checklist to reference real CAD figures with quote references and expiry dates. Update the disclaimer to state that figures are now **user-reported live quotes** (still non-binding pending purchase, since underwriting can change the final bind price).
- `01-provider-briefs.md` — switch the **Sample premium** section for each quoted provider from the desk-research placeholder to the post-Phase-3 state, linking to `04-quotes/<provider-slug>.md`.

#### 5. Finalize

Update `README.md` status to "Phase 3 — finalized with user-captured quotes; engagement folder is now immutable. Re-running creates a new dated folder."

## Edge cases

- **JS-rendered quote tools.** Several insurers' quote flows are SPAs. Plain `curl` will return a near-empty shell. Use WebFetch (which usually receives a rendered snapshot) or document "quote tool only — public ranges unavailable" rather than guess. In Phase 3 this is moot — the user runs the SPA themselves.
- **Provincial gaps.** Quebec is the most common gap (separate AMF licensing). Some smaller insurers exclude territories (Yukon, NWT, Nunavut). Check explicitly.
- **Underwriter vs. brand.** Many "providers" are MGAs or brokerages whose policies are underwritten by a third party (e.g., Northbridge, Trisura, Old Republic). Capture the underwriter; their solvency profile is what matters.
- **Bilateral conditions clause.** Many policies treat a condition on the opposite limb (e.g., second cruciate ligament tear) as related to the first — record this explicitly per provider.
- **Pre-existing condition definitions vary.** Some treat a resolved condition with a clean look-back as eligible after a defined period; others permanently exclude. Capture the wording verbatim where significant.
- **Age limits.** Most insurers cap *new* enrollment at 8–14 years depending on breed. Renewability into senior years is usually unrestricted but premiums climb steeply. Capture both.
- **Waiting periods differ by event type.** Accident waits (often 48 hours) are shorter than illness waits (often 14 days), and orthopedic/cruciate waits can be 6 months. Capture all three.
- **USD vs. CAD billing.** Trupanion (and possibly others) historically billed in USD with FX exposure. Check current billing currency and call it out.
- **French-only documents.** Quebec wordings may be French-only. Note language availability; do not machine-translate without the user's request.
- **Bank/auto/membership offerings.** CAA, Desjardins, and similar offer pet insurance bundled or as a member benefit. Capture eligibility constraints (membership required, regional restrictions).
- **User pastes full PII.** If the user pastes a full postal code, DOB, full name on quote, email, phone, or card details, **strip / redact before saving** and remind the user the agent only needs the figures and FSA prefix.

## Bundled resources (progressive disclosure)

Read on demand to keep context lean.

- [`references/data-fields.md`](references/data-fields.md) — canonical extraction schema with field definitions, types, normalization rules, source priorities, and a **column-number → field-name → comparison-table-column** mapping that aligns 1:1 with [`assets/comparison-template.md`](assets/comparison-template.md).
- [`references/canadian-context.md`](references/canadian-context.md) — Canadian regulatory, tax, linguistic, and veterinary-cost context.
- [`references/source-pet-insurance-comparison.txt`](references/source-pet-insurance-comparison.txt) — archived plain-text export of the public US Google Doc whose multi-column row-per-insurer layout the comparison template mirrors. Read only when reasoning about column choices or footnote conventions.
- [`assets/comparison-template.md`](assets/comparison-template.md) — wide multi-column comparison table (insurers as rows, ~33 numbered attribute columns) with Canadian adaptations (CAD, provincial availability, Quebec/AMF, billing currency, direct vet pay, live-quote columns for Phase 3) and a column legend.
- [`assets/provider-brief-template.md`](assets/provider-brief-template.md) — markdown template for single-provider deep-dives (two-state premium section: desk-research placeholder vs. post-Phase-3 captured quote).
- [`assets/quote-capture-template.md`](assets/quote-capture-template.md) — per-provider Phase 3 quote-capture template; one file per provider in `04-quotes/`.
- [`scripts/fetch-provider-page.sh`](scripts/fetch-provider-page.sh) — POSIX shell helper that fetches provider HTML/PDFs into a timestamped cache with a traceability index.
- [`reports/2026-05-08-toronto-cockapoo-schnauzer/`](reports/2026-05-08-toronto-cockapoo-schnauzer/) — worked example engagement folder.

## Output validation checklist

Before declaring an engagement done:

- [ ] Engagement folder exists at `reports/<YYYY-MM-DD>-<short-slug>/` and `README.md` records phase status.
- [ ] `01-provider-briefs.md`, `02-comparison-and-recommendation.md`, and `03-final-recommendation.md` are present.
- [ ] Top-of-report `Data captured at: <UTC timestamp>` is present in each generated file.
- [ ] Every numeric figure (premium, deductible option, limit, reimbursement %) cites a source URL with retrieval UTC timestamp **or** a `04-quotes/<provider-slug>.md` file (Phase 3).
- [ ] Every provider row records: underwriter, provincial availability, enrollment age range, all three waiting periods (accident, illness, orthopedic), pre-existing handling, bilateral clause, deductible model, reimbursement options, annual/lifetime limit, dental & alternative coverage status, claims channels, and currency.
- [ ] Anecdotal sources are tagged "anecdotal" and not used for numeric figures.
- [ ] Missing fields are explicitly `unknown` with a reason — never silently omitted.
- [ ] Footer disclaimer states figures are non-binding (and, post-Phase-3, that user-reported live quotes remain subject to the provider's bind-time underwriting).
- [ ] Citations section lists every URL fetched, with retrieval timestamps.
- [ ] Provincial scope of the report matches the user's stated scope (or notes the deviation).
- [ ] **Phase 3 (if run):** every `04-quotes/<provider-slug>.md` includes quote reference, expiry date, and FSA-only postal code; `02-` and `03-` reference real CAD figures; `01-` brief premium sections link to the corresponding quote file.
- [ ] **Privacy:** no full postal codes, DOB, email, phone, or payment details stored anywhere in the engagement folder.
