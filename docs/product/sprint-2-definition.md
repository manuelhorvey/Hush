# Sprint 2 Definition

## Duration

2 weeks.

## Goal

Deliver the first complete end-to-end user journey: register a new identity from the mobile app through the backend, with session tokens persisted securely on device.

## Backend Tasks

1. Create `services/auth` — a new Axum crate in the Rust workspace.
2. Add `POST /api/v1/auth/register` — accepts username and public key, returns user ID and session token.
3. Add `POST /api/v1/auth/login` — accepts username, returns new session token.
4. Add `GET /api/v1/auth/session` — validates session token and returns current user info.
5. Add database migrations for `users` and `sessions` tables (via `sqlx`).
6. Wire auth service into the gateway (route prefix) and `compose.yaml`.
7. Add session token middleware for authenticated routes.

## Mobile Tasks

1. Add `http` and `flutter_secure_storage` packages to the Flutter app.
2. Create an API client module targeting the gateway.
3. Replace the welcome flow with a **Create Identity** screen:
   - Username input field
   - "Create Identity" button
   - Calls `POST /api/v1/auth/register`
   - Stores session token in secure storage
   - Navigates to home on success
4. Add a **Login** screen accessible from the create-identity screen:
   - Username input
   - "Login" button
   - Calls `POST /api/v1/auth/login`
   - Stores session token
   - Navigates to home on success
5. Add basic error handling (network failure, duplicate username).

## Infrastructure Tasks

1. Add `sqlx-cli` for database migration management.
2. Ensure PostgreSQL is reachable from the auth service in `compose.yaml`.
3. Add a `.env` file for local database connection string.

## Documentation Tasks

1. Update `docs/project-status.md` with Sprint 2 progress.
2. Update `docs/architecture/backend-architecture.md` to include the auth service.
3. Document migration workflow in `docs/development.md`.

## Success Criteria

- `POST /api/v1/auth/register` returns a session token for a new user.
- `POST /api/v1/auth/login` returns a session token for an existing user.
- A user can register from the Flutter app, get a session, and land on the home screen.
- `docker compose up` starts the gateway + auth service + PostgreSQL.
- `cargo test --workspace` and `flutter test` both pass.
