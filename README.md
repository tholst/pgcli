# pgcli container (hardened, self-published)

This repository builds and publishes a hardened `pgcli` image intended to replace `nixery.dev/shell/pgcli` usage with an image we control and consume by immutable digest.

## Security and reproducibility controls

- Base image pinned by immutable digest in `Dockerfile`.
- Python dependencies fully pinned and hash-locked in `requirements.lock`.
- Install enforces hash verification: `pip install --require-hashes`.
- Install enforces wheels only (`--only-binary=:all:`) to avoid runtime source builds.
- Runtime user is non-root (`uid=10001`, `gid=10001`).
- Deterministic entrypoint is `pgcli`.
- Production usage examples reference digest only (`repo@sha256:...`), not mutable tags.

## Repository contents

- `Dockerfile`: hardened image definition
- `requirements.in`: top-level Python dependency intent
- `requirements.lock`: fully pinned, hash-locked dependency graph
- `scripts/update-lock.sh`: regenerate `requirements.lock` safely
- `scripts/get-dockerhub-digest.sh`: resolve digest for Docker Hub base tags

## Build image

Set your image location (example GHCR namespace):

```bash
export IMAGE=ghcr.io/<org-or-user>/pgcli
export VERSION=4.3.0-r1
```

Build a local image:

```bash
docker build --pull --platform linux/amd64 -t "$IMAGE:$VERSION" .
```

## Verify locally

1. Verify `pgcli` runs:

```bash
docker run --rm "$IMAGE:$VERSION" --version
```

2. Verify container is non-root:

```bash
docker run --rm --entrypoint id "$IMAGE:$VERSION" -u
# expected: 10001
```

3. Optional shell check:

```bash
docker run --rm --entrypoint id "$IMAGE:$VERSION"
# expected includes uid=10001 gid=10001
```

## Publish to GHCR

Authenticate to GHCR first (`docker login ghcr.io`). Then push:

```bash
docker push "$IMAGE:$VERSION"
```

## Get immutable digest after publish

```bash
docker buildx imagetools inspect "$IMAGE:$VERSION" --format '{{json .Manifest.Digest}}'
```

or:

```bash
docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE:$VERSION"
```

Expected form:

```text
ghcr.io/<org-or-user>/pgcli@sha256:<digest>
```

## Consume by digest only

Use immutable digest references operationally:

```bash
kubectl run pgcli --rm -it --restart=Never \
  --image=ghcr.io/<org-or-user>/pgcli@sha256:<digest> -- \
  --host "$DB_HOST" --port 5432 --username "$DB_USER" "$DB_NAME"
```

Do not use mutable tags in production manifests.

## Dependency update process (safe)

1. Edit `requirements.in` (for example, bump `pgcli`).
2. Regenerate lock + hashes:

```bash
./scripts/update-lock.sh
```

3. Review lockfile diff for unexpected transitive changes.
4. Rebuild and run verification checklist.
5. Publish new image version.
6. Roll out by updating downstream digest references only.

## Base image digest update process

Resolve newest digest for chosen base tag:

```bash
./scripts/get-dockerhub-digest.sh library/python 3.12.8-slim-bookworm
```

Update the `FROM ...@sha256:...` line in `Dockerfile`, then rebuild, verify, publish, and roll out by digest.

## Versioning guidance

- Track upstream app version in image version (example: `4.3.0-r1`, `4.3.0-r2`).
- Bump `rN` for packaging-only/security changes when `pgcli` version stays the same.
- Bump major/minor when `pgcli` major/minor changes.

## Release checklist

1. Update `requirements.in` and regenerate `requirements.lock`.
2. Optionally refresh base digest.
3. Build image.
4. Verify:
   - `pgcli --version` works
   - runtime uid is non-root (`10001`)
5. Push image.
6. Record the pushed digest.
7. Update downstream consumers to `repo@sha256:<digest>`.

## Remaining trust assumptions and risks

- Trust in base image publisher (`library/python`) and Docker Hub registry integrity.
- Trust in PyPI package availability/signing model and TLS transport.
- Reproducibility depends on wheel availability for target platform.
- Digest pinning prevents tag drift but does not itself provide provenance/signature verification.

Recommended next hardening steps:

1. Sign published images (for example, cosign keyless or key-backed signing).
2. Emit and store SLSA/in-toto provenance attestations.
3. Generate and scan SBOMs (for example, syft/grype or Trivy).
4. Enforce admission policy (for example, Kyverno/Gatekeeper) to allow only signed, digest-pinned images.
