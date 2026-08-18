---
name: harness:skill-feedback
model: opus
description: Grow a skill's gotchas from evidence, by reading the transcripts of sessions that actually ran it and extracting where it misfired. Triggers on, skill feedback, improve a skill from usage, why does this skill keep failing, mine my sessions for skill friction, what goes wrong when I run X, grow the gotchas, tune a skill from real runs, /harness:skill-feedback.
---

# harness:skill-feedback

Goal: turn observed misfires into a small number of evidence-backed gotchas on one skill. `skill-creator` says a skill's gotchas grow over time; this is the mechanism that feeds them, and the evidence is transcripts of real runs rather than a guess about what might go wrong.

Sibling of `harness:model-upgrade`: that one deletes scaffolding a new model has outgrown, this one adds scaffolding a real failure has earned. Both keep the harness honest, in opposite directions.

## Locate the runs

Target skill comes from the args. Without one, run the tracker's extraction with no filter and offer the handful with the most recent, highest usage.

```bash
node ~/.claude/commands/obsidian/skill-tracker/lib/extract-usage.js --skill <name>
```

Returns `sessions[]` with `sessionId`, `date`, `project`, and a resolved `transcript` path, newest first. Shared with `obsidian:skill-tracker`, which owns that script; the filter lists there (`BUILTIN_COMMANDS`, `NAMESPACE_ONLY`, `RENAMES`) also govern what this finds.

Source is `~/.claude/history.jsonl`, which records what was typed, so only explicit `/skill` invocations appear. A run the model triggered on its own is invisible here, and a heavily model-triggered skill will look less used than it is.

Transcripts are pruned on a rolling window (as of 2026-08, nothing on disk is older than ~45 days), so `transcript: null` is the normal state for anything older and the minable pool is roughly the last month of runs. Keep only non-null rows, say how many of the tracker's sessions survived, and stop rather than mine a skill whose history has aged out: `obsidian:standup` reports 41 sessions and resolves 0.

## Mine them

Fan out at most 4 `classifier` agents over the newest transcripts (10 to 15 sessions is usually plenty; say so if you cut). Transcript `.jsonl` files run to megabytes, so miners grep a window around the invocation rather than reading a file whole.

What counts as signal, in rough order of value:

- a correction immediately after the skill ran ("no", "actually", "I said", "don't", a restated instruction)
- the same step redone two or three times in one session
- an abandoned run, where the skill was invoked and the session went another way
- a step the model skipped every time, which usually means the instruction is unreadable where it sits

What does not: the user changing their mind, a one-off environment failure, or friction from a tool the skill only borrows.

Each miner returns, per candidate, the misfire in one line, the session id and date as evidence, and how many distinct sessions show it.

## Gate before writing

A gotcha earns its place the same way any harness rule does (master question in `~/dotfiles/CLAUDE.md`). Two extra bars here:

- **Recurrence.** One session is an anecdote. Two or more independent sessions is a pattern worth a line.
- **Placement.** If the model skipped an instruction that already exists, the fix is moving or sharpening it, not appending a gotcha that repeats it. Say which.

If the target skill is already long on gotchas, treat that as a signal about its shape: a skill needing a growing list of warnings to be used correctly usually wants restructuring instead. Propose that rather than another bullet.

## Report

Numbered proposals, each with its evidence count and the exact line to add or change. Edit the target skill only on approval, then commit via `/git:commit`.

## Gotchas

- Never read a transcript file whole. They are large, they contain full tool output, and one file can swamp a subagent's context. Grep windows only.
- Transcripts contain whatever was pasted into those sessions, including secrets, customer data, and case details. Evidence in the report is a session id and a one-line paraphrase, never a verbatim excerpt of user content.
- A skill that was recently rewritten will show misfires against the old version. Check the target's git log before treating an old session as evidence about current behavior.
- Zero proposals is a normal outcome for a skill that works. Do not turn ordinary back-and-forth into a gotcha to justify the run.
