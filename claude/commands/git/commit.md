---
name: git:commit
model: haiku
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(npm run lint:*), Bash(npx prettier:*), Bash(cat package.json:*), Bash(grep:*), Read
description: Create a git commit with lint checks. Triggers on: commit, save changes, commit this, git commit
---

## Your task

Create a single git commit for the current changes.

## Step 1 — Gather context (do this yourself)

Run these commands to understand what you're committing:

1. `git status` — see what files are changed/untracked
2. `git diff --stat HEAD` — summary of changes (file names and line counts only)
3. `git diff HEAD` — full diff, BUT if it's very large (>200 lines), use `git diff --stat HEAD` and read individual key files instead
4. `git branch --show-current` — current branch
5. `git log --oneline -5` — recent commit style

## Step 2 — Pre-commit lint check

**HIGH PRIORITY — Do this BEFORE committing.**

Check if the repo has an `npm run lint` script by running `grep -q '"lint"' package.json && echo "HAS_LINT" || echo "NO_LINT"`.

- **If HAS_LINT**: Run `npm run lint`. If lint fails with errors (not warnings), stop and report the errors — do NOT commit.
- **If NO_LINT**: Skip this step.

### Exception: Viper repo (~/eBacon/Viper)

The Viper repo does NOT have a standard lint script. Instead, run `npx prettier --write` **only on the files being committed** (i.e. the changed/staged files). Do not run prettier on the entire codebase.

## Step 3 — Stage and commit

1. Stage the appropriate files with `git add` (prefer specific files over `git add -A`)
2. Write a concise commit message that summarizes the "why" not the "what"
3. Commit using a heredoc for the message:
```bash
git commit -m "$(cat <<'EOF'
Commit message here.
EOF
)"
```

## Step 4 — Report

Print the short hash and full commit message so the user can see what was committed:
```bash
git log --oneline -1
```
