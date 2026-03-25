import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A compact row displaying a single commit entry.
///
/// Shows abbreviated SHA, truncated message, author avatar, relative timestamp,
/// and an optional verified badge.
class EdenCommitRow extends StatefulWidget {
  /// Creates a commit row widget.
  const EdenCommitRow({
    super.key,
    required this.sha,
    required this.message,
    required this.authorName,
    required this.authorAvatarInitial,
    required this.timestamp,
    this.isVerified = false,
    this.onTap,
    this.onShaTap,
    this.onBrowseFiles,
  });

  /// The full commit SHA hash.
  final String sha;

  /// The commit message (first line will be displayed).
  final String message;

  /// The name of the commit author.
  final String authorName;

  /// A single character initial for the author avatar.
  final String authorAvatarInitial;

  /// The commit timestamp.
  final DateTime timestamp;

  /// Whether this commit has a verified/signed signature.
  final bool isVerified;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  /// Called when the abbreviated SHA is tapped.
  final VoidCallback? onShaTap;

  /// Called when the browse-files button is tapped.
  final VoidCallback? onBrowseFiles;

  @override
  State<EdenCommitRow> createState() => _EdenCommitRowState();
}

class _EdenCommitRowState extends State<EdenCommitRow> {
  String get _abbreviatedSha =>
      widget.sha.length >= 7 ? widget.sha.substring(0, 7) : widget.sha;

  String get _relativeTime {
    final now = DateTime.now();
    final diff = now.difference(widget.timestamp);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return '$d day${d == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 365) {
      final mo = diff.inDays ~/ 30;
      return '$mo month${mo == 1 ? '' : 's'} ago';
    }
    final y = diff.inDays ~/ 365;
    return '$y year${y == 1 ? '' : 's'} ago';
  }

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
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: EdenRadii.borderRadiusMd,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: EdenRadii.borderRadiusMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space4,
              vertical: EdenSpacing.space3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Author avatar
                    _AuthorAvatar(
                      initial: widget.authorAvatarInitial,
                      isDark: isDark,
                    ),
                    const SizedBox(width: EdenSpacing.space3),

                    // Message + author info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: EdenSpacing.space1),
                          Row(
                            children: [
                              Text(
                                widget.authorName,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(width: EdenSpacing.space2),
                              Text(
                                _relativeTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space3),

                    // Verified badge
                    if (widget.isVerified) ...[
                      const Tooltip(
                        message: 'Verified signature',
                        child: Icon(
                          Icons.verified_user,
                          size: 16,
                          color: EdenColors.success,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space2),
                    ],

                    // Abbreviated SHA
                    _ShaBadge(
                      sha: _abbreviatedSha,
                      isDark: isDark,
                      onTap: widget.onShaTap,
                    ),
                    const SizedBox(width: EdenSpacing.space2),

                    // Browse files button
                    _BrowseFilesButton(
                      isDark: isDark,
                      onTap: widget.onBrowseFiles,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({
    required this.initial,
    required this.isDark,
  });

  final String initial;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final fgColor = isDark ? EdenColors.neutral[200]! : EdenColors.neutral[700]!;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.isNotEmpty ? initial[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fgColor,
          ),
        ),
      ),
    );
  }
}

class _ShaBadge extends StatelessWidget {
  const _ShaBadge({
    required this.sha,
    required this.isDark,
    this.onTap,
  });

  final String sha;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;
    final textColor = isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: EdenRadii.borderRadiusSm,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Text(
            sha,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseFilesButton extends StatelessWidget {
  const _BrowseFilesButton({
    required this.isDark,
    this.onTap,
  });

  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Tooltip(
      message: 'Browse files',
      child: SizedBox(
        width: 28,
        height: 28,
        child: Material(
          color: Colors.transparent,
          borderRadius: EdenRadii.borderRadiusSm,
          child: InkWell(
            onTap: onTap,
            borderRadius: EdenRadii.borderRadiusSm,
            child: Center(
              child: Icon(
                Icons.folder_outlined,
                size: 16,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
