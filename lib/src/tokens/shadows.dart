import 'package:flutter/material.dart';

/// Eden UI shadow tokens — matches eden_ui/tokens.css.
class EdenShadows {
  EdenShadows._();

  static List<BoxShadow> sm({bool dark = false}) => [
        BoxShadow(
          offset: const Offset(0, 1),
          blurRadius: 2,
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.05),
        ),
      ];

  static List<BoxShadow> md({bool dark = false}) => [
        BoxShadow(
          offset: const Offset(0, 4),
          blurRadius: 6,
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.07),
        ),
      ];

  static List<BoxShadow> lg({bool dark = false}) => [
        BoxShadow(
          offset: const Offset(0, 10),
          blurRadius: 15,
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
        ),
      ];

  static List<BoxShadow> xl({bool dark = false}) => [
        BoxShadow(
          offset: const Offset(0, 20),
          blurRadius: 25,
          color: Colors.black.withValues(alpha: dark ? 0.3 : 0.1),
        ),
      ];

  static List<BoxShadow> glow(Color color, {bool dark = false}) => [
        BoxShadow(
          blurRadius: 20,
          color: color.withValues(alpha: dark ? 0.15 : 0.1),
        ),
      ];

  static List<BoxShadow> glowStrong(Color color) => [
        BoxShadow(
          blurRadius: 30,
          color: color.withValues(alpha: 0.25),
        ),
      ];
}
