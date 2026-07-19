# Security Policy

Hush is a privacy-first communication platform. Security issues should be treated as product-critical.

## Baseline Rules

- No plaintext messages outside user devices.
- Private keys never leave devices.
- Use established cryptographic libraries only.
- Apply least privilege to services, data stores, queues, and secrets.
- Every feature requires a privacy review.

See `docs/security/security-baseline.md` for the full baseline.

## Sensitive Data Handling

Do not commit:

- Private keys
- Access tokens
- API keys
- Production credentials
- Database dumps
- Real user data
- Plaintext message samples

## Reporting

Until a formal disclosure channel exists, keep security reports private and route them directly to the repository owner.
