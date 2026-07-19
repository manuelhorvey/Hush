# Backend Architecture

The backend is a coordinator of control, not a storehouse for content. It manages routing, identity metadata, lifecycle transitions, and operational safety while avoiding plaintext message access.

## Initial Services

| Service | Purpose |
| - | - |
| Gateway | Axum HTTP and WebSocket entry point |
| Auth | Session creation, validation, refresh, and revocation |
| Identity | User identity, public keys, device registration, device trust |
| Messaging | Encrypted payload relay and delivery acknowledgements |
| Lifecycle | Conversation creation, active state, completion, destruction events |

## Runtime

- Language: Rust
- Framework: Axum
- Async runtime: Tokio
- Database: PostgreSQL
- Cache and temporary state: Redis
- Internal queue: NATS
- Transport: HTTPS and WebSockets

### Messaging Service (`services/messaging`, port 8083)

- Runs its own embedded migrations on startup (inline SQL in `migrations/`).
- Shares the same PostgreSQL `hush` database.
- Endpoints:
  - `GET  /api/v1/users/search?q=` – find users by username (ILIKE).
  - `POST /api/v1/conversations` – create conversation between two users.
  - `GET  /api/v1/conversations` – list authenticated user's conversations.
  - `POST /api/v1/conversations/:id/messages` – store an encrypted message.
  - `GET  /api/v1/conversations/:id/messages` – fetch messages in order.
- Session auth via `Authorization: Bearer <token>` (validates against auth `sessions` table).
- Messages store opaque `ciphertext` — the server never sees plaintext.

## Sprint 1 Backend Scope

Sprint 1 should start with a gateway service only:

- Rust workspace.
- Axum server.
- Configuration loading.
- Structured logging.
- `GET /health`.

Expected response:

```json
{
  "status": "ok"
}
```
