import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single downloadable asset attached to a release.
class EdenReleaseAsset {
  /// Creates a release asset descriptor.
  const EdenReleaseAsset({
    required this.name,
    required this.size,
    required this.downloadUrl,
  });

  /// File name of the asset (e.g. "app-v1.2.0-linux-amd64.tar.gz").
  final String name;

  /// Human-readable file size (e.g. "12.4 MB").
  final String size;

  /// URL to download the asset.
  final String downloadUrl;
}

/// A card that displays a GitHub-style release with tag, notes, and assets.
///
/// Shows the release tag as a badge, optional pre-release/draft indicators,
/// the release notes body, a list of downloadable assets, and author + date.
class EdenReleaseCard extends StatefulWidget {
  /// Creates an Eden release card.
  const EdenReleaseCard({
    super.key,
    required this.tagName,
    required this.title,
    this.body,
    this.author,
    this.publishedAt,
    this.assets = const [],
    this.isPreRelease = false,
    this.isDraft = false,
    this.onTap,
    this.onAssetDownload,
  });

  /// The git tag name (e.g. "v1.2.0").
  final String tagName;

  /// Release title.
  final String title;

  /// Release notes body text.
  final String? body;

  /// Author display name.
  final String? author;

  /// Publication date string (e.g. "2026-03-20").
  final String? publishedAt;

  /// List of downloadable assets.
  final List<EdenReleaseAsset> assets;

  /// Whether this is a pre-release.
  final bool isPreRelease;

  /// Whether this is a draft release.
  final bool isDraft;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when an asset download button is pressed.
  final ValueChanged<EdenReleaseAsset>? onAssetDownload;

  @override
  State<EdenReleaseCard> createState() => _EdenReleaseCardState();
}

class _EdenReleaseCardState extends State<EdenReleaseCard> {
  bool _assetsExpanded = true;

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
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: EdenRadii.borderRadiusLg,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: EdenRadii.borderRadiusLg,
          child: Padding(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tag + badges row
                _buildHeader(theme, isDark, mutedText),
                const SizedBox(height: EdenSpacing.space2),

                // Title
                Text(
                  widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Body
                if (widget.body != null && widget.body!.isNotEmpty) ...[
                  const SizedBox(height: EdenSpacing.space3),
                  Text(
                    widget.body!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: mutedText,
                      height: 1.5,
                    ),
                  ),
                ],

                // Assets
                if (widget.assets.isNotEmpty) ...[
                  const SizedBox(height: EdenSpacing.space3),
                  _buildAssetsSection(theme, isDark, borderColor, mutedText),
                ],

                // Author + date footer
                if (widget.author != null || widget.publishedAt != null) ...[
                  const SizedBox(height: EdenSpacing.space3),
                  _buildFooter(theme, mutedText),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, Color mutedText) {
    return Wrap(
      spacing: EdenSpacing.space2,
      runSpacing: EdenSpacing.space1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Tag badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1 / 2,
          ),
          decoration: BoxDecoration(
            color: EdenColors.info.withValues(alpha: 0.12),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer_outlined, size: 12, color: EdenColors.info),
              const SizedBox(width: EdenSpacing.space1),
              Text(
                widget.tagName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EdenColors.info,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        // Pre-release badge
        if (widget.isPreRelease)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1 / 2,
            ),
            decoration: BoxDecoration(
              color: EdenColors.warning.withValues(alpha: 0.12),
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: const Text(
              'Pre-release',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: EdenColors.warning,
              ),
            ),
          ),

        // Draft badge
        if (widget.isDraft)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1 / 2,
            ),
            decoration: BoxDecoration(
              color: mutedText.withValues(alpha: 0.12),
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              'Draft',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: mutedText,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssetsSection(
    ThemeData theme,
    bool isDark,
    Color borderColor,
    Color mutedText,
  ) {
    final assetBg =
        isDark ? EdenColors.neutral[800]! : EdenColors.neutral[100]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _assetsExpanded = !_assetsExpanded),
          child: Row(
            children: [
              Icon(
                _assetsExpanded
                    ? Icons.expand_more
                    : Icons.chevron_right,
                size: 18,
                color: mutedText,
              ),
              const SizedBox(width: EdenSpacing.space1),
              Text(
                'Assets (${widget.assets.length})',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: mutedText,
                ),
              ),
            ],
          ),
        ),
        if (_assetsExpanded) ...[
          const SizedBox(height: EdenSpacing.space2),
          Container(
            decoration: BoxDecoration(
              color: assetBg,
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.assets.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: borderColor),
                  _AssetRow(
                    asset: widget.assets[i],
                    isDark: isDark,
                    onDownload: widget.onAssetDownload != null
                        ? () => widget.onAssetDownload!(widget.assets[i])
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, Color mutedText) {
    final parts = <String>[];
    if (widget.author != null) parts.add(widget.author!);
    if (widget.publishedAt != null) parts.add(widget.publishedAt!);

    return Row(
      children: [
        Icon(Icons.person_outline, size: 14, color: mutedText),
        const SizedBox(width: EdenSpacing.space1),
        Text(
          parts.join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
        ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.asset,
    required this.isDark,
    this.onDownload,
  });

  final EdenReleaseAsset asset;
  final bool isDark;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 16, color: mutedText),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              asset.name,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: EdenSpacing.space2),
          Text(
            asset.size,
            style: theme.textTheme.bodySmall?.copyWith(color: mutedText),
          ),
          const SizedBox(width: EdenSpacing.space2),
          SizedBox(
            width: 28,
            height: 28,
            child: Material(
              color: Colors.transparent,
              borderRadius: EdenRadii.borderRadiusSm,
              child: InkWell(
                onTap: onDownload,
                borderRadius: EdenRadii.borderRadiusSm,
                child: const Center(
                  child: Icon(
                    Icons.download_outlined,
                    size: 16,
                    color: EdenColors.info,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
