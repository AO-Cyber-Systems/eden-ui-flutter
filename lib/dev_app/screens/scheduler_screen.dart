// lib/dev_app/screens/scheduler_screen.dart
//
// Objective 008 Wave 5 (TRD 008-09) — HEADLINE scheduler enrichment.
//
// Surfaces:
//   1. Cross-vertical event picker (trades / salon / medical / fuel / gov)
//      driving a single live EdenScheduler.
//   2. Full 7-view-mode driver via the toolbar embedded in EdenScheduler.
//      Trades preset uses TradesScenarios.monthEvents (54 events) — exercises
//      the viewport-culling perf path from objective 004 TRD-16.
//   3. Side-by-side parity rows: trades-react PNG reference (left/top) +
//      live EdenScheduler in matching view-mode (right/bottom). 5 view
//      modes covered (week / day / month / mobile / swimlane).
//
// Asset references live under lib/dev_app/_assets/trades_react_reference/
// (registered in pubspec.yaml). Provenance + attribution in that dir's
// README.md.

import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../_sample_data/sample_data.dart';
import '../widgets/section.dart';

/// Dev-catalog Scheduler screen — Objective 004 + 008 demos.
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  late final EdenSchedulerController _controller;
  String _selectedVertical = 'trades';

  @override
  void initState() {
    super.initState();
    _controller = EdenSchedulerController(
      initialView: EdenSchedulerView.week,
      initialDate: DateTime(2026, 5, 16), // catalog "today"
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<EdenSchedulerEvent> get _events {
    switch (_selectedVertical) {
      case 'salon':
        return SalonScenarios.weekAppointments;
      case 'medical':
        return MedicalScenarios.weekVisits;
      case 'fuel':
        return FuelScenarios.weekDeliveries;
      case 'gov':
        return GovScenarios.weekCases;
      case 'trades':
      default:
        return TradesScenarios.monthEvents; // 54 events — perf demo
    }
  }

  List<String> get _assignees {
    switch (_selectedVertical) {
      case 'salon':
        return const <String>[
          'Marisol Reyes',
          'Devon Park',
          'Tasha Ali',
          'Ava Lindgren',
        ];
      case 'medical':
        return const <String>['Dr. Patel', 'NP Khan', 'Rosa Soto, RN'];
      case 'fuel':
        return const <String>[
          'Manny Tovar',
          "Kris O'Hara",
          'Tomás Aguilera',
        ];
      case 'gov':
        return const <String>[
          'Linnea Sørensen',
          'Avery Kim',
          'Hiroshi Tanaka',
        ];
      case 'trades':
      default:
        return const <String>[
          'Alice Chen',
          'Bob Kowalski',
          'Carlos Mendez',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _events;
    return Scaffold(
      appBar: AppBar(title: const Text('EdenScheduler — Objective 004')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: <Widget>[
          // --------------------------------------------------------------
          // Cross-vertical picker (Obj 008 W5 — TRD 008-09)
          // --------------------------------------------------------------
          Section(
            title: 'Vertical · drives the live scheduler below',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final v in const <String>[
                  'trades',
                  'salon',
                  'medical',
                  'fuel',
                  'gov',
                ])
                  ChoiceChip(
                    label: Text(v),
                    selected: _selectedVertical == v,
                    onSelected: (_) =>
                        setState(() => _selectedVertical = v),
                  ),
              ],
            ),
          ),

          Section(
            title:
                'Live EdenScheduler · ${events.length} events · 7-view toolbar',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'EdenSchedulerController (extracted state) + 7-variant '
                  'ViewToggle (month/week/workWeek/day/list/mobile/swimlane) '
                  '+ responsive collapse to icon-only below 1100pt + '
                  'narrow-mode below 480pt. Vertical picker above swaps the '
                  'event source from _sample_data.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: EdenSpacing.space3),
                SizedBox(
                  height: 720,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return EdenScheduler(
                        controller: _controller,
                        events: events,
                        assignees: _assignees,
                        selectedAssignees: const <String>{},
                        onEventTap: (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tapped: ${e.title}')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // --------------------------------------------------------------
          // Side-by-side trades-react parity rows (closes obj 004
          // human-verify parity checkpoint inside the catalog).
          // --------------------------------------------------------------
          const EdenDivider(label: 'Side-by-side trades-react parity'),
          _ParityRow(
            label: 'Week view',
            referenceAsset:
                'lib/dev_app/_assets/trades_react_reference/qa-admin-scheduler.png',
            view: EdenSchedulerView.week,
            events: events,
            assignees: _assignees,
          ),
          // --------------------------------------------------------------
          // Live view-mode preview (no parity reference). Only the Week
          // view has a real trades-react reference screenshot
          // (qa-admin-scheduler.png); the previous Day/Month/Mobile/Swimlane
          // rows pointed at unrelated screenshots (Forefront UI, Projects,
          // Customer Detail) and were misleading parity claims. Replaced
          // with live-only previews until real reference assets exist.
          // --------------------------------------------------------------
          const EdenDivider(
            label: 'Live view-mode preview · no parity reference',
          ),
          Section(
            title: 'Day · Month · Mobile · Swimlane',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Only the Week view has a trades-react reference '
                  'screenshot (qa-admin-scheduler.png). The four views below '
                  'are live EdenScheduler instances locked to their '
                  'view-mode — no side-by-side comparison until additional '
                  'reference assets are captured.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: EdenSpacing.space3),
                _LiveViewModePreview(
                  label: 'Day view',
                  view: EdenSchedulerView.day,
                  events: events,
                  assignees: _assignees,
                ),
                const SizedBox(height: EdenSpacing.space4),
                _LiveViewModePreview(
                  label: 'Month view',
                  view: EdenSchedulerView.month,
                  events: events,
                  assignees: _assignees,
                ),
                const SizedBox(height: EdenSpacing.space4),
                _LiveViewModePreview(
                  label: 'Mobile view (forceMobileView=true)',
                  view: EdenSchedulerView.mobile,
                  events: events,
                  assignees: _assignees,
                  forceMobile: true,
                ),
                const SizedBox(height: EdenSpacing.space4),
                _LiveViewModePreview(
                  label: 'Swimlane view',
                  view: EdenSchedulerView.swimlane,
                  events: events,
                  assignees: _assignees,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Parity comparison row: trades-react reference image + live EdenScheduler
/// in matching view mode.
///
/// Stateful so each row owns its own EdenSchedulerController instance (the
/// row's view is locked to [view] regardless of the top-level controller's
/// current view). Disposes cleanly on widget removal.
class _ParityRow extends StatefulWidget {
  const _ParityRow({
    required this.label,
    required this.referenceAsset,
    required this.view,
    required this.events,
    required this.assignees,
  });

  final String label;
  final String referenceAsset;
  final EdenSchedulerView view;
  final List<EdenSchedulerEvent> events;
  final List<String> assignees;

  @override
  State<_ParityRow> createState() => _ParityRowState();
}

class _ParityRowState extends State<_ParityRow> {
  late final EdenSchedulerController _local;

  @override
  void initState() {
    super.initState();
    _local = EdenSchedulerController(
      initialView: widget.view,
      initialDate: DateTime(2026, 5, 16),
    );
  }

  @override
  void dispose() {
    _local.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isCompact = c.maxWidth < 900;
        final referencePane = Container(
          height: 480,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Image.asset(
            widget.referenceAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  '(reference image unavailable in this build)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
        final livePane = SizedBox(
          height: 480,
          child: AnimatedBuilder(
            animation: _local,
            builder: (_, __) {
              return EdenScheduler(
                controller: _local,
                events: widget.events,
                assignees: widget.assignees,
                selectedAssignees: const <String>{},
              );
            },
          ),
        );

        final Widget body;
        if (isCompact) {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'trades-react reference',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              referencePane,
              const SizedBox(height: 12),
              const Text(
                'Live EdenScheduler',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              livePane,
            ],
          );
        } else {
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'trades-react reference',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    referencePane,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Text(
                      'Live EdenScheduler',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    livePane,
                  ],
                ),
              ),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: EdenSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              body,
            ],
          ),
        );
      },
    );
  }
}

/// Live-only view-mode preview — one labeled bounded `EdenScheduler` locked
/// to [view]. Models on [_ParityRow]'s right pane but without the reference
/// image. Owns its own [EdenSchedulerController] and disposes it on widget
/// removal (avoids hot-reload controller leaks).
class _LiveViewModePreview extends StatefulWidget {
  const _LiveViewModePreview({
    required this.label,
    required this.view,
    required this.events,
    required this.assignees,
    this.forceMobile = false,
  });

  final String label;
  final EdenSchedulerView view;
  final List<EdenSchedulerEvent> events;
  final List<String> assignees;
  final bool forceMobile;

  @override
  State<_LiveViewModePreview> createState() => _LiveViewModePreviewState();
}

class _LiveViewModePreviewState extends State<_LiveViewModePreview> {
  late final EdenSchedulerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EdenSchedulerController(
      initialView: widget.view,
      initialDate: DateTime(2026, 5, 16),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 540,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) {
              return EdenScheduler(
                controller: _controller,
                events: widget.events,
                assignees: widget.assignees,
                selectedAssignees: const <String>{},
                forceMobileView: widget.forceMobile,
              );
            },
          ),
        ),
      ],
    );
  }
}
