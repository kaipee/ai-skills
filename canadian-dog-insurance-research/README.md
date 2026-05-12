# canadian-dog-insurance-research

An [Agent Skill](https://agentskills.io) that researches Canadian dog insurance providers and produces a structured, citation-backed comparison report.

## Overview

`canadian-dog-insurance-research` helps an AI agent (or a human collaborator) gather, normalize, and compare Canadian dog insurance policies across multiple providers. It auto-discovers current providers (rather than relying on a hardcoded list), fetches live data from each provider's own materials and sample policy wordings, cross-references Canadian regulator and industry sources, and renders findings into a consistent, comparable schema.

Defining principles:

- **Live fetch, never fabricate.** Every numeric figure (premiums, deductibles, limits) cites a source URL with a UTC retrieval timestamp.
- **As-of timestamps mandatory.** Output always carries explicit staleness disclaimers; binding numbers require contacting the provider for a quote.
- **Auto-discover, don't hardcode.** The Canadian pet insurance market evolves; the skill discovers active providers each run.
- **Cite everything, tag anecdotes.** Anecdotal sources (Reddit, BBB, review aggregators) are clearly labelled and never used for numeric figures.

This skill was authored with [`skill-builder`](../skill-builder/) and conforms to the [Agent Skills standard](https://agentskills.io/specification).

## When to use this skill

Invoke `canadian-dog-insurance-research` whenever a user wants to:

- Compare Canadian dog or pet insurance providers.
- Evaluate coverage, premiums, deductibles, exclusions, waiting periods, reimbursement rates, or annual/lifetime limits.
- Investigate a specific Canadian insurer (Trupanion, Petsecure, Pets Plus Us, Fetch, OVMA, Furkin, Sonnet, Desjardins, CAA, etc.).
- Understand province-specific availability or pricing context (Ontario, BC, Alberta, Quebec, etc.).
- Summarize or compare a sample policy wording PDF.
- Choose an insurer for a specific dog (age, breed, pre-existing conditions, postal code).

See [`SKILL.md`](SKILL.md) for the full triggering language and the canonical workflow.

## Directory structure

```
canadian-dog-insurance-research/
├── SKILL.md                              # Skill entry point (frontmatter + 3-phase workflow)
├── README.md                             # This file
├── references/                           # On-demand reference material (progressive disclosure)
│   ├── data-fields.md                    # Canonical extraction schema (fields, types, normalization, source priority)
│   └── canadian-context.md               # Regulatory, tax, language, currency, and veterinary-cost context
├── assets/                               # Output templates
│   ├── comparison-template.md            # Multi-provider side-by-side comparison (incl. mandatory Live Monthly Premium column post-Phase-3)
│   ├── provider-brief-template.md        # Single-provider deep-dive (two-state premium section)
│   └── quote-capture-template.md         # Phase 3 per-provider real-quote capture template
├── scripts/
│   └── fetch-provider-page.sh            # POSIX shell helper: fetches HTML/PDFs into a timestamped cache with a CSV traceability index
└── reports/                              # Per-engagement output (one folder per run; immutable once finalized)
    └── <YYYY-MM-DD>-<short-slug>/
        ├── README.md                     # Engagement index: user profile, file list, phase status
        ├── 01-provider-briefs.md         # One section per researched provider
        ├── 02-comparison-and-recommendation.md  # Side-by-side comparison + trade-off framing
        ├── 03-final-recommendation.md    # User-facing exec summary, shortlist, confirm-at-quote checklist
        └── 04-quotes/                    # Phase 3: one file per provider quoted
            └── <provider-slug>.md
```

A worked example engagement lives at [`reports/2026-05-08-toronto-cockapoo-schnauzer/`](reports/2026-05-08-toronto-cockapoo-schnauzer/).

## How to use

### As an agent

An Agent Skills-compatible client discovers the skill by reading [`SKILL.md`](SKILL.md). The frontmatter (`name`, `description`) is used to decide when to load it; the body provides a **three-phase workflow**, all output written to `reports/<YYYY-MM-DD>-<short-slug>/`:

**Phase 1 — Scope & desk research**

Research can be captured sing Playwright where available.

1. Capture user scope (provinces, dog profile, owner priorities, output mode). FSA-only postal code; never full PII.
2. Create the engagement folder under `reports/` and seed `README.md`.
3. Auto-discover current Canadian providers via web search; validate Canadian eligibility.
4. Fetch primary sources for each provider: coverage page, sample policy wording PDF, FAQ/claims page, quote tool.
5. Cross-reference Canadian regulators (OSFI, AMF, FSRA, BCFSA, AIRB, FCAA, etc.), industry bodies (IBC, CVMA, OVMA), and clearly-tagged anecdotal review sources.
6. Extract fields per [`references/data-fields.md`](references/data-fields.md); apply context from [`references/canadian-context.md`](references/canadian-context.md).

**Phase 2 — Render desk-research artifacts**

7. Write `01-provider-briefs.md` (from [`assets/provider-brief-template.md`](assets/provider-brief-template.md)), `02-comparison-and-recommendation.md` (from [`assets/comparison-template.md`](assets/comparison-template.md)), and `03-final-recommendation.md` with a 2–3 provider shortlist and the quote-tool URLs the user will use in Phase 3. Premium cells are `quote required — Phase 3` until then.

**Phase 3 — Live quote capture (user-supplied)**

8. Pause and prompt the user (verbatim template in [`SKILL.md`](SKILL.md)) to run each shortlisted provider's quote tool themselves and paste back the figures. The agent never asks for full PII.
9. For each quote, create `04-quotes/<provider-slug>.md` from [`assets/quote-capture-template.md`](assets/quote-capture-template.md). Validate that quote reference, expiry, and FSA-only postal code are present.
10. Re-generate `02-` and `03-` to reference the real CAD figures and reorder the shortlist by actual price-vs-coverage trade-offs. Update `01-` premium sections to link to the corresponding quote files.
11. Validate against the output checklist in [`SKILL.md`](SKILL.md). Mark the engagement folder immutable; re-runs create a new dated folder.

### As a human

You can run the bundled helper script directly from the repository root:

```sh
# Fetch a provider page (HTML) into a timestamped cache directory
sh canadian-dog-insurance-research/scripts/fetch-provider-page.sh https://example-insurer.ca/coverage

# Also pull any same-host PDF wordings linked from the page
sh canadian-dog-insurance-research/scripts/fetch-provider-page.sh https://example-insurer.ca/coverage --with-pdfs

# Direct cache to a specific directory
sh canadian-dog-insurance-research/scripts/fetch-provider-page.sh https://example-insurer.ca/coverage /tmp/research --with-pdfs
```

Each fetch appends a row to `<output-dir>/index.csv` recording UTC timestamp, URL, HTTP status, SHA256, byte count, saved path, and kind (`html` or `pdf`) for full traceability.

## References

The [`references/`](references/) directory contains focused on-demand documentation. Files are loaded by the agent only when relevant, keeping the activation context lean.

| Path | Purpose |
|---|---|
| [`references/data-fields.md`](references/data-fields.md) | Canonical extraction schema. Defines every field with type, normalization rule, source-priority order, and example value. Codifies the "complete enough to publish" threshold for each provider row. |
| [`references/canadian-context.md`](references/canadian-context.md) | Canadian regulatory landscape (OSFI, AMF, FSRA, BCFSA, etc.), insurance premium tax treatment by province, Quebec specifics (AMF licensing, French-language wordings), USD/CAD billing nuances, structural model differences (annual vs. per-condition deductibles), and a glossary. |

## Assets

The [`assets/`](assets/) directory holds the markdown templates the skill fills in to render its final output.

| Path | Purpose |
|---|---|
| [`assets/comparison-template.md`](assets/comparison-template.md) | Side-by-side multi-provider comparison report. Section D includes a **Live Monthly Premium (CAD)** row that is mandatory once Phase 3 has run. |
| [`assets/provider-brief-template.md`](assets/provider-brief-template.md) | Single-provider deep-dive brief. The "Sample premium" section has two states: a desk-research placeholder (Phase 2) and a post-Phase-3 captured-quote state linked to `04-quotes/<provider-slug>.md`. |
| [`assets/quote-capture-template.md`](assets/quote-capture-template.md) | Phase 3 per-provider quote-capture template — one file per provider in `04-quotes/`. Captures user-supplied real CAD figures, selected coverage parameters, discounts, taxes, quote reference, expiry, and FSA-only postal code. |

## Scripts

### [`scripts/fetch-provider-page.sh`](scripts/fetch-provider-page.sh)

POSIX shell helper that fetches a provider page (and optionally same-host PDFs) into a timestamped cache directory, capturing a traceability record for each artifact.

- **Requires:** POSIX `sh`, `curl`, and either `shasum` or `sha256sum`.
- **Default cache:** `${TMPDIR:-/tmp}/canadian-dog-insurance-research/<UTC-date>/`.
- **Behaviour:**
  - Uses `curl --fail --location --max-time 30` with a realistic User-Agent.
  - Saves the response body to `<host>__<slug>.{html|pdf}`.
  - Computes SHA256 and byte count for each artifact.
  - Appends a CSV row to `<cache>/index.csv` with columns: `utc, url, http_status, sha256, bytes, saved_path, kind`.
  - With `--with-pdfs`, naively grep-extracts `*.pdf` links from the HTML body and downloads any whose host matches the original URL's host. Cross-host PDFs are skipped.
- **Limitations:**
  - Does **not** execute JavaScript. SPA-rendered quote tools will return a near-empty shell — fall back to a rendering-capable WebFetch in that case (the SKILL workflow makes this fallback explicit).
  - PDF discovery is naive and only matches links present in the static HTML body.
  - Does not respect `robots.txt`. Intended for low-volume manual research only.
- **Exit codes:** `0` success, `1` bad usage, `2` curl hard failure on primary URL, `3` missing dependency.
- **Run:**

  ```sh
  sh canadian-dog-insurance-research/scripts/fetch-provider-page.sh <url> [output-dir] [--with-pdfs]
  ```

## Output guarantees

Every engagement produced by this skill includes:

- A dedicated `reports/<YYYY-MM-DD>-<short-slug>/` folder containing `README.md`, `01-provider-briefs.md`, `02-comparison-and-recommendation.md`, `03-final-recommendation.md`, and (post-Phase-3) `04-quotes/<provider-slug>.md` for each provider quoted.
- A top-of-report **Data captured at: `<UTC>`** header in each generated file.
- Every numeric figure carries a source URL and a retrieval UTC timestamp **or** (post-Phase-3) a link to the corresponding `04-quotes/` file.
- Anecdotal sources are tagged `anecdotal` and never used for numeric figures.
- Missing fields are explicitly recorded as `unknown` with a one-line reason — never silently omitted.
- A footer disclaimer stating that figures are non-binding (and, post-Phase-3, that user-reported live quotes remain subject to the provider's bind-time underwriting).
- A complete citations table listing every source URL and its retrieval timestamp.
- **Privacy:** no full postal codes, DOB, email, phone, or payment details are stored anywhere in the engagement folder; only FSA prefixes (e.g. `M5V`) and the figures the user reports back from the quote screen.
- The engagement folder is **immutable once finalized** — re-running the skill creates a new dated folder.

## Validation & contributing

When modifying this skill, follow the same checklist that applies to any Agent Skill (see the **Output validation checklist** in [`SKILL.md`](SKILL.md) and the broader Agent Skills standard):

1. Use [`skill-builder`](../skill-builder/) — refresh the upstream standard, run `validate-self.sh`, and reconcile against any spec drift before authoring changes here.
2. Keep large content under [`references/`](references/) or [`assets/`](assets/) — reference it from [`SKILL.md`](SKILL.md) rather than inlining it (progressive disclosure).
3. Ensure bundled scripts remain executable (`chmod +x`), documented, POSIX-portable, and graceful on error.
4. Preserve the schema in [`references/data-fields.md`](references/data-fields.md): if you add fields, also add their normalization rules and source-priority ordering, and update the templates in [`assets/`](assets/).
5. Never embed pricing or coverage numbers from training data into [`SKILL.md`](SKILL.md), references, or templates. The skill must always derive numbers from a live fetch at run time.

## Disclaimer

This skill produces informational reports drawn from publicly available materials at the captured timestamps. Output is **not** a personalized quote, **not** binding, and **not** financial, legal, or veterinary advice. Real premiums depend on the dog's age, breed, postal code, deductible/reimbursement selection, and the provider's underwriting at application time. Confirm all material terms by requesting a current quote and reading the policy wording in full before purchasing.

License: MIT (see repository [`LICENSE`](../LICENSE)).
