# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 5 is active. See `docs/product/sprint-5-definition.md`.

## What Is Done

- Phase 0 foundation docs and repository scaffolding.
- Rust workspace with Axum gateway, Dockerfiles, CI.
- Auth service (register, login, session validation).
- Identity service (device registration/challenge/verify, exchange keys).
- Messaging service (conversations, messages, user search).
- Flutter app with Splash, Welcome, Create Identity, Login, Home, Devices, New Conversation, Chat screens.
- Ed25519 key generation + X25519 key exchange via `cryptography` package.
- Session persistence with `flutter_secure_storage`.

### Sprint 5 (this commit)

- **X25519 E2EE:**
  - X25519 keypair generated during registration, stored in `flutter_secure_storage`.
  - Public key uploaded via `POST /api/v1/identity/keys/exchange`.
  - X25519 key agreement derives a shared secret for each conversation.
  - AES-GCM-256 encrypts message plaintext before sending; decrypts on receive.
- **WebSocket real-time delivery:**
  - Gateway `GET /ws?token=` upgrades to WebSocket with session validation.
  - In-memory connection registry maps `userId -> Sender`s.
  - Messaging service calls `POST /_internal/push` after storing a message.
  - Gateway forwards push to the recipient's WebSocket connection.
  - Chat screen shows Connected/Offline indicator.
  - Automatic reconnection on disconnect.
- **New identity endpoints:**
  - `POST /api/v1/identity/keys/exchange` — store X25519 public key (upsert).
  - `GET /api/v1/identity/keys/exchange/:user_id` — fetch another user's X25519 public key.
- **Dockerfile fix:** All services copy entire `services/` directory for workspace resolution.

## What Is In Progress

(none)

## Next Product Work After Sprint 5

Message sync across devices, conversation lifecycle events, group messaging.
