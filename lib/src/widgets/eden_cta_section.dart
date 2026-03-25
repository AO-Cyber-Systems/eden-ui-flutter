import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A call-to-action banner section with title, description, and button.
///
/// Used for promotional or conversion sections on landing pages.
class EdenCTASection extends StatelessWidget {
  const EdenCTASection({
    super.key,
    required this.title,
    this.description,
    this.ctaLabel = 'Get Started',
    this.onCtaTap,
    this.backgroundColor,
    this.padding,
  });

  /// The headline text.
  final String title;

  /// Supporting description text.
  final String? description;

  /// Label for the CTA button.
  final String ctaLabel;

  /// Called when the CTA button is tapped.
  final VoidCallback? onCtaTap;

  /// Background color override. Defaults to primary container.
  final Color? backgroundColor;

  /// Custom padding.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space8,
            vertical: EdenSpacing.space12,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primaryContainer,
        borderRadius: EdenRadii.borderRadiusXl,
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: EdenSpacing.space3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
          const SizedBox(height: EdenSpacing.space6),
          FilledButton(
            onPressed: onCtaTap,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space8,
                vertical: EdenSpacing.space3,
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(ctaLabel),
          ),
        ],
      ),
    );
  }
}
