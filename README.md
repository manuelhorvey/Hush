# Hush

Hush is a privacy-first communication platform built around temporary, end-to-end encrypted conversations. Digital conversations should be private by default, temporary by design, and able to end cleanly.

## Architecture

```text
Hush/
├── apps/
│   └── mobile/              # Flutter cross-platform mobile app
├── services/
│   ├── gateway/             # WebSocket gateway (:8080)
│   ├── auth/                # Authentication service (:8081)
│   ├── identity/            # Identity & key management (:8082)
│   └── messaging/           # Conversation & message API (:8083)
├── packages/
│   ├── crypto/              # Shared crypto primitives
│   └── shared/              # Shared types & utilities
├── database/
│   └── migrations/          # PostgreSQL migrations
├── infrastructure/
│   ├── docker/              # Dockerfiles for each service
│   └── terraform/           # AWS provisioning
├── docs/
│   ├── architecture/        # System design docs
│   ├── security/            # Threat model & security baseline
│   ├── product/             # Product specs & Figma foundation
│   └── decisions/           # Architecture Decision Records
├── scripts/                 # Dev & CI helper scripts
├── tests/                   # Integration & smoke tests
├── compose.yaml             # Local dev environment
└── Makefile                 # Dev workflow targets
```

## Stack

| Layer | Technology |
| - | - |
| Mobile | Flutter / Dart |
| Backend | Rust (Axum) |
| Database | PostgreSQL |
| Realtime | WebSockets (gateway service) |
| E2E Encryption | X25519 ECDH + Double Ratchet + AES-256-GCM |
| Message Queue | NATS |
| Containers | Docker Compose |
| CI/CD | GitHub Actions |
| Monitoring | OpenTelemetry |

## Quick Start

```bash
# Start all backend services
make dev

# Run mobile app
cd apps/mobile && flutter run

# Run full CI check (Rust + Flutter)
make check
```

Check the stack is healthy:

```bash
curl http://localhost:8080/health
```

## Features

| Feature | Status | Details |
| - | - | - |
| **Ephemeral conversations** | ✅ | Create, complete, destroy lifecycle |
| **E2E encryption** | ✅ | X25519 ECDH + Double Ratchet per-message key ratcheting, AES-256-GCM, forward secrecy |
| **Group conversations** | ✅ | Group key exchange at creation, encrypted per participant |
| **Real-time messaging** | ✅ | WebSocket with auto-reconnect & exponential backoff |
| **Identity & device management** | ✅ | Register devices, verify identity via challenge-response |
| **Offline support** | ✅ | Local caching, pending message queue, connectivity monitoring |
| **User search** | ✅ | Search users by name to start conversations |
| **Verification** | ✅ | Out-of-band phrase comparison to mark identities as trusted |
| **Responsive UI** | ✅ | Adaptive shell (bottom nav / nav rail), constrained desktop layouts |

## Development

### Backend

```bash
make dev          # docker compose up -d
make logs         # tail all service logs
make rust-check   # cargo check
make rust-test    # cargo test
make rust-fmt     # cargo fmt --check
```

### Mobile

```bash
make mobile-get      # flutter pub get
make mobile-analyze  # flutter analyze
make mobile-test     # flutter test
```

### Full CI

```bash
make ci  # fmt → check → test → analyze → test
```

## Security Model

Hush uses a **zero-trust, ephemeral key** model:

- Each device generates an Ed25519 identity keypair and an X25519 key exchange keypair on first launch.
- Public exchange keys are registered with the identity service.
- 1:1 messages use the **Double Ratchet** protocol ([Signal spec](https://signal.org/docs/specifications/doubleratchet/)): X25519 ECDH shared secret bootstraps the session, then per-message key ratcheting provides forward secrecy and future-compromise resistance. Sessions are persisted to secure storage and survive app restarts.
- Group conversations use a group key encrypted per-participant via X25519 ECDH (group key exchange is out of scope for Double Ratchet ratcheting).
- Conversations have a lifecycle: `active → completed → destroyed`. Completed conversations are preserved until explicitly destroyed; destroyed conversations are permanently deleted.
- Identity verification uses out-of-band phrase comparison — both parties see the same phrase and confirm they match.

## Documentation

- [System overview](docs/architecture/system-overview.md)
- [Backend architecture](docs/architecture/backend-architecture.md)
- [Security model](docs/architecture/security-model.md)
- [Data flow](docs/architecture/data-flow.md)
- [Deployment](docs/architecture/deployment.md)
- [Security baseline](docs/security/security-baseline.md)
- [Architecture decisions](docs/decisions/0001-final-technology-stack.md)
- [Sprint 1 definition](docs/product/sprint-1-definition.md)
