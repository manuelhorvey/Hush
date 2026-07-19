# Contributing

Hush is currently in Phase 0 foundation setup. Contributions should preserve the security and privacy model before adding feature surface.

## Branches

- `main`: protected release-ready branch.
- `develop`: integration branch once active development starts.
- `feature/*`: feature work.
- `security/*`: security-sensitive changes.

## Commit Types

Use concise conventional prefixes:

- `feat:`
- `fix:`
- `security:`
- `docs:`
- `test:`
- `refactor:`
- `chore:`

Example:

```text
security: implement device key storage
```

## Before Opening Changes

- Confirm no plaintext messages, secrets, keys, or tokens are logged.
- Update relevant docs when architecture, security, or setup changes.
- Add tests for security-sensitive behavior once implementation begins.
