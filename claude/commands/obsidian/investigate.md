---
name: obsidian:investigate
model: haiku
description: Create or append to an investigation note in Obsidian for debugging, research, or exploration. Triggers on: investigate, investigation, debug notes, research trail, what did I find, log investigation
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
**Status:** Active
**Started:** YYYY-MM-DD
**Related:** [ticket/case number if mentioned, branch name if relevant]

## Summary
[1-2 sentence description of what's being investigated]

## Findings
- [timestamp] Finding description

## Dead Ends
[Empty — populated as investigation progresses]
```

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

When the user says they're done, update the Status line to "Resolved" and add a resolution summary.

## Gotchas

- **Source zprofile:** Always prefix obsidian commands with `source ~/.zprofile &&`.
- **Slugs should be short and grep-friendly.** Use lowercase, hyphens, no special chars.
- **Don't over-document.** These are breadcrumbs, not reports. One sentence per finding is ideal.
- **Dead ends are the most valuable part.** Always record why something didn't work, not just that it didn't.
