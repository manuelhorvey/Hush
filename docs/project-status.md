# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 4 is active. See `docs/product/sprint-4-definition.md`.

Latest pushed commit: `bea456b feat: add identity service and key generation`

## What Is Done

- Phase 0 foundation docs and repository scaffolding.
- Rust workspace with Axum gateway (`GET /health`), Dockerfiles, CI.
- Auth service at `services/auth` (register, login, session validation).
- Identity service at `services/identity` (device registration/challenge/verify with Ed25519).
- Flutter app with Splash, Welcome, Create Identity, Login, Home, Devices screens.
- Ed25519 key generation via `cryptography` package.
- Session persistence with `flutter_secure_storage`.
- CI: Rust format/check/test + Flutter analyze/test.

### Sprint 4 (this commit)

- Messaging service at `services/messaging`:
  - `POST /api/v1/conversations` — create a conversation between two users.
  - `GET /api/v1/conversations` — list authenticated user's conversations.
  - `POST /api/v1/conversations/{id}/messages` — send an encrypted message.
  - `GET /api/v1/conversations/{id}/messages` — fetch messages.
  - `GET /api/v1/users/search?q=` — find users by username.
  - Database migrations for `conversations` and `messages` tables.
  - Dockerfile and `compose.yaml` service definition.
- Flutter screens:
  - **New Conversation** screen with username search.
  - **Chat** screen with message bubbles, compose bar, and polling.
  - **Home** screen now lists conversations with a FAB to start new ones.
  - Messages encrypted (base64 placeholder) client-side before sending.

## What Is In Progress

(none)

## Next Product Work After Sprint 4

Add real E2EE using X25519 key exchange, WebSocket for real-time delivery, and
message sync across devices.
