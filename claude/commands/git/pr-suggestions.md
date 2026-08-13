---
name: git:pr-suggestions
description: Address unresolved review comments on a PR. Triggers on: pr suggestions, review comments, address review
allowed-tools: Bash(gh *), Bash(git *), Bash(dotnet *), Bash(npm run lint*), Bash(npx prettier*), Bash(grep*), Read, Write, Edit, Glob, Grep, Agent, Skill(git:commit), Skill(code-review:code-review)
---

## Your task

Review and address all unresolved review comments on the current branch's PR — from bots, humans, or any other source.

## Authorship (ABSOLUTE, no exceptions)

Every reply you post is MINE, in my voice, first person ("I", "we"). Teammates read these. **NEVER** disclose or hint that a model, agent, or tool wrote it: no "Claude", no model name, no 🤖, no "AI"/"AI-assisted"/"generated", no "the agent", "the subagent", "this session", or "the prompt". Same for every commit made through `/git:commit` here: no attribution trailers. Re-read each reply before posting and strip any self-reference; one slip is a defect, not a style nit.

## Step 1 — Find the PR and fetch comments

1. `git branch --show-current` to get the branch
2. `gh pr view --json number,url --jq '.number'` to get the PR number
3. Fetch all review comments (not filtered by author):
```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments --jq '.[] | {id, path, line, body, in_reply_to_id, user_login: .user.login}'
```
4. Filter to only TOP-LEVEL comments (where `in_reply_to_id` is null). For each, check if there's already a reply from you (the current git user) — skip those.
5. Also fetch review-level comments (non-inline):
```bash
gh api repos/{owner}/{repo}/pulls/{number}/reviews --jq '.[] | select(.state != "APPROVED" and .state != "DISMISSED" and .body != "") | {id, user_login: .user.login, state, body}'
```

If no unresolved comments exist, report that — then offer to run a full code review on the PR using the `/code-review:code-review` skill. Ask: "No unresolved comments. Want me to do a full review of this PR instead?"

If the user accepts, invoke the `code-review:code-review` skill via the Skill tool. If they decline, stop.

## Step 2 — For each comment, evaluate and act

For each unresolved comment, read the referenced code and make a judgment call:

### Option A: Intentional / Not an issue
The comment asks about a deliberate design choice, or flags something that's correct as-is. Reply explaining the rationale concisely. Don't be defensive — acknowledge the concern and explain why the current approach is right.

### Option B: Valid issue — fix it
The comment identifies a real bug, gap, or improvement worth making. Make the code change, then:
1. Stage and commit (invoke `/git:commit` via the Skill tool)
2. Push: `git push`
3. Reply to the comment noting the fix was applied, with a brief description of what changed

### Option C: Noise / low-value
The comment is generic, obvious, or not actionable. Reply briefly acknowledging it and explaining why no change is needed. Keep it professional — the comment is visible to the team.

## Replying to comments and resolving threads

### Reply in-thread
```bash
gh api repos/{owner}/{repo}/pulls/{number}/comments/{comment_id}/replies \
  -X POST -f body="<your reply>"
```

### Resolve the conversation
After replying, resolve the thread so it collapses in the PR. This requires the thread's GraphQL node ID.

1. Fetch review threads to find the thread ID for the comment:
```bash
gh api graphql -f query='
query {
  repository(owner: "{owner}", name: "{repo}") {
    pullRequest(number: {number}) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes {
              databaseId
              author { login }
            }
          }
        }
      }
    }
  }
}'
```

2. Match the thread by finding the one whose first comment's `databaseId` matches your `comment_id`, then resolve it:
```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "{thread_node_id}"}) {
    thread { isResolved }
  }
}'
```

You can batch this: fetch all threads once at the start, build a map of `comment_id → thread_node_id`, then resolve each after replying.

## Step 3 — Report

After addressing all comments, print a summary:
- How many comments were addressed
- What action was taken for each (replied/fixed/dismissed)
- Who left each comment (so the user knows which teammates to follow up with)
- Any that need the user's input (if you weren't sure)

## Gotchas

- **Don't auto-fix without reading context.** Always read the surrounding code and understand the architectural intent before deciding. A suggestion that looks valid in isolation may be wrong in context.
- **Bot vs human comments:** Treat human comments with more weight — they reflect team knowledge and context that bots lack. Bot comments (Augment, CodeRabbit, etc.) are more likely to be noise.
- **Reply in-thread, not as new comments.** Use the `/replies` endpoint with the comment ID, not the top-level comments endpoint — otherwise you create a disconnected comment instead of a thread reply.
- **Check if already addressed.** Before acting on a comment, check if there's already a reply thread. Don't double-reply.
- **Push before replying on fixes.** If you made a code change, push first so the reply references committed code.
