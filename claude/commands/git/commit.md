---
name: git:commit
model: haiku
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Read
description: Create a git commit with lint checks. Triggers on: commit, save changes, commit this, git commit
---

## Your task

Create a single git commit for the current changes. Terse caveman-style commit message.

## Step 1 — Gather context

Run these commands:

1. `git status` — what files changed/untracked
2. `git diff --stat HEAD` — summary of changes
3. `git diff HEAD` — full diff (if >200 lines, use `--stat` and read key files instead)
4. `git branch --show-current` — current branch
5. `git log --oneline -5` — recent commit style

## Step 2 — Stage and commit

1. Stage appropriate files with `git add` (prefer specific files over `git add -A`)
2. Write commit message using Conventional Commits format:
   - Subject: `<type>(<scope>): <imperative summary>` — **≤50 chars**, hard cap 72
   - Types: feat, fix, refactor, perf, docs, test, chore, build, ci, style, revert
   - Body: only when "why" isn't obvious from subject. Why over what.
   - Skip body for self-explanatory changes
   - Add body for: breaking changes, migrations, linked issues, security fixes, reversions
   - No "This commit does X", no "I"/"we"/"now"/"currently", no emoji (unless project convention)
   - Bullets use `-` not `*`
   - Reference issues: `Closes #42`, `Refs #17`
   - No period on subject line
3. Commit using heredoc:
```bash
git commit -m "$(cat <<'EOF'
Commit message here.
EOF
)"
```

## Step 3 — Report

```bash
git log --oneline -1
```
