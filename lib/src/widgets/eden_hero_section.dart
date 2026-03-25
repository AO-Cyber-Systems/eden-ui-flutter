import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// A large hero section with title, subtitle, CTA button, and optional image.
///
/// Used for landing page hero banners.
class EdenHeroSection extends StatelessWidget {
  const EdenHeroSection({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCtaTap,
    this.image,
    this.secondaryCtaLabel,
    this.onSecondaryCtaTap,
    this.padding,
    this.alignment = CrossAxisAlignment.center,
  });

  /// The main headline text.
  final String title;

  /// Supporting subtitle text below the title.
  final String? subtitle;

  /// Label for the primary CTA button.
  final String? ctaLabel;

  /// Called when the CTA button is tapped.
  final VoidCallback? onCtaTap;

  /// An optional image/widget displayed alongside or below the text.
  final Widget? image;

  /// Label for an optional secondary CTA button.
  final String? secondaryCtaLabel;

  /// Called when the secondary CTA is tapped.
  final VoidCallback? onSecondaryCtaTap;

  /// Custom padding. Defaults to generous vertical padding.
  final EdgeInsets? padding;

  /// Alignment of the text content.
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space6,
            vertical: EdenSpacing.space16,
          ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            title,
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: EdenSpacing.space4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Text(
                subtitle!,
                textAlign: alignment == CrossAxisAlignment.center
                    ? TextAlign.center
                    : TextAlign.start,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (ctaLabel != null || secondaryCtaLabel != null) ...[
            const SizedBox(height: EdenSpacing.space8),
            Wrap(
              spacing: EdenSpacing.space3,
              runSpacing: EdenSpacing.space3,
              alignment: alignment == CrossAxisAlignment.center
                  ? WrapAlignment.center
                  : WrapAlignment.start,
              children: [
                if (ctaLabel != null)
                  FilledButton(
                    onPressed: onCtaTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space8,
                        vertical: EdenSpacing.space4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(ctaLabel!),
                  ),
                if (secondaryCtaLabel != null)
                  OutlinedButton(
                    onPressed: onSecondaryCtaTap,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space8,
                        vertical: EdenSpacing.space4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(secondaryCtaLabel!),
                  ),
              ],
            ),
          ],
          if (image != null) ...[
            const SizedBox(height: EdenSpacing.space10),
            image!,
          ],
        ],
      ),
    );
  }
}
