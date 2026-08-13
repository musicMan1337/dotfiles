---
name: security:harden-gate
description: Pre-ship gate for a security-relevant change, run it through the spine's invariant checklist and return PASS or BLOCK with the exact invariant it breaks. Use before landing a new automation, credential grant, network rule, agent capability, or approval flow. Triggers on, is this safe to ship, review this security change, gate this, pre-flight this automation, does this break least-privilege, check before we deploy this rule, sign off on this change, /security:harden-gate.
model: opus # opus runs the gate inline for clear calls; a non-obvious verdict on a real change is delegated to assessor-fable via fable:hunt (see spine "Execution"). (scaffold: added 2026-08; retest each model release.)
---

# /security:harden-gate: the pre-ship gate

The fast guardrail. Given a specific change about to ship, check it against the spine's seven
invariants and return a verdict. Narrower than `security:harden` (which reasons about a
control open-endedly); this one is a go/no-go with a named reason.

## First, always

Read the spine: `/Users/derek/dotfiles/claude/commands/security/harden/references/spine.md`.
The seven invariants and the scaffold tells are the checklist. If the change touches an
eBacon system, glance at its `~/eBacon/attacksurface.md` entry for the surrounding posture.

## The gate

Run the change against each invariant. It PASSES only if it violates none of them (or the
violations are explicitly accepted with a stated compensating control). Report:

```
CHANGE: <one line>
THREAT: <what this must survive>

  [pass/FAIL] least privilege / no standing access
  [pass/FAIL] root of trust outside attacker reach
  [pass/FAIL] fails closed
  [pass/FAIL] blast radius bounded
  [pass/FAIL] independently verifiable (audit + detection out of band)
  [pass/FAIL] reversible / kill-switchable
  [pass/FAIL] two trust domains for the high-value action (if applicable)

VERDICT: PASS  |  BLOCK -> <the invariant it breaks, and the minimum fix to pass>
```

Only mark invariants that actually apply to the change; drop the rest rather than padding.
A single FAIL that is load-bearing is a BLOCK; lead the verdict with it.

For a real, security-relevant change where the pass/fail call is non-obvious, render the
verdict via the `fable:hunt` skill (`assess <the change + which invariants are in question>`)
per the spine's Execution policy, and relay `assessor-fable`'s call. Obvious invariant breaks
(a non-expiring token, a fail-open default) you call inline. Keep it proportionate: do not
send a trivial gate through the heavy harness.

## Gotchas

- **This is a gate, not a redesign.** Return the minimum fix to pass, not a rewrite. If the
  change needs rethinking from scratch, say "BLOCK, needs design" and hand off to
  `security:harden`.
- **Fail-closed and standing-access are the usual culprits.** New automations most often
  break on a non-expiring credential or a fail-open default; check those first.
- **"Accepted risk" must name the compensating control.** A FAIL is only allowed to pass if
  there is a real Tier-3 detection/blast-radius control behind it, stated. "We accept it"
  with nothing behind it is a BLOCK.
- **An agent capability grant is a change.** New tool access, new egress, new creds for an
  automation or AI agent all go through this gate; the spine's agent section applies.
