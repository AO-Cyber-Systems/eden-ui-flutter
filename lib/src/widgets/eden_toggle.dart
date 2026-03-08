import 'package:flutter/material.dart';

/// Mirrors the eden_toggle Rails component.
class EdenToggle extends StatelessWidget {
  const EdenToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final toggle = Switch(
      value: value,
      onChanged: disabled ? null : onChanged,
      activeTrackColor: theme.colorScheme.primary,
    );

    if (label == null) return toggle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        toggle,
        const SizedBox(width: 8),
        Text(
          label!,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: disabled ? theme.colorScheme.onSurfaceVariant : null,
          ),
        ),
      ],
    );
  }
}
