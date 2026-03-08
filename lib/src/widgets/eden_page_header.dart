import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_page_header Rails component.
///
/// Page title with optional description and trailing action widgets.
class EdenPageHeader extends StatelessWidget {
  const EdenPageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions,
    this.leading,
  });

  final String title;
  final String? description;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: EdenSpacing.space3),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: EdenSpacing.space3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions![i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
