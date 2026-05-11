---
name: obsidian:investigate
model: haiku
description: Create or append an investigation note in Obsidian for debugging research. Triggers on: investigate, debug notes, research trail
---

# Investigation Journal

Create or update an investigation note in Obsidian. Captures what you tried, what you found, and dead ends — so you never re-walk a research trail.

## Input

**Request:** $ARGUMENTS

The user provides context about what they're investigating. This could be:
- Starting a new investigation: "the DD update bug" or "Procore cost code mapping"
- Appending to an existing one: "update the DD investigation — found it's a null reference in ach_lines"
- Reviewing past investigations: "show my investigations" or "what did I find about X"

## Creating a new investigation

Generate a slug from the topic (e.g., "dd-update-bug", "procore-cost-code-mapping").

```bash
source ~/.zprofile && obsidian create path="investigations/YYYY-MM-DD-<slug>.md" content="..."
```

**Format:**
```markdown
---
status: active
project: [inferred from context — e.g. "viper", "hive", "dotfiles"]
started: YYYY-MM-DD
related: ""
tags: [project-tag]
---

## Summary
[1-2 sentence description of what's being investigated]

## Findings
- [timestamp] Finding description

## Dead Ends
[Empty — populated as investigation progresses]
```

**Filling in frontmatter:**
- `project`: infer from context (branch name, ticket prefix, or explicit mention)
- `related`: wikilink to related decision/standup/investigation if one exists — e.g. `"[[decisions/2026-03-19-vault-dev-token-delivery]]"`. Search for it:
  ```bash
  source ~/.zprofile && obsidian search query="<keywords>" path="decisions"
  source ~/.zprofile && obsidian search query="<keywords>" path="investigations"
  ```
  Leave empty string if nothing relevant found. Don't fabricate links.
- `tags`: one or more lowercase tags matching the project/domain (e.g. `[viper, architecture]`)

## Appending to an existing investigation

Search for the investigation first:
```bash
source ~/.zprofile && obsidian search query="<keywords>" path="investigations"
```

Read the file, then append new findings or dead ends to the appropriate section:
```bash
source ~/.zprofile && obsidian append path="investigations/<filename>" content="..."
```

When appending findings, prefix with a timestamp: `- [HH:MM] Found that...`
When something turns out to be a dead end, add it under Dead Ends so it's not re-explored.

## Closing an investigation

When the user says they're done, update the frontmatter `status` to `resolved` and add a resolution summary.

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Slugs should be short and grep-friendly.** Use lowercase, hyphens, no special chars.
- **Don't over-document.** These are breadcrumbs, not reports. One sentence per finding is ideal.
- **Dead ends are the most valuable part.** Always record why something didn't work, not just that it didn't.
