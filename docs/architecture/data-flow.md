# Data Flow

This document captures the initial Hush data-flow model for Phase 0.

## Identity Creation

```text
Mobile app
  -> generate identity keys on device
  -> store private keys in secure local storage
  -> send public identity and device keys to backend
  -> identity service stores public metadata only
```

## Message Delivery

```text
Sender device
  -> encrypt message locally
  -> send encrypted payload to gateway
  -> gateway routes to messaging service
  -> messaging service stores temporary delivery metadata
  -> recipient receives encrypted payload over WebSocket
  -> recipient decrypts locally
```

## Conversation Completion

```text
Participant completes conversation
  -> lifecycle service records completion intent
  -> clients receive completion event
  -> clients destroy local conversation keys
  -> backend purges temporary routing and lifecycle state according to policy
```

## Forbidden Flows

- Plaintext message from client to server.
- Private key from client to server.
- Plaintext message into logs, analytics, crash reports, or database rows.
- Server-side message decryption for moderation, search, backup, or support.
