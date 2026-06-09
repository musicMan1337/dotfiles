---
name: skill-finder
description: Find the right skill or command by intent, even when it is not surfaced in context. Searches every installed SKILL.md and command-file frontmatter (including gsd-* and any name-only / user-invocable-only / hidden skills whose descriptions are suppressed for startup-context savings) and returns the best match plus exactly how to invoke it. Triggers on, find a skill, which skill, is there a skill for, what skill does X, discover a skill, find a command, no skill surfaced for this, /skill-finder.
---

# skill-finder

Most skills are deliberately suppressed from startup context (via `skillOverrides` in
`settings.json`) to save tokens: the whole `gsd-*` cluster is `user-invocable-only`
(invisible to the model, still runnable with `/gsd-...`), and long-tail clusters
(`spec:*`, `vuln:*`, `splunk:*`, `setup:*`, `project:*`, `research:*`, plus some
`obsidian:*` and misc) are `name-only` (name known, description dropped). This skill
recovers their full descriptions on demand so you can route to them by intent.

## When to use

- The user describes a task and you suspect a skill exists but its description is not in context.
- The user explicitly asks "is there a skill for X" / "which skill does Y".
- Before telling the user "no skill exists" — verify here first.

## Procedure

Pass the user's intent as `$ARGUMENTS` (keywords, not a sentence). Then:

1. **Search frontmatter across all installed skills/commands.** Spawn a Haiku subagent
   (per the global subagent rule) to run this and return the matches:

   ```bash
   # Search both skill dirs and command files for the query terms in their
   # frontmatter `description:` (and headings). Case-insensitive, multi-term OR.
   Q="$ARGUMENTS"   # e.g. "deadlock splunk logs"
   roots=("$HOME/.claude/skills" "$HOME/.claude/commands")
   # collect candidate files. -L is REQUIRED: ~/.claude/commands is itself a symlink
   # into dotfiles, and ~/.claude/skills holds symlinks; without -L find scans nothing.
   files=$(find -L "${roots[@]}" \( -name SKILL.md -o -name '*.md' \) -type f 2>/dev/null)
   # rank: print file + description line for any file whose description matches any term
   for f in $files; do
     desc=$(awk '/^description:/{sub(/^description:[[:space:]]*/,"");print;exit}' "$f")
     name=$(awk -F'"' '/^name:/{sub(/^name:[[:space:]]*/,"");gsub(/"/,"");print;exit}' "$f")
     for term in $Q; do
       if printf '%s\n' "$desc $name $f" | grep -qi -- "$term"; then
         printf '%s\t%s\t%s\n' "${name:-?}" "$f" "$desc"; break
       fi
     done
   done
   ```

   For `gsd-*` and other suppressed skills the `description:` line in the SKILL.md is the
   full, un-truncated text, which is exactly what was dropped from startup context.

2. **Rank and present the top 3-5 matches.** For each: the invocation name (slash form,
   e.g. `/gsd-spike`, `/splunk:sql`) and a one-line reason it fits. Number them per the
   global numbered-options rule.

3. **Map file path back to invocation name** when frontmatter `name:` is absent:
   - `~/.claude/skills/<dir>/SKILL.md` -> `/<dir>`
   - `~/.claude/commands/<ns>/<name>/SKILL.md` or `.../<ns>/<name>.md` -> `/<ns>:<name>`
   - `~/.claude/commands/<name>.md` -> `/<name>`

4. **Offer to invoke.** If one match is clearly right, invoke it directly via the Skill
   tool (suppressed skills are still invocable). Otherwise present the numbered list and
   ask which to run.

## Notes

- This does not cover marketplace/plugin skills (managed via `enabledPlugins`); it targets
  user skills/commands under `~/.claude`.
- If nothing matches, say so plainly and suggest `/skill-creator` to make one.
- To re-surface a suppressed skill permanently, edit its entry in `settings.json`
  `skillOverrides` (`on` = full, `name-only` = name kept, `user-invocable-only` = slash
  only, `off` = hidden). Run `/reload-skills` after editing.
