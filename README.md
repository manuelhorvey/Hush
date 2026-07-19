# Hush

Hush is a privacy-first communication platform built around temporary, end-to-end encrypted conversations. The product principle is simple: digital conversations should be private by default, temporary by design, and able to end cleanly.

This repository is currently in Phase 0: foundation and architecture. Coding should begin only after the stack, repository structure, architecture docs, security baseline, Figma foundation, and first sprint definition are in place.

## Phase 0 Stack

| Layer | Technology |
| - | - |
| Mobile | Flutter |
| Language | Dart |
| Backend | Rust |
| API framework | Axum |
| Database | PostgreSQL |
| Cache | Redis |
| Realtime | WebSockets |
| Queue | NATS |
| Containers | Docker |
| CI/CD | GitHub Actions |
| Cloud target | AWS |
| Monitoring | OpenTelemetry |

## Planned Repository Layout

```text
Hush/
├── apps/
│   └── mobile/
├── services/
│   ├── gateway/
│   ├── auth/
│   ├── identity/
│   ├── messaging/
│   └── lifecycle/
├── packages/
│   ├── crypto/
│   └── shared/
├── database/
│   └── migrations/
├── infrastructure/
│   ├── docker/
│   ├── terraform/
│   └── kubernetes/
├── docs/
│   ├── architecture/
│   ├── security/
│   ├── product/
│   └── decisions/
├── scripts/
├── tests/
└── README.md
```

## Documentation

- Product foundation: `docs/product/`
- Architecture and implementation plans: `docs/architecture/`
- Security, privacy, and threat model: `docs/security/`
- Architecture and stack decisions: `docs/decisions/`

## Sprint 1 Target

Sprint 1 should create the first runnable foundation:

- Rust workspace with an Axum gateway service.
- `GET /health` returning `{ "status": "ok" }`.
- Flutter mobile shell with splash, welcome, and empty home screens.
- Docker Compose with PostgreSQL, Redis, and backend service.
- Development instructions and baseline security rules.

The first commit after project initialization should be:

```text
chore: initialize Hush project foundation
```
