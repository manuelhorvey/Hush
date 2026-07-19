# Hush v0.1: Product Foundation Document — Part 2: Users, Personas, User Journeys, MVP Scope & UX

---

## 15. Target Users
Hush should not attempt to serve everyone initially. It is built for people who experience the cost of permanent communication and want to communicate openly without leaving a permanent record.

## 16. Primary User Personas
*   **The Privacy-Conscious Individual (Alex):** Values privacy, desires control, and wants less digital baggage.
*   **The Professional (Sarah):** Needs a space for business ideas, negotiations, and temporary collaboration without the choice of convenience vs. confidentiality.
*   **The Journalist / Source (Daniel):** Requires communication channels where conversations do not create permanent digital evidence.
*   **The Modern Relationship User (Maya):** Seeks a natural communication experience for private, emotional, or sensitive moments without the creation of an archive.
*   **Teams (Temporary Collaboration):** Startup teams or project groups needing a secure, temporary space for specific internal discussions.

## 17. Initial Target Market
*   **Phase 1:** Privacy-aware individuals.
*   **Phase 2:** Professionals (consultants, founders, executives).
*   **Phase 3:** Organizations (Enterprise version: "Hush for Teams").

## 18. User Jobs To Be Done
*   "When I have a private conversation, I want confidence that it won't become a permanent record."
*   "When I discuss something sensitive, I want to communicate naturally without worrying about future exposure."
*   "When a conversation is over, I want it to actually be over."

## 19. Core User Experience Principle
The user should never feel they are using a security product. They should feel they are having a **private conversation**.

## 20. User Journey
*   **First-Time User:** Simple onboarding focusing on the philosophy of temporary communication.
*   **Starting a Conversation:** Select type (Private, Group, Workspace) and configure lifetime settings (After reply, specific duration, etc.).
*   **During Conversation:** A familiar, minimalist interface without archive/export/history-hoarding features.
*   **Ending Conversation:** Explicit initiation of "End Conversation," leading to the cryptographic destruction of all associated messages.

## 21. MVP Definition (v1)
*   **Identity:** Basic account/profile creation.
*   **Messaging:** One-to-one private messaging.
*   **Encryption:** Mandatory end-to-end encryption.
*   **Lifecycle:** State-based conversation management (Created $\rightarrow$ Active $\rightarrow$ Completed $\rightarrow$ Destroyed).
*   **Destruction:** Mandatory cryptographic key destruction.
*   **Read Receipts & Reply Detection:** Essential for tracking conversation state.
*   **Device Security:** App/biometric lock and session management.
*   **Minimal Media:** Initially text-only (potentially adding simple images).

## 22. Features NOT In MVP
Hush will strictly avoid: Stories, public profiles, channels, communities, AI assistants, stickers, games, payments, social discovery, and cloud archives.

## 23. Future Feature Roadmap
*   **v2:** Media (photos, voice messages, videos).
*   **v3:** Group Hush (temporary group conversations).
*   **v4:** Hush Teams (enterprise).
*   **v5:** Advanced Privacy (anonymous/decentralized identity).

## 24. Information Architecture
Extremely minimal navigation:
*   **Hush** (Main View)
    *   **Active**
    *   **Contacts**
    *   **Settings**

## 25. UX Rules
*   **Peaceful Disappearance:** Never make deletion feel scary.
*   **Normalcy:** Do not constantly remind users that data is deleted; let the silence feel normal.
*   **No Engagement Manipulation:** No streaks, unread anxiety, or addictive notifications.
*   **Functional Focus:** Every screen must exist only to help a conversation happen.

## 26. The Emotional Goal
Users should conclude a session feeling: "That conversation happened. It mattered. And now it is gone."