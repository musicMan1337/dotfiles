---
name: notebooklm:study
description: Generate study materials — quizzes, flashcards, and study guides from sources. Export in multiple formats. Triggers on: make a quiz, create flashcards, study materials, notebooklm study, quiz me, study guide, test me on
---

# NotebookLM — Study Mode

Read `notebooklm/SKILL_BASE.txt` and internalize the shared reference before proceeding. This mode generates study materials (quizzes, flashcards, study guides) from user-provided sources or existing notebooks.

## Workflow

### Phase 1 — Auth & Notebook Setup

1. Verify auth: `notebooklm status`
2. **If user references an existing notebook:**
   ```bash
   source ~/notebooklm-py/.venv/bin/activate && notebooklm list --json
   ```
   Find the matching notebook and use its ID.

3. **If creating fresh:**
   ```bash
   notebooklm create "Study: {topic}" --json
   ```
   Then add sources (see SKILL_BASE patterns). Wait for all sources to be `ready`.

### Phase 2 — Generate Study Materials

Ask the user what they want, or generate a default set:

**Default set:** quiz + flashcards + study guide

**Quiz:**
```bash
source ~/notebooklm-py/.venv/bin/activate && notebooklm generate quiz --difficulty {level} --quantity {amount} --notebook {id} --json
```
- `--difficulty`: easy, medium (default), hard
- `--quantity`: fewer, standard (default), more

**Flashcards:**
```bash
notebooklm generate flashcards --difficulty {level} --quantity {amount} --notebook {id} --json
```

**Study Guide:**
```bash
notebooklm generate report --format study-guide --notebook {id} --json
```

Optionally append focus instructions:
```bash
notebooklm generate report --format study-guide --append "Focus on {specific area}" --notebook {id} --json
```

### Phase 3 — Download & Export

Spawn background agents for async artifacts. Download in the most useful format:

**Quizzes:**
```bash
# JSON (structured, for apps):
notebooklm download quiz ./study-{slug}-quiz.json -n {id}

# Markdown (readable, for review):
notebooklm download quiz --format markdown ./study-{slug}-quiz.md -n {id}

# HTML (interactive, for browser):
notebooklm download quiz --format html ./study-{slug}-quiz.html -n {id}
```

**Flashcards:**
```bash
# JSON (for Anki import or apps):
notebooklm download flashcards ./study-{slug}-cards.json -n {id}

# Markdown (readable):
notebooklm download flashcards --format markdown ./study-{slug}-cards.md -n {id}
```

**Study Guide:**
```bash
notebooklm download report ./study-{slug}-guide.md -n {id}
```

**Default download format:** Markdown for readability. Mention JSON/HTML as options.

### Phase 4 — Interactive Review (Optional)

After materials are generated, offer to quiz the user interactively:
```bash
notebooklm ask "Ask me a challenging question about {topic}" --notebook {id}
```

Or let the user ask their own questions to test understanding.

## Arguments

Parse from user input:
- **Topic or notebook**: Existing notebook name/ID, or a topic to create a new one
- **Sources**: URLs, files, YouTube links (if creating new)
- **Difficulty**: easy, medium, hard (default: medium)
- **Quantity**: fewer, standard, more (default: standard)
- **Materials**: quiz, flashcards, study-guide, or all (default: all)
- **Format**: json, markdown, html (default: markdown)
- **Output directory**: where to save files (default: current directory)

## Hard Constraints

- **Always generate quiz and flashcards together** unless user specifically asks for only one. They complement each other.
- **Wait for sources before generating.** Study materials from unprocessed sources are useless.
- **Default to markdown downloads.** JSON is for programmatic use; HTML is for browser-based study. Markdown is the most versatile default.

## Gotchas

- Quiz and flashcard generation are rate-limited. If one fails, try the other — they use different endpoints.
- `--quantity more` can produce 30+ questions. Good for comprehensive review, but takes longer to generate.
- `--difficulty hard` generates questions that require synthesis across multiple sources. Best when you have 3+ sources.
- JSON quiz format includes correct answers and explanations — great for building custom study apps.
- Flashcard JSON can be imported into Anki with a simple script. Mention this for users studying for exams.
- Study guide `--append` is powerful: "Focus on differences between X and Y" or "Explain as if to a beginner" reshapes the entire output.
