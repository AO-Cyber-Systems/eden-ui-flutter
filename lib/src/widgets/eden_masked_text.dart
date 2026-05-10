import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Inline secret-reveal field for API keys, tokens, IDs.
///
/// Renders [text] masked by default with two trailing affordances:
/// 1. A reveal/hide toggle that swaps between the full value and a mask.
/// 2. An optional copy-to-clipboard button (default on) that surfaces a
///    SnackBar confirmation.
///
/// Pass [maskedText] to override the default mask format. The default mask:
/// - <= 8 chars: `****`
/// - >  8 chars: first 4 + 8 stars + last 4 (e.g. `aoc_********ZxYW`)
class EdenMaskedText extends StatefulWidget {
  const EdenMaskedText({
    super.key,
    required this.text,
    this.maskedText,
    this.copyable = true,
  });

  /// The full secret value. Revealed when the eye icon is tapped, copied
  /// to the clipboard when the copy icon is tapped.
  final String text;

  /// Optional pre-formatted mask. When `null`, a default mask is computed
  /// from [text] (see class doc).
  final String? maskedText;

  /// Whether to render a clipboard-copy affordance.
  final bool copyable;

  @override
  State<EdenMaskedText> createState() => _EdenMaskedTextState();
}

class _EdenMaskedTextState extends State<EdenMaskedText> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = _revealed
        ? widget.text
        : (widget.maskedText ?? _mask(widget.text));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => setState(() => _revealed = !_revealed),
          child: Icon(
            _revealed ? Icons.visibility_off : Icons.visibility,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.copyable) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Icon(
              Icons.copy,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  String _mask(String text) {
    if (text.length <= 8) return '****';
    return '${text.substring(0, 4)}${'*' * 8}${text.substring(text.length - 4)}';
  }
}
