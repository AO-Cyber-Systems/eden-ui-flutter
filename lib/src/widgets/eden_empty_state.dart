import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_empty_state Rails component.
///
/// Placeholder shown when a list or section has no data.
class EdenEmptyState extends StatelessWidget {
  const EdenEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space16,
          horizontal: EdenSpacing.space8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: theme.colorScheme.primary),
              ),
            if (icon != null) const SizedBox(height: EdenSpacing.space4),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: EdenSpacing.space2),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              action!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
