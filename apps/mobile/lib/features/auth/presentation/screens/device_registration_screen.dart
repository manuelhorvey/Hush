import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/theme/theme.dart';
import '../../../../core/responsive/responsive_layout.dart';
import '../../../../theme/app_spacing.dart';

/// Device registration confirmation screen.
///
/// Shown immediately after identity creation to confirm that this device
/// is now a trusted endpoint for the user's identity.
///
/// Message: "This device is now your private Hush device."
/// Displays: device name, platform, created date.
/// Action: Continue to the app.
class DeviceRegistrationScreen extends ConsumerStatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  ConsumerState<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState
    extends ConsumerState<DeviceRegistrationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: FadeTransition(
              opacity: _fadeIn,
              child: ScaleTransition(
                scale: _scale,
                child: ResponsiveBuilder(
                  builder: (context, size) {
                    final contentWidth =
                        size.isDesktop || size.isTablet ? 420.0 : double.infinity;
                    return SizedBox(
                      width: contentWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 32),

                          // Success icon
                          Semantics(
                            label: 'Device registered successfully',
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    cs.primaryContainer,
                                    cs.primary.withValues(alpha: 0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 44,
                                color: cs.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Trust message
                          Semantics(
                            label: 'This device is now your private Hush device',
                            child: Text(
                              'This device is now your\nprivate Hush device.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Explanation
                          Semantics(
                            label:
                                'Your identity is securely stored on this device and ready to use.',
                            child: Text(
                              'Your identity is securely stored on this '
                              'device and ready to use.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Device info card
                          Semantics(
                            label: 'Device information',
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(HushSpacing.lg),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(
                                    HushSpacing.borderRadiusMd),
                              ),
                              child: Column(
                                children: [
                                  _DeviceInfoRow(
                                    icon: Icons.phone_android_rounded,
                                    label: 'Device',
                                    value: 'This device',
                                  ),
                                  const SizedBox(height: HushSpacing.md),
                                  _DeviceInfoRow(
                                    icon: Icons.language_rounded,
                                    label: 'Platform',
                                    value: _detectPlatform(),
                                  ),
                                  const SizedBox(height: HushSpacing.md),
                                  _DeviceInfoRow(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Created',
                                    value: 'Just now',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Trust language
                          Semantics(
                            label: 'Device trusted',
                            child: Container(
                              padding: const EdgeInsets.all(HushSpacing.md),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_rounded,
                                    size: 16,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: HushSpacing.sm),
                                  Text(
                                    'Device trusted',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: cs.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            height: HushSpacing.buttonHeight,
                            child: Semantics(
                              label: 'Continue to your private space',
                              child: FilledButton.icon(
                                onPressed: () => context.go('/chats'),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const Text('Continue'),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _detectPlatform() {
    // Platform detection
    return 'Mobile';
  }
}

class _DeviceInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DeviceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: HushSpacing.md),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
