import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/eden_bare_field_theme.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_field_purpose.dart';

/// A rich chat input with attachments, typing callbacks, and multi-line support.
class EdenMessageInput extends StatefulWidget {
  const EdenMessageInput({
    super.key,
    this.onSubmit,
    this.onTypingStart,
    this.onTypingStop,
    this.onAttachmentTap,
    this.placeholder = 'Type a message...',
    this.enabled = true,
    this.prefix,
    this.trailingActions,
    this.minLines = 1,
    this.maxLines = 5,
    this.typingDebounce = const Duration(seconds: 2),
  });

  final ValueChanged<String>? onSubmit;
  final VoidCallback? onTypingStart;
  final VoidCallback? onTypingStop;
  final VoidCallback? onAttachmentTap;
  final String placeholder;
  final bool enabled;
  final Widget? prefix;
  final List<Widget>? trailingActions;
  final int minLines;
  final int maxLines;
  final Duration typingDebounce;

  @override
  State<EdenMessageInput> createState() => _EdenMessageInputState();
}

class _EdenMessageInputState extends State<EdenMessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    if (_isTyping) {
      widget.onTypingStop?.call();
    }
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() {});
    if (value.isNotEmpty && !_isTyping) {
      _isTyping = true;
      widget.onTypingStart?.call();
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(widget.typingDebounce, () {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingStop?.call();
      }
    });
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit?.call(text);
    _controller.clear();
    setState(() {});
    _typingTimer?.cancel();
    if (_isTyping) {
      _isTyping = false;
      widget.onTypingStop?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmpty = _controller.text.trim().isEmpty;

    // A chat composer. Explicitly NOT `none`: it genuinely wants the multiline
    // keyboard and the newline action key, and multilineText resolves both
    // together with sentence capitalization. It resolves null autofillHints —
    // there is no autofill token for free-form prose, and inventing one would
    // emit an invalid `autocomplete` value.
    const purpose = EdenFieldPurpose.multilineText;
    final composerSemantics = purpose.semantics;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.prefix != null) widget.prefix!,
        Container(
          decoration: BoxDecoration(
            color: isDark ? EdenColors.neutral[900] : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onAttachmentTap != null)
                Padding(
                  padding: const EdgeInsets.only(right: EdenSpacing.space2, bottom: 2),
                  child: IconButton(
                    icon: Icon(
                      Icons.attach_file,
                      color: widget.enabled
                          ? (isDark ? EdenColors.neutral[400] : EdenColors.neutral[500])
                          : (isDark ? EdenColors.neutral[700] : EdenColors.neutral[300]),
                      size: 22,
                    ),
                    onPressed: widget.enabled ? widget.onAttachmentTap : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    splashRadius: 18,
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? EdenColors.neutral[800] : EdenColors.neutral[50],
                    borderRadius: EdenRadii.borderRadiusLg,
                    border: Border.all(
                      color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                    ),
                  ),
                  child: EdenBareFieldTheme(
                    // THE COMPOSER IS THE CHROME. The Container above
                    // declares the fill (neutral[50] / neutral[800]) AND a
                    // Border.all (neutral[200] / neutral[700]); EdenTheme's
                    // inputDecorationTheme painted its own fill over the first
                    // and a colorScheme.outline ring one pixel inside the
                    // second — #d4d4d8 immediately within the composer's own
                    // #e4e4e7 edge, a doubled border. Pinned by
                    // field_border_overpaint_test.dart.
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled,
                      // minLines/maxLines stay the widget's own business:
                      // multilineText resolves TextInputType.multiline but
                      // deliberately does NOT set line counts.
                      minLines: widget.minLines,
                      maxLines: widget.maxLines,
                      onChanged: _handleChanged,
                      autofillHints: composerSemantics.autofillHints,
                      keyboardType: composerSemantics.keyboardType,
                      obscureText: composerSemantics.obscureText,
                      textInputAction: composerSemantics.textInputAction,
                      textCapitalization: composerSemantics.textCapitalization,
                      autocorrect: composerSemantics.autocorrect,
                      enableSuggestions: composerSemantics.enableSuggestions,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        hintStyle: TextStyle(
                          color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: EdenSpacing.space3,
                          vertical: EdenSpacing.space2,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.trailingActions != null)
                for (final action in widget.trailingActions!)
                  Padding(
                    padding: const EdgeInsets.only(left: EdenSpacing.space1, bottom: 2),
                    child: action,
                  ),
              Padding(
                padding: const EdgeInsets.only(left: EdenSpacing.space2, bottom: 2),
                child: IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: isEmpty || !widget.enabled
                        ? (isDark ? EdenColors.neutral[600] : EdenColors.neutral[300])
                        : theme.colorScheme.primary,
                    size: 22,
                  ),
                  onPressed: isEmpty || !widget.enabled ? null : _handleSubmit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  splashRadius: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
