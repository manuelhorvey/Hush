import 'dart:io' show Platform;

abstract final class AppPlatform {
  AppPlatform._();

  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isLinux => Platform.isLinux;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isDesktop => isLinux || isMacOS || isWindows;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isWeb => false;
}
