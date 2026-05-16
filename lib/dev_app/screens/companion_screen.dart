import 'package:flutter/material.dart';

import '../../eden_ui.dart';

/// Catalog screen for the Companion Shell Foundation primitives
/// (objective 002). Hosts live demos for `EdenAppMode` (slider-driven
/// `resolveAppMode` preview + mode toggle) and future Wave-1/2/3
/// companion primitives.
class CompanionScreen extends StatefulWidget {
  const CompanionScreen({super.key});

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  late final EdenAppModeController _controller;
  double _viewportWidth = 390;
  double _adaptiveDemoWidth = 390;
  bool _forceCompact = false;

  @override
  void initState() {
    super.initState();
    _controller = EdenAppModeController(initialMode: EdenAppMode.fieldCompanion);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Companion Shell')),
      body: EdenAppModeScope(
        controller: _controller,
        child: ListView(
          padding: const EdgeInsets.all(EdenSpacing.space4),
          children: [
            _Section(
              title: 'EdenAppMode controller + scope',
              child: _AppModeControllerDemo(controller: _controller),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'resolveAppMode (viewport-driven)',
              child: _ResolveAppModeDemo(
                viewportWidth: _viewportWidth,
                onWidthChanged: (v) => setState(() => _viewportWidth = v),
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenAdaptiveLayout demo',
              child: _AdaptiveLayoutDemo(
                width: _adaptiveDemoWidth,
                forceCompact: _forceCompact,
                onWidthChanged: (v) => setState(() => _adaptiveDemoWidth = v),
                onForceCompactChanged: (v) => setState(() => _forceCompact = v),
              ),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenUxModeToggle demo',
              child: _UxModeToggleDemo(controller: _controller),
            ),
            const SizedBox(height: EdenSpacing.space4),
            _Section(
              title: 'EdenFieldViewGate demo',
              child: _FieldViewGateDemo(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldViewGateDemo extends StatelessWidget {
  const _FieldViewGateDemo({required this.controller});
  final EdenAppModeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flip the mode toggle above to swap which card is visible.',
        ),
        const SizedBox(height: EdenSpacing.space3),
        EdenFieldViewGate.companionOnly(
          fallback: const _GateCard(
            icon: Icons.visibility_off,
            label: 'Companion card hidden — not in field mode',
          ),
          child: const _GateCard(
            icon: Icons.smartphone,
            label: 'Companion-only widget',
          ),
        ),
        const SizedBox(height: EdenSpacing.space2),
        EdenFieldViewGate.adminOnly(
          fallback: const _GateCard(
            icon: Icons.visibility_off,
            label: 'Admin card hidden — not in admin mode',
          ),
          child: const _GateCard(
            icon: Icons.desktop_windows,
            label: 'Admin-only widget',
          ),
        ),
      ],
    );
  }
}

class _GateCard extends StatelessWidget {
  const _GateCard({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space3),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class _UxModeToggleDemo extends StatelessWidget {
  const _UxModeToggleDemo({required this.controller});
  final EdenAppModeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active mode: ${controller.currentMode.name}'),
            const SizedBox(height: EdenSpacing.space3),
            const Text('Compact (icon-only):'),
            const SizedBox(height: EdenSpacing.space2),
            EdenUxModeToggle.compact(controller: controller),
            const SizedBox(height: EdenSpacing.space3),
            const Text('Labeled (icon + text):'),
            const SizedBox(height: EdenSpacing.space2),
            EdenUxModeToggle.labeled(controller: controller),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EdenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: EdenSpacing.space3),
          child,
        ],
      ),
    );
  }
}

class _AppModeControllerDemo extends StatelessWidget {
  const _AppModeControllerDemo({required this.controller});
  final EdenAppModeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current mode: ${controller.currentMode.name}'),
            const SizedBox(height: EdenSpacing.space3),
            Wrap(
              spacing: 8,
              children: [
                for (final m in EdenAppMode.values)
                  ChoiceChip(
                    label: Text(m.name),
                    selected: controller.currentMode == m,
                    onSelected: (_) => controller.setMode(m),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AdaptiveLayoutDemo extends StatelessWidget {
  const _AdaptiveLayoutDemo({
    required this.width,
    required this.forceCompact,
    required this.onWidthChanged,
    required this.onForceCompactChanged,
  });

  final double width;
  final bool forceCompact;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<bool> onForceCompactChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Demo width: ${width.round()}pt'),
        Slider(
          value: width,
          min: 320,
          max: 1600,
          divisions: 128,
          label: '${width.round()}pt',
          onChanged: onWidthChanged,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('forceCompact'),
          value: forceCompact,
          onChanged: onForceCompactChanged,
        ),
        const SizedBox(height: EdenSpacing.space2),
        SizedBox(
          width: width,
          height: 80,
          child: EdenAdaptiveLayout(
            forceCompact: forceCompact,
            compactBuilder: (_) => _TierBadge(
              tier: 'Compact (<600pt)',
              color: Colors.blue.shade100,
            ),
            mediumBuilder: (_) => _TierBadge(
              tier: 'Medium (600–840pt)',
              color: Colors.amber.shade100,
            ),
            expandedBuilder: (_) => _TierBadge(
              tier: 'Expanded (≥840pt)',
              color: Colors.green.shade100,
            ),
          ),
        ),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier, required this.color});
  final String tier;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(tier, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ResolveAppModeDemo extends StatelessWidget {
  const _ResolveAppModeDemo({
    required this.viewportWidth,
    required this.onWidthChanged,
  });

  final double viewportWidth;
  final ValueChanged<double> onWidthChanged;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveAppMode(
      viewport: Size(viewportWidth, 800),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Viewport width: ${viewportWidth.round()}pt'),
        Slider(
          value: viewportWidth,
          min: 320,
          max: 1600,
          divisions: 128,
          label: '${viewportWidth.round()}pt',
          onChanged: onWidthChanged,
        ),
        Text('resolveAppMode → ${resolved.name}'),
        const SizedBox(height: EdenSpacing.space2),
        Text(
          'Compact (<600): fieldCompanion · Medium (600–840): askUser · '
          'Expanded (≥840): admin',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
