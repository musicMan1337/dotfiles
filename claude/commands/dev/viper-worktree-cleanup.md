---
name: dev:viper-worktree-cleanup
description: Tear down a Viper worktree. Verifies the branch is committed and pushed AND has an open or already-merged PR (unless the user declares it a dead branch), stops and deletes the Docker containers/networks/volumes for that worktree's compose project, cd's out of the worktree, and runs `git worktree remove`. Leaves no stale worktree behind (prunes metadata). Preserves the origin branch (does not delete remote or local branch). Triggers on: cleanup viper worktree, remove viper worktree, teardown worktree, viper teardown, kill worktree, drop a viper worktree, /dev:viper-worktree-cleanup.
model: opus
---

# /dev:viper-worktree-cleanup

Personal teardown wrapper for Viper worktrees. Pairs with `/dev:viper-worktree`. Lives in `~/.claude/commands/dev/`; safe to customize.

## What this does

1. Resolves the target slug (cwd, args, or interactive pick).
2. Verifies the worktree branch is **clean** (no uncommitted changes) and **pushed** (no unpushed commits).
3. Verifies the branch has a **home**: an open PR or an already-merged PR. Skipped only when the user explicitly declares it a **dead branch** (work being thrown away).
4. **Stops and deletes** the Docker containers + networks + volumes for that worktree's compose project.
5. cd's out of the worktree if currently inside.
6. Runs `git worktree remove --force` from the main Viper checkout, then `git worktree prune` so no stale entry lingers.

**Does NOT delete the branch.** Origin branch and local branch are both preserved. The user can revisit the branch later (e.g. for PR rework) by recreating the worktree. (Exception: a dead branch may be deleted if the user explicitly confirms; see Step 2.5.)

## Load these into context before doing anything

1. `/Users/derek/eBacon/Viper/.claude/skills/viper-dev-worktree/SKILL.md` (canonical teardown semantics)
2. `/Users/derek/eBacon/Viper/bin/viper-docker.sh` (the `teardown` subcommand this skill invokes)

## Constants

- **Viper repo:** `/Users/derek/eBacon/Viper`
- **Worktree root:** `/Users/derek/eBacon/Viper/.worktrees/`
- **Teardown script:** `/Users/derek/eBacon/Viper/bin/viper-docker.sh teardown <slug>`

---

## Step 1: Resolve target slug

Determine which worktree to clean up:

1. **Arg passed** (e.g. `/dev:viper-worktree-cleanup derek-339224-ci4`): use that slug. Verify it exists under `.worktrees/`.
2. **No arg, cwd is inside a worktree** (`pwd` under `/Users/derek/eBacon/Viper/.worktrees/<slug>/`): use that slug.
3. **No arg, cwd is anywhere else:** scan `ls -1t /Users/derek/eBacon/Viper/.worktrees/` and present `AskUserQuestion` picker (top 3 + Other for typing).

If the slug doesn't map to an existing `.worktrees/<slug>/` directory:
- Check `docker ps -a --filter "name=viper-worktree-<slug>-"`. If containers exist but the dir doesn't, the worktree was already removed; offer to clean up the orphaned containers and exit.
- Otherwise tell the user the slug is unknown and stop.

## Step 2: Verify clean + pushed

Run inside the worktree directory (`cd /Users/derek/eBacon/Viper/.worktrees/<slug>`):

```bash
git status --porcelain
git rev-parse --abbrev-ref HEAD
git rev-list --count @{u}..HEAD 2>/dev/null || echo "no-upstream"
```

Bucket the result:

- **Dirty** (`git status --porcelain` non-empty): uncommitted changes exist. Stop and ask:
  1. Commit now via `/git:commit` then continue
  2. Stash and continue (changes preserved in `git stash` list)
  3. Abort cleanup
  4. Force (lose changes)
- **No upstream** (`@{u}` doesn't resolve): branch was never pushed. Stop and ask:
  1. Push now (`git push -u origin <branch>`) then continue
  2. Abort cleanup
  3. Force (branch will still exist locally, but no remote backup)
- **Unpushed commits** (`@{u}..HEAD` count > 0): local commits not on origin. Stop and ask:
  1. Push now (`git push`) then continue
  2. Abort cleanup
  3. Force (commits will still exist locally on the branch, but no remote backup)
- **Clean + pushed:** proceed to Step 3.

Use numbered options in plain text per the global rule (or `AskUserQuestion` if 4 options fit; that's structured selection).

**Note on "force":** even after force, the local branch is preserved. `git worktree remove --force` only removes the working tree, not the branch ref. So "force" here means "I accept the loss of working-tree changes / unpushed commits would only remain locally on the branch ref."

## Step 2.5: Verify the branch has a home (open or merged PR)

Once the branch is clean + pushed, confirm the work won't be orphaned. A worktree should only be torn down when its branch is either in review (open PR) or already landed (merged), unless the user is deliberately discarding it.

**Dead-branch shortcut:** if the user already said this is a dead/throwaway branch (in the invocation args or earlier in the conversation, e.g. "this one's dead", "scrap it", "abandon this branch"), skip the PR check entirely and go to Step 3. Optionally, since the branch is being abandoned, ask whether to also delete it (default: preserve, per the standing rule):
1. Preserve the branch (default), just remove the worktree
2. Delete local + origin branch too (`git branch -D <branch>` and `git push origin --delete <branch>`)

Otherwise check the PR state with `gh` from the worktree (or pass `--head <branch>`):

```bash
gh pr list --head "$(git rev-parse --abbrev-ref HEAD)" --state all \
  --json number,state,url,title --jq '.[0] | "\(.state)\t#\(.number)\t\(.title)\t\(.url)"' 2>/dev/null \
  || echo "gh-unavailable"
```

Bucket the result:

- **OPEN PR:** good, the branch is in review. Note the PR number/URL and proceed to Step 3.
- **MERGED PR:** good, the work landed. Proceed to Step 3.
- **CLOSED PR (not merged):** the PR was closed without merging. Treat like "no PR" below, surface that it was closed.
- **No PR found** (empty result) **or `gh-unavailable`:** stop and ask:
  1. Open a PR now via `/git:pr`, then continue teardown
  2. This is a dead branch, proceed without a PR (and offer the preserve/delete choice above)
  3. Abort cleanup

Do not tear down a worktree whose branch has no PR and no merge unless the user explicitly chooses option 2. The whole point of this gate is "no work silently lost, no stale worktree left behind."

## Step 3: Tear down Docker (stop + delete)

From the main Viper checkout (not the worktree, since we're about to remove it):

```bash
cd /Users/derek/eBacon/Viper && ./bin/viper-docker.sh teardown <slug>
```

This runs the upstream teardown: `docker compose down -v` from the worktree, which **stops the running containers and deletes them** along with the `eBacon` network and the `viper-sessions` volume. The `-v` is intentional here, this is full cleanup. (Contrast: `/dev:viper-worktree` never uses `-v`.) Nothing for this worktree should remain in `docker ps -a` afterward.

If the teardown script errors because the worktree dir is already gone (race or prior partial cleanup), fall back to:

```bash
docker rm -f viper-worktree-<slug>-app-1 viper-worktree-<slug>-hotreload-1 viper-worktree-<slug>-sandbox-1 viper-worktree-<slug>-ci4-1 2>/dev/null
docker network rm viper-worktree-<slug>_eBacon 2>/dev/null
docker volume rm viper-worktree-<slug>_viper-sessions 2>/dev/null
```

Suppress "not found" errors per container; some worktrees don't have every service.

## Step 4: cd out (if needed)

If the cwd was inside the target worktree, switch to the Viper main checkout before the git worktree remove:

```bash
cd /Users/derek/eBacon/Viper
```

This is informational for the user (we run this inline anyway), but the user's shell still has the worktree as cwd. Phase 5 will print a `cd` line they can paste.

## Step 5: Remove the worktree

```bash
cd /Users/derek/eBacon/Viper && git worktree remove --force .worktrees/<slug> && git worktree prune
```

`git worktree remove` is the **correct** removal method, never `rm -rf`/`rimraf` the directory: a manual delete leaves a dangling entry in `git worktree list` (a stale worktree, exactly what we're avoiding) until something prunes it. `git worktree remove` deletes the working tree **and** clears git's metadata in one step. `--force` is used because the Docker teardown may have left untracked artifacts (build caches, generated configs) that `git worktree remove` would otherwise refuse to discard. The trailing `git worktree prune` is belt-and-suspenders: it sweeps any orphaned administrative entry (e.g. if the dir was already partly gone). The branch ref is **not** touched.

Verify nothing stale remains:

```bash
git worktree list | grep <slug> && echo "STILL PRESENT — investigate" || echo "removed"
```

If it still appears, run `git worktree prune` again and re-check; do not leave a stale entry.

## Step 6: Print final state and cd line

End the turn with:

1. A one-line confirmation: `Removed worktree <slug>. Branch <branch-name> preserved (local + origin).`
2. The cd line for the user's shell, in its own fenced block (only if their cwd was inside the removed worktree):

```
cd /Users/derek/eBacon/Viper
```

If their cwd was not inside the removed worktree, omit the cd block.

---

## Gotchas

- **Never delete the branch (default).** No `--delete-branch` flag to the upstream teardown. No `git branch -D`. No `git push origin --delete`. The user wants the branch preserved on both local and origin so they can rehydrate the worktree later if needed. **Only exception:** an explicit dead branch where the user chose option 2 in Step 2.5 (delete local + origin). Never delete on your own initiative.
- **PR/merge gate is mandatory unless dead.** Step 2.5 blocks teardown of a branch that has no open PR and was never merged, so review-bound or unlanded work isn't quietly thrown away with the worktree. Skip the gate only when the user explicitly calls the branch dead/throwaway. If `gh` is unavailable, treat it as "no PR found" and prompt; don't silently skip the gate.
- **`git worktree remove`, never `rimraf`/`rm -rf`.** Deleting the directory by hand leaves a dangling `git worktree list` entry (a stale worktree). Always remove via `git worktree remove --force` and follow with `git worktree prune`. Verify the slug is gone from `git worktree list` before declaring done.
- **Volumes go with `-v` here.** Unlike `/dev:viper-worktree` (which never uses `-v` because preserving sessions matters mid-development), this skill is **full teardown**. The `viper-docker.sh teardown` command already includes `-v` by default. Sessions for this worktree are gone, which is fine because the worktree itself is going.
- **`git worktree remove --force` is non-destructive to the branch.** It only removes the working tree directory + the worktree's metadata entry. The branch ref remains in `refs/heads/<branch>`.
- **Cwd-inside-worktree edge case.** If the user runs this from inside the worktree, the shell process's cwd becomes invalid the moment `git worktree remove` succeeds. The bash commands this skill runs use absolute paths or chained `cd /Users/derek/eBacon/Viper && ...`, so they're fine. But the user's interactive shell still has a stale cwd. Step 6's cd line is for them.
- **Confirm before force.** "Force" options on the dirty/unpushed prompts must surface what's lost (working tree changes are gone; local-only commits remain on the branch ref). Do not pass `--force` to the teardown silently.
- **Orphan-only mode is allowed.** If the `.worktrees/<slug>/` dir is already gone but containers linger (prior partial cleanup), just run the Step 3 fallback `docker rm/network rm/volume rm` block and exit. No git worktree remove needed (it's already not in `git worktree list`, or `git worktree prune` will fix it).
- **Single target per invocation.** No batch mode. If the user wants to clean up multiple worktrees, run this skill once per slug. Batch operations belong in the upstream `./bin/viper-docker.sh teardown --all` which has its own confirmation flow.
- **Customize this file freely.** Personal wrapper; you own it.
