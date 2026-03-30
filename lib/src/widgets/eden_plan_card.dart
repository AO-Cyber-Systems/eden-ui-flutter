import 'package:flutter/material.dart';

/// Pricing/subscription plan card.
///
/// Displays a plan tier with name, price, feature list, and CTA button.
/// Supports a "recommended" highlight state.
///
/// ```dart
/// EdenPlanCard(
///   name: 'Pro',
///   price: '\$49',
///   period: '/month',
///   features: ['Unlimited users', '50GB storage', 'Priority support'],
///   isRecommended: true,
///   ctaLabel: 'Start Free Trial',
///   onCtaTap: () => selectPlan('pro'),
/// )
/// ```
class EdenPlanCard extends StatelessWidget {
  const EdenPlanCard({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isRecommended ? 2 : 1,
        ),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (isRecommended)
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
                Text(name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(price,
                        style: theme.textTheme.headlineLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(period,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 20),
                // Features
                for (final feature in features) ...[
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
                // CTA
                SizedBox(
                  width: double.infinity,
                  child: isCurrent
                      ? OutlinedButton(
                          onPressed: null,
                          child: const Text('Current Plan'),
                        )
                      : FilledButton(
                          onPressed: onCtaTap,
                          child: Text(ctaLabel),
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
