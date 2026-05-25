# Ecosystem: GitHub Actions

Use when `.github/workflows/` detected. Source: playbook §4.5.

**Pin every action to a 40-character commit SHA. Never to a tag.**

```yaml
# WRONG: tag is mutable. tj-actions/changed-files (March 2025) showed this fails closed.
- uses: actions/checkout@v4

# CORRECT: SHA is immutable. Comment alongside is for human readability.
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

Use Renovate to keep SHAs current. `renovate.json` excerpt:

```json
{
  "extends": ["config:best-practices", "helpers:pinGitHubActionDigests"],
  "packageRules": [{
    "matchManagers": ["github-actions"],
    "pinDigests": true,
    "minimumReleaseAge": "3 days"
  }]
}
```

## Workflow-level least-privilege

```yaml
name: CI
on: [push, pull_request]

# Top-level: deny all by default, grant per-job.
permissions: {}

jobs:
  test:
    permissions:
      contents: read           # minimum needed to checkout
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
        with:
          persist-credentials: false   # don't leave GITHUB_TOKEN in .git/config
      - run: pnpm test
```

## Audit workflows with zizmor

Rust-based, finds injection, overprivileged tokens, `pull_request_target` abuse:

```sh
uvx zizmor==<verified-version> .github/workflows/
```

## Dangers

| Anti-pattern | Why bad | Safer |
|---|---|---|
| `on: pull_request_target` | Runs with write token *and* checks out PR code from forks. Used to exfiltrate secrets from malicious PRs. | `on: pull_request` + `permissions: contents: read`; don't run untrusted code |
| `${{ github.event.pull_request.title }}` in `run:` | Script injection; PR title is attacker-controlled | `env:` to pass into a shell variable, then `"$VAR"` |
| Self-hosted runners on public repos | Persistent host; one malicious PR build can poison subsequent jobs | GitHub-hosted runners (ephemeral) or self-hosted only on private repos with single-job lifecycle |
| Shared workflow secrets across orgs | Blast radius on token compromise | Per-repo secrets; OIDC to cloud (no long-lived tokens) |
| `actions/cache` for sensitive paths | Cache is read+write by anyone with PR access; cache-poisoning vector | Don't cache anything secret-adjacent; cache lockfiles only |

## Cache-poisoning defense (Mini Shai-Hulud vector)

```yaml
# When caching, scope keys aggressively. Never use `restore-keys` for
# security-sensitive workflows.
- uses: actions/cache@1bd1e32a3bdc45362d1e726936510720a7c30a57 # v4.2.0
  with:
    path: ~/.cache/uv
    key: uv-${{ runner.os }}-${{ hashFiles('uv.lock') }}
    # NO restore-keys: exact match or rebuild.
```
