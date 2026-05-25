# Ecosystem: Rust (Cargo)

Use when `Cargo.toml` detected. Source: playbook §4.3.

## `Cargo.toml` (binary-producing crates)

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2021"
rust-version = "1.85.0"   # exact MSRV pin; verified YYYY-MM-DD

[dependencies]
# Exact pins for security-relevant crates
serde = "=1.0.219"        # verified YYYY-MM-DD
tokio = "=1.42.0"
reqwest = { version = "=0.12.12", default-features = false, features = ["rustls-tls"] }
```

**Commit `Cargo.lock`.** Even for library crates (Cargo's default `.gitignore` advice changed in 2024; for security-conscious projects, always commit it).

## Install / build commands

```sh
# Install a CLI tool from crates.io with lockfile respect
cargo install --locked <crate>

# Build with lockfile respect (default behavior, but be explicit)
cargo build --locked

# Audit known vulnerabilities
cargo install --locked cargo-audit
cargo audit

# Deny unwanted licenses, advisories, and bans
cargo install --locked cargo-deny
cargo deny check advisories
cargo deny check licenses
cargo deny check bans
```

## `deny.toml` (cargo-deny config) at repo root

```toml
[advisories]
db-path = "~/.cargo/advisory-db"
db-urls = ["https://github.com/rustsec/advisory-db"]
vulnerability = "deny"
unmaintained = "warn"
yanked = "deny"
notice = "warn"

[licenses]
unlicensed = "deny"
allow = ["MIT", "Apache-2.0", "Apache-2.0 WITH LLVM-exception", "BSD-3-Clause", "ISC", "Unicode-DFS-2016", "0BSD"]
copyleft = "deny"
confidence-threshold = 0.93

[bans]
multiple-versions = "warn"
wildcards = "deny"
# deny = [{ name = "openssl-sys" }]    # add specific bans here

[sources]
unknown-registry = "deny"
unknown-git = "deny"
allow-registry = ["https://github.com/rust-lang/crates.io-index"]
```

## Rust-specific risks

- **`build.rs` scripts run at compile time** with full host access (attack vector T6). Audit every direct dep's `build.rs` before adding.
- **Proc macros also execute at compile time.** Treat like `build.rs`.
- **`cargo install` without `--locked`** ignores `Cargo.lock` and resolves to latest compatible. Always use `--locked` in CI and Dockerfiles.
- **Crates with C/system-library bindings** (`*-sys`) link unaudited C code. Prefer pure-Rust alternatives when available.
