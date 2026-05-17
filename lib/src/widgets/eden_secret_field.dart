import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// Clipboard handling mode for [EdenSecretField].
///
/// Default [standard] preserves existing behavior: the copy button (when
/// `onCopy` is registered) is visible; paste is accepted silently.
///
/// [classified] is the DoD CUI pattern:
///   - copy affordance is suppressed (an Icon + Tooltip / Semantics
///     announces 'Classified — copy disabled' in its place);
///   - paste-from-outside detection fires
///     [EdenSecretField.onPasteFromOutsideWarning] when an `onChanged`
///     delta exceeds 4 characters in a single tick (heuristic).
///
/// Civilian re-use: PCI clipboard confinement / password-manager handoff
/// guards in commercial contexts.
enum EdenSecretClipboardMode { standard, classified }

/// A password/secret input field with reveal toggle and optional copy button.
class EdenSecretField extends StatefulWidget {
  const EdenSecretField({
    super.key,
    required this.value,
    this.label,
    this.onChanged,
    this.onCopy,
    this.readOnly = false,
    this.clipboardMode = EdenSecretClipboardMode.standard,
    this.onPasteFromOutsideWarning,
  });

  final String value;
  final String? label;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCopy;
  final bool readOnly;

  /// Clipboard mode. [EdenSecretClipboardMode.standard] preserves current
  /// behavior. [EdenSecretClipboardMode.classified] suppresses copy and
  /// warns on outside-paste (DoD CUI pattern).
  final EdenSecretClipboardMode clipboardMode;

  /// Fires when paste-from-outside is detected (only in
  /// [EdenSecretClipboardMode.classified] mode). Heuristic: an
  /// `onChanged` delta of more than 4 characters in a single tick.
  final VoidCallback? onPasteFromOutsideWarning;

  @override
  State<EdenSecretField> createState() => _EdenSecretFieldState();
}

class _EdenSecretFieldState extends State<EdenSecretField> {
  bool _obscured = true;
  late TextEditingController _controller;
  late String _lastText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _lastText = widget.value;
  }

  @override
  void didUpdateWidget(EdenSecretField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
      _lastText = widget.value;
    }
  }

  void _handleChange(String newText) {
    final delta = newText.length - _lastText.length;
    _lastText = newText;
    if (widget.clipboardMode == EdenSecretClipboardMode.classified &&
        delta > 4) {
      widget.onPasteFromOutsideWarning?.call();
    }
    widget.onChanged?.call(newText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceBg = isDark
        ? EdenColors.neutral[900]!
        : EdenColors.neutral[50]!;
    final borderColor = isDark
        ? EdenColors.neutral[700]!
        : EdenColors.neutral[200]!;
    final focusBorderColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EdenSpacing.space1),
        ],
        if (widget.readOnly)
          _buildReadOnlyField(theme, isDark, surfaceBg, borderColor)
        else
          _buildEditableField(
            theme,
            isDark,
            surfaceBg,
            borderColor,
            focusBorderColor,
          ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    ThemeData theme,
    bool isDark,
    Color surfaceBg,
    Color borderColor,
  ) {
    final displayText = _obscured
        ? '\u2022' * (widget.value.length.clamp(6, 24))
        : widget.value;

    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Courier New', 'Courier'],
                letterSpacing: _obscured ? 2.0 : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ..._buildSuffixButtons(theme),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    ThemeData theme,
    bool isDark,
    Color surfaceBg,
    Color borderColor,
    Color focusBorderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceBg,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: TextField(
        controller: _controller,
        obscureText: _obscured,
        onChanged: _handleChange,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier New', 'Courier'],
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space3,
          ),
          border: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: EdenRadii.borderRadiusMd,
            borderSide: BorderSide(color: focusBorderColor, width: 2),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildSuffixButtons(theme),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSuffixButtons(ThemeData theme) {
    final isClassified =
        widget.clipboardMode == EdenSecretClipboardMode.classified;
    return [
      IconButton(
        icon: Icon(
          _obscured ? Icons.visibility : Icons.visibility_off,
          size: 18,
          color: EdenColors.neutral[500],
        ),
        tooltip: _obscured ? 'Reveal secret' : 'Hide secret',
        onPressed: _toggleObscured,
        visualDensity: VisualDensity.compact,
      ),
      // Standard mode: copy button visible if onCopy registered.
      // Classified mode: copy suppressed; a disabled-marker Semantics
      // Icon takes its place announcing 'Classified — copy disabled'.
      if (widget.onCopy != null && !isClassified)
        IconButton(
          icon: Icon(
            Icons.copy,
            size: 18,
            color: EdenColors.neutral[500],
          ),
          tooltip: 'Copy to clipboard',
          onPressed: widget.onCopy,
          visualDensity: VisualDensity.compact,
        ),
      if (isClassified)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            label: 'Classified — copy disabled',
            child: Tooltip(
              message: 'Classified — copy disabled',
              child: Icon(
                Icons.copy_outlined,
                color: EdenColors.neutral[400],
                size: 18,
              ),
            ),
          ),
        ),
    ];
  }
}
