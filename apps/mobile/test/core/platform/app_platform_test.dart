import 'package:flutter_test/flutter_test.dart';
import 'package:hush_mobile/core/platform/app_platform.dart';

void main() {
  test('platform detection runs without exception', () {
    expect(AppPlatform.isMobile || AppPlatform.isDesktop || AppPlatform.isWeb,
        isTrue);
  });
}
