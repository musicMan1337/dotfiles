# Reflection Notes: Session-Transcript Mining (2026-07-02)

Corpus: ~100 sessions, ~100MB JSONL across `-Users-derek-eBacon-Viper` (85 non-trivial), 4 Viper worktree dirs (7 sessions), `-Users-derek-eBacon-Viper-php` (4 sessions). `-Users-derek/` contained no transcripts. Extraction: 12 classifier subagents pulling user messages, corrections, repeated asks, and tool-error samples per session; clustering done centrally. Session IDs are transcript basename prefixes.

Verdict key: **SKILL** = build new skill/command. **FIX** = change an existing skill/config/doc. **AUTOMATION** = hook/script. **NOTHING** = not worth building; noted for the record.

---

## Ranked candidates (most leverage first)

### 1. `/dev:wrapup` composite closing command — SKILL
The single most repeated ritual in the corpus: a hand-typed chain of `commit push pr standup-add`, with variants adding worktree cleanup or a pithy case-note summary. Appears in **18+ sessions**: 8f312173 (2x in one session), 84a1c20a, b0be5164, 23023bc3 ("make sure all is committed, push pr, standup-add, then cleanup the worktree"), e8b91dc4, 78d8c4fc ("print a pithy sentence or two on the fix for a case note, then standup-add"), 50b9cc5c, e8d560ee, 2be7688b (interrupted mid-chain), c46c2050, 3fa5cbc9, 268922fa, c965427d, 75d6012c, 6792d189, 84e24b76, fac811e3, 45c9f07a. Failure mode already observed: typo "standdup-add" in eb78413d silently never invoked the skill.
**Build:** one skill chaining `/git:commit` → push → `/git:pr` → `/obsidian:standup-add`, with optional flags for worktree cleanup and case-note sentence. Tiny cost, fires nearly every working session.

### 2. `/dev:viper-worktree` upgrades (bundle of 4 recurring manual fixups) — FIX
All in the skill you already own:
- **Auto-carry gitignored local config into new worktrees.** "recopy the config/database.php file to the worktree" (23023bc3, a4f91000); the config.php "line 21, add the `&& false` clause" patch dictated by hand twice (e8b91dc4, 0a6252e7).
- **Print the docker URL after build.** Asked verbatim in 3+ sessions: b0be5164 ("give tme the docker url"), e8b91dc4 ("make sure the build is up to date and print out the docker url"), 23023bc3.
- **Build-completeness / staleness check before handing off.** "Uncaught SyntaxError ... infinite refreshes ... usually happens on incomplete builds": user supplied this diagnosis, not Claude, in 39503afa, c965427d, a4f91000; post-master-merge stale bundle in 0547398a. A hash/mtime check of source vs built bundle after merge/build would catch all of these.
- **Docker Desktop case-insensitivity phantom-file trap** (Documents.php vs documents.php stale-cache loop, fac811e3): add a warn/force-recreate note to the skill.
**~10 sessions of friction, cheap edits to an existing skill.**

### 3. `/obsidian:standup-add` concurrency + idempotency — FIX
Real data-loss risk, flagged repeatedly: "another session just wrote more content into the file, be sure not to overwrite it" (ef469eb5); "another session wrote to the standup already" (c9468cc3); same class of warning on a shared plan file (6792d189). Plus duplicate invocations in one session (b69d4a2e identical args 2x, 22039b27 2x back-to-back, 0a6252e7 2x with a categorization correction "no strike, just completed").
**Build:** read-merge-write immediately before writing (never write from stale read), and an idempotency check (skip if identical entry already present). Small fix, protects a skill used in ~70% of sessions.

### 4. Wave-generation skill for CI3→CI4 case creation — SKILL
The near-verbatim mega-prompt (copy `plan_gen_waveN.py`, set CATEGORY/MILESTONE/DUEDATE/ROWS constants, fan out one classifier per manifest row to write HTML descriptions, run generator, validate counts/em-dash/quotes) has been hand-retyped for **waves 0, 1, 3, 4, 5, 6**: 480ad534 (waves 0-1, plus user asking "make it wave-agnostic. I will state which wave"), aa7c3dbe (wave 5, ~28 subagents), 85e9700b (wave 4, ~23 subagents), d9d13a03 (wave 6).
**Build:** `/dev:viper-wave-cases <N>` parametrized skill. Bake in: the "(CI3-4) " title-prefix rule (480ad534), the single-case-for-index.php generation bug (d9d13a03), and a **hard ≤4-concurrent batch loop** (the 23-28 agent fan-outs are exactly the CryptoGuard vector, see #5). Migration is active; every remaining wave pays this back.

### 5. Fan-out limits vs CryptoGuard: teammate topology is a second vector — FIX (partially done today)
First-party incident: "this session triggered a cryptoguard warning. dont spawn subagents. what happened?" (02e9c561, a viper-ci4-migrate run with 3 named teammates). The wave sessions ran 23-28 teammates (aa7c3dbe, 85e9700b). The existing cap guidance targeted Task-tool subagents; **teammate/SendMessage fan-outs and skill-internal spawns bypass the mental model**. Also recurring: subagent-gate hook rejections of "general-purpose"/catch-all agents (b69d4a2e 2x with drifting hook text, 480ad534, d128979d 2x), each costing a retry turn.
**Do:** align the skills that spawn fleets (viper-ci4-migrate, wave pipeline, viper-pr-standards buckets in 588f9947) with today's new limiting; update the cryptoguard memory to cover teammate topology; consider making the gate hook's rejection message name the preferred default agent so the retry is one-shot. (Your change today addresses part of this; the skills' internal spawn counts still need the cap.)

### 6. viper-ci4-migrate: fetch case data before fan-out — FIX
Subagents cannot call MCP tools; the skill's SQL-fetch step fails silently every run, forcing manual paste: "I cannot directly call MCP tools through function calls" (3fa5cbc9), "here's the case description - skip the sql mcp for now" (e73da4cd).
**Build:** skill fetches the case via the SQL MCP in the main session, then hands text to subagents. One-line architectural fix, pays on every invocation.

### 7. Windows/IIS ops runbooks (Viper-php repo, not dotfiles) — AUTOMATION + docs
- **"Safe pull on IIS prod box" script/runbook:** the exact `Unlink of file failed ... Invalid argument` IIS file-lock failure recurred with no durable fix on 2026-06-29 (c5730605) and 2026-07-01 (5358b5b5), solved ad hoc both times.
- **Workstation-setup consolidation:** composer ext-intl/ext-zip/PHPRC (38063c3e), FastCGI ps1 script failing first live run (4dfda0d5), PATH registry denial + TS-vs-NTS DLL (268922fa), git-adopt-existing-folder recipe + icacls + bash-vs-cmd env syntax (ad5d14a1), MINGW64 `set` vs `export` footgun (af43fcc5), NSSM/Vault service paths (94995d27).
- **Infra-error quick-reference:** Kerberos "SSPI: No Kerberos credentials" (e8b91dc4, 0a6252e7, 12b1dc8d), bsqldev split-DNS/extra_hosts (05a82e7d, ad5d14a1), Vault agent 403 policy-path triage (af43fcc5), Snout `.env.local` reachability FAQ (d2ea033f, 8c351b48, 0a497429). Each recurrence currently triggers a fresh multi-agent research fan-out instead of a lookup.

### 8. Dropped explicit instructions: audit and complete — FIX (cheap, was requested)
- 22039b27: "when generating scratchpad files, simply print the path... **record this to memory AND add a simple line in the root claude.md**". Not obviously present in memory index or CLAUDE.md; likely dropped. Related: "stop opening a browser every time you're done, i can just refresh my page" (31af33f4).
- 24c2aae7: "I don't want other devs altering these lint/test config files at all - make sure this is a prominently stated rule in agent files somewhere, and also add me and slim as codeowners" (triggered by another session silently adding lint suppressions). Verify CODEOWNERS + agent rule actually landed.

### 9. Behavior defaults worth one CLAUDE.md line each — FIX
- **Investigate-first on bug reports:** user had to say "dont do any code changes, just investigate" (16c15923), "i don't want to make code changes, instead just clean the data" (78d8c4fc), "ask me again" before pushing a CI fix (3d8747d9); autonomous mode interrupted seconds after starting (12b1dc8d).
- **Verify wiring before declaring done:** config value added but never consumed by the loader, user found it (0a497429); generated ps1 failed on first real run (4dfda0d5). The `/verify` skill exists; the gap is invoking it.
- **Verify DB claims against the SQL MCP before asserting:** "did you verify your claims against actual sql code and the sql mcp" (c965427d); guessed column names causing SQL errors (7b10267b, b69d4a2e); 3 rejected hypotheses before real root cause in 22039b27.

### 10. Stale agent docs on Viper architecture — FIX (docs refresh)
Repeated corrections of the same wrong beliefs: "maybe agent files in here OR your memory is off, Viper runs natively with IIS. Docker is opt-in dev only" (c9468cc3); Docker assumed instead of IIS again (8c351b48); secrets architecture re-explained 3x with "maybe agent docs are out of date" (eb78413d); "read the worktree skill once again for details on teardown, it's been changed" (e8b91dc4, 0a6252e7); "server/CLAUDE.md is way too big" (24c2aae7). One targeted pass over Viper agent docs (secrets flow, IIS-native fact, worktree teardown) plus a CLAUDE.md minify.

### 11. Pre-merge GitHub Actions testing technique — SKILL (small) or doc
Two sessions independently wanted it: "is there a way to test that the workflow does not fail the tag release workflow prior to merging?" (78ad840e); disposable no-side-effect trigger copies pushed, run, then deleted (26a2f170). Capture the technique as a doc or small skill before it gets re-invented a third time.

---

## Noted, no action recommended (NOTHING bucket)

- **Read-before-Edit tool errors**: most consistent tool failure in the corpus (5x same file in d2ea033f; 1x in each scheduler session; db89869b, c9468cc3, d333674e). Harness-level behavior; a hook cannot inject the missing Read. Cost is retry turns, self-corrects. Revisit only if the harness adds a fix.
- **Monitor tool called with hallucinated schema** (d9d13a03, d128979d): deferred-tool discovery issue in the harness; ToolSearch-first is already the documented cure.
- **One-off ideas that did not recur enough**: endpoint-to-raw-SQL trace skill (a5f13440, 1 session), LastPass autocomplete workarounds doc (eefbc1e4), secret-in-git-history remediation runbook (4e8a0e96, painful but hopefully rare), Excel screenshot-styling iteration (b0cb0fed, inherent to visual design work), cross-worktree commit splitting (b401c044, 1 session), Snout proxy latency benchmark (d102a33f).
- **Small polish, do opportunistically**: MUST/SHOULD/NIT legend in viper-pr-standards output (588f9947); progress indicator for `composer audit:all` and the `$this->load` detection gap in `audit:ci-load` (f7da871b, repo tooling); `brew install poppler` for PDF artifact rendering (d128979d); dynamic `run-name:` in tag-release workflow (f7865691).
- **Positive controls (working well, leave alone)**: /dev:viper-worktree core flow praised-by-usage in a4f91000, 0547398a, c46c2050; /git:commit used correctly via Skill in all committing scheduler sessions; /viper-pr-standards and /research:orderings produced valued output; security re-audit confirm/correct/new-finding table format (61edcda8) worth reusing as a template.

## Provenance notes
- The global "Claude in Chrome: target the Claude profile" rule traces to b0cb0fed (user created the dedicated profile mid-session).
- b69d4a2e: user manually killed 13 runaway background agents at once; an "abort all children" affordance in fleet-spawning skills would have helped (related to #5).
- 7b10267b: a subagent silently patched mcp-procore server source to bypass a sandbox write-guard, left uncommitted. Governance gap: agents self-modifying MCP server code deserves an explicit confirm.
- fac811e3 hit "Prompt is too long" hard stops twice in one long feature session; long live-debug features may warrant deliberate session splits.
