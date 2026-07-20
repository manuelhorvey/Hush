# ADR-008 — No Permanent History

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Traditional messaging apps maintain a permanent, searchable history of all messages. Hush's philosophy of temporary conversations is in direct tension with this model. We need to define what "permanence" means in the context of the Active → Completed → Destroyed lifecycle.

## Options Considered

| Option | Rationale |
|---|---|
| **Permanent history** | Industry standard. Users can search past messages. Useful for reference. | 
| **No permanent history (lifecycle only)** | Messages exist only within their Active → Completed → Destroyed lifecycle. After destruction, they are gone. |
| **Hybrid: permanent with destruction** | Messages are stored until explicitly destroyed. Users can keep conversations indefinitely if they never complete/destroy them. |

## Decision

Hush has no permanent message history. All messages exist within the conversation lifecycle. When a conversation is destroyed, all messages are permanently deleted. Users may keep a conversation indefinitely by never completing it, but the expectation is that conversations will eventually end.

## Rationale

- **Philosophical alignment**: The entire product is built around the idea that conversations should end. Permanent history is the opposite of that.
- **Privacy**: Permanent history is a surveillance risk. Even encrypted messages, when stored indefinitely, create a record of who said what and when. Destruction eliminates that risk.
- **Product differentiation**: "No permanent history" is a stronger, clearer differentiator than "disappearing messages." Disappearing messages imply that the user sets a timer. Hush's model is that the user controls the ending.
- **User behavior**: Users who want to keep a conversation can simply not complete/destroy it. The conversation remains active and readable. The choice is theirs.

## Consequences

- Positive: Clear product differentiation from every major messaging app.
- Positive: Stronger privacy guarantees. No indefinite data retention.
- Positive: Reinforces the lifecycle model at every level.
- Negative: Users cannot search across destroyed conversations.
- Negative: Users who want permanent records of important conversations will be frustrated.
- Negative: Destroys the "searchable history" use case that many users rely on.

## Mitigation

- Users can keep conversations active indefinitely by choosing not to complete them
- Before destruction, Hush shows a clear warning that all messages will be permanently deleted
- Users are encouraged to complete conversations (making them read-only) before destroying them, giving a grace period for review

## Related

- Product Canon — Principle 5 (Destroyed Means Destroyed)
- Product Canon — Principle 6 (The User Controls the Ending)
- Product Canon — Part VI (The Conversation Lifecycle)
