# Ecosystem: Python (uv)

Use when `pyproject.toml` / `uv.lock` detected. Source: playbook §4.2.

Why uv: single lockfile with cross-platform hashes (`uv.lock`), built-in `exclude-newer` cooldown, SLSA-signed binary releases, PEP 517 build isolation by default, 10-100x faster than pip-tools/poetry/pdm.

## Install

```sh
# macOS, preferred (Homebrew's audit chain)
brew install uv

# Linux/CI hardened (download + verify SLSA attestation)
VERSION=<verified-uv-version>
curl -LO https://github.com/astral-sh/uv/releases/download/${VERSION}/uv-aarch64-apple-darwin.tar.gz
gh attestation verify uv-aarch64-apple-darwin.tar.gz --owner astral-sh
# Expected: Sigstore bundle confirming workflow `astral-sh/uv/.github/workflows/release.yml`

# Linux/CI alternative (HTTPS to Astral-owned domain, no signature in script)
curl -LsSf https://astral.sh/uv/${VERSION}/install.sh | sh
```

Important nuance: Homebrew's uv formula **compiles from source** (`cargo install` in formula), so the brew-installed binary has a different SHA-256 than the attested release artifact. `gh attestation verify` against `$(brew --prefix uv)/bin/uv` returns HTTP 404 by design, not because attestation is broken.

| Install channel | Trust anchor | What's verified |
|---|---|---|
| Homebrew | `homebrew-core` formula PR review + upstream source-URL SHA pin | Brew compiled from audited source |
| Official tarball + `gh attestation verify` | Sigstore SLSA tied to Astral's release workflow | Binary bytes were produced by Astral's release workflow |
| `ghcr.io/astral-sh/uv:<version>` image | Sigstore chain (Astral signs container images too) | Image bytes were produced by Astral's release pipeline |
| `pip install uv` | PyPI sha512 + PEP 740 attestation (if present) | PyPI artifact integrity |

Rule: for CI / production / Docker, use a channel that produces a verifiable artifact (official tarball + attestation, or `ghcr.io/astral-sh/uv` image). For local dev, brew is acceptable. Don't mix (verifying brew binaries against GitHub attestations is a category error).

Generalizes: **any Homebrew formula whose install block calls `cargo install`, `go build`, `pip install`, `npm install`, or `make` builds from source and won't match upstream binary attestations.** Check via `brew cat <formula> | head -30`.

## Workspace root `pyproject.toml` (uv workspace)

```toml
[project]
name = "myproject-workspace"
version = "0.0.0"
requires-python = "==3.12.*"
dependencies = []

[tool.uv.workspace]
members = ["apps/api", "packages/*"]

[tool.uv]
exclude-newer = "7 days"
```

## `uv.toml` (project-level supply-chain defaults)

```toml
# (L1 Age gate) Refuse PyPI uploads from the last 7 days.
exclude-newer = "7 days"

[pip]
# (L2 Hash pinning) Reject installs unless every wheel/sdist hash matches.
require-hashes = true
```

## App-level `pyproject.toml` (exact pins, groups separated)

```toml
[project]
name = "my-api"
version = "0.0.0"
requires-python = "==3.12.*"

# Exact pins. Renovate proposes bumps as PRs after cooldown.
dependencies = [
    "fastapi==<verified>",          # verified YYYY-MM-DD
    "starlette==<verified>",        # explicit (CVE-prone, don't rely on transitive)
    "pydantic==<verified>",
    "sqlalchemy==<verified>",
    "transformers==<verified>",     # explicit (ReDoS CVE floor)
]

[dependency-groups]
dev = [
    "pytest==<verified>",
    "ruff==<verified>",
    "mypy==<verified>",
    "pip-audit==<verified>",
]

[build-system]
requires = ["hatchling==<verified>"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/my_api"]
```

## Critical commands

```sh
# Generate/update uv.lock (commit it)
uv lock

# Install exactly per lockfile (fails on drift)
uv sync --frozen          # CI dev/test (includes dev group)
uv sync --frozen --no-dev # production (runtime only)

# Block setup.py execution in production (requires wheels)
uv sync --frozen --no-dev --no-build

# Export for Docker / airgapped deploys (hashes preserved)
uv export --format requirements-txt --frozen -o requirements.lock.txt
pip install -r requirements.lock.txt --require-hashes

# Audit (uv-managed Python lacks ensurepip; need these flags)
uv export --format requirements-txt --frozen -o /tmp/reqs.txt
uvx pip-audit --requirement /tmp/reqs.txt --no-deps --disable-pip --strict
```

## Pinning rule

| Location | Pin style | Example |
|---|---|---|
| `[project].dependencies` | **Exact** | `"fastapi==0.115.6"  # verified 2026-05-25` |
| `[dependency-groups]` | **Exact** | `"pytest==8.3.4"` |
| `[tool.uv.constraints]` (transitive overrides) | **Floor** | `starlette>=0.50.0` |
| `uv.lock` | Exact + SHA-256 (committed) | auto |
| `requires-python` | **Exact minor** | `"==3.12.*"` |

## uv-specific pitfalls

- **TARmageddon (CVE-2025-62518)** in uv's async-tar was patched in 0.4.x. Keep uv pinned and bumped via Renovate.
- **`--no-build-isolation`** disables PEP 517 build isolation. Never in production (exposes host environment to arbitrary `setup.py` code).
- **Trusted Publishing** (OIDC from GitHub Actions to PyPI) is the only acceptable publish path for packages you author. No long-lived API tokens.
- **pip-audit on uv-managed Python**: needs `--no-deps --disable-pip` (uv's Python lacks `ensurepip`; pip-audit's default mode SIGABRTs trying to create a sub-venv).
