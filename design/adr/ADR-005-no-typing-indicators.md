# ADR-005 — No Typing Indicators

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Typing indicators ("Alice is typing...") are a standard feature in messaging apps. They provide real-time awareness of the other participant's activity. However, they also create a pressured environment where the other person knows you're composing a response.

## Options Considered

| Option | Rationale |
|---|---|
| **Show typing indicators** | Industry standard. Provides conversational rhythm. Lets users know the other person is engaged. |
| **No typing indicators** | Reduces pressure to respond quickly. Preserves asynchronous communication feel. Harder to implement reliably (WS overhead). |
| **Delayed typing indicator** | Show the indicator only after 5+ seconds of typing. Reduces "they just opened the keyboard" anxiety. |

## Decision

Hush will never have typing indicators.

## Rationale

- **Social pressure**: Typing indicators create the same dynamic as read receipts — the other person knows you're engaged and waiting for you to finish. This is incompatible with calm communication.
- **False precision**: Typing indicators are unreliable. User opens keyboard → thinks of something else → walks away. The indicator stays on. The other person waits. Both parties are frustrated.
- **Implementation complexity**: Typing indicators require additional WebSocket message types, debounce logic, and state management. The engineering cost is not justified by the user benefit for Hush's target experience.
- **Philosophical alignment**: Hush conversations are more like letters that arrive instantly than real-time chat rooms. You don't see someone typing a letter.

## Consequences

- Positive: No pressure to respond immediately. Conversations feel asynchronous and calm.
- Positive: Lower implementation complexity. No WS messages for typing state.
- Positive: Less metadata (timestamps of when someone is actively typing).
- Negative: Users may feel uncertain whether the other person is still engaged.
- Negative: Some users may prefer the conversational rhythm that typing indicators provide.

## Mitigation

Instead of typing indicators, Hush shows a "Online" indicator when the other participant is currently viewing the same conversation. This is less granular (doesn't show per-message composition) and calmer.

## Related

- ADR-004 (No Read Receipts)
- ADR-006 (No Online Status in the list)
- Product Canon — Principle 3 (Design for Deliberation, Not Addiction)
