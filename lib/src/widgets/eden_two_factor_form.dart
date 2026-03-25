import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A two-factor authentication form with 6 individual digit input boxes.
///
/// Mirrors the eden 2FA verification flow pattern.
class EdenTwoFactorForm extends StatefulWidget {
  const EdenTwoFactorForm({
    super.key,
    required this.onSubmit,
    this.onResend,
    this.loading = false,
    this.errorMessage,
    this.codeLength = 6,
    this.submitLabel = 'Verify',
    this.resendLabel = 'Resend code',
    this.description =
        'Enter the verification code sent to your device.',
  });

  /// Called when the form is submitted with the full code.
  final void Function(String code) onSubmit;

  /// Called when the resend link is tapped.
  final VoidCallback? onResend;

  final bool loading;
  final String? errorMessage;
  final int codeLength;
  final String submitLabel;
  final String resendLabel;
  final String description;

  @override
  State<EdenTwoFactorForm> createState() => _EdenTwoFactorFormState();
}

class _EdenTwoFactorFormState extends State<EdenTwoFactorForm> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.codeLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.codeLength,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isComplete =>
      _controllers.every((c) => c.text.isNotEmpty);

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste: distribute digits across fields
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (int i = 0; i < widget.codeLength && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final lastFilledIndex =
          (digits.length - 1).clamp(0, widget.codeLength - 1);
      if (lastFilledIndex < widget.codeLength - 1) {
        _focusNodes[lastFilledIndex + 1].requestFocus();
      } else {
        _focusNodes[lastFilledIndex].unfocus();
      }
      setState(() {});
      if (_isComplete) _handleSubmit();
      return;
    }

    if (value.isNotEmpty && index < widget.codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});

    if (_isComplete) _handleSubmit();
  }

  void _handleKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  void _handleSubmit() {
    if (_isComplete) {
      widget.onSubmit(_code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: EdenSpacing.space5),
        if (widget.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: EdenRadii.borderRadiusMd,
            ),
            child: Text(
              widget.errorMessage!,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: EdenSpacing.space4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.codeLength; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 56,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) => _handleKeyDown(i, event),
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    maxLength: widget.codeLength, // allow paste
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: EdenRadii.borderRadiusMd,
                      ),
                    ),
                    onChanged: (value) => _handleChanged(i, value),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: EdenSpacing.space6),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: (widget.loading || !_isComplete)
                ? null
                : _handleSubmit,
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.submitLabel),
          ),
        ),
        if (widget.onResend != null) ...[
          const SizedBox(height: EdenSpacing.space4),
          Center(
            child: GestureDetector(
              onTap: widget.onResend,
              child: Text(
                widget.resendLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
