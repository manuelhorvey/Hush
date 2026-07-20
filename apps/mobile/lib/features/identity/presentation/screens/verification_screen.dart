import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../providers/identity_provider.dart';
import '../widgets/verification_card.dart';
import '../../models/verification_state.dart';

class VerificationScreen extends StatefulWidget {
  final String phrase;
  final VerificationState initialState;

  const VerificationScreen({
    super.key,
    required this.phrase,
    this.initialState = VerificationState.unknown,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  late VerificationState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          HushSpacing.lg,
          HushSpacing.lg,
          HushSpacing.lg,
          HushSpacing.xxl,
        ),
        children: [
          _buildHeader(context, cs),
          const SizedBox(height: HushSpacing.xl),
          VerificationCard(
            state: _state,
            phrase: widget.phrase,
            onStartVerification: () {
              context.read<IdentityProvider>().requestVerification();
              setState(() => _state = VerificationState.pending);
            },
            onConfirm: () {
              context.read<IdentityProvider>().confirmVerification();
              setState(() => _state = VerificationState.verified);
            },
          ),
          const SizedBox(height: HushSpacing.xl),
          _buildHowItWorks(context, cs),
          if (_state == VerificationState.verified) ...[
            const SizedBox(height: HushSpacing.xl),
            _buildVerifiedActions(context, cs),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Identity',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Verification helps you confirm that you are speaking '
          'with the person you expect.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks(BuildContext context, ColorScheme cs) {
    return Semantics(
      label: 'How verification works. Three steps.',
      child: Container(
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How it works',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: HushSpacing.md),
            _step(context, '1', 'Share this phrase',
                'Read this phrase to the person you want to verify.'),
            const SizedBox(height: HushSpacing.sm),
            _step(context, '2', 'Compare',
                'Ask them to read their phrase. They should match.'),
            const SizedBox(height: HushSpacing.sm),
            _step(context, '3', 'Confirm',
                'If the phrases match, confirm verification.'),
          ],
        ),
      ),
    );
  }

  Widget _step(BuildContext context, String number, String title, String description) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: HushSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedActions(BuildContext context, ColorScheme cs) {
    return Semantics(
      label: 'Verification complete',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: HushColors.successContainer,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(
            color: HushColors.success.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded,
                    size: 20, color: HushColors.success),
                const SizedBox(width: 8),
                Text(
                  'Identity Verified',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: HushColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              'You have confirmed this person\'s identity.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HushColors.onPrimaryContainer,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
