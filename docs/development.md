# Development Setup

This repository is in foundation setup. The initial runtime target is:

- Flutter mobile app in `apps/mobile`
- Rust backend workspace under `services`
- PostgreSQL, Redis, and NATS via Docker Compose

## Local Environment

Copy `.env.example` to `.env` when local development begins and adjust values as needed.

## Infrastructure

Start local dependencies from the Docker folder:

```text
docker compose up
```

The same baseline Compose file is mirrored at `infrastructure/docker/docker-compose.yml` for infrastructure-specific organization.

## Toolchains

Install:

- Rust stable
- Flutter stable
- Docker

Specific pinned versions should be added when implementation begins.
