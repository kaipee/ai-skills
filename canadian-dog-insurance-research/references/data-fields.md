# Data Fields — Canonical Extraction Schema

This is the authoritative schema for extracting policy attributes from Canadian dog insurance providers. Use it as the column set for comparison reports and the field set for single-provider briefs.

## Source-priority order

For every field, prefer sources in this order:

1. **Sample policy wording PDF** (authoritative for exclusions, waiting periods, definitions).
2. **Provider's coverage / plan page** (authoritative for plan tiers and headline coverage claims).
3. **Provider's FAQ / claims page** (authoritative for claims process and customer service).
4. **Provider's pricing or quote tool** (only source for premium ranges; capture as ranges, not point quotes).
5. **Regulator / industry sources** (OSFI, AMF, FSRA, IBC) — used for context and underwriter solvency, not coverage figures.
6. **Independent reviews / forums** — anecdotal only; never cite for numeric figures. Tag explicitly as "anecdotal".

If a field is unavailable from sources 1–4, mark it `unknown` with a one-line reason. Never guess.

## Field schema

Each field below is defined with: **name**, **type**, **normalization rule**, and **example**.

### Section A — Identity & administration

| Field | Type | Normalization | Example |
|---|---|---|---|
| `provider_name` | string | Brand name as the provider markets itself in Canada. | `Trupanion Canada` |
| `underwriter` | string | Legal underwriter as disclosed in policy wording. `unknown` if not disclosed. | `Omega General Insurance Company` |
| `parent_company` | string | Ultimate parent if different from underwriter. | `Trupanion, Inc.` |
| `provider_url` | string (URL) | Canonical Canadian-facing landing page. | `https://trupanion.com/canada` |
| `policy_wording_urls` | list of URL | Public PDF wordings retrieved. | `[".../sample-policy.pdf"]` |
| `quote_tool_url` | string (URL) | Public quote/pricing entry point. | `https://example.ca/quote` |

### Section B — Eligibility & geographic availability

| Field | Type | Normalization | Example |
|---|---|---|---|
| `provinces_available` | list | ISO subdivision codes (e.g. `ON`, `QC`, `BC`). Use `ALL` only if explicitly stated. | `[ON, BC, AB, SK, MB, NB, NS, PE, NL]` |
| `provinces_excluded` | list | Subdivisions explicitly excluded. | `[QC, YT, NT, NU]` |
| `min_enrollment_age_weeks` | integer | Convert any "X weeks/months" to weeks. | `8` |
| `max_enrollment_age_years` | number | Maximum age at *new* enrollment. | `14` |
| `breed_restrictions` | string | Breeds excluded or surcharged at enrollment, verbatim where significant. | `none disclosed` |
| `microchip_required` | boolean or `unknown` | Required as a condition of coverage. | `false` |
| `vet_exam_required` | string | E.g. `none`, `recent (within 12 months)`, `at enrollment`. | `recent (within 12 months)` |
| `lifetime_renewability` | string | `guaranteed`, `subject to underwriting`, or `unknown`. | `guaranteed` |
| `language_of_wording` | list | Language codes available. | `[en, fr]` |
| `billing_currency` | string | `CAD` or `USD` (or other). | `CAD` |

### Section C — Core coverage

| Field | Type | Normalization | Example |
|---|---|---|---|
| `coverage_accident` | enum | `included` / `excluded` / `optional` / `unknown` | `included` |
| `coverage_illness` | enum | as above | `included` |
| `coverage_hereditary_congenital` | enum | as above; capture wording on diagnosis-before-coverage. | `included` |
| `coverage_dental_accident` | enum | Dental due to accident. | `included` |
| `coverage_dental_illness` | enum | Periodontal disease, extractions, etc. | `optional` |
| `coverage_behavioral` | enum | Behavioral therapy / consultations. | `optional` |
| `coverage_alternative` | enum | Acupuncture, chiropractic, hydrotherapy, physiotherapy. | `included` |
| `coverage_prescription_drugs` | enum | Maintenance and one-off prescriptions. | `included` |
| `coverage_exam_fees` | enum | Vet exam fees during covered illness/accident visits. | `optional` |
| `coverage_prescription_food` | enum | Therapeutic diets. | `excluded` |
| `coverage_wellness_preventive` | enum | Vaccines, annual exam, dental cleaning. Usually a separate add-on. | `optional add-on` |

### Section D — Cost structure

| Field | Type | Normalization | Example |
|---|---|---|---|
| `monthly_premium_range_cad` | object | `{min, max, assumptions}`. Assumptions string MUST capture dog age, breed class, postal code, deductible, and reimbursement % used to derive the range. | `{min: 35, max: 110, assumptions: "1yr mixed breed, M5V, $250 deductible, 80% reimbursement"}` |
| `deductible_model` | enum | `annual` / `per-condition` / `per-incident` / `none` | `annual` |
| `deductible_options_cad` | list | Available deductible amounts. | `[100, 250, 500, 750, 1000]` |
| `reimbursement_options_pct` | list | Available reimbursement percentages. | `[70, 80, 90]` |
| `annual_limit_cad` | string | Numeric, `unlimited`, or list of tier options. | `[5000, 10000, 20000, unlimited]` |
| `lifetime_limit_cad` | string | Numeric, `unlimited`, or `none`. | `unlimited` |
| `per_condition_limit_cad` | string | Where applicable (often Trupanion-style). | `none` |
| `coinsurance_after_deductible` | string | If coinsurance differs from reimbursement %. | `n/a` |
| `premium_increases_at_renewal` | string | Disclosed renewal pricing behaviour. | `age-based + claims-experience` |

### Section E — Exclusions & waiting periods

| Field | Type | Normalization | Example |
|---|---|---|---|
| `pre_existing_definition` | string | Verbatim or close-paraphrase from wording. Identify look-back window. | `"any condition with signs/symptoms before policy effective date or during waiting period"` |
| `pre_existing_curable_clause` | string | Whether resolved conditions can become eligible after a defined symptom-free window. | `"eligible after 18 months symptom-free, except cruciate"` |
| `bilateral_clause` | string | How conditions on the contralateral limb/eye are treated. | `"contralateral cruciate considered related"` |
| `waiting_period_accident_days` | integer | Days from policy start. | `2` |
| `waiting_period_illness_days` | integer | Days from policy start. | `14` |
| `waiting_period_orthopedic_days` | integer | Cruciate, hip, elbow, etc. | `180` |
| `waiting_period_other` | object | Any additional waits (cancer, IVDD, behavioral). | `{cancer: 30, behavioral: 180}` |
| `notable_exclusions` | list | Verbatim wording for material exclusions. | `["pregnancy/breeding", "cosmetic procedures", "experimental treatment"]` |

### Section F — Claims & service

| Field | Type | Normalization | Example |
|---|---|---|---|
| `claim_submission_channels` | list | `mobile-app` / `web-portal` / `email` / `mail` / `direct-vet-pay` | `[mobile-app, web-portal, direct-vet-pay]` |
| `direct_vet_pay_available` | boolean | Provider pays vet directly at point of care. | `true` |
| `claim_payout_time_disclosed` | string | Verbatim disclosure or marketing claim. | `"average 6 days"` |
| `support_channels` | list | `phone` / `email` / `chat` / `app` | `[phone, email, chat]` |
| `support_hours` | string | E.g. `24/7`, `Mon-Fri 8-8 ET`. | `Mon-Sat 8-8 ET` |
| `cancellation_policy` | string | Cancellation window and refund treatment. | `"30-day free look; pro-rata thereafter"` |

### Section G — External signal (anecdotal)

Use ONLY for qualitative signal in the per-provider notes section. Never for numeric figures.

| Field | Type | Notes |
|---|---|---|
| `review_signal_summary` | string | 1–2 sentence neutral summary of consistent themes across reviews. Tag every cited source as anecdotal. |
| `bbb_canada_status` | string | BBB Canada accreditation/rating if available. |
| `regulatory_complaints_signal` | string | Any disclosures from provincial regulators (rare). |

## Normalization rules

- **Currencies.** Express all monetary fields in CAD unless the provider bills in another currency, in which case capture native currency in the field and add a `_cad_equivalent_at_<UTC>` companion field if the user requested CAD-only output.
- **Date/time.** All retrieval timestamps are ISO 8601 UTC.
- **Booleans.** `true` / `false` / `unknown` only.
- **Enums.** Use exactly the enum values defined above. If the provider's wording is more nuanced, set the enum to the closest match and add a `*_notes` companion field.
- **Lists.** Lower-case kebab-case for canonical channel names; ISO codes for provinces.
- **`unknown` is a first-class value.** It MUST come with a `*_unknown_reason` note (e.g. `"quote tool only — public ranges not disclosed"`).

## Field completeness threshold

A provider row is considered "complete enough to publish" when:

- All Section A and Section B fields are populated (or `unknown` with reason).
- All three waiting periods (accident, illness, orthopedic) are populated.
- `pre_existing_definition` and `bilateral_clause` are populated.
- `deductible_model`, `deductible_options_cad`, `reimbursement_options_pct`, and `annual_limit_cad` are populated.

Below this threshold, mark the provider row `INCOMPLETE` in the report and explain the gap.

## Column mapping — comparison table ↔ field schema

The master table in [`../assets/comparison-template.md`](../assets/comparison-template.md) numbers each column 1–33. The mapping below shows which schema field (above) backs each comparison-table column. When extending or pruning the comparison template, update this mapping in lock-step so the agent always knows where each cell's value comes from. The numbering parallels the source Google Doc archived at [`source-pet-insurance-comparison.txt`](source-pet-insurance-comparison.txt) but is reordered and Canadianised.

| Col `#` | Comparison-table header | Backing field(s) | Section |
|---|---|---|---|
| — | Insurer | `provider_name` | A |
| 1 | Underwriter | `underwriter` | A |
| 2 | Provinces available | `provinces_available` | B |
| 3 | Provincial gaps | `provinces_excluded` | B |
| 4 | Billing currency | `billing_currency` | B |
| 5 | Wording lang | `language_of_wording` | B |
| 6 | Lifetime renewability | `lifetime_renewability` | B |
| 7 | Max enrollment age | `max_enrollment_age_years` | B |
| 8 | Accident | `coverage_accident` | C |
| 9 | Illness | `coverage_illness` | C |
| 10 | Hereditary & congenital | `coverage_hereditary_congenital` | C |
| 11 | Dental — illness | `coverage_dental_illness` (with `coverage_dental_accident` assumed included; surface as a verbatim caveat in-cell if differs) | C |
| 12 | Behavioural | `coverage_behavioral` | C |
| 13 | Alternative / holistic | `coverage_alternative` | C |
| 14 | Exam fees | `coverage_exam_fees` | C |
| 15 | Prescription meds | `coverage_prescription_drugs` | C |
| 16 | Wellness add-on | `coverage_wellness_preventive` | C |
| 17 | Direct vet pay | `direct_vet_pay_available` | F |
| 18 | Bilateral clause | `bilateral_clause` | E |
| 19 | Pre-existing handling | `pre_existing_definition` + `pre_existing_curable_clause` | E |
| 20 | Wait — accident (days) | `waiting_period_accident_days` | E |
| 21 | Wait — illness (days) | `waiting_period_illness_days` | E |
| 22 | Wait — orthopedic (days) | `waiting_period_orthopedic_days` | E |
| 23 | Deductible model | `deductible_model` | D |
| 24 | Deductible options (CAD) | `deductible_options_cad` | D |
| 25 | Reimbursement options (%) | `reimbursement_options_pct` | D |
| 26 | Annual limit (CAD) | `annual_limit_cad` | D |
| 27 | Min monthly CAD — desk | `monthly_premium_range_cad.min` | D |
| 28 | Max monthly CAD — desk | `monthly_premium_range_cad.max` | D |
| 29 | **Live monthly CAD** | Phase 3: from `04-quotes/<provider-slug>.md` (final monthly total CAD) — never desk-research | D (Phase 3) |
| 30 | Quote ref / expiry | Phase 3: from `04-quotes/<provider-slug>.md` (quote reference + expiry date) | D (Phase 3) |
| 31 | Discounts | Phase 3 quote-file discount lines (Phase 2 may pre-populate from public marketing) | D |
| 32 | Notable exclusions | `notable_exclusions` | E |
| 33 | Source URL + retrieved (UTC) | `provider_url` / `policy_wording_urls` / `quote_tool_url` plus retrieval timestamps from the fetch index | A |

Cells that have no backing schema field (e.g., a verbatim parenthetical added for nuance) MUST still cite a source URL in column `33`.
