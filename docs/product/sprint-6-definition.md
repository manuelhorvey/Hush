# Sprint 6 Definition

## Duration

2 weeks.

## Goal

Add the "Hush" lifecycle state machine — conversations transition through Active → Completed → Destroyed, with optional expiration timers.

## Backend Tasks

1. Add `status` column to `conversations` table (`'active'`, `'completed'`, `'destroyed'`).
2. Add `expires_at` column (nullable `TIMESTAMPTZ`).
3. New migration `002_add_conversation_status.sql`.
4. `PATCH /api/v1/conversations/{id}/complete` — set status to `completed`.
5. `DELETE /api/v1/conversations/{id}` — set status to `destroyed`, delete all messages.
6. `GET /api/v1/conversations` — exclude `destroyed` conversations, include `status` and `expires_at`.
7. Background Tokio task: every 30s, find conversations where `expires_at < NOW()` and destroy them.
8. Update Dockerfile / `compose.yaml` if needed.

## Mobile Tasks

1. Update `ConversationInfo` model with `status` and `expiresAt`.
2. Show status badge on home screen (active=green, completed=grey, destroyed=none).
3. Add "Complete" button in chat screen app bar (sets status to completed).
4. Add "Destroy" option (with confirmation dialog) — deletes conversation and all messages.
5. Show countdown timer if `expiresAt` is set.
6. Refresh conversation list after completing/destroying.

## Success Criteria

- Conversations can be completed and destroyed from the UI.
- Destroyed conversations disappear from the list and have messages deleted server-side.
- Expired conversations are auto-destroyed by the background task.
- `cargo test --workspace` and `flutter test` pass.
- `docker compose config` is valid.
