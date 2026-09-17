import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import 'eden_field_purpose.dart';

/// Input size presets.
enum EdenInputSize { sm, md, lg }

/// Mirrors the eden_input Rails component.
///
/// ## Autofill
///
/// Prefer [purpose] over the deprecated raw [autofillHints], [keyboardType] and
/// [obscureText] arguments: one value resolves all three as a consistent set,
/// so a hint can never drift away from the keyboard it requires
/// (editable_text.dart:1855-1858).
///
/// ```dart
/// // Before (still works, deprecated - hint and keyboard can drift apart):
/// EdenInput(label: 'Email', keyboardType: TextInputType.emailAddress,
///           autofillHints: const [AutofillHints.email])
///
/// // After:
/// EdenInput(label: 'Email', hint: 'you@example.com',
///           purpose: EdenFieldPurpose.email)
/// ```
///
/// A field with no legitimate autofill purpose must SAY so with
/// [EdenFieldPurpose.none]. An omitted purpose is indistinguishable from an
/// oversight, and the guard test treats it as a defect.
///
/// Set [hint] on every purposed field: `hintText` becomes the DOM `placeholder`
/// on web (text_editing.dart:471), and password-manager heuristics read it.
///
/// Hints alone only make a field FILLABLE. Nothing is ever SAVED without
/// `finishAutofillContext` - see `EdenAutofillScope` for that half.
class EdenInput extends StatelessWidget {
  const EdenInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.size = EdenInputSize.md,
    @Deprecated(
      'Use `purpose:` instead. Supplying obscureText independently of the '
      'autofill hint is how a password field ends up as DOM type="text" on web '
      '(text_editing.dart:514-531), invisible to password managers. '
      'Will be removed in eden_ui_flutter 4.0.',
    )
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    @Deprecated(
      'Use `purpose:` instead. Supplying keyboardType independently of '
      'autofillHints is the hint<->keyboardType mismatch this library now '
      'prevents (editable_text.dart:1855-1858). '
      'Will be removed in eden_ui_flutter 4.0.',
    )
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    @Deprecated(
      'Use `purpose:` instead. Supplying autofillHints independently of '
      'keyboardType is the hint<->keyboardType mismatch this library now '
      'prevents (editable_text.dart:1855-1858). '
      'Will be removed in eden_ui_flutter 4.0.',
    )
    this.autofillHints,
    this.readOnly = false,
    this.focusNode,
    this.inputFormatters,
    this.onTap,
    this.purpose = EdenFieldPurpose.none,
  })  : assert(
          purpose == EdenFieldPurpose.none || autofillHints == null,
          'EdenInput: a non-none `purpose` already resolves autofillHints. '
          'Passing `autofillHints:` as well reintroduces exactly the '
          'hint<->keyboardType mismatch (editable_text.dart:1855-1858) that '
          'EdenFieldPurpose exists to prevent. Drop the raw `autofillHints:` '
          'argument, or use EdenFieldPurpose.none if you genuinely need '
          'manual control.',
        ),
        assert(
          purpose == EdenFieldPurpose.none || keyboardType == null,
          'EdenInput: a non-none `purpose` already resolves keyboardType. '
          'Passing `keyboardType:` as well reintroduces exactly the '
          'hint<->keyboardType mismatch (editable_text.dart:1855-1858) that '
          'EdenFieldPurpose exists to prevent. Drop the raw `keyboardType:` '
          'argument, or use EdenFieldPurpose.none if you genuinely need '
          'manual control.',
        ),
        assert(
          purpose == EdenFieldPurpose.none || !obscureText,
          'EdenInput: a non-none `purpose` already resolves obscureText '
          'together with a password-family autofill hint. Passing '
          '`obscureText:` as well can produce an obscured field with no '
          'password hint, which web renders as DOM type="text" '
          '(text_editing.dart:514-531). Drop the raw `obscureText:` argument, '
          'or use EdenFieldPurpose.none if you genuinely need manual control.',
        );

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final EdenInputSize size;
  /// Superseded by [purpose], which resolves this together with the autofill
  /// hint so an obscured field always carries a password-family hint.
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  /// Superseded by [purpose], which resolves this together with
  /// [autofillHints] so the two can never disagree.
  final TextInputType? keyboardType;

  /// Stays the caller's business even for a purposed field:
  /// [EdenFieldPurpose.multilineText] resolves [TextInputType.multiline] but
  /// deliberately does NOT set [maxLines].
  final int maxLines;
  final bool autofocus;
  /// Superseded by [purpose], which emits platform-correctly ORDERED hints
  /// (iOS and web read only the first one - autofill.dart:688-694).
  final Iterable<String>? autofillHints;
  final bool readOnly;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;

  /// The semantic purpose of this field. ONE value resolves [autofillHints]
  /// (in platform-correct order), [keyboardType], [obscureText],
  /// `textInputAction` and `textCapitalization` as a consistent set - see
  /// [EdenFieldPurpose].
  ///
  /// Defaults to [EdenFieldPurpose.none]: optional and additive, so existing
  /// call sites are unchanged.
  ///
  /// Also set [hint] on any field with a non-none purpose - `hintText` becomes
  /// the DOM `placeholder` on web (text_editing.dart:471) and password-manager
  /// heuristics read it. It is free classification signal.
  final EdenFieldPurpose purpose;

  @override
  Widget build(BuildContext context) {
    final sizing = _resolveSizing();
    final hasError = errorText != null;

    // ONE value resolves the whole set, so the hint <-> keyboardType pair can
    // never drift apart (editable_text.dart:1855-1858).
    final EdenFieldSemantics semantics = purpose.semantics;
    final bool isPurposed = purpose != EdenFieldPurpose.none;

    Widget field = TextField(
      controller: controller,
      obscureText: isPurposed ? semantics.obscureText : obscureText,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      // When `purpose` is none the caller's value - very often null - is
      // forwarded verbatim, so behaviour is byte-identical to before this
      // parameter existed. TextField itself then applies its own
      // `keyboardType ?? (maxLines == 1 ? text : multiline)` default
      // (text_field.dart:354).
      keyboardType: isPurposed ? semantics.keyboardType : keyboardType,
      maxLines: maxLines,
      autofocus: autofocus,
      autofillHints: isPurposed ? semantics.autofillHints : autofillHints,
      // New forwards. On the `none` branch they must be the Flutter defaults so
      // nothing changes for existing callers.
      //
      // `autocorrect` is passed as a non-null bool DELIBERATELY. It is a
      // non-nullable `bool` (default true) on the declared floor 3.27.0 and
      // only became nullable later, where null means
      // `_inferAutocorrect(autofillHints:)` (editable_text.dart:920). Passing
      // null would not compile at the floor. The inference differs from a plain
      // `true` only on iOS for username/password hints, which is exactly the
      // case a real `purpose` resolves explicitly - and on every platform.
      textInputAction: isPurposed ? semantics.textInputAction : null,
      textCapitalization:
          isPurposed ? semantics.textCapitalization : TextCapitalization.none,
      autocorrect: isPurposed ? semantics.autocorrect : true,
      enableSuggestions: isPurposed ? semantics.enableSuggestions : true,
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
