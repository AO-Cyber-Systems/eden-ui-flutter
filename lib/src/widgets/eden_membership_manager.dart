import 'dart:math';

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_card.dart';
import 'eden_currency_display.dart';
import 'eden_membership_tier_badge.dart';

/// Membership lifecycle states.
enum EdenMembershipStatus { active, paused, cancelled, pastDue }

/// One membership benefit — supports finite ("2 haircuts/month") and unlimited
/// (`remainingThisCycle: null`).
@immutable
class EdenMembershipBenefit {
  const EdenMembershipBenefit({
    required this.id,
    required this.label,
    this.remainingThisCycle,
    this.totalThisCycle,
    this.resetsAt,
  });

  final String id;
  final String label;
  final int? remainingThisCycle;
  final int? totalThisCycle;
  final DateTime? resetsAt;

  bool get isUnlimited => remainingThisCycle == null;
}

/// Customer's active membership — tier + billing + benefits state. Generic
/// across verticals (salon recurring, gym, trades maintenance subscriptions).
@immutable
class EdenMembership {
  const EdenMembership({
    required this.id,
    required this.customerId,
    required this.tier,
    required this.tierLabel,
    required this.monthlyPriceCents,
    this.currency = 'USD',
    required this.startedAt,
    required this.nextBillingAt,
    required this.status,
    this.benefits = const [],
    this.customerDisplayName,
  });

  final String id;
  final String customerId;
  final EdenMembershipTier tier;
  final String tierLabel;
  final int monthlyPriceCents;
  final String currency;
  final DateTime startedAt;
  final DateTime nextBillingAt;
  final EdenMembershipStatus status;
  final List<EdenMembershipBenefit> benefits;
  final String? customerDisplayName;
}

/// Membership manager surface — tier header (with [EdenMembershipTierBadge]
/// from obj 001-06) + status pill + benefits-remaining list + lifecycle action
/// buttons (Pause/Resume/Cancel/Change card based on status).
class EdenMembershipManager extends StatelessWidget {
  const EdenMembershipManager({
    super.key,
    required this.membership,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onChangeCard,
    this.onUpdatePaymentMethod,
    this.tippingFallbackBuilder,
  });

  final EdenMembership membership;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onChangeCard;
  final VoidCallback? onUpdatePaymentMethod;

  /// Future obj 015 [EdenTippingSelector] integration slot. v1 leaves empty.
  final Widget Function(BuildContext)? tippingFallbackBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                EdenMembershipTierBadge(tier: membership.tier),
                const SizedBox(width: EdenSpacing.space2),
                if (membership.customerDisplayName != null)
                  Expanded(
                    child: Text(
                      membership.customerDisplayName!,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                _StatusPill(status: membership.status),
              ],
            ),
            const SizedBox(height: EdenSpacing.space2),
            Wrap(
              spacing: EdenSpacing.space2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EdenCurrencyDisplay(
                  cents: membership.monthlyPriceCents,
                  currencyCode: membership.currency,
                ),
                Text('/month', style: theme.textTheme.bodyMedium),
                Text('·', style: theme.textTheme.bodyMedium),
                Text(
                  'Next bill: ${_formatDate(membership.nextBillingAt)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (membership.benefits.isNotEmpty) ...[
              const SizedBox(height: EdenSpacing.space4),
              Text(
                'Benefits remaining this cycle:',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: EdenSpacing.space2),
              for (final b in membership.benefits) _BenefitRow(benefit: b),
            ],
            const SizedBox(height: EdenSpacing.space4),
            Wrap(
              spacing: EdenSpacing.space2,
              runSpacing: EdenSpacing.space2,
              children: _actions(),
            ),
            if (tippingFallbackBuilder != null) ...[
              const SizedBox(height: EdenSpacing.space3),
              tippingFallbackBuilder!(context),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _actions() {
    final out = <Widget>[];
    switch (membership.status) {
      case EdenMembershipStatus.active:
        if (onPause != null) {
          out.add(EdenButton(label: 'Pause', onPressed: onPause));
        }
        if (onCancel != null) {
          out.add(EdenButton(
              label: 'Cancel',
              onPressed: onCancel,
              variant: EdenButtonVariant.secondary));
        }
        if (onChangeCard != null) {
          out.add(EdenButton(
              label: 'Change card',
              onPressed: onChangeCard,
              variant: EdenButtonVariant.ghost));
        }
        break;
      case EdenMembershipStatus.paused:
        if (onResume != null) {
          out.add(EdenButton(label: 'Resume', onPressed: onResume));
        }
        if (onCancel != null) {
          out.add(EdenButton(
              label: 'Cancel',
              onPressed: onCancel,
              variant: EdenButtonVariant.secondary));
        }
        if (onChangeCard != null) {
          out.add(EdenButton(
              label: 'Change card',
              onPressed: onChangeCard,
              variant: EdenButtonVariant.ghost));
        }
        break;
      case EdenMembershipStatus.cancelled:
        break;
      case EdenMembershipStatus.pastDue:
        if (onUpdatePaymentMethod != null) {
          out.add(EdenButton(
              label: 'Update payment method',
              onPressed: onUpdatePaymentMethod,
              variant: EdenButtonVariant.danger));
        }
        if (onCancel != null) {
          out.add(EdenButton(
              label: 'Cancel',
              onPressed: onCancel,
              variant: EdenButtonVariant.secondary));
        }
        break;
    }
    return out;
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final EdenMembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    late final String label;
    late final Color bg;
    switch (status) {
      case EdenMembershipStatus.active:
        label = 'Active';
        bg = theme.colorScheme.primary;
        break;
      case EdenMembershipStatus.paused:
        label = 'Paused';
        bg = theme.colorScheme.tertiary;
        break;
      case EdenMembershipStatus.cancelled:
        label = 'Cancelled';
        bg = theme.colorScheme.outline;
        break;
      case EdenMembershipStatus.pastDue:
        label = 'Past due';
        bg = theme.colorScheme.error;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.benefit});

  final EdenMembershipBenefit benefit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(benefit.label, style: theme.textTheme.bodyMedium),
          ),
          if (benefit.isUnlimited)
            Text(
              'Unlimited',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${benefit.remainingThisCycle} of ${benefit.totalThisCycle}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: (benefit.totalThisCycle ?? 0) > 0
                        ? benefit.remainingThisCycle! /
                            max(1, benefit.totalThisCycle!)
                        : 0,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
