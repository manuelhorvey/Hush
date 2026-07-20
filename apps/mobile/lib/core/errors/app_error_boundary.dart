import 'package:flutter/material.dart';
import '../../core/design_system/components/feedback/error_state.dart';

class AppErrorBoundary extends StatefulWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return HushErrorState(
        title: 'Something went wrong',
        message: _error.toString(),
        actionLabel: 'Retry',
        onAction: () => setState(() => _error = null),
      );
    }
    return widget.child;
  }
}

class ErrorBoundaryInstaller {
  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
  }
}
