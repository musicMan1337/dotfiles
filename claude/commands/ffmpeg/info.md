---
name: ffmpeg:info
model: haiku
allowed-tools: Bash(ffprobe:*), Bash(ffmpeg:*), Bash(ls:*), Bash(du:*), Bash(file:*), Bash(mediainfo:*)
description: Probe and analyze media files for metadata, streams, and technical details. Triggers on: media info, file info, ffprobe, what codec, video details, analyze media, what is this file, how long is, what resolution, bitrate, show me the metadata
---

## Activation

Use this skill when the user wants to know technical details about a media file without modifying it. This includes:
- General info ("what is this file?", "how long is this video?")
- Codec/format questions ("what codec is this?", "what resolution?")
- Metadata inspection ("show me the metadata", "what tags does this have?")
- Comparison ("compare these two files", "are these the same format?")
- Stream listing ("what audio tracks does this have?", "are there subtitles?")

Do NOT use for: any operation that modifies the file — use the appropriate action skill instead.

## Your task

Analyze the user's media file and present a clear summary of its technical details using `ffprobe`.

## Guidelines

- **Full probe command**:
  ```
  ffprobe -v quiet -print_format json -show_format -show_streams <input>
  ```
- **File size**: Also run `du -h <input>`.

### Present a clean summary covering:

**General:**
- File name, format/container, duration, total bitrate, file size

**Video stream** (if present):
- Codec (name + profile + level)
- Resolution (width x height)
- Display aspect ratio
- Frame rate (fps)
- Pixel format
- Bitrate
- HDR info if present (color_space, color_transfer, color_primaries)

**Audio stream(s)** (for each):
- Codec, sample rate, channels (mono/stereo/5.1/etc.), bitrate, language tag

**Subtitle stream(s)** (if present):
- Codec, language tag

**Metadata:**
- Title, artist, album, date, encoder, and any other tags present

### Multiple files
If the user provides multiple files or a glob, create a comparison table.

### Additional analysis on request
- Keyframe intervals: `ffprobe -select_streams v -show_entries frame=pict_type,pts_time -of csv <input> | grep I`
- Bitrate graph data: `ffprobe -select_streams v -show_entries frame=pkt_size,pts_time -of csv <input>`
- Chapter info: `-show_chapters`

## Gotchas

- **Duration can be misleading**: Some files report duration in the container metadata but the actual stream is shorter (or longer). If accuracy matters, decode and check: `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input`.
- **Bitrate "N/A"**: Variable bitrate files often don't report per-stream bitrate. Calculate from file size and duration instead.
- **Multiple audio streams**: Many MKV files have multiple audio tracks (different languages, commentary). Always list all of them, not just the first.
- **HDR detection**: If color_transfer is `smpte2084` or `arib-std-b67`, it's HDR (PQ or HLG). This matters if the user plans to convert — they'll need tone mapping.
