import 'package:flutter/material.dart';
import '../../eden_ui.dart';
import '../widgets/section.dart';

class ColorsScreen extends StatelessWidget {
  const ColorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colors')),
      body: ListView(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        children: [
          ...EdenColors.presets.entries.map((entry) => Section(
            title: entry.key[0].toUpperCase() + entry.key.substring(1),
            child: _ColorSwatches(swatch: entry.value),
          )),
          Section(
            title: 'Neutral (Zinc)',
            child: _ColorSwatches(swatch: EdenColors.neutral),
          ),
          Section(
            title: 'Status Colors',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip('Success', EdenColors.success),
                _StatusChip('Warning', EdenColors.warning),
                _StatusChip('Error', EdenColors.error),
                _StatusChip('Info', EdenColors.info),
              ],
            ),
          ),
          Section(
            title: 'Aurora Gradients',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip('Purple', EdenColors.auroraPurple),
                _StatusChip('Blue', EdenColors.auroraBlue),
                _StatusChip('Cyan', EdenColors.auroraCyan),
                _StatusChip('Emerald', EdenColors.auroraEmerald),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.swatch});
  final MaterialColor swatch;

  @override
  Widget build(BuildContext context) {
    final shades = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 950];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: shades.map((shade) {
        final color = swatch[shade];
        if (color == null) return const SizedBox.shrink();
        final isLight = ThemeData.estimateBrightnessForColor(color) == Brightness.light;
        return Container(
          width: 56,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          alignment: Alignment.center,
          child: Text(
            '$shade',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isLight ? Colors.black87 : Colors.white,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
