# ADR 0001: Final Technology Stack

## Status

Accepted for Phase 0.

## Context

Hush is a security-sensitive, privacy-first messaging platform. The stack must support strong security practices, high concurrency, mobile velocity, hiring availability, and long-term platform growth.

## Decision

| Layer | Technology |
| - | - |
| Mobile | Flutter |
| Language | Dart |
| Backend | Rust |
| API framework | Axum |
| Async runtime | Tokio |
| Database | PostgreSQL |
| Cache | Redis |
| Realtime | WebSockets |
| Queue | NATS |
| Containers | Docker |
| CI/CD | GitHub Actions |
| Cloud target | AWS |
| Monitoring | OpenTelemetry |

## Rationale

Flutter gives Hush one mobile codebase for iOS and Android with a path toward desktop. Rust provides memory safety, performance, and strong concurrency for security-sensitive backend services. PostgreSQL and Redis are mature operational choices. NATS keeps event-driven architecture simple at the start while leaving room for Kafka later if volume requires it.

## Consequences

- Mobile development starts in `apps/mobile`.
- Backend development starts as a Rust workspace under `services`.
- Cryptographic code must use established libraries and remain isolated in clear security boundaries.
- Docker Compose should become the default local development path.
