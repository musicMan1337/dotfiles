---
name: git:commit
description: Create a git commit following the house format. Triggers on: commit, save changes, commit this
---

## Goal

One commit for the current changes, message in the house format below.

## Who commits

- **Nontrivial diff** (many files, large hunks, or a diff you haven't already seen in-session): spawn the `committer` agent (Haiku-pinned; the one agent permitted to run mutating git) and relay its one-line result. This keeps large diffs out of the premium main session. Pass it the format spec and ground rules below, plus any context on why the change was made.
- **Trivial diff** already understood in-session: commit directly, same format.

## Message format (the spec is the validation; no regex self-check needed)

- Conventional Commits, terse. Subject: `<type>(<scope>): <imperative summary>`, 50-char target, 72 hard max, lowercase after the colon, no trailing period.
- Types: feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert.
- Body only when the why isn't obvious; always for breaking changes, migrations, security fixes. Bullets use `-`. Reference issues: `Closes #42`, `Refs #17`.
- No filler ("This commit", "I", "we", "now"), no emoji, never the em-dash character.

## Ground rules (incident-derived)

- Stage specific files; avoid blanket `git add -A`; never stage `.env`, credentials, or secrets.
- Multi-line messages via heredoc (`git commit -m "$(cat <<'EOF' ... EOF)"`); other quoting is fragile on MSYS Git Bash.
- Pre-commit hook failure: fix only what the hook flags in the files being committed, re-stage, create a NEW commit. Never `--amend`; the failed commit never happened.
