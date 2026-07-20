# Hush Product Canon

**Edition**: 1.0
**Status**: Ratified
**Every designer, engineer, and PM must read this before contributing.**

---

## Preamble

Hush exists because digital communication lost something that spoken conversation has always had: **a natural ending.**

Messaging apps are built to maximize engagement. They treat every message as a permanent record, every conversation as a thread that should never end. Notifications, read receipts, typing indicators, "last seen" timestamps — all designed to keep you coming back.

Hush rejects that model.

Hush is a **conversation platform**, not a messaging app. The difference is fundamental:

- Messaging apps optimize for **keeping** conversations.
- Conversation platforms optimize for **helping conversations happen well — and then end naturally.**

This canon exists to ensure every decision — from the largest feature to the smallest label — reinforces that belief. When in doubt, return to this document.

---

## Part I: Core Principles

### Principle 1: Conversations Have a Lifecycle

Every conversation passes through distinct phases: Created → Active → Completed → Destroyed. This is not a feature. It is the product. The UI must make the current phase visible and the next phase clear at all times.

**Why**: Without visible lifecycle, Hush is just another messaging app with a "delete" button. The lifecycle is the differentiation.

### Principle 2: The Default is Privacy

Every privacy-related setting defaults to the most restrictive option. Notifications are off. Read receipts don't exist. Online status is invisible. Data is encrypted before it leaves the device.

**Why**: Privacy should be earned by the user opting in to less privacy, not the other way around. This is the opposite of every major messaging platform.

### Principle 3: Design for Deliberation, Not Addiction

Hush should never trigger a dopamine loop. No badges. No streaks. No "seen" indicators. No gamification. Every interaction should feel chosen, not compelled.

**Why**: The product goal is to enable meaningful communication, not maximize time spent in the app. If users spend less time in Hush but the time they spend is higher quality, the product is working.

### Principle 4: Trust Must Be Visible

Encryption is not a background property. It must be surfaced in a way that is understandable to a non-technical user. Security indicators should be present but calm — never alarmist, never absent.

**Why**: If users cannot see or understand the trust model, they cannot trust it. Visible security builds confidence. Invisible security builds skepticism.

### Principle 5: Destroyed Means Destroyed

Cryptographic destruction is irreversible. There is no "recover deleted messages." There is no "trash can." There is no grace period beyond the completion window. When a conversation is destroyed, it is gone from all devices and all servers.

**Why**: The promise of Hush is that conversations end. If they can be recovered, they haven't ended. This is a product decision, not a technical limitation.

### Principle 6: The User Controls the Ending

Destruction is always user-initiated. There is no auto-destroy timer. The user decides when a conversation is complete and when it is destroyed. The app's role is to make those actions visible and intentional — not automatic.

**Why**: Giving users control over the ending reinforces trust. Auto-destruction feels like the app is making decisions for you. Hush facilitates, it does not dictate.

### Principle 7: No Metadata as a Product

Hush does not expose who you talk to, how often, or when. There is no "most contacted" list. There is no analytics dashboard showing usage patterns. The server stores only what is necessary to deliver messages.

**Why**: Metadata reveals as much as content. A list of who you talk to and when is a surveillance asset. Hush does not build it.

### Principle 8: Identity Before Conversation

Before a user sends a message, they must be able to verify who they are talking to. Identity verification is not a settings screen — it is a first-class action accessible from every conversation.

**Why**: Trust in E2EE requires knowing the other endpoint is the right one. Verification is the foundation of secure communication.

### Principle 9: Less is More

Every feature request is evaluated against a single question: *Does this make conversations more intentional, more private, or more trustworthy?* If the answer is no, the feature is declined. If the answer is unclear, the feature is postponed.

**Why**: Feature creep is the death of focused products. Hush's competitive advantage is what it does not do, not what it does.

### Principle 10: Platform Independence

Hush is not tied to a phone number, email address, or any external identity provider. A username is sufficient. The user's identity is their cryptographic key pair, not a phone number.

**Why**: Phone-number-based identity ties the product to a single carrier relationship and excludes users who value pseudonymity. Username + keypair is more private and more portable.

### Principle 11: Calm is a Feature

The app should never feel urgent. No red badges. No "urgent" notifications. No pressure-inducing UI. Empty states are peaceful, not sad. Loading states are quiet, not anxious. Errors are informative, not alarming.

**Why**: Urgency is the tool of addiction-driven products. Calm is the tool of trust-driven products. Hush competes on trust.

### Principle 12: The Product is the Philosophy

Every UI element, every string of copy, every animation communicates a belief about communication. There is no neutral design. The app bar, the send button, the destroy confirmation — they all say something about what Hush believes. They must say the right thing.

**Why**: If the product philosophy lives only in a document and not in the UI, users will experience a generic messaging app with a "delete" button, not a new category of communication.

---

## Part II: What Hush Is

- A platform for **intentional, finite conversations** between verified participants
- A **privacy-first** communication tool where encryption is visible and understandable
- A product that **completes** — conversations end, and the platform helps them end well
- A **calm** alternative to notification-driven messaging apps
- A **username-based** identity system with no phone number or email requirement
- A **cross-platform** experience (iOS, Android, Desktop, Web)

---

## Part III: What Hush Is Not

Hush will never have:
- Read receipts
- Typing indicators
- Online/Last seen status
- Message previews on the lock screen or notification
- Stories, status, or "moments"
- Public profiles or discoverable identities
- Phone number verification
- Email verification
- Contact/address book integration
- Chatbots or AI features in conversations
- Message reactions (likes, emoji responses)
- Message editing or unsend
- File sharing beyond text (initial scope)
- Voice messages
- Video/voice calls (initial scope)
- Group conversations beyond small groups (initial scope)
- Disappearing message timers (destruction is always user-initiated)
- Export or backup of messages
- Data analytics or telemetry
- Advertising or sponsored content
- Payment or commerce features
- Third-party integrations

**Note**: "Will never have" means the principle excludes it permanently. Some features listed as "initial scope" may be added later if they align with the principles. Items in "will never have" are excluded by principle and will not be revisited.

---

## Part IV: Feature Evaluation Framework

Every proposed feature must pass the **Hush Test**:

1. **Does it make conversations more intentional?**
   - Does it encourage deliberate communication?
   - Does it reduce accidental actions?
   - Does it make the lifecycle clearer?

2. **Does it make conversations more private?**
   - Does it reduce metadata exposure?
   - Does it strengthen encryption visibility?
   - Does it give users more control?

3. **Does it make conversations more trustworthy?**
   - Does it help users verify participants?
   - Does it make security understandable?
   - Does it honor the destruction promise?

4. **Does it preserve calm?**
   - Does it add urgency or noise?
   - Does it trigger dopamine loops?
   - Does it compete for attention?

5. **Does it honor the lifecycle?**
   - Does it respect that conversations end?
   - Does it avoid creating permanence?
   - Does it reinforce the Active → Completed → Destroyed model?

**Pass**: The feature passes all five questions.
**Conditional**: The feature passes 4/5. Proceed with design review to address the gap.
**Fail**: The feature fails 2+ questions. Decline or postpone.

---

## Part V: Copy and Terminology

Consistent language is not cosmetic — it is the product philosophy made tangible.

| Use | Never Use | Reason |
|---|---|---|
| Conversation | Chat | "Chat" implies casual, endless. "Conversation" implies intentional, bounded. |
| Complete | End, Close, Finish | "Complete" implies fulfillment, not termination. |
| Destroy | Delete, Remove, Erase | "Destroy" communicates irreversibility. "Delete" is too casual. |
| Participant | Member, User | "Participant" implies active engagement. |
| Verify | Confirm, Check | "Verify" has cryptographic weight. |
| Private | Secure, Encrypted | "Private" is human. "Encrypted" is technical. |
| You, Username | User, Customer | Direct address builds trust. |
| Conversation screen | Chat screen | Maps to the terminology above. |

**Tone rules**:
- No exclamation points in UI copy
- No emoji in UI copy
- No marketing language ("experience the future of messaging")
- Error messages: state the problem, offer the action. Never apologize ("sorry, something went wrong").
- Success messages: state the outcome. No celebration.

---

## Part VI: The Conversation Lifecycle — Detailed

### State Diagram

```
                   ┌──────────┐
                   │ Pending  │  (invitation sent, not yet accepted)
                   └────┬─────┘
                        │
                   ┌────▼─────┐
                   │  Active  │  (sending/receiving messages)
                   └────┬─────┘
                        │
                   ┌────▼──────┐
                   │ Completed │  (read-only, messages preserved)
                   └────┬──────┘
                        │
                   ┌────▼───────┐
                   │ Destroyed  │  (removed from all devices and servers)
                   └────────────┘
```

**Pending**: A conversation has been created but the other participant has not yet opened it. Visible only to the creator. Not counted as an "active" conversation.

**Active**: Both (all) participants have opened the conversation. Messages can be sent and received. This is the only state where messaging occurs.

**Completed**: Any participant may complete the conversation. Once completed:
- No new messages can be sent by any participant
- Messages remain visible in read-only mode
- The destroy action becomes available
- A completion undo window exists for 5 minutes

**Destroyed**: Any participant may destroy the conversation. Once destroyed:
- All messages are cryptographically destroyed on all devices and servers
- The conversation is removed from the list
- The action is irreversible

### Destroyed Means Destroyed — The Full Promise

When a conversation is destroyed:
- Messages are deleted from the server database
- Messages are deleted from all participant devices (via sync)
- Cryptographic keys associated with the conversation are discarded
- No backup, no recovery, no trash can
- The conversation simply ceases to exist

**This is a product promise, not just a technical implementation.** If the implementation cannot meet this promise, the implementation must change — not the promise.

---

## Part VII: Privacy & Trust Model

### Data Hush Does Not Collect
- Phone number
- Email address
- Real name
- Contact list
- Location data
- Device identifiers (beyond what is necessary for push notifications)
- Usage analytics
- Message content (end-to-end encrypted)

### Data Hush Stores (Server-Side)
- Username (hashed)
- Public key (for key exchange)
- Encrypted messages (temporary, deleted on destruction)
- Conversation metadata (participants, creation date — necessary for delivery)

### Trust Model
- Authentication: username + token
- Encryption: E2EE with X3DH key agreement (Signal Protocol)
- Verification: security phrase (BIP39-style word list)
- No server has access to message content at any point
- The server is untrusted by design

---

## Part VIII: The Hush Test for Design Decisions

A quick checklist for everyday design decisions:

| Question | Yes | No |
|---|---|---|
| Does this make the conversation lifecycle clearer? | ☐ | ☐ |
| Does this reduce accidental actions? | ☐ | ☐ |
| Does this make security visible? | ☐ | ☐ |
| Does this respect the user's attention? | ☐ | ☐ |
| Does this work without notifications? | ☐ | ☐ |
| Would this feature exist in a calm product? | ☐ | ☐ |
| Does this reinforce trust? | ☐ | ☐ |
| Could this be used to pressure users? | ☐ | ☐ |
| Would this feature exist in a product without engagement metrics? | ☐ | ☐ |
| Would we build this if no competitor had it? | ☐ | ☐ |

**Scoring**: 10/10 — proceed. 7-9/10 — review with caution. Below 7 — decline.

---

## Appendix A: Canon Evolution

This canon is not static. It evolves as Hush learns more about its users and its market. However:

- **Core Principles (Part I)** require unanimous team agreement to change
- **What Hush Is Not (Part III)** requires founder-level approval to amend
- **Copy and Terminology (Part V)** may be updated by the design team without approval, but changes must be documented
- A canon review should be conducted every 12 months

Every change to this document must include:
- The date of change
- The rationale
- The previous text
- The new text
- Who approved the change

---

*This canon was ratified on July 20, 2026.*

*"Digital conversations should be allowed to have a natural ending."*
