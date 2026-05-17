import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/springs.dart';

/// Visual styles for [EdenButtonGroup].
///
/// v1 ships [connected] only — segments share borders in one continuous pill
/// cluster. A future `.spaced` variant slot is reserved for forward-compat.
enum EdenButtonGroupStyle { connected }

/// One segment inside an [EdenButtonGroup].
///
/// Provide an [icon] and/or a [label] — at least one must be non-null. Use
/// [semanticsLabel] when the visible label is decorative or icon-only segments
/// need a descriptive screen-reader name.
class EdenButtonGroupItem {
  const EdenButtonGroupItem({
    this.icon,
    this.label,
    this.semanticsLabel,
    this.enabled = true,
  }) : assert(icon != null || label != null,
            'EdenButtonGroupItem requires at least one of icon or label.');

  final IconData? icon;
  final String? label;
  final String? semanticsLabel;
  final bool enabled;
}

/// M3 Expressive segmented button-group — a connected pill cluster of 2-6
/// buttons with shape-morph-on-press driven by [EdenSprings.snap].
///
/// Library is state-agnostic: the consumer owns [selectedIndex] and reacts to
/// [onSelected]. This is intentional — Eden widgets never own selection state.
///
/// Usage:
/// ```dart
/// EdenButtonGroup(
///   selectedIndex: _viewMode,
///   onSelected: (i) => setState(() => _viewMode = i),
///   items: const [
///     EdenButtonGroupItem(icon: Icons.view_day_outlined, label: 'Day'),
///     EdenButtonGroupItem(icon: Icons.view_week_outlined, label: 'Week'),
///     EdenButtonGroupItem(icon: Icons.calendar_month_outlined, label: 'Month'),
///   ],
/// )
/// ```
class EdenButtonGroup extends StatefulWidget {
  const EdenButtonGroup({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
    this.style = EdenButtonGroupStyle.connected,
  }) : assert(items.length >= 2 && items.length <= 6,
            'EdenButtonGroup supports 2-6 segments.');

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<EdenButtonGroupItem> items;
  final EdenButtonGroupStyle style;

  @override
  State<EdenButtonGroup> createState() => _EdenButtonGroupState();
}

class _EdenButtonGroupState extends State<EdenButtonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _setPressed(int? index) {
    setState(() => _pressedIndex = index);
    if (index != null) {
      _pressController.animateWith(EdenSprings.simulationFor(
        EdenSprings.snap,
        from: _pressController.value,
        to: 1.0,
      ));
    } else {
      _pressController.animateWith(EdenSprings.simulationFor(
        EdenSprings.snap,
        from: _pressController.value,
        to: 0.0,
      ));
    }
  }

  BorderRadius _radiusFor(int index, double pressed) {
    final isFirst = index == 0;
    final isLast = index == widget.items.length - 1;
    // Rest radius matches `EdenRadii.lg` for sensible pill corners on outer
    // edges; pressed compresses ~30%.
    const restR = EdenRadii.lg;
    const pressedR = restR * 0.7;
    final r = restR + (pressedR - restR) * pressed;
    return BorderRadius.only(
      topLeft: Radius.circular(isFirst ? r : 0),
      bottomLeft: Radius.circular(isFirst ? r : 0),
      topRight: Radius.circular(isLast ? r : 0),
      bottomRight: Radius.circular(isLast ? r : 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.items.length; i++)
          Flexible(child: _Segment(
            item: widget.items[i],
            index: i,
            isFirst: i == 0,
            isLast: i == widget.items.length - 1,
            isSelected: i == widget.selectedIndex,
            pressController: _pressController,
            isPressed: _pressedIndex == i,
            radiusBuilder: _radiusFor,
            theme: theme,
            onTapDown: () => _setPressed(i),
            onTapUp: () => _setPressed(null),
            onTapCancel: () => _setPressed(null),
            onTap: widget.items[i].enabled ? () => widget.onSelected(i) : null,
          )),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.item,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isSelected,
    required this.pressController,
    required this.isPressed,
    required this.radiusBuilder,
    required this.theme,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  final EdenButtonGroupItem item;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool isSelected;
  final AnimationController pressController;
  final bool isPressed;
  final BorderRadius Function(int, double) radiusBuilder;
  final ThemeData theme;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHigh;
    final fg = isSelected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final disabledOpacity = item.enabled ? 1.0 : 0.4;
    final semanticsLabel =
        item.semanticsLabel ?? item.label ?? 'Button ${index + 1}';

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: item.enabled,
      label: semanticsLabel,
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: item.enabled ? (_) => onTapDown() : null,
        onTapUp: item.enabled ? (_) => onTapUp() : null,
        onTapCancel: item.enabled ? onTapCancel : null,
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pressController,
          builder: (context, _) {
            final pressed = isPressed ? pressController.value.clamp(0.0, 1.0) : 0.0;
            return Opacity(
              opacity: disabledOpacity,
              child: ExcludeSemantics(child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space4,
                  vertical: EdenSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: radiusBuilder(index, pressed),
                  border: Border(
                    top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                    left: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                    right: isLast
                        ? BorderSide(color: theme.colorScheme.outlineVariant, width: 1)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 18, color: fg),
                      if (item.label != null)
                        const SizedBox(width: EdenSpacing.space2),
                    ],
                    if (item.label != null)
                      Flexible(
                        child: Text(
                          item.label!,
                          style: theme.textTheme.labelLarge?.copyWith(color: fg),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              )),
            );
          },
        ),
      ),
    );
  }
}
