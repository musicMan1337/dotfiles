---
name: notebooklm:research
description: Deep research workflow — create a notebook, gather web/Drive sources, generate reports and mind maps. Triggers on: research this, notebooklm research, deep dive into, summarize topic, research notebook
---

# NotebookLM — Research Mode

Read `notebooklm/SKILL_BASE.txt` and internalize the shared reference before proceeding. This mode creates research notebooks with auto-discovered sources and generates structured output (reports, mind maps, data tables).

## Workflow

### Phase 1 — Auth & Setup

1. Verify auth: `notebooklm status`
2. Create notebook:
   ```bash
   source ~/notebooklm-py/.venv/bin/activate && notebooklm create "Research: {topic}" --json
   ```

### Phase 2 — Gather Sources

**Two source strategies** (can combine):

**A. User-provided sources** — Add directly:
```bash
notebooklm source add "{url_or_file}" --notebook {id} --json
```

**B. Web research** — Auto-discover sources:
```bash
# Fast mode (5-10 sources, seconds)
notebooklm source add-research "{query}" --notebook {id} --mode fast

# Deep mode (20+ sources, 2-5 minutes)
notebooklm source add-research "{query}" --notebook {id} --mode deep --no-wait
```

For deep mode, spawn a background agent to wait:
```bash
notebooklm research wait -n {id} --import-all --timeout 300
```

**Default to deep mode** unless the user asks for something quick.

Wait for all sources to reach `ready` status before proceeding.

### Phase 3 — Generate Outputs

Ask the user which outputs they want, or suggest a default set based on the topic:

**Quick research (default):**
1. Mind map (instant): `notebooklm generate mind-map --notebook {id} --json`
2. Briefing doc: `notebooklm generate report --format briefing-doc --notebook {id} --json`

**Deep research:**
1. Mind map (instant)
2. Study guide: `notebooklm generate report --format study-guide --notebook {id} --json`
3. Data table (if structured data is relevant): `notebooklm generate data-table "Extract key findings, dates, and metrics" --notebook {id} --json`

**Academic research:**
1. Mind map
2. Briefing doc
3. Blog post: `notebooklm generate report --format blog-post --notebook {id} --json`

Use `--append "extra instructions"` on reports to tailor output (e.g., `--append "Target audience: software engineers"`).

### Phase 4 — Download Results

Mind maps download instantly:
```bash
notebooklm download mind-map ./research-{slug}-mindmap.json -n {id}
```

For async artifacts, spawn background agents to wait and download.

Reports:
```bash
notebooklm download report ./research-{slug}-report.md -n {id}
```

Data tables:
```bash
notebooklm download data-table ./research-{slug}-data.csv -n {id}
```

### Phase 5 — Interactive Q&A (Optional)

After sources are loaded, offer to answer questions:
```bash
notebooklm ask "What are the key takeaways?" --notebook {id} --json
```

Use `--json` to get citations back. Follow up with the user for deeper exploration.

## Arguments

Parse from user input:
- **Topic/query**: The research subject
- **Sources**: Optional URLs, files, or YouTube links to include alongside auto-research
- **Depth**: quick or deep (default: deep)
- **Output types**: mind-map, briefing-doc, study-guide, blog-post, data-table (default: mind-map + briefing-doc)
- **Output directory**: where to save files (default: current directory)

## Hard Constraints

- **Deep research can take 15-30 minutes.** Always use `--no-wait` and a background agent for deep mode.
- **Don't generate reports before sources are ready.** Mind maps are an exception (sync/instant).
- **Always download mind maps immediately** — they're instant and provide structure for the user while waiting for reports.

## Gotchas

- Web research quality varies by topic. Niche technical topics may get sparse results with fast mode — prefer deep.
- `--from drive` searches Google Drive instead of the web. Useful if the user has existing documents.
- Mind map JSON can be visualized with tools like Markmap or D3.js. Mention this to the user.
- Reports use `--format custom` if none of the built-in formats fit. Pair with `--append` for full control.
- Data tables need a descriptive prompt to know what to extract. Don't use a bare `generate data-table`.
