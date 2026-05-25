# Ecosystem: Container images (Docker / OCI)

Use when `Dockerfile*` detected. Source: playbook §4.6.

## Pin base images to digests, not tags

```dockerfile
# WRONG: tag is mutable
FROM python:3.12-slim

# CORRECT: digest is immutable
FROM python:3.12-slim-bookworm@sha256:abc123def456...

# Refresh digests via Renovate's Docker manager.
```

## Multi-stage build with non-root runtime

```dockerfile
FROM python:3.12-slim-bookworm@sha256:abc... AS base
COPY --from=ghcr.io/astral-sh/uv:0.5.13@sha256:def... /uv /usr/local/bin/uv

WORKDIR /app
COPY uv.lock pyproject.toml ./
RUN uv sync --frozen --no-dev --no-install-project --no-build

COPY src ./src
RUN uv sync --frozen --no-dev --no-build

FROM python:3.12-slim-bookworm@sha256:abc... AS runtime
RUN useradd --create-home --shell /bin/bash --uid 10001 app
USER app
COPY --from=base --chown=app:app /opt/venv /opt/venv
COPY --from=base --chown=app:app /app /app
WORKDIR /app
EXPOSE 8000
CMD ["python", "-m", "my_api"]
```

## Reproducible build flags

```sh
docker build \
  --no-cache \
  --pull \
  --build-arg SOURCE_DATE_EPOCH=$(git log -1 --format=%ct) \
  -t myorg/myapp:${SHA} \
  -f Dockerfile .
```

## Sign with cosign (keyless via OIDC)

```sh
# CI
cosign sign --yes ${REGISTRY}/${IMAGE}@${DIGEST}

# Verify before deploy
cosign verify \
  --certificate-identity-regexp="https://github.com/${ORG}/.+/.github/workflows/.+" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ${REGISTRY}/${IMAGE}:latest
```

## Trivy on every push

```yaml
- name: Trivy scan
  uses: aquasecurity/trivy-action@915b19bbe73b92a6cf82a1bc12b087c9a19a5fe # v0.28.0
  with:
    image-ref: myorg/myapp:${{ github.sha }}
    format: sarif
    output: trivy-results.sarif
    severity: CRITICAL,HIGH
    exit-code: "1"
    ignore-unfixed: true
```

## Base image tradeoffs

| Image | Surface | Use when |
|---|---|---|
| `scratch` | None | Static binaries (Go, Rust). Best. |
| `distroless` (Google) | Minimal, no shell | Compiled binaries, Java, Python wheels-only |
| `*-slim-bookworm` (Debian slim) | Reduced Debian | Python apps needing some system libs |
| `alpine` | musl-based, smaller | Compiled languages tolerant of musl |
| Full `ubuntu` / `debian` | Large surface | Avoid for production runtime |
