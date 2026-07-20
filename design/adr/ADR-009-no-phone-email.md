# ADR-009 — No Phone Number or Email Required

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Every major messaging platform requires a phone number (WhatsApp, Signal, Telegram) or email (iMessage, Facebook Messenger) for account creation. This ties the user's identity to an external identifier that may not be private.

## Options Considered

| Option | Rationale |
|---|---|
| **Phone number required** | Industry standard. Simplifies identity verification, prevents spam, enables phone-based discovery. |
| **Email required** | Common for non-phone apps. Enables password reset, recovery. |
| **Username only** | Maximum privacy. No external identifier needed. Pseudonymity by default. |
| **Username + optional email** | Maximum privacy with recovery option. Email is optional and not tied to identity. |

## Decision

Hush requires only a username for account creation. No phone number, no email, no external identity provider.

## Rationale

- **Privacy**: Phone numbers and emails are personally identifiable information. Requiring them ties the user's Hush identity to their real-world identity. Username-only allows pseudonymity.
- **Accessibility**: Not everyone has a phone number (children, some countries) or wants to share it.
- **Platform independence**: The user's identity is their key pair stored on their device. No external identifier means no one can lose access to their account by losing a phone number (SIM swap attacks).
- **No contact book matching**: Phone-number-based platforms enable contact discovery, which is a privacy violation (your contacts know you're on the platform without your consent).

## Consequences

- Positive: Maximum privacy at signup. Users can join without revealing any personal information.
- Positive: No SIM swap attack vector for account takeover.
- Positive: No contact discovery spam.
- Negative: No phone-based account recovery if device is lost.
- Negative: Users must remember their username (no email to look it up).
- Negative: Harder to prevent spam accounts (no phone verification barrier).

## Mitigation

- Account recovery is handled via the user's key pair backup (stored securely on device, with export option).
- Username availability is checked in real-time during signup.
- Spam prevention is handled via rate limiting and, if needed, proof-of-work challenges (not phone verification).

## Related

- Product Canon — Principle 10 (Platform Independence)
- Product Canon — Part III (What Hush Is Not)
- ADR-010 (Why No Contact Discovery)
