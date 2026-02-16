SHELL := /usr/bin/env bash

IMAGE ?= ghcr.io/<org-or-user>/pgcli
VERSION ?= 4.3.0-r1
REF := $(IMAGE):$(VERSION)

.PHONY: help build test publish digest release update pin-base

help:
	@echo "Usage: make <target> IMAGE=ghcr.io/<org-or-user>/pgcli VERSION=4.3.0-r1"
	@echo
	@echo "Targets:"
	@echo "  build    Build container image"
	@echo "  test     Verify pgcli runs and container is non-root"
	@echo "  publish  Push image tag to registry"
	@echo "  digest   Print immutable image digest reference"
	@echo "  release  build + test + publish + digest"
	@echo "  update   Regenerate requirements.lock with hashes"
	@echo "  pin-base Resolve current base-image digest"

build:
	docker build --pull --platform linux/amd64 -t "$(REF)" .

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

release: build test publish digest

update:
	./scripts/update-lock.sh

pin-base:
	./scripts/get-dockerhub-digest.sh library/python 3.12.8-slim-bookworm
