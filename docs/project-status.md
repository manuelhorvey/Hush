# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 6 is active. See `docs/product/sprint-6-definition.md`.

## What Is Done

- Phase 0 foundation docs and repository scaffolding.
- Rust workspace with Axum gateway, Dockerfiles, CI.
- Auth service (register, login, session validation).
- Identity service (device registration/challenge/verify, exchange keys).
- Messaging service (conversations, messages, user search, lifecycle).
- Flutter app with Splash, Welcome, Create Identity, Login, Home, Devices, New Conversation, Chat screens.
- Ed25519 key generation + X25519 key exchange + AES-GCM-256 E2EE via `cryptography` package.
- WebSocket real-time delivery with auto-reconnect.
- Session persistence with `flutter_secure_storage`.

### Sprint 6 (this commit)

- **Lifecycle state machine:**
  - `status` column on conversations: `active`, `completed`, `destroyed`.
  - `expires_at` column for auto-destruction timers.
  - `PATCH /api/v1/conversations/{id}/complete` — mark as completed.
  - `DELETE /api/v1/conversations/{id}` — destroy conversation and delete all messages.
  - `GET /api/v1/conversations` — excludes destroyed conversations, returns status/expires_at.
  - Background Tokio task runs every 30s, auto-destroys expired conversations.
  - New `expires_in_minutes` field on conversation creation.
- **Flutter lifecycle UI:**
  - Status badges on home screen (Active green, Completed grey).
  - "Complete" button in chat app bar — disables message input.
  - "Destroy" option in popup menu with confirmation dialog.
  - Chat screen returns `true` on destroy; home screen auto-refreshes the list.
  - Home screen refreshes on return from New Conversation screen.

## What Is In Progress

(none)

## Next Product Work After Sprint 6

Group messaging, cross-device sync, production hardening.
