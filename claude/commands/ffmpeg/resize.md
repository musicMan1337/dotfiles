---
name: ffmpeg:resize
model: haiku
allowed-tools: Bash(ffmpeg:*), Bash(ffprobe:*), Bash(ls:*), Bash(du:*), Bash(file:*)
description: Resize, scale, crop, rotate, or change resolution of video/images. Triggers on: resize video, scale video, change resolution, crop video, downscale, upscale, make it 1080p, rotate video, flip, remove black bars, letterbox, square crop
---

## Activation

Use this skill when the user wants to change the spatial dimensions or orientation of a video. This includes:
- Resolution changes ("make it 720p", "downscale to 1080p")
- Cropping ("crop to square", "remove black bars", "16:9 crop")
- Scaling ("half size", "double the resolution")
- Padding/letterboxing ("add black bars for 16:9")
- Rotation/flipping ("rotate 90 degrees", "mirror", "flip upside down")

Do NOT use for: compression without resolution change (use `ffmpeg:compress`), or image watermark overlays (use `ffmpeg:watermark`).

## Your task

Resize, scale, or crop the user's media file using `ffmpeg`.

## Guidelines

- **Always probe first**: Get current resolution and aspect ratio.

### Scale to specific resolution
```bash
# Scale to exact width, auto height (preserve aspect ratio)
ffmpeg -i input -vf "scale=1280:-2" -c:a copy output.mp4

# Scale to exact dimensions (may distort)
ffmpeg -i input -vf "scale=1920:1080" -c:a copy output.mp4

# Scale to fit within bounds (preserve aspect ratio, no upscale)
ffmpeg -i input -vf "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease" -c:a copy output.mp4
```

### Common presets
- **4K → 1080p**: `-vf "scale=1920:-2"`
- **1080p → 720p**: `-vf "scale=1280:-2"`
- **720p → 480p**: `-vf "scale=854:-2"`
- **Half size**: `-vf "scale=iw/2:ih/2"`
- **Double size**: `-vf "scale=iw*2:ih*2"`

### Crop
```bash
# Crop to width:height starting at x:y
ffmpeg -i input -vf "crop=1280:720:320:180" -c:a copy output.mp4

# Crop to center square
ffmpeg -i input -vf "crop='min(iw,ih)':'min(iw,ih)'" -c:a copy output.mp4

# Remove black bars (auto-detect)
ffmpeg -i input -vf "cropdetect" -f null - 2>&1 | tail -5  # detect first
ffmpeg -i input -vf "crop=<detected_values>" -c:a copy output.mp4
```

### Pad (add letterbox/pillarbox)
```bash
# Pad to 16:9 with black bars
ffmpeg -i input -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:-1:-1:color=black" -c:a copy output.mp4
```

### Rotate
```bash
ffmpeg -i input -vf "transpose=1" output.mp4   # 90 clockwise
ffmpeg -i input -vf "transpose=2" output.mp4   # 90 counter-clockwise
ffmpeg -i input -vf "hflip" output.mp4          # horizontal mirror
ffmpeg -i input -vf "vflip" output.mp4          # vertical flip
```

- Use `-2` instead of `-1` for auto-height to ensure even dimensions (required by most codecs).
- **Output naming**: Default to `<input_name>_resized.<ext>`.
- After resizing, report: original resolution → new resolution, file size change.

## Gotchas

- **Odd dimensions crash encoders**: H.264 and H.265 require even width AND height. Always use `-2` for auto-calculated dimensions, not `-1`.
- **Upscaling doesn't add detail**: Scaling 480p to 1080p just makes a blurry 1080p. Warn the user. If they need it for a specific resolution requirement, suggest padding instead.
- **Crop coordinates are easy to miscalculate**: `crop=w:h:x:y` where x:y is the top-left corner. The user usually thinks in terms of "remove 100px from each side" — translate that for them.
- **Rotation metadata vs actual rotation**: Some phone videos have rotation metadata but aren't actually rotated. Check `-display_rotation` in ffprobe. Using `transpose` on an already-metadata-rotated video will double-rotate it. Use `-metadata:s:v rotate=0` to strip metadata rotation first if needed.
- **`-c:a copy` with video filters**: Video filters always require video re-encoding. You can't use `-c:v copy` with `-vf`. But `-c:a copy` is fine — always copy audio when only changing video dimensions.
