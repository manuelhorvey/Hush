# Hush Design System

The shared visual language for the Hush privacy-first conversation platform.

## Principles

- **Calm** — No visual noise. Purposeful whitespace. Understated elegance.
- **Privacy** — Security indicators are subtle but present. No technical jargon (avoid "E2EE" in UI).
- **Trust** — Clear identity and verification states. Transparent system status.
- **Intentionality** — Every component has a reason to exist. No decorative elements.
- **Premium** — Refined typography, deliberate motion, consistent spacing.

## Architecture

```
design_system/
├── theme/           # Design tokens — colors, spacing, radius, shadows, motion
├── animations/      # Reusable motion utilities (fade, slide, scale, stagger)
├── components/
│   ├── avatars/     # UserAvatar, InitialsAvatar
│   ├── buttons/     # PrimaryButton, SecondaryButton, TextButton, DestructiveButton, IconButton
│   ├── cards/       # HushCard, SectionCard, ConversationCard, SettingsGroup
│   ├── dialogs/     # HushDialog (confirm/info), HushBottomSheet
│   ├── feedback/    # HushSnackbar, HushToast, InlineError, SuccessMessage, ErrorState
│   ├── indicators/  # LoadingIndicator, StatusBadge, OfflineBanner, ShimmerLoading
│   ├── inputs/      # HushTextField, HushSearchBar
│   ├── lifecycle/   # LifecycleBanner (Active/Waiting/Completing/Closed/Destroyed)
│   ├── messages/    # HushMessageBubble, MessageInputBar, MessageList, ConversationAppBar
│   ├── navigation/  # HushAppBar, HushScaffold
│   └── security/    # SecurityBadge (Private/Verified/Warning)
├── responsive/      # ResponsiveBuilder, AdaptivePadding, AdaptiveWidth, AdaptiveColumn
├── design_system.dart  # Barrel export — import everything from one file
└── README.md
```

## Token Reference

| Category | Classes | File |
|----------|---------|------|
| Colors | `HushColors` (light/dark), `HushCustomColors` (ThemeExtension) | `theme/colors.dart`, `theme/hush_theme_extensions.dart` |
| Spacing | `HushSpacing` (xs=2 → huge=64) | `theme/spacing.dart` |
| Radius | `HushRadius` (xs=4 → full=999) | `theme/radius.dart` |
| Shadows | `HushShadows` (none=0 → xl=8) | `theme/shadows.dart` |
| Motion | `HushMotion` (durations + curves) | `theme/motion.dart` |
| Opacity | `HushOpacity` (disabled=0.38 → high=0.87) | `theme/opacity.dart` |
| Typography | `HushTypography` (15 text styles) | `theme/typography.dart` |

## Component Usage Guidelines

### Do

- Import from the barrel: `import 'package:hush_mobile/core/design_system/design_system.dart';`
- Use semantic colors — never hardcode hex values.
- Support dark mode by referencing `Theme.of(context).colorScheme` or `HushCustomColors.of(context)`.
- Wrap interactive elements with `Semantics` for screen reader support.
- Use `expanded: true` on buttons that should fill their container width.
- Use named constructors for security/empty-state variants: `SecurityBadge.verified()`, `HushEmptyState.noConversations()`.

### Don't

- Don't import directly from individual component files (use the barrel).
- Don't use deprecated `ColorScheme.background` — use `surface` instead.
- Don't hardcode `maxWidth` — use responsive utilities or percentage-based widths.
- Don't expose "E2EE" in UI labels — use "Private" instead.
- Don't add business logic to design system components.
- Don't add provider/service dependencies to reusable widgets.

## Accessibility

All components support:
- `Semantics` labels on interactive and meaningful elements
- `liveRegion` on banners and dynamic content
- `MediaQuery.accessibleNavigation` and `MediaQuery.disableAnimations` (reduced motion)
- Minimum 48x48 touch targets on interactive elements
- WCAG 2.5.5 compliant touch target size constant (44)

## Dark Mode

Dark mode is supported by:
- `HushTheme.light` / `HushTheme.dark` full Material theme configurations
- `HushCustomColors.light` / `HushCustomColors.dark` ThemeExtension instances
- Theme-aware all components via `Theme.of(context).colorScheme`

## Testing

Component tests live in `test/design_system/components/`. Each test verifies:
- Rendering with default properties
- Interactive states (tap, disabled)
- Accessibility semantics
- All named variants

Run: `flutter test test/design_system/`

## Component Inventory

| Component | Variants | States | Accessibility |
|-----------|----------|--------|---------------|
| HushButton | filled, outline, text, danger | default, pressed, disabled, loading | Semantics, min 48x48 |
| HushIconButton | - | enabled, disabled | Semantics, tooltip |
| HushCard | default, identity | - | Semantics label |
| ConversationCard | active, closed | - | Semantics label |
| StatusBadge | neutral, success, warning, error, info | - | Semantics label |
| SecurityBadge | private, verified, warning | - | Semantics label |
| HushMessageBubble | sent, received | normal, sending, delivered, failed | Semantics label |
| MessageInputBar | - | active, disabled | Semantics |
| LifecycleBanner | active, waiting, completing, closed, destroyed | - | Semantics, liveRegion |
| InlineError | - | - | Semantics, liveRegion |
| SuccessMessage | - | - | Semantics, liveRegion |
| HushSnackbar | success, error, info, warning | - | Semantics |
| HushToast | success, error, info, warning | - | Semantics, liveRegion |
| ShimmerLoading | rectangle, conversation list | - | - |
| UserAvatar | photo, initials | - | Semantics |

## Future Improvements

- Golden file tests for visual regression
- Widgetbook/Storybook integration for interactive documentation
- Custom font family integration
- Tertiary color family in HushColors
- Animated list transitions for conversation reordering
- Keyboard navigation focus indicators
