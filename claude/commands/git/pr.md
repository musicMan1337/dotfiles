---
name: git:pr
description: Create a pull request for the current branch. Triggers on: make a PR, open PR, create pull request
---

## Goal

Open a PR for the current branch against the repo's default branch and report its URL. If a PR already exists for the branch, report the existing URL instead.

## Who does it

- Default: spawn the `reader` agent (or any cheap-tier subagent) to do the whole thing; PR creation is mechanical and keeps git/gh output out of the main session.
- If the branch's commits and changes are already fully in your context, doing it directly is fine.

## Content rules

- Title: under 70 chars, imperative mood.
- Body: `## Summary` (1–3 bullets) + `## Test plan` (bulleted checklist). Ground the summary in the actual changes; commit messages are usually sufficient since house commits are diff-derived. On a huge diff, skim `--stat` plus key files rather than reading everything; never invent details.
- Base branch = the repo default. Push with `-u` first if the branch has no upstream.
- Multi-line body via heredoc (`gh pr create --body "$(cat <<'EOF' ... EOF)"`); other quoting is fragile on MSYS Git Bash.
- **Prefix the command with `PR_VIA_SKILL=1`**, i.e. `PR_VIA_SKILL=1 gh pr create ...`. The `pr-guard.sh` PreToolUse hook denies raw `gh pr create`, and denies `gh pr edit` when it carries `--title`/`--body`/`--body-file`, so PR prose cannot bypass this file's format and authorship rules. That marker is what identifies the call as coming from here; without it your own command is blocked. Metadata-only edits (`--add-label`, `--add-reviewer`, `--base`, `--milestone`) need no marker.
- If `gh pr create` fails because a PR exists, report the existing PR's URL (`gh pr view --json url`).

## Authorship (ABSOLUTE, no exceptions)

The PR is MINE; title and body must read as if I typed them, first person ("I", "we"). **NEVER** mention yourself, a model, an agent, a subagent, a session, a prompt, or a tool anywhere in the PR, and **NEVER** append an attribution footer ("Generated with Claude Code", 🤖, "AI-assisted", any model name). Summary and test-plan bullets describe the change, never who or what produced it. Pass this rule to any subagent you spawn for the PR, and re-read the body before `gh pr create`.

## Report

The PR URL, nothing else.
