# pgcli Docker Image

A minimal, reproducible Docker image for [pgcli](https://www.pgcli.com/) — a powerful PostgreSQL terminal client with auto-completion.

## Features

- Non-root runtime
- Pinned dependencies for reproducibility
- Runs as single binary (`pgcli`)

## Quick Start

```bash
docker run -it --rm ghcr.io/tholst/pgcli:latest --host $DB_HOST --port 5432 -U $DB_USER $DB_NAME
```

## Building

Images are built for **linux/amd64** and **linux/arm64** (Apple Silicon) so the same tag works everywhere.

```bash
export IMAGE=ghcr.io/tholst/pgcli
export VERSION=4.3.0-r1

# Full release: build native (for test), verify, then build & push multi-platform
make release IMAGE="$IMAGE" VERSION="$VERSION"

# Or step by step:
make build-native IMAGE="$IMAGE" VERSION="$VERSION"  # local build for testing
make test        IMAGE="$IMAGE" VERSION="$VERSION"
make build       IMAGE="$IMAGE" VERSION="$VERSION"  # multi-platform build & push
make digest      IMAGE="$IMAGE" VERSION="$VERSION"
```

## Usage Examples

**kubectl (Kubernetes):**
```bash
kubectl run pgcli --rm -it --restart=Never \
  --image=ghcr.io/tholst/pgcli@sha256:<digest> -- \
  --host "$DB_HOST" --port 5432 --username "$DB_USER" "$DB_NAME"
```

**Docker Compose:** Add to your services:
```yaml
pgcli:
  image: ghcr.io/tholst/pgcli:latest
  stdin_open: true
  tty: true
  command: ["--host", "db", "--port", "5432", "-U", "postgres", "mydb"]
```

## Versioning

Image tags mirror pgcli versions plus an optional revision:

| Tag | Meaning |
|-----|---------|
| `4.3.0` | pgcli 4.3.0, first build |
| `4.3.0-r1` | pgcli 4.3.0, first revision (packaging/base image fixes) |
| `4.3.0-r2` | Same pgcli, second revision |
| `4.3.1` | pgcli 4.3.1 upgrade |
| `latest` | Latest release (convenience, avoid in production) |

When pgcli gets a new release, bump the version in `requirements.in` and `Makefile` (VERSION). When you rebuild the same pgcli version (e.g. base image or lockfile update), bump the `-rN` suffix.

## Updating Dependencies

**Manual:**
1. Edit `requirements.in` (bump pgcli version if upgrading)
2. Run `make update`
3. Run `make release` to build, test, push, and print the digest

**Automatic (upgrade to latest pgcli):**
```bash
make release-latest
```
Fetches the latest pgcli from PyPI, updates requirements, regenerates the lockfile, and runs the full release.

**GitHub Actions:** A workflow runs weekly (Mondays) and on manual trigger to check for new pgcli versions, build, and push. It also commits updated `requirements.in` and `requirements.lock` when upgrading.
