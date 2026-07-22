# Real-Time Communication Architecture

## Overview

Hush's real-time communication layer enables ephemeral, private conversations with end-to-end encryption. This document describes the architecture, event flow, connection lifecycle, and integration points.

### Core Philosophy

> "Digital conversations should have a natural ending."

A conversation (called a "Moment") follows a strict lifecycle:
```
Created → Active → Completed → Closed → Destroyed
```

Messages exist only within this lifecycle. There are no read receipts, no typing indicators, and no online status to preserve privacy.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌───────────────────┐  ┌───────────────────┐               │
│  │ ConversationScreen │  │   HomeScreen      │               │
│  └────────┬──────────┘  └────────┬──────────┘               │
│           │                      │                          │
│  ┌────────▼──────────────────────▼──────────┐               │
│  │         Riverpod Providers               │               │
│  │  ┌────────────────────────────────────┐  │               │
│  │  │ MessageListNotifier                │  │               │
│  │  │ MessageComposerNotifier            │  │               │
│  │  │ ConnectionStateNotifier            │  │               │
│  │  │ ConversationSyncManager            │  │               │
│  │  └────────────────────────────────────┘  │               │
│  └────────────────┬─────────────────────────┘               │
└───────────────────┼─────────────────────────────────────────┘
                    │
┌───────────────────▼─────────────────────────────────────────┐
│                    Domain Layer                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │              MessageRepository                     │     │
│  │  (abstract interface — single source of truth)     │     │
│  └────────────────────────────────────────────────────┘     │
│                    ↑                                        │
│  ┌────────────────────────────────────────────────────┐     │
│  │         MessageRepositoryImpl                      │     │
│  │  (wires RemoteDataSource + WebSocket + Crypto)     │     │
│  └────────────────────────────────────────────────────┘     │
└───────────────────┼─────────────────────────────────────────┘
                    │
┌───────────────────┼─────────────────────────────────────────┐
│                   ▼                                          │
│  ┌────────────────────────┐   ┌─────────────────────────┐   │
│  │ MessageRemoteDataSource│   │   WebSocketService      │   │
│  │  (REST API calls)      │   │   (real-time events)    │   │
│  └────────────────────────┘   └─────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## Connection Lifecycle

### States

```
                        ┌──────────┐
                        │Connected │◄────┐
                        └────┬─────┘     │
                             │            │
                      disconnected    reconnecting
                             │            │
                        ┌────▼─────┐     │
                        │Disconnect│─────┘
                        └────┬─────┘
                             │
                        ┌────▼─────┐
                        │  Failed  │
                        └──────────┘
```

### Reconnect Strategy

- **Exponential backoff**: `min(2^attempt, 60)` seconds
- **Maximum retry attempts**: Unlimited (persistent recovery)
- **Token refresh**: On reconnection, the stored session token is reused
- **State recovery**: Active conversations are re-fetched after reconnect

### Connection State Provider

```dart
// Wraps WebSocket's stateStream into Riverpod
final connectionStateProvider = NotifierProvider<ConnectionStateNotifier, ConnectionStateInfo>;
```

---

## Event Flow

### Sending a Message

```
User writes message
       │
       ▼
MessageComposerNotifier.setText(text)
       │
       ▼
MessageListNotifier.sendMessage(plaintext)
       │
       ├─► Optimistic UI: add message with status=sending
       │
       ▼
MessageRepository.sendMessage()
       │
       ├─► MessageRemoteDataSource.sendMessage() → POST /api/v1/conversations/:id/messages
       │
       ▼
Server confirms → Message returned with server-assigned ID
       │
       ▼
Optimistic message replaced with confirmed message (status=sent)
```

### Receiving a Message (Real-Time)

```
WebSocket event received
       │
       ▼
WebSocketService.eventStream
       │
       ▼
MessageRepositoryImpl._handleWsEvent()
       │
       ├─► Filters: only messageReceived, ignores own messages
       │
       ▼
MessageRepositoryImpl._messageControllers[convId].add(message)
       │
       ▼
MessageListNotifier._onMessageReceived(message)
       │
       ├─► Dedup check (by message ID)
       │
       ▼
state = state.copyWith(messages: [...state.messages, message])
       │
       ▼
UI rebuilds via Riverpod consumer
```

### Conversation Event Flow

```
WebSocket event: conversation.completed / conversation.destroyed
       │
       ▼
ConversationSyncManager.processEvent(event)
       │
       ▼
_refreshController.add(conversationId)
       │
       ▼
Listening providers re-fetch conversation state
```

---

## Message State Lifecycle

```
         ┌──────────┐
         │  Sending │  (optimistic — shown immediately)
         └────┬─────┘
              │
         ┌────▼─────┐       ┌──────────┐
         │   Sent   │──────►│ Delivered│
         └────┬─────┘       └──────────┘
              │
         ┌────▼─────┐
         │  Failed  │  (retryable)
         └──────────┘

         ┌──────────┐
         │ Pending  │  (offline queue)
         └──────────┘
```

### Privacy Constraints

- **No read receipts**: `delivered` status is the final state
- **No seen status**: Never implemented
- **No typing indicators**: Never sent or received
- **No online presence**: Users appear offline at all times

---

## File Structure

```
features/messaging/
├── data/
│   ├── datasources/
│   │   └── message_remote_datasource.dart    # REST API calls
│   ├── repositories/
│   │   └── message_repository_impl.dart      # Core implementation
│   └── models/
│       └── message_dto.dart                  # Serialization DTOs
├── domain/
│   ├── entities/
│   │   ├── message.dart                      # Message entity
│   │   ├── message_status.dart               # Status enum
│   │   ├── connection_state.dart             # WS connection enum
│   │   └── conversation_event.dart           # Event model
│   ├── repositories/
│   │   └── message_repository.dart           # Abstract interface
│   └── usecases/
│       ├── send_message.dart                 # Send use case
│       └── get_messages.dart                 # Get messages use case
└── presentation/
    ├── providers/
    │   ├── message_list_provider.dart        # Main message list state
    │   ├── message_composer_provider.dart    # Input field state
    │   ├── message_repository_provider.dart  # DI wiring
    │   ├── connection_state_provider.dart    # Connection tracking
    │   └── conversation_sync_manager.dart    # Sync management
    └── controllers/
        └── message_controller.dart           # List management utilities
```

---

## Key Design Decisions

### 1. No Direct UI WebSocket Usage

UI widgets never communicate directly with WebSockets. All real-time data flows through Riverpod providers → Repository → WebSocketService.

### 2. Repository as Single Source of Truth

`MessageRepository` is the only interface for message operations. All providers read from it, never from the WebSocket or API directly.

### 3. Optimistic UI

Messages appear in the UI immediately (status: `sending`) before the API call completes. On success, the status updates to `sent`. On failure, it updates to `failed` with retry capability.

### 4. Provider Isolation

Each conversation gets its own `MessageListNotifier` instance via Riverpod's family provider pattern. This prevents cross-conversation state leaks.

### 5. ConversationSyncManager

A singleton-like service that lives for the app's lifetime. It monitors connection state and triggers refreshes for all active conversations when the WebSocket reconnects.

---

## Provider Dependencies

```dart
// Core wire-up in app.dart
messageRepositoryProvider
  ├── messagingServiceProvider    (from conversations_state_provider.dart)
  ├── webSocketServiceProvider    (overridden with WebSocketService instance)
  ├── cryptoServiceProvider       (CryptoService instance)
  └── identityServiceProvider     (IdentityService instance)

messageListProvider               (per-conversation via family)
  └── messageRepositoryProvider

connectionStateProvider
  └── webSocketClientProvider     (from network_providers.dart)

conversationSyncManagerProvider
  └── messageRepositoryProvider
```

---

## Security Considerations

### Logging

- **Never log**: Message content, conversation content, sensitive identifiers
- **Development logs contain only**: Event type, timestamp, status
- **Example**: `[MessagingRepo] Error handling WS event: ...` (no data content)

### Encryption Integration Points

The messaging layer is designed for Double Ratchet encryption integration:

1. **`MessageRepositoryImpl.sendMessage()`** — `TODO: encrypt with Double Ratchet` at the point where `plaintext` becomes `ciphertext`
2. **`MessageRepositoryImpl.getMessages()`** — `TODO: decrypt` at the point where `dto.ciphertext` becomes `content`
3. **`MessageRepositoryImpl._handleMessageReceived()`** — Decrypt `data['ciphertext']` before emitting to stream

### Future Backend Requirements

- WebSocket token authentication
- Message delivery acknowledgments
- Conversation lifecycle events from server
- Ephemeral key rotation

---

## Testing Strategy

### Unit Tests

- `MessageStatus` enum — label, isFinal, isError
- `ConnectionState` enum — label, isOnline, isTransitioning
- `ConversationEvent` — fromJson, toJson
- `MessageController` — append, prepend, update, remove, groupByDate
- `MessageDto` — fromJson, toJson, toDomain
- `SendMessage` use case — validation, call delegation
- `GetMessages` use case — call delegation

### Widget Tests

- `ConnectionStateProvider` — state transitions
- `MessageComposerProvider` — text, sending, enabled states
- `MessageListState` — copyWith

### Integration Tests

- MessageRepositoryImpl with mocked datasource
- MessageListNotifier with mocked repository
- Connection recovery flow

---

## Future Improvements

1. **Offline message queue**: Persist failed messages and retry on reconnect
2. **Pagination**: Load older messages on scroll-to-top
3. **Encrypted search**: Client-side search over decrypted content
4. **Conversation preview**: Last message snippet in conversation list
5. **Multi-device sync**: Handle messages from other devices via WS events
