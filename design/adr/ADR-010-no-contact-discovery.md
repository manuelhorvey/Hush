# ADR-010 — Why No Contact Discovery

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team / Privacy team  

## Context

Most messaging apps upload the user's address book to their servers to discover which contacts are already on the platform. This is called "contact discovery" and is one of the most controversial privacy features in messaging.

## Options Considered

| Option | Rationale |
|---|---|
| **Server-side contact discovery** | Upload hashed phone numbers to server, match against registered users. Industry standard (WhatsApp, Telegram). |
| **Hashed contact discovery** | Hash phone numbers client-side before uploading. Better than plaintext, but still shares contact metadata. |
| **User-side discovery** | User manually enters usernames of people they want to contact. No contact data ever leaves the device. |

## Decision

Hush does not implement contact discovery. Users find each other by username.

## Rationale

- **Privacy**: Contact discovery leaks the user's entire address book to the server. Even hashed, the set of contacts can be used for social graph analysis.
- **Consent**: Your contacts did not consent to being uploaded to Hush's servers. Contact discovery is a violation of their privacy, not just yours.
- **Phone-number-free**: Since Hush doesn't use phone numbers, contact discovery based on phone numbers is irrelevant. The entire model is username-based.
- **Philosophical alignment**: Hush is designed for intentional communication. Finding someone by username is intentional. "This app told me you're here" is not.

## Consequences

- Positive: Maximum privacy. No contact data ever leaves the user's device.
- Positive: No consent violation of non-users whose numbers are uploaded.
- Positive: Users only communicate with people they explicitly choose to find.
- Negative: Higher friction to start conversations. Users must know each other's usernames.
- Negative: Slower network growth. Viral adoption is harder without contact discovery.

## Related

- ADR-009 (No Phone Number or Email Required)
- Product Canon — Principle 2 (The Default is Privacy)
- Product Canon — Principle 7 (No Metadata as a Product)
