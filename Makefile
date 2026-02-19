SHELL := /usr/bin/env bash

IMAGE ?= ghcr.io/tholst/pgcli
VERSION ?= 4.3.0-r1
PLATFORMS ?= linux/amd64,linux/arm64
REF := $(IMAGE):$(VERSION)

.PHONY: help build build-native test publish digest release update pin-base check-latest release-latest

help:
	@echo "Usage: make <target> IMAGE=ghcr.io/tholst/pgcli VERSION=4.3.0-r1"
	@echo
	@echo "Targets:"
	@echo "  build        Build multi-platform image (amd64 + arm64)"
	@echo "  build-native Build for current platform only (faster iteration)"
	@echo "  test         Verify pgcli runs and container is non-root"
	@echo "  publish      Push image tag to registry"
	@echo "  digest       Print immutable image digest reference"
	@echo "  release      build-native + test + build (multi-platform) + digest"
	@echo "  update       Regenerate requirements.lock with hashes"
	@echo "  pin-base     Resolve current base-image digest"
	@echo "  check-latest  Print latest pgcli version on PyPI"
	@echo "  release-latest Upgrade to latest pgcli, rebuild lockfile, and release"
	@echo
	@echo "Set PLATFORMS=linux/amd64,linux/arm64 to customize build target."

build:
	docker buildx build --pull --platform "$(PLATFORMS)" -t "$(REF)" --push .

build-native:
	docker build --pull -t "$(REF)" .

test:
	docker run --rm "$(REF)" --version
	@test "$$(docker run --rm --entrypoint id "$(REF)" -u)" = "10001"
	@echo "Verified non-root uid=10001"

publish:
	docker push "$(REF)"

digest:
	@digest="$$(docker buildx imagetools inspect "$(REF)" --format '{{json .Manifest.Digest}}' | tr -d '"')"; \
	if [[ -z "$$digest" ]]; then \
		echo "Failed to resolve digest for $(REF)" >&2; exit 1; \
	fi; \
	echo "$(IMAGE)@$$digest"

release: build-native test build digest

update:
	./scripts/update-lock.sh

pin-base:
	./scripts/get-dockerhub-digest.sh library/python 3.12.8-slim-bookworm

check-latest:
	@curl -s https://pypi.org/pypi/pgcli/json | python3 -c "import sys,json; v=json.load(sys.stdin)['info']['version']; print('Latest pgcli on PyPI:', v)"

release-latest:
	./scripts/release-latest.sh
