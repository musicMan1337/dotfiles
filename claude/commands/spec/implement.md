---
name: spec:implement
model: opus
description: Implement a spec file via parallel sub-agents, committing between waves. Triggers on: implement spec, build spec, execute spec
---

# spec-implement

Read the spec file at `$1` in full. If no argument was provided, ask the user for the spec file path.

## Your Role: Lead Implementation Agent

You are the orchestrator. You do **not** write implementation code directly — you analyze the spec, plan execution waves, spawn sub-agents in parallel, and commit between waves.

## Step 0 — Gather Context via Haiku Sub-Agents

Before analyzing the spec, spawn **multiple Haiku sub-agents in parallel** to gather all codebase context you'll need (file structure, existing implementations, relevant patterns, dependencies, etc.). Do NOT search or explore the codebase yourself — delegate all information gathering to Haiku agents. Each agent should have a narrow search scope (e.g. one searches for data models, another for API routes, another for UI components). Collect their results before proceeding.

## Step 1 — Analyze the Spec

Read `$1` and extract every implementation section. For each section identify:
- A short **section ID** (e.g. `data-models`, `auth-api`, `ui-components`)
- Its **dependencies** — other section IDs that must be fully implemented first
- A concise **scope summary** (1–3 sentences describing exactly what to build)

Output a dependency table like:

| Section ID | Depends On | Scope Summary |
|------------|-----------|---------------|
| data-models | — | Define TypeScript interfaces and DB schemas |
| auth-api | data-models | JWT login/logout endpoints |
| ... | ... | ... |

## Step 2 — Plan Execution Waves

Group sections into ordered waves where **all sections in a wave can run in parallel**:
- Wave 1: sections with no dependencies
- Wave 2: sections whose dependencies are all in Wave 1
- Wave N: sections whose dependencies are all in earlier waves

List the waves before spawning anything.

## Step 3 — Execute Wave by Wave

For each wave:

### 3a. Spawn Sub-Agents in Parallel

In a **single message**, launch one Agent tool call per section in the wave. Each agent prompt must include:
- The full path to the spec file
- Its specific section ID and scope
- Brief summary of what prior waves produced (so it has context for integration)
- Instruction to implement *only* its assigned section — not other sections
- Instruction to use general-purpose agent type

### 3b. Commit After the Wave Completes

After ALL agents in the wave finish, invoke `/git:commit` before proceeding to the next wave.

### 3c. Repeat

Continue to the next wave until all sections are implemented.

## Rules

- **Maximize parallelism**: spawn every section that is ready simultaneously — never run sequentially what can run in parallel
- **Minimize agent scope**: each sub-agent works on exactly one section; narrow context = higher accuracy
- **No partial commits**: commit once per wave, after the wave is fully done, never mid-wave
- **Stay in lead role**: if you find yourself writing implementation code, stop and delegate to a sub-agent instead
- **Handle blockers**: if a sub-agent reports an error or ambiguity, resolve it before spawning dependent waves
- **Haiku for gathering**: any time you need to search files, explore code, or gather context, spawn Haiku sub-agents (`model: "haiku"`) — never do exploratory searching yourself
