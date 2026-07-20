# ADR-003 — Why Conversation Instead of Chat

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Throughout the Hush codebase and UI, we use the term "conversation" rather than "chat." This decision extends from user-facing copy to class names to database schema.

## Options Considered

| Option | Rationale |
|---|---|
| **Chat** | Industry standard term. Users understand it immediately. Shorter, easier to localize. |
| **Conversation** | More intentional. Implies a bounded interaction with a beginning, middle, and end. Less casual. |

## Decision

Use "conversation" consistently throughout the product and codebase.

## Rationale

- **Philosophical alignment**: "Chat" implies an endless, informal exchange. "Conversation" implies a structured, intentional interaction with a natural lifecycle. Hush's entire product model is built around the lifecycle — the term must reflect that.
- **Behavioral design**: Referring to "chats" subconsciously primes users for the behavior patterns of other messaging apps (endless scrolling, constant checking). "Conversation" primes a different mental model.
- **Category differentiation**: Hush is not competing to be "another messaging app." It is defining a new category: conversation platforms. The terminology should reinforce the category.

## Consequences

- Positive: Consistent terminology reinforces product philosophy at every touchpoint
- Positive: Differentiates Hush from every other messaging app in the market
- Negative: "Conversation" is longer and may feel slightly formal to some users
- Negative: Users searching for "chat" features in the app store may not find Hush (mitigated by keyword optimization)

## Implementation

Codebase rules:
- All class names: `ConversationScreen`, not `ChatScreen`
- All model names: `Conversation`, not `Chat`
- All API routes: `/conversations`, not `/chats`
- All user-facing copy: "Conversation", not "Chat"
- Variable names in Dart/Rust: `conversation_id`, not `chat_id`

## Related

- Product Canon Part V (Copy and Terminology)
