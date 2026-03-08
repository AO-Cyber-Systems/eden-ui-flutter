import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// A single key-value item in a description list.
class EdenDescriptionItem {
  const EdenDescriptionItem({
    required this.label,
    required this.value,
    this.valueWidget,
  });

  final String label;
  final String value;
  final Widget? valueWidget;
}

/// Mirrors the eden_description_list / eden_description_item Rails components.
///
/// Renders a list of label-value pairs, commonly used in settings and detail views.
class EdenDescriptionList extends StatelessWidget {
  const EdenDescriptionList({
    super.key,
    required this.items,
    this.divided = true,
  });

  final List<EdenDescriptionItem> items;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    items[i].label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: EdenSpacing.space3),
                Expanded(
                  child: items[i].valueWidget ??
                      Text(
                        items[i].value,
                        style: theme.textTheme.bodyMedium,
                      ),
                ),
              ],
            ),
          ),
          if (divided && i < items.length - 1)
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
        ],
      ],
    );
  }
}
