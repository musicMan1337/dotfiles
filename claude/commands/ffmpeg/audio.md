---
name: ffmpeg:audio
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(du:*), Bash(file:*)
description: Audio processing — normalize, adjust volume, mix, add to video, fade, speed change. Triggers on: normalize audio, volume, audio processing, add music, mix audio, speed up, slow down, too quiet, too loud, fade in, fade out, change speed, playback speed, background music
---

## Activation

Use this skill when the user wants to process or modify audio. This includes:
- Volume/loudness ("too quiet", "normalize", "boost the volume", "make louder")
- Speed changes ("speed up", "slow down", "2x speed", "half speed")
- Fades ("fade in", "fade out")
- Audio mixing ("add background music", "overlay narration", "replace audio")
- Channel changes ("convert to mono", "make stereo")
- Sample rate changes ("convert to 44.1kHz")

Do NOT use for: extracting audio from video (use `ffmpeg:extract`), or converting audio formats (use `ffmpeg:convert`).

## Your task

Process audio using `ffmpeg` — normalization, volume adjustment, mixing, speed changes, and more.

## Guidelines

- **Always probe first**: Check audio codec, sample rate, channels, and loudness.

### Normalize audio (EBU R128 loudness)
```bash
# Two-pass loudness normalization
ffmpeg -i input -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=summary -f null - 2>&1 | tail -12  # analyze
ffmpeg -i input -af "loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=<val>:measured_TP=<val>:measured_LRA=<val>:measured_thresh=<val>" output
```

### Simple volume adjustment
```bash
ffmpeg -i input -af "volume=1.5" output          # 150% volume
ffmpeg -i input -af "volume=0.5" output          # 50% volume
ffmpeg -i input -af "volume=6dB" output          # +6dB
ffmpeg -i input -af "volume=-3dB" output         # -3dB
```

### Fade in/out
```bash
ffmpeg -i input -af "afade=t=in:st=0:d=3" output                    # 3s fade in
ffmpeg -i input -af "afade=t=out:st=<start>:d=3" output             # 3s fade out
ffmpeg -i input -af "afade=t=in:d=2,afade=t=out:st=<start>:d=3" output  # both
```

### Speed change (audio only)
```bash
ffmpeg -i input -af "atempo=2.0" output          # 2x speed
ffmpeg -i input -af "atempo=0.5" output          # half speed
ffmpeg -i input -af "atempo=1.5" output          # 1.5x speed
# For >2x: chain filters: atempo=2.0,atempo=2.0 = 4x
```

### Speed change (video + audio together)
```bash
ffmpeg -i input -filter_complex "[0:v]setpts=0.5*PTS[v];[0:a]atempo=2.0[a]" -map "[v]" -map "[a]" output  # 2x
ffmpeg -i input -filter_complex "[0:v]setpts=2.0*PTS[v];[0:a]atempo=0.5[a]" -map "[v]" -map "[a]" output  # 0.5x
```

### Mix/overlay audio onto video
```bash
# Replace audio entirely
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -map 0:v:0 -map 1:a:0 -shortest output.mp4

# Mix original audio with new audio
ffmpeg -i video.mp4 -i music.mp3 -filter_complex "[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[a]" -map 0:v -map "[a]" -c:v copy output.mp4

# Add background music at lower volume
ffmpeg -i video.mp4 -i music.mp3 -filter_complex "[1:a]volume=0.3[bg];[0:a][bg]amix=inputs=2:duration=first[a]" -map 0:v -map "[a]" -c:v copy output.mp4
```

### Channel manipulation
```bash
ffmpeg -i input -ac 1 output                     # stereo to mono
ffmpeg -i input -ac 2 output                     # mono to stereo
```

### Sample rate conversion
```bash
ffmpeg -i input -ar 44100 output                  # convert to 44.1kHz
ffmpeg -i input -ar 48000 output                  # convert to 48kHz
```

- **Output naming**: Default to `<input_name>_processed.<ext>`.
- After processing, report the changes made (before/after loudness, duration, etc.).

## Gotchas

- **`atempo` range is 0.5–2.0**: Values outside this range fail silently or produce garbage. For 4x speed, chain two filters: `atempo=2.0,atempo=2.0`. For 0.25x: `atempo=0.5,atempo=0.5`.
- **Loudnorm two-pass is critical**: Single-pass loudnorm guesses and often overshoots. Always analyze first, then apply with measured values. The first pass output gives you the `measured_*` values for the second pass.
- **`amix` reduces volume**: By default `amix` divides each input's volume by the number of inputs. Two inputs = half volume each. Compensate with `volume=2.0` after mixing, or use `weights` parameter.
- **Speed change on video**: `setpts` and `atempo` use inverse values — `setpts=0.5*PTS` doubles video speed (halves presentation timestamps), matching `atempo=2.0`. Getting these backwards produces desync.
- **Fade out needs the total duration**: `afade=t=out:st=<start>:d=3` — if you set `st` past the end of the file, nothing happens. Always probe duration first and calculate `st = duration - fade_duration`.
