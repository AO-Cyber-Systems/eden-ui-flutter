import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Input size presets.
enum EdenInputSize { sm, md, lg }

/// Mirrors the eden_input Rails component.
class EdenInput extends StatelessWidget {
  const EdenInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.size = EdenInputSize.md,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final EdenInputSize size;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final sizing = _resolveSizing();
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: hasError ? EdenColors.error : null,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          maxLines: maxLines,
          autofocus: autofocus,
          style: TextStyle(fontSize: sizing.fontSize),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: sizing.padding,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: sizing.iconSize) : null,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: sizing.iconSize) : null,
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
        if (helperText != null && !hasError) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  _InputSizing _resolveSizing() {
    switch (size) {
      case EdenInputSize.sm:
        return _InputSizing(const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 13, 18);
      case EdenInputSize.md:
        return _InputSizing(const EdgeInsets.symmetric(horizontal: 16, vertical: 12), 14, 20);
      case EdenInputSize.lg:
        return _InputSizing(const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 16, 22);
    }
  }
}

class _InputSizing {
  const _InputSizing(this.padding, this.fontSize, this.iconSize);
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
}
