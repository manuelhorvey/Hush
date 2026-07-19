# Hush v0.1: Product Foundation Document — Part 10: Technical Specification

---

## 179. System Architecture
Hush utilizes a decoupled architecture separating the **Client Layer** (UI, E2EE, Key Mgmt), **Service Layer** (Auth, Lifecycle, Relay), and **Data Layer** (PostgreSQL/Redis) to ensure security boundaries.

## 180. Engineering Philosophy
The server manages **control** (delivery, lifecycle), while the users own **content**. The system is split into specialized microservices for enhanced security auditing.

## 181. Backend Service Blueprint
*   **Gateway Service:** Single entry point for routing and auth validation.
*   **Authentication Service:** Manages device-bound sessions; no message access.
*   **Identity Service:** Stores public keys; private keys remain device-resident.
*   **Conversation Service:** Tracks lifecycle states (`CREATED`, `ACTIVE`, `DESTROYING`, `DESTROYED`).
*   **Message Relay:** Strictly forwards encrypted objects.
*   **Lifecycle Engine:** Monitors conversation conditions and triggers key destruction.

## 182. Database Schema (PostgreSQL)
*   **Users:** `id`, `username`, `email_hash`
*   **Devices:** `id`, `user_id`, `public_key`, `trusted`
*   **Conversations:** `id`, `creator_id`, `state`, `policy`, `destroyed_at`
*   **Messages:** `id`, `conversation_id`, `ciphertext`, `nonce`, `expires_at`
*   **Security Events:** Audit logs for lifecycle transitions (no content).

## 183. API Design (`/api/v1/`)
*   `POST /auth/register`: Identity creation.
*   `POST /conversations`: Lifecycle initiation.
*   `POST /messages`: Relay of encrypted payloads.
*   `POST /conversations/{id}/complete`: Trigger destruction process.

## 184. Client-Side Integrity
*   **Architecture:** Feature-driven (Flutter) with dedicated `crypto/` and `storage/` modules.
*   **Local Storage:** All data stored in hardware-backed encrypted databases (iOS Secure Enclave/Android Keystore).

## 185. Lifecycle & Destruction
1.  **Creation:** Message/Conversation keys generated.
2.  **Usage:** Encrypted payloads relayed via server.
3.  **Completion:** Both users confirm; Lifecycle Engine triggers.
4.  **Destruction:** Local keys deleted, cache cleared, server remnants expired.

## 186. DevOps & Monitoring
*   **Pipeline:** Automated CI/CD (GitHub Actions) with integrated dependency scanning and vulnerability checks.
*   **Monitoring:** Track health (uptime, latency) and security events; explicitly avoid content-based analytics.

## 187. Engineering Rules
1. Never log sensitive information.
2. Never store plaintext.
3. Never implement custom cryptography.
4. Security decisions require documentation.