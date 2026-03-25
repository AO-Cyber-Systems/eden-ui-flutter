import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// A single option for [EdenMultiSelect].
class EdenMultiSelectOption<T> {
  const EdenMultiSelectOption({
    required this.value,
    required this.label,
    this.group,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? group;
  final bool enabled;
}

/// A multi-select dropdown with checkboxes, tag display, search, and clear all.
///
/// Selected values are shown as removable chips in the input area.
/// The dropdown overlay includes optional search filtering, select all,
/// and clear all actions.
class EdenMultiSelect<T> extends StatefulWidget {
  const EdenMultiSelect({
    super.key,
    required this.options,
    this.values = const [],
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.searchable = true,
    this.maxSelections,
    this.showSelectAll = false,
    this.enabled = true,
    this.chipColor,
  });

  final List<EdenMultiSelectOption<T>> options;
  final List<T> values;
  final ValueChanged<List<T>>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool searchable;
  final int? maxSelections;
  final bool showSelectAll;
  final bool enabled;
  final Color? chipColor;

  @override
  State<EdenMultiSelect<T>> createState() => _EdenMultiSelectState<T>();
}

class _EdenMultiSelectState<T> extends State<EdenMultiSelect<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _query = '';

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.clear();
    if (_isOpen) setState(() { _isOpen = false; _query = ''; });
  }

  void _onToggleValue(T value) {
    final current = List<T>.from(widget.values);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      if (widget.maxSelections != null && current.length >= widget.maxSelections!) {
        return;
      }
      current.add(value);
    }
    widget.onChanged?.call(current);
    _overlayEntry?.markNeedsBuild();
  }

  void _onRemoveValue(T value) {
    final current = List<T>.from(widget.values);
    current.remove(value);
    widget.onChanged?.call(current);
  }

  void _onSelectAll() {
    final selectable = widget.options
        .where((o) => o.enabled)
        .map((o) => o.value)
        .toList();
    if (widget.maxSelections != null) {
      widget.onChanged?.call(selectable.take(widget.maxSelections!).toList());
    } else {
      widget.onChanged?.call(selectable);
    }
    _overlayEntry?.markNeedsBuild();
  }

  void _onClearAll() {
    widget.onChanged?.call([]);
    _overlayEntry?.markNeedsBuild();
  }

  List<EdenMultiSelectOption<T>> get _filteredOptions {
    if (_query.isEmpty) return widget.options;
    final lower = _query.toLowerCase();
    return widget.options
        .where((o) => o.label.toLowerCase().contains(lower))
        .toList();
  }

  /// Groups filtered options by their [group] field. `null` groups come first.
  Map<String?, List<EdenMultiSelectOption<T>>> get _groupedOptions {
    final filtered = _filteredOptions;
    final map = <String?, List<EdenMultiSelectOption<T>>>{};
    for (final opt in filtered) {
      map.putIfAbsent(opt.group, () => []).add(opt);
    }
    return map;
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (_) => _OverlayContent<T>(
        link: _layerLink,
        width: size.width,
        query: _query,
        searchController: _searchController,
        searchable: widget.searchable,
        showSelectAll: widget.showSelectAll,
        groupedOptions: _groupedOptions,
        values: widget.values,
        maxSelections: widget.maxSelections,
        onToggle: _onToggleValue,
        onSelectAll: _onSelectAll,
        onClearAll: _onClearAll,
        onSearchChanged: (q) {
          _query = q;
          _overlayEntry?.markNeedsBuild();
        },
        onClose: _removeOverlay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final isDark = theme.brightness == Brightness.dark;

    final selectedLabels = <String>[];
    for (final v in widget.values) {
      final match = widget.options.where((o) => o.value == v);
      if (match.isNotEmpty) selectedLabels.add(match.first.label);
    }

    final borderColor = hasError
        ? EdenColors.error
        : _isOpen
            ? theme.colorScheme.primary
            : isDark
                ? EdenColors.neutral[700]!
                : EdenColors.neutral[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _toggleOverlay,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: EdenRadii.borderRadiusMd,
                border: Border.all(color: borderColor, width: _isOpen ? 2 : 1),
                color: widget.enabled
                    ? theme.colorScheme.surface
                    : (isDark ? EdenColors.neutral[800] : EdenColors.neutral[100]),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: widget.values.isEmpty
                        ? Text(
                            widget.hint ?? 'Select...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (int i = 0; i < widget.values.length; i++)
                                InputChip(
                                  label: Text(
                                    selectedLabels.length > i ? selectedLabels[i] : '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  deleteIconColor: theme.colorScheme.onSurfaceVariant,
                                  backgroundColor: widget.chipColor ??
                                      (isDark ? EdenColors.neutral[700] : EdenColors.neutral[200]),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: EdenRadii.borderRadiusSm,
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  onDeleted: widget.enabled
                                      ? () => _onRemoveValue(widget.values[i])
                                      : null,
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: EdenColors.error),
          ),
        ],
      ],
    );
  }
}

/// The overlay dropdown content, extracted as a stateless widget for rebuilds.
class _OverlayContent<T> extends StatelessWidget {
  const _OverlayContent({
    required this.link,
    required this.width,
    required this.query,
    required this.searchController,
    required this.searchable,
    required this.showSelectAll,
    required this.groupedOptions,
    required this.values,
    required this.maxSelections,
    required this.onToggle,
    required this.onSelectAll,
    required this.onClearAll,
    required this.onSearchChanged,
    required this.onClose,
  });

  final LayerLink link;
  final double width;
  final String query;
  final TextEditingController searchController;
  final bool searchable;
  final bool showSelectAll;
  final Map<String?, List<EdenMultiSelectOption<T>>> groupedOptions;
  final List<T> values;
  final int? maxSelections;
  final ValueChanged<T> onToggle;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allOptions = groupedOptions.values.expand((v) => v).toList();

    return Stack(
      children: [
        // Tap-outside barrier.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 4),
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: EdenRadii.borderRadiusLg,
            color: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            child: Container(
              width: width,
              constraints: const BoxConstraints(maxHeight: 320),
              decoration: BoxDecoration(
                borderRadius: EdenRadii.borderRadiusLg,
                border: Border.all(
                  color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field.
                  if (searchable)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14),
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: EdenRadii.borderRadiusSm,
                          ),
                        ),
                      ),
                    ),
                  // Select all / clear all bar.
                  if (showSelectAll)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: onSelectAll,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Select all'),
                          ),
                          const SizedBox(width: 4),
                          TextButton(
                            onPressed: onClearAll,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 1),
                  // Options list.
                  Flexible(
                    child: allOptions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No options found',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            children: [
                              for (final entry in groupedOptions.entries) ...[
                                if (entry.key != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                    child: Text(
                                      entry.key!,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                for (final opt in entry.value)
                                  _CheckboxTile<T>(
                                    option: opt,
                                    selected: values.contains(opt.value),
                                    enabled: opt.enabled &&
                                        (values.contains(opt.value) ||
                                            maxSelections == null ||
                                            values.length < maxSelections!),
                                    onTap: () => onToggle(opt.value),
                                  ),
                              ],
                            ],
                          ),
                  ),
                  // Footer.
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          maxSelections != null
                              ? '${values.length} / $maxSelections selected'
                              : '${values.length} selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (values.isNotEmpty)
                          GestureDetector(
                            onTap: onClearAll,
                            child: Text(
                              'Clear all',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckboxTile<T> extends StatelessWidget {
  const _CheckboxTile({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final EdenMultiSelectOption<T> option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: enabled ? (_) => onTap() : null,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                option.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
