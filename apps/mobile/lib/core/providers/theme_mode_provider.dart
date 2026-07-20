import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeModeStateNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
  void toggle() {
    state = switch (state) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.light => ThemeMode.dark,
    };
  }
}

final themeModeProvider = NotifierProvider<ThemeModeStateNotifier, ThemeMode>(
  ThemeModeStateNotifier.new,
);
