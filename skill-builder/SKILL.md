---
name: skill-builder
description: Authors and updates Agent Skills that comply with the official Agent Skills standard (agentskills.io). Use when the user asks to create a new skill, scaffold a SKILL.md, update or refactor an existing skill, validate a skill against the spec, optimize a skill's description for reliable triggering, or organize bundled scripts, references, and assets via progressive disclosure. Always refetches the upstream standard at the start of every invocation and reconciles itself against the latest spec before authoring.
license: MIT
compatibility: Requires curl and internet access; every invocation runs scripts/fetch-standard.sh to refresh references/ and scripts/validate-self.sh to self-reconcile against the latest standard. python3 + PyYAML recommended for full frontmatter validation (grep fallback otherwise).
metadata:
  author: Keith Patton
  author_id: github.com/kaipee
  version: "3.0"
  upstream_spec: https://agentskills.io/specification
  upstream_repo: https://github.com/anthropics/skills
---

# Skill Builder

Create or update Agent Skills that strictly conform to the [Agent Skills standard](https://agentskills.io/specification). This skill is itself an exemplar: a single `SKILL.md` with valid frontmatter, supporting material under `references/` and `scripts/`, and progressive disclosure.

## Conciseness Directive (apply to this skill and every skill it touches)

- **Be concise.**
- Ensure new and modified Skills are **not overly verbose**.
- Keep the amount of text within ease of use for humans to **read and grok**.
- Understand that **slimline output helps control token usage** and remain human readable, while still providing the **necessary unambiguous directions** for AI models.

Operational, not aspirational: applies to every edit of `skill-builder/SKILL.md`, every new `SKILL.md` you scaffold, every README, and every bundled reference. Prefer cutting words to adding them; never sacrifice an unambiguous instruction for brevity.

**Anti-patterns to avoid:** verbose preambles ("In this section we will…", "It is important to note that…"); redundant restatements of rules already in the standard or earlier in the file; over-explained examples; decorative headings or filler tables that carry no rules; inlining content that belongs under `references/`.

## Step 0 — Always refresh and reconcile (mandatory)

**Run these before anything else, on every invocation. Do not skip. Do not assume cached `references/` are current. This applies whether you are authoring a new skill or modifying skill-builder itself.**

1. **Refetch the standard.** Run:
   ```sh
   sh skill-builder/scripts/fetch-standard.sh
   ```
   This always re-downloads (no skip-if-cached). On any critical failure it exits non-zero — if so, **stop**; do not proceed with stale data.

2. **Confirm freshness.** Read [`skill-builder/references/FETCHED.txt`](references/FETCHED.txt:1) and verify the `Epoch:` line is within the last few minutes (this invocation).

3. **Run the self-validator.** Run:
   ```sh
   sh skill-builder/scripts/validate-self.sh
   ```
   It enforces the freshness window (≤600s) and re-validates this `SKILL.md`'s frontmatter against the standard's hard rules. It must exit 0. If it fails, fix the reported drift before continuing.

4. **Reload the standard into context.** Read the freshly-refreshed [`references/agent-skills-standard.md`](references/agent-skills-standard.md:1) and [`references/agentskills-io/specification.md`](references/agentskills-io/specification.md:1) to load the current rules.

5. **Self-reconcile.** Compare this `SKILL.md` against the just-fetched standard. If anything has drifted (frontmatter fields, length limits, naming rules, structural conventions, new required fields), update `skill-builder/SKILL.md` to match the latest standard **as part of this same invocation**, then re-run `validate-self.sh`. Only after it passes may you proceed to the user's task.

## When to use this skill

Use it whenever the user wants to:

- Scaffold a brand-new skill from an idea or workflow.
- Update, refactor, or fix an existing skill.
- Validate a skill against the current standard.
- Optimize a `description` field so the skill triggers reliably.
- Organize bundled scripts, references, or assets.

## Bundled resources (progressive disclosure)

Read these on demand — keep the agent's context lean.

- [`references/agent-skills-standard.md`](references/agent-skills-standard.md:1) — combined canonical spec & guides. **Always consult after Step 0.**
- [`references/agentskills-io/`](references/agentskills-io/specification.md:1) — individual upstream pages (specification, best practices, optimizing descriptions, evaluating skills, using scripts, quickstart, client implementation).
- [`references/anthropics-skills/`](references/anthropics-skills/template-SKILL.md:1) — Anthropic's reference artifacts: `template-SKILL.md`, `skill-creator-SKILL.md`, `spec.md`, `README.md`, `skill-creator-schemas.md`.
- [`references/FETCHED.txt`](references/FETCHED.txt:1) — UTC + epoch timestamp + script version for the current refresh.
- [`scripts/fetch-standard.sh`](scripts/fetch-standard.sh:1) — always-fresh re-download of the standard.
- [`scripts/validate-self.sh`](scripts/validate-self.sh:1) — freshness + frontmatter self-validator.

## Authoring workflow

After Step 0 succeeds, follow these steps. Treat the freshly-fetched standard as the source of truth; defer to `references/agent-skills-standard.md` whenever this file is silent.

### 1. Capture intent

Confirm with the user:

1. What should the skill enable the agent to do?
2. When should it trigger (user phrases, contexts, file types)?
3. What is the expected output / success criterion?
4. Are there bundled assets (scripts, templates, reference docs) needed?

### 2. Choose a name and create the directory

- The skill's directory name **must** match the `name` field in frontmatter.
- Lowercase ASCII letters, digits, and single hyphens; 1–64 chars; no leading/trailing/consecutive hyphens.
- Place new skills as **siblings** of `skill-builder/` (e.g., `pdf-processing/`). **Never** nest them inside `skill-builder/`.

```
<repo-root>/
├── skill-builder/      # this skill
└── <new-skill-name>/   # the new skill goes here
    └── SKILL.md
```

### 3. Write `SKILL.md`

Required structure:

```markdown
---
name: <directory-name>
description: <≤1024 chars; what it does AND when to use it; third person; trigger keywords>
---

# <Human-readable title>

<Body: actionable instructions, examples, edge cases.>
```

Frontmatter rules (see [`references/agentskills-io/specification.md`](references/agentskills-io/specification.md:1) for full detail):

| Field | Required | Notes |
|---|---|---|
| `name` | yes | Matches directory; ≤64 chars; `[a-z0-9-]`; no edge/consecutive hyphens. |
| `description` | yes | ≤1024 chars; covers **what** + **when**; third person; rich in trigger keywords. |
| `license` | no | License name or reference to a bundled `LICENSE`. |
| `compatibility` | no | ≤500 chars; environment requirements. Omit unless needed. |
| `metadata` | no | Flat string→string map (author, version, etc.). |
| `allowed-tools` | no | Experimental; space-separated tool patterns. |

Body should be **concise and high-signal** (see [Conciseness Directive](#conciseness-directive-apply-to-this-skill-and-every-skill-it-touches)):

- Step-by-step instructions, no preamble.
- Minimum examples needed to disambiguate.
- Pointers to `references/`, `scripts/`, `assets/` instead of inlined content.
- Cut filler ("this section explains…", restated rules, decorative headings).

### 4. Add bundled resources (only when they earn their place)

Each file must justify its tokens. Keep individual `references/` files small and focused; split rather than bloat.

- `scripts/` — executable helpers; POSIX-portable when possible. See [`references/agentskills-io/skill-creation_using-scripts.md`](references/agentskills-io/skill-creation_using-scripts.md:1).
- `references/` — focused, on-demand docs.
- `assets/` — templates, images, lookup data, schemas.

### 5. Optimize the description

A weak `description` is the top cause of a skill failing to trigger. Apply [`references/agentskills-io/skill-creation_optimizing-descriptions.md`](references/agentskills-io/skill-creation_optimizing-descriptions.md:1):

- Lead with concrete actions and artifacts the skill produces.
- Enumerate the **when** with explicit user phrases / domains / file types.
- Use precise verbs ("extracts", "generates", "validates"); avoid "helps with".
- Stay well under 1024 chars — dense, not padded.

### 6. Validate

Run the checklist below before declaring the skill done.

### 7. (Optional) Iterate with evals

For skills with verifiable outputs, follow [`references/agentskills-io/skill-creation_evaluating-skills.md`](references/agentskills-io/skill-creation_evaluating-skills.md:1).

## Validation checklist

Before finishing any skill — new or a modification to `skill-builder` itself — confirm every box:

- [ ] Ran `scripts/fetch-standard.sh` this invocation (FETCHED.txt epoch within last 10 minutes).
- [ ] Ran `scripts/validate-self.sh` and it exited 0.
- [ ] Re-read `references/agent-skills-standard.md` after refresh; reconciled any drift in `SKILL.md`.
- [ ] Directory name matches `name` in frontmatter.
- [ ] `name`: 1–64 chars, lowercase `[a-z0-9-]`, no leading/trailing/consecutive hyphens.
- [ ] `description`: ≤1024 chars, third-person, states **what + when** with trigger keywords.
- [ ] `compatibility` (if present) ≤500 chars and genuinely needed.
- [ ] `metadata` (if present) is a flat string→string map.
- [ ] YAML frontmatter parses cleanly.
- [ ] Progressive disclosure: large content lives under `references/` / `scripts/` / `assets/`, referenced not inlined.
- [ ] **Concise:** no verbose preambles, redundant restatements, over-explained examples, or decorative sectioning. Trimmed before shipping.
- [ ] Bundled scripts are executable (`chmod +x`), documented, and handle errors.
- [ ] New skills placed as siblings of `skill-builder/`, never nested inside it.
