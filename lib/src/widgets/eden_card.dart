import 'package:flutter/material.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_card Rails component.
///
/// Supports optional image, horizontal layout, gradient, and glass variants.
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
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      );
    } else if (glass) {
      decoration = BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: EdenRadii.borderRadiusLg,
        color: theme.colorScheme.surface,
        border: Border.all(
          color: borderColor ?? theme.colorScheme.outlineVariant,
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Text(title!, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          )),
        ],
      ],
    );
  }
}
