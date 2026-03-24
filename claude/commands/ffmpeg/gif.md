---
name: ffmpeg:gif
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(du:*), Bash(file:*)
description: Create GIFs from video files with optimized palettes. Triggers on: make gif, video to gif, create gif, convert to gif, turn this into a gif, gif of this, animated gif, make a loop
---

## Activation

Use this skill when the user wants to create a GIF from video. This includes:
- Direct requests ("make a gif", "convert to gif")
- Clip-to-gif ("gif of the first 5 seconds", "gif this moment")
- Loop creation ("make a looping gif")
- Reaction gif style ("gif for Slack", "small animated clip")

Do NOT use for: general format conversion (use `ffmpeg:convert`), or full video compression (use `ffmpeg:compress`).

## Your task

Create an optimized GIF from the user's video file using `ffmpeg`'s two-pass palette method.

## Guidelines

- **Always probe first**: Get duration and resolution with `ffprobe`.

### High-quality GIF (two-pass palette method)

**Step 1 — Generate palette:**
```
ffmpeg -ss <start> -t <duration> -i input -vf "fps=<fps>,scale=<width>:-1:flags=lanczos,palettegen=stats_mode=diff" palette.png
```

**Step 2 — Create GIF using palette:**
```
ffmpeg -ss <start> -t <duration> -i input -i palette.png -lavfi "fps=<fps>,scale=<width>:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5" output.gif
```

**Step 3 — Clean up palette:**
```
rm palette.png
```

### Defaults
- **FPS**: 15 (good balance of smoothness and size)
- **Width**: 480px (scale down for reasonable file sizes)
- **Duration**: Full video if short (<10s), otherwise ask user for range
- **Dither**: `bayer:bayer_scale=5` (good for most content)

### Size optimization
- For smaller files: reduce fps (10), width (320), or duration
- For smoother GIFs: increase fps (20-24) at cost of file size
- Rule of thumb: 480px wide, 15fps, 5 seconds ~ 2-5MB

### Quick single-pass GIF (when quality doesn't matter)
```
ffmpeg -ss <start> -t <duration> -i input -vf "fps=10,scale=320:-1" output.gif
```

- **Output naming**: Default to `<input_name>.gif`.
- After creation, report: dimensions, duration, fps, file size.

## Gotchas

- **GIFs are huge**: A 10-second 1080p GIF can easily be 50MB+. Always scale down and limit duration. Suggest MP4/WebM if the user needs longer or higher quality.
- **256 color limit**: GIFs only support 256 colors per frame. The palette method helps but gradients will still band. Warn if the source has smooth gradients or photographic content.
- **`stats_mode=diff` vs `full`**: `diff` produces better palettes for video with motion, `full` for static-heavy content. Default to `diff`.
- **No audio**: GIFs can't contain audio. If the user expects sound, suggest MP4 with `-an` or a WebP animation instead.
- **Looping**: GIFs loop by default with ffmpeg. If the user wants a non-looping gif, add `-loop 1` (plays once) or `-loop N` (plays N+1 times).
