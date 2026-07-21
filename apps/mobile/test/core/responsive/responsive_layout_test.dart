import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/responsive/responsive_layout.dart';

void main() {
  group('ScreenSize', () {
    test('isSmallPhone when width < 360', () {
      const size = ScreenSize(
        constraints: BoxConstraints(maxWidth: 320),
        orientation: Orientation.portrait,
      );
      expect(size.isSmallPhone, isTrue);
      expect(size.isPhone, isTrue);
    });

    test('isTablet for 600 <= width < 900', () {
      const size = ScreenSize(
        constraints: BoxConstraints(maxWidth: 768),
        orientation: Orientation.landscape,
      );
      expect(size.isTablet, isTrue);
      expect(size.isDesktop, isFalse);
      expect(size.isLandscape, isTrue);
    });

    test('isDesktop for width >= 900', () {
      const size = ScreenSize(
        constraints: BoxConstraints(maxWidth: 1200),
        orientation: Orientation.landscape,
      );
      expect(size.isDesktop, isTrue);
      expect(size.isTablet, isFalse);
    });

    test('reports orientation correctly', () {
      const portrait = ScreenSize(
        constraints: BoxConstraints(maxWidth: 400),
        orientation: Orientation.portrait,
      );
      expect(portrait.isPortrait, isTrue);
      expect(portrait.isLandscape, isFalse);
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets('calls builder with ScreenSize info', (tester) async {
      ScreenSize? capturedSize;
      await tester.pumpWidget(
        ResponsiveBuilder(
          builder: (context, size) {
            capturedSize = size;
            return const SizedBox();
          },
        ),
      );
      expect(capturedSize, isNotNull);
    });

    testWidgets('switches between phone and desktop build', (tester) async {
      await tester.pumpWidget(
        ResponsiveBuilder(
          builder: (_, size) {
            return SizedBox(
              width: size.maxWidth,
              height: size.maxHeight,
            );
          },
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
