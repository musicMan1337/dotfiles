# Anti-patterns

Source: playbook §8. Use during EXISTING AUDIT scope as the gap-detection checklist; surface every match as a finding.

| Anti-pattern | Why it's bad | Replace with |
|---|---|---|
| `npm install` / `npm i` (no `ci` flag) | Mutates lockfile; pulls latest within range | `npm ci` (or pnpm with `--frozen-lockfile`) |
| `^1.2.3` or `~1.2.3` in app `dependencies` | Range allows silent updates within range | Exact `1.2.3`; let Renovate propose bumps |
| Mutable tag pins in CI (`@v4`) | Hijack vector (tj-actions) | 40-char commit SHA |
| `curl \| sh` from any non-Homebrew source | No verification | Homebrew or download + `gh attestation verify` |
| Committing `node_modules/` | Stale, huge, masks lockfile issues | Lockfile only, `--frozen-lockfile` in CI |
| Not committing the lockfile | "Works on my machine" + zero reproducibility | Always commit `uv.lock`, `pnpm-lock.yaml`, `Cargo.lock`, `go.sum` |
| `npm install --force` to resolve conflicts | Bypasses peer-dep checks and integrity verification | Resolve the actual conflict |
| `pip install` without `--require-hashes` in production | No tamper detection | `pip install -r requirements.lock.txt --require-hashes` |
| Single-maintainer dep with no escrow | Bus-factor / takeover risk | Vendor critical deps into your org (fork or `git subtree`) |
| `pull_request_target` in workflows | Runs untrusted code with write tokens | `pull_request` + isolation |
| `actions/cache@v4` with broad `restore-keys` | Cache-poisoning vector (Mini Shai-Hulud) | Exact-match keys; no `restore-keys` for security paths |
| Adding random package because Stack Overflow said so | No vetting | `pre-install-checklist.md` 9 steps |
| Trusting "popular" packages without scrutiny | Lottiefiles had 4M weekly DLs when compromised | Popularity is not security |
| Disabling postinstall blocking globally because one package failed | Removes a major defense | Add only the specific package to allowBuilds |
| Running `pnpm install` on receipt of webhook from an untrusted source | Self-inflicted RCE | All installs in CI on trusted code only |
| Bundling secrets into Storybook / dev builds | `.env` leaked in Storybook build (CVE-2025-68429) | Storybook `env: () => ({})`; never source `.env` at static-build time |
| `GOSUMDB=off` or `npm config set strict-ssl false` | Disables integrity verification | Fix the actual issue (proxy config, network) |
| `cargo install <crate>` (no `--locked`) | Ignores `Cargo.lock` | `cargo install --locked <crate>` always |
| `uv pip install` (legacy) in new project | Skips lockfile path | `uv add` + `uv sync --frozen` |
| Long-lived NPM_TOKEN / TWINE_TOKEN in CI | Token theft surface | OIDC Trusted Publishing (npm + PyPI both support) |
| Trusting version numbers from LLM output / blog posts / prior agent reports without verifying against the live registry | LLMs hallucinate plausible-looking versions ("pnpm 11.3.0" when reality is 11.1.3) and use future dates. Real incident: 3 of 5 tool pins from research output were wrong (Tundra case study). | Run `pre-install-checklist.md` Step 0 against the actual registry before writing *any* pin. Date-stamp pins. |
| Picking "Node LTS" from memory | LTS rotates yearly. Pinning Node 22 when 24 is Active LTS leaves you on Maintenance LTS with shorter support window. | `curl -s https://nodejs.org/dist/index.json \| jq` |
| Trusting "current date" in tool/agent context to imply future-dated registry contents | Future dates don't unlock future versions. Registry holds what was published. | Always cross-check with registry timestamp (`npm view <pkg> time`, PyPI `releases` keys) |
| Running `gh attestation verify` against a Homebrew-installed binary built from source | Brew formulas that use `cargo install` / `go build` / `pip install` / `npm install` / `make` produce binaries with different SHA-256 than upstream attested artifact. 404 is by design. | Verify the *official downloaded release artifact* (or signed container image); accept brew's audit chain for the local binary |
| Following self-update prompts on package manager binaries (`pnpm self-update`, `npm install -g pnpm@latest`) without checking cooldown | The prompt is a `latest` query; doesn't respect project's `minimumReleaseAge`. Can fetch a <24h release. | Use Renovate to gate manager updates; ignore in-CLI self-update nudges |
| Trusting brew formula `installed` field in `brew info --json=v2` to know latest available | `installed` reflects local cache, not upstream. Stale caches show "latest" for ~24h after upstream releases. | Query canonical registry (`npm view <pkg> version`, PyPI JSON, GitHub releases). Brew is one input, not the authority |
