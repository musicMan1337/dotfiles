---
model: haiku
allowed-tools: Bash(which *), Bash(pandoc *), Bash(magick *), Bash(sips *), Bash(cwebp *), Bash(dwebp *), Bash(rsvg-convert *), Bash(ffmpeg *), Bash(lame *), Bash(sox *), Bash(yq *), Bash(jq *), Bash(mlr *), Bash(dasel *), Bash(in2csv *), Bash(csvjson *), Bash(csvformat *), Bash(ssconvert *), Bash(xlsx2csv *), Bash(sass *), Bash(esbuild *), Bash(tsc *), Bash(tar *), Bash(gzip *), Bash(gunzip *), Bash(bzip2 *), Bash(bunzip2 *), Bash(xz *), Bash(zip *), Bash(unzip *), Bash(7z *), Bash(unrar *), Bash(woff2_compress *), Bash(woff2_decompress *), Bash(sfnt2woff *), Bash(pyftsubset *), Bash(ebook-convert *), Bash(assimp *), Bash(pdftoppm *), Bash(pdftotext *), Bash(pdfunite *), Bash(pdfseparate *), Bash(pdfimages *), Bash(gs *), Bash(qpdf *), Bash(img2pdf *), Bash(wkhtmltopdf *), Bash(weasyprint *), Bash(dot *), Bash(neato *), Bash(mmdc *), Bash(plantuml *), Bash(sqlite3 *), Bash(sqlite-utils *), Bash(ls *), Bash(file *), Bash(brew install *), Bash(pip install *), Bash(npm install *), Bash(realpath *), Bash(basename *), Bash(dirname *), Bash(mkdir *)
description: Convert a file to another format via best CLI tool. Triggers on: convert file, change format, transcode
---

## Your task

Convert a file based on the user's request: **$ARGUMENTS**

Parse the arguments to determine the **input file** and **target format**. The user may provide:
- Explicit: `/convert-file report.md docx`
- Natural language: `/convert-file convert my-doc.md to a Word document`
- Just a file with context: `/convert-file screenshot.heic` (infer target from context, or ask)

If the target format is ambiguous, ask the user.

## Step 1: Verify the input file exists

Check that the input file exists. Use `ls` or `file` to confirm.

## Step 2: Look up the conversion in the table below

Find the source format → target format pair and identify the **best tool** and **command template**.

## Step 3: Check if the tool is installed

Run `which TOOL_NAME` to verify. If not installed, tell the user the install command and ask if they want you to run it.

## Step 4: Run the conversion

Execute the conversion command. Place the output file in the **same directory** as the input file, preserving the base filename with the new extension, unless the user specified an output path.

## Step 5: Confirm

Report: the output file path, file size, and any relevant details (e.g., quality settings used).

---

# CONVERSION LOOKUP TABLE

## Documents

All document conversions use **pandoc** (`brew install pandoc`).
PDF output also requires a LaTeX engine (`brew install basictex`).

| Source | Target | Command |
|--------|--------|---------|
| md | docx | `pandoc INPUT -s -o OUTPUT` |
| md | pdf | `pandoc INPUT -s --pdf-engine=xelatex -o OUTPUT` |
| md | html | `pandoc INPUT -s -o OUTPUT` |
| md | epub | `pandoc INPUT -s -o OUTPUT` |
| md | latex | `pandoc INPUT -s -o OUTPUT` |
| md | odt | `pandoc INPUT -s -o OUTPUT` |
| md | rtf | `pandoc INPUT -s -o OUTPUT` |
| md | pptx | `pandoc INPUT -s -o OUTPUT` |
| md | rst | `pandoc INPUT -s -o OUTPUT` |
| md | txt | `pandoc INPUT -t plain -o OUTPUT` |
| docx | md | `pandoc INPUT -o OUTPUT` |
| docx | pdf | `pandoc INPUT --pdf-engine=xelatex -o OUTPUT` |
| docx | html | `pandoc INPUT -s -o OUTPUT` |
| docx | epub | `pandoc INPUT -s -o OUTPUT` |
| docx | odt | `pandoc INPUT -o OUTPUT` |
| docx | rst | `pandoc INPUT -o OUTPUT` |
| html | md | `pandoc INPUT -o OUTPUT` |
| html | docx | `pandoc INPUT -o OUTPUT` |
| html | pdf | `pandoc INPUT --pdf-engine=xelatex -o OUTPUT` |
| html | epub | `pandoc INPUT -s -o OUTPUT` |
| html | rst | `pandoc INPUT -o OUTPUT` |
| html | latex | `pandoc INPUT -o OUTPUT` |
| epub | md | `pandoc INPUT -o OUTPUT` |
| epub | html | `pandoc INPUT -s -o OUTPUT` |
| epub | docx | `pandoc INPUT -o OUTPUT` |
| epub | pdf | `pandoc INPUT --pdf-engine=xelatex -o OUTPUT` |
| latex | pdf | `pandoc INPUT --pdf-engine=xelatex -o OUTPUT` |
| latex | docx | `pandoc INPUT -o OUTPUT` |
| latex | html | `pandoc INPUT -s -o OUTPUT` |
| rst | md | `pandoc INPUT -o OUTPUT` |
| rst | html | `pandoc INPUT -s -o OUTPUT` |
| rst | docx | `pandoc INPUT -o OUTPUT` |
| odt | md | `pandoc INPUT -o OUTPUT` |
| odt | docx | `pandoc INPUT -o OUTPUT` |
| odt | pdf | `pandoc INPUT --pdf-engine=xelatex -o OUTPUT` |

**Pandoc recommended flags:**
- `-s` (standalone) for HTML/EPUB/LaTeX output to produce a complete document
- `--toc` if the user wants a table of contents
- `--pdf-engine=xelatex` for better Unicode support in PDFs
- `--wrap=none` for cleaner markdown/HTML output

---

## Images

**Primary tool: `magick`** (ImageMagick 7, `brew install imagemagick`) — handles nearly all image conversions.
**SVG source: `rsvg-convert`** (`brew install librsvg`) — superior SVG rendering.
**WebP: `cwebp`/`dwebp`** (`brew install webp`) — optimized WebP encoding/decoding.
**macOS built-in: `sips`** — no install needed, handles common formats.

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| png | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| png | webp | cwebp | `cwebp -q 80 INPUT -o OUTPUT` |
| png | avif | magick | `magick INPUT -quality 50 OUTPUT` |
| png | gif | magick | `magick INPUT OUTPUT` |
| png | tiff | magick | `magick INPUT OUTPUT` |
| png | bmp | magick | `magick INPUT OUTPUT` |
| png | ico | magick | `magick INPUT -resize 256x256 OUTPUT` |
| png | heic | magick | `magick INPUT -quality 80 OUTPUT` |
| jpg | png | magick | `magick INPUT OUTPUT` |
| jpg | webp | cwebp | `cwebp -q 80 INPUT -o OUTPUT` |
| jpg | avif | magick | `magick INPUT -quality 50 OUTPUT` |
| jpg | heic | magick | `magick INPUT -quality 80 OUTPUT` |
| jpg | tiff | magick | `magick INPUT OUTPUT` |
| webp | png | dwebp | `dwebp INPUT -o OUTPUT` |
| webp | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| heic | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| heic | png | magick | `magick INPUT OUTPUT` |
| avif | png | magick | `magick INPUT OUTPUT` |
| avif | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| gif | png | magick | `magick INPUT OUTPUT` |
| gif | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| tiff | png | magick | `magick INPUT OUTPUT` |
| tiff | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| bmp | png | magick | `magick INPUT OUTPUT` |
| bmp | jpg | magick | `magick INPUT -quality 85 OUTPUT` |
| svg | png | rsvg-convert | `rsvg-convert INPUT -o OUTPUT` |
| svg | pdf | rsvg-convert | `rsvg-convert -f pdf INPUT -o OUTPUT` |
| svg | png (hi-res) | rsvg-convert | `rsvg-convert -d 300 -p 300 INPUT -o OUTPUT` |

**Quality defaults:** JPEG: 85, WebP: 80, AVIF: 50, HEIC: 80.
**Fallback:** If the specific tool isn't installed, `magick` handles almost everything. If `magick` isn't installed, `sips` handles basic PNG/JPG/TIFF/GIF/BMP conversions (`sips -s format FORMAT INPUT --out OUTPUT`).

---

## Audio

All audio conversions use **ffmpeg** (`brew install ffmpeg`).

| Source | Target | Command |
|--------|--------|---------|
| wav | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| wav | flac | `ffmpeg -i INPUT -c:a flac -compression_level 8 OUTPUT` |
| wav | aac/m4a | `ffmpeg -i INPUT -c:a aac -b:a 192k OUTPUT` |
| wav | ogg | `ffmpeg -i INPUT -c:a libvorbis -qscale:a 6 OUTPUT` |
| wav | opus | `ffmpeg -i INPUT -c:a libopus -b:a 128k OUTPUT` |
| wav | aiff | `ffmpeg -i INPUT OUTPUT` |
| flac | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| flac | wav | `ffmpeg -i INPUT OUTPUT` |
| flac | aac/m4a | `ffmpeg -i INPUT -c:a aac -b:a 192k OUTPUT` |
| mp3 | wav | `ffmpeg -i INPUT OUTPUT` |
| mp3 | flac | `ffmpeg -i INPUT -c:a flac OUTPUT` |
| m4a | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| m4a | wav | `ffmpeg -i INPUT OUTPUT` |
| ogg | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| ogg | wav | `ffmpeg -i INPUT OUTPUT` |
| wma | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| aiff | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| aiff | wav | `ffmpeg -i INPUT OUTPUT` |
| opus | mp3 | `ffmpeg -i INPUT -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| * | wav | `ffmpeg -i INPUT -c:a pcm_s16le OUTPUT` |

**Quality reference:**
- MP3 VBR `-qscale:a`: 0 (best, ~245kbps) → 9 (worst, ~65kbps). Default: 2 (~190kbps).
- AAC: 128k (minimum good), 192k (high), 256k (very high).
- Opus: 96k (speech), 128k (music), 192k (transparent).

---

## Video

All video conversions use **ffmpeg** (`brew install ffmpeg`).

| Source | Target | Command |
|--------|--------|---------|
| * | mp4 | `ffmpeg -i INPUT -c:v libx264 -preset slow -crf 22 -c:a aac -b:a 128k -movflags +faststart OUTPUT` |
| * | mkv | `ffmpeg -i INPUT -c:v libx264 -preset slow -crf 22 -c:a copy OUTPUT` |
| * | webm | `ffmpeg -i INPUT -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k OUTPUT` |
| * | avi | `ffmpeg -i INPUT -c:v libx264 -c:a mp3 OUTPUT` |
| * | mov | `ffmpeg -i INPUT -c:v libx264 -c:a aac OUTPUT` |
| * | gif | `ffmpeg -i INPUT -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" OUTPUT` |
| mov | mp4 | `ffmpeg -i INPUT -c copy -movflags +faststart OUTPUT` (remux, instant) |
| mkv | mp4 | `ffmpeg -i INPUT -c copy -movflags +faststart OUTPUT` (remux if codecs compatible) |
| gif | mp4 | `ffmpeg -i INPUT -movflags +faststart -pix_fmt yuv420p OUTPUT` |
| * | mp3 (extract audio) | `ffmpeg -i INPUT -vn -codec:a libmp3lame -qscale:a 2 OUTPUT` |
| * | m4a (extract audio) | `ffmpeg -i INPUT -vn -c:a copy OUTPUT` |

**Notes:**
- Use `-c copy` for container changes (MOV→MP4, MKV→MP4) — instant and lossless.
- H.264 CRF: 18 (visually lossless), 22 (high quality default), 28 (smaller files).
- `-movflags +faststart` enables web streaming for MP4/M4A.

---

## Data / Structured Formats

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| yaml | json | yq | `yq -o=json '.' INPUT` |
| json | yaml | yq | `yq -p=json -P '.' INPUT` |
| yaml | xml | yq | `yq -o=xml '.' INPUT` |
| xml | yaml | yq | `yq -p=xml '.' INPUT` |
| xml | json | yq | `yq -p=xml -o=json '.' INPUT` |
| json | xml | yq | `yq -p=json -o=xml '.' INPUT` |
| csv | json | yq | `yq -p=csv -o=json '.' INPUT` |
| csv | yaml | yq | `yq -p=csv '.' INPUT` |
| tsv | json | yq | `yq -p=tsv -o=json '.' INPUT` |
| toml | json | yq | `yq -p=toml -o=json '.' INPUT` |
| toml | yaml | yq | `yq -p=toml '.' INPUT` |
| json | toml | dasel | `cat INPUT \| dasel -r json -w toml` |
| yaml | toml | dasel | `cat INPUT \| dasel -r yaml -w toml` |
| csv | tsv | mlr | `mlr --c2t cat INPUT` |
| tsv | csv | mlr | `mlr --t2c cat INPUT` |
| csv | markdown | mlr | `mlr --c2m cat INPUT` |
| json | csv | mlr | `mlr --j2c cat INPUT` |
| json | tsv | mlr | `mlr --j2t cat INPUT` |
| xlsx | csv | csvkit | `in2csv INPUT` |
| xlsx | json | csvkit | `in2csv INPUT \| csvjson` |
| csv | xlsx | ssconvert | `ssconvert INPUT OUTPUT` |
| xlsx | ods | ssconvert | `ssconvert INPUT OUTPUT` |
| ods | csv | ssconvert | `ssconvert INPUT OUTPUT` |

**Tool install commands:** yq (`brew install yq`), jq (`brew install jq`), mlr (`brew install miller`), dasel (`brew install dasel`), csvkit (`brew install csvkit`), ssconvert (`brew install gnumeric`).

**Note:** For data format conversions, redirect stdout to the output file: `COMMAND > OUTPUT`

---

## PDF Operations

| Operation | Best Tool | Command |
|-----------|-----------|---------|
| pdf → png (pages) | poppler | `pdftoppm -png -r 300 INPUT OUTPUT_PREFIX` |
| pdf → jpg (pages) | poppler | `pdftoppm -jpeg -r 300 INPUT OUTPUT_PREFIX` |
| pdf → text | poppler | `pdftotext INPUT OUTPUT` |
| pdf → text (layout) | poppler | `pdftotext -layout INPUT OUTPUT` |
| merge pdfs | qpdf | `qpdf --empty --pages FILE1 FILE2 -- OUTPUT` |
| split pdf (per page) | qpdf | `qpdf --split-pages INPUT OUTPUT-%d.pdf` |
| extract pages | qpdf | `qpdf --empty --pages INPUT FIRST-LAST -- OUTPUT` |
| compress pdf | gs | `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/ebook -sOutputFile=OUTPUT INPUT` |
| images → pdf | img2pdf | `img2pdf IMG1 IMG2 -o OUTPUT` |
| html → pdf | weasyprint | `weasyprint INPUT OUTPUT` |
| url → pdf | weasyprint | `weasyprint URL OUTPUT` |
| rotate pages | qpdf | `qpdf --rotate=DEGREES:PAGES INPUT OUTPUT` |
| decrypt pdf | qpdf | `qpdf --decrypt --password=PASS INPUT OUTPUT` |

**Tool install commands:** poppler (`brew install poppler`), qpdf (`brew install qpdf`), gs (`brew install ghostscript`), img2pdf (`brew install img2pdf`), weasyprint (`pip install weasyprint`).

**GS compression presets:** `/screen` (72dpi), `/ebook` (150dpi), `/printer` (300dpi), `/prepress` (300dpi, color-preserving).

---

## Fonts

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| ttf/otf | woff2 | woff2 | `woff2_compress INPUT` |
| woff2 | ttf/otf | woff2 | `woff2_decompress INPUT` |
| ttf/otf | woff | sfnt2woff | `sfnt2woff INPUT` |
| ttf/otf | subset woff2 | fonttools | `pyftsubset INPUT --unicodes="U+0000-00FF" --flavor=woff2 --output-file=OUTPUT` |

**Tool install commands:** woff2 (`brew install woff2`), sfnt2woff (`brew tap bramstein/webfonttools && brew install sfnt2woff`), fonttools (`pip install fonttools[woff] brotli`).

---

## Ebooks

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| epub | mobi | calibre | `ebook-convert INPUT OUTPUT` |
| epub | azw3 | calibre | `ebook-convert INPUT OUTPUT` |
| epub | pdf | pandoc | `pandoc INPUT --pdf-engine=xelatex -o OUTPUT` |
| mobi | epub | calibre | `ebook-convert INPUT OUTPUT` |
| azw3 | epub | calibre | `ebook-convert INPUT OUTPUT` |
| md | epub | pandoc | `pandoc INPUT -s -o OUTPUT` |
| docx | epub | pandoc | `pandoc INPUT -s -o OUTPUT` |

**Tool install commands:** calibre (`brew install --cask calibre`), pandoc (`brew install pandoc`).
**Note:** Calibre CLI is at `/Applications/calibre.app/Contents/MacOS/ebook-convert` on macOS.

---

## Diagrams

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| dot | svg | graphviz | `dot -Tsvg INPUT -o OUTPUT` |
| dot | png | graphviz | `dot -Tpng INPUT -o OUTPUT` |
| dot | pdf | graphviz | `dot -Tpdf INPUT -o OUTPUT` |
| mmd | svg | mermaid-cli | `mmdc -i INPUT -o OUTPUT` |
| mmd | png | mermaid-cli | `mmdc -i INPUT -o OUTPUT` |
| mmd | pdf | mermaid-cli | `mmdc -i INPUT -o OUTPUT` |
| puml | svg | plantuml | `plantuml -tsvg INPUT` |
| puml | png | plantuml | `plantuml -tpng INPUT` |

**Tool install commands:** graphviz (`brew install graphviz`), mermaid-cli (`npm install -g @mermaid-js/mermaid-cli`), plantuml (`brew install plantuml`).

---

## 3D / CAD

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| obj | stl | assimp | `assimp export INPUT OUTPUT` |
| stl | obj | assimp | `assimp export INPUT OUTPUT` |
| stl | ply | assimp | `assimp export INPUT OUTPUT` |
| * | gltf | assimp | `assimp export INPUT OUTPUT` |

**Tool install command:** `brew install assimp`

---

## Archives

| Source | Target | Command |
|--------|--------|---------|
| directory | tar.gz | `tar -czf OUTPUT INPUT` |
| directory | tar.bz2 | `tar -cjf OUTPUT INPUT` |
| directory | tar.xz | `tar -cJf OUTPUT INPUT` |
| directory | zip | `zip -r OUTPUT INPUT` |
| directory | 7z | `7z a OUTPUT INPUT` |
| tar.gz | (extract) | `tar -xf INPUT` |
| tar.bz2 | (extract) | `tar -xf INPUT` |
| tar.xz | (extract) | `tar -xf INPUT` |
| zip | (extract) | `unzip INPUT` |
| 7z | (extract) | `7z x INPUT` |
| rar | (extract) | `unrar x INPUT` |
| gz | (decompress) | `gunzip -k INPUT` |
| bz2 | (decompress) | `bunzip2 -k INPUT` |
| xz | (decompress) | `xz -dk INPUT` |

**Pre-installed on macOS:** tar, gzip, bzip2, zip, unzip, xz.
**Needs install:** 7z (`brew install 7zip`), unrar (`brew install unrar`).

---

## Code / Markup

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| scss | css | sass | `sass INPUT OUTPUT` |
| sass | css | sass | `sass INPUT OUTPUT` |
| scss | css (minified) | sass | `sass --style=compressed --no-source-map INPUT OUTPUT` |
| ts | js | esbuild | `esbuild INPUT --outfile=OUTPUT` |
| tsx | js | esbuild | `esbuild INPUT --outfile=OUTPUT --loader:.tsx=tsx` |
| ts | js (bundle) | esbuild | `esbuild INPUT --bundle --outfile=OUTPUT` |
| js | js (minified) | esbuild | `esbuild INPUT --minify --outfile=OUTPUT` |

**Tool install commands:** sass (`brew install sass/sass/sass`), esbuild (`brew install esbuild`).

---

## Database

| Source | Target | Best Tool | Command |
|--------|--------|-----------|---------|
| sqlite | csv | sqlite3 | `sqlite3 -header -csv INPUT "SELECT * FROM TABLE;" > OUTPUT` |
| sqlite | json | sqlite3 | `sqlite3 -json INPUT "SELECT * FROM TABLE;" > OUTPUT` |
| sqlite | tsv | sqlite3 | `sqlite3 -separator $'\t' -header INPUT "SELECT * FROM TABLE;" > OUTPUT` |
| csv | sqlite | sqlite-utils | `sqlite-utils insert OUTPUT TABLE INPUT --csv` |
| json | sqlite | sqlite-utils | `sqlite-utils insert OUTPUT TABLE INPUT` |

**Pre-installed:** sqlite3. **Needs install:** sqlite-utils (`brew install sqlite-utils`).
**Note:** For SQLite exports, ask the user which table to export (list tables with `sqlite3 DB ".tables"`).
