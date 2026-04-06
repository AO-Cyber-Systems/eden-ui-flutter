import 'package:flutter/material.dart';
import '../../eden_ui.dart';

/// A horizontal chip group that lets you select a value from an enum.
class EnumSelector<T extends Enum> extends StatelessWidget {
  const EnumSelector({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values.map((v) {
        final isActive = v == selected;
        final label = labelBuilder?.call(v) ?? v.name;
        return FilterChip(
          label: Text(label),
          selected: isActive,
          onSelected: (_) => onChanged(v),
          labelStyle: TextStyle(fontSize: 12),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}

/// A labeled toggle switch for boolean properties.
class ToggleControl extends StatelessWidget {
  const ToggleControl({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        SizedBox(
          height: 28,
          child: FittedBox(
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// A container widget that wraps a preview area with a controls panel below.
class InteractivePlayground extends StatelessWidget {
  const InteractivePlayground({
    super.key,
    required this.title,
    required this.preview,
    required this.controls,
  });

  final String title;
  final Widget preview;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: EdenRadii.borderRadiusLg,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EdenSpacing.space4, EdenSpacing.space3, EdenSpacing.space4, 0,
            ),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? EdenColors.neutral[300] : EdenColors.neutral[600],
              ),
            ),
          ),
          // Preview area
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: Center(child: preview),
          ),
          // Divider
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          // Controls area
          Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Wrap(
              spacing: EdenSpacing.space4,
              runSpacing: EdenSpacing.space2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: controls,
            ),
          ),
        ],
      ),
    );
  }
}
