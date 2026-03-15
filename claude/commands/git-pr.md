---
model: haiku
allowed-tools: Bash(gh pr:*), Bash(git log:*), Bash(git diff:*), Bash(git branch:*)
description: Create a pull request for the current branch
---

## Context

- Current branch: !`git branch --show-current`
- Default branch: !`gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`
- Commits on this branch: !`git log --oneline $(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')..HEAD`
- Diff stat: !`git diff $(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')...HEAD --stat`

## Your task

Create a pull request for the current branch using `gh pr create`.

- Base branch should be the default branch (shown above)
- Derive the PR title and body from the commits and diff above
- Keep the title short (under 70 characters)
- Body format:

```
## Summary
<1-3 bullet points>

## Test plan
<bulleted checklist>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- After creating, print the PR URL so the user can see it
