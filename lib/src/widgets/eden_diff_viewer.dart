import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// The type of a single diff line.
enum EdenDiffLineType { addition, deletion, context, header }

/// Which side of a side-by-side diff.
enum EdenDiffSide { left, right }

/// Display mode for the diff viewer.
enum EdenDiffViewMode { unified, sideBySide }

/// A single line in a diff hunk.
class EdenDiffLine {
  const EdenDiffLine({
    required this.type,
    this.oldLineNumber,
    this.newLineNumber,
    required this.content,
  });

  final EdenDiffLineType type;
  final int? oldLineNumber;
  final int? newLineNumber;
  final String content;
}

/// A hunk of consecutive diff lines with a header.
class EdenDiffHunk {
  const EdenDiffHunk({
    required this.header,
    required this.lines,
  });

  final String header;
  final List<EdenDiffLine> lines;
}

/// A side-by-side and unified diff viewer with line comments, hunk collapsing,
/// and expand controls.
class EdenDiffViewer extends StatefulWidget {
  const EdenDiffViewer({
    super.key,
    required this.hunks,
    this.viewMode = EdenDiffViewMode.unified,
    this.onLineCommentTap,
    this.collapsedLinesBetweenHunks = 0,
  });

  /// The list of diff hunks to render.
  final List<EdenDiffHunk> hunks;

  /// Whether to show a unified or side-by-side view.
  final EdenDiffViewMode viewMode;

  /// Called when the user taps the comment icon on a line.
  final void Function(int lineNumber, EdenDiffSide side)? onLineCommentTap;

  /// Number of hidden context lines between hunks (shown as "Show N more
  /// lines" buttons). Set per gap; 0 hides the expand button.
  final int collapsedLinesBetweenHunks;

  @override
  State<EdenDiffViewer> createState() => _EdenDiffViewerState();
}

class _EdenDiffViewerState extends State<EdenDiffViewer> {
  final Set<int> _collapsedHunks = {};
  final Set<int> _expandedGaps = {};
  int _hoveredLineIndex = -1;
  int _hoveredHunkIndex = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < widget.hunks.length; i++) ...[
          if (i > 0 && widget.collapsedLinesBetweenHunks > 0)
            _buildExpandButton(context, i, isDark),
          _buildHunk(context, i, isDark, theme),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Expand button between hunks
  // ---------------------------------------------------------------------------

  Widget _buildExpandButton(BuildContext context, int gapIndex, bool isDark) {
    if (_expandedGaps.contains(gapIndex)) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => setState(() => _expandedGaps.add(gapIndex)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space1,
          horizontal: EdenSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? EdenColors.blue[950]!.withValues(alpha: 0.4)
              : EdenColors.blue[50],
          border: Border.symmetric(
            horizontal: BorderSide(
              color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Center(
          child: Text(
            'Show ${widget.collapsedLinesBetweenHunks} more lines',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? EdenColors.blue[300] : EdenColors.blue[600],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hunk
  // ---------------------------------------------------------------------------

  Widget _buildHunk(
    BuildContext context,
    int hunkIndex,
    bool isDark,
    ThemeData theme,
  ) {
    final hunk = widget.hunks[hunkIndex];
    final isCollapsed = _collapsedHunks.contains(hunkIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHunkHeader(hunk, hunkIndex, isDark, theme),
        if (!isCollapsed)
          widget.viewMode == EdenDiffViewMode.unified
              ? _buildUnifiedLines(hunk, hunkIndex, isDark, theme)
              : _buildSideBySideLines(hunk, hunkIndex, isDark, theme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Hunk header
  // ---------------------------------------------------------------------------

  Widget _buildHunkHeader(
    EdenDiffHunk hunk,
    int hunkIndex,
    bool isDark,
    ThemeData theme,
  ) {
    final isCollapsed = _collapsedHunks.contains(hunkIndex);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isCollapsed) {
            _collapsedHunks.remove(hunkIndex);
          } else {
            _collapsedHunks.add(hunkIndex);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: EdenSpacing.space1,
          horizontal: EdenSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? EdenColors.blue[950]!.withValues(alpha: 0.3)
              : EdenColors.blue[50]!.withValues(alpha: 0.7),
          border: Border(
            bottom: BorderSide(
              color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCollapsed
                  ? Icons.chevron_right_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
            ),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                hunk.header,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark ? EdenColors.blue[300] : EdenColors.blue[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Unified view
  // ---------------------------------------------------------------------------

  Widget _buildUnifiedLines(
    EdenDiffHunk hunk,
    int hunkIndex,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < hunk.lines.length; i++)
          _buildUnifiedLine(hunk.lines[i], hunkIndex, i, isDark, theme),
      ],
    );
  }

  Widget _buildUnifiedLine(
    EdenDiffLine line,
    int hunkIndex,
    int lineIndex,
    bool isDark,
    ThemeData theme,
  ) {
    final bgColor = _lineBackground(line.type, isDark);
    final isHovered =
        _hoveredHunkIndex == hunkIndex && _hoveredLineIndex == lineIndex;

    return MouseRegion(
      onEnter: (_) => setState(() {
        _hoveredHunkIndex = hunkIndex;
        _hoveredLineIndex = lineIndex;
      }),
      onExit: (_) => setState(() {
        _hoveredHunkIndex = -1;
        _hoveredLineIndex = -1;
      }),
      child: Container(
        color: bgColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Old line number gutter
              _buildGutter(line.oldLineNumber, isDark),
              // New line number gutter
              _buildGutter(line.newLineNumber, isDark),
              // Comment icon
              SizedBox(
                width: 24,
                height: 20,
                child: isHovered && widget.onLineCommentTap != null
                    ? GestureDetector(
                        onTap: () {
                          final ln =
                              line.newLineNumber ?? line.oldLineNumber ?? 0;
                          final side = line.type == EdenDiffLineType.deletion
                              ? EdenDiffSide.left
                              : EdenDiffSide.right;
                          widget.onLineCommentTap!(ln, side);
                        },
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: isDark
                              ? EdenColors.blue[300]
                              : EdenColors.blue[600],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              // Prefix character
              SizedBox(
                width: 14,
                child: Text(
                  _prefixChar(line.type),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: _prefixColor(line.type, isDark),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.only(right: EdenSpacing.space4),
                child: Text(
                  line.content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: isDark
                        ? EdenColors.neutral[100]
                        : EdenColors.neutral[900],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Side-by-side view
  // ---------------------------------------------------------------------------

  Widget _buildSideBySideLines(
    EdenDiffHunk hunk,
    int hunkIndex,
    bool isDark,
    ThemeData theme,
  ) {
    // Pair left (old) and right (new) lines.
    final leftLines = <EdenDiffLine?>[];
    final rightLines = <EdenDiffLine?>[];

    final deletions = <EdenDiffLine>[];
    final additions = <EdenDiffLine>[];

    void flushPairs() {
      final count =
          deletions.length > additions.length ? deletions.length : additions.length;
      for (int j = 0; j < count; j++) {
        leftLines.add(j < deletions.length ? deletions[j] : null);
        rightLines.add(j < additions.length ? additions[j] : null);
      }
      deletions.clear();
      additions.clear();
    }

    for (final line in hunk.lines) {
      if (line.type == EdenDiffLineType.deletion) {
        deletions.add(line);
      } else if (line.type == EdenDiffLineType.addition) {
        additions.add(line);
      } else {
        flushPairs();
        leftLines.add(line);
        rightLines.add(line);
      }
    }
    flushPairs();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < leftLines.length; i++)
          _buildSideBySideRow(
            leftLines[i],
            rightLines[i],
            hunkIndex,
            i,
            isDark,
            theme,
          ),
      ],
    );
  }

  Widget _buildSideBySideRow(
    EdenDiffLine? left,
    EdenDiffLine? right,
    int hunkIndex,
    int lineIndex,
    bool isDark,
    ThemeData theme,
  ) {
    final isHovered =
        _hoveredHunkIndex == hunkIndex && _hoveredLineIndex == lineIndex;

    return MouseRegion(
      onEnter: (_) => setState(() {
        _hoveredHunkIndex = hunkIndex;
        _hoveredLineIndex = lineIndex;
      }),
      onExit: (_) => setState(() {
        _hoveredHunkIndex = -1;
        _hoveredLineIndex = -1;
      }),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left side
            Expanded(
              child: _buildSideBySideCell(
                left,
                EdenDiffSide.left,
                isHovered,
                isDark,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
            ),
            // Right side
            Expanded(
              child: _buildSideBySideCell(
                right,
                EdenDiffSide.right,
                isHovered,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideBySideCell(
    EdenDiffLine? line,
    EdenDiffSide side,
    bool isHovered,
    bool isDark,
  ) {
    if (line == null) {
      return Container(
        color: isDark
            ? EdenColors.neutral[900]!.withValues(alpha: 0.5)
            : EdenColors.neutral[100]!.withValues(alpha: 0.5),
        height: 20,
      );
    }

    final bgColor = _lineBackground(line.type, isDark);
    final lineNum =
        side == EdenDiffSide.left ? line.oldLineNumber : line.newLineNumber;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGutter(lineNum, isDark),
            SizedBox(
              width: 24,
              height: 20,
              child: isHovered && widget.onLineCommentTap != null
                  ? GestureDetector(
                      onTap: () =>
                          widget.onLineCommentTap!(lineNum ?? 0, side),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: isDark
                            ? EdenColors.blue[300]
                            : EdenColors.blue[600],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.only(right: EdenSpacing.space4),
              child: Text(
                line.content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: isDark
                      ? EdenColors.neutral[100]
                      : EdenColors.neutral[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _buildGutter(int? lineNumber, bool isDark) {
    return Container(
      width: 48,
      height: 20,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: EdenSpacing.space2),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
            width: 0.5,
          ),
        ),
      ),
      child: Text(
        lineNumber?.toString() ?? '',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
        ),
      ),
    );
  }

  Color _lineBackground(EdenDiffLineType type, bool isDark) {
    switch (type) {
      case EdenDiffLineType.addition:
        return isDark
            ? EdenColors.emerald[950]!.withValues(alpha: 0.35)
            : EdenColors.emerald[50]!.withValues(alpha: 0.6);
      case EdenDiffLineType.deletion:
        return isDark
            ? EdenColors.red[950]!.withValues(alpha: 0.35)
            : EdenColors.red[50]!.withValues(alpha: 0.6);
      case EdenDiffLineType.header:
        return isDark
            ? EdenColors.blue[950]!.withValues(alpha: 0.2)
            : EdenColors.blue[50]!.withValues(alpha: 0.4);
      case EdenDiffLineType.context:
        return Colors.transparent;
    }
  }

  String _prefixChar(EdenDiffLineType type) {
    switch (type) {
      case EdenDiffLineType.addition:
        return '+';
      case EdenDiffLineType.deletion:
        return '-';
      case EdenDiffLineType.header:
        return '@';
      case EdenDiffLineType.context:
        return ' ';
    }
  }

  Color _prefixColor(EdenDiffLineType type, bool isDark) {
    switch (type) {
      case EdenDiffLineType.addition:
        return isDark ? EdenColors.emerald[400]! : EdenColors.emerald[700]!;
      case EdenDiffLineType.deletion:
        return isDark ? EdenColors.red[400]! : EdenColors.red[700]!;
      case EdenDiffLineType.header:
        return isDark ? EdenColors.blue[300]! : EdenColors.blue[700]!;
      case EdenDiffLineType.context:
        return isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!;
    }
  }
}
