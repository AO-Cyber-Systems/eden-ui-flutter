import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A single key-value pair for display in [EdenKeyValueTable].
class EdenKeyValue {
  final String key;
  final String value;
  final bool monospace;

  const EdenKeyValue({
    required this.key,
    required this.value,
    this.monospace = false,
  });
}

/// A generic key-value display table with optional copy buttons, compact mode,
/// and alternating row backgrounds.
class EdenKeyValueTable extends StatelessWidget {
  const EdenKeyValueTable({
    super.key,
    required this.items,
    this.compact = false,
    this.onCopy,
  });

  final List<EdenKeyValue> items;
  final bool compact;
  final VoidCallback? Function(int index)? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark
        ? EdenColors.neutral[700]!
        : EdenColors.neutral[200]!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          return _buildRow(
            context,
            index: index,
            item: items[index],
            theme: theme,
            isDark: isDark,
            isLast: index == items.length - 1,
            borderColor: borderColor,
          );
        }),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required int index,
    required EdenKeyValue item,
    required ThemeData theme,
    required bool isDark,
    required bool isLast,
    required Color borderColor,
  }) {
    final stripeBg = !compact && index.isOdd
        ? (isDark
            ? EdenColors.neutral[800]!.withAlpha(128)
            : EdenColors.neutral[100]!.withAlpha(128))
        : Colors.transparent;

    final verticalPadding =
        compact ? EdenSpacing.space2 : EdenSpacing.space3;
    final horizontalPadding =
        compact ? EdenSpacing.space3 : EdenSpacing.space4;

    final monoStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'Courier'],
    );

    final VoidCallback? copyCallback =
        onCopy != null ? onCopy!(index) : null;

    return Container(
      decoration: BoxDecoration(
        color: stripeBg,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: borderColor, width: 1),
              ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key column
          SizedBox(
            width: compact ? 120 : 160,
            child: Text(
              item.key,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: EdenSpacing.space3),
          // Value column
          Expanded(
            child: Text(
              item.value,
              style: item.monospace
                  ? monoStyle
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
            ),
          ),
          // Copy button
          if (copyCallback != null) ...[
            const SizedBox(width: EdenSpacing.space2),
            IconButton(
              icon: Icon(
                Icons.copy,
                size: 16,
                color: EdenColors.neutral[500],
              ),
              tooltip: 'Copy value',
              onPressed: copyCallback,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
