import 'package:flutter/material.dart';

import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Dev-catalog Scheduler screen — home for all Objective 004 demos. Wave 1
/// renders a baseline `EdenScheduler` driven by an `EdenSchedulerController`.
/// Subsequent waves append demo sections for day/week/workWeek/month/list/
/// mobile/swimlane variants, drag-to-reschedule, conflict highlighting, and
/// mini-sidebar features.
class SchedulerScreen extends StatefulWidget {
  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  late final EdenSchedulerController _controller;

  late final List<EdenSchedulerEvent> _events = [
    EdenSchedulerEvent(
      id: 'demo-1',
      title: 'Service call — Atlanta',
      start: DateTime(2026, 3, 9, 9, 0),
      end: DateTime(2026, 3, 9, 10, 30),
      color: const Color(0xFF3B82F6),
      assignee: 'Truck 47',
      status: 'scheduled',
      type: 'service',
    ),
    EdenSchedulerEvent(
      id: 'demo-2',
      title: 'Maintenance — Truck 12',
      start: DateTime(2026, 3, 10, 13, 0),
      end: DateTime(2026, 3, 10, 15, 0),
      color: const Color(0xFFF59E0B),
      assignee: 'Truck 12',
      status: 'in_progress',
      type: 'maintenance',
    ),
    EdenSchedulerEvent(
      id: 'demo-3',
      title: 'Installation — Buckhead',
      start: DateTime(2026, 3, 11, 9, 0),
      end: DateTime(2026, 3, 11, 12, 0),
      color: const Color(0xFF10B981),
      assignee: 'Truck 47',
      status: 'scheduled',
      type: 'project',
    ),
    EdenSchedulerEvent(
      id: 'demo-conflict-1',
      title: 'Overlap — first',
      start: DateTime(2026, 3, 11, 14, 0),
      end: DateTime(2026, 3, 11, 15, 30),
      color: const Color(0xFFEF4444),
      assignee: 'Truck 47',
    ),
    EdenSchedulerEvent(
      id: 'demo-conflict-2',
      title: 'Overlap — second',
      start: DateTime(2026, 3, 11, 14, 30),
      end: DateTime(2026, 3, 11, 16, 0),
      color: const Color(0xFF8B5CF6),
      assignee: 'Truck 47',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = EdenSchedulerController(
      initialView: EdenSchedulerView.week,
      initialDate: DateTime(2026, 3, 9),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EdenScheduler — Objective 004')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          Section(
            title: 'Wave 1 — Foundation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EdenSchedulerController (extracted state) + 7-variant '
                  'ViewToggle (month/week/workWeek/day/list/mobile/swimlane) '
                  '+ responsive collapse to icon-only below 1100pt + '
                  'narrow-mode below 480pt.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: EdenSpacing.space3),
                SizedBox(
                  height: 600,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return EdenScheduler(
                        controller: _controller,
                        events: _events,
                        assignees: const ['Truck 47', 'Truck 12'],
                        selectedAssignees: const {},
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
        ],
      ),
    );
  }
}
