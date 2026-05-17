import 'dart:async';

import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
import '../widgets/section.dart';

class MiscScreen extends StatefulWidget {
  const MiscScreen({super.key});

  @override
  State<MiscScreen> createState() => _MiscScreenState();
}

class _MiscScreenState extends State<MiscScreen> {
  EdenNetworkStatus _networkStatus = EdenNetworkStatus.offline;
  EdenAiPersona _persona = EdenAiPersona.operations;
  bool _slotEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Misc')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          // Network Status Bar (Wave A — Cross-vertical primitive)
          Section(
            title: 'Network Status Bar (Wave A)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EdenNetworkStatusBar(
                  status: _networkStatus,
                  attemptCount:
                      _networkStatus == EdenNetworkStatus.reconnecting ? 2 : null,
                  retryButton: _networkStatus == EdenNetworkStatus.offline,
                  onRetry: () =>
                      setState(() => _networkStatus = EdenNetworkStatus.reconnecting),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: EdenNetworkStatus.values.map((s) {
                    return ChoiceChip(
                      label: Text(s.name),
                      selected: _networkStatus == s,
                      onSelected: (_) => setState(() => _networkStatus = s),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Section(
            title: 'Progress Bars',
            child: Column(
              children: [
                EdenProgress(value: 0.25, label: 'Upload', showPercentage: true),
                SizedBox(height: 16),
                EdenProgress(value: 0.6, size: EdenProgressSize.sm, color: EdenColors.success),
                SizedBox(height: 16),
                EdenProgress(value: 0.85, size: EdenProgressSize.lg, color: EdenColors.warning, showPercentage: true),
              ],
            ),
          ),
          Section(
            title: 'Spinners',
            child: Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: EdenSpinnerSize.values.map((s) => EdenSpinner(size: s)).toList(),
            ),
          ),
          const Section(
            title: 'Skeletons',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EdenSkeleton.circle(size: 40),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EdenSkeleton.text(width: 160),
                          SizedBox(height: 8),
                          EdenSkeleton.text(width: 100),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                EdenSkeleton.block(height: 100),
              ],
            ),
          ),
          const Section(
            title: 'Dividers',
            child: Column(
              children: [
                EdenDivider(),
                SizedBox(height: 8),
                EdenDivider(label: 'OR'),
                SizedBox(height: 8),
                EdenDivider(label: 'Section Break'),
              ],
            ),
          ),
          Section(
            title: 'Tooltip',
            child: Row(
              children: [
                EdenTooltip(
                  message: 'This is a tooltip!',
                  child: EdenButton(
                    label: 'Hover Me',
                    variant: EdenButtonVariant.secondary,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenPersonaSelector — Phase 1 (objective 003)'),
          Section(
            title: 'Live persona selector — Riverpod-free, callback-driven',
            child: Row(
              children: [
                EdenPersonaSelector(
                  activePersona: _persona,
                  onChanged: (p) => setState(() => _persona = p),
                ),
                const SizedBox(width: 12),
                Text('Active: ${_persona.displayLabel}'),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenAiInsightSlot — Phase 1 (objective 003)'),
          Section(
            title: 'Gated AI panel slot (enabled / disabled toggle)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EdenButton(
                      label: _slotEnabled ? 'Disable slot' : 'Enable slot',
                      variant: EdenButtonVariant.secondary,
                      onPressed: () =>
                          setState(() => _slotEnabled = !_slotEnabled),
                    ),
                    const SizedBox(width: 8),
                    Text('enabled: $_slotEnabled'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 280,
                  width: 320,
                  child: EdenAiInsightSlot(
                    enabled: _slotEnabled,
                    insights: const [
                      EdenInsightContent(
                        id: 's',
                        type: EdenInsightType.summary,
                        title: 'Project Update',
                        subtitle: '3 tasks remaining',
                      ),
                      EdenInsightContent(
                        id: 'a',
                        type: EdenInsightType.alert,
                        title: 'Permit expiring',
                        severity: EdenInsightSeverity.warning,
                      ),
                    ],
                    persona: EdenAiPersona.operations,
                  ),
                ),
              ],
            ),
          ),

          const EdenDivider(label: 'EdenAiCollapsibleSection — Phase 1 (objective 003)'),
          const Section(
            title: 'Default (expanded) / defaultExpanded=false / custom icon',
            child: Column(
              children: [
                EdenAiCollapsibleSection(
                  title: 'Default expanded section',
                  child: Text('Hello insights — body of the section.'),
                ),
                EdenAiCollapsibleSection(
                  title: 'Starts collapsed',
                  defaultExpanded: false,
                  child: Text('You only see this after tapping the header.'),
                ),
                EdenAiCollapsibleSection(
                  title: 'Custom icon (insights)',
                  icon: Icons.insights,
                  child: Text('Executive-tier KPIs.'),
                ),
                EdenAiCollapsibleSection(
                  title:
                      'A very long section title that should ellipsize gracefully on narrow viewports — 60 chars',
                  child: Text('Body with long-title parent.'),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // Objective 008 Wave 2 (TRD 008-04) — cross-vertical misc demos.
          // -----------------------------------------------------------------
          const EdenDivider(label: 'Network lifecycle simulator'),
          const Section(
            title: 'Auto-cycle: online → reconnecting → offline → reconnecting → online',
            child: _NetworkLifecycleDemo(),
          ),

          const EdenDivider(label: 'EdenOfflineQueueViewer — cross-vertical'),
          const Section(
            title: 'Realistic queued mutations (5 items, mixed verticals)',
            child: _OfflineQueueDemo(),
          ),
          const Section(
            title: 'Edge — Conflict-heavy queue',
            child: _OfflineQueueConflictDemo(),
          ),
          const Section(
            title: 'Edge — Empty queue',
            child: SizedBox(
              height: 120,
              child: EdenOfflineQueueViewer(items: <EdenOfflineQueueItem>[]),
            ),
          ),

          const EdenDivider(label: 'EdenAuthenticatedImage — headers + async builder'),
          const Section(
            title: 'Static headers map (404 fallback)',
            child: EdenAuthenticatedImage(
              url: 'https://images.example.invalid/avatar.png',
              headers: <String, String>{
                'Authorization': 'Bearer demo-token',
              },
              width: 80,
              height: 80,
            ),
          ),
          Section(
            title: 'Async headersBuilder (500ms delay)',
            child: EdenAuthenticatedImage(
              url: 'https://images.example.invalid/signed-photo.jpg',
              headersBuilder: () async {
                await Future<void>.delayed(const Duration(milliseconds: 500));
                return const <String, String>{
                  'Authorization': 'Bearer late-loaded',
                };
              },
              width: 200,
              height: 120,
            ),
          ),
          const Section(
            title: 'Error fallback (no headers, invalid URL)',
            child: EdenAuthenticatedImage(
              url: 'https://images.example.invalid/missing.jpg',
              width: 200,
              height: 120,
            ),
          ),

          const EdenDivider(label: 'EdenPlaceholderPage — Phase 1 (objective 003)'),
          Section(
            title: 'EdenPlaceholderPage preview (tap to open)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EdenButton(
                  label: 'Open default (Coming soon)',
                  variant: EdenButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).push<void>(MaterialPageRoute(
                      builder: (_) => const EdenPlaceholderPage(
                        title: 'Reports',
                        icon: Icons.bar_chart,
                      ),
                    ));
                  },
                ),
                EdenButton(
                  label: 'Open with action',
                  variant: EdenButtonVariant.secondary,
                  onPressed: () {
                    Navigator.of(context).push<void>(MaterialPageRoute(
                      builder: (ctx) => EdenPlaceholderPage(
                        title: 'Agent Builder',
                        icon: Icons.smart_toy_outlined,
                        subtitle: 'Migration in progress',
                        actionLabel: 'Notify me when ready',
                        onAction: () => Navigator.of(ctx).pop(),
                      ),
                    ));
                  },
                ),
              ],
            ),
          ),
          const EdenDivider(label: 'EdenSkeletonScope — skeleton-to-content morph (Obj 010)'),
          const Section(
            title: 'Single-card morph + list morph',
            child: _SkeletonScopeDemos(),
          ),
          const EdenDivider(label: 'EdenEmptyState — enhanced (Obj 010)'),
          const Section(
            title: 'Illustration + primary + secondary actions',
            child: _EmptyStateDemos(),
          ),
          const EdenDivider(label: 'EdenStatusDotOverlay (Obj 010)'),
          const Section(
            title: 'Composable status dot / unread count badge',
            child: _StatusDotOverlayDemos(),
          ),
        ],
      ),
    );
  }
}

class _StatusDotOverlayDemos extends StatelessWidget {
  const _StatusDotOverlayDemos();

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Avatar with online status'),
        const SizedBox(height: EdenSpacing.space2),
        const EdenStatusDotOverlay(
          kind: EdenStatusDotKind.online,
          child: EdenAvatar(initials: 'MK', size: EdenAvatarSize.lg),
        ),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Button with unread count badge (tap fires snack — confirms pass-through)'),
        const SizedBox(height: EdenSpacing.space2),
        EdenStatusDotOverlay(
          kind: EdenStatusDotKind.unread,
          count: 12,
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _snack(context, 'notifications'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Card with sync indicator'),
        const SizedBox(height: EdenSpacing.space2),
        EdenStatusDotOverlay(
          kind: EdenStatusDotKind.sync,
          child: SizedBox(
            width: 240,
            height: 80,
            child: EdenCard.interactive(
              title: 'Syncing...',
              subtitle: '5 items pending',
              onTap: () => _snack(context, 'sync details'),
            ),
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Icons with all alignments (topLeft / topRight / bottomLeft / bottomRight)'),
        const SizedBox(height: EdenSpacing.space2),
        const Row(children: [
          EdenStatusDotOverlay(
            kind: EdenStatusDotKind.offline,
            alignment: Alignment.topLeft,
            child: SizedBox(width: 48, height: 48, child: Icon(Icons.email_outlined, size: 32)),
          ),
          SizedBox(width: 16),
          EdenStatusDotOverlay(
            kind: EdenStatusDotKind.offline,
            alignment: Alignment.topRight,
            child: SizedBox(width: 48, height: 48, child: Icon(Icons.email_outlined, size: 32)),
          ),
          SizedBox(width: 16),
          EdenStatusDotOverlay(
            kind: EdenStatusDotKind.offline,
            alignment: Alignment.bottomLeft,
            child: SizedBox(width: 48, height: 48, child: Icon(Icons.email_outlined, size: 32)),
          ),
          SizedBox(width: 16),
          EdenStatusDotOverlay(
            kind: EdenStatusDotKind.offline,
            alignment: Alignment.bottomRight,
            child: SizedBox(width: 48, height: 48, child: Icon(Icons.email_outlined, size: 32)),
          ),
        ]),
      ],
    );
  }
}

class _EmptyStateDemos extends StatelessWidget {
  const _EmptyStateDemos();

  void _snack(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Illustration variant'),
        const SizedBox(height: EdenSpacing.space2),
        Card(child: EdenEmptyState(
          title: 'No appointments today',
          description: 'Schedule a new booking to fill your calendar.',
          illustration: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_outlined,
                size: 64, color: theme.colorScheme.primary),
          ),
          actionLabel: 'New booking',
          onAction: () => _snack(context, 'New booking'),
        )),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Primary + secondary actions'),
        const SizedBox(height: EdenSpacing.space2),
        Card(child: EdenEmptyState(
          title: 'Sync failed',
          description: 'Could not reach the server.',
          icon: Icons.cloud_off_outlined,
          actionLabel: 'Try again',
          onAction: () => _snack(context, 'Retry'),
          secondaryActionLabel: 'Work offline',
          onSecondaryAction: () => _snack(context, 'Offline mode'),
        )),
        const SizedBox(height: EdenSpacing.space4),
        const Text('Full combo (illustration + 2 actions + responsive)'),
        const SizedBox(height: EdenSpacing.space2),
        Card(child: EdenEmptyState(
          title: 'No work orders assigned',
          description:
              'New jobs will appear here when dispatched by the office.',
          illustration: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.work_outline,
                size: 48, color: theme.colorScheme.secondary),
          ),
          actionLabel: 'Refresh',
          onAction: () => _snack(context, 'Refreshed'),
          secondaryActionLabel: 'View past jobs',
          onSecondaryAction: () => _snack(context, 'Past jobs'),
        )),
      ],
    );
  }
}

class _SkeletonScopeDemos extends StatefulWidget {
  const _SkeletonScopeDemos();

  @override
  State<_SkeletonScopeDemos> createState() => _SkeletonScopeDemosState();
}

class _SkeletonScopeDemosState extends State<_SkeletonScopeDemos> {
  bool _isLoading = true;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Switch(value: _isLoading, onChanged: (v) => setState(() => _isLoading = v)),
          const SizedBox(width: 8),
          const Text('Show as loading skeleton'),
        ]),
        const SizedBox(height: EdenSpacing.space3),
        const Text('Single-card morph'),
        const SizedBox(height: EdenSpacing.space2),
        EdenSkeletonScope(
          isLoading: _isLoading,
          skeleton: const EdenCard(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EdenSkeleton.text(width: 180),
              SizedBox(height: 8),
              EdenSkeleton.text(width: 240),
              SizedBox(height: 8),
              EdenSkeleton.text(width: 120),
            ],
          )),
          content: EdenCard.interactive(
            title: 'Loaded card',
            subtitle: 'Cross-faded from skeleton',
            onTap: () => _snack('Tap'),
          ),
        ),
        const SizedBox(height: EdenSpacing.space4),
        const Text('List morph (3 items)'),
        const SizedBox(height: EdenSpacing.space2),
        EdenSkeletonScope(
          isLoading: _isLoading,
          skeleton: const Column(children: [
            EdenSkeleton.block(width: double.infinity, height: 64),
            SizedBox(height: 8),
            EdenSkeleton.block(width: double.infinity, height: 64),
            SizedBox(height: 8),
            EdenSkeleton.block(width: double.infinity, height: 64),
          ]),
          content: Column(children: [
            EdenCard.interactive(title: 'Item 1', subtitle: 'real card', onTap: () => _snack('1')),
            const SizedBox(height: 8),
            EdenCard.interactive(title: 'Item 2', subtitle: 'real card', onTap: () => _snack('2')),
            const SizedBox(height: 8),
            EdenCard.interactive(title: 'Item 3', subtitle: 'real card', onTap: () => _snack('3')),
          ]),
        ),
      ],
    );
  }
}

// =============================================================================
// Objective 008 Wave 2 (TRD 008-04) demo widgets — misc surfaces.
// =============================================================================

/// Auto-cycle network status simulator. Defaults to OFF (no timer running)
/// so widget tests don't leak; user taps "Start" to begin.
class _NetworkLifecycleDemo extends StatefulWidget {
  const _NetworkLifecycleDemo();

  @override
  State<_NetworkLifecycleDemo> createState() => _NetworkLifecycleDemoState();
}

class _NetworkLifecycleDemoState extends State<_NetworkLifecycleDemo> {
  static const List<EdenNetworkStatus> _cycle = <EdenNetworkStatus>[
    EdenNetworkStatus.online,
    EdenNetworkStatus.reconnecting,
    EdenNetworkStatus.offline,
    EdenNetworkStatus.reconnecting,
    EdenNetworkStatus.syncing,
  ];

  EdenNetworkStatus _status = EdenNetworkStatus.online;
  int _idx = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _idx = (_idx + 1) % _cycle.length;
        _status = _cycle[_idx];
      });
    });
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final running = _timer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        EdenNetworkStatusBar(
          status: _status,
          attemptCount: _status == EdenNetworkStatus.reconnecting ? 2 : null,
        ),
        const SizedBox(height: EdenSpacing.space3),
        Row(
          children: <Widget>[
            EdenButton(
              label: running ? 'Stop' : 'Start auto-cycle',
              variant: EdenButtonVariant.secondary,
              onPressed: running ? _stop : _start,
            ),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              'Current: ${_status.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

/// Hand-built realistic queue with mixed-vertical mutations.
class _OfflineQueueDemo extends StatelessWidget {
  const _OfflineQueueDemo();

  @override
  Widget build(BuildContext context) {
    final today = CrossCuttingFixtures.catalogToday;
    final items = <EdenOfflineQueueItem>[
      EdenOfflineQueueItem(
        id: 'q-trades-001',
        actionType: 'Upload Photos',
        summary: 'Trades · Whitfield install · 3 photos',
        queuedAt: today.subtract(const Duration(minutes: 4)),
        status: EdenOfflineQueueItemStatus.syncing,
        payloadPreview: '{"jobId":"tr-evt-001","count":3}',
      ),
      EdenOfflineQueueItem(
        id: 'q-salon-002',
        actionType: 'Checkout',
        summary: r'Salon · A. Okonkwo-Reyes balayage · $385',
        queuedAt: today.subtract(const Duration(minutes: 12)),
      ),
      EdenOfflineQueueItem(
        id: 'q-medical-003',
        actionType: 'Upload Labs',
        summary: 'Medical · MRN 44291 · A1C result',
        queuedAt: today.subtract(const Duration(minutes: 38)),
        status: EdenOfflineQueueItemStatus.error,
        errorMessage: 'Cellular connection dropped before upload completed.',
      ),
      EdenOfflineQueueItem(
        id: 'q-gov-004',
        actionType: 'Submit Form',
        summary: 'Gov · Case CCM-2026-0427 · Tier-2 attestation',
        queuedAt: today.subtract(const Duration(hours: 1, minutes: 20)),
      ),
      EdenOfflineQueueItem(
        id: 'q-fuel-005',
        actionType: 'Confirm Delivery',
        summary: 'Fuel · Northpoint Diesel · 1,800 gal · Truck T7',
        queuedAt: today.subtract(const Duration(hours: 2, minutes: 8)),
        status: EdenOfflineQueueItemStatus.conflict,
        conflictDescription:
            'Server-side tank reading conflicts with submitted gallons total.',
      ),
    ];
    return SizedBox(
      height: 560,
      child: EdenOfflineQueueViewer(
        items: items,
        now: today,
        onRetry: (_) {},
        onDiscard: (_) {},
        onResolveConflict: (_) {},
      ),
    );
  }
}

class _OfflineQueueConflictDemo extends StatelessWidget {
  const _OfflineQueueConflictDemo();

  @override
  Widget build(BuildContext context) {
    final today = CrossCuttingFixtures.catalogToday;
    final items = <EdenOfflineQueueItem>[
      EdenOfflineQueueItem(
        id: 'qc-1',
        actionType: 'Update Customer',
        summary: 'Trades · Bartholomew · phone changed',
        queuedAt: today.subtract(const Duration(minutes: 8)),
        status: EdenOfflineQueueItemStatus.conflict,
        conflictDescription: 'Server has newer record (updated 4 min after queue).',
      ),
      EdenOfflineQueueItem(
        id: 'qc-2',
        actionType: 'Update Stylist Schedule',
        summary: 'Salon · Marisol · double-booked 2pm',
        queuedAt: today.subtract(const Duration(minutes: 30)),
        status: EdenOfflineQueueItemStatus.conflict,
        conflictDescription: 'Slot already taken by walk-in.',
      ),
      EdenOfflineQueueItem(
        id: 'qc-3',
        actionType: 'Adjust Tank Reading',
        summary: 'Fuel · Terminal 4 · Tank 3 (87 → 22%)',
        queuedAt: today.subtract(const Duration(hours: 1)),
        status: EdenOfflineQueueItemStatus.conflict,
        conflictDescription:
            'Another driver reported 78% — manual reconciliation needed.',
      ),
    ];
    return SizedBox(
      height: 460,
      child: EdenOfflineQueueViewer(
        items: items,
        now: today,
        onResolveConflict: (_) {},
        onDiscard: (_) {},
        onRetry: (_) {},
      ),
    );
  }
}
