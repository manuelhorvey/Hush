# Development Setup

This repository is in foundation setup. The initial runtime target is:

- Flutter mobile app in `apps/mobile`
- Rust backend workspace under `services`
- PostgreSQL, Redis, and NATS via Docker Compose

## Local Environment

Copy `.env.example` to `.env` when local development begins and adjust values as needed.

## Infrastructure

Start the local stack:

```text
docker compose up
```

The same baseline Compose file is mirrored at `infrastructure/docker/docker-compose.yml` for infrastructure-specific organization.

The gateway should expose:

```text
GET http://localhost:8080/health
```

Expected response:

```json
{
  "status": "ok"
}
```

## Toolchains

Install:

- Rust stable
- Flutter stable
- Docker

Current backend workspace settings:

- Rust edition: 2021
- Minimum Rust version: 1.80
- Gateway framework: Axum
