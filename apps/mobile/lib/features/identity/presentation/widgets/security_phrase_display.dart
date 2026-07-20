import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/theme/theme.dart';

/// Displays a verification security phrase with large, readable text.
///
/// The phrase consists of two random words and a number (e.g. "BLUE RIVER 92").
/// Users compare this phrase out-of-band to verify each other's identity.
///
/// Supports:
/// - Copy to clipboard
/// - Large, readable typography
/// - Screen reader support
/// - Calm animation on reveal
class SecurityPhraseDisplay extends StatefulWidget {
  final String phrase;
  final bool showCopyButton;
  final double fontSize;

  const SecurityPhraseDisplay({
    super.key,
    required this.phrase,
    this.showCopyButton = true,
    this.fontSize = 28,
  });

  @override
  State<SecurityPhraseDisplay> createState() => _SecurityPhraseDisplayState();
}

class _SecurityPhraseDisplayState extends State<SecurityPhraseDisplay> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.phrase));
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final custom = HushCustomColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Security phrase: ${widget.phrase}',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: HushSpacing.xl,
              horizontal: HushSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius:
                  BorderRadius.circular(HushSpacing.borderRadiusMd),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              widget.phrase,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: cs.onSurface,
                  ),
              textAlign: TextAlign.center,
              semanticsLabel:
                  'Security phrase: ${widget.phrase.replaceAll(' ', ', ')}',
            ),
          ),
        ),
        if (widget.showCopyButton) ...[
          const SizedBox(height: HushSpacing.sm),
          Semantics(
            label: _copied ? 'Phrase copied' : 'Copy security phrase',
            button: true,
            child: SizedBox(
              height: HushSpacing.buttonHeight - 8,
              child: TextButton.icon(
                onPressed: _copy,
                icon: AnimatedSwitcher(
                  duration: HushMotion.fast,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    key: ValueKey(_copied),
                    size: 16,
                    color:
                        _copied ? custom.success : cs.onSurfaceVariant,
                  ),
                ),
                label: Text(
                  _copied ? 'Copied' : 'Copy phrase',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _copied
                            ? custom.success
                            : cs.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
