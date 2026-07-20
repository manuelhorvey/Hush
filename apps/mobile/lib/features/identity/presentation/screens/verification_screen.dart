import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../models/verification_state.dart';
import '../providers/identity_notifier.dart';
import '../providers/identity_repository_provider.dart';
import '../widgets/privacy_education_card.dart';
import '../widgets/security_phrase_display.dart';
import '../widgets/trust_indicator.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  final String? phrase;
  final VerificationState initialState;

  const VerificationScreen({
    super.key,
    this.phrase,
    this.initialState = VerificationState.unknown,
  });

  @override
  ConsumerState<VerificationScreen> createState() =>
      _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen>
    with SingleTickerProviderStateMixin {
  late VerificationState _state;
  late String _phrase;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    _phrase = widget.phrase ?? _loadPhrase();
    _successController = AnimationController(
      vsync: this,
      duration: HushMotion.slow,
    );
    _successAnimation = CurvedAnimation(
      parent: _successController,
      curve: HushMotion.spring,
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  String _loadPhrase() {
    // Cache the phrase to ensure it doesn't change on every rebuild
    final user = ref.read(identityUserProvider);
    if (user?.verificationPhrase != null) return user!.verificationPhrase!;
    return ref.read(identityRepositoryProvider).generateVerificationPhrase();
  }

  void _startVerification() {
    ref.read(identityNotifierProvider.notifier).requestVerification();
    setState(() => _state = VerificationState.pending);
  }

  void _confirmVerification() {
    ref.read(identityNotifierProvider.notifier).confirmVerification();
    setState(() => _state = VerificationState.verified);
    _successController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: ResponsiveBuilder(
        builder: (context, size) {
          return ListView(
            padding: EdgeInsets.fromLTRB(
              HushSpacing.lg,
              size.isDesktop ? HushSpacing.xl : HushSpacing.lg,
              HushSpacing.lg,
              HushSpacing.xxl,
            ),
            children: [
              // Header
              _buildHeader(cs),

              const SizedBox(height: HushSpacing.xl),

              // Security phrase (cached, doesn't change on rebuild)
              SecurityPhraseDisplay(
                phrase: _phrase,
                fontSize: size.isPhone ? 24 : 28,
              ),

              const SizedBox(height: HushSpacing.xl),

              // Verification status card
              _buildStatusCard(cs),

              if (_state == VerificationState.verified) ...[
                const SizedBox(height: HushSpacing.xl),
                FadeTransition(
                  opacity: _successAnimation,
                  child: _buildVerifiedState(cs),
                ),
              ],

              const SizedBox(height: HushSpacing.xl),

              // How it works
              _buildHowItWorks(cs),

              const SizedBox(height: HushSpacing.lg),

              // Privacy education
              PrivacyEducationCard.verified(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
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
                height: 1.6,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(ColorScheme cs) {
    final custom = HushCustomColors.of(context);

    final (bgColor, borderColor, accentColor) = switch (_state) {
      VerificationState.verified => (
        custom.successContainer.withValues(alpha: 0.3),
        custom.success.withValues(alpha: 0.3),
        custom.success,
      ),
      VerificationState.warning => (
        custom.warningContainer.withValues(alpha: 0.3),
        custom.warning.withValues(alpha: 0.3),
        custom.warning,
      ),
      VerificationState.pending => (
        cs.secondaryContainer.withValues(alpha: 0.3),
        cs.secondary.withValues(alpha: 0.3),
        cs.secondary,
      ),
      VerificationState.unknown => (
        cs.surfaceContainerHighest.withValues(alpha: 0.5),
        cs.outlineVariant,
        cs.onSurfaceVariant,
      ),
    };

    return Semantics(
      label: 'Verification status: ${_state.label}. Security phrase: $_phrase.',
      child: AnimatedContainer(
        duration: HushMotion.normal,
        curve: HushMotion.standard,
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // State header
            Row(
              children: [
                AnimatedSwitcher(
                  duration: HushMotion.fast,
                  child: TrustIndicator(
                    key: ValueKey(_state),
                    state: _state,
                    size: 16,
                  ),
                ),
                const SizedBox(width: HushSpacing.sm),
                Text(
                  _state.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: HushSpacing.md),

            // Instruction text
            Text(
              _state == VerificationState.verified
                  ? 'You have confirmed this identity.'
                  : 'Compare this phrase with the person you are talking to.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
            ),

            // Action buttons
            const SizedBox(height: HushSpacing.lg),

            if (_state == VerificationState.unknown)
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'Start verification',
                  button: true,
                  child: OutlinedButton.icon(
                    onPressed: _startVerification,
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    label: const Text('Start Verification'),
                  ),
                ),
              ),

            if (_state == VerificationState.pending)
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'Confirm the phrase matches',
                  button: true,
                  child: FilledButton.icon(
                    onPressed: _confirmVerification,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm Match'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedState(ColorScheme cs) {
    final custom = HushCustomColors.of(context);
    return Semantics(
      label: 'Verification complete. Identity verified.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: custom.successContainer,
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(
            color: custom.success.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 24,
                  color: custom.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Identity Verified',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: custom.success,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: HushSpacing.sm),
            Text(
              "You have confirmed this person's identity.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: custom.onSuccess,
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks(ColorScheme cs) {
    return Semantics(
      label: 'How verification works. Three steps.',
      child: Container(
        padding: const EdgeInsets.all(HushSpacing.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HushSpacing.borderRadiusMd),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
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
            _Step(
              number: '1',
              title: 'Share this phrase',
              description:
                  'Read this phrase to the person you want to verify.',
            ),
            const SizedBox(height: HushSpacing.sm),
            _Step(
              number: '2',
              title: 'Compare',
              description:
                  'Ask them to read their phrase. They should match yours.',
            ),
            const SizedBox(height: HushSpacing.sm),
            _Step(
              number: '3',
              title: 'Confirm',
              description:
                  'If the phrases match, confirm the verification.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _Step({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
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
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
