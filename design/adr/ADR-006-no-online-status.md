# ADR-006 — No Online/Last Seen Status

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Every major messaging platform shows when a user was last active ("Last seen 5m ago") or is currently online. This feature is often requested by users who want to know if someone is available to respond.

## Options Considered

| Option | Rationale |
|---|---|
| **Full online/last seen** | Industry standard. Helps users know when someone is available. |
| **No online status at all** | Maximum privacy. No information leakage about user activity. |
| **Conversation-level presence only** | Show "Active" only when someone is currently viewing the same conversation. No global online indicator. |

## Decision

Hush will never show global online status or last seen timestamps. The only presence indicator is a per-conversation "Active" state when the participant is viewing that conversation.

## Rationale

- **Privacy**: Online status is metadata that reveals when a user is active, their sleep schedule, and their communication patterns. This is a surveillance asset.
- **Social pressure**: "They're online but not replying to me" is a common source of anxiety in messaging apps. Hush avoids this entirely.
- **Product model**: Hush conversations are asynchronous and intentional. Knowing whether someone is "online" is irrelevant to the question of whether they will respond when ready.
- **Consistency**: If we don't have read receipts or typing indicators, showing online status would be inconsistent. The user would know someone is online but not whether they read the message — a worse experience than either extreme.

## Consequences

- Positive: Maximum privacy. No activity metadata exposed.
- Positive: No social pressure around "ignoring" messages.
- Positive: Consistent with the rest of the communication model.
- Negative: Users cannot know if someone is available for real-time conversation.
- Negative: Goes against user expectations set by every other messaging app.

## Mitigation

The per-conversation "Active" indicator (visible only when both participants are viewing the same conversation) provides a lightweight, contextual presence signal without the privacy implications of global online status.

## Related

- ADR-004 (No Read Receipts)
- ADR-005 (No Typing Indicators)
- Product Canon — Principle 2 (The Default is Privacy)
