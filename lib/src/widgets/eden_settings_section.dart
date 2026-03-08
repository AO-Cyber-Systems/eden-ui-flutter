import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_settings_section Rails component.
///
/// A labeled card section used in settings pages, with title, description,
/// and content area.
class EdenSettingsSection extends StatelessWidget {
  const EdenSettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.action,
  });

  final String title;
  final String? description;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: EdenSpacing.space4),
          child,
        ],
      ),
    );
  }
}
