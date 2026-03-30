import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A compact pill-shaped label badge with auto-contrasting text color.
///
/// Supports an optional description tooltip and a removable mode with an X
/// button.
class EdenLabelBadge extends StatefulWidget {
  /// Creates a label badge widget.
  const EdenLabelBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    this.description,
    this.removable = false,
    this.onRemove,
    this.onTap,
  });

  /// The label text to display.
  final String label;

  /// The background color of the badge.
  final Color backgroundColor;

  /// An optional description shown as a tooltip on hover/tap.
  final String? description;

  /// Whether to show a remove (X) button.
  final bool removable;

  /// Called when the remove button is tapped.
  final VoidCallback? onRemove;

  /// Called when the badge itself is tapped.
  final VoidCallback? onTap;

  @override
  State<EdenLabelBadge> createState() => _EdenLabelBadgeState();
}

class _EdenLabelBadgeState extends State<EdenLabelBadge> {
  /// Determines whether to use white or dark text based on background
  /// luminance.
  Color get _textColor {
    return widget.backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
  }

  Color get _removeButtonColor {
    return _textColor.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.removable ? EdenSpacing.space1 : EdenSpacing.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(EdenRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.removable)
            const SizedBox(width: EdenSpacing.space1),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor,
              height: 1.2,
            ),
          ),
          if (widget.removable) ...[
            const SizedBox(width: EdenSpacing.space1),
            _RemoveButton(
              color: _removeButtonColor,
              hoverColor: _textColor,
              onTap: widget.onRemove,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );

    if (widget.onTap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(EdenRadii.full),
          child: badge,
        ),
      );
    }

    if (widget.description != null) {
      badge = Tooltip(
        message: widget.description!,
        child: badge,
      );
    }

    return badge;
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({
    required this.color,
    required this.hoverColor,
    required this.isDark,
    this.onTap,
  });

  final Color color;
  final Color hoverColor;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(EdenRadii.full),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EdenRadii.full),
          child: Center(
            child: Icon(
              Icons.close,
              size: 12,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
