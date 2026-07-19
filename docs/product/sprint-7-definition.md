# Sprint 7 Definition

## Duration

2 weeks.

## Goal

Group messaging — multi-participant conversations with E2EE group key distribution.

## Backend Tasks

1. Replace `creator_id` / `participant_id` columns with a `conversation_participants` join table.
2. Migration: create `conversation_participants(conversation_id, user_id)` and migrate existing rows.
3. Create `conversation_keys(conversation_id, user_id, encrypted_key)` table for group key distribution.
4. `POST /api/v1/conversations` — accept an array of `participant_ids` (2+ users), generate a random group AES-256 key, encrypt it with each participant's X25519 public key, store encrypted keys.
5. `GET /api/v1/conversations/{id}/key` — return the encrypted group key for the authenticated user (so they can decrypt it with their private key).
6. `GET /api/v1/conversations/{id}/participants` — list participants.
7. Update `send_message` / `list_messages` to work with multi-participant conversations.
8. Push notifications to all active participants (not just the single recipient).

## Mobile Tasks

1. `NewConversationScreen` — allow selecting multiple users (checkboxes).
2. `ConversationCard` — show participant count and avatars.
3. `ChatScreen` — fetch encrypted group key on open, decrypt with X25519 private key, use group key for AES-GCM.
4. `ChatScreen` — show participant list in app bar.
5. `CryptoService` — add `generateGroupKey()`, `encryptGroupKey(publicKeyBase64, groupKey)`, `decryptGroupKey(privateKey, encryptedKey)`.

## Success Criteria

- Group conversations with 3+ participants can be created.
- All participants can decrypt messages using the shared group key.
- New messages are pushed to all participants via WebSocket.
- `cargo test --workspace` and `flutter test` pass.
- `docker compose config` is valid.
