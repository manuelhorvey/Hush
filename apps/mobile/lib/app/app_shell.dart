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
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Column(
        children: [
          HushOfflineBanner(isOffline: isOffline),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outlineVariant, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (i) => _onTap(context, i),
          backgroundColor: cs.surface,
          indicatorColor: cs.primaryContainer,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: cs.primary),
              label: 'Moments',
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => _onTap(context, i),
            backgroundColor: cs.surface,
            indicatorColor: cs.primaryContainer,
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Semantics(
                label: 'Hush',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    size: 22,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded, color: cs.primary),
                label: const Text('Moments'),
              ),
            ],
          ),
          VerticalDivider(width: 1, thickness: 1, color: cs.outlineVariant),
          Expanded(
            child: Column(
              children: [
                HushOfflineBanner(isOffline: isOffline),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
