import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/springs.dart';

/// Mirrors the eden_card Rails component.
///
/// Supports optional image, horizontal layout, gradient, and glass variants.
///
/// **Obj 010 — `.interactive` variant.** Use [EdenCard.interactive] for the
/// hover-lift + focus-ring + 44pt-min-tap-target variant. Default constructor
/// + behavior unchanged for backwards compatibility.
class EdenCard extends StatelessWidget {
  const EdenCard({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.image,
    this.horizontal = false,
    this.gradient = false,
    this.glass = false,
    this.padding,
    this.onTap,
    this.borderColor,
  })  : interactive = false,
        hoverLift = false,
        focusRing = false,
        onLongPress = null;

  /// Interactive variant — hover lift, focus ring, ripple polish, 44pt-min
  /// tap target.
  ///
  /// Backwards-compatible: existing `EdenCard()` callers see ZERO change.
  /// `.interactive` opts in to the micro-polish.
  ///
  /// Usage:
  /// ```dart
  /// EdenCard.interactive(
  ///   title: 'Job #4291',
  ///   subtitle: 'Tap to open',
  ///   onTap: _openJob,
  ///   onLongPress: _showActions,
  /// )
  /// ```
  const EdenCard.interactive({
    super.key,
    this.child,
    this.title,
    this.subtitle,
    this.image,
    this.horizontal = false,
    this.padding,
    required VoidCallback this.onTap,
    this.onLongPress,
    this.borderColor,
    this.hoverLift = true,
    this.focusRing = true,
  })  : interactive = true,
        gradient = false,
        glass = false;

  final Widget? child;
  final String? title;
  final String? subtitle;
  final ImageProvider? image;
  final bool horizontal;
  final bool gradient;
  final bool glass;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  // Interactive-only fields.
  final bool interactive;
  final bool hoverLift;
  final bool focusRing;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (interactive) {
      return _InteractiveBody(card: this);
    }
    return _buildDefault(context, lifted: 0.0, focused: false);
  }

  Widget _buildDefault(BuildContext context, {required double lifted, required bool focused}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBorderColor = borderColor ?? theme.colorScheme.outlineVariant;
    final focusBorderColor = theme.colorScheme.primary;

    BoxDecoration decoration;
    if (gradient) {
      decoration = BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        border: focused && interactive
            ? Border.all(color: focusBorderColor, width: 2)
            : Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      );
    } else if (glass) {
      decoration = BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        border: focused && interactive
            ? Border.all(color: focusBorderColor, width: 2)
            : Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        color: theme.colorScheme.surface,
        border: focused && interactive
            ? Border.all(color: focusBorderColor, width: 2)
            : Border.all(color: defaultBorderColor),
      );
    }

    Widget content = _buildContent(context);

    if (horizontal && image != null) {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            child: Image(image: image!, width: 140, height: double.infinity, fit: BoxFit.cover, excludeFromSemantics: true),
          ),
          Expanded(child: Padding(
            padding: padding ?? const EdgeInsets.all(EdenSpacing.space4),
            child: _buildContent(context),
          )),
        ],
      );
    } else if (image != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image(image: image!, width: double.infinity, height: 180, fit: BoxFit.cover, excludeFromSemantics: true),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(EdenSpacing.space4),
            child: _buildContent(context),
          ),
        ],
      );
    } else {
      content = Padding(
        padding: padding ?? const EdgeInsets.all(EdenSpacing.space4),
        child: _buildContent(context),
      );
    }

    final card = Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (interactive) {
      // Interactive variant wraps in InkWell with onTap + onLongPress, plus
      // 44pt min height enforcement and Semantics(button: true).
      return Semantics(
        button: true,
        label: title ?? 'Card',
        focused: focused,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: EdenRadii.borderRadiusLg,
              child: card,
            ),
          ),
        ),
      );
    }

    if (onTap != null) {
      return Semantics(
        button: true,
        child: GestureDetector(onTap: onTap, child: card),
      );
    }
    return card;
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    if (child != null) return child!;

    // Use SelectableText for read-only cards (no onTap) so title/subtitle text
    // is selectable on Flutter web. When onTap is set the card is an interactive
    // button — SelectableText would absorb the tap gesture, so we fall back to
    // regular Text and let the GestureDetector handle the interaction.
    final bool selectable = onTap == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          selectable
              ? SelectableText(title!, style: theme.textTheme.titleMedium)
              : Text(title!, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          selectable
              ? SelectableText(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ))
              : Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
        ],
      ],
    );
  }
}

class _InteractiveBody extends StatefulWidget {
  const _InteractiveBody({required this.card});

  final EdenCard card;

  @override
  State<_InteractiveBody> createState() => _InteractiveBodyState();
}

class _InteractiveBodyState extends State<_InteractiveBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _liftController;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _liftController = AnimationController.unbounded(vsync: this, value: 0.0);
  }

  @override
  void dispose() {
    _liftController.dispose();
    super.dispose();
  }

  void _setHover(bool hovering) {
    if (!widget.card.hoverLift) return;
    _liftController.animateWith(EdenSprings.simulationFor(
      EdenSprings.smooth,
      from: _liftController.value,
      to: hovering ? 1.0 : 0.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowFocusHighlight: widget.card.focusRing ? (f) => setState(() => _focused = f) : null,
      onShowHoverHighlight: _setHover,
      child: AnimatedBuilder(
        animation: _liftController,
        builder: (context, _) {
          final lifted = _liftController.value.clamp(0.0, 1.0);
          return Transform.translate(
            offset: Offset(0, -2 * lifted),
            child: widget.card._buildDefault(context, lifted: lifted, focused: _focused),
          );
        },
      ),
    );
  }
}
