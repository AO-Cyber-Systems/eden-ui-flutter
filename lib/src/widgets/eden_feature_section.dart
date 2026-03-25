import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A single feature item for [EdenFeatureSection].
class EdenFeatureItem {
  const EdenFeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// A feature grid section with title and 3-column layout of icon + title + description.
///
/// Used on landing pages to showcase product features.
class EdenFeatureSection extends StatelessWidget {
  const EdenFeatureSection({
    super.key,
    this.title,
    this.subtitle,
    required this.features,
    this.crossAxisCount = 3,
    this.padding,
  });

  /// Optional section title above the feature grid.
  final String? title;

  /// Optional subtitle below the title.
  final String? subtitle;

  /// List of features to display.
  final List<EdenFeatureItem> features;

  /// Number of columns. Defaults to 3.
  final int crossAxisCount;

  /// Custom padding.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space6,
            vertical: EdenSpacing.space12,
          ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: EdenSpacing.space2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: EdenSpacing.space10),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // Use single column for narrow widths
              final effectiveColumns = constraints.maxWidth < 500
                  ? 1
                  : constraints.maxWidth < 700
                      ? 2
                      : crossAxisCount;

              return Wrap(
                spacing: EdenSpacing.space6,
                runSpacing: EdenSpacing.space6,
                children: features.map((feature) {
                  final itemWidth =
                      (constraints.maxWidth -
                              (EdenSpacing.space6 * (effectiveColumns - 1))) /
                          effectiveColumns;
                  return SizedBox(
                    width: itemWidth,
                    child: _FeatureCard(feature: feature),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final EdenFeatureItem feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: EdenRadii.borderRadiusLg,
          ),
          child: Icon(
            feature.icon,
            size: 22,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: EdenSpacing.space3),
        Text(
          feature.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: EdenSpacing.space1),
        Text(
          feature.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
