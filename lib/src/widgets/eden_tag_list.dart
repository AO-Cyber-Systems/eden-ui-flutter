import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A registry tag entry with metadata.
class EdenRegistryTag {
  /// Creates a registry tag.
  const EdenRegistryTag({
    required this.name,
    this.size,
    this.updatedAt,
    this.digest,
    this.platform,
  });

  /// Tag name (e.g. "latest", "v1.2.0").
  final String name;

  /// Human-readable image size (e.g. "245 MB").
  final String? size;

  /// Last update time string (e.g. "2 hours ago").
  final String? updatedAt;

  /// Full digest hash (e.g. "sha256:abc123def456...").
  final String? digest;

  /// Platform/architecture string (e.g. "linux/amd64").
  final String? platform;
}

/// Displays a list of container registry tags with metadata.
///
/// Each row shows the tag name, size, date, abbreviated digest,
/// platform badges, and a copy digest button.
class EdenTagList extends StatefulWidget {
  /// Creates an Eden tag list.
  const EdenTagList({
    super.key,
    required this.tags,
    this.onTagTap,
  });

  /// List of tags to display.
  final List<EdenRegistryTag> tags;

  /// Called when a tag row is tapped.
  final ValueChanged<EdenRegistryTag>? onTagTap;

  @override
  State<EdenTagList> createState() => _EdenTagListState();
}

class _EdenTagListState extends State<EdenTagList> {
  String? _copiedDigest;

  void _handleCopyDigest(EdenRegistryTag tag) {
    setState(() => _copiedDigest = tag.digest);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedDigest = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
        color: surfaceColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < widget.tags.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _TagRow(
              tag: widget.tags[i],
              isDark: isDark,
              isCopied: _copiedDigest == widget.tags[i].digest &&
                  _copiedDigest != null,
              onTap: widget.onTagTap != null
                  ? () => widget.onTagTap!(widget.tags[i])
                  : null,
              onCopyDigest: widget.tags[i].digest != null
                  ? () => _handleCopyDigest(widget.tags[i])
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  const _TagRow({
    required this.tag,
    required this.isDark,
    required this.isCopied,
    this.onTap,
    this.onCopyDigest,
  });

  final EdenRegistryTag tag;
  final bool isDark;
  final bool isCopied;
  final VoidCallback? onTap;
  final VoidCallback? onCopyDigest;

  String _abbreviateDigest(String digest) {
    if (digest.length <= 15) return digest;
    final colonIndex = digest.indexOf(':');
    if (colonIndex >= 0 && digest.length > colonIndex + 13) {
      return '${digest.substring(0, colonIndex + 13)}...';
    }
    return '${digest.substring(0, 15)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Semantics(
      label: 'Tag: ${tag.name}',
      button: onTap != null,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top: tag name + platform badge
              Row(
                children: [
                  Icon(Icons.label_outline, size: 16, color: mutedText),
                  const SizedBox(width: EdenSpacing.space2),
                  Text(
                    tag.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (tag.platform != null) ...[
                    const SizedBox(width: EdenSpacing.space2),
                    _PlatformBadge(platform: tag.platform!, isDark: isDark),
                  ],
                ],
              ),
              const SizedBox(height: EdenSpacing.space2),

              // Bottom: size, date, digest, copy button
              Row(
                children: [
                  if (tag.size != null) ...[
                    Text(
                      tag.size!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: mutedText),
                    ),
                    const SizedBox(width: EdenSpacing.space3),
                  ],
                  if (tag.updatedAt != null) ...[
                    Icon(Icons.access_time, size: 12, color: mutedText),
                    const SizedBox(width: EdenSpacing.space1),
                    Text(
                      tag.updatedAt!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: mutedText),
                    ),
                    const SizedBox(width: EdenSpacing.space3),
                  ],
                  if (tag.digest != null) ...[
                    Expanded(
                      child: Text(
                        _abbreviateDigest(tag.digest!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: mutedText,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Semantics(
                      label: isCopied ? 'Digest copied' : 'Copy digest',
                      button: true,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: EdenRadii.borderRadiusSm,
                          child: InkWell(
                            onTap: onCopyDigest,
                            borderRadius: EdenRadii.borderRadiusSm,
                            child: Center(
                              child: Icon(
                                isCopied ? Icons.check : Icons.copy_outlined,
                                size: 14,
                                color: isCopied
                                    ? EdenColors.success
                                    : mutedText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
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

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({
    required this.platform,
    required this.isDark,
  });

  final String platform;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        platform,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
