---
name: agentsmd-generator
description: Generates or updates AGENTS.md files that conform to the https://agents.md/ specification. Use this skill when the user wants to create a new AGENTS.md file, update or improve an existing one, scaffold agent instructions for a project, or add coding conventions, build commands, test instructions, or code style guidance for AI coding agents. Triggers on phrases like "create AGENTS.md", "write AGENTS.md", "update my AGENTS.md", "add agent instructions", "scaffold agent context", or "help agents work on my project", even if the user doesn't explicitly mention the agents.md format.
license: MIT
metadata:
  author: Keith Patton
  author_id: github.com/kaipee
  version: "1.1"
  spec: https://agents.md/
  spec_repo: https://github.com/agentsmd/agents.md
---

## Bundled references (load on demand)

- [`references/agents-md/home.md`](references/agents-md/home.md) — upstream spec summary: format overview, key facts, FAQ, supported tools. Fetched from https://agents.md/.
- [`references/agents-md/github-readme.md`](references/agents-md/github-readme.md) — upstream GitHub README with a canonical example AGENTS.md. Fetched from https://github.com/agentsmd/agents.md.
- [`references/FETCHED.txt`](references/FETCHED.txt) — fetch timestamp and sources.

# AGENTS.md Generator

Generates or updates `AGENTS.md` files conforming to the [agents.md specification](https://agents.md/).

## What is AGENTS.md?

A Markdown file placed at the root of a repository (or inside subdirectories for monorepos) that gives AI coding agents the project-specific context they need to work effectively. It is the **README for agents** — complementing human-focused docs without cluttering them.

Key facts:
- No required fields — pure Markdown with any headings you choose.
- Nested files are supported: place one per package in a monorepo; the nearest file wins.
- Supported by 60k+ projects and tools including Copilot, Cursor, Devin, Codex, Gemini CLI, RooCode, Aider, and more.

## Workflow

### 1. Check for an existing AGENTS.md

Look for an `AGENTS.md` at the project root (and nested paths for monorepos). If found, read it and determine what to update rather than overwriting wholesale.

### 2. Gather project context

Use `ask_followup_question` to collect missing information. Prioritise questions — ask only what you cannot infer from the codebase. Common sources to read first: `package.json`, `pyproject.toml`, `Makefile`, `README.md`, `.github/workflows/`, existing CI configs.

**Collect (or infer) the following:**

| Topic | What to capture |
|---|---|
| Project name & purpose | One-line description |
| Language / runtime | e.g. Node 20, Python 3.12, Go 1.22 |
| Setup commands | Install deps, env setup |
| Dev server command | How to run locally |
| Build command | How to compile / bundle |
| Test command(s) | Unit, integration, lint, type-check |
| Code style | Formatter, linter, naming conventions, quote style |
| Commit / PR conventions | Format, branch naming, review rules |
| Security gotchas | Secrets handling, auth patterns to follow |
| Monorepo structure | Package layout, workspace tooling |
| Any other gotchas | Non-obvious pitfalls agents encounter |

Ask the user to confirm or fill gaps before writing. One focused `ask_followup_question` call is better than several.

### 3. Write the AGENTS.md

Produce clean, focused Markdown. Rules:
- Use `##` headings for sections; `###` for sub-sections.
- Be specific and actionable — commands agents can run verbatim, not vague advice.
- Omit sections for which there is no project-specific information to add.
- Keep the file concise; agents load it on every task.

**Recommended section order** (include only what applies):

```markdown
# AGENTS.md

## Project overview
[One or two sentences: what this repo does.]

## Setup
[Install / bootstrap commands]

## Dev environment
[Start dev server, env vars, tips for navigating the codebase]

## Build
[Build command(s)]

## Testing
[How to run tests, lint, type-check. Any filtering patterns.]

## Code style
[Formatter, linter rules, naming, quote style, any non-obvious conventions]

## Commit & PR conventions
[Title format, branch naming, required checks before merge]

## Security
[Secrets handling, auth patterns, anything that must never be committed]

## Gotchas
[Non-obvious pitfalls, soft-delete patterns, environment quirks, etc.]

## Monorepo notes
[Package layout, workspace tool, how to target a single package]
```

### 4. Place the file

- Root of the repo: `AGENTS.md`
- Per-package in a monorepo: `packages/<name>/AGENTS.md`
- Write the file and confirm its path to the user.

### 5. Verify

After writing, read the file back and confirm:
- Commands are syntactically correct (no broken shell lines).
- No secrets or credentials are present.
- Sections are accurate to what the user provided.

## Gotchas

- AGENTS.md is plain Markdown — no YAML frontmatter, no special syntax.
- Do not copy README content verbatim; focus on what agents need that humans don't.
- For monorepos with many packages, ask which packages need their own file rather than generating all at once.
- If the user says "update", preserve existing sections and only modify what they specify.
