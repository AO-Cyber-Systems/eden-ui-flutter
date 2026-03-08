import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Mirrors the eden_tooltip Rails component.
class EdenTooltip extends StatelessWidget {
  const EdenTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[700] : EdenColors.neutral[900],
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: child,
    );
  }
}
