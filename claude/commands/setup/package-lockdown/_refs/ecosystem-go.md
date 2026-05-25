# Ecosystem: Go (go mod)

Use when `go.mod` detected. Source: playbook §4.4.

**Commit `go.sum`.** It's the lockfile equivalent.

## Commands

```sh
# Always pin to a specific version in go.mod (not @latest)
go install golang.org/x/tools/cmd/staticcheck@v0.5.1   # verified YYYY-MM-DD

# Verify checksums against the public sum database
go mod verify

# Audit known vulnerabilities (govulncheck is the official scanner)
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```

## Production / Docker env

```sh
GOFLAGS="-mod=readonly -trimpath -buildvcs=false"
GOPROXY=https://proxy.golang.org,direct
GOSUMDB=sum.golang.org
# NEVER set GONOSUMCHECK=* or GOSUMDB=off
```

## Go-specific pitfalls

- `go get` without a version specifier resolves to `@latest`. Always specify `@vX.Y.Z`.
- Private modules need `GOPRIVATE=github.com/your-org/*` so they don't leak to the public proxy.
- `init()` functions run at import time (effectively at compile time for tests/binaries). Treat like Rust `build.rs` for trust purposes.
