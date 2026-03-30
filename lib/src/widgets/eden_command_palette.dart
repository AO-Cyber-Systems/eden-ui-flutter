import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single item in the command palette.
class EdenCommandItem {
  /// Creates a command palette item.
  const EdenCommandItem({
    required this.id,
    required this.label,
    this.description,
    this.icon,
    this.group,
    this.shortcut,
    this.onSelect,
    this.keywords = const [],
  });

  final String id;
  final String label;
  final String? description;
  final IconData? icon;
  final String? group;

  /// Display shortcut hint, e.g. "Cmd+N".
  final String? shortcut;
  final VoidCallback? onSelect;

  /// Additional search terms beyond the label.
  final List<String> keywords;
}

/// A keyboard-accessible command palette (Cmd+K / Ctrl+K) for navigation
/// and actions, inspired by Spotlight and VS Code.
///
/// Use [EdenCommandPalette.show] to display as an overlay dialog, or embed
/// directly as a widget.
class EdenCommandPalette extends StatefulWidget {
  const EdenCommandPalette({
    super.key,
    required this.items,
    this.onSelect,
    this.onSearch,
    this.placeholder = 'Type a command or search...',
    this.loading = false,
    this.recentItems,
    this.maxVisibleItems = 10,
    this.groups,
  });

  final List<EdenCommandItem> items;
  final ValueChanged<EdenCommandItem>? onSelect;

  /// Called when the search query changes (for async searching).
  final ValueChanged<String>? onSearch;
  final String placeholder;
  final bool loading;

  /// Recent item IDs, displayed in a "Recent" group when query is empty.
  final List<String>? recentItems;
  final int maxVisibleItems;

  /// Explicit group ordering. Groups not listed appear after these.
  final List<String>? groups;

  /// Show the command palette as an overlay dialog positioned at the top-center.
  static Future<EdenCommandItem?> show(
    BuildContext context, {
    required List<EdenCommandItem> items,
    String placeholder = 'Type a command or search...',
    ValueChanged<String>? onSearch,
    bool loading = false,
    List<String>? recentItems,
    int maxVisibleItems = 10,
    List<String>? groups,
  }) {
    return showDialog<EdenCommandItem>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _EdenCommandPaletteDialog(
        items: items,
        placeholder: placeholder,
        onSearch: onSearch,
        loading: loading,
        recentItems: recentItems,
        maxVisibleItems: maxVisibleItems,
        groups: groups,
      ),
    );
  }

  @override
  State<EdenCommandPalette> createState() => _EdenCommandPaletteState();
}

class _EdenCommandPaletteState extends State<EdenCommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  String _query = '';

  List<EdenCommandItem> get _filtered => _filterItems(_query);

  List<EdenCommandItem> _filterItems(String query) {
    if (query.isEmpty) return _recentThenAll();
    final lower = query.toLowerCase();
    return widget.items.where((item) {
      return item.label.toLowerCase().contains(lower) ||
          (item.description?.toLowerCase().contains(lower) ?? false) ||
          item.keywords.any((k) => k.toLowerCase().contains(lower));
    }).toList();
  }

  List<EdenCommandItem> _recentThenAll() {
    if (widget.recentItems == null || widget.recentItems!.isEmpty) {
      return widget.items;
    }
    final recentIds = widget.recentItems!.toSet();
    final recent =
        widget.items.where((i) => recentIds.contains(i.id)).toList();
    final rest =
        widget.items.where((i) => !recentIds.contains(i.id)).toList();
    // Tag recent items with a virtual group for display.
    return [
      ...recent.map((i) => EdenCommandItem(
            id: i.id,
            label: i.label,
            description: i.description,
            icon: i.icon,
            group: 'Recent',
            shortcut: i.shortcut,
            onSelect: i.onSelect,
            keywords: i.keywords,
          )),
      ...rest,
    ];
  }

  void _onQueryChanged(String value) {
    setState(() {
      _query = value;
      _selectedIndex = 0;
    });
    widget.onSearch?.call(value);
  }

  void _selectItem(EdenCommandItem item) {
    widget.onSelect?.call(item);
    item.onSelect?.call();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final items = _filtered;
    if (items.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _selectedIndex = (_selectedIndex + 1) % items.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() =>
          _selectedIndex = (_selectedIndex - 1 + items.length) % items.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex < items.length) {
        _selectItem(items[_selectedIndex]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final groups = _groupItems(items);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(isDark),
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.all(EdenSpacing.space4),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (items.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildResultsList(groups, items, isDark),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          ),
        ),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        onChanged: _onQueryChanged,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.placeholder,
          prefixIcon: const Icon(Icons.search, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: EdenSpacing.space8,
        horizontal: EdenSpacing.space4,
      ),
      child: Center(
        child: Text(
          'No results found',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
    List<_GroupedItems> groups,
    List<EdenCommandItem> flatItems,
    bool isDark,
  ) {
    int globalIndex = 0;
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: widget.maxVisibleItems * 48.0 + 40),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space1),
        children: [
          for (final group in groups) ...[
            if (group.name != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  EdenSpacing.space4,
                  EdenSpacing.space3,
                  EdenSpacing.space4,
                  EdenSpacing.space1,
                ),
                child: Text(
                  group.name!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[500],
                  ),
                ),
              ),
            for (final item in group.items) ...[
              _buildResultItem(item, globalIndex++, isDark),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResultItem(EdenCommandItem item, int index, bool isDark) {
    final isSelected = index == _selectedIndex;
    final selectedBg =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[100]!;

    return InkWell(
      onTap: () => _selectItem(item),
      onHover: (hovering) {
        if (hovering) setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        color: isSelected ? selectedBg : Colors.transparent,
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 18,
                color: isDark
                    ? EdenColors.neutral[300]
                    : EdenColors.neutral[600],
              ),
              const SizedBox(width: EdenSpacing.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHighlightedText(
                    item.label,
                    _query,
                    TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? EdenColors.neutral[100]
                          : EdenColors.neutral[900],
                    ),
                    isDark,
                  ),
                  if (item.description != null)
                    Text(
                      item.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? EdenColors.neutral[400]
                            : EdenColors.neutral[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (item.shortcut != null) ...[
              const SizedBox(width: EdenSpacing.space2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? EdenColors.neutral[700]
                      : EdenColors.neutral[100],
                  borderRadius: EdenRadii.borderRadiusSm,
                  border: Border.all(
                    color: isDark
                        ? EdenColors.neutral[600]!
                        : EdenColors.neutral[300]!,
                  ),
                ),
                child: Text(
                  item.shortcut!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? EdenColors.neutral[300]
                        : EdenColors.neutral[500],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Highlights matching portions of [text] that match [query].
  Widget _buildHighlightedText(
    String text,
    String query,
    TextStyle baseStyle,
    bool isDark,
  ) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final matchStart = lower.indexOf(queryLower);

    if (matchStart < 0) return Text(text, style: baseStyle);

    final highlightColor =
        isDark ? EdenColors.blue[300]! : EdenColors.blue[600]!;

    return RichText(
      text: TextSpan(
        children: [
          if (matchStart > 0)
            TextSpan(text: text.substring(0, matchStart), style: baseStyle),
          TextSpan(
            text: text.substring(matchStart, matchStart + query.length),
            style: baseStyle.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (matchStart + query.length < text.length)
            TextSpan(
              text: text.substring(matchStart + query.length),
              style: baseStyle,
            ),
        ],
      ),
    );
  }

  /// Groups items by their [EdenCommandItem.group], preserving order.
  List<_GroupedItems> _groupItems(List<EdenCommandItem> items) {
    final ordering = widget.groups ?? [];
    final groups = <String?, List<EdenCommandItem>>{};

    for (final item in items) {
      groups.putIfAbsent(item.group, () => []).add(item);
    }

    final result = <_GroupedItems>[];

    // Add explicitly ordered groups first.
    for (final name in ordering) {
      if (groups.containsKey(name)) {
        result.add(_GroupedItems(name, groups.remove(name)!));
      }
    }

    // Add remaining groups in encounter order.
    for (final entry in groups.entries) {
      result.add(_GroupedItems(entry.key, entry.value));
    }

    return result;
  }
}

/// Internal grouped items helper.
class _GroupedItems {
  const _GroupedItems(this.name, this.items);
  final String? name;
  final List<EdenCommandItem> items;
}

/// The dialog wrapper that positions the palette at the top-center of the screen.
class _EdenCommandPaletteDialog extends StatelessWidget {
  const _EdenCommandPaletteDialog({
    required this.items,
    required this.placeholder,
    this.onSearch,
    required this.loading,
    this.recentItems,
    required this.maxVisibleItems,
    this.groups,
  });

  final List<EdenCommandItem> items;
  final String placeholder;
  final ValueChanged<String>? onSearch;
  final bool loading;
  final List<String>? recentItems;
  final int maxVisibleItems;
  final List<String>? groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Align(
      alignment: const Alignment(0.0, -0.6),
      child: Material(
        elevation: 16,
        borderRadius: EdenRadii.borderRadiusXl,
        color: isDark ? EdenColors.neutral[800] : Colors.white,
        child: Container(
          width: mediaQuery.size.width > 600 ? 560 : mediaQuery.size.width - 32,
          constraints: BoxConstraints(
            maxHeight: mediaQuery.size.height * 0.6,
          ),
          decoration: BoxDecoration(
            borderRadius: EdenRadii.borderRadiusXl,
            border: Border.all(
              color:
                  isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
            ),
          ),
          child: ClipRRect(
            borderRadius: EdenRadii.borderRadiusXl,
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  Navigator.of(context).pop();
                }
              },
              child: EdenCommandPalette(
                items: items,
                placeholder: placeholder,
                onSearch: onSearch,
                loading: loading,
                recentItems: recentItems,
                maxVisibleItems: maxVisibleItems,
                groups: groups,
                onSelect: (item) => Navigator.of(context).pop(item),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
