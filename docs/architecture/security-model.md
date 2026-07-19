# Security Model

Hush assumes the service provider should be technically unable to read user conversation content.

## Core Security Goals

- Confidentiality: message content is readable only by intended participants.
- Integrity: recipients can detect tampering.
- Forward secrecy: compromise of current keys should not expose historical messages.
- Post-compromise recovery: device trust can recover after key or device rotation.
- Data minimization: store only metadata required for routing, safety, and lifecycle state.
- Cryptographic destruction: completed conversations become inaccessible by destroying required key material and purging temporary state.

## Trust Boundaries

| Boundary | Rule |
| - | - |
| Device | Owns private keys and plaintext |
| Backend | Stores metadata and encrypted payloads only |
| Database | Stores no plaintext messages and no private keys |
| Logs | Must not include plaintext, tokens, private keys, or encrypted payload bodies |
| Analytics | Must not include message content or sensitive identity material |

## Cryptographic Direction

Use established libraries only. Do not design custom encryption, signing, or key exchange algorithms.

Candidate libraries:

- Flutter: libsodium bindings, `flutter_secure_storage`
- Rust: `ring`, `rustls`, `snow`
