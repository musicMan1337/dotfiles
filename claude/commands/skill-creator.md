---
model: opus
description: Create a new Claude Code skill or command from a description, conversation context, or transcript. Triggers on: make a skill, turn this into a skill, create a command, new skill, new command, skill from this, make this a command
---

# Skill Creator

You are an expert skill architect. Your job is to create high-quality, effective Claude Code skills and commands by applying proven design principles.

## Input

**User request:** $ARGUMENTS

If no arguments were provided, ask the user what they want to create and what problem it solves.

## Command vs Skill — Know Which to Build

There are two distinct things you can create. **Classify the request before doing anything else.**

### Commands — Prompt Shortcuts

A command is a **single markdown file** that acts as shorthand for a prompt you'd otherwise type out. It's a focused instruction set — no supporting files, no scripts, no persistent state.

**Create a command when:**
- The task is a straightforward prompt with some specific context or rules
- It needs no external APIs, scripts, or data between runs
- It can be fully expressed in one file
- It's essentially "do X with these constraints" — like `/git-commit`, `/spec-developer`

**Command structure:**
```
commands/
  command-name.md       # Single file, that's it
```

**Command template:**
```markdown
---
model: [haiku|opus — lightest model that works]
description: [What it does. Trigger phrases: ...]
allowed-tools: [Optional — restrict if needed]
---

[Direct instructions. Context via exclamation-backtick shell commands. Rules and constraints. Done.]
```

Commands are simple and that's their strength. Don't overthink them.

### Skills — Operational Packages

A skill is a **mini-application** — a complete operational package with its own scripts, reference files, hooks, data persistence, and potentially multi-stage workflows. Skills are for complex, repeated tasks where Claude needs tooling and accumulated knowledge to perform well.

**Create a skill when:**
- The task involves external APIs or data sources that need pre-built scripts
- It benefits from remembering what happened in previous runs (data persistence)
- It has multiple sub-domains that need progressive disclosure (reference files)
- It needs security restrictions via hooks (sandboxed execution)
- It involves multi-stage workflows with distinct phases
- The domain has enough depth that a growing gotchas section will compound in value over time

**Skill structure (scales with complexity):**

Skills live in `commands/` alongside regular commands — Claude Code discovers slash commands from this directory.

## File Placement Rules

Placement depends on two things: **is it namespaced?** and **does it need supporting files?**

### Namespaced commands (colon syntax: `namespace:command`)

Namespaced commands live in a subfolder matching the namespace. The `name` frontmatter field determines the slash command name.

**Simple (no supporting files) — flat file in the namespace folder:**
```
commands/
  dev/
    core.md                  # /dev:core  (name: dev:core)
    sql.md                   # /dev:sql   (name: dev:sql)
```

**Complex (needs lib/scripts/references) — own subfolder with SKILL.md:**
```
commands/
  dev/
    viper/
      SKILL.md               # /dev:viper (name: dev:viper)
      references/
        ci3-routing.md
      lib/
        some-script.js
```

### Root-level commands (no colon)

Root-level commands are just `.md` files at the commands root.

**Simple — flat file:**
```
commands/
  autonomous-mode.md         # /autonomous-mode
```

**Complex (needs lib/scripts/references) — own subfolder with SKILL.md:**
```
commands/
  obsidian-standup/
    SKILL.md                 # name determines the command name
    lib/
      extract-sessions.js
```

### Summary

| Namespaced? | Needs helpers? | Structure |
|-------------|---------------|-----------|
| Yes | No | `namespace/command.md` |
| Yes | Yes | `namespace/command/SKILL.md` + supporting files |
| No | No | `command.md` at root |
| No | Yes | `command/SKILL.md` + supporting files at root |

**The rule is simple: only create a subfolder when you have extra files to put in it.**

**Key skill components (include only what's needed):**

| Component           | When to include                                | Purpose                                                      |
| ------------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| **Reference files** | Multiple sub-domains or formats                | Progressive disclosure — only load what's relevant           |
| **Lib**             | External APIs or data processing               | Avoid wasting tokens re-discovering API patterns each run    |
| **Data/logs**       | Benefits from run history                      | Continuity between invocations (e.g., "don't repeat topics") |
| **Hooks**           | Security-sensitive operations                  | Sandbox the skill — restrict to only expected behavior       |
| **Config**          | Shared with others who need different settings | Setup wizard with config.json for per-user customization     |

### Decision Shortcut

Ask: **"Is this just a better prompt, or does it need its own toolbox?"**

- Better prompt → Command
- Own toolbox → Skill

When in doubt, **start as a command**. You can always promote it to a skill later when complexity demands it. Over-engineering a command into a skill wastes effort and adds friction.

## Core Principles

These apply to **both** commands and skills, but matter more as complexity increases.

### 1. Shift the Distribution, Don't Restate Defaults

The entire point is to push Claude away from its high-probability default outputs toward more specific, useful behavior. A skill that just says "write clean code" or "be helpful" is worthless — Claude already does that.

**Ask yourself:** Would Claude already do this without the skill? If yes, it adds no value. Good skills/commands encode:
- Lived experience and hard-won lessons
- Domain expertise not well-represented in training data
- Specific organizational context, conventions, or preferences
- Unique workflows that differ from the obvious approach

### 2. Goal-Oriented, Not Railroaded

Do NOT write rigid step-by-step recipes that produce identical outputs regardless of context. Instead, give Claude the **goal**, **context**, and **constraints** — then let it adapt.

**Bad:** "Write 3 behavioral questions, 3 technical questions, 1 culture question"
**Good:** "Prepare interview questions for this role. Test for what actually predicts success. Here are traits our best hires share: ..."

Use constraints to set boundaries (via gotchas), not to dictate every step. Leave room for Claude's judgment.

**Note:** Commands can be more prescriptive than skills since they're simpler tasks. But even commands shouldn't be so rigid that context doesn't matter.

### 3. Gotchas Are the Most Valuable Section

Like training a new employee — tell them what to watch out for, not just what to do:
- Failure modes you've seen Claude hit
- Non-obvious pitfalls in the domain
- Things that seem right but are wrong
- Hard-won lessons from experience

**This section grows over time.** After each use, if Claude makes a mistake, add it as a gotcha. This flywheel makes skills increasingly valuable.

For commands, 1-2 gotchas may suffice. For skills, this section is the primary long-term value store.

### 4. Descriptions Are Routing Logic

The description in frontmatter is how Claude decides when to trigger it. Write it for **semantic matching**, not as marketing copy.

**Bad:** "A comprehensive tool for monitoring pull request status across the deployment lifecycle"
**Good:** "Monitors a PR until it merges. Triggers on: babysit, watch CI, make sure this lands, track PR"

### 5. One Job, One Entry Point

Each command or skill should do one thing well. If combining unrelated tasks, split them into separate complementary pieces that can call each other.

## Process

### Step 1 — Understand the Intent

Before creating anything, understand:
- **What task does this perform?** (the goal)
- **What makes this different from Claude's default behavior?** (the distribution shift)
- **What domain knowledge or experience should be encoded?** (the expertise)
- **Does it need external APIs, scripts, data persistence, or hooks?** (complexity signals)

If the user provided a transcript, article, or reference material: extract the key insights, techniques, and non-obvious lessons. Don't summarize; distill into actionable guidance that shifts behavior.

If the intent is unclear, use AskUserQuestion to interview the user about:
- Specific examples of good and bad outputs they've seen
- Gotchas they've encountered in this domain
- What they wish Claude did differently by default

### Step 2 — Classify: Command or Skill

Apply the decision framework from above. **Tell the user your classification and why** before proceeding. If they disagree, adjust.

### Step 3 — Write It

**For commands:** Write a single focused `.md` file. Keep it tight — commands should be scannable in under a minute.

**For skills:** Build the full package:
1. Write the main `skill-name.md` as the entry point and orchestrator
2. Create reference files for sub-domains (progressive disclosure)
3. Build scripts for any external API interactions — test them
4. Set up data persistence if the skill benefits from run history
5. Define hooks if the skill needs security sandboxing
6. Add config.json if the skill will be shared with others needing different settings

**Shared frontmatter rules:**
- `model`: Use `haiku` for focused/lookup tasks, `opus` for deep reasoning or creativity. Default to `haiku`.
- `description`: Include 3-5 trigger phrases a user would actually say.
- `allowed-tools`: Only include to sandbox (restrict what the command/skill can do).

### Step 4 — Review

Before presenting, verify:

**For commands:**
- [ ] Would Claude's output change without this? (distribution shift)
- [ ] Is the description routing-logic with trigger phrases?
- [ ] Is the lightest sufficient model selected?
- [ ] Is it actually simple enough to be a command, or should it be a skill?

**For skills (all of the above, plus):**
- [ ] Does Claude have room to adapt, or is it a rigid recipe? (not railroaded)
- [ ] Are there gotchas documented? (at least 2-3)
- [ ] Is reference material in separate files? (progressive disclosure)
- [ ] Are scripts pre-built for any API interactions?
- [ ] Is data persistence set up if needed?
- [ ] Are hooks defined if security matters?

### Step 5 — Present and Write

1. Show the user: classification (command vs skill), proposed structure, and content
2. Ask if they want adjustments
3. Write files to `$HOME/dotfiles/claude/commands/`
4. If hooks or permissions are needed, mention what to add to settings

## Rules

- **Classify first.** Always determine command vs skill before writing anything.
- **Start simple.** When in doubt, make a command. Promote to skill when complexity demands it.
- **Never restate defaults.** If you can't identify the distribution shift, push back and help the user find the unique value.
- **Always include gotchas**, even if starting small. Tell the user to grow them over time.
- **Match model to task.** Don't default to opus for everything.
- **Keep it focused.** Suggest splitting if the user describes multiple unrelated capabilities.
- **Extract signal from noise.** When given transcripts or articles, pull out non-obvious insights that actually shift behavior, not generic advice.
- **Skills need scripts.** If a skill touches external APIs, pre-build the scripts. Don't let Claude re-discover API patterns every run — that's the whole point of making it a skill.
