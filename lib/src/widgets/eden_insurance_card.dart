import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_alert.dart';
import 'eden_authenticated_image.dart';
import 'eden_badge.dart';

/// Insurance plan type. Generalizes to ID-document capture across verticals
/// via the [other] escape hatch + [EdenInsurancePolicy.customPlanTypeLabel].
enum EdenInsurancePlanType {
  /// Preferred Provider Organization.
  ppo,

  /// Health Maintenance Organization.
  hmo,

  /// Exclusive Provider Organization.
  epo,

  /// Point of Service.
  pos,

  /// High-Deductible Health Plan.
  hdhp,

  /// US Medicare (federal).
  medicare,

  /// US Medicaid (federal/state).
  medicaid,

  /// Military TRICARE.
  militaryTricare,

  /// Dental coverage.
  dental,

  /// Vision coverage.
  vision,

  /// Cross-vertical escape hatch — pair with
  /// [EdenInsurancePolicy.customPlanTypeLabel] to relabel (e.g.,
  /// 'Driver License — CDL Class A', 'Warranty', 'Gov Benefit Card').
  other,
}

/// Billing-priority rank for coverage coordination.
enum EdenInsurancePriority {
  /// Primary — billed first.
  primary,

  /// Secondary — billed after primary.
  secondary,

  /// Tertiary — billed after secondary.
  tertiary,
}

/// Subscriber relationship to the patient.
enum EdenSubscriberRelation {
  /// Patient IS the subscriber.
  self,

  /// Spouse of the patient is the subscriber.
  spouse,

  /// Child of the patient (patient IS the dependent child).
  child,

  /// Other relationship.
  other,
}

/// Visual layout for the [EdenInsuranceCard].
enum EdenInsuranceCardLayout {
  /// Front above back, fields below — mobile-first default.
  stacked,

  /// Front + back side-by-side at >=600pt; collapses to [stacked] below.
  sideBySide,
}

/// Patient insurance policy value class.
///
/// Generalizes to ID-document capture across verticals: set [planType] to
/// [EdenInsurancePlanType.other] + provide a [customPlanTypeLabel] for
/// trades driver licenses, retail warranty cards, gov benefit IDs, etc.
@immutable
class EdenInsurancePolicy {
  const EdenInsurancePolicy({
    required this.id,
    required this.patientId,
    required this.planName,
    required this.planType,
    required this.payerId,
    required this.memberId,
    this.groupNumber,
    this.planEffectiveDate,
    this.planTerminationDate,
    this.priorityRank = EdenInsurancePriority.primary,
    this.subscriberName,
    this.subscriberRelation = EdenSubscriberRelation.self,
    this.frontImageUrl,
    this.backImageUrl,
    this.verifiedAt,
    this.customPlanTypeLabel,
  });

  /// Stable id (typically backend policy-record id).
  final String id;

  /// HIPAA isolation key — insurance is patient-specific PHI.
  final String patientId;

  /// Display plan name (e.g., 'Aetna Choice POS II').
  final String planName;

  /// Plan-type enum. Drives the type-pill badge text + cross-vertical
  /// override branch.
  final EdenInsurancePlanType planType;

  /// Payer identifier (e.g., '60054' for Aetna). Free-form string —
  /// consumer maps from clearinghouse / payer registry.
  final String payerId;

  /// Subscriber's member id printed on the card.
  final String memberId;

  /// Group number when present (often null for individual policies).
  final String? groupNumber;

  /// Plan effective date.
  final DateTime? planEffectiveDate;

  /// Plan termination date. When in the past, an expired-policy banner
  /// renders at the top of the card.
  final DateTime? planTerminationDate;

  /// Billing-priority rank.
  final EdenInsurancePriority priorityRank;

  /// Subscriber display name (e.g., 'Alex Alpha').
  final String? subscriberName;

  /// Relationship of subscriber to patient.
  final EdenSubscriberRelation subscriberRelation;

  /// Front-of-card image URL. Library composes [EdenAuthenticatedImage]
  /// for actual rendering — consumer provides any auth headers via the
  /// widget API (TBD: card-level headers parameter; v1 fetches anonymously).
  final String? frontImageUrl;

  /// Back-of-card image URL.
  final String? backImageUrl;

  /// Last verified-at timestamp. Null → "Not verified" warning chip.
  final DateTime? verifiedAt;

  /// When [planType] is [EdenInsurancePlanType.other], this overrides the
  /// type-pill label (e.g., 'Driver License — CDL Class A'). Ignored for
  /// all other plan types.
  final String? customPlanTypeLabel;
}

/// Patient insurance card front/back capture + extracted-data display
/// (obj 017-02).
///
/// Composes obj 001-07 [EdenAuthenticatedImage] for backend-served card
/// images. Library is OCR-agnostic + transport-agnostic — consumer wires
/// card-image capture + OCR extraction; the widget renders the result.
///
/// Cross-vertical reuse: use [EdenInsurancePlanType.other] +
/// [EdenInsurancePolicy.customPlanTypeLabel] to relabel for trades driver
/// licenses, retail warranty cards, gov benefit IDs, etc.
class EdenInsuranceCard extends StatelessWidget {
  const EdenInsuranceCard({
    super.key,
    required this.policy,
    this.layout = EdenInsuranceCardLayout.stacked,
    this.onEditRequested,
    this.onReplaceImageRequested,
    this.onCardImageTap,
    this.now,
  });

  /// The insurance policy to render.
  final EdenInsurancePolicy policy;

  /// Layout variant. Defaults to [EdenInsuranceCardLayout.stacked].
  final EdenInsuranceCardLayout layout;

  /// Fires when the user taps the edit-pencil icon.
  final ValueChanged<EdenInsurancePolicy>? onEditRequested;

  /// Fires when the user taps the per-image replace-overlay affordance.
  /// Library does NOT wire camera / file-picker — consumer handles
  /// platform image acquisition.
  final ValueChanged<EdenInsurancePolicy>? onReplaceImageRequested;

  /// Fires when the user taps a card image (for full-screen viewer
  /// escalation). Distinct from [onReplaceImageRequested].
  final VoidCallback? onCardImageTap;

  /// Optional deterministic clock for tests. Production code defaults to
  /// [DateTime.now].
  final DateTime? now;

  static const double _sideBySideBreakpoint = 600;

  bool get _isExpired {
    final terminationDate = policy.planTerminationDate;
    if (terminationDate == null) return false;
    final clock = now ?? DateTime.now();
    return terminationDate.isBefore(clock);
  }

  String _planTypeLabel() {
    if (policy.planType == EdenInsurancePlanType.other &&
        policy.customPlanTypeLabel != null) {
      return policy.customPlanTypeLabel!;
    }
    return switch (policy.planType) {
      EdenInsurancePlanType.ppo => 'PPO',
      EdenInsurancePlanType.hmo => 'HMO',
      EdenInsurancePlanType.epo => 'EPO',
      EdenInsurancePlanType.pos => 'POS',
      EdenInsurancePlanType.hdhp => 'HDHP',
      EdenInsurancePlanType.medicare => 'Medicare',
      EdenInsurancePlanType.medicaid => 'Medicaid',
      EdenInsurancePlanType.militaryTricare => 'TRICARE',
      EdenInsurancePlanType.dental => 'Dental',
      EdenInsurancePlanType.vision => 'Vision',
      EdenInsurancePlanType.other => 'Other',
    };
  }

  String _priorityLabel() {
    return switch (policy.priorityRank) {
      EdenInsurancePriority.primary => 'Primary',
      EdenInsurancePriority.secondary => 'Secondary',
      EdenInsurancePriority.tertiary => 'Tertiary',
    };
  }

  EdenBadgeVariant _priorityVariant() {
    return switch (policy.priorityRank) {
      EdenInsurancePriority.primary => EdenBadgeVariant.success,
      EdenInsurancePriority.secondary => EdenBadgeVariant.warning,
      EdenInsurancePriority.tertiary => EdenBadgeVariant.neutral,
    };
  }

  String _subscriberRelationLabel() {
    return switch (policy.subscriberRelation) {
      EdenSubscriberRelation.self => 'Self',
      EdenSubscriberRelation.spouse => 'Spouse',
      EdenSubscriberRelation.child => 'Child',
      EdenSubscriberRelation.other => 'Other',
    };
  }

  static String _formatDate(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideBySide = layout == EdenInsuranceCardLayout.sideBySide &&
            constraints.maxWidth >= _sideBySideBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExpired) ...[
              _buildExpiredBanner(context),
              const SizedBox(height: EdenSpacing.space2),
            ],
            _buildHeaderRow(context),
            const SizedBox(height: EdenSpacing.space3),
            _buildImagesBlock(context, useSideBySide: useSideBySide),
            const SizedBox(height: EdenSpacing.space3),
            _buildExtractedFieldsGrid(context),
          ],
        );
      },
    );
  }

  Widget _buildExpiredBanner(BuildContext context) {
    final terminationDate = policy.planTerminationDate!;
    return EdenAlert(
      key: const ValueKey('eden-insurance-card-expired-banner'),
      message: 'Policy expired ${_formatDate(terminationDate)}',
      variant: EdenAlertVariant.warning,
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            policy.planName,
            style: (theme.textTheme.titleMedium ?? const TextStyle())
                .copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onEditRequested != null)
          IconButton(
            key: const ValueKey('eden-insurance-card-edit-button'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit policy',
            visualDensity: VisualDensity.compact,
            onPressed: () => onEditRequested!(policy),
          ),
      ],
    );
  }

  Widget _buildImagesBlock(
    BuildContext context, {
    required bool useSideBySide,
  }) {
    final bothNull =
        policy.frontImageUrl == null && policy.backImageUrl == null;
    if (bothNull) {
      return _buildEmptyImagesPlaceholder(context);
    }
    final front = _buildSingleImage(
      context,
      url: policy.frontImageUrl,
      side: 'front',
    );
    final back = _buildSingleImage(
      context,
      url: policy.backImageUrl,
      side: 'back',
    );
    if (useSideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: front),
          const SizedBox(width: EdenSpacing.space3),
          Expanded(child: back),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        front,
        const SizedBox(height: EdenSpacing.space3),
        back,
      ],
    );
  }

  Widget _buildSingleImage(
    BuildContext context, {
    required String? url,
    required String side,
  }) {
    final theme = Theme.of(context);
    final outerBorderRadius = BorderRadius.circular(EdenRadii.lg);
    Widget imageContent;
    if (url == null) {
      imageContent = Container(
        height: 160,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: outerBorderRadius,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        child: Text(
          side == 'front'
              ? 'Front image not available'
              : 'Back image not available',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } else {
      imageContent = ClipRRect(
        borderRadius: outerBorderRadius,
        child: SizedBox(
          height: 160,
          width: double.infinity,
          child: EdenAuthenticatedImage(
            url: url,
            errorWidget: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    final stack = Stack(
      children: [
        imageContent,
        if (onReplaceImageRequested != null)
          Positioned(
            top: EdenSpacing.space1,
            right: EdenSpacing.space1,
            child: Material(
              color: Colors.black.withValues(alpha: 0.5),
              shape: const CircleBorder(),
              child: InkWell(
                key: ValueKey('eden-insurance-card-replace-$side'),
                customBorder: const CircleBorder(),
                onTap: () => onReplaceImageRequested!(policy),
                child: const Padding(
                  padding: EdgeInsets.all(EdenSpacing.space2),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (onCardImageTap == null) return stack;
    return InkWell(
      key: ValueKey('eden-insurance-card-image-tap-$side'),
      borderRadius: outerBorderRadius,
      onTap: onCardImageTap,
      child: stack,
    );
  }

  Widget _buildEmptyImagesPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('eden-insurance-card-empty-placeholder'),
      height: 160,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EdenRadii.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          if (onReplaceImageRequested != null) ...[
            const SizedBox(height: EdenSpacing.space2),
            TextButton.icon(
              key: const ValueKey(
                'eden-insurance-card-add-image-button',
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add insurance card images'),
              onPressed: () => onReplaceImageRequested!(policy),
            ),
          ] else ...[
            const SizedBox(height: EdenSpacing.space2),
            Text(
              'No insurance card images',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedFieldsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final groupNumber = policy.groupNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: planName + planType pill
        _buildFieldRow(
          context,
          label: 'Plan',
          valueWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  policy.planName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: EdenSpacing.space2),
              _PlanTypeBadge(label: _planTypeLabel()),
            ],
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        // Row 2: payerId + memberId
        _buildFieldRow(
          context,
          label: 'Payer',
          valueWidget: Text('${policy.payerId} • Member ${policy.memberId}'),
        ),
        const SizedBox(height: EdenSpacing.space2),
        // Row 3: groupNumber
        _buildFieldRow(
          context,
          label: 'Group',
          valueWidget: Text(groupNumber ?? '—'),
        ),
        const SizedBox(height: EdenSpacing.space2),
        // Row 4: subscriberName + relation
        _buildFieldRow(
          context,
          label: 'Subscriber',
          valueWidget: Text(
            '${policy.subscriberName ?? '—'} '
            '(${_subscriberRelationLabel()})',
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        // Row 5: priorityRank pill + verified-at (wraps at narrow widths
        // so iPhone-narrow ≥390pt doesn't overflow).
        _buildFieldRow(
          context,
          label: 'Status',
          valueWidget: Wrap(
            spacing: EdenSpacing.space2,
            runSpacing: EdenSpacing.space1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              EdenBadge(
                label: _priorityLabel(),
                variant: _priorityVariant(),
                size: EdenBadgeSize.sm,
              ),
              if (policy.verifiedAt != null)
                Text(
                  'Verified ${_formatDate(policy.verifiedAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                const EdenBadge(
                  label: 'Not verified',
                  variant: EdenBadgeVariant.warning,
                  size: EdenBadgeSize.sm,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldRow(
    BuildContext context, {
    required String label,
    required Widget valueWidget,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: valueWidget),
      ],
    );
  }
}

/// Outlined plan-type pill (locked: outlined for descriptive type;
/// priorityRank uses filled variants).
class _PlanTypeBadge extends StatelessWidget {
  const _PlanTypeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(EdenRadii.sm),
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
