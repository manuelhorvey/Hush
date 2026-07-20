# Hush — Product Specification

> A privacy-first messaging platform built around temporary conversations.
> "Digital conversations should be allowed to have a natural ending."

---

## SECTION 1 — PRODUCT EXPERIENCE

### UX Philosophy

Hush treats conversation as a **finite, intentional act** — not an infinite scroll. Every interaction asks: *does this reinforce trust, calm, and purpose?*

**Emotional model**: Entering a Hush conversation should feel like stepping into a quiet room where you know exactly who is there, why you're talking, and that nothing lingers after you leave.

**Key emotional states**:
| State | Feeling |
|---|---|
| Pre-conversation | Anticipation, security (verified participants) |
| Active conversation | Focus, presence, connection |
| Completion | Closure, satisfaction |
| Destruction | Finality, peace of mind |

**Interaction philosophy**: Deliberate over instant. Every action has a clear trigger and a visible outcome. No accidental sends, no "oh I didn't mean to" moments.

**Trust-building strategy**:
1. **Transparency** — Show encryption state visibly (not hidden in a menu)
2. **Progressive disclosure** — Reveal security details on demand, don't overwhelm
3. **User-controlled destruction** — Completion is always user-initiated, never automatic without consent
4. **Visual evidence** — Show destruction confirmation (no fake "deleted" toasts)

### Onboarding Philosophy

Do not ask for phone number, email, contacts, or notifications on first launch.

**Onboarding flow**:
1. Splash → brief brand moment (calm, not flashy)
2. Identity creation screen — create a username, that's it
3. That's the app. No tutorial. No permissions.

Trust is earned by *not* asking for things up front.

---

## SECTION 2 — INFORMATION ARCHITECTURE

### App Hierarchy

```
App root
├── Splash (auth check)
├── Identity Creation (first launch)
├── Main Shell
│   ├── Tab 1: Conversations (home)
│   │   ├── Conversation list (default)
│   │   ├── Search overlay
│   │   └── New conversation flow
│   │       ├── User search
│   │       └── Chat screen
│   │           ├── Message list
│   │           ├── Input bar
│   │           ├── Info panel (participants)
│   │           └── Complete/Destroy actions
│   └── Tab 2: Settings
│       ├── Profile card
│       ├── Devices
│       ├── Security & Privacy
│       ├── Appearance
│       └── About
```

### Navigation Model

**Android**: Bottom Navigation Bar (2 tabs: Chats, Settings)
**iOS**: Bottom Tab Bar (same)

No drawer. No hamburger menu. Two destinations — conversations and settings. Everything else is a pushed screen.

### Back Navigation

- Chat screen → conversation list (back)
- New conversation → conversation list (back)
- Settings → pushed screens pop to settings
- Always preserve scroll position in conversation list

### State Transitions

```
App launch
  ├── Token exists → Splash (1.5s) → Main Shell (Conversations tab)
  └── No token → Splash (1.5s) → Identity Creation → Main Shell

Conversation lifecycle:
  Created (server confirms) → Active (chat open, typing)
  → Completed (user taps complete) → Active read-only
  → Destroyed (user confirms destruction) → removed from list

Offline:
  Online → Offline: banner appears, "Reconnecting..." indicator in chat
  Offline → Online: messages sync, indicator clears
  No network for 30s: show offline state with retry
```

---

## SECTION 3 — DESIGN SYSTEM (Executive Summary)

The existing design system in `lib/theme/` is a solid foundation. Here are the refinements needed:

### Color Tokens (already in place, refine)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `primary` | Teal 600 | Teal 200 | Primary actions, active indicators |
| `primaryContainer` | Teal 100 | Teal 800 | Selected states, avatar backgrounds |
| `surface` | White | Neutral 900 | Card/background surfaces |
| `surfaceContainerHighest` | Neutral 95 | Neutral 800 | Input backgrounds, dividers |
| `onSurface` | Neutral 900 | White | Primary text |
| `onSurfaceVariant` | Neutral 500 | Neutral 400 | Secondary text, hints |

**Add**: A `secure` green semantic color for verified/encrypted states. Not for buttons — just indicators.

### Typography (already in place, good)

The current text scale (display → label) is correct. No changes needed.

### Spacing (4/8pt system — keep as-is)

Current `HushSpacing` with 4px base is correct.

### Elevation & Shadows

Use Material 3 elevation tokens. No custom shadows. Let the theme handle it.

### Corner Radius

- Cards: 12px
- Buttons: 20px (pill)
- Message bubbles: 16px top, 4px bottom (tail)
- Dialogs: 16px
- Input fields: 12px

### Motion Language (see Section 8)

---

## SECTION 4 — COMPONENT LIBRARY

### ConversationCard (already exists in home_screen.dart)

**Variants**: Active, Completed, Destroyed

**States**: Default, Pressed (InkWell ripple)

**Structure**:
```
┌──────────────────────────────────────┐
│ [Avatar]  Username            Status │
│           Date                ›     │
└──────────────────────────────────────┘
```

- Avatar: 44×44, rounded 10px, initial letter on primaryContainer
- Status chip: Active (teal), Completed (grey), Destroyed (red)
- Chevron: subtle, 16px
- No subtitle text. Just username and payload

**Edges**: If username is unknown, show "Unknown user" with a warning icon.

### MessageBubble

**Variants**: Sent, Received

**Structure**:
```
Sent (right-aligned):
  ┌──────────────────┐
  │ Message text     │
  │ 12:34            │
  └──────────────────┘

Received (left-aligned):
  ┌──────────────────┐
  │ Message text     │
  │ 12:34            │
  └──────────────────┘
```

- Max width: 75% of screen
- Timestamp: 11px, inside bubble, right-aligned
- No sender name on received (we already know who we're talking to)
- Show sender name ONLY in group conversations

**Security indicator**: Small lock icon next to each message (12px) — not prominent, just present. Confirms E2EE without being noisy.

### IdentityCard (for settings/devices)

```
┌──────────────────────────────────────┐
│ [Avatar]  Username                   │
│           user_id (truncated)        │
│           [Verified badge]           │
└──────────────────────────────────────┘
```

### SecurityBadge

Small lock + "E2EE" text. Shown in:
- Chat screen AppBar (next to title)
- Participant verification dialog
- Settings security section

### LifecycleBanner

A subtle banner at the top of a completed conversation:
"Conversation completed — messages will be permanently destroyed on [date]"

Destroyed state: Show nothing. The conversation is gone.

### StatusChip (already exists)

Keep as-is. Active (teal), Completed (grey), Destroyed (red).

### EmptyState (already exists in home_screen.dart)

Update the message for when search returns nothing:
"No conversations found" (not zero-state, which says "Tap + to start")

### PermissionsPrompt

Only shown when user explicitly triggers a permission-needing action:
- Camera (for future feature)
- Notifications (off by default, opt-in only)
- No "allow notifications" on first launch — ever.

---

## SECTION 5 — SCREENS

### Splash Screen (already implemented well)

The shield icon with fade+scale is good. Duration: 1.5s. Crossfade to destination.

### Identity Creation Screen

**Purpose**: First launch only. Create a username to begin.

**Layout**:
```
      [Logo]
      
  Choose your username
  [________________]
  
  Your username is how others find you.
  You can change it later.
  
  [Continue]  ← disabled until 3+ chars, valid
```

**Rules**:
- 3-20 chars, alphanumeric + underscores
- Real-time availability check (debounced 500ms)
- Show availability inline: green check / red X + suggestion
- No email, no phone, no password on first launch
- This IS the account creation

### Home Screen (Conversation List) — current design needs minor updates

Replace username AppBar with search bar ✅ (just done)

Add **section headers**:
- "Active" section (expandable by default)
- "Past" section (collapsed by default, contains completed/destroyed)

```
AppBar: [ Search conversations...          ]

Active (3)
┌──────────────────────────────────────┐
│ [A]  Alice                [Active]  │
│      2026-07-20            ›        │
└──────────────────────────────────────┘
┌──────────────────────────────────────┐
│ [B]  Bob +1              [Active]  │
│      2026-07-19            ›        │
└──────────────────────────────────────┘

Past (2) ▼
┌──────────────────────────────────────┐
│ [C]  Charlie            [Complete] │
│      2026-07-18            ›        │
└──────────────────────────────────────┘
```

FAB: "+" to start new conversation (current position is fine)

### New Conversation Screen — already implemented

Current flow (search → select → start) is correct. No changes needed.

### Chat Screen — current, needs refinements

**AppBar**:
- Back button (auto from Navigator)
- Username of other participant(s) (✅ just fixed)
- Lock icon (E2EE indicator)
- Popup menu: Participants, Complete Conversation, Destroy
- Connection indicator: green dot / grey dot (current implementation)

**Body**:
- Message list, scroll to bottom on new message
- Date separators for multi-day conversations ("Today", "Yesterday", "Jul 15")
- No "typing..." indicator (directional, addictive pattern). Instead, show a subtle "online" dot if the other user is actively in this conversation.

**Input bar**:
- Text field with "Message" placeholder
- Send button (filled icon)
- Enter sends (mobile: send button, desktop: Enter key)
- No voice messages (distraction)
- No emoji picker in v1 (scope control)
- No file attachments in v1 (scope control)

**Completion flow**:
- User taps overflow menu → "Complete Conversation"
- Dialog: "This will end the conversation. Messages will be preserved until you choose to destroy them."
- Confirm → AppBar switches to read-only mode, input bar replaced with:
  "Conversation completed. [Destroy Permanently]"

**Destruction flow**:
- From completed state: tap "Destroy Permanently"
- Dialog: "This will permanently delete all messages. This action cannot be undone."
- Confirm → loading spinner → conversation removed → pop back to list
- Animation: messages fade out, screen collapses → pop

### Settings Screen

**Sections**:

1. **Profile** (current implementation is good)
   - Avatar (initial-based)
   - Username
   - User ID (truncated, copy on tap)

2. **Account**
   - My Devices → device list
   - Security & Privacy → future
   - Change Username → future

3. **Preferences**
   - Appearance (System/Light/Dark) → future
   - Notifications → future (off by default)
   - Language → future

4. **About**
   - Version
   - Open source licenses

5. **Sign Out** (at bottom, with warning)

### Devices Screen — current is fine

Participant/device management for identity verification.

### No "Notifications", "Help", "Feedback", "Recovery" screens in v1

These are scope creep. Notifications are off by default. Help is the calm design itself. Feedback is out of scope.

---

## SECTION 6 — USER FLOWS

### New User Flow

```
1. App launch → Splash (1.5s)
2. No token → Identity Creation
3. Enter username (3+ chars, available, debounced)
4. Tap Continue → API create identity → store token
5. Transition to Main Shell (conversations tab, empty state)
6. See "Tap + to start" + FAB
```

### Start Conversation Flow

```
1. Tap FAB (+) → New Conversation screen
2. Search users by username
3. Tap user to select (multi-select for groups)
4. Tap "Start (N)" in AppBar
5. Loading spinner → API creates conversation
6. Transition to Chat screen
7. Input bar active, ready to type
```

### Complete Conversation Flow

```
1. In chat screen, tap overflow menu (⋮)
2. Tap "Complete Conversation"
3. Dialog appears: explain consequences
4. Tap "Complete" → API call
5. AppBar status changes to "completed"
6. Input bar replaced with completed state + destroy option
```

### Destroy Conversation Flow

```
1. From completed state, tap "Destroy Permanently"
2. Dialog: "This cannot be undone. All messages will be permanently deleted."
3. Tap "Destroy" (red button)
4. Loading → fade animation → pop to list
5. Snackbar: "Conversation destroyed" (2s)
```

---

## SECTION 7 — MICROINTERACTIONS

| Interaction | Animation | Duration | Notes |
|---|---|---|---|
| Button press | Scale 0.97 → 1.0 | 100ms | Minimal feedback |
| Send message | Bubble slides up + fade | 200ms | Content appears, not send animation |
| Receive message | Bubble fades in | 300ms | Gentle appearance |
| Connect to WS | Green dot pulse | 400ms | Once, then steady |
| Disconnect | Dot turns grey, no animation | — | No alarm |
| Complete conv | Status chip transitions | 300ms | Active→Completed (color + text) |
| Destroy conv | Bubbles fade out top-down | 600ms | Then screen pops |
| Verification success | Checkmark draw animation | 400ms | Once, satisfying |
| Page transition | Slide (iOS) / Fade (Android) | 300ms | Respect platform |
| Input focus | Border highlight | 200ms | Subtle color shift |

**Motion language**: Ease-in-out. No bounces. No overshoot. Everything should feel like it was expected.

**Reduced motion**: Replace all animated transitions with instant crossfades (100ms). Remove animation sequences. Replace with static state changes.

---

## SECTION 8 — MOTION DESIGN (KEY ANIMATIONS)

### Conversation Destruction Sequence (the signature Hush moment)

This is the most important animation in the product.

```
1. User taps "Destroy" in confirmation dialog
2. Dialog closes (100ms fade)
3. 200ms pause (weight, gravity)
4. Messages begin fading from top of list, top to bottom
   - Each bubble fades over 200ms, staggered 50ms apart
   - Total: ~1-2s depending on message count
5. After last message fades: the conversation card itself fades on the list screen
   - 300ms fade + scale(1→0.95)
6. Empty state appears (or next conversation shifts up)
7. Snackbar: "Conversation destroyed" (2s, auto-dismiss)
```

**Why this matters**: This is the moment the user trusts that their data is gone. The animation provides visual evidence. A simple toast is not enough.

### Send Message

```
1. Text appears in bubble instantly (no send animation)
2. Bubble grows from 0 to full width over 150ms
3. Content fades in over 100ms
4. List scrolls to bottom over 200ms
```

**Why no send animation**: The user already knows what they typed. Animating the send is noise. The arrival of the bubble on the other side is where animation matters.

### Platform Adaptation

On iOS: use `CupertinoPageTransition` for everything (nav slides from right)
On Android: use `FadeUpwardsPageTransition` or custom fade

Check `Theme.of(context).platform` and adapt.

---

## SECTION 9 — ACCESSIBILITY

### Minimum Standards

- **WCAG AA** across all screens (contrast ratio 4.5:1 normal text, 3:1 large)
- **Touch targets**: minimum 48×48dp for all interactive elements
- **Focus indicators**: visible on all platforms (especially desktop)

### Screen Reader Support

Every component must have:
- `Semantics` widget or `semanticsLabel` on all interactive elements
- `excludeSemantics: true` on decorative elements (status dots, dividers)
- Button labels: "Send message", "Back to conversations", "Complete conversation"
- Status announcements: "Conversation completed", "Destroying conversation..."

### Color Blindness

Do NOT rely on color alone for status:
- Status chip has BOTH color + text label ("Active", "Completed", "Destroyed")
- Connection indicator has dot + label (tooltip: "Connected" / "Disconnected")
- Never: green = good, red = bad without text

### Reduced Motion

Check `MediaQuery.of(context).disableAnimations` or `AccessibilityFeatures.reduceMotion`.

When enabled:
- All page transitions → instant switch (0ms)
- Destroy animation → messages disappear instantly, screen pops
- No staggered animations
- No drawing animations
- Use `AnimatedOpacity` with `duration: Duration.zero` as fallback

### Motor Accessibility

- All actions accessible via navigation (focus + enter)
- Pull-to-refresh on conversation list
- No swipe-to-delete (too error-prone, requires confirmation dialog anyway)
- Long-press only for secondary actions (with alternative tap path)

---

## SECTION 10 — RESPONSIVE DESIGN

### Breakpoints

| Range | Target | Layout |
|---|---|---|
| < 360px | Small phone | Single column, minimal padding |
| 360-599px | Phone | Standard padding (current) |
| 600-839px | Large phone / small tablet | Adaptive, wider cards |
| 840-1199px | Tablet | Two-pane: list + detail |
| 1200px+ | Desktop | Two-pane with max-width center column |

### Adaptive Strategy

Use `LayoutBuilder` and `BoxConstraints` for breakpoint switching.

**Phone (<600px)**: Current design. Full-screen modal for chat.

**Tablet (600-1199px)**: Two-pane split:
- Left: conversation list (320px fixed width)
- Right: selected conversation (expanded)
- New conversation: modal overlay
- Settings: full-screen modal

**Desktop (1200px+)**:
- Same as tablet but centered in max-width container (960px)
- Chat bubbles cap at 600px width
- Everything constrained, no full-width anything

### Future Web Client

Same responsive approach. PWA for mobile web. Desktop app via Flutter.

---

## SECTION 11 — DESIGN LANGUAGE

### Brand Personality

Calm, competent, trustworthy. Think: **a boutique hotel lobby** vs. a nightclub.

- Voice: minimal, precise, reassuring
- No exclamation points in UI copy
- No "You've got mail!" enthusiasm
- No "Oops!" errors. Just errors.

### Visual Identity

- Shield icon (already implemented in splash) — protection, security
- Teal primary — associated with trust, security, healthcare (calming)
- Clean sans-serif (Inter or system default)
- No gradients on production UI (keep it flat, premium)
- Photography: None in v1
- Illustrations: Simple line art with rounded strokes. One color + accent. No complex scenes.

### Empty State Philosophy

Empty states are not "sad". They are peaceful.

"No conversations yet" (not "You have no conversations")

The empty state should feel like a clean desk, not a blank page.

### Security Visualization

- Lock icon: 14×14, outline style, always visible during active conversation
- Verification check: circle + checkmark, green, fills in with draw animation
- Destruction: gradual fade (the "dissolve" animation described above)
- Encryption badge: small pill with "E2EE" text, no lock icon duplication

---

## SECTION 12 — FRONTEND ARCHITECTURE (Flutter)

### Folder Structure (already close, refine)

```
lib/
├── app.dart                    # MultiProvider, MaterialApp.router
├── main.dart                   # Entry point
├── config/
│   └── api_config.dart         # Base URL, WS URL, timeouts
├── models/
│   ├── conversation.dart
│   ├── message.dart
│   ├── user.dart
│   └── device.dart
├── services/
│   ├── api_client.dart         # HTTP client, interceptors, error mapping
│   ├── auth_service.dart       # Login, register, token management
│   ├── messaging_service.dart  # Conversations, messages API
│   ├── identity_service.dart   # Keys, devices, verification
│   ├── crypto_service.dart     # Encrypt/decrypt, key management
│   └── websocket_service.dart  # WS connection, reconnection, message dispatch
├── providers/
│   ├── auth_provider.dart
│   ├── conversations_provider.dart
│   └── connectivity_provider.dart  # NEW: online/offline state
├── theme/
│   ├── app_colors.dart
│   ├── app_typography.dart
│   ├── app_spacing.dart
│   └── app_theme.dart
├── screens/
│   ├── main_shell.dart
│   ├── splash_screen.dart
│   ├── create_identity_screen.dart
│   ├── home_screen.dart
│   ├── chat_screen.dart
│   ├── new_conversation_screen.dart
│   ├── settings_screen.dart
│   └── devices_screen.dart
├── widgets/
│   ├── conversation_card.dart       # Extract from home_screen
│   ├── message_bubble.dart          # Extract from chat_screen
│   ├── status_chip.dart             # Already reusable
│   ├── lifecycle_banner.dart        # NEW
│   ├── security_badge.dart          # NEW
│   └── empty_state.dart             # NEW (reusable)
└── utils/
    ├── date_formatter.dart
    └── validators.dart
```

### State Management

Current Provider approach is fine for this scale. `provider` package with `ChangeNotifier`.

**Three providers max** (simplicity):
1. `AuthProvider` — session, token, userId, username (already exists)
2. `ConversationsProvider` — list, CRUD, search filter state (already exists)
3. `ConnectivityProvider` — online/offline, WS connection state (NEW)

No BLoC. No Riverpod. No Redux. Provider is sufficient for this app's complexity.

### Navigation

`Navigator 2.0` is overkill here. Use imperative `Navigator.of(context).push()`.

For deep linking (future): wrap in a `GoRouter` at the app level. For now, simple navigation.

### Dependency Injection

Current approach (Provider with constructor injection in `app.dart`) is correct.

```dart
MultiProvider(
  providers: [
    Provider<CryptoService>(create: (_) => CryptoService()),
    Provider<IdentityService>(create: (_) => IdentityService()),
    Provider<MessagingService>(create: (_) => MessagingService()),
    ChangeNotifierProvider<AuthProvider>(
      create: (ctx) => AuthProvider(auth: AuthService()),
    ),
    ChangeNotifierProvider<ConversationsProvider>(
      create: (ctx) => ConversationsProvider(
        messaging: ctx.read<MessagingService>(),
      ),
    ),
  ],
)
```

### Localization

Don't implement l10n in v1. Hard-code English. Add l10n in v2 using `flutter_localizations` + ARB files.

### Asset Organization

```
assets/
├── icons/         # App icons, no raster assets for UI
└── images/        # Splash shield illustration (SVG)
```

No raster images. Use SVG + Flutter `flutter_svg` or draw everything with Flutter widgets (circles, icons, text).

### Testing Strategy

```
tests/
├── unit/
│   ├── providers/
│   │   ├── auth_provider_test.dart
│   │   └── conversations_provider_test.dart
│   └── services/
│       └── crypto_service_test.dart
├── widget/
│   ├── conversation_card_test.dart
│   ├── message_bubble_test.dart
│   └── status_chip_test.dart
└── integration/
    └── chat_flow_test.dart
```

- Unit test providers (mock services)
- Widget test all reusable components
- Integration test: create conversation → send message → complete → destroy

### Offline Architecture

Offline is **out of scope for v1**. This is a conscious decision:

- Hush conversations are temporary and active for a short period
- Offline queuing adds encryption complexity (key rotation during offline period)
- Show clear offline state: "No connection" banner, try again when online
- Do NOT queue messages for later delivery in v1

```dart
// ConnectivityProvider
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void setOnline(bool v) {
    _isOnline = v;
    notifyListeners();
  }
}
```

Listen to `flutter_connectivity` or use WS close/open events.

---

## SECTION 13 — DESIGN QA

### Design Review Checklist

- [ ] Does this screen reinforce trust/calm?
- [ ] Is there anything addictive/attention-grabbing?
- [ ] Could any action happen accidentally?
- [ ] Is encryption state visible?
- [ ] Is the conversation lifecycle clear?
- [ ] Could a user get confused about what happens next?

### Accessibility Checklist

- [ ] All touch targets ≥ 48dp
- [ ] Color contrast ≥ 4.5:1
- [ ] Semantics labels on all interactive elements
- [ ] Text labels + color (not color-only)
- [ ] Reduced motion supported
- [ ] Focus visible
- [ ] Screen reader: all content reachable

### Animation Checklist

- [ ] Duration ≤ 300ms (except destruction sequence)
- [ ] No bounce curves
- [ ] Respects reduced motion
- [ ] Doesn't block interaction
- [ ] Platform-appropriate transitions

### Implementation Acceptance Criteria

For every component:
1. All states rendered (default, hover, focus, active, disabled)
2. Light + dark mode
3. Screen reader compatible
4. Reduced motion handled
5. Intrinsic sizing correct

---

## SECTION 14 — FIGMA ORGANIZATION

If created in Figma, organize as:

```
Pages:
├── 🖥️  Cover
├── 🎨  Design System
│   ├── Colors
│   ├── Typography
│   ├── Spacing & Grid
│   ├── Elevation & Shadows
│   └── Motion
├── 📦  Components
│   ├── Buttons
│   ├── Inputs
│   ├── Cards
│   ├── Message Bubbles
│   ├── Status Chips
│   ├── Dialogs & Sheets
│   └── Navigation
├── 📱  Screens — Phone
│   ├── Splash
│   ├── Identity Creation
│   ├── Home
│   ├── Chat
│   ├── New Conversation
│   ├── Settings
│   └── Devices
├── 📐  Screens — Tablet
│   └── (same screens, tablet layout)
├── 🖥️  Screens — Desktop
│   └── (same screens, desktop layout)
├── 🚶  User Flows
│   ├── New User
│   ├── Start Conversation
│   ├── Complete & Destroy
│   └── Settings
└── 📋  Handoff
    ├── Component specs
    └── Screen specs
```

**Variables**:
- `color/primary`, `color/primary-container`, etc.
- `spacing/xs` through `spacing/xxl`
- `corner-radius/sm`, `corner-radius/md`, `corner-radius/lg`
- `duration/fast`, `duration/medium`, `duration/slow`

**Components**: Use Auto Layout. Never position absolutely. Every component should resize naturally.

---

## SECTION 15 — IMPLEMENTATION ROADMAP

### Phase 1 — Design System Foundation (1-2 days)

- [ ] Refine color tokens (add `secure` green)
- [ ] Verify `app_theme.dart` completeness
- [ ] Extract reusable widgets from screens (conversation_card, message_bubble, empty_state)
- [ ] Create `lifecycle_banner.dart`, `security_badge.dart`
- [ ] Finalize `ConnectivityProvider`

### Phase 2 — Core Screens Polish (1-2 days)

- [ ] Home screen: section headers (Active / Past)
- [ ] Home screen: search bar ✅ (done)
- [ ] Chat screen: date separators
- [ ] Chat screen: remove fallback "Chat" title ✅ (done)
- [ ] Chat screen: security badge in AppBar
- [ ] Chat screen: completed state (read-only input)
- [ ] Complete Conversation dialog
- [ ] Destroy Conversation dialog + animation

### Phase 3 — Motion & Microinteractions (1 day)

- [ ] Destroy animation sequence (fade top-down)
- [ ] Send/receive bubble animations
- [ ] Connection indicator pulse
- [ ] Reduced motion support

### Phase 4 — Accessibility (1 day)

- [ ] Semantics labels on all interactive elements
- [ ] Focus indicators
- [ ] Test with screen reader
- [ ] Color-blind review

### Phase 5 — Responsive (2-3 days)

- [ ] Tablet two-pane layout
- [ ] Desktop constrained layout
- [ ] Foldable support

### Phase 6 — Polish & QA (1 day)

- [ ] Design QA pass
- [ ] Accessibility QA pass
- [ ] Edge case review
- [ ] Performance profile

---

## KEY DECISIONS & RATIONALE

### Why no notifications in v1?

Hush is about intentional communication. Notifications create a Pavlovian loop. The user checks the app when they want to, not when a badge tells them to. Notifications can be added later as an opt-in, but the default is no interruptions.

### Why no swipe actions?

Swipe is easy to trigger accidentally and hard to undo. Swipe-to-delete requires confirmation anyway (for destruction). Just use a tap target with a dialog. It's more deliberate.

### Why no read receipts?

Read receipts create social pressure to respond immediately. Hush is not about instant response. It's about intentional communication. The sender knows the message was delivered (server received it). That's enough.

### Why no typing indicators?

Same as read receipts. Typing indicators create anxiety ("they're waiting for me to finish"). Hush conversations are not real-time chat rooms. They're more like letters that arrive instantly.

### Why no contacts/address book integration?

Contacts integration ties your identity to your phone number, which is a privacy leak (your contacts know you're on Hush). Username-based discovery is more private. You share your username with who you want. No one can find you by phone number.

### Why "Complete" before "Destroy"?

This is the core of Hush's philosophy. A conversation deserves a recognized end. Completion is an intentional act that says "we're done here." The data still exists for a grace period. Destruction is the final, irreversible step. Two steps ensure nothing is accidental.

### Why no "delete for everyone" / "unsend"?

Undo mechanics undermine the permanence of destruction. If you can unsend, the recipient's trust is broken. If you want it gone, complete the conversation and destroy it. That's the contract.

### Why username-only identity?

Many users don't want to associate their real identity with a messaging app. A username is pseudonymous by default. No phone, no email, no real name required. This is a privacy-first decision.

---

*This document is a living specification. As implementation reveals gaps, update this document — not the other way around.*
