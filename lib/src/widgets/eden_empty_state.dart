import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import 'eden_app_mode.dart' show kEdenAppModeNarrowMax;

/// Mirrors the eden_empty_state Rails component.
///
/// Placeholder shown when a list or section has no data.
///
/// **Obj 010 enhancements (additive, backwards-compatible):**
/// * [illustration] — Widget slot that replaces the icon circle when supplied.
/// * [secondaryActionLabel] + [onSecondaryAction] — second action button
///   (Polaris convention: primary + secondary side-by-side on ≥480pt, stacked
///   vertically <480pt).
///
/// Existing call-sites (title + icon + actionLabel + onAction) render
/// IDENTICALLY to before.
class EdenEmptyState extends StatelessWidget {
  const EdenEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.illustration,
    this.action,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final Widget? illustration;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  bool get _hasPrimary =>
      action != null || (actionLabel != null && onAction != null);
  bool get _hasSecondary =>
      secondaryActionLabel != null && onSecondaryAction != null;

  Widget _buildLeading(BuildContext context) {
    if (illustration != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200, maxHeight: 200),
        child: illustration!,
      );
    }
    if (icon != null) {
      final theme = Theme.of(context);
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 28, color: theme.colorScheme.primary),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrimary() {
    if (action != null) return action!;
    return ElevatedButton(onPressed: onAction, child: Text(actionLabel!));
  }

  Widget _buildSecondary() {
    return OutlinedButton(
      onPressed: onSecondaryAction,
      child: Text(secondaryActionLabel!),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_hasPrimary && _hasSecondary) {
      return LayoutBuilder(builder: (context, constraints) {
        final stacked = constraints.maxWidth < kEdenAppModeNarrowMax;
        if (stacked) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            _buildPrimary(),
            const SizedBox(height: EdenSpacing.space2),
            _buildSecondary(),
          ]);
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrimary(),
            const SizedBox(width: EdenSpacing.space3),
            _buildSecondary(),
          ],
        );
      });
    }
    if (_hasPrimary) return _buildPrimary();
    if (_hasSecondary) return _buildSecondary();
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLeading = illustration != null || icon != null;
    final hasActions = _hasPrimary || _hasSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space16,
          horizontal: EdenSpacing.space8,
        ),
        child: Semantics(
          container: true,
          label: '$title - empty state',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasLeading) _buildLeading(context),
              if (hasLeading) const SizedBox(height: EdenSpacing.space4),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (description != null) ...[
                const SizedBox(height: EdenSpacing.space2),
                Text(
                  description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (hasActions) ...[
                const SizedBox(height: EdenSpacing.space4),
                _buildActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
