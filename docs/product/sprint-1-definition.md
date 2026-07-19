# Sprint 1 Definition

## Duration

2 weeks.

## Goal

Create the foundation of Hush and launch the first working mobile shell.

## Backend Tasks

1. Create Rust workspace.
2. Create `services/gateway`.
3. Create Axum API server.
4. Add health endpoint.
5. Add configuration system.
6. Add structured logging.

Health endpoint:

```text
GET /health
```

Response:

```json
{
  "status": "ok"
}
```

## Mobile Tasks

Create the Flutter application with:

- Splash screen
- Welcome screen
- Empty home screen

## Infrastructure Tasks

Create Docker Compose with:

- PostgreSQL
- Redis
- Backend gateway

## Documentation Tasks

Keep these current:

- `README.md`
- `docs/architecture/system-overview.md`
- `docs/security/security-baseline.md`

## Success Criteria

At the end of Sprint 1:

- `docker compose up` starts local backend dependencies and gateway.
- `flutter run` opens the mobile app.
- The repository contains architecture docs, security rules, and development instructions.
