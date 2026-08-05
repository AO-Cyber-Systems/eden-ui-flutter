import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.autofillHints,
    this.readOnly = false,
    this.focusNode,
    this.inputFormatters,
    this.onTap,
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
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sizing = _resolveSizing();
    final hasError = errorText != null;

    Widget field = TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      autofillHints: autofillHints,
      readOnly: readOnly,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      onTap: onTap,
      style: TextStyle(fontSize: sizing.fontSize),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: sizing.padding,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: sizing.iconSize) : null,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: sizing.iconSize) : null,
        errorText: errorText,
        errorStyle: const TextStyle(fontSize: 12),
      ),
    );

    // The label is a sibling `Text`, not an `InputDecoration.labelText`, so
    // nothing associated it with the field: screen readers announced these
    // inputs as bare "text" / "password" with no name at all.
    //
    // MERGE, do not annotate. `Semantics(label:, textField: true, child: field)`
    // looks like the obvious fix and is WRONG: it declares a SECOND text-field
    // node above the TextField's own, and Flutter web then emits two `<input>`
    // elements per field — measured live as 4 inputs for 2 fields, doubling the
    // tab stops and giving a screen reader two "Email" boxes. `MergeSemantics`
    // instead folds the label and the field into ONE node, so the field is named
    // and stays a single control. Not a pixel moves: the same Text, the same
    // SizedBox, the same order.
    final labelText = label;
    if (labelText != null) {
      field = MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              labelText,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: hasError ? EdenColors.error : null,
              ),
            ),
            const SizedBox(height: 6),
            field,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
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
        return const _InputSizing(EdgeInsets.symmetric(horizontal: 12, vertical: 8), 13, 18);
      case EdenInputSize.md:
        return const _InputSizing(EdgeInsets.symmetric(horizontal: 16, vertical: 12), 14, 20);
      case EdenInputSize.lg:
        return const _InputSizing(EdgeInsets.symmetric(horizontal: 16, vertical: 14), 16, 22);
    }
  }
}

class _InputSizing {
  const _InputSizing(this.padding, this.fontSize, this.iconSize);
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
}
