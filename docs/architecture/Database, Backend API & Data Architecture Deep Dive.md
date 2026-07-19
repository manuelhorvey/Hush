# Hush v0.1: Product Foundation Document — Part 19: Backend Specification

---

## 394. Backend Architecture Philosophy
The backend is a coordinator of **Control**, not a storehouse for **Content**. The system follows an event-driven, modular microservice architecture to isolate security-sensitive logic from routine delivery tasks.

## 395. Service Breakdown
* **API Gateway:** Central entry point; enforces auth and rate limits.
* **Identity Service:** Manages public keys and device relationships; stores no private key material.
* **Messaging Service:** Orchestrates encrypted payload routing; strictly content-agnostic.
* **Lifecycle Engine:** An event-driven state machine managing conversation transitions (`CREATED` $\rightarrow$ `DESTROYED`).
* **Notification Service:** Minimalist alerts; no content leakage.

## 396. Data Infrastructure
* **Primary Store (PostgreSQL):** Relational state management for users, devices, and lifecycle markers.
* **Cache/Realtime (Redis):** Session management and rate limiting.
* **Asynchronous Bus (Kafka/NATS):** Decouples event generation (e.g., "Completion Requested") from execution (e.g., "Destruction Job").

## 397. Core Database Schema Highlights
* **Devices Table:** Employs independent trust; each device is registered with unique keys.
* **Conversations Table:** Uses an explicit `state` column (e.g., `ACTIVE`, `DESTROYING`) to drive the lifecycle engine.
* **Messages Table:** Stores only `ciphertext` and `nonce` (BYTEA); the backend is incapable of decryption.

## 398. API & Event Design
* **Versioned REST API:** `/api/v1/` ensures predictable contracts.
* **Event-Driven Lifecycle:** Actions like "Complete Conversation" trigger an event, allowing the `Lifecycle Engine` to process cleanup asynchronously and reliably.

## 399. Security & Data Retention
* **Retention Policy:** Every table carries a defined TTL (Time-To-Live). Content in the `Messages` table is transient by design.
* **Audit Logs:** Only structural events (e.g., `CONVERSATION_CREATED`) are logged; content is never included in observability pipelines.