# Hardening Spine: the shared gold standard

The methodology all three `security:harden*` skills inherit. `security:harden` (advisor),
`security:harden-plan` (remediation workflow), and `security:harden-gate` (pre-ship gate)
each read THIS file first, then apply it to their own job. One source of truth for the
frame; edit it here and all three inherit the change.

Not a security primer. A capable model already knows what MFA and TLS are. This encodes a
specific **opinionated lens** for judging whether a control actually buys anything, and the
eBacon-specific tiers/examples it grew out of. That is the distribution shift; the generic
"harden your systems" advice is not.

---

## The core lens: three questions, asked of every control

Grade any control, existing or proposed, by answering these in order. The verdict is not
"is this good security?" but "**what does it actually buy, and against whom?**"

1. **Survives-what?** Which level of compromise does this control still hold under?
   - stolen credential (an attacker has a valid account/key)
   - platform / vendor / supply-chain compromise (the thing issuing commands is hostile)
   - assumed breach (the attacker is already executing on the box)

   A control that only survives the first is not worthless; it is just Tier 1, and must be
   labelled as such so nobody mistakes it for platform-compromise defense.

2. **Root-of-trust-where?** Where does the control's authority/verification actually live,
   and is that location **outside the attacker's maximum reachable privilege**?
   - The governing principle: *the verifier must sit below the attacker's max privilege.*
     RMM/agent compromise yields SYSTEM/root; a verifier in kernel Code Integrity anchored
     in Secure Boot sits below that, so SYSTEM cannot neutralize it. A verifier that is a
     user-space process sits at or above the attacker's reach, so it cannot.
   - "Delivery is not authorship." A compromised channel can carry a policy/command; if the
     authorization is verified against a key the channel does not hold, delivery buys the
     attacker nothing.

3. **Boundary-or-scaffold?** Is this a real structural boundary or scaffolding?
   - **Boundary:** enforced by something the attacker at their privilege level cannot switch
     off. Cryptography, kernel/hypervisor isolation, capability limits, network segmentation
     at an off-box device, physical/air gap, an offline signing key.
   - **Scaffold:** a process, config flag, or agent the attacker can stop, clear, or edit
     once they have the privilege the threat model already grants them. Useful as defense-in-
     depth; fatal when mistaken for a boundary.
   - The one-line test: **"can root turn this off?"** If yes, it is scaffold against a
     root-level threat. (It may still be a real boundary against a lesser threat, name which.)

---

## The survives-what ladder (the three tiers)

Generalized from the RMM assessment (`~/dotfiles/artifacts/rmm-defense-tiers.html`). Every
hardening recommendation should say which tier it is; a plan that is all Tier 1 has not
addressed platform compromise, and should say so out loud rather than imply coverage.

- **Tier 1: survives a stolen credential.** Account/console hardening: FIDO2 over phishable
  factors, enforced not merely available; scoped least-privilege roles; short-lived scoped
  credentials over standing access; maker-checker where the platform supports it. Dies with
  the platform: every Tier 1 control assumes the issuer is honest.

- **Tier 2: survives platform / vendor / supply-chain compromise.** Root of trust lives
  outside the compromised thing. Endpoint-enforced signed policy with the key offline;
  minimum-version rules that reject downgrades regardless of who pushed them; the receiver
  verifies the second key, not the sender. This is where the two-key idea actually pays off,
  and only if the verifier passes question 2.

- **Tier 3: assume breach.** Bound blast radius and detect. Segmentation; tier-0 exclusion
  (keep the powerful agent off DCs, hypervisors, backup, identity/secrets infra); detection
  in an **independent trust domain** (not deployable/removable by the thing it watches);
  egress control; canary + soak before fleet-wide; a real kill switch; tamper-evident audit.
  Tier 3 is not optional garnish. Tiers 1-2 reduce the chance of breach; Tier 3 is what you
  have left when they fail, so a plan that skips it has no answer for its own worst case.

---

## Gold-standard invariants (the properties a strong control has)

Score a control against these. The more it satisfies structurally (not by promise), the
higher it grades. Treat these as the rubric behind the verdict.

1. **Least privilege / no standing access**: authority is scoped and short-lived; nothing
   holds more than its task needs, nothing holds it longer than the task.
2. **Root of trust outside the attacker's reach**: off-box, offline, or below max privilege
   (question 2). The single highest-leverage property.
3. **Fails closed**: the default/silent state is deny; "open" is an explicit, TTL'd,
   revocable exception whose close is the reliable half.
4. **Blast radius bounded**: one compromise does not cascade; segmentation and tier-0
   exclusion cap how far it reaches.
5. **Independently verifiable**: an audit trail and detection that live in a *different*
   trust domain than the thing they observe, so compromising the target does not blind you.
6. **Reversible / kill-switchable**: you can revoke, roll back, or halt without depending on
   the possibly-compromised control plane.
7. **Two independent trust domains for high-value actions**: the attacker must compromise
   two unrelated planes (e.g. the vendor cloud AND your offline key), verified where they
   cannot reach, not one.

---

## Durability: what a faster/smarter attacker breaks, and what it doesn't

The frame for the "AI makes attack surfaces impossible to defend" fear. It is half true, and
the half decides where to invest.

- **Degrades as the attacker gets faster/smarter** (defenses that are a *race*): detection-
  and-response at human speed, signature/heuristic matching, security-through-obscurity,
  human-review-in-the-loop as the *only* gate, "they won't think of that." Faster recon,
  vuln discovery, and exploit chaining compress all of these.
- **Does not degrade** (structural invariants): cryptographic boundaries, kernel/hypervisor
  isolation, capability least-privilege, network segmentation, air gaps. A signed policy is
  exactly as strong against a genius as against a script kiddie.
- **The rule:** put the guarantee where the attacker's *power* cannot reach, so their
  *intelligence* buys them nothing. Prefer boundaries over races. "Impossible to defend" is
  only true for defenses that were always a race; migrate those to structure where you can,
  and accept-and-detect (Tier 3) where you can't.

- **Boring beats clever.** A solid, well-understood base pattern (proven crypto primitives,
  OS/kernel isolation, capability least-privilege, network segmentation, an offline key)
  protects the same no matter how smart the attacker is. A clever or novel control's
  cleverness is usually a hidden dependency on the defender out-thinking the attacker, which
  is a race, and its novelty means unaudited failure modes nobody has stress-tested. When a
  boring control and a clever one both cover the threat, pick boring; reserve cleverness for
  where no base pattern exists, and treat it as unproven until it is. This is the same lesson
  as question 3: the strongest control is often the least interesting one.

---

## AI agents as a hardening target (and a threat)

When the operator runs AI agents to harden or operate systems, the agent is a **new
privileged identity**: functionally another RMM: broad reach concentrated in one steerable
thing. Grade it with the same three tiers.

- The scary property is not the model's intelligence; it is the **standing credentials and
  network reach** granted to it. Scope and expire them (Tier 1); keep the *enforcement* of
  what it may do outside the agent's reach so it cannot widen its own authority (Tier 2);
  assume it is compromised or injected and bound the blast radius (Tier 3).
- **Prompt injection is the present-tense version of "attackers get in through the same
  mechanism."** An agent that reads logs, tickets, PRs, or web pages ingests attacker-
  influenceable text; the channel that lets the good agent work is the channel the attacker
  hijacks. An attacker who can write a log line the agent will analyze can try to steer it.
- Two incident lessons (July 2026, verified): **test the wall, do not trust that it is
  sealed** (Anthropic's eval env was believed isolated and was not: a *config* escape); and
  **bound by can't-reach, not by won't-think-of-it** (OpenAI's models found a real path out
  to Hugging Face: a *capability* escape). Design assumes both failure modes.
- Controls: scoped/short-lived creds, default-deny egress from the agent sandbox, human-gated
  mutating actions, full tamper-evident audit, a kill switch. Same rubric as everything above.

---

## Scaffold tells (anti-patterns that fail question 3)

Flag these explicitly; they are the recurring ways a control looks like a boundary but is
not. Each is fine as defense-in-depth, dangerous when sold as the boundary.

- Console-side / account-side controls presented as platform-compromise defense (Tier 1
  wearing a Tier 2 label).
- On-box "approval" or "authorizer" processes (die to root; the key holder is on the box).
- Product tamper-protection treated as a boundary (vendor software fighting a same-privilege
  attacker is a speed bump, not a wall).
- Security through obscurity; unpublished endpoints; "nobody knows the URL."
- Human review as the *only* gate (does not scale against machine-speed attackers).
- Fail-open defaults; exceptions with no TTL; the "temporary" allow that never closes.
- A single trust domain guarding a high-value action (one compromise = full authority).
- Detection that lives inside the thing it watches (compromise blinds it).

---

## eBacon anchors (living examples; portable-but-aware)

The inventory `~/eBacon/attacksurface.md` already tiers real systems, names their current
gaps, and records assessment history. It lives outside every git repo on purpose, because
this repo is PUBLIC. Read it at runtime and use it as the worked corpus when the target is
one of ours. **Never copy its contents back into this file, this repo, or any artifact that
leaves the machine:** naming a specific system alongside its unpatched weaknesses turns a
teaching example into a targeting list.

When grading an eBacon target, pull these from the inventory rather than from memory:

- The target's tier, criticality, and blast radius (what a compromise of it reaches). The
  secrets backbone and any vendor platform with fleet-wide push rights sit at the top; grade
  them against question 2 (where the root of trust actually lives), not a control checklist.
- Its known-deferred items, and whether each is a real boundary gap or accepted scaffold.
  Deferred items cluster around root-of-trust custody far more often than around missing
  features.
- The estate's best-hardened system, used as the reference bar rather than as a gap.
- The recurring cross-estate gap classes the inventory keeps surfacing. These repeat across
  systems, so check a new target for the same classes before assuming it is clean: disabled
  TLS verification, unpinned supply-chain refs, unauthenticated internal endpoints, and
  unverified webhook signatures (delivery is not authorship).

Vendor-platform targets (RMM, CI, identity providers) get the tiered treatment the inventory
records: provider-console hardening, endpoint-side verification of anything the provider
pushes, and assume-breach containment. That layering is the canonical worked example of this
whole spine.

---

## Execution: route REAL assessment to the Fable workers

These skills split reasoning from real assessment and run them on different engines, because
the operator wants security JUDGMENT on the custom Fable workers, not authored inline by the
premium main session.

- **Abstract / advisory** (grade a hypothetical control or design, threat-model a pattern,
  explain why something is scaffold; no first-party code or live system in front of you):
  reason inline. Low refusal risk, not worth the recovery cost.
- **REAL security concern** (analyzing actual first-party code/config/systems for actual
  weaknesses; rendering a severity, real-vs-noise, or boundary-vs-scaffold verdict on a live
  control or change; producing a remediation plan for a real system): do NOT author the
  verdict inline. Route it through the `fable:hunt` skill, which runs the Fable workers
  (`vuln-searcher-fable`, `bug-searcher-fable`, `assessor-fable`) behind a guardrail-recovery
  harness. Stay the orchestrator: gather scope, invoke `fable:hunt`, relay its verdicts.
  Never spawn the Fable agents directly (they are gated to that harness), and do not overrule
  or re-derive the Fable judgment.
  - find real weaknesses in real code -> `fable:hunt` with `vuln <scope>` (and/or `bug`)
  - render the judgment (severity, real-vs-noise, tier, remediation call) -> `fable:hunt`
    with `assess <the findings + the decision to make>` (assessor-fable)
- **Authorization:** invoking one of these skills on a real first-party target is itself the
  explicit request that authorizes the fable delegation, satisfying `fable:hunt`'s
  explicit-request-only guardrail. Never send abstract questions there.
- **When the main session is already Fable:** the harness is redundant; inline judgment is
  fine if it does not self-stop (the rule `fable:hunt` itself uses). If it self-stops, route
  through `fable:hunt` rather than watering down the analysis.
- **Coverage honesty:** if `fable:hunt` reports a coverage gap (repeated self-stops left
  scope un-assessed), surface it; never present partial assessment as complete. The Opus
  fallback that does not false-refuse is `security-auditor`.
