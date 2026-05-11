---
name: git:commit
description: Create a git commit with lint checks via Haiku subagent. Triggers on: commit, save changes, commit this
allowed-tools: Agent
---

## Your task

Create a single git commit for the current changes.

## CRITICAL: Delegate immediately

**Do NOT read diffs, run git commands, or do any work yourself.** Spawn a single Haiku subagent and let it do everything. The diff can be large — loading it into the main session wastes context and risks limit errors.

Your only job is to launch the subagent and relay its one-line result.

## Spawn the subagent

Use the Agent tool with `model: "haiku"` and this prompt (adapt the working directory if needed):

---

Create a git commit for the current changes. Follow these steps exactly:

### Step 1 — Gather context

Run in parallel:
1. `git status` — what changed
2. `git diff --stat HEAD` — change summary
3. `git branch --show-current` — current branch
4. `git log --oneline -5` — recent commit style

Then read the full diff. If `git diff HEAD` is >200 lines, use `--stat` and selectively read key changed files instead.

### Step 2 — Stage and commit

1. Stage files with `git add` — prefer specific files over `git add -A`. Never stage `.env`, credentials, or secrets.
2. Write commit message — Conventional Commits, terse:
   - Subject: `<type>(<scope>): <imperative summary>` — **50 char cap**, hard max 72
   - Types: feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert
   - Body: only when "why" isn't obvious. Skip for self-explanatory changes.
   - Add body for: breaking changes, migrations, linked issues, security fixes
   - No filler ("This commit", "I", "we", "now"), no emoji, no period on subject
   - Bullets use `-` not `*`
   - Reference issues: `Closes #42`, `Refs #17`
3. Commit using heredoc:
```bash
git commit -m "$(cat <<'EOF'
message here
EOF
)"
```

### Step 3 — Handle pre-commit hook failures

If the commit fails due to a pre-commit hook (lint, format, etc.):
1. Read the error output carefully
2. Fix the issues the hook flagged — if they are simple formatting/linting errors (e.g., Prettier, ESLint auto-fixable rules, trailing whitespace), fix them directly. Only fix issues in files being committed, not the entire repo.
3. Re-stage the fixed files
4. Create a NEW commit (do NOT use --amend — the failed commit never happened)

### Step 4 — Report

Run `git log --oneline -1` and return ONLY that one line. Nothing else.

---

## After the subagent returns

Relay the one-line commit result to the user. That's it. No elaboration needed.
