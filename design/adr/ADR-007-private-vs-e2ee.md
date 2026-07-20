# ADR-007 — "Private" Instead of "E2EE"

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Design team  

## Context

The security badge in the conversation screen needs to communicate that messages are encrypted. The question is what term to use: the technically accurate "E2EE" (End-to-End Encrypted) or the more human-readable "Private."

## Options Considered

| Option | Rationale |
|---|---|
| **E2EE / End-to-End Encrypted** | Technically precise. Used by Signal, WhatsApp. Educates users about encryption. |
| **Private** | Understandable by all users. Less intimidating. Broader meaning (encryption + no data collection). |
| **Secure** | Common term. Positive connotation. But vague — doesn't differentiate between encryption in transit vs. at rest. |
| **🔒 (lock icon only)** | No text. Universal symbol. Minimalist. But ambiguous — users may not know what it signifies. |

## Decision

Use "Private" with a lock icon. When tapped, show a brief explanation: "This conversation is private. Only participants can read it."

## Rationale

- **Human-readable**: Most users don't know what "E2EE" means. Those who do will understand that "Private" implies encryption in Hush's context. Those who don't get the meaning immediately.
- **Broader promise**: "Private" communicates more than just encryption. It communicates that Hush doesn't read messages, doesn't collect data, and doesn't share information. "E2EE" only covers encryption.
- **Calm tone**: "Private" is a warm, reassuring word. "E2EE" is technical and cold. Hush's tone should be warm and human.
- **Transparency on tap**: Users who want the technical detail can tap to learn more. This respects both the casual user and the privacy-conscious user.

## Consequences

- Positive: All users understand the security indicator immediately.
- Positive: Warmer, more human tone in the UI.
- Positive: Tappable explanation provides depth for those who want it.
- Negative: Privacy-purist users may object that "Private" is less precise than "E2EE."
- Negative: "Private" could imply the conversation is hidden from other people on the same device (local privacy), not encrypted.

## Related

- ADR-008 (No Permanent History)
- Product Canon — Principle 4 (Trust Must Be Visible)
