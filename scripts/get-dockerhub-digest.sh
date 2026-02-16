#!/usr/bin/env bash
set -euo pipefail

image_ref="${1:-library/python}"
tag="${2:-3.12.8-slim-bookworm}"

scope="repository:${image_ref}:pull"
token="$(curl -fsSL "https://auth.docker.io/token?service=registry.docker.io&scope=${scope}" | sed -E 's/.*"token":"([^"]+)".*/\1/')"

digest="$(curl -fsSI \
  -H "Authorization: Bearer ${token}" \
  -H 'Accept: application/vnd.oci.image.manifest.v1+json' \
  "https://registry-1.docker.io/v2/${image_ref}/manifests/${tag}" \
  | awk -F': ' 'tolower($1)=="docker-content-digest" {print $2}' \
  | tr -d '\r')"

if [[ -z "${digest}" ]]; then
  echo "failed to resolve digest for ${image_ref}:${tag}" >&2
  exit 1
fi

echo "${image_ref}:${tag}@${digest}"
