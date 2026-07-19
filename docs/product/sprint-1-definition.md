# Sprint 1 Definition

## Duration

2 weeks.

## Goal

Create the foundation of Hush and launch the first working mobile shell.

## Backend Tasks

1. Create Rust workspace. Done.
2. Create `services/gateway`. Done.
3. Create Axum API server. Done.
4. Add health endpoint. Done.
5. Add configuration system. Done.
6. Add structured logging. Done.

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
