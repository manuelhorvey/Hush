import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLifecycleStateEx {
  foreground,
  background,
  inactive,
  detached;

  static AppLifecycleStateEx fromFlutter(AppLifecycleState state) => switch (state) {
        AppLifecycleState.resumed => AppLifecycleStateEx.foreground,
        AppLifecycleState.inactive => AppLifecycleStateEx.inactive,
        AppLifecycleState.hidden => AppLifecycleStateEx.background,
        AppLifecycleState.paused => AppLifecycleStateEx.background,
        AppLifecycleState.detached => AppLifecycleStateEx.detached,
      };
}

class AppLifecycleNotifier extends Notifier<AppLifecycleStateEx>
    with WidgetsBindingObserver {
  @override
  AppLifecycleStateEx build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(this));
    return AppLifecycleStateEx.foreground;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    this.state = AppLifecycleStateEx.fromFlutter(state);
  }
}

final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleStateEx>(
  AppLifecycleNotifier.new,
);
