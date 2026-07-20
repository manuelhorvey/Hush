# ADR-012 — Why Provider Over Other State Management

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Flutter architect  

## Context

Flutter offers multiple state management solutions: Provider, Riverpod, BLoC, Redux, GetX, and others. We need to select one that matches the complexity of Hush's state requirements.

## Options Considered

| Option | Pros | Cons |
|---|---|---|
| **Provider** | Simple, well-documented, recommended by Flutter team, good for small-to-medium apps | Limited with complex async flows, can lead to widget rebuild issues if not careful |
| **Riverpod** | More powerful than Provider, compile-time safety, better testability | Newer, smaller ecosystem, more boilerplate for simple cases |
| **BLoC** | Clear separation of concerns, excellent testability, good for complex apps | Heavy boilerplate, overkill for Hush's state complexity, steep learning curve |
| **GetX** | Minimal boilerplate, high performance | Opinionated, ties everything to GetX framework, poor separation of concerns |

## Decision

Use Provider for v1. Evaluate Riverpod for v2 if Provider proves insufficient.

## Rationale

- **Complexity fit**: Hush's state is relatively simple: auth state, conversation list, connectivity. Provider handles this comfortably without the overhead of BLoC or the learning curve of Riverpod.
- **Team familiarity**: Provider is the most widely understood Flutter state management solution. New developers can be productive immediately.
- **Performance**: For Hush's number of concurrent listeners (< 50), Provider's notifyListeners() model is more than sufficient.
- **Migration path**: Provider and Riverpod share similar mental models (ChangeNotifier, providers). Migrating to Riverpod later is straightforward if needed.

## Consequences

- Positive: Simple, familiar state management for v1 development.
- Positive: Well-documented pattern with extensive community support.
- Positive: Easy to test (ChangeNotifier can be unit tested directly).
- Negative: More verbose than GetX for simple state reads.
- Negative: Provider's `context.read`/`context.watch` pattern requires discipline to avoid rebuild issues.
- Negative: If state complexity grows significantly, migration to Riverpod may be needed.

## Current Providers

Hush uses three ChangeNotifier providers:
1. `AuthProvider` — session, token, userId, username
2. `ConversationsProvider` — conversation list, CRUD, search state
3. `ConnectivityProvider` (future) — online/offline state

Services (CryptoService, IdentityService, MessagingService) are provided as non-notifying dependencies.

## Related

- ADR-001 (Why Flutter)
- Product Specification Section 12 (Frontend Architecture)
