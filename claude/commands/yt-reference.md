---
name: ffmpeg:yt-reference
model: sonnet
allowed-tools: Bash(yt-dlp:*), Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(mkdir:*), Bash(cat:*), Bash(rm:*), Bash(wc:*), Bash(head:*), Bash(python3:*), Bash(file:*), Bash(cp:*), Bash(source:*), Bash(obsidian:*), Read(*), Write(*)
description: Extract timestamped screenshots and transcripts from YouTube videos to Obsidian. Triggers on: youtube reference, grab frames, video reference
---

## Activation

Use this skill when the user wants to extract visual reference material from a YouTube video. This includes:
- Design reference ("grab reference frames from this YouTube video", "screenshot the UI from that tutorial")
- Transcript-aligned frames ("extract frames with what they're saying")
- Video-to-reference-library ("save this video as reference material")
- Agent-consumable output ("I want an agent to use these as design reference")

Do NOT use for: downloading a YouTube video to keep (that's just `yt-dlp`), extracting frames from a local video (use `ffmpeg:extract`), or creating GIFs from video (use `ffmpeg:gif`).

## Your task

Download a YouTube video, extract its transcript, and produce a folder of timestamped screenshots paired with their transcript text — saved to the Obsidian vault for persistent reference.

## Output location

All output goes to the Obsidian vault at:
```
/Users/derek/eBacon/obsidian/eBacon/references/<run-name>/
```

The `<run-name>` should be a slugified version of the video title or a user-provided name (e.g., `stripe-dashboard-redesign`).

Structure:
```
references/<run-name>/
├── images/
│   ├── frame_0001_00-00-00.png
│   ├── frame_0002_00-00-30.png
│   └── ...
├── transcript.md          <- full transcript with file path references
└── manifest.json          <- machine-readable for agent consumption
```

## Workflow

### Step 1: Set up and download (single yt-dlp pass)

Download the video AND transcript in a single yt-dlp call to avoid rate limiting. Use `srv3` format (XML) — it's the cleanest format for programmatic parsing.

```bash
TMPDIR=$(mktemp -d)
VAULT="/Users/derek/eBacon/obsidian/eBacon"
RUN_NAME="<slugified-name>"
OUT="$VAULT/references/$RUN_NAME"
mkdir -p "$OUT/images"

# Single call: video + auto-subs in srv3 format
yt-dlp -f "bestvideo[height<=720]+bestaudio/best[height<=720]" \
  --merge-output-format mp4 \
  --write-auto-sub --sub-lang en-orig,en --sub-format srv3 \
  -o "$TMPDIR/video.%(ext)s" "<URL>"
```

**Important**: Use `en-orig` first (original English), falling back to `en`. Check `--list-subs` only if this fails. Do NOT make multiple yt-dlp calls — YouTube rate-limits aggressively.

If manual subs exist, prefer them: add `--write-sub` before `--write-auto-sub`.

### Step 2: Parse srv3 transcript into paragraph groups

YouTube's transcript data (whether from auto-CC, the "Show transcript" panel, or manual subs) is always word/phrase-level cues. The "Show transcript" panel just renders these with CSS spacing — there is no separate "clean" paragraph-level transcript.

Group consecutive cues into ~30-second paragraphs to produce clean, readable text blocks with one frame per paragraph.

```python
import xml.etree.ElementTree as ET
import json, sys, glob

# Find the srv3 file
srv3_files = glob.glob(f"{sys.argv[1]}/video.*.srv3")
if not srv3_files:
    print("ERROR: No srv3 file found")
    sys.exit(1)

tree = ET.parse(srv3_files[0])
body = tree.getroot().find('body')

# Extract non-empty cues
cues = []
for elem in body:
    text = ''.join(elem.itertext()).strip()
    t = elem.get('t')
    if text and t:
        cues.append({'t_ms': int(t), 'text': text})

# Group into ~30 second paragraphs
GROUP_MS = 30000
paragraphs = []
current_texts = []
current_start = None

for cue in cues:
    if current_start is None:
        current_start = cue['t_ms']
    current_texts.append(cue['text'])
    if cue['t_ms'] - current_start >= GROUP_MS:
        sec = current_start / 1000
        paragraphs.append({
            'timestamp_sec': sec,
            'timestamp_fmt': f"{int(sec//3600):02d}:{int((sec%3600)//60):02d}:{int(sec%60):02d}",
            'text': ' '.join(current_texts)
        })
        current_texts = []
        current_start = None

if current_texts and current_start is not None:
    sec = current_start / 1000
    paragraphs.append({
        'timestamp_sec': sec,
        'timestamp_fmt': f"{int(sec//3600):02d}:{int((sec%3600)//60):02d}:{int(sec%60):02d}",
        'text': ' '.join(current_texts)
    })

with open(sys.argv[2], 'w') as f:
    json.dump(paragraphs, f, indent=2)
print(f"Found {len(paragraphs)} paragraph groups")
```

Run as: `python3 script.py "$TMPDIR" "$OUT/paragraphs.json"`

### Step 3: Extract one frame per paragraph

```bash
cat "$OUT/paragraphs.json" | OUT="$OUT" TMPDIR="$TMPDIR" python3 -c "
import json, sys, subprocess, os
out_dir = os.environ['OUT']
tmpdir = os.environ['TMPDIR']
entries = json.load(sys.stdin)
total = len(entries)
for i, e in enumerate(entries):
    ts = e['timestamp_fmt']
    fname = f'frame_{i+1:04d}_{ts.replace(\":\", \"-\")}.png'
    fpath = os.path.join(out_dir, 'images', fname)
    subprocess.run(['ffmpeg', '-ss', str(e['timestamp_sec']), '-i', os.path.join(tmpdir, 'video.mp4'),
                    '-frames:v', '1', '-q:v', '1', fpath, '-y'], capture_output=True)
    e['image'] = f'images/{fname}'
    if (i+1) % 10 == 0 or i == total-1:
        print(f'  [{i+1}/{total}] extracted')
with open(os.path.join(out_dir, 'manifest.json'), 'w') as f:
    json.dump(entries, f, indent=2)
print(f'Done. {total} frames extracted.')
"
```

### Step 4: Generate Obsidian transcript note

Create `transcript.md` — clean text, no inline image embeds. Images are browsable in Obsidian's file explorer under `images/`.

Format:

```markdown
---
source: <youtube-url>
title: <video-title>
date: <YYYY-MM-DD>
type: reference
frames: <count>
---

# <Video Title>

> Source: [YouTube](<url>)
> Extracted: <date> | Frames: <count> | ~30s per paragraph

---

## 00:00:00
> A lot of people are banking on 2026 to be the year where AI gets real work done and delivers real business value. And I'm not talking about small stuff like writing blog posts or drafting social media content...
> `images/frame_0001_00-00-00.png`

## 00:00:34
> is reliability. Andre Carpathy describes this as the march of nines where you can reach the first 90% of reliability...
> `images/frame_0002_00-00-34.png`
```

Write this file using the `Write` tool to `$OUT/transcript.md`.

### Step 5: Clean up

```bash
rm -rf "$TMPDIR"
rm -f "$OUT/paragraphs.json"  # intermediate file, manifest.json has everything
```

## Guidelines

- **Naming**: Slugify the video title (lowercase, hyphens, no special chars) or use a user-provided name.
- **Resolution**: Default to 720p. Offer 1080p if the user needs pixel-perfect detail.
- **Paragraph grouping**: Default ~30 seconds per paragraph. For denser coverage use 15s, for sparser use 60s. This directly controls the number of frames.
- **Single yt-dlp call**: ALWAYS download video + subs in one call. Multiple calls trigger YouTube rate limiting.
- **Filtering**: If the user is only interested in a portion of the video, use `yt-dlp --download-sections "*START-END"` to download only that range.
- **Large videos**: For videos over 30 minutes, warn about frame count and suggest 60s grouping or a time range filter.
- **No inline embeds**: Do NOT use `![[image]]` syntax. Images live in the `images/` subfolder and are browsable directly in Obsidian's file explorer. The transcript note references paths as inline code only.
- After completion, report: number of frames extracted, vault path, and that the transcript note is ready in Obsidian.
- **Agent handoff**: Tell the user they can point any agent at `manifest.json` for machine-readable reference, or browse `images/` in Obsidian's file explorer for visual reference.

## Gotchas

- **YouTube rate limiting**: Multiple yt-dlp calls in quick succession will get rate-limited. ALWAYS combine video + subtitle download into a single call.
- **Transcript data is always cue-level**: YouTube's "Show transcript" panel, auto-CC, and subtitle downloads all use the same word/phrase-level cue data. There is no separate "paragraph-level" transcript. The skill groups cues into paragraphs programmatically.
- **srv3 is the best format for parsing**: XML with simple `<w t="ms">text</w>` elements. Cleaner than VTT (which has duplicate cues and `<c>` tags) or json3 (deeply nested).
- **Subtitle language codes vary**: Some videos use `en-orig`, `en-US`, or `en-GB` instead of `en`. Use `en-orig,en` as a fallback chain, or check `--list-subs` if both fail.
- **yt-dlp format selection can fail**: The `bestvideo[height<=720]+bestaudio` format string may not match. Fall back to `best[height<=720]` or just `best`.
- **No transcript at all**: Some videos have no subs. Fall back to fixed-interval frame extraction (every 30s) with no transcript text.
- **Temp directory cleanup**: If the script fails partway through, the temp directory with the full video won't be cleaned up. Handle this in error paths.
