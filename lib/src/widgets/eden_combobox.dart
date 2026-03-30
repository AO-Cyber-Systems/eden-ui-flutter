import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// A single option for [EdenCombobox].
class EdenComboboxOption<T> {
  const EdenComboboxOption({
    required this.value,
    required this.label,
    this.description,
    this.leading,
  });

  final T value;
  final String label;
  final String? description;
  final Widget? leading;
}

/// A searchable single-select dropdown (combobox) with autocomplete.
///
/// Supports text filtering, custom option rendering, keyboard navigation,
/// highlighted matching text, async search via [onSearch], and a
/// "create new" action via [onCreateNew].
class EdenCombobox<T> extends StatefulWidget {
  const EdenCombobox({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.onSearch,
    this.label,
    this.hint,
    this.errorText,
    this.loading = false,
    this.enabled = true,
    this.clearable = true,
    this.onCreateNew,
    this.createNewLabel,
    this.optionBuilder,
    this.debounceMs = 300,
  });

  final List<EdenComboboxOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final ValueChanged<String>? onSearch;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool loading;
  final bool enabled;
  final bool clearable;
  final VoidCallback? onCreateNew;
  final String? createNewLabel;
  final Widget Function(EdenComboboxOption<T>, bool isHighlighted)? optionBuilder;
  final int debounceMs;

  @override
  State<EdenCombobox<T>> createState() => _EdenComboboxState<T>();
}

class _EdenComboboxState<T> extends State<EdenCombobox<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  int _highlightedIndex = -1;
  Timer? _debounceTimer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _syncTextFromValue();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant EdenCombobox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _syncTextFromValue();
    }
    // Rebuild overlay when options change (e.g. async results arrived).
    if (_isOpen) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _syncTextFromValue() {
    if (widget.value == null) {
      _textController.clear();
      return;
    }
    final match = widget.options.where((o) => o.value == widget.value);
    if (match.isNotEmpty) {
      _textController.text = match.first.label;
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay removal so tap on overlay items registers first.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) _removeOverlay();
      });
    }
  }

  void _showOverlay() {
    if (_isOpen) return;
    _highlightedIndex = -1;
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen) setState(() => _isOpen = false);
  }

  void _onTextChanged(String text) {
    _query = text;
    _highlightedIndex = -1;
    _overlayEntry?.markNeedsBuild();

    if (widget.onSearch != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
        widget.onSearch?.call(text);
      });
    }

    if (!_isOpen) _showOverlay();
  }

  List<EdenComboboxOption<T>> get _filteredOptions {
    if (_query.isEmpty) return widget.options;
    final lower = _query.toLowerCase();
    return widget.options
        .where((o) => o.label.toLowerCase().contains(lower))
        .toList();
  }

  void _selectOption(EdenComboboxOption<T> option) {
    _textController.text = option.label;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: option.label.length),
    );
    widget.onChanged?.call(option.value);
    _focusNode.unfocus();
    _removeOverlay();
  }

  void _clearSelection() {
    _textController.clear();
    _query = '';
    widget.onChanged?.call(null);
    _overlayEntry?.markNeedsBuild();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final filtered = _filteredOptions;
    final hasCreateNew = widget.onCreateNew != null && _query.isNotEmpty;
    final totalItems = filtered.length + (hasCreateNew ? 1 : 0);

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _highlightedIndex = (_highlightedIndex + 1).clamp(0, totalItems - 1);
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _highlightedIndex = (_highlightedIndex - 1).clamp(-1, totalItems - 1);
      _overlayEntry?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_highlightedIndex >= 0 && _highlightedIndex < filtered.length) {
        _selectOption(filtered[_highlightedIndex]);
        return KeyEventResult.handled;
      }
      if (hasCreateNew && _highlightedIndex == filtered.length) {
        widget.onCreateNew?.call();
        return KeyEventResult.handled;
      }
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _focusNode.unfocus();
      _removeOverlay();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (_) => _ComboboxOverlay<T>(
        link: _layerLink,
        width: size.width,
        options: _filteredOptions,
        query: _query,
        highlightedIndex: _highlightedIndex,
        loading: widget.loading,
        onCreateNew: widget.onCreateNew,
        createNewLabel: widget.createNewLabel,
        optionBuilder: widget.optionBuilder,
        onSelect: _selectOption,
        onClose: () {
          _focusNode.unfocus();
          _removeOverlay();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = widget.errorText != null;
    final hasValue = widget.value != null && _textController.text.isNotEmpty;

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
          child: Focus(
            onKeyEvent: _onKeyEvent,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onChanged: _onTextChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                errorText: widget.errorText,
                errorStyle: const TextStyle(fontSize: 12),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.loading)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (widget.clearable && hasValue && !widget.loading)
                      GestureDetector(
                        onTap: _clearSelection,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.close, size: 18),
                        ),
                      ),
                    Icon(
                      _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Overlay content for the combobox dropdown.
class _ComboboxOverlay<T> extends StatelessWidget {
  const _ComboboxOverlay({
    required this.link,
    required this.width,
    required this.options,
    required this.query,
    required this.highlightedIndex,
    required this.loading,
    required this.onCreateNew,
    required this.createNewLabel,
    required this.optionBuilder,
    required this.onSelect,
    required this.onClose,
  });

  final LayerLink link;
  final double width;
  final List<EdenComboboxOption<T>> options;
  final String query;
  final int highlightedIndex;
  final bool loading;
  final VoidCallback? onCreateNew;
  final String? createNewLabel;
  final Widget Function(EdenComboboxOption<T>, bool isHighlighted)? optionBuilder;
  final ValueChanged<EdenComboboxOption<T>> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasCreateNew = onCreateNew != null && query.isNotEmpty;

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
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                borderRadius: EdenRadii.borderRadiusLg,
                border: Border.all(
                  color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                ),
              ),
              child: _buildContent(context, theme, isDark, hasCreateNew),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    bool hasCreateNew,
  ) {
    if (loading && options.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (options.isEmpty && !hasCreateNew) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No results found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      shrinkWrap: true,
      children: [
        for (int i = 0; i < options.length; i++)
          _buildOptionTile(context, theme, isDark, options[i], i),
        if (hasCreateNew) ...[
          const Divider(height: 1),
          _buildCreateNewTile(context, theme, options.length),
        ],
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    EdenComboboxOption<T> option,
    int index,
  ) {
    final isHighlighted = index == highlightedIndex;
    final highlightColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[100]!;

    if (optionBuilder != null) {
      return InkWell(
        onTap: () => onSelect(option),
        child: Container(
          color: isHighlighted ? highlightColor : null,
          child: optionBuilder!(option, isHighlighted),
        ),
      );
    }

    return InkWell(
      onTap: () => onSelect(option),
      child: Container(
        color: isHighlighted ? highlightColor : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (option.leading != null) ...[
              option.leading!,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HighlightedText(
                    text: option.label,
                    query: query,
                    style: theme.textTheme.bodyMedium!,
                    highlightStyle: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateNewTile(
    BuildContext context,
    ThemeData theme,
    int index,
  ) {
    final isHighlighted = index == highlightedIndex;
    final isDark = theme.brightness == Brightness.dark;
    final highlightColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[100]!;

    return InkWell(
      onTap: onCreateNew,
      child: Container(
        color: isHighlighted ? highlightColor : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              createNewLabel ?? 'Create "$query"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [text] with substrings matching [query] highlighted.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
  });

  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lower.indexOf(queryLower, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle,
      ));
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
