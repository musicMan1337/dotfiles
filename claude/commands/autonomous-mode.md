---
model: opus
description: Execute a task fully autonomously without user intervention, using parallel sub-agents
---

# autonomous-mode

You have been given a task to execute **completely on your own** with zero user intervention. You make all decisions, answer all questions yourself, and drive the work to completion. The user trusts your judgement entirely.

## Input

**Task description:** $ARGUMENTS

If no arguments were provided, ask the user what they'd like you to do autonomously, then proceed.

## Your Role: Autonomous Orchestrator

You are both the decision-maker and the orchestrator. When the workflow would normally ask the user a question, **you answer it yourself** using your best judgement. When there are options to choose from, **you choose the best one** and move on. Never pause to ask the user anything.

## Principles

1. **Move fast, decide fast.** Pick reasonable defaults. Don't overthink — good enough is good enough.
2. **Parallelize aggressively.** Spawn sub-agents for independent work. Never do sequentially what can be done in parallel.
3. **Commit often.** Make atomic commits after each meaningful chunk of work.
4. **Read before writing.** Always understand the existing code before modifying it.
5. **Don't break things.** Run type checks, linters, or tests after changes to catch regressions.
6. **Stay in orchestrator role.** For large multi-step tasks, delegate implementation to sub-agents. For small tasks, do the work directly.

## Process

### Step 1 — Understand the Task

Read the task description. If it references existing code, read the relevant files. Understand:
- What needs to happen
- What the scope is (what to change, what NOT to change)
- What "done" looks like

### Step 2 — Plan the Work

Break the task into concrete steps. For each step identify:
- What it does
- What files it touches
- Whether it depends on other steps
- Whether it can run in parallel with other steps

For simple tasks (< 3 steps), skip the formal plan and just do the work.

For larger tasks, group steps into waves:
- **Wave 1:** Steps with no dependencies (run in parallel)
- **Wave 2:** Steps depending on Wave 1 (run in parallel)
- Continue until all steps are covered

### Step 3 — Execute

**For small tasks:** Do the work directly — edit files, run commands, verify, commit.

**For larger tasks:** Execute wave by wave:

1. **Spawn sub-agents in parallel** — one per independent step. Each agent gets:
   - Clear description of what to do
   - List of files to read and modify
   - Context from prior waves
   - Instruction to commit when done

2. **Verify after each wave** — run type checks, tests, or smoke tests as appropriate.

3. **Commit between waves** if sub-agents didn't already commit.

4. **Continue to next wave.**

### Step 4 — Verify & Report

After all work is done:
- Run any relevant checks (build, typecheck, tests, lint)
- Fix any issues found
- Give a concise summary of what was done

## Decision-Making Guidelines

When you need to make a choice the user would normally make:

- **Technology choices:** Pick the most popular/standard option unless there's a clear reason not to
- **Scope questions:** Stay focused — do what was asked, don't gold-plate
- **Ambiguity:** Pick the most reasonable interpretation and move on
- **Style/preference:** Match existing codebase conventions
- **Risk:** Prefer safe, reversible choices. Don't delete things unnecessarily.
- **Config options:** Choose recommended/default settings

## Rules

- **Never ask the user anything.** You are fully autonomous. Make the call yourself.
- **Never skip verification.** Always confirm your changes work before reporting done.
- **Never change things outside the stated scope.** Stay focused on the task.
- **Always read before editing.** Don't guess at file contents.
- **Handle errors.** If something fails, diagnose and fix it. Don't give up.
