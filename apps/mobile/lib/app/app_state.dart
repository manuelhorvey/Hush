import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppInitState { uninitialized, initializing, initialized }

class AppState {
  final AppInitState initState;
  final String? error;

  const AppState({this.initState = AppInitState.uninitialized, this.error});

  AppState copyWith({AppInitState? initState, String? error}) => AppState(
        initState: initState ?? this.initState,
        error: error,
      );

  bool get isReady => initState == AppInitState.initialized;
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() => const AppState();

  void setInitializing() =>
      state = state.copyWith(initState: AppInitState.initializing);

  void setInitialized() =>
      state = state.copyWith(initState: AppInitState.initialized);

  void setError(String message) =>
      state = state.copyWith(initState: AppInitState.initialized, error: message);
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);
