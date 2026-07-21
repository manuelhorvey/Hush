import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityMonitor {
  Timer? _timer;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void start(void Function(bool isOnline) onChanged) {
    _checkNow(onChanged);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkNow(onChanged);
    });
  }

  Future<void> _checkNow(void Function(bool) onChanged) async {
    final wasOnline = _isOnline;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      _isOnline = false;
    }
    if (wasOnline != _isOnline) {
      onChanged(_isOnline);
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  return ConnectivityMonitor();
});
