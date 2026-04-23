import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';

/// A single option for [EdenSelect].
class EdenSelectOption<T> {
  const EdenSelectOption({required this.value, required this.label});
  final T value;
  final String label;
}

/// Input size presets.
enum EdenSelectSize { sm, md, lg }

/// Mirrors the eden_select Rails component.
class EdenSelect<T> extends StatelessWidget {
  const EdenSelect({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.errorText,
    this.size = EdenSelectSize.md,
    this.enabled = true,
  });

  final List<EdenSelectOption<T>> options;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final String? errorText;
  final EdenSelectSize size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;
    final sizing = _resolveSizing();

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
          const SizedBox(height: 6),
        ],
        DropdownButtonFormField<T>(
          initialValue: value,
          items: options
              .map((opt) => DropdownMenuItem<T>(
                    value: opt.value,
                    child: Text(opt.label, style: TextStyle(fontSize: sizing.fontSize)),
                  ))
              .toList(),
          onChanged: enabled ? onChanged : null,
          hint: hint != null ? Text(hint!, style: TextStyle(fontSize: sizing.fontSize)) : null,
          decoration: InputDecoration(
            contentPadding: sizing.padding,
            errorText: errorText,
            enabled: enabled,
          ),
          borderRadius: EdenRadii.borderRadiusLg,
          isExpanded: true,
        ),
      ],
    );
  }

  _SelectSizing _resolveSizing() {
    switch (size) {
      case EdenSelectSize.sm:
        return const _SelectSizing(EdgeInsets.symmetric(horizontal: 12, vertical: 8), 13);
      case EdenSelectSize.md:
        return const _SelectSizing(EdgeInsets.symmetric(horizontal: 16, vertical: 12), 14);
      case EdenSelectSize.lg:
        return const _SelectSizing(EdgeInsets.symmetric(horizontal: 16, vertical: 14), 16);
    }
  }
}

class _SelectSizing {
  const _SelectSizing(this.padding, this.fontSize);
  final EdgeInsets padding;
  final double fontSize;
}
