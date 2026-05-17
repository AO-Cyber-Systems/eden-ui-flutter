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
          Section(
            title: 'M3 Expressive — Loading Indicator',
            child: _LoadingIndicatorDemos(),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicatorDemos extends StatelessWidget {
  const _LoadingIndicatorDemos();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('shapeMorph — 4-dot M3 Expressive loader'),
        const SizedBox(height: EdenSpacing.space2),
        Row(children: [
          const EdenLoadingIndicator.shapeMorph(),
          const SizedBox(width: 16),
          Text('default (48pt, primary)', style: theme.textTheme.bodySmall),
        ]),
        const SizedBox(height: EdenSpacing.space2),
        Row(children: [
          EdenLoadingIndicator.shapeMorph(size: 64, color: theme.colorScheme.tertiary),
          const SizedBox(width: 16),
          Text('64pt, tertiary color', style: theme.textTheme.bodySmall),
        ]),
        const SizedBox(height: EdenSpacing.space6),
        const Text('shimmer — text-line skeleton placeholder'),
        const SizedBox(height: EdenSpacing.space2),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          EdenLoadingIndicator.shimmer(width: 320, height: 14, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          EdenLoadingIndicator.shimmer(width: 180, height: 14, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 8),
          EdenLoadingIndicator.shimmer(width: 240, height: 14, borderRadius: BorderRadius.circular(4)),
        ]),
        const SizedBox(height: EdenSpacing.space6),
        const Text('crossFade — toggle to swap skeleton ↔ content'),
        const SizedBox(height: EdenSpacing.space2),
        const _CrossFadeToggleDemo(),
      ],
    );
  }
}

class _CrossFadeToggleDemo extends StatefulWidget {
  const _CrossFadeToggleDemo();

  @override
  State<_CrossFadeToggleDemo> createState() => _CrossFadeToggleDemoState();
}

class _CrossFadeToggleDemoState extends State<_CrossFadeToggleDemo> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Switch(value: _isLoading, onChanged: (v) => setState(() => _isLoading = v)),
            const SizedBox(width: 8),
            const Text('isLoading'),
          ]),
          const SizedBox(height: 12),
          EdenLoadingIndicator.crossFade(
            isLoading: _isLoading,
            skeleton: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EdenLoadingIndicator.shimmer(width: 220, height: 16, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 8),
              EdenLoadingIndicator.shimmer(width: 280, height: 12, borderRadius: BorderRadius.circular(4)),
            ]),
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Loaded title', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('This is the real body after the load completed.',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
        ],
      ),
    ));
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
