# Hush v0.1: Product Foundation Document — Part 3: Technical Architecture & Cryptographic Design

---

## 27. Technical Philosophy
The biggest mistake Hush could make is building a normal messaging system and adding "delete messages" as a feature. The architecture assumes:
*   Messages are temporary objects with a limited lifetime.
*   The system should move from "Create temporarily $\rightarrow$ Use $\rightarrow$ Destroy cryptographic access" rather than "Store forever $\rightarrow$ Delete later."

## 28. High-Level Architecture
Hush follows a privacy-first client-centric architecture. The server’s role is limited to delivering encrypted data, managing temporary synchronization, and coordinating connection states—never understanding the content of conversations.

## 29. Core Architecture Components
*   Mobile & Desktop Applications
*   Authentication Service
*   Message Relay Service
*   Key Management Service
*   Presence Service
*   Notification Service
*   Security Monitoring System

## 30. Client-First Design
The user's device is the trusted environment handling encryption, decryption, key generation, lifecycle management, and destruction events. The server never sees plaintext, keys, or content.

## 31. Conversation Object Model
A conversation is a temporary cryptographic container tracking `conversation_id`, `participants`, `created_at`, `lifecycle` state, `destruction_policy`, and `key_status`.

## 32. Conversation Lifecycle
States: `CREATED` $\rightarrow$ `ACTIVE` $\rightarrow$ `COMPLETED` / `EXPIRED` $\rightarrow$ `DESTROYING` $\rightarrow$ `DESTROYED`.

## 33. Cryptographic Model
Hush utilizes proven, audited standards:
*   Asymmetric key exchange
*   Symmetric message encryption
*   Forward secrecy
*   Authenticated encryption

## 34. Key Architecture
*   **Identity Key:** Long-term trust.
*   **Session Keys:** Temporary per conversation.
*   **Message Keys:** Individual per message (prevents total compromise).

## 35. Conversation Creation Flow
1.  Device generates temporary conversation and message keys.
2.  Encrypted key material is shared with the participant.
3.  Participant verifies identity.
4.  Secure channel is established.

## 36. Message Encryption Flow
The server only relays encrypted payloads (e.g., `8F72A91BC83F992...`). Bob's device decrypts locally.

## 37. Cryptographic Destruction
Instead of deleting database rows, Hush destroys the encryption keys.
*   **Before:** Encrypted Message + Encryption Key = Readable.
*   **After:** Encrypted Message + NO KEY = Mathematically inaccessible data.

## 38. Destruction Protocol
1.  Both users confirm completion.
2.  Clients verify mutual confirmation.
3.  Key destruction begins locally.
4.  Server is notified; encrypted remnants expire from relay storage.

## 39. The Destruction Proof Problem
Hush may generate a "Cryptographic Destruction Receipt" (Conversation Hash + Timestamp + Key Destruction Signature) to prove the event occurred without revealing the conversation content.

## 40. Database Philosophy
The database focuses on `Users`, `Active Sessions`, `Encrypted Temporary Objects`, and `Lifecycle Events`. Messages are not stored long-term; the database enforces expiration.

## 41. Example Database Schema
*   **Users:** `id`, `public_identity_key`, `status`
*   **Conversations:** `id`, `participants`, `expiry_policy`, `state`, `destroyed_at`
*   **Messages:** `id`, `conversation_id`, `encrypted_payload`, `delivery_status`

## 42. Server Storage Rules
Automatic lifecycle cleanup ensures permanent removal of messages once a conversation is completed and the destruction timer expires.

## 43. Metadata Protection
To protect "who talks to whom and when," Hush employs temporary identifiers, rotating session IDs, limited timestamps, and minimized logging.

## 44. Offline Communication
Encrypted payloads are stored in temporary relay storage until the recipient comes online, at which point the message is downloaded and removed from the relay.

## 45. Multi-Device Support
Each device maintains its own identity/keys. Adding a device requires explicit user authorization.

## 46. Device Loss Scenario
Recovery restores identity and contacts, but not old conversations. Lost devices are revoked.

## 47. Security Threat Model
*   **Server Compromise:** Attacker gains only encrypted blobs.
*   **Network Interception:** Protected by end-to-end encryption.
*   **Malicious Employee:** No plaintext access.
*   **Stolen Device:** Protected by biometric locks and local encryption.
*   **User Screenshot:** Mitigated via warnings/watermarking.

## 48. Security Priorities
1. Encryption correctness. 2. Key management. 3. Authentication. 4. Metadata reduction. 5. User experience.

## 49. Suggested Technology Stack
*   **Mobile:** Flutter (one codebase) or Native (Swift/Kotlin) for tighter security.
*   **Backend:** Go, Rust, or Elixir (performance/concurrency).
*   **Database:** PostgreSQL.
*   **Transport:** WebSockets/QUIC.
*   **Cryptography:** Use only audited, standard libraries (never custom primitives).

## 50. Engineering Rule
For every feature, ask: "Does this create unnecessary permanent data?" If yes, reject or redesign.

## 51. The Technical North Star
The architecture succeeds when even if the database, server, or storage is compromised, an attacker cannot reconstruct completed conversations.