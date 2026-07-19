# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 3 is active. See `docs/product/sprint-3-definition.md`.

Latest pushed commit:

```text
9934da7 feat: add auth service and identity flow
```

## What Is Done

- Phase 0 foundation docs and repository scaffolding.
- Rust workspace with Axum gateway (`GET /health`), Dockerfiles, CI.
- Auth service at `services/auth` (register, login, session validation).
- Identity service at `services/identity`:
  - Device registration (`POST /api/v1/identity/devices`).
  - Device listing (`GET /api/v1/identity/devices`).
  - Challenge creation (`POST /api/v1/identity/challenge`).
  - Challenge verification (`POST /api/v1/identity/verify`) with Ed25519 sig check.
  - Dockerfile and `compose.yaml` service definition.
- Flutter app with:
  - Splash, Welcome, Create Identity, Login, Home screens.
  - Real Ed25519 keypair generation via `cryptography` package.
  - Device registration during identity creation.
  - "My Devices" screen listing registered devices.
  - `flutter_secure_storage` for keys and session tokens.
  - Session persistence and auto-login.
- CI: Rust format/check/test + Flutter analyze/test.

## What Is In Progress

The Sprint 3 identity service + key generation + devices screens is currently
uncommitted. Commit it with:

```text
feat: add identity service and key generation
```

## Next Product Work After Sprint 3

Continue into secure messaging as defined in the engineering roadmap
(`docs/architecture/Engineering Execution Roadmap.md`).
