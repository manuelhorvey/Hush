# Sprint 5 Definition

## Duration

2 weeks.

## Goal

Replace placeholder "encryption" with real X25519 E2EE and add WebSocket push for instant message delivery.

## Backend Tasks

1. Add WebSocket endpoint to the gateway service: `GET /ws` (upgrade to WS, authenticate via token query param).
2. The gateway authenticates the WS connection, parses the user ID, and registers the connection in an in-memory `UserId -> Vec<Sender>` map.
3. After a message is stored in the messaging service, publish a notification to NATS (or directly to the gateway via HTTP) with the recipient ID and message metadata.
4. The gateway looks up the recipient's WebSocket connection and pushes the new message envelope.
5. Add `POST /api/v1/identity/keys/exchange` — store an X25519 public key alongside the existing Ed25519 key.
6. Add `GET /api/v1/identity/keys/:user_id/exchange` — fetch another user's X25519 public key.

## Mobile Tasks

1. Generate an X25519 keypair during registration (via `cryptography` package) and store the private key in `flutter_secure_storage`.
2. Upload the X25519 public key via the new endpoint.
3. When creating a conversation, perform X25519 key agreement with the other user's X25519 public key to derive a shared secret.
4. Derive an AES-GCM key from the shared secret (SHA-256 of the raw shared secret).
5. Encrypt message plaintext with AES-GCM before sending (`ciphertext` field).
6. Decrypt incoming ciphertext with the same derived key.
7. Connect to the WebSocket endpoint on app startup and listen for new message push events.
8. Update the chat screen to use push events instead of polling.
9. Show a "Connecting..." / "Connected" indicator in the app bar.

## Infrastructure Tasks

1. Add/generate X25519 key columns to the device registration (or a new `exchange_keys` table).
2. Ensure the gateway WebSocket port is exposed in `compose.yaml`.

## E2EE Key Exchange Detail

```
Mobile A                              Server                         Mobile B
  │                                      │                              │
  │ POST /identity/keys/exchange         │                              │
  │ { x25519_public_key }                │                              │
  │─────────────────────────────────────>│                              │
  │                                      │                              │
  │ GET /identity/keys/:user_b_id/exchange│                             │
  │<─────────────────────────────────────│                              │
  │                                      │                              │
  │ X25519 agree(A_priv, B_pub)          │                              │
  │ → shared_secret                      │                              │
  │ AES-GCM key = SHA-256(shared_secret) │                              │
  │                                      │                              │
  │ POST /conversations                  │                              │
  │ { participant_id: B }                │                              │
  │─────────────────────────────────────>│                              │
  │                                      │                              │
  │ POST /conversations/:id/messages     │                              │
  │ { ciphertext: AES-GCM(plaintext) }   │                              │
  │─────────────────────────────────────>│                              │
  │                                      │  WS push { message }         │
  │                                      │─────────────────────────────>│
  │                                      │                              │
  │                                      │  decrypt with derived key    │
```

## Success Criteria

- X25519 key exchange produces a shared secret known only to both participants.
- Messages sent from A are decryptable only by B (and vice versa).
- WebSocket delivers new messages within 500 ms (vs 3 s polling).
- `cargo test --workspace` and `flutter test` both pass.
- `docker compose config` is valid.
