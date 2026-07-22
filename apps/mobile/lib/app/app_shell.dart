import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/indicators/offline_banner.dart';
import '../../core/responsive/responsive_layout.dart';
import '../../core/providers/connectivity_state_provider.dart';

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = !ref.watch(connectivityStateProvider).isOnline;

    return ResponsiveBuilder(
      builder: (context, size) {
        if (size.isDesktop) {
          return _DesktopShell(
            navigationShell: navigationShell,
            isOffline: isOffline,
          );
        }
        return _MobileShell(
          navigationShell: navigationShell,
          isOffline: isOffline,
        );
      },
    );
  }
}

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isOffline;

  const _MobileShell({
    required this.navigationShell,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HushOfflineBanner(isOffline: isOffline),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final bool isOffline;

  const _DesktopShell({
    required this.navigationShell,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          HushOfflineBanner(isOffline: isOffline),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
