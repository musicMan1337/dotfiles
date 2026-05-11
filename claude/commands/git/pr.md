---
name: git:pr
description: Create a pull request for the current branch via Haiku subagent. Triggers on: make a PR, open PR, create pull request
allowed-tools: Agent
---

## Your task

Create a pull request for the current branch.

## CRITICAL: Delegate immediately

**Do NOT read diffs, run git commands, or do any work yourself.** Spawn a single Haiku subagent and let it do everything. The diff can be large — loading it into the main session wastes context and risks limit errors.

Your only job is to launch the subagent and relay the PR URL.

## Spawn the subagent

Use the Agent tool with `model: "haiku"` and this prompt (adapt the working directory if needed):

---

Create a pull request for the current branch. Follow these steps exactly:

### Step 1 — Gather context

Run in parallel:
1. `git branch --show-current` — current branch name
2. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` — default/base branch
3. `git log --oneline $(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')..HEAD` — commits on this branch
4. `git diff $(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')...HEAD --stat` — diff summary (file names only, NOT full diff)
5. `git remote -v` — check remote exists

If the branch has no upstream, push it first:
```bash
git push -u origin $(git branch --show-current)
```

### Step 2 — Create PR

Derive title and summary from commit messages and diff stat. Do NOT read full diffs.

```bash
gh pr create --title "<short title under 70 chars>" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points derived from the commits>

## Test plan
<bulleted checklist>
EOF
)"
```

Rules:
- Title under 70 characters, imperative mood
- Summary from commit messages — don't invent details
- Base branch = default branch
- If `gh pr create` fails because a PR already exists, run `gh pr view --web` instead and report the existing URL

### Step 3 — Report

Return ONLY the PR URL. Nothing else.

---

## After the subagent returns

Relay the PR URL to the user. That's it. No elaboration needed.
