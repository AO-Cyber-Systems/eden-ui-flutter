import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';

/// Phone number input with formatting.
///
/// Provides US phone number formatting (XXX) XXX-XXXX by default.
/// Uses numeric keyboard and input formatting.
///
/// ```dart
/// EdenPhoneInput(
///   label: 'Phone',
///   controller: phoneController,
///   onChanged: (value) => setState(() => phone = value),
/// )
/// ```
class EdenPhoneInput extends StatelessWidget {
  const EdenPhoneInput({
    super.key,
    this.controller,
    this.label,
    this.hint = '(555) 555-5555',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.prefixText,
  });

  final TextEditingController? controller;
  final String? label;
  final String hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Country code prefix (e.g., '+1'). Displayed before the input.
  final String? prefixText;

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
          onSubmitted: onSubmitted,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _USPhoneFormatter(),
          ],
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            prefixText: prefixText,
            errorText: errorText,
            errorStyle: const TextStyle(fontSize: 12),
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

/// Formats digits as (XXX) XXX-XXXX.
class _USPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 10) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
