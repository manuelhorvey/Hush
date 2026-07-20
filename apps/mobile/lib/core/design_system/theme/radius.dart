import 'package:flutter/material.dart';

class HushRadius {
  HushRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static BorderRadius get xsAll => BorderRadius.all(xsCircular);
  static BorderRadius get smAll => BorderRadius.all(smCircular);
  static BorderRadius get mdAll => BorderRadius.all(mdCircular);
  static BorderRadius get lgAll => BorderRadius.all(lgCircular);
  static BorderRadius get xlAll => BorderRadius.all(xlCircular);

  static Radius get xsCircular => const Radius.circular(xs);
  static Radius get smCircular => const Radius.circular(sm);
  static Radius get mdCircular => const Radius.circular(md);
  static Radius get lgCircular => const Radius.circular(lg);
  static Radius get xlCircular => const Radius.circular(xl);
  static Radius get fullCircular => const Radius.circular(full);
}
