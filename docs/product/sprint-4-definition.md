# Sprint 4 Definition

## Duration

2 weeks.

## Goal

Build the core messaging loop: create a conversation, exchange E2EE messages, and display them in a chat UI.

## Backend Tasks

1. Create `services/messaging` — a new Axum crate for conversations and messages.
2. Add `POST /api/v1/conversations` — create a conversation between two users (authenticated).
3. Add `GET /api/v1/conversations` — list the authenticated user's conversations.
4. Add `POST /api/v1/conversations/{id}/messages` — post an encrypted message to a conversation.
5. Add `GET /api/v1/conversations/{id}/messages` — fetch messages in a conversation.
6. Add database migrations for `conversations` and `messages` tables.
7. Add session-based auth middleware (reuse pattern from identity service).
8. Wire messaging service into `compose.yaml`.

## Mobile Tasks

1. Add a **New Conversation** screen (search/select user by username).
2. Add a **Chat** screen showing messages in a conversation.
3. Add a compose bar at the bottom of the chat for typing and sending messages.
4. Encrypt message plaintext with the conversation's shared key before sending.
5. Decrypt received ciphertext after fetching.
6. Link from Home screen to existing conversations and the "new conversation" button.
7. Basic polling for new messages (WebSocket to be added in a later sprint).

## Infrastructure Tasks

1. Add migration directory for the messaging service.
2. Ensure the messaging service shares the same PostgreSQL instance.

## Documentation Tasks

1. Update `docs/project-status.md`.
2. Update `docs/architecture/backend-architecture.md` to include the messaging service.

## Success Criteria

- Two users can be created and each can see the other.
- A conversation can be created between two users.
- A user can send a message that is stored encrypted in the database.
- The receiving user can fetch and display the decrypted message.
- `cargo test --workspace` and `flutter test` both pass.
- `docker compose config` is valid.
