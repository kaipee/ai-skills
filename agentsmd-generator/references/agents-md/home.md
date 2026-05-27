# AGENTS.md — Upstream Specification Reference

> Source: https://agents.md/  
> GitHub: https://github.com/agentsmd/agents.md  
> Steward: [Agentic AI Foundation](https://aaif.io) under the Linux Foundation

## Overview

AGENTS.md is a simple, open format for guiding coding agents, used by over 60k open-source projects.

Think of AGENTS.md as a **README for agents**: a dedicated, predictable place to provide the context and instructions to help AI coding agents work on your project.

## Key facts

- **No required fields** — pure Markdown with any headings you choose.
- **Nested files supported** — place one per package in a monorepo; the nearest file wins.
- **Living documentation** — treat it as an evolving project artifact.
- Supported by tools including GitHub Copilot, Cursor, Devin, OpenAI Codex, Gemini CLI, RooCode, Aider, Amp, Windsurf, Kilo Code, Augment Code, and more.

## How to use AGENTS.md

### 1. Add AGENTS.md
Create an `AGENTS.md` at the root of the repository.

### 2. Cover what matters
Popular sections:
- Project overview
- Build and test commands
- Code style guidelines
- Testing instructions
- Security considerations

### 3. Add extra instructions
Commit messages, PR guidelines, security gotchas, deployment steps — anything you'd tell a new teammate.

### 4. Large monorepo? Use nested AGENTS.md files
Place another `AGENTS.md` inside each package. Agents automatically read the nearest file in the directory tree; the closest one takes precedence.

## Example

```markdown
# Sample AGENTS.md file

## Dev environment tips
- Use `pnpm dlx turbo run where <project_name>` to jump to a package instead of scanning with `ls`.
- Run `pnpm install --filter <project_name>` to add the package to your workspace.
- Use `pnpm create vite@latest <project_name> -- --template react-ts` to spin up a new React + Vite package.

## Testing instructions
- Find the CI plan in the .github/workflows folder.
- Run `pnpm turbo run test --filter <project_name>` to run every check for that package.
- From the package root: `pnpm test`. The commit should pass all tests before merge.
- Fix any test or type errors until the whole suite is green.
- Add or update tests for the code you change, even if nobody asked.

## PR instructions
- Title format: [<project_name>] <Title>
- Always run `pnpm lint` and `pnpm test` before committing.
```

## FAQ

**Are there required fields?**  
No. AGENTS.md is standard Markdown. Use any headings you like.

**What if instructions conflict?**  
The closest AGENTS.md to the edited file wins; explicit user chat prompts override everything.

**Will the agent run testing commands automatically?**  
Yes — if you list them. The agent will attempt to execute relevant programmatic checks and fix failures before finishing the task.

**Can I update it later?**  
Absolutely. Treat AGENTS.md as living documentation.

**How do I migrate existing docs?**  
```bash
mv AGENT.md AGENTS.md && ln -s AGENTS.md AGENT.md
```

**How do I configure Aider?**  
In `.aider.conf.yml`:
```yaml
read: AGENTS.md
```

**How do I configure Gemini CLI?**  
In `.gemini/settings.json`:
```json
{ "context": { "fileName": "AGENTS.md" } }
```

## Attribution

AGENTS.md emerged from collaborative efforts across the AI software development ecosystem, including OpenAI Codex, Amp, Jules from Google, Cursor, and Factory. It is now stewarded by the [Agentic AI Foundation](https://aaif.io) under the Linux Foundation.
