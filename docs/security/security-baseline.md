# Security Baseline

This baseline must be satisfied before Hush feature development begins.

## Rule 1: No Plaintext Messages Outside Devices

Plaintext messages are forbidden in:

- Logs
- Database records
- Analytics
- Crash reports
- Push notification payloads
- Support tooling

## Rule 2: Private Keys Never Leave Devices

Private identity keys, private device keys, and conversation secrets must remain on user devices.

## Rule 3: Use Established Cryptographic Libraries

Do not create custom:

- Encryption algorithms
- Key exchange algorithms
- Signature algorithms
- Random number generation systems

## Rule 4: Least Privilege Everywhere

Every service, database role, queue subject, secret, and deployment identity should receive only the access required for its job.

## Rule 5: Privacy Review For Every Feature

Every feature must answer:

- What user data does it touch?
- Is the data required?
- Where is the data stored?
- How long does the data exist?
- Can the feature work without plaintext access?
- What happens when a conversation completes?

## Approved Initial Libraries

Flutter:

- libsodium bindings
- `flutter_secure_storage`

Rust:

- `ring`
- `rustls`
- `snow`

## Logging Baseline

Logs may include operational metadata such as request IDs, status codes, timings, and service names. Logs must not include plaintext content, private keys, tokens, encrypted payload bodies, or sensitive identity secrets.
