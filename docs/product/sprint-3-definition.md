# Sprint 3 Definition

## Duration

2 weeks.

## Goal

Replace placeholder key generation with real Ed25519 keypairs, register devices with the server, and add identity verification via challenge-response so that two users can verify each other's identity.

## Backend Tasks

1. Create `services/identity` — a new Axum crate for identity management.
2. Add `POST /api/v1/identity/devices` — accepts user_id, device_name, public_key; returns device_id.
3. Add `GET /api/v1/identity/devices` — lists devices for the authenticated user.
4. Add `POST /api/v1/identity/challenge` — generates a random challenge for a target user.
5. Add `POST /api/v1/identity/verify` — accepts a signed challenge, returns verification result.
6. Add database migration for `devices` table (id, user_id, device_name, public_key, created_at).
7. Add session-based auth middleware (reusable from the gateway).
8. Wire identity service into `compose.yaml`.

## Mobile Tasks

1. Add `ed25519` or `cryptography` Dart package for key generation.
2. Generate a real Ed25519 keypair on first launch (store private key in secure storage, public key in the register flow).
3. Update the register flow to pass the real public key instead of a placeholder.
4. Add a **Settings / My Devices** screen showing registered devices.
5. Add a **Verify Contact** screen (scan QR / compare fingerprints).
6. Show a fingerprint (public key hash) on the profile for visual comparison.

## Infrastructure Tasks

1. Add migration directory for the identity service.
2. Ensure sessions are reusable across services (shared token validation).

## Documentation Tasks

1. Update `docs/project-status.md`.
2. Update `docs/architecture/backend-architecture.md` to include the identity service.
3. Document the challenge-response verification flow.

## Success Criteria

- A real Ed25519 keypair is generated on device during registration.
- The public key is sent to the server and stored in the `devices` table.
- The device registration endpoint returns a device ID.
- A challenge can be requested and signed responses verified.
- `cargo test --workspace` and `flutter test` both pass.
- `docker compose config` is valid.
