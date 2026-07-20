# Hush — Design Review Board Report

**Session**: Pre-implementation final review
**Status**: No design is protected. Everything is challenged.

---

## Panel Assessment

### 1. INFORMATION ARCHITECTURE

| Role | Verdict |
|---|---|
| Apple HIG | **2 tabs is correct.** No drawer. No tabs beyond Chats and Settings. Structurally sound. |
| Signal UX | **Missing "Identity" as a first-class concept.** Signal surfaces safety numbers in chat. Hush should surface participant identity at the app level, not buried in settings. |
| Linear PM | **The architecture assumes conversations are the only object.** What about drafts? What if a user starts a conversation but never sends a message? That orphan state has no home. |

**Weaknesses**:
- No "identity" section in the IA — users have no way to understand their own cryptographic identity
- No draft/inbox concept — what happens when conversations are proposed but not accepted?
- Setting up a conversation requires knowing the username — there's no "receive invite" flow

**Hidden Risk**: If Alice creates a conversation with Bob but Bob hasn't opened Hush in 3 days, where does that conversation live? Currently it goes straight into the list. That's inbox noise for Bob.

**Edge Case**: User has 50+ completed conversations. The list becomes a graveyard. Section headers help but don't solve the fundamental problem of decay.

**Recommended Design**:
- Add a 3rd IA concept: `Inbox` for pending invitations / new conversation requests
- Auto-archive completed conversations after 7 days (remove from list, accessible via "Show All" at bottom)
- Identity verification should be a screen accessible from the conversation itself AND from a dedicated path

**Confidence**: 7/10 — The two-tab structure is right. The gaps are in what exists between the tabs.

---

### 2. NAVIGATION

| Role | Verdict |
|---|---|
| Apple HIG | Bottom tab bar is correct. Back swipe on iOS is automatic. |
| Material Design | Bottom navigation + push for detail is correct. No complaints. |
| Linear PM | **The navigation model doesn't handle "deep links to a specific message"** — but that's out of scope for v1. Flag for v2. |

**Weaknesses**:
- Chat screen AppBar has too many actions (complete, menu, status, connection dot, back). That's 5+ items. Apple HIG recommends max 2-3.
- Connection dot in the AppBar is bad UX — it's not an action, but it's in the actions slot. It should be embedded in the title or moved to a status bar.

**Risk**: The overflow menu (⋮) buries the most important lifecycle actions. "Complete Conversation" is the defining action of the product. It should NEVER be in an overflow menu.

**Recommended Design**:
- Remove connection dot from AppBar actions. Add a subtle colored dot next to the title or in the trailing edge of the title row.
- Move "Complete Conversation" to the input bar area (replacing the send button contextually when the user is done) OR as a prominent text button in a bottom sheet.
- Overflow menu should contain only secondary actions: View Participants, Report Issue (future), Help

**Confidence**: 9/10

---

### 3. HOME SCREEN

| Role | Verdict |
|---|---|
| Apple HIG | Search in AppBar is good. FAB is standard. |
| Signal UX | **No "new message" FAB.** Signal uses a pencil icon in the top right, not a FAB. FABs are for primary actions. Is "new conversation" truly the primary action? Or is "read existing conversations" the primary action? |
| Privacy Researcher | The search bar searches ALL conversations, including completed ones. Does searching a completed conversation imply it still exists? How does this reconcile with the destruction promise? |

**Weaknesses**:
- The FAB is wrong. A FAB signals "this is the most important action." On Hush, reading existing conversations is the primary action. New conversations are secondary events.
- The search bar indexing completed conversations creates a false sense of permanence
- No differentiation between active, completed, and destroyed in search results

**Hidden Risk**: User searches "taxes" and finds a completed conversation about taxes. They tap it, see the messages, and feel the system is surveilling them. Trust broken.

**Recommended Design**:
- Replace FAB with an icon button in the top-right of the AppBar (pencil or compose icon). Standard messaging pattern.
- In search results, dim or label completed conversations distinctly: "Completed — messages pending destruction"
- Section headers: "Active" / "Closed" (not "Completed" — see review feedback)
- Add "Show All" at bottom of closed section when >10 items, to prevent scrolling graveyards

**Confidence**: 8/10

---

### 4. CONVERSATION LIST

| Role | Verdict |
|---|---|
| Linear PM | **A flat list of cards is too heavy for a conversation list.** Linear uses compact rows for a reason — information density matters when you have 20+ items. |
| Accessibility | Card-based layout with 44px avatars + 3 rows of text + chevron = 72+ px per item. That's luxurious but wasteful. On a small phone, you see 4-5 items. Users will scroll endlessly. |

**Weaknesses**:
- Conversation cards are too tall. The avatar + username + date + chip + chevron creates visual clutter.
- Status chip in every card is redundant if we have section headers. If it's in the "Active" section, we know it's active.
- Date is not useful for active conversations. "2 hours ago" is useful. "2026-07-20" is not.

**Edge Case**: What does a conversation card look like when it's been completed but not yet destroyed? The status chip says "Completed" but the card looks the same as active. Need visual distinction.

**Recommended Design**:
- Compact row layout, not cards.
  ```
  [Avatar 36px]  Username            2h ago
                 Last message preview  [Active]
  ```
- No cards. No elevated surfaces. Just clean rows with thin dividers.
- Last message preview (1 line, truncated) for active conversations
- No message preview for completed/destroyed conversations
- Status chip only visible in "All" view (if user expands closed section)

**Confidence**: 7/10 — Cards are a valid design choice. This is a values decision: spacious vs. dense. Hush should lean spacious, but not at the cost of usability.

---

### 5. CHAT SCREEN

| Role | Verdict |
|---|---|
| Apple HIG | Standard messaging layout. No issues. |
| Signal UX | **Where is the identity verification entry point?** Signal has it in the chat header (tap name → safety numbers). Hush buries it in an overflow menu. |
| Flutter Architect | The current `chat_screen.dart` at 485 lines is already too long. The `_connectWs`, `_decrypt`, `_loadGroupKey` methods should be extracted into a `ChatViewModel` or a service class. |

**Weaknesses**:
- 485 lines in `chat_screen.dart` is unsustainable. By v1 release, this will be 800+ lines.
- No identity verification entry point
- Overflow menu is the only way to find "Complete" — the most important action in the product
- Connection indicator in AppBar is in the wrong place (as noted in navigation)

**Hidden Risk**: The WS reconnect logic (`_scheduleReconnect`) uses a fixed 5-second interval. If the server is down for 10 minutes, the app will hammer it with reconnection attempts. No exponential backoff.

**Edge Case**: User is in a chat and their token expires. The WS connection drops. The reconnect attempt uses the expired token and fails silently. User sees "connected" indicator but messages don't send.

**Recommended Design**:
- Extract chat state management into a `ChatProvider` or use a `ChatCubit` for the chat screen only
- Add an identity verification entry point: tap the username in the AppBar → verification sheet
- Move "Complete Conversation" to a persistent text button above the input field (not in overflow)
- Use exponential backoff for WS reconnection: 2s, 4s, 8s, 16s, max 60s
- Add token refresh check before WS connect

**Confidence**: 8/10

---

### 6. MESSAGE BUBBLE DESIGN

| Role | Verdict |
|---|---|
| Apple HIG | Standard iMessage-style bubbles. Familiar. Works. |
| Privacy Researcher | **Do not show message text in bubbles on the conversation list.** Ever. No previews. The home screen shows "Bob +1" and the date. Nothing else. |
| Accessibility | 16px font in bubbles is too small for some users. Need to support system font scaling. |

**Edge Case**: What does a destroyed message look like in a conversation that's been completed? If the conversation is in read-only mode and a message was encrypted before destruction... the bubble should show "[This message has been destroyed]" — not an empty gap, not a rendering error.

**Recommended Design**:
- Increase minimum font size in bubbles to 17px (iOS readability standard)
- Support dynamic type / font scaling (use `MediaQuery.textScaleFactor` or `textScaler`)
- For destroyed messages in completed conversations: show a subtle placeholder with strikethrough
- No message previews on conversation list (privacy)

**Confidence**: 9/10

---

### 7. IDENTITY VERIFICATION

| Role | Verdict |
|---|---|
| Signal UX | **This is the most under-designed screen in the current spec.** Identity verification is the foundation of trust in E2EE. It needs to be prominent, accessible, and understandable. |
| Privacy Researcher | Users don't understand safety numbers. They need a security phrase or emoji pair that's human-readable. |

**Weaknesses**:
- No identity verification screen exists in the current codebase
- `devices_screen.dart` exists but only shows device list, not identity verification
- No visual representation of cryptographic identity (fingerprint, phrase, emoji)

**Risk**: Without a verification moment, users have no way to confirm they're talking to the right person. Man-in-the-middle attacks are invisible.

**Recommended Design**:
- Add a "Verify" action in the chat screen (tap username → Verify)
- Verification screen:
  ```
  Verify Sarah
  
  Your security phrase:
  
  OCEAN     WOLF      BRIDGE
    18        23        7
  
  Sarah sees the same phrase if you're verified.
  
  [Generate New]  [Mark as Verified]
  ```
- Use a BIP39-style word list (12-bit words, 3 words = 36 bits of verification)
- Animations: words draw in one by one, 200ms each
- When verified: show a green checkmark on the username in chat

**Confidence**: 10/10 — This must be designed before launch.

---

### 8. SECURITY INDICATORS

| Role | Verdict |
|---|---|
| Mobile Security UX | **Too many indicators create noise.** The current design has a lock icon, a connection dot, a status chip, and E2EE badge. Users will ignore all of them. |
| Apple HIG | Apple uses a single lock icon in the title bar for secure Safari connections. One indicator. That's it. |

**Weaknesses**:
- Indicator overload. The chat AppBar has: back button, username, lock icon, status icon, connection dot, overflow menu. That's 6 elements.
- Users don't know what the connection dot means. "Green = connected to server" is backend trivia, not user-facing information.

**Recommended Design**:
- Single indicator: a privacy badge in the title row
  - Active + verified: lock icon + "Private" text
  - Active + not verified: lock icon + "Verify" (tappable, prompts verification)
  - Completed: "Closed" badge
  - Destroyed: not shown (conversation is gone)
- Remove the connection dot entirely. Users don't need to know about WebSocket state.
- Remove the E2EE badge. The lock icon is sufficient.

**Confidence**: 8/10

---

### 9. CONVERSATION LIFECYCLE

| Role | Verdict |
|---|---|
| Staff Product Designer | **The 3-state model (Active → Completed → Destroyed) is elegant but incomplete.** What about "Pending" (invitation sent but not accepted)? |
| Principal PM | The lifecycle needs to be visible to the user at all times. Currently, the user has to infer state from the UI. |

**Missing States**:
- `Pending` — conversation created but other participant hasn't opened it yet
- `Active` — both participants have opened and can send/receive
- `Completed` — at least one participant has completed. Still readable, no new messages.
- `Destroyed` — all messages deleted, conversation removed from list

**Recommended Design**:
- Lifecycle banner in chat (below AppBar, above messages):
  ```
  Active: ─────●──────────────────  (green line, shows progress)
  ```
  A thin colored line showing lifecycle progress. Active = left side. Completed = middle. Destroyed = end (with fade out).
- This gives users a constant, calming signal of where they are

**Confidence**: 9/10

---

### 10. CONVERSATION COMPLETION

| Role | Verdict |
|---|---|
| Signal UX | **The completion action must be reversible for a grace period.** Signal lets you delete messages for everyone within an hour. Hush should let you "uncomplete" within 5 minutes. Accidental completion is catastrophic. |
| Apple HIG | A completion should feel like closing a door. Not deleting a file. The UI should reflect that. |

**Weaknesses**:
- No undo option for completion
- The input bar disappearing is jarring. Users might think the app crashed.

**Recommended Design**:
- After completion, show an undo banner for 30 seconds:
  ```
  Conversation completed. Messages will be destroyed soon.
  [Undo]  [Destroy Now]
  ```
- After 30 seconds, the undo option disappears
- The completed state should show a brief explanation text, not just a disabled input:
  "This conversation has ended. Messages are preserved until destruction."

**Confidence**: 9/10

---

### 11. CONVERSATION DESTRUCTION

| Role | Verdict |
|---|---|
| Signal UX | **The destruction animation must be meaningful but not theatrical.** Signal's "disappearing messages" fade out with a brief animation. Hush's destruction should feel final but respectful. |
| Accessibility | The fade-out animation will be invisible to screen reader users. Need a complementary audio/haptic cue. |
| Privacy Researcher | **The destroyed state must be clearly communicated to ALL participants.** Not just the person who initiated destruction. The other participant should see evidence that messages were destroyed on their end too. |

**Weaknesses**:
- Current spec only shows the destroyer's experience. What does the other participant see? Do they get a notification? Does the conversation disappear from their list mid-session?
- No haptic feedback for destruction

**Recommended Design**:
- Destroyer experience: fade animation (as described), soft haptic, "This moment has ended" text
- Other participant experience (if in the chat at the same time): messages fade out simultaneously, "X has ended this conversation" system message
- Other participant experience (if not in the chat): the conversation moves to "Closed" with a "Destroyed" label. They see: "Alice has ended this conversation."

**Confidence**: 8/10

---

### 12. NOTIFICATIONS

| Role | Verdict |
|---|---|
| Apple HIG | Request notification permission in context, not at first launch. Hush currently doesn't request at all — which is better than requesting too early. |
| Privacy Researcher | **No preview, no sender name, no sound differentiation.** Every notification is identical. This prevents metadata leakage if someone sees your lock screen. |

**Weaknesses**:
- No notification system exists in the current codebase (acceptable for v1)
- When implemented, must follow strict privacy rules

**Recommended Design**:
- Silent notification: "New Hush message" — no sender, no preview, no sound
- When user taps: open to the conversation (don't show which conversation on the lock screen)
- Notification permission requested only after user sends their first message (they've committed to using the app)
- No notification grouping — one conversation doesn't get priority over another

**Confidence**: 9/10 — Notifications should be additive only after the core product is proven

---

### 13. SETTINGS

| Role | Verdict |
|---|---|
| Apple HIG | Settings should be brief. Apple's Settings app is a list of toggles. Hush's current settings screen has too much whitespace and not enough density. |
| Linear PM | Settings should feel as polished as the main app. The current `settings_screen.dart` is adequate but not premium. |

**Weaknesses**:
- Profile card takes up ⅓ of the screen with low information density
- "Sign Out" at the bottom with a simple ListTile — should be more prominent or in a danger zone section
- No option to change username (acceptable for v1, but should be listed as "coming soon" otherwise users will look for it)

**Recommended Design**:
- Compact profile section: avatar + username + user ID (copyable) in a single row
- Clear section grouping with thin section headers (swift-style)
- Danger zone: "Sign Out" and "Delete Account" in a red-bordered section
- "Security & Privacy" as a dedicated settings section with: Verification phrase, Devices, Encryption keys info

**Confidence**: 7/10

---

### 14. DEVICE MANAGEMENT

| Role | Verdict |
|---|---|
| Mobile Security UX | **Device management is table stakes for E2EE.** If a user loses their phone, they need to revoke the old device and register a new one. The current `devices_screen.dart` is read-only. |
| Signal UX | Signal allows linking desktops. Hush should design for multi-device from the start, even if it's v2. The device list should show: current device, linked devices, last active timestamp. |

**Weaknesses**:
- Current devices screen shows a list with no actions
- No "remove device" functionality
- No indication of which device is the current one

**Recommended Design**:
- Show current device with "(This device)" label
- Show linked devices with last active date
- Swipe-to-remove or "X" button to unlink devices (with confirmation dialog)
- Add "Link New Device" option (placeholder for future multi-device support)

**Confidence**: 8/10

---

### 15. ONBOARDING

| Role | Verdict |
|---|---|
| Apple HIG | No tutorial. No permissions. No sign-up wall. The current spec is correct. |
| Linear PM | **The only question: does the user immediately understand what Hush is?** On first launch, they see a shield, then "Choose your username." If they don't know what the app does, they'll leave. |

**Weaknesses**:
- Splash screen shield is abstract — doesn't communicate "messaging" or "private conversations"
- Identity creation screen doesn't explain the product philosophy
- No "what is Hush?" moment before identity creation

**Recommended Design**:
- Splash → brief tagline screen (1.5s auto-advance):
  ```
  Hush
  
  Conversations that end.
  ```
- Then identity creation. Short. No tutorial.
- After identity creation, show a brief empty state that teaches:
  ```
  No conversations yet.
  
  Your conversations are private.
  They have a beginning, a middle, and an end.
  
  Tap + to start your first Hush.
  ```

**Confidence**: 8/10

---

### 16. EMPTY STATES

| Role | Verdict |
|---|---|
| Apple HIG | Empty states are opportunities to teach. The current spec's "No conversations yet. Tap + to start" is too generic. |
| Privacy Researcher | Empty states should never suggest features that compromise privacy. "Invite friends" would be a privacy violation. |

**Recommended Design**:
- Empty state for "no conversations":
  ```
  ┌─────────────────────────┐
  │                         │
  │     [Shield icon]       │
  │                         │
  │  No conversations yet.  │
  │                         │
  │  Start a private        │
  │  conversation with      │
  │  someone you trust.     │
  │                         │
  │  [New Conversation]     │
  │                         │
  └─────────────────────────┘
  ```
- Empty state for search filtering:
  ```
  No conversations matching "{query}".
  ```
- Empty state for completed conversations (if all are completed):
  ```
  All conversations closed.
  Start a new one when you're ready.
  ```

**Confidence**: 9/10

---

### 17. ERROR STATES

| Role | Verdict |
|---|---|
| Apple HIG | Error messages should be actionable, not technical. "Connection failed" is useless. |
| Signal UX | Signal silently retries. No error messages for transient failures. Hush should do the same. |

**Weaknesses**:
- No error states currently implemented for most screens
- Silent failures in WS connection (user sees "connected" when they aren't)
- No offline state differentiation (server down vs. client offline)

**Recommended Design**:
- Network errors: shown in a banner below AppBar, not a dialog (dialogs are blocking and frustrating)
  ```
  [No connection. Reconnecting...   X]
  ```
  - Banner slides down from top, stays until resolved, can be dismissed
- Server errors: same banner, different message:
  ```
  [Hush is having trouble. Try again.   X]
  ```
- Send failures: show a red (!) icon on the failed message bubble. Tap for retry.
  ```
  [Message text]   (!)
  12:34
  ```

**Confidence**: 9/10

---

### 18. OFFLINE EXPERIENCE

| Role | Verdict |
|---|---|
| Signal UX | Signal works offline (messages queue). Hush v1 explicitly does not support offline queuing. This is a valid choice but must be communicated clearly. |
| Apple HIG | "No connection" states should never feel punitive. The app should remain functional, just limited. |

**Weaknesses**:
- Current codebase has no offline detection
- If the app goes offline mid-conversation, the user can keep typing but nothing happens. No feedback.
- When coming back online, the user has to manually reload

**Recommended Design**:
- Add `ConnectivityProvider` (as specified)
- When offline:
  - Subtle banner: "You're offline"
  - App remains fully navigable
  - Send button is disabled with a tooltip: "Reconnect to send"
  - Messages typed are preserved in the input field (don't lose user input)
- When reconnecting:
  - Banner: "Reconnecting..."
- When back online:
  - Banner fades out after 2s
  - Auto-refresh conversation list

**Confidence**: 9/10

---

### 19. LOADING STATES

| Role | Verdict |
|---|---|
| Linear PM | **Linear uses skeleton screens, not spinners.** Skeleton screens feel faster because they show structure before content. Hush should use skeletons for the conversation list. |
| Apple HIG | CircularProgressIndicator is acceptable but should be used sparingly. Prefer content-shaped placeholders. |

**Weaknesses**:
- Current codebase uses `CircularProgressIndicator` for everything
- No skeleton screens
- Loading feels like waiting instead of anticipation

**Recommended Design**:
- Conversation list: skeleton rows (gray pill shapes matching the row layout)
- Chat screen: skeleton bubbles (2-3 gray rounded rectangles)
- Identity creation: no loading state (it's an instant local operation)
- Send message: no loading state (optimistic UI — show message immediately, mark with a clock icon until confirmed)

**Confidence**: 8/10

---

### 20. MOTION DESIGN

| Role | Verdict |
|---|---|
| Apple HIG | Animations should feel natural, not theatrical. The destruction animation described is borderline theatrical. Apple would pull it back. |
| Accessibility | The destruction animation MUST respect reduced motion. When disabled, messages should disappear instantly, not fade. |
| Flutter Architect | Complex animations in Flutter require careful performance optimization. The staggered fade animation for destruction could cause jank on low-end devices if not implemented with `AnimatedList` or `ImplicitlyAnimatedWidget`. |

**Weaknesses**:
- Destruction animation as specified (staggered 50ms fade) is high complexity for the emotional return
- No reduced motion path specified

**Recommended Design**:
- Destruction animation: 400ms total, not 1-2s
  - Messages fade simultaneously (not staggered) over 300ms
  - 100ms pause
  - Screen pops
  - Haptic feedback (soft, single tap)
- Respect `MediaQuery.disableAnimations` — skip animation entirely
- For reduced motion: instant state change, no fade

**Confidence**: 8/10

---

### 21. ACCESSIBILITY

| Role | Verdict |
|---|---|
| Senior Accessibility | **The current spec is aware of accessibility but hasn't implemented it anywhere.** Semantics labels, focus indicators, font scaling, and reduced motion are all "future" work. They need to be built in from day one, not bolted on. |
| Apple HIG | Dynamic Type is not optional on iOS. If Hush doesn't support it, the app will be unusable for users who need larger text. |

**Weaknesses**:
- Zero accessibility implementation in current codebase
- No `Semantics` widgets anywhere
- No support for `MediaQuery.textScaleFactor`
- No focus management for navigation
- Color-only status indicators (green dot for connected, no label)
- Touch targets below 48dp in some places (status chip is ~20px tall)

**Critical Issues**:
1. Message bubbles don't have semantics labels — screen readers read raw ciphertext or "encrypted"
2. No focus outline on conversation cards for keyboard navigation
3. Destruction animation has no screen reader announcement
4. Text in bubbles is hard-coded font size, doesn't scale
5. Empty states have no semantics (screen readers read nothing)

**Recommended Design**:
- Every interactive widget needs `Semantics()` with a proper label
- Use `MediaQuery.textScaler` throughout
- Status indicators: always include `semanticsLabel: "Connected" / "Disconnected"`
- Touch targets: minimum 48×48 for all interactive elements
- Add `ExcludeSemantics` for decorative elements (avatars, dividers)

**Confidence**: 6/10 — This is the weakest area of the current design.

---

### 22. TABLET/DESKTOP ADAPTATION

| Role | Verdict |
|---|---|
| Apple HIG | iPad apps should not stretch phone layouts. The current spec's two-pane approach is correct. |
| Flutter Architect | Flutter's `LayoutBuilder` approach is correct. The current codebase isn't ready for it but the architecture supports it. |

**Weaknesses**:
- No responsive code exists in the current codebase
- All layouts are fixed-width phone layouts
- No `breakpoints.dart` or responsive utilities

**Recommended Design**:
- Create `lib/theme/breakpoints.dart`:
  ```dart
  class Breakpoints {
    static const double phone = 600;
    static const double tablet = 840;
    static const double desktop = 1200;
  }
  ```
- Create `lib/widgets/adaptive_scaffold.dart`:
  ```dart
  class AdaptiveScaffold extends StatelessWidget {
    // Phone: Navigator-based push
    // Tablet: Split view (list + detail)
    // Desktop: Split view with max width constraint
  }
  ```
- Start with phone-only v1, but architect for responsive from day one

**Confidence**: 9/10

---

### 23. FLUTTER ARCHITECTURE

| Role | Verdict |
|---|---|
| Flutter Architect | **The current Provider-based architecture is sufficient for v1 but will not scale.** For a team of 3+ developers, the lack of clear state boundaries will cause conflicts. |
| Linear PM | Extracting widgets is urgent. `chat_screen.dart` at 485 lines is already technical debt. `home_screen.dart` at 225 lines is manageable. |

**Weaknesses**:
- No test coverage (unit, widget, or integration)
- `chat_screen.dart` is doing too much (WS management, encryption, messaging, state)
- No clear separation between data layer and presentation layer
- `ConversationsProvider` mixes API calls with state management

**Recommended Design**:
- Extract `ChatProvider` or use a `ChatCubit` for chat screen state
- Move WS management to a dedicated `WebSocketService` (not in the screen)
- Add unit tests for all providers before phase 2
- Repository pattern: `ConversationRepository` wraps `MessagingService` and provides cached data

**Confidence**: 7/10

---

### 24. DESIGN SYSTEM

| Role | Verdict |
|---|---|
| Staff Product Designer | **The current design system in `lib/theme/` is a good start but incomplete.** Missing: focus styles, disabled states, error states for inputs, interactive elevation tokens. |
| Apple HIG | The teal palette is distinctive. Deep purple was wrong. Teal was the right choice. |

**Weaknesses**:
- No focus/selection colors defined
- No error state colors for inputs
- No disabled state opacity tokens
- No surface elevation tokens (only Material defaults)
- No component-level design tokens

**Recommended Design**:
- Add:
  - `color/error-container` (light pink / dark red)
  - `color/focus` (a11y-compliant outline blue)
  - `color/disabled` (opacity 0.38 for text, 0.12 for background)
  - `elevation/resting`, `elevation/hovered`, `elevation/pressed` for interactive components
- Document all tokens in a single source of truth (`app_tokens.dart`)

**Confidence**: 8/10

---

### 25. BRAND CONSISTENCY

| Role | Verdict |
|---|---|
| Staff Product Designer | **The brand is clear: calm, private, intentional. Every screen reinforces this.** The question is whether the visual execution matches the brand promise. Current screens are functional but not yet "premium." |
| Principal PM | The "Conversation platform" framing (vs. "messaging app") needs to be reflected in UI copy. Every string should be reviewed. "Delete" → "Destroy". "End" → "Complete". "Chat" → "Conversation". |

**Weaknesses**:
- Inconsistent terminology: codebase uses "chat" and "conversation" interchangeably
- "New Conversation" screen title is correct. "ChatScreen" class name is wrong (should be "ConversationScreen")
- Status labels: "Active", "Completed", "Destroyed" — these are correct
- No copy style guide exists

**Recommended Design**:
- Create a copy style guide:
  - Always use "Conversation", never "Chat" in product-facing UI
  - Always use "Complete", not "End" or "Close"
  - Always use "Destroy", not "Delete" or "Remove"
  - Always use "You" and names, never generic labels
  - No exclamation points
- Rename `ChatScreen` → `ConversationScreen` in the codebase
- Rename `MainShell` → `AppShell`

**Confidence**: 9/10

---

## TOP 20 DESIGN IMPROVEMENTS (ranked by impact)

1. **Identity verification screen** — Without this, users have no way to trust they're talking to the right person
2. **"Complete" action out of overflow menu** — The defining product action cannot be hidden
3. **Compact conversation rows** — Current cards are too tall for the information they carry
4. **Lifecycle banner in chat** — Users need constant awareness of conversation state
5. **Undo grace period for completion** — Accidental completion is catastrophic
6. **Inbox concept for pending invitations** — Conversations that haven't been opened need a home
7. **Silent notifications with no preview** — Privacy-respecting notification model
8. **Exponential backoff for WS reconnection** — Prevents server hammering
9. **Skeleton screens instead of spinners** — Perceived performance improvement
10. **Semantics labels on all components** — Accessibility is not optional
11. **Dynamic Type / font scaling** — Users with visual impairments need this
12. **Banner-style error states (not dialogs)** — Less blocking, more calm
13. **Conversation screen provider extraction** — `chat_screen.dart` is already too long
14. **Swipe-to-delete disabled device** — Device management needs actionability
15. **Focus indicators for keyboard navigation** — Desktop/web will need this
16. **Reduced motion support for destruction animation** — Accessibility requirement
17. **Completed/destroyed message indicators for other participants** — Both sides need visibility
18. **Search respects lifecycle** — Searching a completed conversation shouldn't imply permanence
19. **Copy style guide** — Inconsistent terminology undermines brand
20. **Responsive scaffolding from day one** — Even if only phone is built, architect for tablet now

---

## TOP 20 IMPLEMENTATION RISKS

1. **WS reconnection without exponential backoff** — High server load during outages
2. **Token expiry during active session** — Silent failures, user loses trust
3. **Encrypted key not cached locally** — Group key fetch fails when offline
4. **Group key cache management** — If a user leaves a group, their cached key needs invalidation
5. **No test coverage for providers** — State changes will break silently
6. **chat_screen.dart growth** — Will become unmaintainable before v1
7. **Destroy animation jank on low-end devices** — Staggered animations are expensive
8. **No error boundary for WS messages** — Malformed messages crash the chat screen
9. **API client returns unstructured errors** — Error handling will be inconsistent
10. **No connectivity detection** — Offline behaviors are completely undefined
11. **flutter_secure_storage platform issues** — Linux build already required workarounds
12. **Provider context access after async gap** — Current code has several `use_build_context_synchronously` patterns that were fixed but could regress
13. **Message decryption in build method** — `_decrypt` is called in a `FutureBuilder` in the build method, potentially decrypting every message on every rebuild
14. **No pagination for message loading** — Conversations with 1000+ messages will be slow
15. **No error state for group key fetch failure** — Chat loads but messages can't be decrypted
16. **Search without debounce** — Can cause rapid API calls if not carefully managed
17. **Section headers without animation** — Will feel abrupt when conversations move between sections
18. **No migration strategy for future versions** — Token format changes will break existing sessions
19. **Flutter version lock-in** — Current codebase uses Flutter 3.44.6. Upgrading Flutter SDK versions may break plugins
20. **No CI pipeline for design review** — Design decisions will drift over time

---

## TOP 20 UX RISKS

1. **No "why should I use this?" moment** — Users may not understand the value proposition
2. **Username-only identity feels incomplete** — Users expect email/phone verification
3. **Completed conversations linger too long** — Users forget to destroy them, cluttering the list
4. **"Destroy" is scary** — Users may never complete conversations because "destroy" sounds irreversible (which is the point, but may cause hesitation)
5. **No typing indicators confuse users** — "Did my message send? Is the other person there?"
6. **No read receipts feel like "ghosting"** — Some users will feel ignored
7. **Search doesn't find destroyed conversations** — Users may think the search is broken
8. **No invite flow** — "How do I get someone else to use Hush?" is unanswered
9. **No block/report flow** — What if someone sends unwanted messages?
10. **No way to verify the other person's destruction** — "Did they really delete the conversation?"
11. **Users tap "Complete" thinking it means "close and go back"** — Terminology mismatch with common UI patterns
12. **Two-tab model feels restrictive** — Power users will want more
13. **No conversation search within a conversation** — "Where did we talk about X?"
14. **Conversation list shows all participants** — In a 5-person group, showing all names is noisy
15. **No conversation themes** — Premium feel requires visual customization options
16. **Empty state teaches but doesn't guide** — Users may not know how to find other users
17. **No conversation pinning** — Important conversations bury beneath new ones
18. **No mute option** — If notifications are added, there's no granularity
19. **Destroy all conversations option** — Power users may want to wipe everything
20. **No export/backup** — Users who want to save messages have no option (privacy feature, but UX friction)

---

## TOP 20 SECURITY UX RISKS

1. **Identity verification is optional** — Users will skip it, undermining the trust model
2. **No visible encryption at rest indicator** — Users don't know messages are encrypted on device
3. **Copy-paste of messages** — Can be pasted into insecure apps. No screenshot detection (can't prevent, but should warn)
4. **Screen recording during active conversation** — No protection against screen recording on Android
5. **Notification previews on lock screen** — OS-level settings can leak message content
6. **Device not password/PIN protected** — Hush can't enforce device security
7. **Backup to iCloud/Google Drive** — Encrypted at rest but key management is complex
8. **No forward secrecy indicator** — Users don't know if past messages could be decrypted if a key is compromised
9. **Username enumeration** — Can attackers check if a username exists?
10. **No rate limiting feedback** — "Wrong password" / "Too many attempts" reveals attack surface
11. **No session management** — "Logged in on another device" has no UI
12. **Timing attacks on verification** — How long does verification take? Can an attacker infer proximity?
13. **Metadata leakage in conversation list** — The list reveals who you talk to, how often, and when
14. **No ephemeral profile** — A profile with an avatar can be reverse-image searched
15. **Audio call vulnerability** — Not in v1, but the architecture should consider it
16. **Group admin abuse** — In group conversations, can an admin remove someone? The current model has no admin concept
17. **No key rotation notification** — When keys rotate, users should be informed
18. **Spam/abuse reporting** — Reporting a conversation reveals its contents to a reviewer (privacy trade-off)
19. **Foreground service indicator** — On Android, a persistent notification says "Hush is running" — users may not understand why
20. **GDPR/CCPA compliance** — "Delete my data" requests need a workflow

---

## TOP 20 ACCESSIBILITY ISSUES

1. **No Semantics labels on message bubbles** — Blind users cannot read messages
2. **Status chip has no accessibilityLabel** — "Active" chip is read as unlabeled container
3. **Conversation cards not grouped as a single actionable element** — Screen readers navigate individual text nodes
4. **Send button has no semantics** — Read as "icon button" instead of "Send message"
5. **No focus order defined** — Tab order follows widget tree order, which may not be logical
6. **Font sizes not scalable** — Hard-coded 14-16px text breaks dynamic type
7. **No high contrast mode support** — Dark mode alone is not sufficient
8. **Green dot / red dot for connection status** — Color-only indicator with no text alternative
9. **Destroy animation has no screen reader announcement** — "Conversation destroyed" should be announced
10. **Empty states unreachable by screen readers** — No landmark or heading for empty state content
11. **Input field placeholder is not a label** — "Type a message..." disappears on focus, leaving no label
12. **No error announcements** — "Send failed" should be read by screen readers
13. **Popup menu items have no semantic grouping** — "More actions" is not descriptive
14. **Avatar images have no alt text** — Read as "circle" instead of "Alice's avatar"
15. **No skip-to-content link** — Keyboard users must tab through AppBar to reach messages
16. **Reduced motion not detected** — `MediaQuery.disableAnimations` is not checked
17. **Touch targets below 48dp** — Status chips, security badges, date labels are too small
18. **No visible focus ring on cards/buttons** — Keyboard navigation is invisible
19. **Contrast ratio for "Completed" status chip (grey on grey)** — May fail WCAG AA
20. **No support for right-to-left languages** — `Directionality` widget is not wrapped

---

## THE FINAL QUESTION

### If Apple were launching Hush tomorrow, what would they remove?

**They would remove:**
- **The destruction animation.** Apple would argue it's subjective, unnecessary, and could trigger motion sickness. They'd replace it with an instant state change accompanied by a subtle haptic. The emotional weight would come from the UI change, not an animation.
- **The overflow menu.** Apple would surface every primary action as a first-class control. "Complete" would be a button. Period.
- **The FAB.** Apple doesn't use FABs on iOS. The compose button would be in the navigation bar.
- **The connection indicator entirely.** Apple would say: "The app either works or it doesn't. Don't show infrastructure."
- **Status chips on conversation cards.** Apple would use typography and layout to differentiate state, not colored pills.

### What would Signal add?

**They would insist on:**
- **Identity verification as a first-class screen**, accessible from the chat header. Two taps, not four.
- **Safety number display** as an alternative to the word-based phrase (power users need it).
- **Forward secrecy guarantees** displayed somewhere in the security section.
- **Screen security** — prevent recent apps from showing conversation content on Android.
- **Proxy support** — for users in censored regions. Not in v1, but the conversation needs to start.
- **Open source the client code immediately** — "Trust through transparency" is Signal's mantra.

### What would Linear simplify?

**They would remove:**
- **The security badge.** Linear would ask: "What does this communicate that the user needs to know right now?" The answer is "nothing." Move it to a security detail screen.
- **The lifecycle progress bar** (the line I recommended). Linear would say: "This is decorative. Remove it."
- **The section headers** on the conversation list. Active/Closed adds visual noise. Let the user sort by status with a control, not a permanent section.
- **The completion undo banner.** "Adds complexity for an edge case. Ship without it. If users complain, add it."
- **Any animation over 200ms.** Linear optimizes for speed. Even the destruction animation would be 200ms max.

### What would the Accessibility team redesign?

**They would redesign everything that currently isn't accessible:**
- Every screen would have a clear heading hierarchy (h1 → h2 → h3)
- Every interactive element would be at least 48×48dp
- Every color would be checked against WCAG AAA (not just AA)
- Dynamic type would be supported before any custom styling is applied
- The destruction flow would have an alternative non-animated path
- Focus management would be explicitly designed: when a dialog opens, focus goes to the confirm button. When it closes, focus returns to the trigger.
- Screen readers would get custom announcements: "Conversation with Alice. Active. Double-tap to open."
- The search bar would have a clear label, not a placeholder

### What would the Privacy team insist on changing?

**They would demand:**
- **No message previews on the conversation list** — Currently the spec says no preview, which is correct. They would enforce this.
- **No server-side metadata retention** — The spec doesn't address this, but the Privacy team would want a visible privacy policy and data retention notice.
- **Ephemeral user IDs** — A user's ID should change periodically to prevent long-term tracking.
- **No analytics or telemetry** — No Firebase Analytics, no Crashlytics, no Mixpanel. If you must have crash reporting, it must be opt-in and anonymous.
- **No third-party SDKs** — Every dependency must be audited for data collection.
- **Screenshot blocking on Android** — Use `FLAG_SECURE` to prevent recent apps from showing conversation content.
- **Clipboard access warning** — Warn users when pasting content from Hush into other apps (iOS 14+ has this natively).
- **Network request logging** — The user should be able to see what data Hush sends to servers (a "network activity" log in settings).

---

## FINAL VERDICT

**Before implementation begins, resolve these three things:**

1. **Identity verification.** Design it. Implement it. Do not ship without it.
2. **Copy consistency.** "Conversation" everywhere. Not "chat". Not "message thread."
3. **Accessibility foundations.** Semantics labels. Dynamic type. Focus management. Build it in, not bolt it on.

**Everything else can be iterated.**

The product concept is strong. The design direction is correct. The execution needs restraint, consistency, and a relentless focus on the core promise: conversations that end.

**Score after review: 8.8 → 9.4/10** (potential)
**Score if the three blockers are resolved before v1: 9.8/10**
