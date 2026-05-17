import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

/// Motion catalog (objective 010 — Visual Polish Pass).
///
/// Sections:
/// - M3 Expressive — FAB Menu (TRD 010-04)
/// - M3 Expressive — Loading Indicator (TRD 010-05 — appended)
class MotionScreen extends StatelessWidget {
  const MotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Motion (Obj 010)')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: const [
          Section(
            title: 'M3 Expressive — FAB Menu',
            child: _FabMenuDemos(),
          ),
          // TRD 010-05 will append Loading Indicator demos below this section.
        ],
      ),
    );
  }
}

class _FabMenuDemos extends StatelessWidget {
  const _FabMenuDemos();

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
        const Text('3 actions — trades dispatch quick actions'),
        const SizedBox(height: EdenSpacing.space2),
        Card(child: SizedBox(
          height: 360,
          child: Stack(children: [
            const Center(child: Text('Open the FAB ↘')),
            EdenFabMenu(
              primaryIcon: Icons.add,
              heroTag: 'motion_demo_3',
              actions: [
                EdenFabAction(
                  icon: Icons.work_outline,
                  label: 'New Job',
                  onPressed: () => _snack(context, 'New Job'),
                ),
                EdenFabAction(
                  icon: Icons.assignment_outlined,
                  label: 'New Estimate',
                  onPressed: () => _snack(context, 'New Estimate'),
                ),
                EdenFabAction(
                  icon: Icons.access_time,
                  label: 'Clock In',
                  onPressed: () => _snack(context, 'Clock In'),
                ),
              ],
            ),
          ]),
        )),
        const SizedBox(height: EdenSpacing.space4),
        const Text('6 actions — salon owner quick actions (overflow test)'),
        const SizedBox(height: EdenSpacing.space2),
        Card(child: SizedBox(
          height: 480,
          child: Stack(children: [
            const Center(child: Text('Open the FAB ↘')),
            EdenFabMenu(
              primaryIcon: Icons.add,
              heroTag: 'motion_demo_6',
              actions: [
                EdenFabAction(icon: Icons.event_available, label: 'New booking', onPressed: () => _snack(context, 'New booking')),
                EdenFabAction(icon: Icons.person_add, label: 'New client', onPressed: () => _snack(context, 'New client')),
                EdenFabAction(icon: Icons.directions_walk, label: 'Walk-in', onPressed: () => _snack(context, 'Walk-in')),
                EdenFabAction(icon: Icons.event_busy, label: 'No-show', onPressed: () => _snack(context, 'No-show')),
                EdenFabAction(icon: Icons.cancel, label: 'Cancellation', onPressed: () => _snack(context, 'Cancellation')),
                EdenFabAction(icon: Icons.schedule_send, label: 'Reschedule', onPressed: () => _snack(context, 'Reschedule')),
              ],
            ),
          ]),
        )),
      ],
    );
  }
}
