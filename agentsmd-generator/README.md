# agentsmd-generator

An Agent Skill that generates or updates [`AGENTS.md`](https://agents.md/) files conforming to the official agents.md specification.

## What it does

Guides an AI agent through collecting project context and producing a well-structured `AGENTS.md` file — the "README for agents" that gives coding agents the build commands, test steps, code style rules, and project-specific gotchas they need to work effectively.

## When to use it

Invoke this skill when you want to:

- Create a new `AGENTS.md` from scratch for any project.
- Update or extend an existing `AGENTS.md` with new sections.
- Scaffold agent instructions for a monorepo package.
- Ensure your `AGENTS.md` covers the right topics without cluttering your `README.md`.

## Skill structure

```
generators/agentsmd-generator/
├── SKILL.md    # Skill entry point
└── README.md   # This file
```

## How it works

1. **Checks** for an existing `AGENTS.md` and reads it if present.
2. **Infers** as much as possible from the codebase (`package.json`, `pyproject.toml`, CI configs, `README.md`).
3. **Asks** focused follow-up questions for anything it cannot infer.
4. **Writes** a clean, concise `AGENTS.md` using the recommended section order.
5. **Verifies** the output for correctness before confirming completion.

## Output format

The generated file is plain Markdown (no YAML frontmatter). Sections are included only when there is project-specific content to add. Typical sections:

- Project overview
- Setup / install commands
- Dev environment tips
- Build commands
- Testing instructions
- Code style conventions
- Commit & PR guidelines
- Security notes
- Gotchas
- Monorepo notes (when applicable)

## References

- [agents.md specification](https://agents.md/)
- [agents.md GitHub repository](https://github.com/agentsmd/agents.md)
