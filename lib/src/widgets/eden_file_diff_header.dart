import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The type of file change in a diff.
enum EdenFileChangeType { added, modified, deleted, renamed, copied }

/// Data model for a file diff header.
class EdenFileDiffHeaderData {
  const EdenFileDiffHeaderData({
    required this.filePath,
    required this.changeType,
    this.oldPath,
    this.additions = 0,
    this.deletions = 0,
  });

  final String filePath;
  final EdenFileChangeType changeType;

  /// Previous path, used for renames and copies.
  final String? oldPath;
  final int additions;
  final int deletions;
}

/// A collapsible file header for diff views showing file path, change badge,
/// line stats, viewed checkbox, and copy-path action.
class EdenFileDiffHeader extends StatefulWidget {
  const EdenFileDiffHeader({
    super.key,
    required this.data,
    this.isCollapsed = false,
    this.isViewed = false,
    this.onToggleCollapse,
    this.onViewedChanged,
    this.child,
  });

  final EdenFileDiffHeaderData data;
  final bool isCollapsed;
  final bool isViewed;
  final VoidCallback? onToggleCollapse;
  final ValueChanged<bool>? onViewedChanged;

  /// The diff content displayed below this header when expanded.
  final Widget? child;

  @override
  State<EdenFileDiffHeader> createState() => _EdenFileDiffHeaderState();
}

class _EdenFileDiffHeaderState extends State<EdenFileDiffHeader> {
  bool _copyFeedback = false;

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
        _buildHeader(isDark, theme),
        if (!widget.isCollapsed && widget.child != null) widget.child!,
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header bar
  // ---------------------------------------------------------------------------

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: EdenSpacing.space2,
        horizontal: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: isDark ? EdenColors.neutral[850] : EdenColors.neutral[50],
        border: Border(
          bottom: BorderSide(
            color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
            width: 0.5,
          ),
        ),
        borderRadius: widget.isCollapsed
            ? EdenRadii.borderRadiusMd
            : const BorderRadius.only(
                topLeft: Radius.circular(EdenRadii.md),
                topRight: Radius.circular(EdenRadii.md),
              ),
      ),
      child: Row(
        children: [
          // Collapse chevron
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Icon(
              widget.isCollapsed
                  ? Icons.chevron_right_rounded
                  : Icons.expand_more_rounded,
              size: 18,
              color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),

          // Change-type badge
          _buildBadge(isDark),
          const SizedBox(width: EdenSpacing.space2),

          // File path
          Expanded(child: _buildFilePath(isDark)),
          const SizedBox(width: EdenSpacing.space2),

          // +/- stats
          if (widget.data.additions > 0 || widget.data.deletions > 0) ...[
            _buildStats(isDark),
            const SizedBox(width: EdenSpacing.space3),
          ],

          // Copy path button
          _buildCopyButton(isDark),
          const SizedBox(width: EdenSpacing.space2),

          // Viewed checkbox
          _buildViewedCheckbox(isDark),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Badge
  // ---------------------------------------------------------------------------

  Widget _buildBadge(bool isDark) {
    final label = _changeTypeLabel(widget.data.changeType);
    final badgeColor = _changeTypeColor(widget.data.changeType, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // File path with dimmed folders
  // ---------------------------------------------------------------------------

  Widget _buildFilePath(bool isDark) {
    final parts = widget.data.filePath.split('/');
    final fileName = parts.last;
    final folderPath =
        parts.length > 1 ? '${parts.sublist(0, parts.length - 1).join('/')}/' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (folderPath.isNotEmpty)
          Flexible(
            child: Text(
              folderPath,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color:
                    isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Flexible(
          child: Text(
            fileName,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? EdenColors.neutral[100] : EdenColors.neutral[900],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.data.changeType == EdenFileChangeType.renamed &&
            widget.data.oldPath != null) ...[
          const SizedBox(width: EdenSpacing.space1),
          Icon(
            Icons.arrow_back_rounded,
            size: 12,
            color: isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
          ),
          const SizedBox(width: EdenSpacing.space1),
          Flexible(
            child: Text(
              widget.data.oldPath!,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color:
                    isDark ? EdenColors.neutral[500] : EdenColors.neutral[400],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats (+/-) counts
  // ---------------------------------------------------------------------------

  Widget _buildStats(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.data.additions > 0)
          Text(
            '+${widget.data.additions}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? EdenColors.emerald[400] : EdenColors.emerald[700],
            ),
          ),
        if (widget.data.additions > 0 && widget.data.deletions > 0)
          const SizedBox(width: EdenSpacing.space1),
        if (widget.data.deletions > 0)
          Text(
            '-${widget.data.deletions}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? EdenColors.red[400] : EdenColors.red[700],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Copy path button
  // ---------------------------------------------------------------------------

  Widget _buildCopyButton(bool isDark) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.data.filePath));
        if (!mounted) return;
        setState(() => _copyFeedback = true);
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copyFeedback = false);
        });
      },
      child: Tooltip(
        message: _copyFeedback ? 'Copied!' : 'Copy file path',
        child: Icon(
          _copyFeedback ? Icons.check_rounded : Icons.copy_rounded,
          size: 15,
          color: _copyFeedback
              ? EdenColors.success
              : (isDark ? EdenColors.neutral[400] : EdenColors.neutral[500]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Viewed checkbox
  // ---------------------------------------------------------------------------

  Widget _buildViewedCheckbox(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: widget.isViewed,
            onChanged: widget.onViewedChanged != null
                ? (v) => widget.onViewedChanged!(v ?? false)
                : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(
              color: isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!,
            ),
          ),
        ),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          'Viewed',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? EdenColors.neutral[400] : EdenColors.neutral[500],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _changeTypeLabel(EdenFileChangeType type) {
    switch (type) {
      case EdenFileChangeType.added:
        return 'Added';
      case EdenFileChangeType.modified:
        return 'Modified';
      case EdenFileChangeType.deleted:
        return 'Deleted';
      case EdenFileChangeType.renamed:
        return 'Renamed';
      case EdenFileChangeType.copied:
        return 'Copied';
    }
  }

  Color _changeTypeColor(EdenFileChangeType type, bool isDark) {
    switch (type) {
      case EdenFileChangeType.added:
        return isDark ? EdenColors.emerald[400]! : EdenColors.emerald[600]!;
      case EdenFileChangeType.modified:
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case EdenFileChangeType.deleted:
        return isDark ? EdenColors.red[400]! : EdenColors.red[600]!;
      case EdenFileChangeType.renamed:
      case EdenFileChangeType.copied:
        return isDark ? EdenColors.blue[400]! : EdenColors.blue[600]!;
    }
  }
}
