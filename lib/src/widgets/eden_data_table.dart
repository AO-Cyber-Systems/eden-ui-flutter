import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_table Rails component.
///
/// A styled data table with optional striped rows, hover highlighting, and border.
class EdenDataTable extends StatelessWidget {
  const EdenDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.striped = false,
    this.hoverable = true,
    this.onRowTap,
  });

  final List<EdenTableColumn> columns;
  final List<EdenTableRow> rows;
  final bool striped;
  final bool hoverable;
  final ValueChanged<int>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  flex: col.flex,
                  child: Text(
                    col.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
          // Rows
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final stripedBg = striped && index.isOdd
                ? (isDark ? EdenColors.neutral[850]!.withValues(alpha: 0.5) : EdenColors.neutral[50]!.withValues(alpha: 0.5))
                : null;

            Widget rowWidget = Container(
              color: stripedBg,
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space3,
              ),
              child: Row(
                children: [
                  for (int i = 0; i < columns.length; i++)
                    Expanded(
                      flex: columns[i].flex,
                      child: i < row.cells.length ? row.cells[i] : const SizedBox.shrink(),
                    ),
                ],
              ),
            );

            if (hoverable || onRowTap != null) {
              rowWidget = Semantics(
                button: onRowTap != null,
                label: 'Row ${index + 1}',
                child: InkWell(
                  onTap: onRowTap != null ? () => onRowTap!(index) : null,
                  hoverColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                  child: rowWidget,
                ),
              );
            }

            return Column(
              children: [
                rowWidget,
                if (index < rows.length - 1)
                  Divider(height: 1, thickness: 1, color: theme.colorScheme.outlineVariant),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Column definition for [EdenDataTable].
class EdenTableColumn {
  const EdenTableColumn({
    required this.label,
    this.flex = 1,
  });

  final String label;
  final int flex;
}

/// Row data for [EdenDataTable].
class EdenTableRow {
  const EdenTableRow({required this.cells});

  final List<Widget> cells;
}
