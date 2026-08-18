---
name: agentic-coding-school:update
model: opus
description: Mine recent Agentic Coding School videos (default, last 60 days, unwatched first) for techniques worth adding to my local harness, gate them against the Bitter Lesson rules, and propose concrete file changes. Triggers on, agentic coding school update, check for new course videos, any new videos worth watching, mine the course for harness ideas, what's new in the class, acs update, course update, harness ideas from videos, /agentic-coding-school:update.
---

# agentic-coding-school:update

Goal: find the few things in recent course videos that would actually change a file in `~/dotfiles/claude`, and reject everything else. The deliverable is a short list of proposed harness diffs, usually 0 to 3, plus what was rejected and why.

This is not a "what's new" digest and not a watchlist builder. Summaries of videos are not the output; harness changes are.

## Environment facts

- MCP `mcp__agentic-coding-school__*` is **read-only**: `list_classes`, `list_videos`, `search_videos`, `get_video`, `get_my_progress`, `get_my_notes`. There is no tool to mark a video watched, favorited, or watch-later; completion is set in the web UI. That is why the ledger below exists. (Re-check on MCP server upgrades; if a mutation tool appears, use it and shrink the ledger. Last checked 2026-08.)
- `isCompleted` reflects watch progress, not whether a video was mined for harness value. The two are independent axes: unwatched-and-unmined is the priority queue, watched-but-unmined is still fair game.
- `list_videos` returns a per-video `glossary` blob that is noise for this task. Ignore it. `includeContext: true` is large output; only use it inside a subagent.
- Pinned agents (`reader`, `classifier`, `synthesizer`) have no MCP access (`tools: Read, Grep, Glob, Bash`). Transcript miners must be `general-purpose` with an explicit `model` param, which is also what the subagent-gate requires. Miners load the schema themselves first: `ToolSearch("select:mcp__agentic-coding-school__get_video")`.
- Max 4 concurrent subagents (CryptoGuard; see Subagent Strategy in `~/dotfiles/CLAUDE.md`).
- Transcripts are paid course material and `~/dotfiles` is a public repo. Transcript text stays in the session: never into the ledger, a scratchpad file, a commit, or an artifact. Short verbatim anchors (a sentence or less) are fine in chat.

## Run

### 1. Queue

Window defaults to the last 60 days. Args override it: `30d`, `since 2026-05-01`, a class slug (`loopy-ai`), or `all`.

`list_videos({ addedSince })`, then drop every title already in `ledger.md`. Report the counts (new / already mined / total in window) before going further.

### 2. Inventory the harness before scoring anything

The dominant failure of this skill is proposing something already built months ago. Read the current surface first:

```bash
cd ~/dotfiles/claude && grep -rh "^name:" commands --include='*.md' | sort
ls hooks agents && grep -h "^# " ~/dotfiles/CLAUDE.md CLAUDE.md
```

Pull `settings.json` (hooks, env, skillOverrides) when a candidate is about a config-level feature.

### 3. Shortlist, on titles only

Keep only videos whose title and chapter plausibly bear on how the harness is built. Deprioritize hard: tours of tools not in use (Codex, iOS, Slack workspace setup), beginner/install content, and feature announcements for features already wired in `settings.json` or an existing skill. If more than ~12 survive, rank and cut, and say what was cut.

### 4. Checkpoint: show the shortlist, ask what is relevant

Stop here and print a numbered table (class, chapter, title, date, why it might matter, whether the harness already covers it). Ask which numbers to mine, offer "all" and "none", and mine nothing until the answer comes back. Transcripts are the expensive step and Derek knows his own gaps faster than a scorer does.

### 5. Mine the chosen transcripts

Batch into at most 4 concurrent `general-purpose` agents (`model: sonnet`), 2 to 4 videos each. Each miner:

- ToolSearch for `get_video`, then fetch each assigned `classSlug` + `videoTitle`
- extracts only techniques that would change a file in `~/dotfiles/claude` or a `CLAUDE.md`; skips demo narration, product tours, and anything already listed in the inventory it was handed
- returns per technique: one line on the technique, the mechanism it would use (hook / skill / agent / setting / prompt rule), and an anchor quote under 25 words
- writes no files and dumps no transcripts

Merge duplicates across videos before gating; the course teaches the same technique in several classes.

### 6. Gate every candidate

This is the actual work. Run the master question from "Harness Engineering Conventions" in `~/dotfiles/CLAUDE.md`: is it (a) an environment fact the model cannot infer, (b) an authority boundary, or (c) an encoding of how a human thinks the task should be done?

Course content is (c) by construction: an instructor demonstrating their method, filmed because it is teachable. REJECT is therefore the default verdict, and a (c) candidate only survives with a named model weakness or cost fact, a date, and a re-test trigger, written into the change itself.

One verdict per candidate:

1. **ALREADY HAVE**, naming the file that has it
2. **ADOPT**, naming the exact file to change and the one-line change
3. **ADAPT**, the idea is right but the local version differs; say how
4. **REJECT**, naming which part of the gate it failed

A run with zero ADOPTs is a good run. Report it as such; do not manufacture proposals to justify the run.

### 7. Report, then ledger

Present verdicts, then numbered options for the ADOPT/ADAPT items (implement now / defer / drop). Do not edit the harness in the same breath (Working Defaults: investigate first). Implement only what is picked, delegating nontrivial edits to `coder`.

Append one row per mined video to `ledger.md`, rejects included, since rejects are what stop the same video being re-mined next month. Then print the mined titles as a plain list so they can be marked watched in the web UI, and commit via `/git:commit`.

## Gotchas

- Skipping step 2 makes the whole run worthless. Already shipped and easy to re-propose: custom statusline, the `claude-usage` shell poller, the worktree flows, subagent tiering, `/loop`, hooks, plugins, `research:orderings`, plan archiving, `/verify` discipline.
- The course optimizes for what demos well; the harness optimizes for what survives a model upgrade. A slick multi-step recipe usually loses to a two-line rule, and a video-length technique is a warning sign, not evidence of value.
- Feature videos (artefacts, `/verify`, `/security-review`, Chrome MCP, plugins) are mostly "this exists". Check `settings.json` and the skills list before treating one as new.
- Everything in the window reading `isCompleted: false` is normal; it means videos were mined without being marked. Cross-check the ledger, not the flag.
- A tool, flag, or MCP shown in a video may not exist in this install or may have been renamed. Verify against `settings.json` / `~/.claude.json` before proposing it; do not assert it from the transcript.
- A version-specific claim in a transcript can be stale in either direction. The nested-spawn depth default went 5, then 1 in v2.1.217, then 3 in v2.1.219, so a video recorded inside that window states a live-sounding fact that was wrong two versions later. Check version claims against the docs (`claude-code-guide` agent), not the local binary: it is packed, and even a known-real env var greps zero, so a local miss proves nothing.
- `get_video` in the main session burns a lot of context per call. Keep transcripts inside miners; the only exception is a single video the user names directly.

Add whatever misfires on a run as a new gotcha here.
