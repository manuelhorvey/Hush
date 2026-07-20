import 'package:flutter/material.dart';

class MotionCurves {
  MotionCurves._();

  static const standard = Curves.easeInOutCubic;
  static const emphasize = Curves.easeInOutCubicEmphasized;
  static const decelerate = Curves.easeOutCubic;
  static const accelerate = Curves.easeInCubic;
  static const spring = Curves.fastOutSlowIn;
}

class MotionDurations {
  MotionDurations._();

  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const xslow = Duration(milliseconds: 800);
}
