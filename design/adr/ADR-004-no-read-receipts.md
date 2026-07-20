# ADR-004 — No Read Receipts

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Read receipts (showing "Seen" or "Read" timestamps) are a standard feature in every major messaging platform. Their absence would be notable. However, Hush's philosophy of intentional, calm communication may conflict with this feature.

## Options Considered

| Option | Rationale |
|---|---|
| **Full read receipts** | Industry standard. Users expect them. Provides confirmation that a message was seen. |
| **No read receipts** | Reduces social pressure. Users don't feel obligated to respond immediately. |
| **Delivery receipts only** | Shows the message was delivered to the device but not opened. Partial information. |

## Decision

Hush will never have read receipts.

## Rationale

- **Social pressure**: Read receipts create an implicit expectation of immediate response. "They saw it. Why haven't they replied?" This is antithetical to calm, intentional communication.
- **Asymmetry**: Read receipts benefit the sender at the expense of the receiver's peace of mind. Hush prioritizes the receiver's experience.
- **Product philosophy**: Hush is designed for communication that happens when both parties are ready, not on demand. Read receipts work against this.
- **Privacy**: Read receipts leak information about when a user is active. This is metadata that Hush has committed to not exposing.

## Consequences

- Positive: Reduced anxiety for recipients. No social pressure to reply immediately.
- Positive: Consistent with the "calm" design principle.
- Positive: Less metadata stored on servers.
- Negative: Users accustomed to read receipts may feel uncertain ("Did they get my message?").
- Negative: No way to confirm time-sensitive messages were seen (mitigated by delivery confirmation — the message reached the device).

## Mitigation

Delivery receipts ARE implemented. The sender sees a subtle indicator that the message was delivered to the recipient's device. This confirms the message arrived without revealing whether it was opened.

## Related

- ADR-005 (No Typing Indicators)
- ADR-006 (No Online Status)
- Product Canon — Principle 3 (Design for Deliberation, Not Addiction)
