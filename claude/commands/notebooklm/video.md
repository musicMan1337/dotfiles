---
name: notebooklm:video
description: Generate video explainers from sources — whiteboard, anime, retro, and more visual styles. Triggers on: create a video, make a video, video explainer, notebooklm video, visual explainer, explain visually
---

# NotebookLM — Video Mode

Read `notebooklm/SKILL_BASE.txt` and internalize the shared reference before proceeding. This mode generates video explainers from sources with multiple visual styles.

## Workflow

### Phase 1 — Auth & Setup

1. Verify auth: `notebooklm status`
2. Create or select notebook:
   ```bash
   source ~/notebooklm-py/.venv/bin/activate && notebooklm create "Video: {topic}" --json
   ```

### Phase 2 — Add Sources

Add user-provided sources. Same patterns as SKILL_BASE. Wait for all sources to reach `ready`.

### Phase 3 — Generate Video

Present style options to the user, then confirm before generating:

```bash
source ~/notebooklm-py/.venv/bin/activate && notebooklm generate video "{instructions}" --format {format} --style {style} --notebook {id} --json
```

**Formats:**
- `explainer` (default) — longer, detailed walkthrough
- `brief` — short, condensed overview

**Styles:**
| Style | Best For |
|-------|----------|
| `auto` | Let NotebookLM choose (default) |
| `whiteboard` | Technical topics, diagrams |
| `classic` | Professional, general purpose |
| `kawaii` | Friendly, approachable tone |
| `anime` | Engaging, dynamic presentation |
| `watercolor` | Creative, artistic topics |
| `retro-print` | Vintage aesthetic |
| `heritage` | Historical topics |
| `paper-craft` | Crafts, DIY, hands-on topics |
| `sketch-note` | Note-taking style, educational |
| `scientific` | Research, data-heavy topics |
| `bento-grid` | Structured, grid-based layout |
| `editorial` | Journalism, reporting style |
| `instructional` | How-to, step-by-step |
| `bricks` | Playful, building-block style |
| `clay` | 3D clay animation style |

### Phase 4 — Wait & Download

Video generation takes **15-45 minutes**. Always use a background agent:

```
Agent(
  prompt="Run: source ~/notebooklm-py/.venv/bin/activate && notebooklm artifact wait {task_id} -n {notebook_id} --timeout 2700
          Then: notebooklm download video ./video-{slug}.mp4 -a {task_id} -n {notebook_id}
          Report success or failure.",
  run_in_background=true
)
```

## Arguments

Parse from user input:
- **Sources**: URLs, files, YouTube links, or topic for research
- **Format**: explainer, brief (default: explainer)
- **Style**: see table above (default: auto)
- **Language**: language code for narration
- **Output path**: where to save MP4 (default: `./video-{slug}.mp4`)

## Hard Constraints

- **Always confirm style choice before generating.** Video generation is expensive and slow — wrong style wastes 15-45 minutes.
- **Suggest a style based on topic.** Technical → whiteboard. Historical → heritage. Educational → instructional. Don't default to `auto` without at least suggesting.
- **One video at a time per notebook.** Don't queue multiple video generations.

## Gotchas

- Video is the **slowest** artifact type. 15-45 minutes is normal. Set timeout to 2700s.
- Video generation is rate-limited. If it fails, wait 10+ minutes before retrying.
- `--style` has a dramatic effect on output. Choosing the right style matters more than instructions.
- Brief format is 1-3 minutes; explainer can be 5-10+ minutes. Match to the user's use case.
- Videos have audio narration — language setting affects the narration language.
