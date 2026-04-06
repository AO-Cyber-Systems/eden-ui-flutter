import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import '../eden_data_grid.dart';

class ColumnVisibilityButton<T> extends StatefulWidget {
  const ColumnVisibilityButton({
    super.key,
    required this.columns,
    required this.hiddenColumns,
    required this.onToggle,
  });

  final List<EdenGridColumn<T>> columns;
  final Set<String> hiddenColumns;
  final void Function(String columnId, bool visible) onToggle;

  @override
  State<ColumnVisibilityButton<T>> createState() =>
      ColumnVisibilityButtonState<T>();
}

class ColumnVisibilityButtonState<T>
    extends State<ColumnVisibilityButton<T>> {
  final GlobalKey _buttonKey = GlobalKey();

  void _showPopup() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      items: widget.columns.map((col) {
        final isVisible = !widget.hiddenColumns.contains(col.id);
        return PopupMenuItem<void>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return CheckboxListTile(
                dense: true,
                title: Text(
                  col.label,
                  style: const TextStyle(fontSize: 13),
                ),
                value: isVisible,
                onChanged: (value) {
                  widget.onToggle(col.id, value ?? true);
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 30,
      child: OutlinedButton.icon(
        key: _buttonKey,
        onPressed: _showPopup,
        icon: const Icon(Icons.view_column_outlined, size: 16),
        label: Text(
          'Columns',
          style: theme.textTheme.labelSmall,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: EdenRadii.borderRadiusSm,
          ),
        ),
      ),
    );
  }
}

class PaginationButton extends StatelessWidget {
  const PaginationButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  String get _semanticLabel {
    if (icon == Icons.first_page) return 'First page';
    if (icon == Icons.chevron_left) return 'Previous page';
    if (icon == Icons.chevron_right) return 'Next page';
    if (icon == Icons.last_page) return 'Last page';
    return 'Page navigation';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: _semanticLabel,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: enabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
