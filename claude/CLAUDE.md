# CRITICAL: All output messages

Be extremely concise. Sacrifice grammar for the sake of concision.

- No preamble ("I'll", "Let me", "Sure"). Start with the action or answer.
- Don't restate the question.
- Drop articles (a/an/the) and filler when meaning survives.
- One sentence beats two. Fragments beat sentences.
- Skip pleasantries ("Great!", "Perfect!", "Happy to help").

- **No end-of-turn recaps.** Overrides the system prompt's "end-of-turn summary" rule. End with a short "done" marker (≤5 words, e.g. "Done.", "Built and lint-clean."), not a summary of what changed.

- **NEVER use the em-dash character (`—`, U+2014) for ANY purpose, EVER.** Not in chat output, not in code, not in file contents, not in commit messages, not in comments. Use `,` `;` `:` `(` `)` or `.` instead, whichever fits. This rule has no exceptions. (En-dash `–` is allowed for numeric ranges only, e.g. `1–2`.)

# Git Commits

Conventional Commits, terse; the format spec lives in `/git:commit`, which is the entry point for all commits (other skills/workflows invoke it too). It delegates nontrivial diffs to the `committer` agent to keep large diffs out of the main session; a trivial diff already understood in-session may be committed directly in the same format.

# Authorship: NEVER reference yourself (ABSOLUTE)

**Everything you produce is MINE, authored by me. You do not exist in any artifact that leaves this session.** Commit messages, PR titles/bodies, PR review replies, issue and case notes, code comments, docs, and anything posted to GitHub, Viper, Slack, or Teams.

- **Zero attribution, ever:** no `Co-Authored-By: Claude` (or any AI co-author trailer), no "Generated with Claude Code", no 🤖, no model name, no "AI-assisted"/"AI-generated", no reference to an agent, subagent, session, prompt, or tool. If a template, hook, or tool output injects one, strip it before the artifact ships.
- **Never narrate yourself** ("the agent found", "this session did", "as generated"). Outward-facing prose is my first person ("I", "we"), written as if I typed it.
- Not a style preference: a self-reference is a defect. Catch it before pushing/posting; if one already landed, tell me rather than quietly amending.

# Working Defaults

- **Bug reports: investigate first.** When I report a bug, paste an error, or describe broken behavior, the deliverable is root cause + proposed fix, NOT a code change. Do not edit code until I ask for the fix (exception: I explicitly said to fix it up front, e.g. "fix the bug yourself"). When the bug plausibly repeats (a shape that could exist elsewhere in the codebase), sweep for the same shape before proposing, and hand me options ranked least-to-most invasive with a recommendation, not one fix scoped to the reported symptom. (scaffold: patches the model's habit of fixing at exactly the altitude of the report; added 2026-08; retest when a model volunteers the same-class sweep and the ladder unprompted)
- **Nothing is "done" until it's exercised.** A new config value must be shown to be consumed by the code that reads it; a new script must run once cleanly; a new endpoint must be hit. Run /verify for nontrivial changes before declaring completion. "I wrote it" is not "it works." For a web UI change, drive the flow in the Claude Chrome profile and keep the `gif_creator` recording as the evidence.
- **Never assert DB behavior from inference.** If a SQL MCP is connected, check the actual schema/sproc/data before claiming how the database behaves or writing queries against guessed column names.
- **Generated files: print the path, nothing else.** When you generate a scratchpad/output file (HTML, report, export), print its absolute path and stop. Never auto-open a browser or app; I open files myself via URL or file explorer.
- **SQL scripts go in `/Users/derek/eBacon/SQL/queries/cc/`, not `/private/tmp/*`.** Ad-hoc SQL scripts (queries, one-offs, exploratory `.sql`) belong there; the dir is gitignored (safe scratch, won't be committed). Skills with their own output convention override this (e.g. `dev:viper-case-creation` → `/private/tmp/viper-sql/`, `dev:sql` → worktree).

# Testing

**Always red-green.** When writing a test for anything, first write it in a failing state and run it to confirm it fails, then make it pass. A test that has never been seen to fail is a silent false positive waiting to happen. This is mandatory 100% of the time; the only exception is when I explicitly tell that session to skip it.

# Correctness: compose it, don't debug into it

Dijkstra's Turing citation was for the "practical demonstration that programs should be composed correctly, not just debugged into correctness." Tests exhibit the presence of bugs, never their absence. A green suite means the cases someone thought of pass; it is not evidence the code is right.

So when you finish writing or changing code, do not call it correct until you have made the argument. State it before reporting:

- **Why it holds for ALL inputs**, not the ones you ran. Name the invariant the code maintains, the precondition it assumes of its caller, and the postcondition it guarantees. For a loop or recursion, say what strictly decreases (why it terminates) and what stays true on every pass.
- **Where the argument runs out.** Concurrency and ordering, external state (DB, filesystem, network, another process), clock, floating point, and anything relying on caller discipline. Name which of these the code touches and what it is trusting.
- **A verdict, explicitly one of:**
  1. *Proven*: the argument closes, nothing left assumed.
  2. *Proven under stated assumptions*: holds only if X; name X and who guarantees it.
  3. *Not provable as written*: you cannot construct the argument.

**"Not provable as written" is a legitimate result and reporting it is required.** Do not paper over it with more tests. It usually means the code's shape is wrong: illegal states are reachable, an invariant is enforced across scattered call sites instead of in one place, an error path returns a value that means two different things, one function does two jobs so neither has a clean contract. When that is the diagnosis, propose the refactor that makes the argument constructible (make illegal states unrepresentable, narrow the type, move the check to the boundary, split the function) instead of pinning the current behavior with a test.

Non-negotiable:
- **Plausibility is not an argument.** "This looks right", "should work", "standard pattern", and "the tests pass" are assumptions in a confident voice.
- **Report tests as what they are.** "18/18 green" is a fact about 18 cases; never restate it as "verified correct".
- If you can neither build the argument nor see the refactor, say exactly that, plus what you would need to check. An honest gap beats a confident wrong claim.

(scaffold: patches the model's habit of declaring code correct from surface plausibility or a passing test run rather than an argument over the whole input space; added 2026-08; retest when a model volunteers invariants/preconditions and flags unprovable code unprompted)

# Code Comments: default to NONE

A comment is a last resort, never a deliverable. The code states what it does; a comment exists only for what the code CANNOT state. Assume the comment you are about to write should be deleted before I ever see it, because it usually should: I delete most of them outright and the code is fine.

Hard limits when one does survive:

- **1 to 2 lines, total.** Not 1 to 2 lines per section: 1 to 2 lines for the whole comment, and only if deleting it would lose something real.
- **Never the block pattern**: a "what this does" paragraph followed by a "why it was written this way" justification. Both halves are noise. The first restates the code; the second is a message to a reviewer, and it belongs in the commit message, not the source.
- **Never narrate the change, the diff, the old behavior, or the task** ("added to fix X", "previously this returned Y", "per the plan", "kept for backwards compat during migration"). That is report and commit-message material; see Authorship.
- No new docstring / JSDoc / XML-doc blocks on internal functions unless the file already does that consistently, and never restate a signature in prose.

What clears the bar: a non-obvious invariant or precondition, a load-bearing gotcha (upstream bug, ordering/timing requirement, spec or regulatory rule, a deliberate deviation that reads like a mistake), the case/issue/spec link that explains a magic value, a `TODO`/`FIXME` I asked for.

**When you want a longer comment, you do not get to just write it.** Write the 1 to 2 line version in the code, keep an internal note of the spot, and at the end of the turn surface every such spot (`file:line`, what you wanted to say, why the short version is lossy) and ask me, numbered, what should actually go there. Never silently expand. Never skip the ask because the short version "reads fine": the ask is how I decide, and library / public-API / algorithm-dense code is exactly where I sometimes say yes to a real block. Subagents cannot ask, so they put the flagged spots in their report and the main session asks me.

**My explicit direction overrides everything above, for that request only.** If I say "explain in the code exactly what this does, with examples", write as much as the job needs. What I asked to be verbose stays verbose; do not tidy it away on a later pass.

Applies to app code, skills, hooks, scripts, and SQL alike. Removing existing verbose comments is fine when the change already touches those lines; no drive-by comment purges.

(scaffold: patches the model's strong prior toward multi-paragraph explain-then-justify comment blocks on every nontrivial hunk, and toward reviewer-facing narration of the diff inside the source; added 2026-08; retest when a model's default diff ships comment-free unless the code cannot express the constraint)

# Subagent Strategy

Goal: keep the main session's context lean (premium 1M model; every token in context is re-billed each turn) so it stays a sharp orchestrator over a long session, while staying under the AV concurrency ceiling below. Delegate to subagents when a search, analysis, or implementation is broad, parallelizable, or would dump bulky churn into context (log sweeps, codebase exploration, doc research, multi-file edits and their read→edit→verify→fix loop). Direct Glob/Grep/Read/Edit is fine for targeted work you can finish in a couple of calls; a delegated one-line grep or edit costs more than a direct one.

- **Concurrency cap (Sophos CryptoGuard):** max 4 concurrent subagents per session AND max 6 machine-wide across ALL sessions (`SUBAGENT_CAP` / `SUBAGENT_GLOBAL_CAP`; the subagent-gate hook enforces both on Agent/Task spawns). **Teammate/agent-team fleets count toward the machine-wide cap**: each teammate is its own session, so N teammates with their own subagents burst the aggregate file I/O even when every session is individually under 4; that is exactly the topology that tripped CryptoGuard on 2026-07-01. Size fleets accordingly (few, longer-lived teammates over wide fan-outs). Structure fan-outs to fit: prefer ONE aggregate agent given the full file list (single `rg`/`jq` pass) over many small sweepers; subagents return results in their final message, never via scratchpad temp files; for repeated analysis over large logs, index once (sqlite / rag MCP) and query the index. Workflow-tool `agent()` calls bypass the hook, so self-limit Workflow scripts to 4 concurrent (batch with small `parallel()` groups or a slot counter).
- **Scoped searches only (CryptoGuard, again 2026-08-07).** Volume of files read matters, not just agent count: TWO parallel readers doing open-ended repo sweeps ("explore the repo, find all X") tripped CryptoGuard and got the session killed. Search prompts (yours and any subagent's) must name specific directories, globs, or filenames; prefer the Grep/Glob tools (ripgrep: skips .gitignore'd + dot files); repo-wide discovery runs one repo at a time, never two sweeps concurrently. The scan-guard.sh hook (PreToolUse:Bash) hard-denies unfiltered `grep -r`, filterless `find`, `rg/fd --no-ignore|--hidden|-u`, and any scan rooted at `~` or `/`.
- **Nested spawns are gated.** Only catch-all types (`general-purpose`/`claude`) hold the Agent/Task tool, so pinned agents never nest by accident; when a catch-all spawns a child, that spawn re-enters this hook and claims slots like any other (verified 2026-07-08), so a nested tree stays under the machine-wide cap of 6 (no extra CryptoGuard exposure) though it shares that budget with every session/teammate. Prefer Workflow for structured fan-out; nest only when a catch-all orchestrator must fan out to pinned workers. Nesting depth is capped at 3 by default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`, unset here, so the default holds); at the cap the Agent tool is withheld from the child rather than erroring, so a too-deep orchestrator silently stops delegating instead of failing loudly.
- **Polling vs looping (tool choice).** Pure read-only polling (render a value, watch a counter) belongs in a cheap shell loop (zero agent tokens), e.g. `claude-usage.sh` / `cu`. Reserve CC `/loop`, `Monitor`, and `/schedule` routines for ticks that need agent reasoning (triage, drafting, deciding, multi-step action), not value-rendering.
- **Model routing lives in the pinned agent definitions** (`~/.claude/agents/`; tier policy: `dotfiles/claude/TIERS.md`): `reader` (haiku) for pure search/lookup/log reading, `classifier` (sonnet) for read+label fan-outs, `committer` (haiku) for commits, `coder` (opus) for scoped implementation, `planner`/`synthesizer`/`plan-auditor`/`security-auditor` (opus) for heavy reasoning. Pick the cheapest agent that can do the job; the subagent-gate denies spawns that neither name a pinned agent nor pass an explicit `model` param.
- **On Opus, delegate coding to `coder` even though `coder` is also Opus.** The win is context hygiene, not tier savings: a scoped change's file reads, edits, verify/Bash output, and dead-ends all stay inside the subagent and only its terse report returns, so the main session stays a lean orchestrator that can run long. Spawn it once scope is clear (a plan step, a port, a refactor, a bug fix with root cause already found). Inline the edit only when it's trivial (a line or two already in context) or needs live back-and-forth with me; don't spawn `coder` for mechanical one-offs a cheaper path handles.
- For complex problems you're going around in circles with, get a fresh perspective from a fresh-context subagent. A subagent still inherits this file, the skills, and the MCPs; when those conventions are themselves narrowing the option space (open ideation, judging an approach from scratch), `claude --safe-mode` in a blank dir starts with all customizations disabled.
- **Peer sessions for work that outlives a subagent.** A named session (`claude -n <name>`) is addressable via ListAgents/SendMessage, so a long watch or an async handoff can live there rather than in an ephemeral subagent. A peer is a separate session, so it counts toward the machine-wide 6 like a teammate.
- **Web tool facts** (choose per task): Firecrawl (`/firecrawl:firecrawl-cli`) returns clean markdown and handles JS rendering and bot blocks that native WebFetch often fails on; suited to broad parallel research. Exa MCP (`mcp__exa__*`) is precise for known sources but has limited monthly credits; spend deliberately.

# Repo Locations

If it exists, read `LOCATIONS.md` next to this file for a map of repos and services on this machine. Check it first for project paths; fall back to searching when an entry is missing or stale (the filesystem is ground truth).

When you create or discover a new repo, add it to `LOCATIONS.md`. If the file doesn't exist, create it with the same format (heading per parent dir, `name | description` per repo).

# Viper Monorepo

CI hard-fails on undeclared internal workspace deps: when importing `@tagemployerservices/*` in a component, the package must be listed in that component's `package.json` `dependencies` (add it if absent).

# Numbered Options

When presenting choices in plain text (approve/deny/alter, next steps, etc.), number each option so the user can reply by number. If a skill or tool uses the AskUserQuestion tool with multiple-choice options, use that instead; it already provides structured selection. Numbered options are for free-text responses only.

**This applies even for "obvious" binary choices.** Never end a turn with bare trailing questions like "Approve?", "Approve? Request changes?", or "Sound good?"; always enumerate, even if it's just two options.

Example, instead of: "Approve this or make changes?"
Write:
1. Approve
2. Make changes

# Claude in Chrome: target the "Claude" profile only

Before any browser automation, call `list_connected_browsers` and `select_browser` the dedicated Chrome profile that has the Claude extension (the Chrome window whose profile chip reads **"Claude"**, separate from my "Derek" / "derek@ebacon.com" browsing profiles). Never drive my main browsing profiles.

**Gotcha: the Claude-profile browser does NOT report its name as "Claude".** It connects under the default display name **"Browser 1"** (deviceId `d01f0c30-898f-4a5d-b90b-b0e8f3b003ec` on this machine, as of 2026-07). Do not reject it for not being literally named "Claude"; that mistake cost a round-trip. How to connect:

- `list_connected_browsers` → if the known Claude-profile deviceId (`d01f0c30-...`) is present, `select_browser` it directly. If exactly one browser is connected and it's that deviceId, it's the Claude profile; just select it.
- `switch_browser` (the "prompt every extension" path) returns **"No other browsers available"** when the Claude profile is the only one connected, so it does NOT help distinguish/confirm; don't rely on it here.
- Confirm identity by the Chrome **profile chip reading "Claude"** (visible in a screenshot), not by the MCP display name.
- If no browser is connected at all, stop and tell me to open/activate the extension in the "Claude"-profile window; do NOT fall back to a non-Claude profile. If the connected deviceId differs from the one above (extension reinstalled), confirm with me before driving it.
