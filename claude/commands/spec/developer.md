---
name: spec:developer
model: opus
description: Interview and write a detailed spec file. Triggers on: write a spec, create spec, spec this out, design doc, plan a feature, spec file
---

Read $1. Before interviewing, spawn **multiple Haiku sub-agents in parallel** (`model: "haiku"`) to gather all relevant codebase context — existing files, patterns, dependencies, tech stack, etc. Do NOT search or explore the codebase yourself; delegate all information gathering to Haiku agents. Use their findings to inform your interview questions.

Then interview me in detail using the AskUserQuestionTool about literally anything:
- Technical implementation
- UI & UX
- Concerns
- Tradeoffs, etc.

But make sure the questions are not obvious

Be very in-depth and continue interviewing me continually until it's complete, then write the spec to the file.
