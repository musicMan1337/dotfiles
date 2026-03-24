---
name: ffmpeg:trim
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(file:*)
description: Trim, cut, or clip sections of media files. Triggers on: trim video, cut video, clip, extract segment, split video, chop, first 30 seconds, last minute, remove the intro, skip to, just the part where
---

## Activation

Use this skill when the user wants to keep or remove a time-based portion of a media file. This includes:
- Keeping a segment ("just the first 30 seconds", "from 1:00 to 2:30")
- Removing a segment ("cut out the intro", "remove the last 10 seconds")
- Splitting into pieces ("split into 3 parts")
- Extracting a moment ("the part where they show the dashboard")

Do NOT use for: extracting audio/video streams (use `ffmpeg:extract`), or frame-by-frame image extraction (use `ffmpeg:extract`).

## Your task

Trim or cut the user's media file to the specified time range using `ffmpeg`.

## Guidelines

- **Always probe first**: Run `ffprobe -v quiet -print_format json -show_format -show_streams <input>` to get the total duration.
- **Time format**: Accept flexible time formats — `HH:MM:SS`, `MM:SS`, `SS`, or seconds with decimals (e.g., `90.5`). Normalize to `HH:MM:SS.mmm` for ffmpeg.
- **Fast trim (stream copy)** — use when no re-encoding is needed:
  ```
  ffmpeg -ss <start> -to <end> -i input -c copy output
  ```
  Note: `-ss` before `-i` seeks to nearest keyframe (fast but may be a few frames off). For frame-accurate cuts, put `-ss` after `-i` (slower).
- **Frame-accurate trim** — use when precision matters:
  ```
  ffmpeg -i input -ss <start> -to <end> -c:v libx264 -crf 18 -c:a aac output
  ```
- **Using duration instead of end time**: If the user says "30 seconds starting at 1:00", use `-ss 00:01:00 -t 30`.
- **Multiple segments**: If the user wants several clips from one file, run multiple ffmpeg commands and offer to concatenate them afterward.
- **Remove a section** (keep everything except a range): Extract the parts before and after, then concatenate.
- **Output naming**: Default to `<input_name>_trimmed.<ext>`.
- After trimming, report: original duration, new duration, and file size.

## Gotchas

- **`-ss` position matters**: `-ss` *before* `-i` is fast but keyframe-aligned (may start a few frames early). `-ss` *after* `-i` is frame-accurate but slow on large files. Default to before for most cases, after when precision is critical.
- **Stream copy can produce glitchy starts**: When using `-c copy`, the first few frames may be corrupted because the cut didn't land on a keyframe. If the user reports glitches at the start, re-encode instead.
- **`-to` vs `-t`**: `-to` is an absolute timestamp, `-t` is a duration. Mixing these up is the #1 trim mistake. Double-check which the user means.
- **Audio desync on long stream-copy trims**: For files with variable bitrate audio, stream copy can drift. If audio goes out of sync, re-encode the audio (`-c:a aac`) while keeping `-c:v copy`.
