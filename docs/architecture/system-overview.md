# System Overview

Hush is a client-first, end-to-end encrypted messaging system. Clients own plaintext, private keys, and local cryptographic state. Backend services coordinate identity, routing, delivery, lifecycle state, and infrastructure concerns without gaining access to plaintext message content.

```text
                  HUSH

        Mobile Applications
              |
              |
        API Gateway
              |
 ┌────────────┼────────────┐
 Auth      Messaging    Lifecycle
  |            |             |
 Identity    Queue        Workers
              |
          PostgreSQL
              |
        Infrastructure
```

## Primary Layers

| Layer | Responsibility |
| - | - |
| Mobile applications | Identity creation, key storage, encryption, chat UX, lifecycle actions |
| API gateway | Public API entry point, authentication checks, routing, rate limits |
| Auth service | Session and token lifecycle |
| Identity service | Public identity keys, device registration, device trust state |
| Messaging service | Encrypted payload routing and delivery state |
| Lifecycle service | Conversation state machine and destruction workflow |
| Queue | Internal event delivery between services |
| PostgreSQL | Metadata, identity records, device records, lifecycle state |
| Redis | Sessions, rate limits, temporary coordination state |

## Non-Negotiable Boundary

The backend must never require plaintext message access. Message content is encrypted on device before transport and remains opaque to server-side systems.
