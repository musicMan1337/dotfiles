---
name: ffmpeg:compress
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(du:*), Bash(file:*)
description: Compress or optimize media file size. Triggers on: compress video, reduce file size, optimize video, shrink video, make smaller, too large, file too big, need it under, slim this down, lower the quality
---

## Activation

Use this skill when the user wants to reduce a media file's size. This includes:
- Explicit compression requests ("compress this video", "make it smaller")
- Size constraints ("need it under 25MB for Discord", "email attachment limit")
- Quality/size tradeoffs ("lower the quality to save space")
- Bitrate reduction ("too high bitrate", "way too large")

Do NOT use for: format conversion (use `ffmpeg:convert`), resizing resolution specifically (use `ffmpeg:resize`).

## Your task

Compress or optimize the user's media file to reduce file size using `ffmpeg`.

## Guidelines

- **Always probe first**: Run `ffprobe -v quiet -print_format json -show_format -show_streams <input>` and `du -h <input>` to report the original file size, resolution, bitrate, and codec.
- **Strategy selection** based on the source:
  - **Already H.264/H.265**: Increase CRF or reduce resolution
  - **Uncompressed/ProRes/DNxHR**: Encode to H.264 or H.265
  - **Audio-heavy**: Reduce audio bitrate or switch codec
- **Default compression preset** (good balance of quality/size):
  ```
  ffmpeg -i input -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k output.mp4
  ```
- **Aggressive compression** (when user wants smallest possible):
  ```
  ffmpeg -i input -c:v libx265 -crf 28 -preset slow -c:a aac -b:a 96k output.mp4
  ```
- **Quick compression** (when speed matters):
  ```
  ffmpeg -i input -c:v libx264 -crf 23 -preset fast -c:a copy output.mp4
  ```
- **Resolution reduction**: If the source is 4K and the user wants it smaller, suggest scaling:
  - 4K → 1080p: `-vf scale=1920:-2`
  - 1080p → 720p: `-vf scale=1280:-2`
- **Two-pass encoding**: For target file size, calculate bitrate:
  `target_bitrate = (target_size_MB * 8192) / duration_seconds - audio_bitrate`
  Then run two-pass with `-b:v <bitrate>k`.
- **Output naming**: Default to `<input_name>_compressed.<ext>`.
- After compression, report: original size, new size, compression ratio, and any quality notes.

## Gotchas

- **CRF is not linear**: CRF 28 is not "slightly worse" than CRF 23 — it's a significant quality drop. Move in increments of 2-3 and warn the user.
- **H.265 compatibility**: Not all players/browsers support HEVC. If the file needs to be shared broadly, stick with H.264 unless asked.
- **Audio can dominate small files**: On a 30-second clip, 128kbps audio is a huge percentage. Reduce audio bitrate too for aggressive compression.
- **Preset vs CRF confusion**: `-preset slow` doesn't mean worse quality — it means slower encoding for better compression at the *same* CRF. Explain this if the user asks about presets.
- **Re-compressing already compressed video**: Encoding an already-compressed H.264 file to H.264 at the same CRF will make it *larger* and *worse*. Always check what codec the source already uses.
