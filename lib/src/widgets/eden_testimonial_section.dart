import 'package:flutter/material.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A single testimonial entry.
class EdenTestimonial {
  const EdenTestimonial({
    required this.quote,
    required this.name,
    this.role,
    this.avatarUrl,
    this.avatarImage,
  });

  final String quote;
  final String name;
  final String? role;
  final String? avatarUrl;
  final ImageProvider? avatarImage;
}

/// A testimonial section with quote cards showing name, role, and avatar.
///
/// Used on landing pages for social proof.
class EdenTestimonialSection extends StatelessWidget {
  const EdenTestimonialSection({
    super.key,
    this.title,
    this.subtitle,
    required this.testimonials,
    this.padding,
  });

  /// Optional section title.
  final String? title;

  /// Optional subtitle.
  final String? subtitle;

  /// List of testimonials to display.
  final List<EdenTestimonial> testimonials;

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
              final columns = constraints.maxWidth < 500
                  ? 1
                  : constraints.maxWidth < 800
                      ? 2
                      : 3;

              return Wrap(
                spacing: EdenSpacing.space4,
                runSpacing: EdenSpacing.space4,
                children: testimonials.map((t) {
                  final itemWidth =
                      (constraints.maxWidth -
                              (EdenSpacing.space4 * (columns - 1))) /
                          columns;
                  return SizedBox(
                    width: itemWidth,
                    child: _TestimonialCard(testimonial: t),
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

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final EdenTestimonial testimonial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = testimonial.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: EdenRadii.borderRadiusXl,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            size: 28,
          ),
          const SizedBox(height: EdenSpacing.space2),
          Text(
            testimonial.quote,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),
          Row(
            children: [
              if (testimonial.avatarImage != null)
                CircleAvatar(radius: 18, backgroundImage: testimonial.avatarImage)
              else
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(width: EdenSpacing.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testimonial.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (testimonial.role != null)
                    Text(
                      testimonial.role!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
