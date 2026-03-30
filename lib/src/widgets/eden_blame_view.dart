import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A single line in a blame view.
class EdenBlameLine {
  const EdenBlameLine({
    required this.lineNumber,
    required this.content,
    required this.commitHash,
    required this.author,
    required this.date,
    this.isFirstInGroup = false,
  });

  final int lineNumber;
  final String content;
  final String commitHash;
  final String author;
  final String date;

  /// Whether this line is the first in a consecutive group from the same commit.
  final bool isFirstInGroup;
}

/// Gutter display density.
enum EdenBlameGutterMode { compact, full }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Per-line blame annotations showing commit, author, and date alongside code.
class EdenBlameView extends StatefulWidget {
  const EdenBlameView({
    super.key,
    required this.lines,
    this.gutterMode = EdenBlameGutterMode.full,
    this.onCommitTap,
    this.monoFontFamily,
  });

  /// All blame-annotated lines, in order.
  final List<EdenBlameLine> lines;

  /// Whether the gutter should be compact or full width.
  final EdenBlameGutterMode gutterMode;

  /// Called when the user taps a commit hash.
  final ValueChanged<String>? onCommitTap;

  /// Monospace font family for code content. Falls back to platform default.
  final String? monoFontFamily;

  @override
  State<EdenBlameView> createState() => _EdenBlameViewState();
}

class _EdenBlameViewState extends State<EdenBlameView> {
  final ScrollController _verticalController = ScrollController();

  /// Assigns a color-band index to each commit hash for alternating groups.
  late Map<String, int> _commitColorIndex;

  @override
  void initState() {
    super.initState();
    _buildColorIndex();
  }

  @override
  void didUpdateWidget(covariant EdenBlameView old) {
    super.didUpdateWidget(old);
    if (old.lines != widget.lines) _buildColorIndex();
  }

  void _buildColorIndex() {
    _commitColorIndex = {};
    int counter = 0;
    for (final line in widget.lines) {
      if (!_commitColorIndex.containsKey(line.commitHash)) {
        _commitColorIndex[line.commitHash] = counter;
        counter++;
      }
    }
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: EdenRadii.borderRadiusMd,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? EdenColors.neutral[900] : EdenColors.neutral[50],
              border: Border.all(
                color: isDark
                    ? EdenColors.neutral[700]!
                    : EdenColors.neutral[200]!,
              ),
              borderRadius: EdenRadii.borderRadiusMd,
            ),
            child: ListView.builder(
              controller: _verticalController,
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.lines.length,
              itemBuilder: (context, index) =>
                  _buildRow(context, widget.lines[index], isDark, theme),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Row
  // -------------------------------------------------------------------------

  Widget _buildRow(
    BuildContext context,
    EdenBlameLine line,
    bool isDark,
    ThemeData theme,
  ) {
    final colorIdx = _commitColorIndex[line.commitHash] ?? 0;
    final bandColor = _bandColor(colorIdx, isDark);
    final isCompact = widget.gutterMode == EdenBlameGutterMode.compact;
    final gutterWidth = isCompact ? 160.0 : 260.0;
    final monoStyle = TextStyle(
      fontFamily: widget.monoFontFamily ?? 'monospace',
      fontSize: 13,
      height: 1.5,
      color: theme.colorScheme.onSurface,
    );

    return Container(
      color: bandColor,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gutter
            _buildGutter(line, gutterWidth, isDark, theme, isCompact),
            // Separator
            Container(
              width: 1,
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
            // Line number
            _buildLineNumber(line.lineNumber, isDark, theme),
            // Code content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space3,
                ),
                child: Text(
                  line.content,
                  style: monoStyle,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGutter(
    EdenBlameLine line,
    double width,
    bool isDark,
    ThemeData theme,
    bool isCompact,
  ) {
    final gutterText = isDark
        ? EdenColors.neutral[400]!
        : EdenColors.neutral[500]!;
    final hashStyle = TextStyle(
      fontFamily: widget.monoFontFamily ?? 'monospace',
      fontSize: 12,
      height: 1.5,
      color: EdenColors.info,
      fontWeight: FontWeight.w500,
    );
    final metaStyle = TextStyle(
      fontSize: 12,
      height: 1.5,
      color: gutterText,
    );

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space2),
        child: line.isFirstInGroup
            ? Row(
                children: [
                  // Commit hash
                  GestureDetector(
                    onTap: widget.onCommitTap != null
                        ? () => widget.onCommitTap!(line.commitHash)
                        : null,
                    child: MouseRegion(
                      cursor: widget.onCommitTap != null
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: Text(
                        _abbreviateHash(line.commitHash),
                        style: hashStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: EdenSpacing.space2),
                  // Author
                  Expanded(
                    child: Text(
                      isCompact ? _initials(line.author) : line.author,
                      style: metaStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: EdenSpacing.space2),
                    Text(line.date, style: metaStyle),
                  ],
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLineNumber(int number, bool isDark, ThemeData theme) {
    return SizedBox(
      width: 48,
      child: Padding(
        padding: const EdgeInsets.only(right: EdenSpacing.space2),
        child: Text(
          '$number',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: widget.monoFontFamily ?? 'monospace',
            fontSize: 13,
            height: 1.5,
            color: isDark ? EdenColors.neutral[600] : EdenColors.neutral[400],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static String _abbreviateHash(String hash) {
    return hash.length > 7 ? hash.substring(0, 7) : hash;
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Returns an alternating band color for visual group separation.
  static Color _bandColor(int index, bool isDark) {
    final isEven = index.isEven;
    if (isDark) {
      return isEven
          ? Colors.transparent
          : EdenColors.neutral[800]!.withValues(alpha: 0.4);
    } else {
      return isEven
          ? Colors.transparent
          : EdenColors.neutral[100]!.withValues(alpha: 0.6);
    }
  }
}
