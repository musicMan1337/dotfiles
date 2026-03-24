---
name: ffmpeg:extract
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(mkdir:*), Bash(file:*)
description: Extract audio, frames, streams, or subtitles from media files. Triggers on: extract audio, rip audio, get frames, pull the audio, screenshot from video, grab a frame, separate tracks, get subtitles, strip audio, just the sound, take a screenshot at
---

## Activation

Use this skill when the user wants to pull out a specific component from a media file. This includes:
- Audio extraction ("rip the audio", "just the sound", "save as mp3")
- Frame/screenshot extraction ("grab a frame at 1:30", "take a screenshot")
- Frame sequences ("export every frame", "1 frame per second")
- Stream separation ("extract subtitle track", "get the second audio stream")
- Stripping a component ("remove audio", "video only")

Do NOT use for: trimming by time range (use `ffmpeg:trim`), or YouTube video frame extraction (use `ffmpeg:yt-reference`).

## Your task

Extract specific components (audio, video frames, streams, subtitles) from the user's media file using `ffmpeg`.

## Guidelines

- **Always probe first**: Run `ffprobe -v quiet -print_format json -show_format -show_streams <input>` to list all available streams.

### Extract audio
```
ffmpeg -i input -vn -c:a copy output.m4a       # copy audio codec as-is
ffmpeg -i input -vn -c:a libmp3lame -q:a 2 output.mp3  # convert to MP3
ffmpeg -i input -vn -c:a flac output.flac       # lossless extraction
```
- Use `-c:a copy` when the source audio codec matches the desired output format.

### Extract video (strip audio)
```
ffmpeg -i input -an -c:v copy output.mp4
```

### Extract single frame / screenshot
```
ffmpeg -ss <timestamp> -i input -frames:v 1 -q:v 2 output.jpg
ffmpeg -ss <timestamp> -i input -frames:v 1 output.png
```

### Extract frame sequence / image series
```
mkdir -p frames/
ffmpeg -i input -vf "fps=1" frames/frame_%04d.png          # 1 frame per second
ffmpeg -i input -vf "fps=10" frames/frame_%04d.png         # 10 fps
ffmpeg -i input -ss <start> -to <end> frames/frame_%04d.png  # range only
```

### Extract specific stream by index
```
ffprobe -v quiet -print_format json -show_streams input    # find stream indices
ffmpeg -i input -map 0:<stream_index> -c copy output
```

### Extract subtitles
```
ffmpeg -i input -map 0:s:0 output.srt          # first subtitle track
ffmpeg -i input -map 0:s:1 output.ass          # second subtitle track
```

- **Output naming**: Use descriptive names like `<input>_audio.mp3`, `<input>_frame_01:30.png`.
- After extraction, report what was extracted (codec, duration/dimensions, file size).

## Gotchas

- **`-c:a copy` with wrong container**: Copying Opus audio into an `.mp3` file doesn't work — you must re-encode. Check the source codec and match the output container.
- **Frame extraction is slow without `-ss` before `-i`**: Putting `-ss` after `-i` decodes every frame up to that point. Always put `-ss` before `-i` for single-frame extraction.
- **Subtitle extraction may produce empty files**: Some MKV files have bitmap subtitles (PGS/VobSub) which can't be extracted as SRT. Check the subtitle codec first — if it's `hdmv_pgs_subtitle` or `dvd_subtitle`, extract as `.sup` or `.sub` instead.
- **Frame sequences generate lots of files**: A 10-minute video at 1fps = 600 PNGs. Warn the user and suggest a time range or lower fps for long videos.
