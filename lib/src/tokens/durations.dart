import 'package:flutter/animation.dart';

/// Eden UI animation duration tokens — matches eden_ui/tokens.css.
class EdenDurations {
  EdenDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Expo-out easing curve — matches CSS cubic-bezier(0.19, 1, 0.22, 1).
  static const Cubic easeOutExpo = Cubic(0.19, 1, 0.22, 1);
}
