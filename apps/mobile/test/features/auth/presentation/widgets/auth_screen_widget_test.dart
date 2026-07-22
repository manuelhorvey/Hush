import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/features/auth/domain/entities/device_identity.dart';
import 'package:hush_mobile/features/auth/presentation/screens/device_registration_screen.dart';
import 'package:hush_mobile/features/auth/presentation/screens/session_expired_screen.dart';
import 'package:hush_mobile/features/auth/presentation/screens/welcome_screen.dart';
import 'package:hush_mobile/features/auth/presentation/screens/identity_create_screen.dart';
import 'package:hush_mobile/features/auth/presentation/widgets/device_trust_card.dart';
import 'package:hush_mobile/features/auth/presentation/widgets/logout_confirmation_dialog.dart';
import 'package:hush_mobile/features/auth/presentation/widgets/security_notice.dart';
import 'package:hush_mobile/screens/login_screen.dart';

Widget _wrap(Widget child) {
  return ProviderScope(child: MaterialApp(home: child));
}

void _noop() {}

void main() {
  // ═══════════════════════════════════════════════════════════════
  // Session Expired Screen
  // ═══════════════════════════════════════════════════════════════

  group('SessionExpiredScreen', () {
    testWidgets('renders title and message', (tester) async {
      await tester.pumpWidget(_wrap(const SessionExpiredScreen()));

      expect(find.text('Your session has ended.'), findsOneWidget);
      expect(find.text('Please verify again to continue.'), findsOneWidget);
    });

    testWidgets('renders Sign in again button', (tester) async {
      await tester.pumpWidget(_wrap(const SessionExpiredScreen()));

      expect(find.text('Sign in again'), findsOneWidget);
    });

    testWidgets('has accessible tap targets', (tester) async {
      await tester.pumpWidget(_wrap(const SessionExpiredScreen()));
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Device Registration Screen
  // ═══════════════════════════════════════════════════════════════

  group('DeviceRegistrationScreen', () {
    testWidgets('renders trust message and continue button', (tester) async {
      await tester.pumpWidget(_wrap(const DeviceRegistrationScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('This device is now your'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Device trusted'), findsOneWidget);
    });

    testWidgets('renders device info rows', (tester) async {
      await tester.pumpWidget(_wrap(const DeviceRegistrationScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('This device'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('has accessible tap targets', (tester) async {
      await tester.pumpWidget(_wrap(const DeviceRegistrationScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Security Notice
  // ═══════════════════════════════════════════════════════════════

  group('SecurityNotice', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(_wrap(
        const SecurityNotice(message: 'Test message'),
      ));

      expect(find.text('Test message'), findsOneWidget);
    });

    testWidgets('renders detail when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const SecurityNotice(message: 'Test', detail: 'Detail text'),
      ));

      expect(find.text('Detail text'), findsOneWidget);
    });

    testWidgets('trusted factory renders correct message', (tester) async {
      await tester.pumpWidget(_wrap(SecurityNotice.trusted()));

      expect(find.text('This device is trusted'), findsOneWidget);
    });

    testWidgets('review factory renders correct message', (tester) async {
      await tester.pumpWidget(_wrap(SecurityNotice.review()));

      expect(find.text('Review this device'), findsOneWidget);
    });

    testWidgets('info factory renders custom message', (tester) async {
      await tester.pumpWidget(_wrap(
        SecurityNotice.info(message: 'Custom info message'),
      ));

      expect(find.text('Custom info message'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Logout Confirmation Dialog
  // ═══════════════════════════════════════════════════════════════

  group('LogoutConfirmationDialog', () {
    testWidgets('renders title and content', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LogoutConfirmationDialog(
                onConfirm: _noop,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sign out of this device?'), findsOneWidget);
      expect(
        find.textContaining('You can sign back in later'),
        findsOneWidget,
      );
    });

    testWidgets('renders Cancel and Sign out actions', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LogoutConfirmationDialog(
                onConfirm: _noop,
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Device Trust Card
  // ═══════════════════════════════════════════════════════════════

  group('DeviceTrustCard', () {
    final trustedDevice = DeviceIdentity(
      deviceId: 'd1',
      deviceName: 'My Phone',
      platform: 'mobile',
      createdAt: DateTime.now(),
      trustedStatus: DeviceTrustStatus.trusted,
    );

    final pendingDevice = DeviceIdentity(
      deviceId: 'd2',
      deviceName: 'New Tablet',
      platform: 'tablet',
      createdAt: DateTime.now(),
      trustedStatus: DeviceTrustStatus.pending,
    );

    final revokedDevice = DeviceIdentity(
      deviceId: 'd3',
      deviceName: 'Old Laptop',
      platform: 'desktop',
      createdAt: DateTime.now(),
      trustedStatus: DeviceTrustStatus.revoked,
    );

    testWidgets('renders device name', (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(device: trustedDevice),
      ));

      expect(find.text('My Phone'), findsOneWidget);
    });

    testWidgets('renders platform', (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(device: trustedDevice),
      ));

      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('renders trust label', (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(device: trustedDevice),
      ));

      expect(find.text('Device trusted'), findsOneWidget);
    });

    testWidgets('renders pending trust label', (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(device: pendingDevice),
      ));

      expect(find.text('Pending verification'), findsOneWidget);
    });

    testWidgets('renders revoked trust label', (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(device: revokedDevice),
      ));

      expect(find.text('Access revoked'), findsOneWidget);
    });

    testWidgets('renders Registered date', (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(device: trustedDevice),
      ));

      expect(find.textContaining('Registered'), findsOneWidget);
    });

    testWidgets('shows Rename and Remove buttons when callbacks provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        DeviceTrustCard(
          device: trustedDevice,
          onRename: () {},
          onRemove: () {},
        ),
      ));

      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Remove'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Login Screen
  // ═══════════════════════════════════════════════════════════════

  group('LoginScreen', () {
    testWidgets('renders title and login form', (tester) async {
      await tester.pumpWidget(_wrap(
        const LoginScreen(),
      ));

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
    });

    testWidgets('has accessible tap targets', (tester) async {
      await tester.pumpWidget(_wrap(
        const LoginScreen(),
      ));
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Welcome Screen
  // ═══════════════════════════════════════════════════════════════

  group('WelcomeScreen', () {
    testWidgets('renders tagline and action buttons', (tester) async {
      await tester.pumpWidget(_wrap(
        const WelcomeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.textContaining('Private conversations'),
        findsOneWidget,
      );
      expect(
        find.textContaining('No phone number or email required'),
        findsOneWidget,
      );
    });

    testWidgets('renders Create Identity and I have an identity buttons',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const WelcomeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Create Identity'), findsOneWidget);
      expect(find.text('I have an identity'), findsOneWidget);
    });

    testWidgets('has accessible tap targets', (tester) async {
      await tester.pumpWidget(_wrap(
        const WelcomeScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Identity Create Screen
  // ═══════════════════════════════════════════════════════════════

  group('IdentityCreateScreen', () {
    testWidgets('renders title and form', (tester) async {
      await tester.pumpWidget(_wrap(
        const IdentityCreateScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('Create your private identity'),
        findsOneWidget,
      );
      expect(find.text('Display name'), findsOneWidget);
      expect(find.text('Create Identity'), findsOneWidget);
    });

    testWidgets('renders privacy reassurance', (tester) async {
      await tester.pumpWidget(_wrap(
        const IdentityCreateScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.text('No phone number or contacts required.'),
        findsOneWidget,
      );
    });

    testWidgets('has accessible tap targets', (tester) async {
      await tester.pumpWidget(_wrap(
        const IdentityCreateScreen(),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      final handle = tester.ensureSemantics();
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  });
}
