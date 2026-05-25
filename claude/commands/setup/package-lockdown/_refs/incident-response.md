# Incident response

Source: playbook §7. Use INCIDENT scope. Walk the scenario; do not write configs.

## Scenario A: a new CVE drops affecting a package you depend on

```
1. Identify blast radius:
   - Check SBOM:
       grep <package> sbom.spdx.json
       jq '.packages[] | select(.name | contains("<package>"))' sbom.spdx.json
   - Verify exact installed version:
       pnpm why <package>      (Node)
       uv pip show <package>   (Python)

2. Check if CVE applies to your usage:
   - Read the advisory's "affected versions" range
   - Read "affected configurations" notes (some CVEs only fire under specific flags)
   - Run osv-scanner scan source --recursive . to see scanner-confirmed exposure

3. Patch:
   - Renovate will open the PR automatically; bypass cooldown for security
     advisories via vulnerabilityAlerts.minimumReleaseAge: null
   - For pnpm transitive deps, add to pnpm.overrides:
       "pnpm": { "overrides": { "<package>": ">=<fixed-version>" } }
   - For uv transitive deps, add direct dep pin or [tool.uv.constraints]

4. Verify fix in lockfile:
   - pnpm: pnpm install && pnpm why <package>
   - uv: uv lock && uv tree | grep <package>

5. Re-scan:
   uvx pip-audit --requirement <file> --no-deps --disable-pip --strict
   pnpm audit --audit-level=high
   osv-scanner scan source --recursive .
```

## Scenario B: you suspect a package was compromised in a version you installed

```
1. STOP all running CI / deploys IMMEDIATELY:
   - Cancel in-flight workflows: gh run cancel <run-id>
   - Pause Renovate: comment "@renovate pause" on dashboard issue
   - Disable scheduled workflows: Settings > Actions > Disable

2. Establish timeline:
   - When was the suspected version published? (PyPI/npm timestamps)
   - When did you install it locally / in CI?
   - What other workflows ran in that window?

3. Rotate every credential the install host had access to:
   - NPM tokens, PyPI tokens
   - GitHub tokens (PATs; OIDC sessions are short-lived)
   - Cloud provider credentials (AWS, GCP, Azure)
   - SSH keys
   - .env files
   - Browser sessions on the dev machine (kill all)

4. Inspect package source:
   - pnpm: find node_modules/<package> -name "*.js" -o -name "*.json" | xargs grep -l "fetch\|curl\|http"
   - Look at postinstall scripts and what they do
   - Check ~/.npm/_logs and ~/.pnpm-debug.log

5. Pin away from compromised range:
   "pnpm": { "overrides": { "<package>": "<known-good-version>" } }

6. Add to deny list (Renovate or local):
   "packageRules": [{
     "matchPackageNames": ["<package>"],
     "matchUpdateTypes": ["patch"],
     "enabled": false   // freeze until investigation complete
   }]

7. Notify team / org security channel with timeline.
```

## Scenario C: a GitHub Action you depend on is hijacked (tj-actions/changed-files scenario)

```
1. Check git history for the action ref:
   gh api repos/<action>/commits/<your-pinned-sha>
   - Verify SHA exists and points to expected content
   - If you pinned to a tag (not SHA), check what tag points to NOW
     vs what it pointed to when last run

2. If you ran in the compromise window:
   - Treat as Scenario B (credential rotation)
   - Inspect every workflow that used the action for exfiltration patterns
   - Audit OIDC token usage (Audit log: Settings > Audit log > filter `actions`)

3. Revert to known-good SHA:
   - Find a commit on the action's GitHub before compromise:
       gh api repos/<action>/commits?until=<date>
   - Update workflow with the verified SHA + comment

4. Defense:
   - Use Renovate's pinDigests: true so future updates re-pin to a SHA you can audit
   - Consider forking critical actions into your own org and pinning to your fork
```
