import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_alert.dart';
import 'eden_badge.dart';
import 'eden_currency_display.dart';

/// 270/271 eligibility coverage outcome.
enum EdenCoverageStatus {
  /// Service is covered.
  covered,

  /// Service is covered but with patient-side limits (e.g., deductible
  /// not yet met).
  partiallyCovered,

  /// Service is NOT covered.
  notCovered,

  /// Coverage exists but prior authorization is required before service.
  needsAuth,

  /// Eligibility could not be determined; consumer should re-check.
  unknown,
}

/// Prior-authorization status. `required_` carries a trailing underscore
/// to avoid clashing with the `required` Dart keyword.
enum EdenPriorAuthStatus {
  /// No prior authorization needed.
  notRequired,

  /// Prior authorization needed but not yet submitted.
  required_,

  /// Prior authorization submitted; awaiting decision.
  pending,

  /// Prior authorization approved.
  approved,

  /// Prior authorization denied.
  denied,
}

/// Network status for the rendered eligibility result.
enum EdenInsuranceNetworkStatus {
  /// In-network preferred provider.
  inNetwork,

  /// Out-of-network — denial risk.
  outOfNetwork,

  /// Tier-1 narrow-network (lowest cost-share).
  tier1,

  /// Tier-2 broader-network (medium cost-share).
  tier2,

  /// Tier-3 widest-network (highest cost-share).
  tier3,
}

/// Visual density variant.
enum EdenEligibilityCardLayout {
  /// Full vertical card with all rows visible.
  standard,

  /// Coverage status + 1-line responsibility summary + recheck button.
  compact,

  /// 3 inline tiles (coverage pill + copay + deductible remaining).
  /// Wraps to 2 rows at iPhone-narrow (<390pt).
  kpiStrip,
}

/// 270/271 eligibility result value class.
///
/// Library renders the consumer's already-fetched eligibility data — no
/// transport binding, no clearinghouse client, no payer-API knowledge.
/// All dollar amounts stored as int cents (matches [EdenCurrencyDisplay]).
@immutable
class EdenEligibilityResult {
  const EdenEligibilityResult({
    required this.id,
    required this.patientId,
    required this.policyId,
    required this.checkedAt,
    required this.coverageStatus,
    required this.planName,
    required this.serviceType,
    this.copayCents,
    this.coinsurancePercent,
    this.deductibleAmountCents,
    this.deductibleMetCents,
    this.deductibleRemainingCents,
    this.outOfPocketMaxCents,
    this.outOfPocketMetCents,
    this.outOfPocketRemainingCents,
    this.priorAuthRequired = false,
    this.priorAuthStatus,
    this.referralRequired = false,
    required this.networkStatus,
    this.rawPayerResponse,
    this.currencyCode = 'USD',
  }) : assert(
          policyId != '',
          'EdenEligibilityResult.policyId must be non-empty',
        );

  /// Stable id (typically backend eligibility-check record id).
  final String id;

  /// HIPAA isolation key.
  final String patientId;

  /// Linkage to the originating [EdenInsurancePolicy.id] (017-02).
  /// Library does NOT enforce cross-table referential integrity — that
  /// is the consumer's job. Constructor asserts non-empty.
  final String policyId;

  /// When the 270/271 check was performed.
  final DateTime checkedAt;

  /// Coverage outcome.
  final EdenCoverageStatus coverageStatus;

  /// Display plan name.
  final String planName;

  /// Free-form service type ('Office visit (PCP)', 'TMS therapy', etc.).
  final String serviceType;

  /// Patient copay per visit, in cents (e.g., 2500 = $25).
  final int? copayCents;

  /// Patient coinsurance share, 0..100 (e.g., 20.0 = 20%).
  final double? coinsurancePercent;

  /// Annual deductible, in cents.
  final int? deductibleAmountCents;

  /// Deductible amount met to date, in cents.
  final int? deductibleMetCents;

  /// Remaining deductible to satisfy, in cents.
  final int? deductibleRemainingCents;

  /// Annual out-of-pocket maximum, in cents.
  final int? outOfPocketMaxCents;

  /// Out-of-pocket spend to date, in cents.
  final int? outOfPocketMetCents;

  /// Remaining out-of-pocket cap, in cents.
  final int? outOfPocketRemainingCents;

  /// Whether prior authorization is required for this service.
  final bool priorAuthRequired;

  /// Prior authorization status when [priorAuthRequired] is true.
  final EdenPriorAuthStatus? priorAuthStatus;

  /// Whether a specialist referral is required before service.
  final bool referralRequired;

  /// Network status for the rendered service.
  final EdenInsuranceNetworkStatus networkStatus;

  /// Opaque payer-response payload for consumer storage. Library does
  /// NOT parse this — it's a passthrough.
  final String? rawPayerResponse;

  /// ISO-4217 currency code. Defaults to 'USD'.
  final String currencyCode;
}

/// 270/271 eligibility result display widget (obj 017-04).
///
/// Composes [EdenAlert] for coverage status, [EdenBadge] for network
/// status, and [EdenCurrencyDisplay] for every dollar amount.
///
/// Library is transport-agnostic: consumer fetches the 270/271; widget
/// renders the result. Per UC-PRE-01: "patient responsibility known at
/// check-in" — athenahealth marquee KPI.
class EdenEligibilityResultCard extends StatelessWidget {
  const EdenEligibilityResultCard({
    super.key,
    required this.result,
    this.onRecheckRequested,
    this.onAuthRequestRequested,
    this.onTapPatientResponsibilityBreakdown,
    this.layout = EdenEligibilityCardLayout.standard,
    this.now,
  });

  /// The eligibility result to render.
  final EdenEligibilityResult result;

  /// Fires when the user taps "Re-check Eligibility".
  final ValueChanged<EdenEligibilityResult>? onRecheckRequested;

  /// Fires when the user taps "Request Authorization".
  final ValueChanged<EdenEligibilityResult>? onAuthRequestRequested;

  /// When non-null, the patient-responsibility block becomes tappable
  /// (full-screen breakdown escalation).
  final ValueChanged<EdenEligibilityResult>? onTapPatientResponsibilityBreakdown;

  /// Visual density.
  final EdenEligibilityCardLayout layout;

  /// Optional deterministic clock for stale-check tests.
  final DateTime? now;

  static const int _staleThresholdDays = 30;

  bool get _isStale {
    final clock = now ?? DateTime.now();
    return clock.difference(result.checkedAt).inDays > _staleThresholdDays;
  }

  EdenAlertVariant _coverageAlertVariant() {
    return switch (result.coverageStatus) {
      EdenCoverageStatus.covered => EdenAlertVariant.success,
      EdenCoverageStatus.partiallyCovered => EdenAlertVariant.warning,
      EdenCoverageStatus.notCovered => EdenAlertVariant.danger,
      EdenCoverageStatus.needsAuth => EdenAlertVariant.warning,
      EdenCoverageStatus.unknown => EdenAlertVariant.info,
    };
  }

  String _coverageAlertMessage() {
    return switch (result.coverageStatus) {
      EdenCoverageStatus.covered => 'Covered — ${result.planName}',
      EdenCoverageStatus.partiallyCovered =>
        'Partial coverage — ${result.planName}',
      EdenCoverageStatus.notCovered => 'Not covered — ${result.planName}',
      EdenCoverageStatus.needsAuth =>
        'Coverage available — Prior authorization required',
      EdenCoverageStatus.unknown =>
        'Coverage unknown — re-check required',
    };
  }

  String _networkBadgeLabel() {
    return switch (result.networkStatus) {
      EdenInsuranceNetworkStatus.inNetwork => 'In Network',
      EdenInsuranceNetworkStatus.outOfNetwork => 'OUT OF NETWORK',
      EdenInsuranceNetworkStatus.tier1 => 'Tier 1',
      EdenInsuranceNetworkStatus.tier2 => 'Tier 2',
      EdenInsuranceNetworkStatus.tier3 => 'Tier 3',
    };
  }

  EdenBadgeVariant _networkBadgeVariant() {
    return switch (result.networkStatus) {
      EdenInsuranceNetworkStatus.inNetwork => EdenBadgeVariant.success,
      EdenInsuranceNetworkStatus.outOfNetwork => EdenBadgeVariant.danger,
      EdenInsuranceNetworkStatus.tier1 => EdenBadgeVariant.neutral,
      EdenInsuranceNetworkStatus.tier2 => EdenBadgeVariant.neutral,
      EdenInsuranceNetworkStatus.tier3 => EdenBadgeVariant.neutral,
    };
  }

  String _priorAuthStatusLabel() {
    return switch (result.priorAuthStatus) {
      EdenPriorAuthStatus.notRequired => 'Not required',
      EdenPriorAuthStatus.required_ => 'Required',
      EdenPriorAuthStatus.pending => 'Pending',
      EdenPriorAuthStatus.approved => 'Approved',
      EdenPriorAuthStatus.denied => 'Denied',
      null => 'Required',
    };
  }

  EdenBadgeVariant _priorAuthBadgeVariant() {
    return switch (result.priorAuthStatus) {
      EdenPriorAuthStatus.approved => EdenBadgeVariant.success,
      EdenPriorAuthStatus.denied => EdenBadgeVariant.danger,
      EdenPriorAuthStatus.pending => EdenBadgeVariant.warning,
      EdenPriorAuthStatus.required_ => EdenBadgeVariant.warning,
      EdenPriorAuthStatus.notRequired => EdenBadgeVariant.neutral,
      null => EdenBadgeVariant.warning,
    };
  }

  static String _formatDate(DateTime d) {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${pad(d.month)}-${pad(d.day)}';
  }

  @override
  Widget build(BuildContext context) {
    return switch (layout) {
      EdenEligibilityCardLayout.standard => _buildStandard(context),
      EdenEligibilityCardLayout.compact => _buildCompact(context),
      EdenEligibilityCardLayout.kpiStrip => _buildKpiStrip(context),
    };
  }

  Widget _buildStandard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isStale) ...[
          _buildStaleBanner(context),
          const SizedBox(height: EdenSpacing.space2),
        ],
        _buildCoverageAlert(context),
        const SizedBox(height: EdenSpacing.space3),
        _buildServiceTypeRow(context),
        const SizedBox(height: EdenSpacing.space3),
        _buildResponsibilityBlock(context),
        const SizedBox(height: EdenSpacing.space3),
        _buildNetworkRow(context),
        if (result.priorAuthRequired) ...[
          const SizedBox(height: EdenSpacing.space2),
          _buildPriorAuthRow(context),
        ],
        if (result.referralRequired) ...[
          const SizedBox(height: EdenSpacing.space2),
          _buildReferralWarning(context),
        ],
        const SizedBox(height: EdenSpacing.space3),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isStale) ...[
          _buildStaleBanner(context),
          const SizedBox(height: EdenSpacing.space2),
        ],
        _buildCoverageAlert(context),
        const SizedBox(height: EdenSpacing.space2),
        Wrap(
          spacing: EdenSpacing.space2,
          runSpacing: EdenSpacing.space1,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (result.copayCents != null) ...[
              Text(
                'Copay:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              EdenCurrencyDisplay(
                cents: result.copayCents!,
                currencyCode: result.currencyCode,
              ),
            ],
            if (result.deductibleRemainingCents != null) ...[
              Text(
                '• Deductible remaining:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              EdenCurrencyDisplay(
                cents: result.deductibleRemainingCents!,
                currencyCode: result.currencyCode,
              ),
            ],
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        _buildRecheckButton(context),
      ],
    );
  }

  Widget _buildKpiStrip(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isStale) ...[
          _buildStaleBanner(context),
          const SizedBox(height: EdenSpacing.space2),
        ],
        Wrap(
          spacing: EdenSpacing.space3,
          runSpacing: EdenSpacing.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _KpiTile(
              label: 'Coverage',
              valueWidget: EdenBadge(
                label: _coverageAlertMessage(),
                variant: _coverageBadgeVariant(),
                size: EdenBadgeSize.sm,
              ),
            ),
            if (result.copayCents != null)
              _KpiTile(
                label: 'Copay',
                valueWidget: EdenCurrencyDisplay(
                  cents: result.copayCents!,
                  currencyCode: result.currencyCode,
                ),
              ),
            if (result.deductibleRemainingCents != null)
              _KpiTile(
                label: 'Deductible remaining',
                valueWidget: EdenCurrencyDisplay(
                  cents: result.deductibleRemainingCents!,
                  currencyCode: result.currencyCode,
                ),
              ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        _buildRecheckButton(context),
      ],
    );
  }

  EdenBadgeVariant _coverageBadgeVariant() {
    return switch (result.coverageStatus) {
      EdenCoverageStatus.covered => EdenBadgeVariant.success,
      EdenCoverageStatus.partiallyCovered => EdenBadgeVariant.warning,
      EdenCoverageStatus.notCovered => EdenBadgeVariant.danger,
      EdenCoverageStatus.needsAuth => EdenBadgeVariant.warning,
      EdenCoverageStatus.unknown => EdenBadgeVariant.neutral,
    };
  }

  Widget _buildStaleBanner(BuildContext context) {
    return const EdenAlert(
      key: ValueKey('eden-eligibility-stale-banner'),
      message:
          'Eligibility check is stale (>30 days). Re-check before service.',
      variant: EdenAlertVariant.warning,
    );
  }

  Widget _buildCoverageAlert(BuildContext context) {
    return EdenAlert(
      key: const ValueKey('eden-eligibility-coverage-alert'),
      message: _coverageAlertMessage(),
      variant: _coverageAlertVariant(),
    );
  }

  Widget _buildServiceTypeRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.medical_services_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Text(
            result.serviceType,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsibilityBlock(BuildContext context) {
    final theme = Theme.of(context);
    final hasTap = onTapPatientResponsibilityBreakdown != null;
    final content = Column(
      key: const ValueKey('eden-eligibility-responsibility-block'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient responsibility',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        if (result.copayCents != null)
          _buildResponsibilityRow(
            context,
            label: 'Copay',
            valueWidget: EdenCurrencyDisplay(
              cents: result.copayCents!,
              currencyCode: result.currencyCode,
            ),
          ),
        if (result.coinsurancePercent != null)
          _buildResponsibilityRow(
            context,
            label: 'Coinsurance',
            valueWidget:
                Text('${result.coinsurancePercent!.toStringAsFixed(0)}%'),
          ),
        if (result.deductibleRemainingCents != null)
          _buildResponsibilityRow(
            context,
            label: 'Deductible remaining',
            valueWidget: EdenCurrencyDisplay(
              cents: result.deductibleRemainingCents!,
              currencyCode: result.currencyCode,
            ),
          ),
        if (result.outOfPocketRemainingCents != null)
          _buildResponsibilityRow(
            context,
            label: 'Out-of-pocket remaining',
            valueWidget: EdenCurrencyDisplay(
              cents: result.outOfPocketRemainingCents!,
              currencyCode: result.currencyCode,
            ),
          ),
      ],
    );
    if (!hasTap) return content;
    return InkWell(
      key: const ValueKey('eden-eligibility-responsibility-inkwell'),
      onTap: () => onTapPatientResponsibilityBreakdown!(result),
      child: content,
    );
  }

  Widget _buildResponsibilityRow(
    BuildContext context, {
    required String label,
    required Widget valueWidget,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: EdenSpacing.space1),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Widget _buildNetworkRow(BuildContext context) {
    return Row(
      children: [
        Text(
          'Network:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        EdenBadge(
          label: _networkBadgeLabel(),
          variant: _networkBadgeVariant(),
        ),
      ],
    );
  }

  Widget _buildPriorAuthRow(BuildContext context) {
    final theme = Theme.of(context);
    final canRequestAuth = onAuthRequestRequested != null &&
        (result.priorAuthStatus == EdenPriorAuthStatus.required_ ||
            result.priorAuthStatus == EdenPriorAuthStatus.denied);
    return Wrap(
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Prior auth:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        EdenBadge(
          label: _priorAuthStatusLabel(),
          variant: _priorAuthBadgeVariant(),
          size: EdenBadgeSize.sm,
        ),
        if (canRequestAuth)
          OutlinedButton.icon(
            key: const ValueKey('eden-eligibility-request-auth-button'),
            icon: const Icon(Icons.outgoing_mail),
            label: const Text('Request Authorization'),
            onPressed: () => onAuthRequestRequested!(result),
          ),
      ],
    );
  }

  Widget _buildReferralWarning(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 16,
          color: theme.colorScheme.error,
        ),
        const SizedBox(width: EdenSpacing.space1),
        Expanded(
          child: Text(
            'Specialist referral required before service',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Last checked ${_formatDate(result.checkedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        _buildRecheckButton(context),
      ],
    );
  }

  Widget _buildRecheckButton(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('eden-eligibility-recheck-button'),
      icon: const Icon(Icons.refresh),
      label: const Text('Re-check Eligibility'),
      onPressed:
          onRecheckRequested == null ? null : () => onRecheckRequested!(result),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.valueWidget});
  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EdenSpacing.space1),
        valueWidget,
      ],
    );
  }
}
