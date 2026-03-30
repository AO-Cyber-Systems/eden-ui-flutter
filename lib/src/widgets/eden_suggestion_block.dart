import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// State of a code suggestion.
enum EdenSuggestionState { pending, applied }

/// Data model for a code suggestion in a review comment.
class EdenCodeSuggestion {
  const EdenCodeSuggestion({
    required this.originalLines,
    required this.suggestedLines,
    required this.filePath,
    required this.startLine,
  });

  final List<String> originalLines;
  final List<String> suggestedLines;
  final String filePath;
  final int startLine;
}

/// A code-suggestion block that renders a mini diff of original vs suggested
/// lines with apply/copy actions and collapsible/applied states.
class EdenSuggestionBlock extends StatefulWidget {
  const EdenSuggestionBlock({
    super.key,
    required this.suggestion,
    this.state = EdenSuggestionState.pending,
    this.initiallyExpanded = false,
    this.onApply,
    this.onCopy,
  });

  final EdenCodeSuggestion suggestion;
  final EdenSuggestionState state;
  final bool initiallyExpanded;
  final VoidCallback? onApply;
  final VoidCallback? onCopy;

  @override
  State<EdenSuggestionBlock> createState() => _EdenSuggestionBlockState();
}

class _EdenSuggestionBlockState extends State<EdenSuggestionBlock> {
  late bool _expanded;
  bool _copyFeedback = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(isDark),
        if (_expanded && widget.state == EdenSuggestionState.pending)
          _buildDiff(isDark),
        if (_expanded && widget.state == EdenSuggestionState.pending)
          _buildActions(isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(bool isDark) {
    final isApplied = widget.state == EdenSuggestionState.applied;

    return GestureDetector(
      onTap: isApplied ? null : () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space2,
          horizontal: EdenSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isApplied
              ? (isDark
                  ? EdenColors.emerald[950]!.withValues(alpha: 0.3)
                  : EdenColors.emerald[50])
              : (isDark ? EdenColors.neutral[850] : EdenColors.neutral[50]),
          borderRadius: _expanded && !isApplied
              ? const BorderRadius.only(
                  topLeft: Radius.circular(EdenRadii.md),
                  topRight: Radius.circular(EdenRadii.md),
                )
              : EdenRadii.borderRadiusMd,
          border: Border.all(
            color: isApplied
                ? (isDark
                    ? EdenColors.emerald[800]!
                    : EdenColors.emerald[200]!)
                : (isDark
                    ? EdenColors.neutral[700]!
                    : EdenColors.neutral[200]!),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            if (isApplied) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: isDark
                    ? EdenColors.emerald[400]
                    : EdenColors.emerald[600],
              ),
              const SizedBox(width: EdenSpacing.space2),
              Text(
                'Suggestion applied',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? EdenColors.emerald[300]
                      : EdenColors.emerald[700],
                ),
              ),
            ] else ...[
              Icon(
                _expanded
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
                size: 16,
                color:
                    isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
              ),
              const SizedBox(width: EdenSpacing.space2),
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 14,
                color:
                    isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
              ),
              const SizedBox(width: EdenSpacing.space1),
              Text(
                'Suggested change',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? EdenColors.neutral[200]
                      : EdenColors.neutral[700],
                ),
              ),
            ],
            const Spacer(),
            Text(
              widget.suggestion.filePath,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color:
                    isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mini-diff
  // ---------------------------------------------------------------------------

  Widget _buildDiff(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
          vertical: BorderSide(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Original lines (deletions)
          for (int i = 0; i < widget.suggestion.originalLines.length; i++)
            _buildDiffLine(
              lineNumber: widget.suggestion.startLine + i,
              content: widget.suggestion.originalLines[i],
              isDeletion: true,
              isDark: isDark,
            ),
          // Suggested lines (additions)
          for (int i = 0; i < widget.suggestion.suggestedLines.length; i++)
            _buildDiffLine(
              lineNumber: widget.suggestion.startLine + i,
              content: widget.suggestion.suggestedLines[i],
              isDeletion: false,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildDiffLine({
    required int lineNumber,
    required String content,
    required bool isDeletion,
    required bool isDark,
  }) {
    final bgColor = isDeletion
        ? (isDark
            ? EdenColors.red[950]!.withValues(alpha: 0.35)
            : EdenColors.red[50]!.withValues(alpha: 0.6))
        : (isDark
            ? EdenColors.emerald[950]!.withValues(alpha: 0.35)
            : EdenColors.emerald[50]!.withValues(alpha: 0.6));

    final prefixColor = isDeletion
        ? (isDark ? EdenColors.red[400]! : EdenColors.red[700]!)
        : (isDark ? EdenColors.emerald[400]! : EdenColors.emerald[700]!);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line number gutter
            Container(
              width: 44,
              height: 22,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: EdenSpacing.space2),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? EdenColors.neutral[700]!
                        : EdenColors.neutral[200]!,
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                lineNumber.toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark
                      ? EdenColors.neutral[500]
                      : EdenColors.neutral[400],
                ),
              ),
            ),
            // Prefix
            SizedBox(
              width: 18,
              child: Center(
                child: Text(
                  isDeletion ? '-' : '+',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: prefixColor,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.only(right: EdenSpacing.space4),
              child: Text(
                content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: isDark
                      ? EdenColors.neutral[100]
                      : EdenColors.neutral[900],
                  decoration: isDeletion ? TextDecoration.lineThrough : null,
                  decorationColor: isDark
                      ? EdenColors.red[400]
                      : EdenColors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action bar
  // ---------------------------------------------------------------------------

  Widget _buildActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: EdenSpacing.space2,
        horizontal: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(EdenRadii.md),
          bottomRight: Radius.circular(EdenRadii.md),
        ),
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Copy suggestion
          _ActionButton(
            icon: _copyFeedback
                ? Icons.check_rounded
                : Icons.copy_rounded,
            label: _copyFeedback ? 'Copied!' : 'Copy suggestion',
            isDark: isDark,
            onTap: () {
              final text = widget.suggestion.suggestedLines.join('\n');
              Clipboard.setData(ClipboardData(text: text));
              widget.onCopy?.call();
              if (!mounted) return;
              setState(() => _copyFeedback = true);
              Future<void>.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _copyFeedback = false);
              });
            },
          ),
          const SizedBox(width: EdenSpacing.space2),
          // Apply suggestion
          _ActionButton(
            icon: Icons.check_circle_outline_rounded,
            label: 'Apply suggestion',
            isDark: isDark,
            isPrimary: true,
            onTap: widget.onApply,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small action button used in the action bar
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isPrimary = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color fgColor;
    final Color bgColor;

    if (isPrimary) {
      fgColor = isDark ? EdenColors.emerald[300]! : EdenColors.emerald[700]!;
      bgColor = isDark
          ? EdenColors.emerald[950]!.withValues(alpha: 0.4)
          : EdenColors.emerald[50]!;
    } else {
      fgColor = isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;
      bgColor = isDark
          ? EdenColors.neutral[800]!.withValues(alpha: 0.5)
          : EdenColors.neutral[100]!;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space2,
          vertical: EdenSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: EdenRadii.borderRadiusSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
