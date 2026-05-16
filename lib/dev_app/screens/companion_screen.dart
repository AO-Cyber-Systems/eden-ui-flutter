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
          ],
        ),
      ),
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
