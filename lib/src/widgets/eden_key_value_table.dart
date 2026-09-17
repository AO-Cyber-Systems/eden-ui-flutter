import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';
import '../utils/eden_tsv.dart';

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
    this.copyable = false,
  });

  final List<EdenKeyValue> items;
  final bool compact;
  final VoidCallback? Function(int index)? onCopy;

  /// Shows a 'Copy table' action that writes every key/value pair as TSV.
  ///
  /// Off by default, so existing call sites render unchanged. Independent of
  /// [onCopy]: that callback is the per-row "copy this one value" affordance and
  /// is untouched by this flag — a table may have either, both, or neither.
  final bool copyable;

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
        children: <Widget>[
          if (copyable) _buildCopyBar(theme, isDark, borderColor),
          ...List.generate(items.length, (index) {
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
        ],
      ),
    );
  }

  /// The copy-table toolbar, shown only when [copyable].
  ///
  /// The rows are already `String` key/value pairs, so no widget-text
  /// extraction is needed — the data goes straight to [edenCopyTsv], which
  /// normalises any tab or newline hiding inside a value (a raw tab would
  /// silently shift every later column of the pasted grid).
  ///
  /// No header line: the key column IS the label, so a "Key / Value" header
  /// would be noise in the spreadsheet.
  Widget _buildCopyBar(ThemeData theme, bool isDark, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          // Outside the selection so a drag across the table copies the data
          // and not the words 'Copy table' (40-RESEARCH.md section 5).
          SelectionContainer.disabled(
            child: IconButton(
              icon: Icon(
                Icons.copy_all,
                size: 16,
                color: EdenColors.neutral[500],
              ),
              tooltip: 'Copy table',
              onPressed: () => edenCopyTsv(
                items
                    .map((EdenKeyValue item) => <String>[item.key, item.value])
                    .toList(),
              ),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
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
            // Excluded from selection so a drag across the table does not pick
            // up the word 'Copy'. The callback contract itself is unchanged.
            SelectionContainer.disabled(
              child: IconButton(
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
            ),
          ],
        ],
      ),
    );
  }
}
