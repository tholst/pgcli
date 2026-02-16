# syntax=docker/dockerfile:1.7
FROM python:3.12.8-slim-bookworm@sha256:2199a62885a12290dc9c5be3ca0681d367576ab7bf037da120e564723292a2f0

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PATH="/opt/venv/bin:${PATH}"

# Create non-root runtime identity with stable UID/GID.
RUN groupadd --system --gid 10001 pgcli \
    && useradd --system --uid 10001 --gid 10001 --home /home/pgcli --create-home --shell /usr/sbin/nologin pgcli

WORKDIR /app

COPY requirements.lock /app/requirements.lock

# Hash-verified, fully pinned dependency install.
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --require-hashes --only-binary=:all: -r /app/requirements.lock \
    && rm -rf /root/.cache

USER 10001:10001
WORKDIR /home/pgcli

ENTRYPOINT ["pgcli"]
