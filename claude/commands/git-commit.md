---
model: haiku
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git branch:*), Bash(git log:*), Bash(npm run lint:*), Bash(npx prettier:*)
description: Create a git commit
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## IMPORTANT: Pre-commit lint check

**HIGH PRIORITY — Do this BEFORE committing.**

If the repo has an `npm run lint` script (check package.json), run it before committing. If lint fails, stop and report the errors — do NOT commit.

### Exception: Viper repo (~/eBacon/Viper)

The Viper repo does NOT have a standard lint script. Instead, run `npx prettier --write` **only on the files being committed** (i.e. the changed/staged files). Do not run prettier on the entire codebase.

## Your task

Based on the above changes, create a single git commit.

After committing, print the short hash and full commit message (title and body) so the user can see what was committed.
