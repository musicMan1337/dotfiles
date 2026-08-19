# Engineering principles

Adapted from the `principle-*` skills in [pstack](https://github.com/cursor/plugins/tree/main/pstack) (MIT, Lauren Tan), which ships 22 of them as individually invocable skills. Kept here as one reference file instead: 22 always-listed descriptions is context load on every turn, and most of these fire together or not at all.

Each entry is the operative test, not the essay. Pointed at by the `coder` and `planner` agents, and by `blast-radius`.

## Verification

**Prove it works.** Check the real artifact, never a proxy. Process liveness directly, not through derived state. The actual value, not a cached representation. When verification fails, suspect the observation method before the system. For delegated work, inspect the diff and the runtime behavior, never the delegate's summary: agents report what they intended, not always what happened. The strongest proof is a script that re-runs the comparison, kept as an artifact a reviewer can re-run.

**Sequence work into verifiable units.** In a sweep, migration, or run of similar edits, verify each change before starting the next; never batch the edits and check once at the end. Then stack the commits in the order that proves the work: the failing test first, the fix on top, so a reviewer watches it go red then green. Rebase onto clean trunk first so every check measures against the real baseline.

**Build the lever.** For anything non-trivial, build the tool that does or proves the work instead of doing it by hand. Two payoffs: it reruns for free, and it is one artifact a reviewer can read and rerun, which turns "trust me" into "run this". Do the first unit by hand to learn the recipe, then build the tool and diff it against the hand-done version. The falsifiable test: applying this principle produces a file. If there is no script, codemod, or generator in the diff, it was not applied.

## Architecture

**Type system discipline.** Make illegal states unrepresentable: model variants as sum types, not a bag of optional fields where contradictory combinations compile. `{ completed: boolean; completedAt?: Date }` admits `completed: true` with no date, so derive the boolean or model the variants. Build types up from the values you want rather than carving them out of a looser type with checks: a non-empty list is a head plus a rest. Brand semantic primitives (`UserId` and `OrderId` are both strings and must not be interchangeable). External data is untyped until parsed, at every boundary. Never lie to the compiler; a cast is a hazard, not a fix. Exhaustive matching is the compiler's job. Derive from the authoritative schema rather than hand-rolling a parallel type. Strengthen a type only where partiality actually appears, then stop: extra precision costs reuse and buys no safety.

**Boundary discipline.** Guards at system boundaries (CLI args, config, network, external APIs, DB rows), typed data and no re-validation inside. Business logic in pure functions the shell just calls. Expose domain concepts across a boundary, never the boundary's private representation. Test: is this data crossing a boundary right now? If not, the validation is redundant.

**Model the domain.** Encode the domain in a structure instead of scattering it across conditionals: a state machine instead of loose booleans, a typed model instead of repeated shape assumptions, a registry or discriminated union instead of branching spread across files. The tell that this was skipped is a feature that grows an if/else chain by one more branch, or a second boolean that must stay in sync with the first. Do not force it: boring code that is clear, local, and unlikely to grow stays boring.

**Separate before serializing shared state.** When concurrent actors might write the same file, branch, key, or object, first ask whether they need the same mutable object at all. Default to eliminating the sharing: give each actor its own file or state dir and merge at the read boundary. Two workers writing their own field into one `state.json` is still shared mutation. Only when one shared write target is a real invariant, serialize structurally (lockfile, sequential phase, single writer). Treat "we need a lock" as a smell to check, not the default answer.

**Make operations idempotent.** Every state-mutating operation answers two questions: what happens if this runs twice, and what happens if the previous run crashed at any point. If either answer depends on what state was left behind, it needs a reconciliation step. Applies to setup scripts, SQL migrations, wizards, and hooks.

## Simplicity

**Laziness protocol.** Writing code is cheap here, which makes over-engineering easy; borrow a human maintainer's fatigue as the counterweight. Prefer deletion to addition. Keep the call hierarchy flat: if answering a question needs more than three files traced, flatten it. Consolidate a repeated decision behind one source of truth. Minimize the diff. When a task asks for a new signal threaded through types, schemas, and pipelines, stop and look for the direct path. Prime directive: if a human would find the code exhausting to maintain, it is a bad solution.

**Minimize reader load.** Two independent axes: layers to trace, and hidden state to hold. A flat file with 50 globals is as hard as a six-layer adapter stack, so guard both. Collapse wrappers with one caller and adapters with no second implementation. A layer that repeats the same methods and arguments adds load without compression. Prefer returns over mutations, locals over fields, fields over module state. Name the invariant at the boundary so the reader learns it once. Test: can a new reader answer "where does X come from" and "what can change X" in under 30 seconds?

## Meta

**Encode lessons in structure.** When you catch yourself writing the same instruction a second time, ask whether it can be a lint rule, a metadata flag, a runtime check, or a script. If it can, encode it and delete the instruction, because the instruction was the symptom. Pick the strongest rung the situation allows: a state that cannot compile, then a lint that fails CI, then a canonical helper, then a runtime check. Agents copy whatever the surrounding code does, so a weak guard becomes the next template.

## Deliberately not adopted

Recorded so `harness:model-upgrade` does not keep re-litigating them.

- **never-block-on-the-human.** Conflicts with the numbered-options rule, confirm-before-outward-facing-actions, and investigate-first on bug reports.
- **fix-root-causes**, **redesign-from-first-principles**, **subtract-before-you-add.** Already covered by the bug-report rule and its fix ladder.
- **guard-the-context-window.** The subagent strategy in CLAUDE.md is strictly more specific, concurrency caps included.
- **exhaust-the-design-space.** Covered by the arena and judge-panel patterns in the Workflow tool.
- **foundational-thinking**, **experience-first**, **outcome-oriented-execution**, **migrate-callers-then-delete-legacy-apis.** Either default behavior at this tier or a per-project call, not a standing rule.

(scaffold: patches the model's tendency to reach for the locally convenient shape, a lock, a nil-check guard, a boolean pair, a hand-run edit, instead of the structure that makes the failure unrepresentable; added 2026-08; retest when a model volunteers the sum type, the eliminated shared write target, and the rerunnable script without being asked)
