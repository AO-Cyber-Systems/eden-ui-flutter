import 'package:flutter/material.dart';

/// Eden UI border radius tokens — matches eden_ui/tokens.css.
class EdenRadii {
  EdenRadii._();

  static const double sm = 6; // 0.375rem
  static const double md = 8; // 0.5rem
  static const double lg = 12; // 0.75rem
  static const double xl = 16; // 1rem
  static const double xxl = 24; // 1.5rem
  static const double full = 9999;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static final BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
  static final BorderRadius borderRadiusFull = BorderRadius.circular(full);
}
