import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// Mirrors the eden_kbd Rails component.
///
/// Renders text as a keyboard key cap.
class EdenKbd extends StatelessWidget {
  const EdenKbd(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[700] : EdenColors.neutral[100],
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(
          color: isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!,
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 0,
            color: isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? EdenColors.neutral[100] : EdenColors.neutral[800],
        ),
      ),
    );
  }
}
