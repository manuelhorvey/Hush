# Project Status

Last updated: 2026-07-19

## Current Phase

Sprint 1 has started. Phase 0 foundation docs and repository scaffolding are already committed and pushed to `origin/main`.

Latest pushed commit:

```text
7395207 chore: initialize Hush project foundation
```

## What Is Done

- Git repository initialized on `main`.
- Remote configured: `git@github.com:manuelhorvey/Hush.git`.
- Phase 0 documentation organized under:
  - `docs/architecture/`
  - `docs/security/`
  - `docs/product/`
  - `docs/decisions/`
- Root foundation files added:
  - `README.md`
  - `.gitignore`
  - `.editorconfig`
  - `.env.example`
  - `SECURITY.md`
  - `CONTRIBUTING.md`
  - `LICENSE`
- Project skeleton added:
  - `apps/mobile/`
  - `services/`
  - `packages/`
  - `database/`
  - `infrastructure/`
  - `scripts/`
  - `tests/`
- Docker Compose baseline added for PostgreSQL, Redis, and NATS.
- GitHub Actions foundation check added.

## What Is In Progress

Sprint 1 backend gateway foundation is currently uncommitted work.

Current gateway scope:

- Rust workspace at root `Cargo.toml`.
- Axum gateway crate at `services/gateway`.
- `GET /health` endpoint returning:

```json
{
  "status": "ok"
}
```

- Environment-based gateway config:
  - `GATEWAY_HOST`
  - `GATEWAY_PORT`
- Structured tracing setup.
- Dockerfile for the gateway service.
- Gateway wired into root `compose.yaml`.
- CI updated to run Rust format, check, and tests.

## Current Blocker

Rust was not installed locally when the gateway work started, so host-side validation could not run yet.

Install Rust with:

```text
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

Then verify:

```text
rustc --version
cargo --version
```

## Next Validation Commands

Run these from the repository root after Rust is installed:

```text
cargo fmt --all -- --check
cargo check --workspace --all-targets
cargo test --workspace
docker compose config
```

If those pass, start the local stack:

```text
docker compose up --build
```

Then check:

```text
curl http://localhost:8080/health
```

Expected response:

```json
{
  "status": "ok"
}
```

## Next Commit

After validation, commit the gateway slice:

```text
feat: add gateway service foundation
```

Then push:

```text
git push
```

## Next Product Work After Gateway

Once the gateway is committed, continue Sprint 1 with the mobile shell:

- Create Flutter app in `apps/mobile`.
- Add splash, welcome, and empty home screens.
- Add basic navigation structure.
- Add Flutter analyze/test steps to CI.
