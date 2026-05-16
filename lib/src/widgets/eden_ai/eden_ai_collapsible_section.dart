// Reusable collapsible section for AI insights across domain pages.
//
// Provides consistent "sparkle icon + title + chevron toggle" pattern used
// by every Wave 3 AI surface (operations dashboard, finance summary,
// dispatch panel, etc.).

import 'package:flutter/material.dart';

/// Outlined collapsible section for AI insights.
///
/// Renders an outlined card with a header (custom icon + title + animated
/// chevron) and an [AnimatedCrossFade] body. Tap the header to toggle. The
/// chevron rotates 0 → -0.25 turns (left-pointing) on collapse.
///
/// Default icon is `Icons.auto_awesome` tinted gold (0xFFD4A853 — hard-coded
/// for visual parity with the donor's AI chat FAB; not theme-dependent).
///
/// State is owned internally — consumers do NOT need to manage the expanded
/// flag (use [defaultExpanded] to set the initial value).
///
/// Cross-vertical examples:
/// - Operations dashboard insights.
/// - Finance / billing summary.
/// - Dispatch panel insights.
/// - Medical chart insight section.
/// - Legal matter insight wrap.
///
/// Donor: `trades-flutter/lib/shared/widgets/ai_collapsible_section.dart`.
class EdenAiCollapsibleSection extends StatefulWidget {
  const EdenAiCollapsibleSection({
    super.key,
    required this.title,
    required this.child,
    this.defaultExpanded = true,
    this.icon = Icons.auto_awesome,
  });

  /// Section title (renders next to the icon).
  final String title;

  /// Body content. Shown only when expanded.
  final Widget child;

  /// Initial expanded state.
  final bool defaultExpanded;

  /// Header icon (defaults to `Icons.auto_awesome`, gold-tinted).
  final IconData icon;

  @override
  State<EdenAiCollapsibleSection> createState() =>
      _EdenAiCollapsibleSectionState();
}

class _EdenAiCollapsibleSectionState extends State<EdenAiCollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.defaultExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(8),
              bottom: _expanded ? Radius.zero : const Radius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: const Color(0xFFD4A853)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.expand_more,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 150),
          ),
        ],
      ),
    );
  }
}
