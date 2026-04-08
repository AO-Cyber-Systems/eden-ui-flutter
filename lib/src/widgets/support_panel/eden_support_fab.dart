import 'package:flutter/material.dart';

import '../../tokens/shadows.dart';
import '../../tokens/spacing.dart';

/// A floating action button that triggers the support panel to open.
///
/// Positioned in the bottom-right corner of the parent [Stack] with
/// [EdenSpacing.space4] margin on all sides.
class EdenSupportFab extends StatelessWidget {
  const EdenSupportFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      bottom: EdenSpacing.space4,
      right: EdenSpacing.space4,
      child: Semantics(
        button: true,
        label: 'Open support panel',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: EdenShadows.lg(dark: isDark),
            ),
            child: const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
