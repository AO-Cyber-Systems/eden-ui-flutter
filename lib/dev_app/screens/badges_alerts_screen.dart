import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
import '../widgets/interactive_controls.dart';
import '../widgets/section.dart';

class BadgesAlertsScreen extends StatefulWidget {
  const BadgesAlertsScreen({super.key});

  @override
  State<BadgesAlertsScreen> createState() => _BadgesAlertsScreenState();
}

class _BadgesAlertsScreenState extends State<BadgesAlertsScreen> {
  EdenBadgeVariant _badgeVariant = EdenBadgeVariant.primary;
  EdenAlertVariant _alertVariant = EdenAlertVariant.info;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Badges & Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          InteractivePlayground(
            title: 'Badge Explorer',
            preview: EdenBadge(label: 'Preview', variant: _badgeVariant),
            controls: [
              EnumSelector<EdenBadgeVariant>(
                values: EdenBadgeVariant.values,
                selected: _badgeVariant,
                onChanged: (v) => setState(() => _badgeVariant = v),
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space3),
          InteractivePlayground(
            title: 'Alert Explorer',
            preview: EdenAlert(
              title: 'Alert Preview',
              message: 'This is a preview alert message.',
              variant: _alertVariant,
            ),
            controls: [
              EnumSelector<EdenAlertVariant>(
                values: EdenAlertVariant.values,
                selected: _alertVariant,
                onChanged: (v) => setState(() => _alertVariant = v),
              ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),
          Section(
            title: 'Badge Variants',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenBadgeVariant.values.map((v) => EdenBadge(
                label: v.name[0].toUpperCase() + v.name.substring(1),
                variant: v,
              )).toList(),
            ),
          ),
          Section(
            title: 'Badge Sizes',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: EdenBadgeSize.values.map((s) => EdenBadge(
                label: s.name.toUpperCase(),
                size: s,
              )).toList(),
            ),
          ),
          const Section(
            title: 'Badge with Icon',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenBadge(label: 'Active', icon: Icons.circle, variant: EdenBadgeVariant.success, size: EdenBadgeSize.sm),
                EdenBadge(label: 'Pending', icon: Icons.schedule, variant: EdenBadgeVariant.warning),
                EdenBadge(label: 'Error', icon: Icons.error_outline, variant: EdenBadgeVariant.danger),
              ],
            ),
          ),
          const EdenDivider(label: 'Alerts'),
          Section(
            title: 'Alert Variants',
            child: Column(
              children: EdenAlertVariant.values.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EdenAlert(
                  title: '${v.name[0].toUpperCase()}${v.name.substring(1)} Alert',
                  message: 'This is a ${v.name} alert message with relevant details.',
                  variant: v,
                ),
              )).toList(),
            ),
          ),
          Section(
            title: 'Dismissible Alert',
            child: EdenAlert(
              title: 'Dismissible',
              message: 'This alert can be dismissed.',
              variant: EdenAlertVariant.info,
              dismissible: true,
              onDismiss: () {},
            ),
          ),

          const EdenDivider(label: 'Wave A — Membership Tier Badge'),
          Section(
            title: 'Preset Tiers',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EdenMembershipTier.values
                  .map((t) => EdenMembershipTierBadge(tier: t))
                  .toList(),
            ),
          ),
          const Section(
            title: 'Custom Tiers (salon / retail / legal / gov)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenMembershipTierBadge.custom(
                  label: 'Elite',
                  backgroundColor: Color(0xFFEC4899),
                  foregroundColor: Color(0xFFFFFFFF),
                ),
                EdenMembershipTierBadge.custom(
                  label: 'TS-SCI',
                  backgroundColor: Color(0xFF7F1D1D),
                  foregroundColor: Color(0xFFFFFFFF),
                  icon: Icons.security,
                ),
                EdenMembershipTierBadge.custom(
                  label: 'Lapsed',
                  backgroundColor: Color(0xFFE5E7EB),
                  foregroundColor: Color(0xFF374151),
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenUrgencyBadge — Phase 1 (objective 003)'),
          const Section(
            title: 'Known urgency levels',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenUrgencyBadge(urgency: 'low'),
                EdenUrgencyBadge(urgency: 'medium'),
                EdenUrgencyBadge(urgency: 'high'),
                EdenUrgencyBadge(urgency: 'critical'),
              ],
            ),
          ),
          const Section(
            title: 'Unknown urgency fallback',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenUrgencyBadge(urgency: 'urgent_af'),
                EdenUrgencyBadge(urgency: 'p0'),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenPipelineBadge — Phase 1 (objective 003)'),
          const Section(
            title: 'Known pipeline stages',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenPipelineBadge(stage: 'draft'),
                EdenPipelineBadge(stage: 'sent'),
                EdenPipelineBadge(stage: 'won'),
                EdenPipelineBadge(stage: 'lost'),
                EdenPipelineBadge(stage: 'expired'),
              ],
            ),
          ),
          const Section(
            title: 'Aliases + unknown fallback',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenPipelineBadge(stage: 'accepted'),
                EdenPipelineBadge(stage: 'rejected'),
                EdenPipelineBadge(stage: 'invented_stage'),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenApprovalStatusBadge — Phase 1 (objective 003)'),
          const Section(
            title: 'Known approval statuses (10 + 1 alias)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenApprovalStatusBadge(status: 'pending'),
                EdenApprovalStatusBadge(status: 'pending_approval'),
                EdenApprovalStatusBadge(status: 'approved'),
                EdenApprovalStatusBadge(status: 'rejected'),
                EdenApprovalStatusBadge(status: 'draft'),
                EdenApprovalStatusBadge(status: 'ordered'),
                EdenApprovalStatusBadge(status: 'received'),
                EdenApprovalStatusBadge(status: 'in_transit'),
                EdenApprovalStatusBadge(status: 'completed'),
                EdenApprovalStatusBadge(status: 'fulfilled'),
                EdenApprovalStatusBadge(status: 'cancelled'),
              ],
            ),
          ),
          const Section(
            title: 'Unknown / case-mismatch (default-branch fallback)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenApprovalStatusBadge(status: 'in_review'),
                EdenApprovalStatusBadge(status: 'awaiting'),
                EdenApprovalStatusBadge(status: 'Approved'),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenBlockingAlerts — Phase 1 (objective 003)'),
          Section(
            title: 'Mixed list (1 red + 1 amber → red tint)',
            child: EdenBlockingAlerts(alerts: [
              EdenBlockingAlertData(
                task: 'Install HVAC',
                context: 'Phase 2',
                reason: 'Waiting on permit approval',
                actions: [
                  EdenBlockingAction(label: 'View Permit', onPressed: () {}),
                  EdenBlockingAction(label: 'Notify Inspector', onPressed: () {}),
                ],
              ),
              const EdenBlockingAlertData(
                task: 'Pour foundation',
                context: 'Phase 1',
                reason: 'Awaiting inspection',
                severity: EdenBlockingSeverity.amber,
              ),
            ]),
          ),
          const Section(
            title: 'Single-alert (no chevron)',
            child: EdenBlockingAlerts(alerts: [
              EdenBlockingAlertData(
                task: 'Inspect roof',
                context: 'Permit review',
                reason: 'Survey not received',
                severity: EdenBlockingSeverity.amber,
              ),
            ]),
          ),

          // ----------------------------------------------------------------
          // Objective 008 Wave 4 (TRD 008-07) — cross-vertical realistic
          // contexts. Variant enumerations above remain as quick-reference;
          // these sections show each badge family attached to realistic
          // operational data from lib/dev_app/_sample_data/.
          // ----------------------------------------------------------------
          const EdenDivider(
            label: 'Cross-vertical realistic contexts — Obj 008',
          ),
          const Section(
            title: 'EdenUrgencyBadge — realistic urgency contexts',
            child: _CrossVerticalUrgencyDemo(),
          ),
          const Section(
            title: 'EdenPipelineBadge — pipeline stages by vertical',
            child: _CrossVerticalPipelineDemo(),
          ),
          const Section(
            title: 'EdenApprovalStatusBadge — realistic approval scenarios',
            child: _CrossVerticalApprovalDemo(),
          ),
          const Section(
            title: 'EdenMembershipTierBadge — real customers + custom tiers',
            child: _CrossVerticalMembershipDemo(),
          ),
          const Section(
            title: 'EdenBlockingAlerts — Trades fixtures',
            child: EdenBlockingAlerts(
              alerts: TradesScenarios.blockingAlerts,
            ),
          ),
          const Section(
            title: 'EdenBlockingAlerts — Salon fixtures',
            child: EdenBlockingAlerts(
              alerts: SalonScenarios.blockingAlerts,
            ),
          ),
          const Section(
            title: 'EdenBlockingAlerts — Medical fixtures',
            child: EdenBlockingAlerts(
              alerts: MedicalScenarios.blockingAlerts,
            ),
          ),
          const Section(
            title: 'EdenBlockingAlerts — Gov fixtures',
            child: EdenBlockingAlerts(
              alerts: GovScenarios.blockingAlerts,
            ),
          ),
          const Section(
            title: 'Edge — Long-text badge wrapping at narrow viewport',
            child: _LongTextBadgeWrapDemo(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Objective 008 Wave 4 (TRD 008-07) — cross-vertical context demos.
// Demo-only; no library widget changes.
// =============================================================================

class _CrossVerticalUrgencyDemo extends StatelessWidget {
  const _CrossVerticalUrgencyDemo();
  @override
  Widget build(BuildContext context) {
    const rows = <(String, String, String)>[
      (
        'Trades',
        'AC out · 1 child + 1 elderly in home · Atlanta heat advisory',
        'critical',
      ),
      (
        'Trades',
        'Routine HVAC tune-up · scheduled next month',
        'low',
      ),
      (
        'Salon',
        'Bridal updo · ceremony in 3h · cannot reschedule',
        'high',
      ),
      (
        'Medical',
        'Walk-in triage · chest pain · 67yo male',
        'critical',
      ),
      (
        'Medical',
        'Routine 6-week post-op follow-up',
        'low',
      ),
      (
        'Fuel',
        'Terminal tank at 8% · industrial customer · winter',
        'critical',
      ),
      (
        'Gov',
        'SLA breach · case 12d past 10-day target window',
        'high',
      ),
      (
        'Gov',
        'Routine quarterly compliance review',
        'low',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final r in rows) _ContextRow(vertical: r.$1, label: r.$2, badge: EdenUrgencyBadge(urgency: r.$3)),
      ],
    );
  }
}

class _CrossVerticalPipelineDemo extends StatelessWidget {
  const _CrossVerticalPipelineDemo();
  @override
  Widget build(BuildContext context) {
    const rows = <(String, String, String)>[
      ('Trades', 'Whitfield HVAC install estimate', 'draft'),
      ('Trades', 'Bartholomew ranch panel upgrade', 'sent'),
      ('Trades', 'Pierre furnace tune-up', 'won'),
      ('Trades', 'Smith roof inspection', 'lost'),
      ('Fuel', 'Northpoint annual contract', 'accepted'),
      ('Fuel', 'Sauk Trail outpost · new account', 'sent'),
      ('Gov', 'Vendor RFP · radio replacement', 'rejected'),
      ('Gov', 'Pending board approval · CCM-0427', 'expired'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final r in rows) _ContextRow(vertical: r.$1, label: r.$2, badge: EdenPipelineBadge(stage: r.$3)),
      ],
    );
  }
}

class _CrossVerticalApprovalDemo extends StatelessWidget {
  const _CrossVerticalApprovalDemo();
  @override
  Widget build(BuildContext context) {
    const rows = <(String, String, String)>[
      ('Trades', 'Change order #CO-1142 · +\$1,840 labor', 'pending_approval'),
      ('Trades', 'Permit fee passthrough · #M-2026-04419', 'approved'),
      ('Trades', 'Overtime request · Bob · Saturday callout', 'rejected'),
      ('Salon', 'Refund · \$92 · color did not take', 'pending'),
      ('Medical', 'Lab order · A1C + CMP · MRN 44291', 'approved'),
      ('Medical', 'Imaging request · chest x-ray', 'in_transit'),
      ('Gov', 'Clearance renewal · Avery Kim · Tier 2', 'pending_approval'),
      ('Gov', 'Case escalation · CCM-2026-0427 → Tier 3', 'approved'),
      ('Fuel', 'Truck T7 maintenance PO', 'completed'),
      ('Fuel', 'Driver schedule adjustment · Tomás week 2', 'cancelled'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final r in rows)
          _ContextRow(
            vertical: r.$1,
            label: r.$2,
            badge: EdenApprovalStatusBadge(status: r.$3),
          ),
      ],
    );
  }
}

class _CrossVerticalMembershipDemo extends StatelessWidget {
  const _CrossVerticalMembershipDemo();
  @override
  Widget build(BuildContext context) {
    final tieredCustomers =
        CrossCuttingFixtures.customers.where((c) => c.tier != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Real customers from CrossCuttingFixtures (tier-tagged):',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final c in tieredCustomers)
          _ContextRow(
            vertical: c.vertical ?? '—',
            label: c.name,
            badge: EdenMembershipTierBadge(tier: c.tier!),
          ),
        const SizedBox(height: 12),
        const Text(
          'Custom-tier escape hatch (per-vertical bespoke tiers):',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _ContextRow(
          vertical: 'Trades',
          label: 'Premier service contract (24/7)',
          badge: EdenMembershipTierBadge.custom(
            label: 'PREMIER',
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const _ContextRow(
          vertical: 'Salon',
          label: 'Founder Club · lifetime member',
          badge: EdenMembershipTierBadge.custom(
            label: 'FOUNDER',
            backgroundColor: Color(0xFFFCE7F3),
            foregroundColor: Color(0xFFDB2777),
          ),
        ),
        const _ContextRow(
          vertical: 'Medical',
          label: 'Concierge tier · same-day access',
          badge: EdenMembershipTierBadge.custom(
            label: 'CONCIERGE',
            backgroundColor: Color(0xFFCFFAFE),
            foregroundColor: Color(0xFF0E7490),
          ),
        ),
        const _ContextRow(
          vertical: 'Gov',
          label: 'TS-SCI clearance · compartment-aware routing',
          badge: EdenMembershipTierBadge.custom(
            label: 'TS-SCI',
            backgroundColor: Color(0xFFE2E8F0),
            foregroundColor: Color(0xFF334155),
          ),
        ),
        const _ContextRow(
          vertical: 'Fuel',
          label: 'Bulk-fleet contract · NET-30',
          badge: EdenMembershipTierBadge.custom(
            label: 'BULK',
            backgroundColor: Color(0xFFD1FAE5),
            foregroundColor: Color(0xFF15803D),
          ),
        ),
      ],
    );
  }
}

class _LongTextBadgeWrapDemo extends StatelessWidget {
  const _LongTextBadgeWrapDemo();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const <Widget>[
              EdenUrgencyBadge(
                urgency: 'EXTREMELY-LONG-CUSTOM-LEVEL-XYZ',
              ),
              EdenPipelineBadge(stage: 'awaiting-vendor-counter-signature'),
              EdenApprovalStatusBadge(
                status: 'pending_co_signature_from_provider',
              ),
              EdenMembershipTierBadge.custom(
                label: 'VERY-LONG-CUSTOM-TIER-LABEL',
                backgroundColor: Color(0xFFFEE2E2),
                foregroundColor: Color(0xFF7C2D12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared row used by all cross-vertical context demos: vertical prefix
/// (monospace, 70pt) + label (Expanded) + the badge widget on the right.
class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.vertical,
    required this.label,
    required this.badge,
  });

  final String vertical;
  final String label;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 60,
            child: Text(
              vertical,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          badge,
        ],
      ),
    );
  }
}
