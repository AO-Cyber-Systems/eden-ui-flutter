import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A single environment variable entry.
class EdenEnvEntry {
  final String key;
  final String value;
  final String? source;

  const EdenEnvEntry({
    required this.key,
    required this.value,
    this.source,
  });

  EdenEnvEntry copyWith({
    String? key,
    String? value,
    String? source,
  }) {
    return EdenEnvEntry(
      key: key ?? this.key,
      value: value ?? this.value,
      source: source ?? this.source,
    );
  }
}

/// An environment variable key-value editor supporting add, remove, reveal,
/// and read-only modes.
class EdenEnvEditor extends StatefulWidget {
  const EdenEnvEditor({
    super.key,
    required this.entries,
    this.onChanged,
    this.readOnly = false,
  });

  final List<EdenEnvEntry> entries;
  final ValueChanged<List<EdenEnvEntry>>? onChanged;
  final bool readOnly;

  @override
  State<EdenEnvEditor> createState() => _EdenEnvEditorState();
}

class _EdenEnvEditorState extends State<EdenEnvEditor> {
  late List<EdenEnvEntry> _entries;
  final Set<int> _revealed = {};

  @override
  void initState() {
    super.initState();
    _entries = List<EdenEnvEntry>.from(widget.entries);
  }

  @override
  void didUpdateWidget(EdenEnvEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries) {
      _entries = List<EdenEnvEntry>.from(widget.entries);
      _revealed.removeWhere((i) => i >= _entries.length);
    }
  }

  void _notifyChanged() {
    widget.onChanged?.call(List<EdenEnvEntry>.unmodifiable(_entries));
  }

  void _addEntry() {
    setState(() {
      _entries.add(const EdenEnvEntry(key: '', value: ''));
    });
    _notifyChanged();
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);
      _revealed.remove(index);
      // Shift revealed indices above the removed index down by one.
      final shifted = _revealed
          .where((i) => i > index)
          .map((i) => i - 1)
          .toSet();
      _revealed.removeWhere((i) => i >= index);
      _revealed.addAll(shifted);
    });
    _notifyChanged();
  }

  void _updateKey(int index, String newKey) {
    setState(() {
      _entries[index] = _entries[index].copyWith(key: newKey);
    });
    _notifyChanged();
  }

  void _updateValue(int index, String newValue) {
    setState(() {
      _entries[index] = _entries[index].copyWith(value: newValue);
    });
    _notifyChanged();
  }

  void _toggleReveal(int index) {
    setState(() {
      if (_revealed.contains(index)) {
        _revealed.remove(index);
      } else {
        _revealed.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceBg = isDark
        ? EdenColors.neutral[900]!
        : EdenColors.neutral[50]!;
    final borderColor = isDark
        ? EdenColors.neutral[700]!
        : EdenColors.neutral[200]!;
    final separatorColor = isDark
        ? EdenColors.neutral[800]!
        : EdenColors.neutral[100]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, isDark),
          if (_entries.isNotEmpty)
            Divider(height: 1, thickness: 1, color: separatorColor),
          ..._buildEntryRows(theme, isDark, separatorColor),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final badgeBg = isDark
        ? EdenColors.neutral[700]!
        : EdenColors.neutral[200]!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      child: Row(
        children: [
          Text(
            'Environment Variables',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              '${_entries.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          if (!widget.readOnly)
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Add variable',
              onPressed: _addEntry,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildEntryRows(
    ThemeData theme,
    bool isDark,
    Color separatorColor,
  ) {
    final List<Widget> rows = [];
    for (var i = 0; i < _entries.length; i++) {
      if (i > 0) {
        rows.add(Divider(height: 1, thickness: 1, color: separatorColor));
      }
      rows.add(_buildEntryRow(i, theme, isDark));
    }
    return rows;
  }

  Widget _buildEntryRow(int index, ThemeData theme, bool isDark) {
    final entry = _entries[index];
    final isRevealed = _revealed.contains(index);

    final monoStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Courier New', 'Courier'],
    );

    final sourceBadgeBg = isDark
        ? EdenColors.info.withAlpha(40)
        : EdenColors.info.withAlpha(25);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          // Key field
          Expanded(
            flex: 3,
            child: TextField(
              controller: TextEditingController(text: entry.key)
                ..selection = TextSelection.collapsed(offset: entry.key.length),
              style: monoStyle,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                hintText: 'KEY',
                hintStyle: monoStyle?.copyWith(
                  color: EdenColors.neutral[400],
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space2,
                ),
                border: InputBorder.none,
              ),
              onChanged: (v) => _updateKey(index, v),
            ),
          ),
          // Equals divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space1),
            child: Text(
              '=',
              style: monoStyle?.copyWith(
                color: EdenColors.neutral[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Value field
          Expanded(
            flex: 5,
            child: TextField(
              controller: TextEditingController(text: entry.value)
                ..selection =
                    TextSelection.collapsed(offset: entry.value.length),
              style: monoStyle,
              readOnly: widget.readOnly,
              obscureText: !isRevealed,
              decoration: InputDecoration(
                hintText: 'value',
                hintStyle: monoStyle?.copyWith(
                  color: EdenColors.neutral[400],
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space2,
                  vertical: EdenSpacing.space2,
                ),
                border: InputBorder.none,
              ),
              onChanged: (v) => _updateValue(index, v),
            ),
          ),
          // Reveal toggle
          IconButton(
            icon: Icon(
              isRevealed ? Icons.visibility_off : Icons.visibility,
              size: 18,
            ),
            tooltip: isRevealed ? 'Hide value' : 'Reveal value',
            onPressed: () => _toggleReveal(index),
            visualDensity: VisualDensity.compact,
          ),
          // Source badge
          if (entry.source != null) ...[
            const SizedBox(width: EdenSpacing.space1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space2,
                vertical: EdenSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: sourceBadgeBg,
                borderRadius: EdenRadii.borderRadiusSm,
              ),
              child: Text(
                entry.source!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: EdenColors.info,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          // Remove button
          if (!widget.readOnly) ...[
            const SizedBox(width: EdenSpacing.space1),
            IconButton(
              icon: const Icon(
                Icons.close,
                size: 18,
                color: EdenColors.error,
              ),
              tooltip: 'Remove variable',
              onPressed: () => _removeEntry(index),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}
