# CLI binaries (curl / brew install)

Use when installing a CLI tool. Source: playbook §4.7.

## Order of preference (most to least secure)

| Rank | Method | Verification |
|---|---|---|
| 1 | Homebrew (`brew install`) | Formula audited, signed tap |
| 2 | Official signed release + `gh attestation verify` (Sigstore/SLSA) | Cryptographic provenance |
| 3 | Official signed release + GPG verification | Cryptographic, key trust chain |
| 4 | Official signed release + SHA256SUMS verification | Integrity but no authenticity |
| 5 | Official `curl \| sh` from project-controlled HTTPS domain | Transport security only |
| 6 | Third-party scripts, mirrors, SourceForge | **Never** |

## Common patterns

```sh
# uv (gold standard: SLSA signed)
brew install uv
gh attestation verify "$(brew --prefix uv)/bin/uv" --owner astral-sh
# Note: brew compiles uv from source via `cargo install`, so the local SHA
# won't match upstream attestation. 404 here is by design; verify the
# downloaded *release artifact* instead when CI/Docker matters.

# just (Rust binary, SHA256SUMS but no signing)
brew install just
# Or from source: cargo install --locked just

# pnpm
brew install pnpm
# Or: npm install -g pnpm@<verified-version>

# Tools without Homebrew formula
VERSION=<verified-version>
curl -LO "https://github.com/example/tool/releases/download/v${VERSION}/tool-linux-x86_64.tar.gz"
curl -LO "https://github.com/example/tool/releases/download/v${VERSION}/SHA256SUMS"
shasum --algorithm 256 --ignore-missing --check SHA256SUMS
tar xzf "tool-linux-x86_64.tar.gz" -C ~/.local/bin
```

## Never

```sh
# DON'T: arbitrary curl|sh from redirect chain
curl https://get.example.com | sh

# DON'T: trust an unknown PPA / tap / repo
sudo add-apt-repository ppa:random-user/random-stuff
```

## For tools that lack signing (Maestro, some vendor CLIs)

```sh
# 1. Inspect script first
curl -fsSL "https://get.example.com/install.sh" -o /tmp/install.sh
less /tmp/install.sh   # actually read it
# 2. Run only after review
bash /tmp/install.sh
```
