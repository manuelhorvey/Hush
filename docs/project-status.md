# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 2 is active. See `docs/product/sprint-2-definition.md`.

Latest pushed commit:

```text
563b1c6 feat: add mobile shell foundation
```

## What Is Done

- Phase 0 foundation docs and repository scaffolding.
- Rust workspace with Axum gateway crate at `services/gateway` (`GET /health`).
- Environment-based config, structured tracing, Dockerfile, CI (fmt/check/test).
- Flutter mobile shell with splash, welcome, and empty home screens.
- Flutter CI (analyze/test) in GitHub Actions.
- Auth service at `services/auth`:
  - `POST /api/v1/auth/register` — creates user + returns session token.
  - `POST /api/v1/auth/login` — returns session token for existing user.
  - `GET /api/v1/auth/session` — validates token, returns user info.
  - PostgreSQL-backed `users` and `sessions` tables.
  - Dockerfile and `compose.yaml` service definition.
- Flutter app updated with:
  - Create Identity screen (username input, calls register).
  - Login screen (username input, calls login).
  - Session persistence via `flutter_secure_storage`.
  - Splash screen checks for existing session on startup.
  - API client module at `lib/services/`.

## What Is In Progress

The Sprint 2 auth service + Flutter identity flow is currently uncommitted.
Commit it with:

```text
feat: add auth service and identity flow
```

## Next Product Work After Sprint 2

Continue into trust establishment and messaging as defined in the engineering
roadmap (`docs/architecture/Engineering Execution Roadmap.md`).
