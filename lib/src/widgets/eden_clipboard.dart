import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A tap-to-copy widget that copies text to the clipboard with visual feedback.
///
/// Wraps any [child] widget. When tapped, copies [text] to the system
/// clipboard and shows a toast confirmation.
class EdenClipboard extends StatefulWidget {
  const EdenClipboard({
    super.key,
    required this.text,
    this.child,
    this.toastMessage = 'Copied to clipboard',
    this.feedbackDuration = const Duration(seconds: 2),
  });

  /// The text to copy to the clipboard on tap.
  final String text;

  /// The child widget to display. If null, displays the text with a copy icon.
  final Widget? child;

  /// Message shown in the snackbar after copying.
  final String toastMessage;

  /// Duration of the visual feedback.
  final Duration feedbackDuration;

  @override
  State<EdenClipboard> createState() => _EdenClipboardState();
}

class _EdenClipboardState extends State<EdenClipboard> {
  bool _copied = false;

  Future<void> _handleTap() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(widget.toastMessage),
            ],
          ),
          duration: widget.feedbackDuration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await Future.delayed(widget.feedbackDuration);
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _handleTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: widget.child ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _copied ? Icons.check : Icons.content_copy,
                    key: ValueKey(_copied),
                    size: 16,
                    color: _copied
                        ? Colors.green.shade600
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
