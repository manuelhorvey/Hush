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
