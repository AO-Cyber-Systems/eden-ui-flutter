import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_divider Rails component.
class EdenDivider extends StatelessWidget {
  const EdenDivider({
    super.key,
    this.label,
    this.spacing = EdenSpacing.space4,
  });

  final String? label;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: spacing),
        child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, color: theme.colorScheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space3),
            child: Text(
              label!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(height: 1, color: theme.colorScheme.outlineVariant)),
        ],
      ),
    );
  }
}
