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

## Updating Dependencies

1. Edit `requirements.in`
2. Run `make update`
3. Rebuild and republish
