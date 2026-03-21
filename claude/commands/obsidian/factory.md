---
name: obsidian:factory
model: haiku
description: Manage factory session files in Obsidian. Sub-agents write findings to session folders instead of returning to orchestrator. Triggers on: factory file, write factory session, factory obsidian, session file
---

# Factory Session Files

Write, read, append, or list files in a factory session's Obsidian folder. Sub-agents use this to persist their work so the orchestrator's context stays lean — the next phase reads files directly instead of receiving results inline.

## Input

Parse from arguments or calling context:

- **session**: The pipeline run-id (e.g., `20260321-143022-fix-login-bug`) — required
- **op**: `write` | `append` | `read` | `list` — default `write`
- **file**: Filename following the convention below — required for write/append/read
- **content**: The content to write/append — required for write/append

## File Naming Convention

All files live at `factory/<session>/<file>.md` in the Obsidian vault.

**Pattern:** `<phase>-<agent-id>-<description>.md`

- `<phase>` — phase number (1-6) or name (`synthesis`, `spec`, `audit`)
- `<agent-id>` — agent number (01, 02, 03) or role (`synthesis`, `main`)
- `<description>` — short slug describing the content

**Examples:**
```
factory/20260321-143022-fix-login/1-01-codebase-analysis.md
factory/20260321-143022-fix-login/1-02-web-research.md
factory/20260321-143022-fix-login/1-synthesis.md
factory/20260321-143022-fix-login/2-spec.md
factory/20260321-143022-fix-login/3-implement-log.md
factory/20260321-143022-fix-login/4-audit.md
factory/20260321-143022-fix-login/status.md
```

## Operations

### write — Create or overwrite a session file

```bash
source ~/.zprofile && obsidian create path="factory/<session>/<file>.md" content="<content>" overwrite
```

Use for: initial findings, spec output, synthesis results. Overwrites if the file already exists.

### append — Add to an existing session file

```bash
source ~/.zprofile && obsidian append path="factory/<session>/<file>.md" content="<content>"
```

Use for: incremental findings, progressive updates during long-running agents.

### read — Read a session file

```bash
source ~/.zprofile && obsidian read path="factory/<session>/<file>.md"
```

Use for: next-phase agents loading prior-phase output. The orchestrator tells agents which files to read — agents read directly rather than receiving content from the orchestrator.

### list — List all files in a session

```bash
source ~/.zprofile && obsidian search query="" path="factory/<session>"
```

Use for: discovering what's been written so far, resuming from a checkpoint, debugging.

## Gotchas

- **Source zprofile.** Always `source ~/.zprofile &&` before any obsidian command.
- **Session ID is the pipeline run-id.** Don't invent a new ID scheme. The pipeline generates `YYYYMMDD-HHMMSS-<slug>` and every agent in that run uses the same session ID.
- **Agents write, orchestrator coordinates.** The orchestrator tells sub-agents the session ID and what filename to use. Sub-agents write their output. The orchestrator tells the next phase's agents which files to read. The orchestrator itself never reads the full content — that's the whole point.
- **Don't nest deeper.** Files go directly in `factory/<session>/`, not in sub-subdirectories. The phase prefix in the filename provides enough organization.
- **Keep files focused.** One file per agent per phase. Don't have one agent write to multiple files — that makes it harder for the next phase to know what to read.
- **The synthesis file is special.** Each phase should produce a `<phase>-synthesis.md` that combines the individual agent outputs into a coherent summary. This is what the next phase actually reads.
