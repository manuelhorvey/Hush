import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hush_mobile/app/providers/connectivity_provider.dart';
import 'package:hush_mobile/app/providers/theme_provider.dart';
import 'package:hush_mobile/app/lifecycle/app_lifecycle_provider.dart';
import 'package:hush_mobile/app/app_state.dart';

void main() {
  group('ConnectivityProvider', () {
    test('starts online', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(connectivityStateProvider).isOnline, isTrue);
    });

    test('setOnline(false) marks offline', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(connectivityStateProvider.notifier).setOnline(false);
      expect(container.read(connectivityStateProvider).isOnline, isFalse);
    });

    test('setOnline(true) returns to online', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(connectivityStateProvider.notifier).setOnline(false);
      container.read(connectivityStateProvider.notifier).setOnline(true);
      expect(container.read(connectivityStateProvider).isOnline, isTrue);
    });

    test('emits only on change (no duplicate rebuild)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(connectivityStateProvider.notifier);
      var rebuilds = 0;
      container.listen(connectivityStateProvider, (_, __) => rebuilds++);
      notifier.setOnline(false);
      notifier.setOnline(false);
      notifier.setOnline(true);
      expect(rebuilds, 2);
    });
  });

  group('ThemeModeProvider', () {
    test('defaults to system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('set updates the mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).set(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('toggle cycles to dark from system', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(themeModeProvider.notifier).set(ThemeMode.system);
      container.read(themeModeProvider.notifier).toggle();
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });

  group('AppLifecycleProvider', () {
    testWidgets('starts in foreground state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: Consumer(
              builder: (_, ref, __) {
                return Scaffold(
                  body: Text(ref.read(appLifecycleProvider).name),
                );
              },
            ),
          ),
        ),
      );
      expect(find.text(AppLifecycleStateEx.foreground.name), findsOneWidget);
    });
  });

  group('AppStateNotifier', () {
    test('starts uninitialized', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appStateProvider).initState,
          AppInitState.uninitialized);
    });

    test('setInitializing -> initializing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appStateProvider.notifier).setInitializing();
      expect(container.read(appStateProvider).initState,
          AppInitState.initializing);
    });

    test('setInitialized -> initialized', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appStateProvider.notifier).setInitialized();
      expect(container.read(appStateProvider).isReady, isTrue);
    });

    test('isReady is true only when initialized', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(appStateProvider).isReady, isFalse);
      container.read(appStateProvider.notifier).setInitialized();
      expect(container.read(appStateProvider).isReady, isTrue);
    });
  });
}
