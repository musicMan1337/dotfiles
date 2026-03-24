---
name: notebooklm:podcast
description: Create a podcast (audio overview) from URLs, documents, or topics. End-to-end workflow from sources to downloaded MP3. Triggers on: create a podcast, make a podcast, podcast about, audio overview, notebooklm podcast
---

# NotebookLM — Podcast Mode

Read `notebooklm/SKILL_BASE.txt` and internalize the shared reference before proceeding. This mode creates audio overviews (podcasts) from user-provided sources.

## Workflow

### Phase 1 — Auth & Setup

1. Verify auth: `notebooklm status`
2. Create a notebook titled based on the user's topic:
   ```bash
   source ~/notebooklm-py/.venv/bin/activate && notebooklm create "Podcast: {topic}" --json
   ```
3. Capture the notebook ID.

### Phase 2 — Add Sources

Add all user-provided sources (URLs, files, YouTube links):

```bash
source ~/notebooklm-py/.venv/bin/activate && notebooklm source add "{source}" --notebook {id} --json
```

**If user provides a topic but no sources:** Ask what sources to use. Optionally suggest using web research:
```bash
notebooklm source add-research "{topic}" --notebook {id} --mode deep --no-wait
```

Then wait for research to complete and import:
```bash
notebooklm research wait -n {id} --import-all --timeout 300
```

**Wait for all sources to be ready** before proceeding. Spawn a Haiku subagent to poll:
```bash
notebooklm source list --notebook {id} --json
```

All sources must show `status: "ready"`.

### Phase 3 — Generate Audio

Ask the user to confirm generation, then:

```bash
source ~/notebooklm-py/.venv/bin/activate && notebooklm generate audio "{instructions}" --notebook {id} --json
```

**Options to present to user:**
- `--format`: deep-dive (default), brief, critique, debate
- `--length`: short, default, long
- `--language`: override output language

Capture the `task_id` from output.

### Phase 4 — Wait & Download

Spawn a **background agent** to wait and download:

```
Agent(
  prompt="Run: source ~/notebooklm-py/.venv/bin/activate && notebooklm artifact wait {task_id} -n {notebook_id} --timeout 1200
          Then: notebooklm download audio ./podcast-{slug}.mp3 -a {task_id} -n {notebook_id}
          Report success or failure.",
  run_in_background=true
)
```

Tell the user: generation takes 10-20 minutes. They'll be notified when the download is ready.

**If user wants to wait interactively**, run in foreground instead.

## Arguments

Parse from user input:
- **Sources**: URLs, file paths, YouTube links, or a topic for research
- **Format**: deep-dive, brief, critique, debate (default: deep-dive)
- **Length**: short, default, long (default: default)
- **Language**: language code (default: account setting)
- **Output path**: where to save the MP3 (default: `./podcast-{slug}.mp3`)

## Hard Constraints

- **Never skip source readiness check.** Generation on unprocessed sources produces garbage.
- **Always use `--notebook` flag.** Never rely on `notebooklm use` context.
- **One generation at a time.** Don't kick off multiple audio generations in the same notebook simultaneously.
- **Rate limits are common for audio.** If generation fails, wait 5-10 minutes and offer to retry.

## Gotchas

- Audio generation is the most rate-limited artifact type. Expect occasional failures.
- `--format debate` produces two contrasting perspectives — good for controversial topics.
- `--format critique` is explicitly critical of the sources — useful for academic review.
- YouTube sources can be slow to process (transcription). Budget extra wait time.
- The `--length long` option can produce 30+ minute podcasts. Use intentionally.
