import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Search result display with type icon, snippet, and match type badge.
class EdenSearchResultCard extends StatelessWidget {
  const EdenSearchResultCard({
    super.key,
    required this.title,
    this.snippet,
    this.icon,
    this.iconColor,
    this.badge,
    this.badgeColor,
    this.timestamp,
    this.metadata,
    this.highlightTerms = const [],
    this.onTap,
  });

  final String title;
  final String? snippet;
  final IconData? icon;
  final Color? iconColor;
  final String? badge;
  final Color? badgeColor;
  final String? timestamp;
  final String? metadata;
  final List<String> highlightTerms;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[50]!;
    final hoverBg = isDark
        ? EdenColors.neutral[700]!.withValues(alpha: 0.5)
        : EdenColors.neutral[100]!;

    return Material(
      color: cardBg,
      borderRadius: EdenRadii.borderRadiusMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: EdenRadii.borderRadiusMd,
        hoverColor: hoverBg,
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(theme, isDark),
              const SizedBox(width: EdenSpacing.space3),
              Expanded(child: _buildContent(theme, isDark)),
              if (badge != null || timestamp != null) ...[
                const SizedBox(width: EdenSpacing.space3),
                _buildTrailing(theme, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, bool isDark) {
    final color = iconColor ?? theme.colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Icon(
        icon ?? Icons.description_outlined,
        size: 18,
        color: color,
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (snippet != null) ...[
          const SizedBox(height: 4),
          _buildSnippet(theme, isDark),
        ],
        if (metadata != null) ...[
          const SizedBox(height: 4),
          Text(
            metadata!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSnippet(ThemeData theme, bool isDark) {
    if (highlightTerms.isEmpty) {
      return Text(
        snippet!,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[600]!,
          height: 1.4,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: _highlightedSpan(theme, isDark),
    );
  }

  TextSpan _highlightedSpan(ThemeData theme, bool isDark) {
    final normalColor = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[600]!;
    final highlightColor = theme.colorScheme.onSurface;
    final text = snippet!;

    if (highlightTerms.isEmpty) {
      return TextSpan(
        text: text,
        style: TextStyle(fontSize: 13, color: normalColor, height: 1.4),
      );
    }

    final pattern = RegExp(
      highlightTerms.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(fontWeight: FontWeight.w700, color: highlightColor),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(
      style: TextStyle(fontSize: 13, color: normalColor, height: 1.4),
      children: spans,
    );
  }

  Widget _buildTrailing(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              borderRadius: EdenRadii.borderRadiusFull,
              border: Border.all(
                color: (badgeColor ?? theme.colorScheme.primary).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              badge!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor ?? theme.colorScheme.primary,
              ),
            ),
          ),
        if (timestamp != null) ...[
          if (badge != null) const SizedBox(height: 6),
          Text(
            timestamp!,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!,
            ),
          ),
        ],
      ],
    );
  }
}
