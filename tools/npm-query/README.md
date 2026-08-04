# npm-query

Workstation scanner for npm supply-chain incidents. Finds every npm project on a
machine and asks `npm query` whether a compromised dependency version is present.

Built for the 2026-08-04 `keyv` / `cacheable` compromise, but the IOC list is the
only thing that changes between incidents.

## Usage

```bash
bash npm-ioc-scan.sh              # scan $HOME
bash npm-ioc-scan.sh ~/code       # scan specific trees (preferred, see Notes)
JOBS=4 bash npm-ioc-scan.sh       # throttle parallelism (default 8)
```

Exit `0` clean, `1` indicator found, `2` setup problem. Safe to run repeatedly;
it only reads.

## Updating for a new incident

Edit the `IOCS` block at the top of `npm-ioc-scan.sh`. One `name range` per line,
npm semver syntax:

```
keyv >=6.0.0
flat-cache >=6.1.0
file-entry-cache >=11.0.0
cacheable >=2.5.1
```

## What it checks

1. **npm lockfiles** via `npm query --package-lock-only`, so no install and no
   network. npm evaluates the semver ranges itself.
2. **yarn / pnpm lockfiles**, parsed directly since `npm query` cannot read them.
3. **The npm cache** (`~/.npm/_cacache`). A cached tarball proves the version was
   actually downloaded, which is the line between "vulnerable on paper" and
   "assume the payload ran and rotate credentials."

## Why it keys on lockfiles, not `.git` or `package.json`

`npm query` walks the full transitive depth of one lockfile's tree but stops at
project boundaries. Verified: querying a repo root returns nothing for a package
that exists only in a nested subproject's own lockfile.

So one invocation per lockfile directory is required. A single repo can hold many
(one monorepo here had 7). Keying on lockfiles also means npm **workspaces**,
which share a single root lockfile, are not scanned once per member. Keying on
`.git` would additionally drag in every non-npm repo on the machine.

## Notes

- Pruning `node_modules` during the walk is what makes this usable. A full `$HOME`
  scan is ~30s; grepping `$HOME` unpruned takes minutes.
- npm roots get npm's real semver engine. The yarn/pnpm and cache paths use a
  minimal comparator handling `>= > <= < =` against `x.y.z` only. Fine for IOC
  lists; it does not evaluate `^`, `~`, or compound ranges.
- A full `$HOME` walk plus 8 parallel npm processes is an I/O burst that some
  endpoint-protection agents flag as ransomware-like. Prefer passing a code
  directory, and drop to `JOBS=4` on a managed fleet.
- Advisory databases are the wrong tool for a same-day compromise. Both
  `npm audit` and `osv-scanner` returned nothing for the `keyv` incident, because
  the malicious releases had no CVE and carried valid GitHub Actions provenance.
  A version check is the detection; the databases catch up later.
