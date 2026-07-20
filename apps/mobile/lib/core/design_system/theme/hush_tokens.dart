class RadiusTokens {
  RadiusTokens._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

class ElevationTokens {
  ElevationTokens._();
  static const double none = 0;
  static const double xs = 0.5;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 4;
  static const double xl = 8;
}

class OpacityTokens {
  OpacityTokens._();
  static const double disabled = 0.38;
  static const double hint = 0.5;
  static const double medium = 0.6;
  static const double high = 0.87;
}

class DurationTokens {
  DurationTokens._();
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const xslow = Duration(milliseconds: 800);
}
