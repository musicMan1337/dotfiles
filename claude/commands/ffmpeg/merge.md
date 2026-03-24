---
name: ffmpeg:merge
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(cat:*), Bash(printf:*), Bash(file:*), Bash(rm:*)
description: Merge, concatenate, or join multiple media files. Triggers on: merge videos, concatenate, join files, combine videos, append audio, stitch together, put these together, chain these clips, combine into one
---

## Activation

Use this skill when the user wants to combine multiple media files into one. This includes:
- Sequential joining ("concatenate these clips", "stitch these together")
- Appending ("add this audio to the end")
- Spatial compositing ("side by side", "picture in picture")
- Audio mixing into video ("overlay music onto video")

Do NOT use for: adding a watermark/logo overlay (use `ffmpeg:watermark`), or mixing audio tracks (use `ffmpeg:audio`).

## Your task

Merge or concatenate multiple media files using `ffmpeg`.

## Guidelines

- **Always probe all inputs first** to check codec compatibility.

### Method 1: Concat demuxer (same codec — fast, no re-encode)
Use when all files have identical codecs, resolution, and sample rates.

```bash
# Create file list
printf "file '%s'\n" file1.mp4 file2.mp4 file3.mp4 > filelist.txt

# Concatenate
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4

# Clean up
rm filelist.txt
```

### Method 2: Concat filter (different codecs — re-encodes)
Use when files have different codecs, resolutions, or properties.

```bash
ffmpeg -i input1.mp4 -i input2.mp4 -filter_complex \
  "[0:v][0:a][1:v][1:a]concat=n=2:v=1:a=1[outv][outa]" \
  -map "[outv]" -map "[outa]" -c:v libx264 -crf 23 -c:a aac output.mp4
```

### Method 3: Audio-only concatenation
```bash
# Same format (fast)
printf "file '%s'\n" *.mp3 > filelist.txt
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp3
rm filelist.txt

# Different formats (re-encode)
ffmpeg -i input1.wav -i input2.mp3 -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1[out]" -map "[out]" output.mp3
```

### Method 4: Side-by-side or picture-in-picture
```bash
# Side by side
ffmpeg -i left.mp4 -i right.mp4 -filter_complex "[0:v][1:v]hstack=inputs=2[v]" -map "[v]" output.mp4

# Picture in picture (small overlay in corner)
ffmpeg -i main.mp4 -i overlay.mp4 -filter_complex "[1:v]scale=320:-1[pip];[0:v][pip]overlay=W-w-10:H-h-10[v]" -map "[v]" -map "0:a" output.mp4
```

- **Ordering**: Concatenate in the order the user specifies, or alphabetical if given a glob.
- **Output naming**: Default to `merged_<timestamp>.<ext>`.
- After merging, report: number of inputs, total duration, file size.

## Gotchas

- **Concat demuxer requires identical streams**: If one file is 1080p and another is 720p, or one has audio and another doesn't, the concat demuxer will fail or produce garbage. Always probe first and use the filter method if streams differ.
- **File list paths must be absolute or relative to the list file**: The `filelist.txt` resolves paths relative to *its own location*, not the working directory. Use absolute paths to be safe.
- **Audio stream count mismatch**: If some files have audio and others don't, the concat filter will fail. Add silent audio to the missing tracks: `-f lavfi -t <duration> -i anullsrc`.
- **Timestamps can be wrong after concat demuxer**: Some containers have incorrect timestamps after concatenation, causing seeking issues. If playback is choppy, re-encode with `-c:v libx264 -c:a aac`.
- **`-safe 0` is required**: Without it, ffmpeg refuses file paths with special characters in the concat demuxer. Always include it.
