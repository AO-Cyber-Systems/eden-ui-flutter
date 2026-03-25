import 'package:flutter/material.dart';
import '../tokens/spacing.dart';

/// Data model for a pricing plan in [EdenPricingSection].
class EdenPricingPlan {
  const EdenPricingPlan({
    required this.name,
    required this.price,
    this.period = '/month',
    this.description,
    this.features = const [],
    this.isRecommended = false,
    this.isCurrent = false,
    this.ctaLabel = 'Get Started',
    this.onCtaTap,
  });

  final String name;
  final String price;
  final String period;
  final String? description;
  final List<String> features;
  final bool isRecommended;
  final bool isCurrent;
  final String ctaLabel;
  final VoidCallback? onCtaTap;
}

/// A pricing section that displays a horizontal row of plan cards.
///
/// Uses [EdenPlanCard] internally. Wraps responsively on smaller screens.
class EdenPricingSection extends StatelessWidget {
  const EdenPricingSection({
    super.key,
    this.title,
    this.subtitle,
    required this.plans,
    this.padding,
  });

  /// Optional section title.
  final String? title;

  /// Optional subtitle.
  final String? subtitle;

  /// List of pricing plans to display.
  final List<EdenPricingPlan> plans;

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
              final useScroll = constraints.maxWidth < 400 * plans.length;

              if (useScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < plans.length; i++) ...[
                        if (i > 0) const SizedBox(width: EdenSpacing.space4),
                        SizedBox(
                          width: 300,
                          child: _PlanCardWidget(plan: plans[i]),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < plans.length; i++) ...[
                    if (i > 0) const SizedBox(width: EdenSpacing.space4),
                    Expanded(child: _PlanCardWidget(plan: plans[i])),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlanCardWidget extends StatelessWidget {
  const _PlanCardWidget({required this.plan});

  final EdenPricingPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isRecommended
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: plan.isRecommended ? 2 : 1,
        ),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan.isRecommended)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                'Recommended',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (plan.description != null) ...[
                  const SizedBox(height: 4),
                  Text(plan.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(plan.price,
                        style: theme.textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(plan.period,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 20),
                for (final feature in plan.features) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle,
                            size: 18, color: Colors.green.shade600),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(feature,
                              style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: plan.isCurrent
                      ? OutlinedButton(
                          onPressed: null,
                          child: const Text('Current Plan'),
                        )
                      : FilledButton(
                          onPressed: plan.onCtaTap,
                          child: Text(plan.ctaLabel),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
