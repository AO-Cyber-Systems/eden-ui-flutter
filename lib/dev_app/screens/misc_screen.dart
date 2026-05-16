import 'package:flutter/material.dart';
import '../../eden_ui.dart';
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
        ],
      ),
    );
  }
}
