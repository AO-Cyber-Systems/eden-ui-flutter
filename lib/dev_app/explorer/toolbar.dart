// lib/dev_app/explorer/toolbar.dart
//
// ExplorerToolbar — global controls for the Flutter explorer (38-02):
// theme-profile chips (EnumSelector), brand chips (EdenBrandPresetRegistry),
// a light/dark toggle (ToggleControl), and viewport chips. Every selection is
// lifted to StoryShell via the onChanged callbacks; the toolbar holds no state.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

import '../widgets/interactive_controls.dart';

/// Named viewport presets for the canvas. `width == null` is "Fluid".
class ExplorerViewport {
  const ExplorerViewport(this.label, this.width);
  final String label;
  final double? width;

  static const List<ExplorerViewport> presets = [
    ExplorerViewport('Mobile', 390),
    ExplorerViewport('Tablet', 768),
    ExplorerViewport('Desktop', 1280),
    ExplorerViewport('Fluid', null),
  ];
}

/// Stateless global toolbar; reflects the current selections and reports
/// changes via callbacks.
class ExplorerToolbar extends StatelessWidget {
  const ExplorerToolbar({
    super.key,
    required this.profile,
    required this.brand,
    required this.isDark,
    required this.viewportWidth,
    required this.onProfile,
    required this.onBrand,
    required this.onBrightness,
    required this.onViewport,
  });

  final EdenThemeProfile profile;
  final EdenBrandPreset? brand;
  final bool isDark;
  final double? viewportWidth;
  final ValueChanged<EdenThemeProfile> onProfile;
  final ValueChanged<EdenBrandPreset?> onBrand;
  final ValueChanged<bool> onBrightness;
  final ValueChanged<double?> onViewport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Group(
            label: 'Profile',
            child: EnumSelector<EdenThemeProfile>(
              values: EdenThemeProfile.values,
              selected: profile,
              onChanged: onProfile,
            ),
          ),
          _Group(label: 'Brand', child: _BrandChips(brand: brand, onBrand: onBrand)),
          ToggleControl(label: 'Dark', value: isDark, onChanged: onBrightness),
          _Group(
            label: 'Viewport',
            child: _ViewportChips(viewportWidth: viewportWidth, onViewport: onViewport),
          ),
        ],
      ),
    );
  }
}

/// A small captioned group: a label above its control.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

/// Brand selector — a "None" chip plus one chip per registered preset. Brand
/// presets are not enums, so this composes [FilterChip]s directly (the TRD
/// sanctions a FilterChip wrap here).
class _BrandChips extends StatelessWidget {
  const _BrandChips({required this.brand, required this.onBrand});
  final EdenBrandPreset? brand;
  final ValueChanged<EdenBrandPreset?> onBrand;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        FilterChip(
          label: const Text('None'),
          selected: brand == null,
          onSelected: (_) => onBrand(null),
          labelStyle: const TextStyle(fontSize: 12),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        for (final preset in EdenBrandPresetRegistry.all())
          FilterChip(
            label: Text(preset.displayName),
            selected: brand?.id == preset.id,
            onSelected: (_) => onBrand(preset),
            labelStyle: const TextStyle(fontSize: 12),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}

/// Viewport selector chips (Mobile / Tablet / Desktop / Fluid).
class _ViewportChips extends StatelessWidget {
  const _ViewportChips({required this.viewportWidth, required this.onViewport});
  final double? viewportWidth;
  final ValueChanged<double?> onViewport;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final vp in ExplorerViewport.presets)
          FilterChip(
            label: Text(vp.label),
            selected: viewportWidth == vp.width,
            onSelected: (_) => onViewport(vp.width),
            labelStyle: const TextStyle(fontSize: 12),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
