import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Data for a citation/reference source.
class EdenSource {
  const EdenSource({
    required this.title,
    this.url,
    this.description,
    this.icon,
    this.number,
  });

  final String title;
  final String? url;
  final String? description;
  final IconData? icon;
  final int? number;
}

/// Collapsible citations/references section.
class EdenSourcesFooter extends StatefulWidget {
  const EdenSourcesFooter({
    super.key,
    required this.sources,
    this.title = 'Sources',
    this.initiallyExpanded = false,
    this.onSourceTap,
  });

  final List<EdenSource> sources;
  final String title;
  final bool initiallyExpanded;
  final ValueChanged<EdenSource>? onSourceTap;

  @override
  State<EdenSourcesFooter> createState() => _EdenSourcesFooterState();
}

class _EdenSourcesFooterState extends State<EdenSourcesFooter>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) _animController.value = 1.0;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: EdenRadii.borderRadiusMd,
        border: Border.all(
          color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, isDark),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                ),
                ...widget.sources.map((s) => _SourceItem(
                      source: s,
                      isDark: isDark,
                      onTap: widget.onSourceTap,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Semantics(
      label: '${widget.title}, ${_isExpanded ? 'collapse' : 'expand'}',
      button: true,
      child: InkWell(
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space3,
        ),
        child: Row(
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: EdenSpacing.space2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!,
                borderRadius: EdenRadii.borderRadiusFull,
              ),
              child: Text(
                '${widget.sources.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? EdenColors.neutral[300]! : EdenColors.neutral[600]!,
                ),
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SourceItem extends StatelessWidget {
  const _SourceItem({
    required this.source,
    required this.isDark,
    this.onTap,
  });

  final EdenSource source;
  final bool isDark;
  final ValueChanged<EdenSource>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = source.url != null;
    final defaultIcon = hasUrl ? Icons.language : Icons.description_outlined;

    return Semantics(
      label: 'Source: ${source.title}',
      button: onTap != null,
      child: InkWell(
      onTap: onTap != null ? () => onTap!(source) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (source.number != null) ...[
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: EdenRadii.borderRadiusSm,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${source.number}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ] else ...[
              Icon(
                source.icon ?? defaultIcon,
                size: 18,
                color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!,
              ),
            ],
            const SizedBox(width: EdenSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasUrl
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      decoration: hasUrl ? TextDecoration.underline : null,
                      decorationColor: hasUrl ? theme.colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (source.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      source.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
