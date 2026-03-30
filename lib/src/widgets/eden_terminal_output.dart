import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A command output display block styled as a terminal.
///
/// Renders pre-formatted text output with an optional command header bar,
/// copy button, and scroll support. The background is always dark regardless
/// of the current theme.
class EdenTerminalOutput extends StatelessWidget {
  const EdenTerminalOutput({
    super.key,
    required this.output,
    this.command,
    this.onCopy,
    this.maxHeight,
  });

  /// The pre-formatted text output to display.
  final String output;

  /// The command that was run, shown as a header line prefixed with `$`.
  final String? command;

  /// Called when the user taps the copy button.
  final VoidCallback? onCopy;

  /// Optional maximum height constraint. When set, the output area scrolls
  /// within this bound. When null, the widget sizes to its intrinsic height.
  final double? maxHeight;

  Widget _buildCommandHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: EdenColors.neutral[700]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '\$ $command',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontFamilyFallback: ['Courier New', 'Courier'],
                fontSize: 13,
                color: Color(0xFF4ADE80), // Green for command prompt.
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onCopy != null)
            SizedBox(
              width: 28,
              height: 28,
              child: IconButton(
                onPressed: onCopy,
                icon: Icon(
                  Icons.copy_outlined,
                  size: 16,
                  color: EdenColors.neutral[400],
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Copy output',
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOutputBody() {
    final outputWidget = SingleChildScrollView(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: SelectableText(
        output,
        style: TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Courier New', 'Courier'],
          fontSize: 13,
          height: 1.5,
          color: EdenColors.neutral[300],
        ),
      ),
    );

    if (maxHeight != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: outputWidget,
      );
    }

    return outputWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EdenColors.neutral[900],
        border: Border.all(
          color: EdenColors.neutral[700]!,
        ),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (command != null) _buildCommandHeader(context),
          _buildOutputBody(),
        ],
      ),
    );
  }
}
