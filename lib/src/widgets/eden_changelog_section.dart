import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// A single change item within a changelog category.
class EdenChangeItem {
  /// Creates a changelog change item.
  const EdenChangeItem({
    required this.description,
    this.prUrl,
    this.commitUrl,
  });

  /// Description of the change.
  final String description;

  /// Optional pull request link.
  final String? prUrl;

  /// Optional commit link.
  final String? commitUrl;
}

/// A versioned changelog entry containing categorized changes.
class EdenChangelogEntry {
  /// Creates a changelog entry for a specific version.
  const EdenChangelogEntry({
    required this.version,
    required this.date,
    this.categories = const {},
  });

  /// Version string (e.g. "1.2.0").
  final String version;

  /// Release date string (e.g. "2026-03-20").
  final String date;

  /// Map of category name to list of change items.
  ///
  /// Standard categories: Added, Changed, Fixed, Removed, Security, Deprecated.
  final Map<String, List<EdenChangeItem>> categories;
}

/// Standard changelog category with associated color and icon.
enum EdenChangelogCategory {
  /// New features.
  added,

  /// Changes to existing functionality.
  changed,

  /// Bug fixes.
  fixed,

  /// Removed features.
  removed,

  /// Security-related changes.
  security,

  /// Deprecated features.
  deprecated,
}

/// Displays a collapsible changelog with versioned, categorized entries.
///
/// Each version section is collapsible and contains categorized change items
/// following the Keep a Changelog convention with colored category headers.
class EdenChangelogSection extends StatefulWidget {
  /// Creates an Eden changelog section.
  const EdenChangelogSection({
    super.key,
    required this.entries,
    this.initiallyExpanded = true,
    this.onItemTap,
  });

  /// List of changelog entries to display.
  final List<EdenChangelogEntry> entries;

  /// Whether the first entry starts expanded.
  final bool initiallyExpanded;

  /// Called when a change item is tapped (with its PR or commit URL).
  final ValueChanged<EdenChangeItem>? onItemTap;

  @override
  State<EdenChangelogSection> createState() => _EdenChangelogSectionState();
}

class _EdenChangelogSectionState extends State<EdenChangelogSection> {
  late Set<String> _expandedVersions;

  static const _categoryMeta = <String, ({Color color, IconData icon})>{
    'Added': (color: Color(0xFF10B981), icon: Icons.add_circle_outline),
    'Changed': (color: Color(0xFF3B82F6), icon: Icons.change_circle_outlined),
    'Fixed': (color: Color(0xFFF59E0B), icon: Icons.build_circle_outlined),
    'Removed': (color: Color(0xFFEF4444), icon: Icons.remove_circle_outline),
    'Security': (color: Color(0xFFF97316), icon: Icons.shield_outlined),
    'Deprecated': (color: Color(0xFF71717A), icon: Icons.warning_amber_outlined),
  };

  @override
  void initState() {
    super.initState();
    _expandedVersions = {};
    if (widget.initiallyExpanded && widget.entries.isNotEmpty) {
      _expandedVersions.add(widget.entries.first.version);
    }
  }

  void _toggleVersion(String version) {
    setState(() {
      if (_expandedVersions.contains(version)) {
        _expandedVersions.remove(version);
      } else {
        _expandedVersions.add(version);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.entries.length; i++) ...[
          if (i > 0) const SizedBox(height: EdenSpacing.space3),
          _VersionSection(
            entry: widget.entries[i],
            isExpanded: _expandedVersions.contains(widget.entries[i].version),
            onToggle: () => _toggleVersion(widget.entries[i].version),
            onItemTap: widget.onItemTap,
            isDark: isDark,
            borderColor: borderColor,
            theme: theme,
            categoryMeta: _categoryMeta,
          ),
        ],
      ],
    );
  }
}

class _VersionSection extends StatelessWidget {
  const _VersionSection({
    required this.entry,
    required this.isExpanded,
    required this.onToggle,
    required this.onItemTap,
    required this.isDark,
    required this.borderColor,
    required this.theme,
    required this.categoryMeta,
  });

  final EdenChangelogEntry entry;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<EdenChangeItem>? onItemTap;
  final bool isDark;
  final Color borderColor;
  final ThemeData theme;
  final Map<String, ({Color color, IconData icon})> categoryMeta;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final mutedText =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Version header
          Material(
            color: Colors.transparent,
            borderRadius: EdenRadii.borderRadiusLg,
            child: InkWell(
              onTap: onToggle,
              borderRadius: EdenRadii.borderRadiusLg,
              child: Padding(
                padding: const EdgeInsets.all(EdenSpacing.space4),
                child: Row(
                  children: [
                    Icon(
                      isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                      color: mutedText,
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Text(
                      'v${entry.version}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: EdenSpacing.space3),
                    Text(
                      entry.date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedText,
                      ),
                    ),
                    const Spacer(),
                    // Category count summary
                    Text(
                      '${entry.categories.values.fold<int>(0, (sum, items) => sum + items.length)} changes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Categories
          if (isExpanded) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final categoryEntry in entry.categories.entries) ...[
                    _CategoryBlock(
                      categoryName: categoryEntry.key,
                      items: categoryEntry.value,
                      meta: categoryMeta[categoryEntry.key],
                      isDark: isDark,
                      theme: theme,
                      onItemTap: onItemTap,
                    ),
                    const SizedBox(height: EdenSpacing.space3),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.categoryName,
    required this.items,
    required this.meta,
    required this.isDark,
    required this.theme,
    this.onItemTap,
  });

  final String categoryName;
  final List<EdenChangeItem> items;
  final ({Color color, IconData icon})? meta;
  final bool isDark;
  final ThemeData theme;
  final ValueChanged<EdenChangeItem>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final color = meta?.color ?? EdenColors.neutral[500]!;
    final icon = meta?.icon ?? Icons.circle_outlined;
    final linkColor = isDark ? EdenColors.info : EdenColors.blue[600]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: EdenSpacing.space2),
            Text(
              categoryName,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space2),

        // Change items
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(
              left: EdenSpacing.space6,
              bottom: EdenSpacing.space1,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: EdenSpacing.space2),
                Expanded(
                  child: GestureDetector(
                    onTap: (item.prUrl != null || item.commitUrl != null) &&
                            onItemTap != null
                        ? () => onItemTap!(item)
                        : null,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: item.description),
                          if (item.prUrl != null)
                            TextSpan(
                              text: ' (PR)',
                              style: TextStyle(
                                color: linkColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (item.commitUrl != null && item.prUrl == null)
                            TextSpan(
                              text: ' (commit)',
                              style: TextStyle(
                                color: linkColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
