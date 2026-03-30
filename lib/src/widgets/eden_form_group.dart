import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Wraps a form field with label, helper text, and error display.
///
/// Provides consistent layout for any input widget — not just EdenInput.
/// Use this when building custom form fields that need the same label/error
/// treatment as standard Eden inputs.
///
/// ```dart
/// EdenFormGroup(
///   label: 'Category',
///   helperText: 'Select the work category',
///   errorText: validationError,
///   child: DropdownButton(...),
/// )
/// ```
class EdenFormGroup extends StatelessWidget {
  const EdenFormGroup({
    super.key,
    required this.child,
    this.label,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.spacing = 6.0,
  });

  final Widget child;
  final String? label;
  final String? helperText;
  final String? errorText;
  final bool isRequired;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            children: [
              Text(
                label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: hasError ? EdenColors.error : null,
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                Text(
                  '*',
                  style: TextStyle(
                    color: EdenColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: spacing),
        ],
        child,
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EdenColors.error,
            ),
          ),
        ] else if (helperText != null) ...[
          SizedBox(height: EdenSpacing.space1),
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
