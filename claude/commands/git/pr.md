---
name: git:pr
model: haiku
allowed-tools: Bash(gh pr:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*), Bash(git remote:*)
description: Create a pull request for the current branch. Triggers on: make a PR, open PR, create pull request, push and PR, submit PR
---

## Your task

Create a pull request for the current branch.

## Step 1 — Gather context (do this yourself)

Run these commands to understand the branch:

1. `git branch --show-current` — current branch name
2. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` — default/base branch
3. `git log --oneline <default-branch>..HEAD` — commits on this branch
4. `git diff <default-branch>...HEAD --stat` — diff summary (file names only, NOT full diff)

## Step 2 — Create PR

Use `gh pr create` with a heredoc body:

```bash
gh pr create --title "<short title under 70 chars>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points derived from the commits>

## Test plan
<bulleted checklist>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- Derive the title and summary from the commit messages and diff stat
- Keep the title short (under 70 characters)
- Base branch should be the default branch

## Step 3 — Report

Print the PR URL so the user can see it.
