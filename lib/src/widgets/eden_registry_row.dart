import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A row displaying a container registry image or package entry.
///
/// Shows name, tag, size, push date, digest (truncated), vulnerability count,
/// and a copy button for the pull command.
class EdenRegistryRow extends StatefulWidget {
  /// Creates an Eden registry row.
  const EdenRegistryRow({
    super.key,
    required this.name,
    required this.tag,
    this.size,
    this.pushedAt,
    this.digest,
    this.vulnerabilityCount = 0,
    this.pullCommand,
    this.onTap,
    this.onCopyCommand,
  });

  /// Image or package name (e.g. "ghcr.io/org/app").
  final String name;

  /// Tag identifier (e.g. "latest", "v1.2.0").
  final String tag;

  /// Human-readable size (e.g. "245 MB").
  final String? size;

  /// When the image was pushed (e.g. "2 hours ago").
  final String? pushedAt;

  /// Image digest, displayed truncated (e.g. "sha256:abc123...").
  final String? digest;

  /// Number of known vulnerabilities. Colored by severity.
  final int vulnerabilityCount;

  /// The full pull command (e.g. "docker pull ghcr.io/org/app:latest").
  final String? pullCommand;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  /// Called when the copy pull command button is pressed.
  final VoidCallback? onCopyCommand;

  @override
  State<EdenRegistryRow> createState() => _EdenRegistryRowState();
}

class _EdenRegistryRowState extends State<EdenRegistryRow> {
  bool _copied = false;

  void _handleCopy() {
    widget.onCopyCommand?.call();
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Color _vulnerabilityColor() {
    if (widget.vulnerabilityCount == 0) return EdenColors.success;
    if (widget.vulnerabilityCount <= 3) return EdenColors.warning;
    return EdenColors.error;
  }

  String _truncateDigest(String digest) {
    if (digest.length <= 19) return digest;
    return '${digest.substring(0, 19)}...';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final mutedText =
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: icon, name, tag badge
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: mutedText,
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Expanded(
                      child: Text(
                        widget.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: EdenSpacing.space2,
                        vertical: EdenSpacing.space1 / 2,
                      ),
                      decoration: BoxDecoration(
                        color: EdenColors.info.withValues(alpha: 0.12),
                        borderRadius: EdenRadii.borderRadiusSm,
                      ),
                      child: Text(
                        widget.tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: EdenColors.info,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: EdenSpacing.space2),

                // Bottom row: size, date, digest, vuln badge, copy button
                Row(
                  children: [
                    if (widget.size != null) ...[
                      Icon(Icons.storage_outlined, size: 13, color: mutedText),
                      const SizedBox(width: EdenSpacing.space1),
                      Text(
                        widget.size!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space3),
                    ],
                    if (widget.pushedAt != null) ...[
                      Icon(Icons.access_time, size: 13, color: mutedText),
                      const SizedBox(width: EdenSpacing.space1),
                      Text(
                        widget.pushedAt!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedText,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space3),
                    ],
                    if (widget.digest != null) ...[
                      Text(
                        _truncateDigest(widget.digest!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: mutedText,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: EdenSpacing.space3),
                    ],
                    // Vulnerability badge
                    _VulnerabilityBadge(
                      count: widget.vulnerabilityCount,
                      color: _vulnerabilityColor(),
                    ),
                    const Spacer(),
                    // Copy pull command button
                    if (widget.pullCommand != null)
                      SizedBox(
                        height: 28,
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: EdenRadii.borderRadiusSm,
                          child: InkWell(
                            onTap: _handleCopy,
                            borderRadius: EdenRadii.borderRadiusSm,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: EdenSpacing.space2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _copied
                                        ? Icons.check
                                        : Icons.copy_outlined,
                                    size: 14,
                                    color:
                                        _copied ? EdenColors.success : mutedText,
                                  ),
                                  const SizedBox(width: EdenSpacing.space1),
                                  Text(
                                    _copied ? 'Copied' : 'Pull',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _copied
                                          ? EdenColors.success
                                          : mutedText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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

class _VulnerabilityBadge extends StatelessWidget {
  const _VulnerabilityBadge({
    required this.count,
    required this.color,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1 / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            count == 0 ? Icons.verified_outlined : Icons.warning_amber,
            size: 12,
            color: color,
          ),
          const SizedBox(width: EdenSpacing.space1),
          Text(
            count == 0 ? 'Clean' : '$count vuln${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
