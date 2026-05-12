# skill-builder

A meta-skill that authors and updates Agent Skills strictly conforming to the [Agent Skills standard](https://agentskills.io/specification).

## Overview

`skill-builder` is an [Agent Skill](https://agentskills.io) whose purpose is to help an AI agent (or a human collaborator) create new skills, refactor existing ones, and validate them against the latest upstream specification. It is itself an exemplar of the standard: a single [`SKILL.md`](SKILL.md:1) entry point with valid frontmatter, supporting material under [`references/`](references/) and [`scripts/`](scripts/), and progressive disclosure of bundled content.

A defining feature of this skill is that it **refetches the upstream standard and self-validates on every invocation** before doing any work, so it never authors against stale rules.

It also enforces a **Conciseness Directive** (see [`SKILL.md`](SKILL.md:18)) on itself and on every skill it creates or modifies: keep skills slim, human-readable, and token-efficient while preserving unambiguous instructions for AI models.

## When to use this skill

Invoke `skill-builder` whenever you want to:

- Scaffold a brand-new skill from an idea or workflow.
- Update, refactor, or fix an existing skill.
- Validate a skill against the current Agent Skills standard.
- Optimize a skill's `description` field so it triggers reliably.
- Organize bundled scripts, references, or assets following progressive-disclosure best practices.

See [`SKILL.md`](SKILL.md:40) for the canonical "when to use" list and the full authoring workflow.

## Directory structure

```
skill-builder/
├── SKILL.md                                  # Skill entry point (frontmatter + instructions)
├── README.md                                 # This file
├── references/                               # On-demand reference material (progressive disclosure)
│   ├── agent-skills-standard.md              # Combined canonical spec & guides (llms-full.txt)
│   ├── agent-skills-index.md                 # Upstream index (llms.txt)
│   ├── FETCHED.txt                           # Provenance: UTC + epoch + script version
│   ├── agentskills-io/                       # Individual pages mirrored from agentskills.io
│   │   ├── specification.md
│   │   ├── home.md
│   │   ├── clients.md
│   │   ├── client-implementation_adding-skills-support.md
│   │   ├── skill-creation_quickstart.md
│   │   ├── skill-creation_best-practices.md
│   │   ├── skill-creation_optimizing-descriptions.md
│   │   ├── skill-creation_evaluating-skills.md
│   │   └── skill-creation_using-scripts.md
│   └── anthropics-skills/                    # Reference artifacts from anthropics/skills
│       ├── README.md
│       ├── spec.md                           # Upstream spec stub
│       ├── template-SKILL.md                 # Official minimal SKILL.md template
│       ├── skill-creator-SKILL.md            # Anthropic's skill-creator meta-skill
│       └── skill-creator-schemas.md
└── scripts/
    ├── fetch-standard.sh                     # Always-fresh re-download of the standard
    └── validate-self.sh                      # Freshness + frontmatter self-validator
```

## How to use

### As an agent

An Agent Skills-compatible client discovers the skill by reading [`SKILL.md`](SKILL.md:1). The frontmatter (`name`, `description`) is used to decide when to load it; the body provides the workflow. On every invocation the skill performs **Step 0** (see [`SKILL.md`](SKILL.md:18)):

1. Run [`scripts/fetch-standard.sh`](scripts/fetch-standard.sh:1) to refresh [`references/`](references/).
2. Verify [`references/FETCHED.txt`](references/FETCHED.txt:1) was just written.
3. Run [`scripts/validate-self.sh`](scripts/validate-self.sh:1) and ensure it exits 0.
4. Re-read the freshly-fetched standard.
5. Reconcile [`SKILL.md`](SKILL.md:1) against any drift before proceeding.

Only after Step 0 succeeds does the skill move on to the user's actual authoring task.

### As a human

You can run the bundled scripts directly from the repository root:

```sh
# Refresh bundled references against the live upstream spec
sh skill-builder/scripts/fetch-standard.sh

# Validate skill-builder/SKILL.md against the freshly-fetched standard
sh skill-builder/scripts/validate-self.sh
```

New skills authored with `skill-builder` should be created as **siblings** of `skill-builder/` (e.g. `<repo-root>/my-new-skill/`), never nested inside it.

## References

The [`references/`](references/) directory bundles upstream documentation so the skill can operate offline after a successful fetch. Files are loaded on demand to keep the agent's context lean.

| Path | Source | Purpose |
|---|---|---|
| [`references/agent-skills-standard.md`](references/agent-skills-standard.md:1) | `https://agentskills.io/llms-full.txt` | Combined canonical spec & guides; primary offline reference. |
| [`references/agent-skills-index.md`](references/agent-skills-index.md:1) | `https://agentskills.io/llms.txt` | Upstream index of available pages. |
| [`references/agentskills-io/`](references/agentskills-io/specification.md:1) | `https://agentskills.io/<page>.md` | Individual upstream pages (specification, quickstart, best practices, optimizing descriptions, evaluating skills, using scripts, clients, client implementation). |
| [`references/anthropics-skills/`](references/anthropics-skills/template-SKILL.md:1) | `https://github.com/anthropics/skills` | Reference implementation artifacts: `spec.md`, official `template-SKILL.md`, `skill-creator-SKILL.md`, schemas, and upstream README. |
| [`references/FETCHED.txt`](references/FETCHED.txt:1) | generated | Provenance marker: UTC timestamp, epoch seconds, and fetch-script version. |

## Scripts

### [`scripts/fetch-standard.sh`](scripts/fetch-standard.sh:1)

Refreshes everything under [`references/`](references/). It **always re-downloads** — there is no skip-if-cached path — so the skill never reconciles against stale data.

- **Sources:** `https://agentskills.io` (canonical spec & guides) and `https://raw.githubusercontent.com/anthropics/skills/main` (reference implementation).
- **Requires:** POSIX `sh` and `curl`.
- **Behaviour:** Downloads the combined `llms-full.txt`, the per-page specification, the official template `SKILL.md`, and supporting docs. Critical files cause a non-zero exit on failure; non-critical files emit a warning.
- **Writes:** [`references/agent-skills-standard.md`](references/agent-skills-standard.md:1), [`references/agentskills-io/*.md`](references/agentskills-io/specification.md:1), [`references/anthropics-skills/*.md`](references/anthropics-skills/template-SKILL.md:1), and [`references/FETCHED.txt`](references/FETCHED.txt:1) (UTC ISO timestamp, epoch seconds, script version).
- **Run:**

  ```sh
  sh skill-builder/scripts/fetch-standard.sh
  ```

### [`scripts/validate-self.sh`](scripts/validate-self.sh:1)

Self-reconciliation validator that confirms the skill is operating against fresh data and that [`SKILL.md`](SKILL.md:1) still satisfies the standard's hard rules.

- **Freshness check:** Reads `Epoch:` from [`references/FETCHED.txt`](references/FETCHED.txt:1) and fails if the fetch is older than **600 seconds** (10 minutes).
- **Frontmatter checks:**
  - `name` matches `^[a-z0-9]+(-[a-z0-9]+)*$`, is 1–64 chars, and equals the directory name (`skill-builder`).
  - `description` is a non-empty string of 1–1024 chars.
  - `compatibility` (if present) is a string ≤500 chars.
  - `metadata` (if present) is a flat string→string map.
  - `license` (if present) is a string.
- **Implementation:** Prefers `python3` + `PyYAML` for full YAML parsing; falls back to a minimal `grep` check if either is unavailable.
- **Exit codes:** `0` on success, `1` on any failure (caller MUST NOT proceed with the skill).
- **Run:**

  ```sh
  sh skill-builder/scripts/validate-self.sh
  ```

## Validation & contributing

When modifying `skill-builder` itself, follow the same checklist that applies to any new skill (see the **Validation checklist** in [`SKILL.md`](SKILL.md:141)):

1. Run [`scripts/fetch-standard.sh`](scripts/fetch-standard.sh:1) so [`references/FETCHED.txt`](references/FETCHED.txt:1) is fresh.
2. Re-read [`references/agent-skills-standard.md`](references/agent-skills-standard.md:1) and reconcile [`SKILL.md`](SKILL.md:1) against any drift.
3. Run [`scripts/validate-self.sh`](scripts/validate-self.sh:1) and confirm it exits 0.
4. Keep large content under [`references/`](references/), [`scripts/`](scripts/), or `assets/` — reference it from [`SKILL.md`](SKILL.md:1) rather than inlining it.
5. Ensure bundled scripts remain executable, documented, and POSIX-portable.

License: MIT (see repository [`LICENSE`](../LICENSE:1)).
