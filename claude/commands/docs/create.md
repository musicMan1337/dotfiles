---
name: docs:create
model: opus
description: Create a new agent-target doc in the current repo (CLAUDE.md, SKILL.md, README, plan/spec, ADR). Before writing, searches for existing docs that overlap and prompts to update, consolidate, or replace instead of creating a duplicate. Triggers on, create doc, new doc, add readme, write claude md, new skill md, new spec, new plan, document this, create agent doc, add adr.
allowed-tools: Read, Edit, Write, Bash, Glob, Grep, Agent
---

# Docs Create

Create a new agent-target doc in the current repo, but only after confirming no existing doc already covers (or partially covers) the topic. **Defaulting to "just write a new file" is the anti-pattern this command exists to prevent.** Doc sprawl rots faster than stale code because there's no compiler complaining.

## Input

**Request:** $ARGUMENTS

Expected shape: a topic + optional path/type hint.
- "create a CLAUDE.md explaining the auth conventions" → topic=auth conventions, target=CLAUDE.md
- "new ADR for the Procore sync direction" → topic=Procore sync, target=ADR
- "README for the new file-sync action" → topic=file-sync action, target=README in that folder
- "a skill that handles X" → defer to `/skill-creator` instead

If the request is just a topic with no target hint, ask which kind of doc the user has in mind before searching.

## Step 1 — Search for overlapping docs (BLOCKING, do this FIRST)

Before drafting anything, find any existing doc whose scope overlaps the topic. Use a Haiku subagent to keep this cheap and avoid context bloat.

Search vectors:

```
fd -t f -e md . | rg -i '(CLAUDE|AGENTS|SKILL|README|\.cursorrules|\.windsurfrules|PLAN|SPEC|ADR)' | head -100
rg -l -i '<keyword from topic>' --type md
ls .claude/rules/ 2>/dev/null
ls .planning/ 2>/dev/null
ls docs/decisions/ docs/adr/ docs/specs/ 2>/dev/null
```

For each candidate file: capture path, top heading, and a one-line summary of its scope. **Overlap is not just keyword match.** A `CLAUDE.md` at root that mentions "auth" is in scope for any auth-doc request, even if the topic is more specific. A component's `README.md` is in scope for any convention doc inside that component.

Be slightly aggressive in flagging overlap — false positives just prompt a user choice, but false negatives create duplicates that linger for months.

## Step 2 — Branch on findings

### Branch A: No overlapping docs exist

Proceed to Step 3 (draft + write the new doc).

### Branch B: One or more overlapping docs exist

**Stop. Present the conflict to the user. Do not write anything yet.**

Show:

```
Found existing docs that overlap with "<topic>":

1. <path> — <one-line scope summary>
2. <path> — <one-line scope summary>

How do you want to proceed?

1. Update <path> — add to an existing doc (recommended when overlap is partial)
2. Consolidate — merge existing + new content into a single doc (best when 2+ files cover the same ground)
3. Replace <path> — overwrite the existing doc with the new content (existing content is stale or wrong)
4. Create anyway — the topics really are distinct (you must say why)
5. Skip
```

For option 4, require the user to articulate the distinction. "They're different" is not enough. If after their explanation it still looks like overlap, push back once: "Last check, [overlap-X] sounds like it'd also fit in [existing-path]. Sure?" Then honor their call.

**Keeping multiple docs covering the same ground is the failure mode this command exists to prevent.** Lean toward update/consolidate.

## Step 3 — Choose path and conventions

If creating new:

- Match repo conventions for placement. Mirror existing docs of the same type.
  - ADRs → wherever the repo already keeps them (`docs/adr/`, `docs/decisions/`, `.planning/decisions/`); use the existing numbering / date prefix scheme.
  - Specs/plans → match `.planning/` structure if present.
  - Skill-level rules → `.claude/rules/<topic>.md` if that pattern is in use.
  - Component README → at the component root, not at repo root.
  - Repo-wide agent rules → `CLAUDE.md` at repo root (but prefer Branch A's "update existing" if one already exists).
- Match file's voice and density: CLAUDE.md is terse, ADRs are structured (Context / Decision / Consequences), READMEs vary by repo.

If consolidating, write the merged doc to the most appropriate existing path (usually the canonical/root-most one) and plan to delete the others in Step 5.

## Step 4 — Draft and show

Draft the new (or merged, or replacement) content. Show it inline before writing. Keep it scoped — a new doc should earn every line.

Present:

```
Plan:
- <Create | Update | Consolidate | Replace>: <target path>
- Delete (if consolidating): <other paths>
- Voice/template: <conventions matched>

Draft:
<contents>
```

Hard gate: do not write until user picks.

1. Approve, write it
2. Make changes (user describes)
3. Skip

## Step 5 — Write, delete, report

After approval:

- Use `Write` for genuinely new files; `Edit` for updates/replacements (preserves diff history clarity).
- If consolidating, delete the redundant files with `rm` after the merged doc is written.
- Update any pointers (CLAUDE.md links, README indexes, plan TOC) that now point to a deleted or renamed file. Search:
  ```
  rg -l '<deleted-file-basename>' --type md
  ```
- One-line summary: what was created, what was merged/deleted, what pointers were updated. Done.

## Gotchas

- **The default impulse is "just write it." Resist.** The search step is the entire reason this command exists. If you skip it, you may as well have used `Write` directly.
- **Overlap is semantic, not lexical.** `auth.md` and `permissions.md` may cover the same ground even though the filenames differ. Read the headings, not just filenames.
- **Consolidate over create.** Two short docs on the same topic age worse than one comprehensive doc. Future agents reading both will get conflicting signals when one drifts.
- **Don't create CLAUDE.md duplicates.** A repo should have at most one CLAUDE.md at root and (rarely) one per major sub-project. If you're about to create a second CLAUDE.md anywhere in the tree, the user almost certainly wanted to add to the existing one.
- **ADRs are append-only.** When the user wants to record a decision that supersedes an old one, create a new ADR that references and supersedes the old — never edit the old ADR's decision section. The "Status" header is the right knob (Accepted → Superseded by ADR-NNNN).
- **Plans/specs in flight are contracts.** If a phase has a PLAN.md and the user wants to add "more plan content," it's a deviation note, not a rewrite. Prefer adding to an existing section over restructuring.
- **READMEs at repo root serve humans first.** Don't dump agent-only conventions into the top-level README. That's CLAUDE.md territory.
- **If creating a skill, redirect to `/skill-creator`.** That's a different beast — it has structure (frontmatter, trigger phrases, gotchas section) this command won't enforce.
- **"They're truly unique" is rare.** Override (option 4) should be the exception. If you find yourself approving option 4 often, the search step is too narrow and needs tuning.
