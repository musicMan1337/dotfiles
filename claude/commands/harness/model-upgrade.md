---
name: harness:model-upgrade
description: Re-test harness scaffolding after a model upgrade and delete what the new model has internalized. Triggers on: model upgrade, new model release, harness audit, re-test scaffolds, bitter lesson check, shrink the harness
---

# harness:model-upgrade

Run after switching to a new model generation (or whenever asked). Goal: find scaffolding whose premise the new model has invalidated, and delete it. Every harness component encodes an assumption about what the model can't do (see "Harness Engineering Conventions" in `~/dotfiles/CLAUDE.md`); unremoved scaffolding becomes the ceiling on the new model.

## Step 1: Inventory dated scaffolds

Grep the config surface for annotations and dated premises:

```bash
grep -rniE "scaffold:|dated premise|re-?test|re-?measure|cost pick" ~/dotfiles/claude ~/dotfiles/CLAUDE.md --include="*.md" --include="*.js" --include="*.sh" -l
```

Standing registry as of 2026-09 (update this list as scaffolds are added/removed):

| Scaffold | Premise class | Re-test when |
|----------|--------------|--------------|
| subagent-gate caps (4/6, Sophos CryptoGuard incident 2026-07-01) | environment | AV policy or machine changes, or IT grants an exclusion; NOT on model upgrades |
| egress/sensitive-write/secret-scan hooks | authority boundary | never on a model upgrade; only when the protected surface changes |
| delegation-by-default for large diffs/searches (git:commit, git:pr, Subagent Strategy) | cost/context economics | pricing or caching economics change |
| TIERS.md tier assignments + price ratios | price/capability snapshot | every model generation |
| obsidian:standup haiku pin (2026-07) | cost pick | on quality misses |
| code-comment limits (CLAUDE.md) | generation bias | every release; held at Opus 5 |
| correctness argument / verdict (CLAUDE.md) | generation bias | every release; held at Opus 5 |
| principles.md "separate before serializing shared state" | generation bias | every release; held at Opus 5, rest of the cluster deleted |
| unslop rules 24/25/27 prose register | generation bias | every release |
| Fable false-refusal harness (fable:hunt, harden*, the *-fable agents) | Fable classifier behavior | a FABLE release, not a session-model upgrade |
| generation/evaluation separation (plan-auditor, /verify doctrine, "nothing is done until exercised") | persistent bias class | every release, but expect to keep; self-report optimism has survived every generation so far |

## Step 2: Re-test, one component at a time

Only scaffolds whose premise is model capability get re-tested (environment facts and authority boundaries stay regardless). For each: run a representative task with the scaffold bypassed on the new model, compare quality and cost against the scaffolded path, and if the new model holds up, DELETE the scaffold (git is the archive; no commented-out corpses). One component per test so you know what moved the needle.

Bypass mechanics: a subagent still inherits this harness, so the bypass is a
fresh `claude` in a throwaway fixture dir with every customization off:

```bash
print -r -- "$PROMPT" | claude --safe-mode --strict-mcp-config \
  --allowedTools Read Edit Write Bash Grep Glob -- -p --model opus
```

`--allowedTools` is variadic and will swallow a trailing positional prompt, so
pass the prompt on stdin and keep the `--` separator. Judge the run by what it
volunteered unprompted, and note that one trial per scaffold is one trial: a
rule that splits into a method half and an authority half usually has only the
method half internalized, so narrow it rather than deleting it whole.

## Step 3: Sweep for new violations

Anything added since the last pass gets the master question (environment fact / authority boundary / human method?). Use `git log --since=<last pass> --diff-filter=A --name-only -- claude/` to enumerate what is new.

## Report

Three lists: deleted (with what replaced them, usually nothing), kept with refreshed date, newly flagged. Update the Step 1 registry and `TIERS.md` dates. Commit via `/git:commit`.
