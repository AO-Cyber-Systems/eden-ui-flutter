import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Multi-line text input field.
///
/// Extends the EdenInput pattern with multi-line support, character counting,
/// and configurable min/max lines.
///
/// ```dart
/// EdenTextarea(
///   label: 'Description',
///   hint: 'Enter a detailed description...',
///   minLines: 3,
///   maxLines: 8,
///   maxLength: 500,
///   onChanged: (value) => setState(() => description = value),
/// )
/// ```
class EdenTextarea extends StatelessWidget {
  const EdenTextarea({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.minLines = 3,
    this.maxLines = 8,
    this.maxLength,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

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
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          minLines: minLines,
          maxLines: maxLines,
          maxLength: maxLength,
          autofocus: autofocus,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
            alignLabelWithHint: true,
          ),
        ),
        if (helperText != null && !hasError) ...[
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
}
