# ADR-011 — No Notifications by Default

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Product team  

## Context

Notifications are the primary driver of engagement in messaging apps. They are also the primary source of interruption and anxiety. Hush must balance usability (knowing when you have a message) with calm (not being interrupted).

## Options Considered

| Option | Rationale |
|---|---|
| **Full notifications by default** | Previews, sender name, sound. Industry standard. Drives engagement. |
| **Silent notifications by default** | "New Hush message" — no preview, no sender, no sound. User taps to see details. |
| **No notifications by default** | Maximum calm. User must opt in to any notification. Least interrupting. |
| **Notification on first message only** | User gets one notification when the first message arrives, then silence. Unique approach. |

## Decision

Hush ships with silent notifications by default. The notification reads: "New Hush message" — no sender name, no preview, no sound. Users can opt in to sender/preview/sound in settings.

## Rationale

- **Privacy (lock screen)**: Notification previews are a massive privacy leak. Anyone looking at the lock screen can see who messaged you and what they said. No preview by default prevents this.
- **Calm**: Silent notifications provide awareness without interruption. The user knows a message is waiting but is not compelled to open it immediately.
- **User choice**: Users who want more detailed notifications can opt in. This puts the privacy decision in the user's hands rather than forcing the least private option.
- **No "badge count anxiety"**: The badge shows a single count (or no count). Not a red badge with "27" that creates urgency.

## Consequences

- Positive: Lock screen privacy by default.
- Positive: Reduced interruption. Users check Hush when they want to.
- Positive: User-controlled notification granularity.
- Negative: Users may miss time-sensitive messages.
- Negative: Notification permission prompt must be carefully timed (not on first launch, but after first message is received).

## Notification Permission Timing

Notification permission is requested:
1. When the user receives their first message (in-app context)
2. Via a calm dialog that explains what they will and won't see
3. Only once — if declined, the option lives in Settings

## Related

- Product Canon — Principle 2 (The Default is Privacy)
- Product Canon — Principle 3 (Design for Deliberation, Not Addiction)
