---
name: ffmpeg:watermark
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(file:*)
description: Add text overlays, image watermarks, or burn subtitles into video. Triggers on: add watermark, text overlay, burn subtitles, add text, logo overlay, add a logo, stamp, put text on, hardcode subtitles, bake in subtitles
---

## Activation

Use this skill when the user wants to overlay visual elements onto a video. This includes:
- Image overlays ("add a logo", "watermark with our brand", "put an image in the corner")
- Text overlays ("add a title", "put text on the video", "timestamp overlay")
- Subtitle burning ("hardcode subtitles", "bake subs into the video", "burn in captions")
- Timed text ("show text from 2s to 5s")

Do NOT use for: merging two full videos side-by-side or PiP (use `ffmpeg:merge`), or adding/mixing audio tracks (use `ffmpeg:audio`).

## Your task

Add text overlays, image watermarks, or burn subtitles into video using `ffmpeg`.

## Guidelines

- **Always probe first**: Get resolution to calculate overlay positions.

### Image watermark / logo
```bash
# Bottom-right corner with padding
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=W-w-10:H-h-10" output.mp4

# Top-left corner
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=10:10" output.mp4

# Center
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=(W-w)/2:(H-h)/2" output.mp4

# Semi-transparent watermark
ffmpeg -i video.mp4 -i logo.png -filter_complex "[1:v]format=rgba,colorchannelmixer=aa=0.3[logo];[0:v][logo]overlay=W-w-10:H-h-10" output.mp4
```

### Text overlay
```bash
# Simple text (requires a font file or uses default)
ffmpeg -i input -vf "drawtext=text='My Text':fontsize=36:fontcolor=white:x=10:y=10" output.mp4

# Text with background box
ffmpeg -i input -vf "drawtext=text='My Text':fontsize=36:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5:x=(w-text_w)/2:y=h-th-20" output.mp4

# Timestamp overlay
ffmpeg -i input -vf "drawtext=text='%{pts\:hms}':fontsize=24:fontcolor=white:x=10:y=10" output.mp4

# Text that appears only during a time range
ffmpeg -i input -vf "drawtext=text='Hello':fontsize=48:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:enable='between(t,2,5)'" output.mp4
```

### Burn subtitles
```bash
# From external SRT file
ffmpeg -i input -vf "subtitles=subs.srt" output.mp4

# From external ASS/SSA file (preserves styling)
ffmpeg -i input -vf "ass=subs.ass" output.mp4

# From embedded subtitle stream
ffmpeg -i input -vf "subtitles=input" output.mp4

# Custom subtitle styling
ffmpeg -i input -vf "subtitles=subs.srt:force_style='FontSize=28,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2'" output.mp4
```

- **Output naming**: Default to `<input_name>_watermarked.<ext>`.
- After processing, report what was added and the output file details.

## Gotchas

- **`drawtext` needs fontconfig or explicit font path**: On macOS, the default font may not exist. If `drawtext` fails with "Cannot find a valid font", specify a font explicitly: `fontfile=/System/Library/Fonts/Helvetica.ttc`.
- **Subtitle filter requires libass**: `subtitles=` filter needs ffmpeg built with `--enable-libass`. If it fails, check `ffmpeg -filters | grep subtitle`. The Homebrew build should have it.
- **Special characters in `drawtext`**: Colons, semicolons, and backslashes must be escaped in drawtext. Use `\\:` for a literal colon, `\\\\` for a backslash. This is the most common source of cryptic filter parse errors.
- **Overlay image must have alpha channel**: If the watermark image doesn't have transparency (e.g., JPG), it will be an opaque rectangle. Convert to PNG with alpha first, or use `colorchannelmixer=aa=0.3` to add transparency.
- **Subtitle path with spaces**: The `subtitles=` filter doesn't handle spaces in file paths well. Either rename the file, use a symlink, or escape with `\\`.
