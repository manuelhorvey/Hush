# ADR-013 — No Analytics or Telemetry

**Status**: Accepted  
**Date**: 2026-07-20  
**Author**: Privacy team  

## Context

Most applications collect usage analytics to understand user behavior, identify issues, and inform product decisions. This conflicts with Hush's privacy commitment if not handled carefully.

## Options Considered

| Option | Rationale |
|---|---|
| **Full analytics** | Firebase Analytics, Mixpanel, or similar. Track events, screen views, user behavior. Industry standard. | 
| **Opt-in crash reporting only** | Collect crash reports with user consent. No behavioral analytics. |
| **No analytics or crash reporting** | Maximum privacy. No data leaves the device without explicit user action. |

## Decision

Hush will never implement behavioral analytics (event tracking, screen views, funnels). Crash reporting is opt-in, anonymous, and minimal (stack trace only, no user identifiers).

## Rationale

- **Privacy commitment**: Analytics are surveillance tools repackaged as product tools. Every event tracked is metadata that could identify user behavior patterns.
- **Philosophical alignment**: Hush's product model is not engagement-driven. Measuring engagement would incentivize engagement-maximizing features, which is the opposite of Hush's goals.
- **Trust**: Users who verify that Hush collects no data will trust the product more. Any analytics — even anonymous — erodes that trust.
- **Alternative**: Product decisions should be informed by direct user research, not passive analytics. Talk to users, don't track them.

## Consequences

- Positive: Complete privacy. No behavioral data collected.
- Positive: No analytics SDK dependencies (smaller binary, no third-party network requests).
- Positive: Stronger trust signal for privacy-conscious users.
- Negative: No data-driven understanding of user behavior. Product decisions rely on qualitative research.
- Negative: Harder to diagnose issues without crash reporting data.
- Negative: Cannot measure feature adoption or engagement.

## Crash Reporting

Crash reporting, if implemented, follows strict rules:
- Opt-in only (requested after a crash occurs, not during onboarding)
- Anonymous (no device ID, user ID, or session ID)
- Stack trace only (no app state, no screen context, no user input)
- User can view the crash report before sending
- The entire crash reporting system is open source and auditable

## Related

- Product Canon — Principle 2 (The Default is Privacy)
- Product Canon — Part III (What Hush Is Not)
