import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// N-digit OTP code entry with one input per digit.
///
/// Behavior:
/// - Typing a digit auto-advances focus to the next box.
/// - Pressing backspace on an empty box moves focus to the previous box.
/// - Pasting (or programmatically entering) a multi-digit string into any
///   box distributes the digits across the remaining boxes.
/// - [onChanged] fires whenever the joined value changes.
/// - [onSubmit] fires once the full N-digit code is entered.
///
/// Transport-agnostic: no network calls; downstream apps wire their own
/// SMS / TOTP provider via [onSubmit] or [onChanged].
class EdenOtpInput extends StatefulWidget {
  const EdenOtpInput({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onSubmit,
    this.autofocus = true,
    this.boxWidth = 44.0,
    this.boxHeight = 52.0,
    this.gap = EdenSpacing.space2,
    this.enabled = true,
  });

  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final bool autofocus;
  final double boxWidth;
  final double boxHeight;
  final double gap;
  final bool enabled;

  @override
  State<EdenOtpInput> createState() => _EdenOtpInputState();
}

class _EdenOtpInputState extends State<EdenOtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
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

  String _joined() => _controllers.map((c) => c.text).join();

  void _emitChanged() {
    final value = _joined();
    widget.onChanged?.call(value);
    if (value.length == widget.length &&
        !value.contains(RegExp(r'\s')) &&
        value.runes.length == widget.length) {
      widget.onSubmit?.call(value);
    }
  }

  void _handleChange(int index, String value) {
    if (value.isEmpty) {
      _emitChanged();
      return;
    }

    if (value.length == 1) {
      // Single digit entry — move focus forward if possible.
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _emitChanged();
      return;
    }

    // Multi-character entry (paste). Distribute across boxes starting at index.
    final digits = value.replaceAll(RegExp(r'\s'), '');
    var target = index;
    for (final ch in digits.split('')) {
      if (target >= widget.length) break;
      _controllers[target].text = ch;
      target++;
    }
    // Focus the next empty box, or the last box if all filled.
    final nextFocus = target < widget.length ? target : widget.length - 1;
    _focusNodes[nextFocus].requestFocus();
    setState(() {});
    _emitChanged();
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        _emitChanged();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxes = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      if (i > 0) boxes.add(SizedBox(width: widget.gap));
      boxes.add(SizedBox(
        width: widget.boxWidth,
        height: widget.boxHeight,
        child: Focus(
          onKeyEvent: (_, e) => _handleKey(i, e),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            autofocus: widget.autofocus && i == 0,
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: theme.textTheme.titleLarge,
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: EdenRadii.borderRadiusMd,
              ),
            ),
            onChanged: (v) => _handleChange(i, v),
          ),
        ),
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: boxes,
    );
  }
}
