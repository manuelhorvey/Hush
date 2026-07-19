# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 7 is active. See `docs/product/sprint-7-definition.md`. (Sprint 6 shipped.)

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

### Sprint 6

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

### Sprint 7 (this commit)

- **Group support — backend (`services/messaging`):**
  - Migration `003_add_group_support.sql`: drops `participant_id` column, creates `conversation_participants` + `conversation_keys` tables.
  - Models rewritten: `ConversationInfo` has `List<ParticipantInfo> participants`; removed single `participant_id`.
  - `create_conversation` accepts `participant_ids: Vec<String>` and optional `encrypted_keys: HashMap<String, String>`.
  - `send_message` pushes to all participants (not just one).
  - `GET /conversations/{id}/key` — returns encrypted group key for authenticated user.
  - `GET /conversations/{id}/participants` — returns participant list.
- **Group support — Flutter:**
  - `CryptoService.generateGroupKey/encryptGroupKey/decryptGroupKey` — X25519-wrapped AES-256 group key.
  - `MessagingService` — `ConversationInfo` with `List<ParticipantInfo>`, `createConversation` takes `List<String> + Map<String,String>?`, new `getGroupKey/getParticipants`.
  - `NewConversationScreen` — multi-select checkboxes, fetches exchange keys for selected users, generates+encrypts group key, passes `encrypted_keys` to create.
  - `ChatScreen` — fetches/decrypts group key on load, uses group key for E2EE, shows participant list via popup menu.
  - `HomeScreen` — `_conversationTitle` helper shows other usernames for both 1-on-1 and group chats.

## What Is In Progress

(none)

## Next Product Work After Sprint 7

Cross-device sync, production hardening.
