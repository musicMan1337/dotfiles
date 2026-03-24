---
name: ffmpeg:convert
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(file:*)
description: Convert media between formats (video, audio, image). Triggers on: convert video, convert audio, change format, transcode, remux, make it an mp4, turn this into, save as mp3, change container, re-encode
---

## Activation

Use this skill when the user wants to change a media file's format, container, or codec. This includes:
- Explicit format conversion ("convert to mp4", "make this a webm")
- Container changes without re-encoding ("remux mkv to mp4")
- Codec swaps ("re-encode with h265")
- Batch format changes ("convert all wav files to mp3")

Do NOT use for: compression (use `ffmpeg:compress`), extracting streams (use `ffmpeg:extract`), or resizing (use `ffmpeg:resize`).

## Your task

Convert the user's media file(s) to the requested format using `ffmpeg`.

## Guidelines

- **Always probe first**: Run `ffprobe -v quiet -print_format json -show_format -show_streams <input>` to understand the source before converting.
- **Codec selection**: Pick sensible defaults based on the target container:
  - `.mp4` → H.264 video (`-c:v libx264 -crf 23`) + AAC audio (`-c:a aac -b:a 128k`)
  - `.mkv` → Same codecs, MKV container
  - `.webm` → VP9 (`-c:v libvpx-vp9 -crf 30 -b:v 0`) + Opus (`-c:a libopus -b:a 128k`)
  - `.mov` → ProRes (`-c:v prores_ks -profile:v 3`) for editing, or H.264 for sharing
  - `.mp3` → `-c:a libmp3lame -q:a 2`
  - `.flac` → `-c:a flac`
  - `.wav` → `-c:a pcm_s16le`
  - `.aac` / `.m4a` → `-c:a aac -b:a 192k`
  - `.ogg` → `-c:a libvorbis -q:a 6`
  - `.png` / `.jpg` → single frame extraction or image sequence
- **Stream copy when possible**: If the user just wants a container change (e.g., MKV→MP4 with same codecs), use `-c copy` for instant remuxing.
- **Preserve metadata**: Add `-map_metadata 0` unless the user asks to strip it.
- **Output naming**: Default to `<input_name>_converted.<ext>` in the same directory unless the user specifies otherwise.
- **Batch conversion**: If the user provides a glob or directory, loop through files with a `for` loop.
- After conversion, run `ffprobe` on the output and report: format, duration, codecs, file size.

## Gotchas

- **MKV→MP4 with subtitles**: MP4 doesn't support SRT/ASS subtitle streams. Either drop them (`-sn`) or burn them in. Warn the user.
- **`-c copy` failures**: Stream copy fails silently if the codec isn't compatible with the target container (e.g., VP9 in MP4). Always check the output.
- **Audio-only from video**: If the user says "make this an mp3" for a video file, strip the video stream (`-vn`), don't just change the extension.
- **WebM encoding is slow**: VP9 is significantly slower than H.264. Set expectations or offer `-deadline realtime` for faster encoding.
- **Variable frame rate**: Some screen recordings have VFR. If the output looks choppy, apply `-vsync cfr` to force constant frame rate.
