import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Color selection with swatch grid.
///
/// Displays a grid of color swatches. Tapping a swatch selects it.
/// The selected color is shown with a check mark overlay.
/// Supports custom color lists or uses defaults.
///
/// ```dart
/// EdenColorPicker(
///   label: 'Category Color',
///   value: selectedColor,
///   onChanged: (color) => setState(() => selectedColor = color),
/// )
/// ```
class EdenColorPicker extends StatelessWidget {
  const EdenColorPicker({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.helperText,
    this.errorText,
    this.colors,
    this.swatchSize = 36,
    this.spacing = 8,
  });

  final Color? value;
  final ValueChanged<Color> onChanged;
  final String? label;
  final String? helperText;
  final String? errorText;

  /// Custom color palette. Defaults to a standard set.
  final List<Color>? colors;
  final double swatchSize;
  final double spacing;

  static const List<Color> _defaultColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;
    final palette = colors ?? _defaultColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final color in palette)
              GestureDetector(
                onTap: () => onChanged(color),
                child: Container(
                  width: swatchSize,
                  height: swatchSize,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: value == color
                        ? Border.all(
                            color: theme.colorScheme.onSurface, width: 2)
                        : Border.all(
                            color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: value == color
                      ? Icon(
                          Icons.check,
                          size: swatchSize * 0.5,
                          color: _contrastColor(color),
                        )
                      : null,
                ),
              ),
          ],
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EdenColors.error,
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Color _contrastColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}
