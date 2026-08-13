---
name: obsidian:decision
model: haiku
description: Log a decision to Obsidian with context and alternatives. Triggers on: log decision, we decided, decision log
---

# Decision Log

Capture a decision with its context, alternatives, and rationale — so future-you knows why.

## Input

**Request:** $ARGUMENTS

The user describes a decision. Could be terse:
- "use company-level bulk API for timecard sync because per-project calls don't scale"
- "decision: keep syncProjects as-is, refactor only timecard flow"

Or a request to review past decisions:
- "what decisions did we make about Procore?"
- "show recent decisions"

## Logging a decision

Parse the user's input for: **what** was decided, **why**, and any **alternatives** mentioned.

Generate a slug from the topic.

```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs write "decisions/YYYY-MM-DD-<slug>.md" <<'EOF'
...
EOF
```

**Format:**
```markdown
---
date: YYYY-MM-DD
participants: [names if mentioned, otherwise "Derek"]
project: [inferred — e.g. "viper", "hive", "dotfiles"]
related: "[[investigations/YYYY-MM-DD-slug]]"
tags: [project-tag]
---

## Decision
[What was decided — one clear sentence]

## Why
[The rationale — what constraints or goals drove this]

## Alternatives Considered
- [Alternative 1] — [why not]
- [Alternative 2] — [why not]
[If the user didn't mention alternatives, omit this section rather than making them up]

## Research
Based on [[investigations/YYYY-MM-DD-<slug>]]
[Only include this section if the decision was derived from an investigation. Remove otherwise.]
```

**Filling in frontmatter:**
- `project`: infer from context (branch name, ticket prefix, or explicit mention)
- `related`: wikilink to the investigation that informed this decision (if any). Search for it if not obvious. Leave empty string if none.
- `tags`: lowercase tags matching the project/domain (e.g. `[viper, auth]`)

Keep it tight. A decision log entry should be scannable in 10 seconds.

### Linking to investigations

If the user mentions the decision came from research or an investigation, search for the related investigation note:

```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs search "<keywords>" --path investigations
```

If a matching investigation is found, add a `## Research` section with a wiki-link to it:
```markdown
## Research
Based on [[investigations/YYYY-MM-DD-<slug>]]
```

- Only add this section when there's a real investigation to link — don't ask or guess.
- If the user explicitly names the investigation, link it directly.
- If the topic clearly matches a recent investigation, link it and mention you did.

## Reviewing decisions

```bash
node ~/.claude/commands/obsidian/_lib/vault-cli.mjs search "<keywords>" --path decisions
```

Then read matching files and summarize.

## Gotchas

- **There is no `obsidian` CLI. Never call it.** The `obsidian` on PATH is the app binary (`/Applications/Obsidian.app/Contents/MacOS/obsidian`). It has no `create`/`read`/`append`/`search` subcommands: passing it `create path=... content=...` silently launches the app and leaves a stray `Untitled N.md` in the vault root, writing nothing. Vault access goes through `_lib/vault-cli.mjs` (or `_lib/gather.mjs` for the bundled reads).
- **Don't inflate.** If the user gives a one-liner, the log entry should be short too. Don't pad with speculation about alternatives they didn't mention.
- **Capture the why, not just the what.** "We chose X" is useless without "because Y". If the user didn't say why, ask.
