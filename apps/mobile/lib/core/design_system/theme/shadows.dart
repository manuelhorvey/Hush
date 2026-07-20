import 'package:flutter/material.dart';

class HushShadows {
  HushShadows._();

  static const double none = 0;
  static const double xs = 0.5;
  static const double sm = 1;
  static const double md = 2;
  static const double lg = 4;
  static const double xl = 8;

  static List<BoxShadow> box(double elevation) {
    return [BoxShadow(blurRadius: elevation, offset: Offset(0, elevation * 0.5))];
  }

  static List<BoxShadow> get noneBox => box(none);
  static List<BoxShadow> get xsBox => box(xs);
  static List<BoxShadow> get smBox => box(sm);
  static List<BoxShadow> get mdBox => box(md);
  static List<BoxShadow> get lgBox => box(lg);
  static List<BoxShadow> get xlBox => box(xl);
}
