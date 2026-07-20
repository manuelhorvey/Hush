import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityState {
  final bool isOnline;

  const ConnectivityState({this.isOnline = true});
}

class ConnectivityStateNotifier extends Notifier<ConnectivityState> {
  @override
  ConnectivityState build() => const ConnectivityState();

  void setOnline(bool v) {
    if (state.isOnline != v) {
      state = ConnectivityState(isOnline: v);
    }
  }
}

final connectivityStateProvider =
    NotifierProvider<ConnectivityStateNotifier, ConnectivityState>(
  ConnectivityStateNotifier.new,
);
