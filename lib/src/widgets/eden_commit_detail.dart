import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The status of a changed file in a commit.
enum EdenChangedFileStatus {
  /// File was added.
  added,

  /// File was modified.
  modified,

  /// File was deleted.
  deleted,

  /// File was renamed.
  renamed,
}

/// A changed file entry within a commit.
class EdenChangedFile {
  /// Creates a changed file model.
  const EdenChangedFile({
    required this.path,
    required this.additions,
    required this.deletions,
    required this.status,
  });

  /// The file path.
  final String path;

  /// Number of lines added.
  final int additions;

  /// Number of lines deleted.
  final int deletions;

  /// The change status.
  final EdenChangedFileStatus status;
}

/// A detailed view of a single commit.
///
/// Shows full commit message, author/committer information, parent SHA links,
/// GPG verification badge, and a list of changed files with diff stats.
class EdenCommitDetail extends StatefulWidget {
  /// Creates a commit detail widget.
  const EdenCommitDetail({
    super.key,
    required this.sha,
    required this.message,
    required this.authorName,
    required this.authorEmail,
    required this.timestamp,
    this.committerName,
    this.parentShas = const [],
    this.changedFiles = const [],
    this.isVerified = false,
    this.onFileTap,
    this.onParentTap,
  });

  /// The full commit SHA hash.
  final String sha;

  /// The full commit message.
  final String message;

  /// The author name.
  final String authorName;

  /// The author email.
  final String authorEmail;

  /// The commit timestamp.
  final DateTime timestamp;

  /// The committer name (if different from author).
  final String? committerName;

  /// List of parent commit SHAs.
  final List<String> parentShas;

  /// List of changed files with diff stats.
  final List<EdenChangedFile> changedFiles;

  /// Whether the commit has a verified GPG signature.
  final bool isVerified;

  /// Called when a changed file is tapped.
  final ValueChanged<EdenChangedFile>? onFileTap;

  /// Called when a parent SHA is tapped.
  final ValueChanged<String>? onParentTap;

  @override
  State<EdenCommitDetail> createState() => _EdenCommitDetailState();
}

class _EdenCommitDetailState extends State<EdenCommitDetail> {
  int get _totalAdditions =>
      widget.changedFiles.fold(0, (sum, f) => sum + f.additions);

  int get _totalDeletions =>
      widget.changedFiles.fold(0, (sum, f) => sum + f.deletions);

  String get _abbreviatedSha =>
      widget.sha.length >= 7 ? widget.sha.substring(0, 7) : widget.sha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: SHA + verification badge
            _buildHeader(theme, isDark, mutedColor),
            const SizedBox(height: EdenSpacing.space4),

            // Full commit message
            _buildMessage(theme, isDark),
            const SizedBox(height: EdenSpacing.space4),

            // Author & committer info
            _buildAuthorInfo(theme, mutedColor),
            const SizedBox(height: EdenSpacing.space3),

            // Parent SHAs
            if (widget.parentShas.isNotEmpty) ...[
              _buildParentShas(theme, isDark, mutedColor),
              const SizedBox(height: EdenSpacing.space4),
            ],

            // Changed files summary bar
            if (widget.changedFiles.isNotEmpty) ...[
              _buildTotalSummary(theme, isDark),
              const SizedBox(height: EdenSpacing.space3),
              _buildChangedFilesList(theme, isDark, mutedColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color mutedColor) {
    return Row(
      children: [
        Text(
          'Commit $_abbreviatedSha',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        if (widget.isVerified) ...[
          const SizedBox(width: EdenSpacing.space2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: EdenColors.success.withValues(alpha: 0.12),
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user,
                  size: 14,
                  color: EdenColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: EdenColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        SelectableText(
          widget.sha,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(ThemeData theme, bool isDark) {
    final bgColor = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Text(
        widget.message,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildAuthorInfo(ThemeData theme, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: mutedColor),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              widget.authorName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: EdenSpacing.space1),
            Text(
              '<${widget.authorEmail}>',
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ],
        ),
        if (widget.committerName != null &&
            widget.committerName != widget.authorName) ...[
          const SizedBox(height: EdenSpacing.space1),
          Row(
            children: [
              Icon(Icons.send_outlined, size: 16, color: mutedColor),
              const SizedBox(width: EdenSpacing.space2),
              Text(
                'Committed by ${widget.committerName}',
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              ),
            ],
          ),
        ],
        const SizedBox(height: EdenSpacing.space1),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: mutedColor),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              _formatTimestamp(widget.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParentShas(ThemeData theme, bool isDark, Color mutedColor) {
    final shaBgColor =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;
    final shaTextColor =
        isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parents:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: mutedColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: EdenSpacing.space2),
        Expanded(
          child: Wrap(
            spacing: EdenSpacing.space2,
            runSpacing: EdenSpacing.space1,
            children: widget.parentShas.map((sha) {
              final abbrev = sha.length >= 7 ? sha.substring(0, 7) : sha;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onParentTap != null
                      ? () => widget.onParentTap!(sha)
                      : null,
                  borderRadius: EdenRadii.borderRadiusSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EdenSpacing.space2,
                      vertical: EdenSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: shaBgColor,
                      borderRadius: EdenRadii.borderRadiusSm,
                    ),
                    child: Text(
                      abbrev,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        color: shaTextColor,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalSummary(ThemeData theme, bool isDark) {
    final total = _totalAdditions + _totalDeletions;
    final addRatio = total > 0 ? _totalAdditions / total : 0.0;
    final delRatio = total > 0 ? _totalDeletions / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              '${widget.changedFiles.length} file${widget.changedFiles.length == 1 ? '' : 's'} changed',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: EdenSpacing.space3),
            Text(
              '+$_totalAdditions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: EdenColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              '-$_totalDeletions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: EdenColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),
        ClipRRect(
          borderRadius: EdenRadii.borderRadiusSm,
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (addRatio > 0)
                  Expanded(
                    flex: (addRatio * 100).round(),
                    child: Container(color: EdenColors.success),
                  ),
                if (delRatio > 0)
                  Expanded(
                    flex: (delRatio * 100).round(),
                    child: Container(color: EdenColors.error),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangedFilesList(
      ThemeData theme, bool isDark, Color mutedColor) {
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.changedFiles.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _ChangedFileRow(
              file: widget.changedFiles[i],
              isDark: isDark,
              onTap: widget.onFileTap != null
                  ? () => widget.onFileTap!(widget.changedFiles[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ChangedFileRow extends StatelessWidget {
  const _ChangedFileRow({
    required this.file,
    required this.isDark,
    this.onTap,
  });

  final EdenChangedFile file;
  final bool isDark;
  final VoidCallback? onTap;

  Color _statusColor() {
    switch (file.status) {
      case EdenChangedFileStatus.added:
        return EdenColors.success;
      case EdenChangedFileStatus.modified:
        return EdenColors.warning;
      case EdenChangedFileStatus.deleted:
        return EdenColors.error;
      case EdenChangedFileStatus.renamed:
        return EdenColors.info;
    }
  }

  String _statusLabel() {
    switch (file.status) {
      case EdenChangedFileStatus.added:
        return 'A';
      case EdenChangedFileStatus.modified:
        return 'M';
      case EdenChangedFileStatus.deleted:
        return 'D';
      case EdenChangedFileStatus.renamed:
        return 'R';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _statusColor().withValues(alpha: 0.12),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                child: Center(
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: EdenSpacing.space3),
              Expanded(
                child: Text(
                  file.path,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: EdenSpacing.space3),
              if (file.additions > 0)
                Text(
                  '+${file.additions}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EdenColors.success,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              if (file.additions > 0 && file.deletions > 0)
                const SizedBox(width: EdenSpacing.space2),
              if (file.deletions > 0)
                Text(
                  '-${file.deletions}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: EdenColors.error,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                ),
              if (file.additions == 0 && file.deletions == 0)
                Text(
                  '0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
