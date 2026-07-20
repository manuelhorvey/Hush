import 'hush_button.dart';

export 'hush_button.dart' show
    HushButton,
    HushOutlineButton,
    HushTextButton,
    HushDangerButton;
export 'hush_icon_button.dart' show HushIconButton;

/// Primary action button.
/// Use for main CTAs like "Create Identity", "Start a Moment".
typedef PrimaryButton = HushButton;

/// Secondary outline button.
/// Use for alternative actions like "Cancel", "Back".
typedef SecondaryButton = HushOutlineButton;

/// Text-only button.
/// Use for less prominent actions.
typedef TextActionButton = HushTextButton;

/// Destructive action button.
/// Use for irreversible actions like "Destroy", "Delete".
typedef DestructiveButton = HushDangerButton;
