import 'package:flutter/material.dart';

class ScreenSize {
  final BoxConstraints constraints;
  final Orientation orientation;

  const ScreenSize({
    required this.constraints,
    required this.orientation,
  });

  bool get isSmallPhone => constraints.maxWidth < 360;
  bool get isPhone => constraints.maxWidth < 600;
  bool get isTablet => constraints.maxWidth >= 600 && constraints.maxWidth < 900;
  bool get isDesktop => constraints.maxWidth >= 900;
  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  double get maxWidth => constraints.maxWidth;
  double get maxHeight => constraints.maxHeight;
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext, ScreenSize) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.of(context).orientation;
        final screenSize = ScreenSize(
          constraints: constraints,
          orientation: orientation,
        );
        return builder(context, screenSize);
      },
    );
  }
}

class AdaptivePadding extends StatelessWidget {
  final Widget child;

  const AdaptivePadding({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        final h = size.isTablet || size.isDesktop ? 48.0 : 16.0;
        final v = size.isTablet || size.isDesktop ? 48.0 : 16.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: h, vertical: v),
          child: child,
        );
      },
    );
  }
}

class AdaptiveColumn extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const AdaptiveColumn({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size.isDesktop) {
          final half = (children.length / 2).ceil();
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(children: children.take(half).toList()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: children.skip(half).toList()),
              ),
            ],
          );
        }
        return Column(children: children);
      },
    );
  }
}

class AdaptiveWidth extends StatelessWidget {
  final Widget child;

  const AdaptiveWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, size) {
        if (size.isDesktop || size.isTablet) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}
