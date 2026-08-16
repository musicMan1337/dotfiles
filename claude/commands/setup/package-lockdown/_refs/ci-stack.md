# CI security stack

Source: playbook §5. Defense in depth via **layered, non-overlapping** tools. More tools means more noise, not more security.

## Recommended combination (each layer catches different things)

| # | Layer | Tool | Frequency | Catches |
|---|---|---|---|---|
| 1 | Pre-install | Socket.dev Firewall | Local dev | Novel malware (T1, T2, T5) |
| 2 | Pre-PR | dependency-review-action | PR open | License + vuln introduction |
| 3 | Per-PR | OSV-Scanner | PR / merge | Known CVEs (cross-language) |
| 4 | Per-PR | pip-audit | PR (Python) | Python-specific advisories |
| 5 | Per-PR | pnpm audit + signatures | PR (Node) | Known CVEs + provenance |
| 6 | Per-PR | Trivy | PR (Docker) | Container CVEs + secrets |
| 7 | Per-PR | zizmor | PR (Actions) | Workflow misconfigs |
| 8 | Continuous | Dependabot (cooldown) | Weekly | Outdated deps + Action SHAs, cooldown-gated (**estate default**) |
| 9 | Continuous | Renovate | Daily | Alternative to 8 for repos needing dashboard/automerge/packageRules |
| 10 | Post-deploy | SBOM (Syft) | Push to main | Inventory for IR (L8) |

## Do not add (overlap = noise, not coverage)

- Snyk + OSV-Scanner (overlap on CVEs; OSV is free and broader)
- npm audit + pnpm audit (pnpm audit uses npm's DB)
- Grype + Trivy (overlap)
- Safety + pip-audit (pip-audit is the PyPA-official superset)

## Dependabot config template (estate default)

Native `cooldown` support landed in Dependabot; this mirrors the age-gate discipline
without a Renovate install. Proven in production on Snout. `.github/dependabot.yml`:

```yaml
# (L1/L9 continuous) Dependabot keeps deps + pinned Action SHAs current, with a cooldown
# so freshly-published versions age before a PR is opened (defense against compromised
# releases that get caught and yanked within days). The "npm" ecosystem covers pnpm-lock.yaml.

version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    cooldown:
      default-days: 7
      semver-major-days: 14
    groups:
      dev-minor-patch:
        dependency-type: "development"
        update-types: ["minor", "patch"]

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 3
```

Tradeoff vs Renovate: no `vulnerabilityAlerts.minimumReleaseAge: null` equivalent, so a
security fix inside its cooldown window needs a manual override-floor bump (pnpm
`overrides` / uv constraints) instead of an expedited bot PR. Acceptable when OSV runs
per-PR and floors are the incident lever anyway.

## Renovate config template (alternative)

Prefer when a repo needs the dependency dashboard, automerge, per-package rules, or
cooldown-bypass for security-flagged bumps.

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:best-practices",
    "security:minimumReleaseAgeNpm",
    ":dependencyDashboard",
    ":separateMajorReleases",
    "helpers:pinGitHubActionDigests"
  ],
  "osvVulnerabilityAlerts": true,
  "vulnerabilityAlerts": {
    "enabled": true,
    "minimumReleaseAge": null,
    "automerge": false,
    "labels": ["security", "vulnerability"]
  },
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 5am on Monday"],
    "automerge": false
  },
  "packageRules": [
    {
      "description": "Majors require 14-day cooldown + manual review",
      "matchUpdateTypes": ["major"],
      "minimumReleaseAge": "14 days",
      "automerge": false
    },
    {
      "description": "Minor / patch: 7-day cooldown",
      "matchUpdateTypes": ["minor", "patch"],
      "minimumReleaseAge": "7 days",
      "automerge": false
    },
    {
      "description": "GitHub Actions: pin to SHAs, 3-day cooldown",
      "matchManagers": ["github-actions"],
      "pinDigests": true,
      "minimumReleaseAge": "3 days"
    },
    {
      "description": "ML / AI libraries: 14 days, always manual",
      "matchPackageNames": ["torch", "transformers", "numpy", "spacy"],
      "minimumReleaseAge": "14 days",
      "automerge": false
    }
  ]
}
```

Key: `vulnerabilityAlerts.minimumReleaseAge: null` bypasses cooldown only for security-flagged bumps. This resolves the cooldown-vs-fresh-fix tension.

## Branch protection (required)

Adapt `contexts` to the checks the repo actually runs (a Node-only repo has no
pip-audit; Snout requires only `osv-scan` + a review). A required context that never
reports blocks every merge.

```sh
gh api repos/$ORG/$REPO/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["osv-scanner","pip-audit","pnpm-audit","dependency-review","ci"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":true}' \
  --field required_linear_history=true \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```
