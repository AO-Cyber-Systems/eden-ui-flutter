import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// A single option for [EdenSelect].
class EdenSelectOption<T> {
  const EdenSelectOption({required this.value, required this.label});
  final T value;
  final String label;
}

/// Input size presets.
enum EdenSelectSize { sm, md, lg }

/// Eden-native single-select. Renders a brand-styled trigger + a custom
/// overlay menu — it does NOT use Flutter's Material `DropdownButton`, so the
/// popup is fully Eden-controlled (styling, hover/selected states, scroll).
class EdenSelect<T> extends StatefulWidget {
  const EdenSelect({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.size = EdenSelectSize.md,
    this.enabled = true,
  });

  final List<EdenSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final EdenSelectSize size;
  final bool enabled;

  @override
  State<EdenSelect<T>> createState() => _EdenSelectState<T>();
}

class _EdenSelectState<T> extends State<EdenSelect<T>> {
  final LayerLink _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _entry;

  bool get _isOpen => _entry != null;

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
  }

  void _close() {
    _remove();
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (!widget.enabled) return;
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _select(T value) {
    widget.onChanged?.call(value);
    _close();
  }

  void _open() {
    final overlay = Overlay.of(context);
    final box = _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final width = box.size.width;
    final fontSize = _resolveSizing().fontSize;

    _entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Outside-tap barrier — closes the menu.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Align(
                alignment: Alignment.topLeft,
                child: _EdenSelectMenu<T>(
                  width: width,
                  options: widget.options,
                  value: widget.value,
                  fontSize: fontSize,
                  onSelect: _select,
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasError = widget.errorText != null;
    final sizing = _resolveSizing();

    final selected = widget.options.where((o) => o.value == widget.value).toList();
    final selectedLabel = selected.isNotEmpty ? selected.first.label : null;

    final borderColor = hasError
        ? EdenColors.error
        : (_isOpen ? EdenColors.gold : scheme.outline.withValues(alpha: 0.5));

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
          link: _link,
          child: MouseRegion(
            cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: GestureDetector(
              key: _fieldKey,
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Container(
                padding: sizing.padding,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? scheme.surface
                      : scheme.surface.withValues(alpha: 0.5),
                  borderRadius: EdenRadii.borderRadiusLg,
                  border: Border.all(
                    color: borderColor,
                    width: (_isOpen || hasError) ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel ?? (widget.hint ?? ''),
                        style: TextStyle(
                          fontSize: sizing.fontSize,
                          color: selectedLabel != null
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(widget.errorText!, style: const TextStyle(fontSize: 12, color: EdenColors.error)),
        ],
      ],
    );
  }

  _SelectSizing _resolveSizing() {
    switch (widget.size) {
      case EdenSelectSize.sm:
        return const _SelectSizing(EdgeInsets.symmetric(horizontal: 12, vertical: 8), 13);
      case EdenSelectSize.md:
        return const _SelectSizing(EdgeInsets.symmetric(horizontal: 16, vertical: 12), 14);
      case EdenSelectSize.lg:
        return const _SelectSizing(EdgeInsets.symmetric(horizontal: 16, vertical: 14), 16);
    }
  }
}

/// The Eden-styled popup menu (custom, not a Material dropdown menu).
class _EdenSelectMenu<T> extends StatelessWidget {
  const _EdenSelectMenu({
    required this.width,
    required this.options,
    required this.value,
    required this.fontSize,
    required this.onSelect,
  });

  final double width;
  final List<EdenSelectOption<T>> options;
  final T? value;
  final double fontSize;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: scheme.outline.withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        shrinkWrap: true,
        itemCount: options.length,
        itemBuilder: (ctx, i) {
          final opt = options[i];
          return _EdenSelectItem(
            label: opt.label,
            fontSize: fontSize,
            selected: opt.value == value,
            onTap: () => onSelect(opt.value),
          );
        },
      ),
    );
  }
}

/// A single hoverable/selectable option row.
class _EdenSelectItem extends StatefulWidget {
  const _EdenSelectItem({
    required this.label,
    required this.fontSize,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double fontSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_EdenSelectItem> createState() => _EdenSelectItemState();
}

class _EdenSelectItemState extends State<_EdenSelectItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? EdenColors.gold.withValues(alpha: 0.15)
        : (_hover ? scheme.onSurface.withValues(alpha: 0.06) : Colors.transparent);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: scheme.onSurface,
                    fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.selected)
                const Icon(Icons.check, size: 16, color: EdenColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectSizing {
  const _SelectSizing(this.padding, this.fontSize);
  final EdgeInsets padding;
  final double fontSize;
}
