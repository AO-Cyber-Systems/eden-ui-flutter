import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Single action descriptor used by [EdenDetailHeader].
///
/// When the row has more actions than `actionsOverflowAtCount` OR when the
/// available width is below the narrow breakpoint, overflow actions collapse
/// into a [PopupMenuButton]. Actions are otherwise rendered inline as
/// [IconButton]s.
class EdenDetailHeaderAction {
  const EdenDetailHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
}

/// Compact header for entity detail views.
///
/// Ported from trades-flutter `lib/shared/widgets/detail_header.dart`.
/// Transport-agnostic: no Riverpod, no RBAC, no business logic — slots only.
///
/// Visual layout (top to bottom):
///   - Optional breadcrumb segments (`List<String>`) rendered as
///     `Crumb › Crumb` with `Wrap` so long breadcrumbs line-wrap safely.
///   - Title row: `leading` (optional avatar/icon) + title (Expanded;
///     wraps 2 lines + ellipsis) + status badge + actions row.
///   - Optional subtitle below the title.
///
/// At narrow widths (`maxWidth < narrowBreakpoint`) OR when
/// `actions.length > actionsOverflowAtCount`, the action row collapses to a
/// [PopupMenuButton]. The first action stays inline if the row fits, then
/// the rest move into the overflow menu.
class EdenDetailHeader extends StatelessWidget {
  const EdenDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumb,
    this.leading,
    this.actions,
    this.statusBadge,
    this.actionsOverflowAtCount = 4,
    this.narrowBreakpoint = 480,
  });

  /// Primary entity name displayed prominently.
  final String title;

  /// Optional secondary info (e.g., trade name, address, type).
  final String? subtitle;

  /// Breadcrumb segments rendered above the title row (e.g.,
  /// `['Customers', 'Active']`).
  final List<String>? breadcrumb;

  /// Optional leading widget (avatar/icon).
  final Widget? leading;

  /// Optional list of action descriptors. Overflows to PopupMenuButton when
  /// `length > actionsOverflowAtCount` OR when `maxWidth < narrowBreakpoint`.
  final List<EdenDetailHeaderAction>? actions;

  /// Optional status indicator widget (typically a Badge/Chip).
  final Widget? statusBadge;

  /// Threshold above which actions collapse to a PopupMenuButton regardless
  /// of viewport width.
  final int actionsOverflowAtCount;

  /// Below this width (logical px), the action row collapses to overflow.
  final double narrowBreakpoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleText = Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (breadcrumb != null && breadcrumb!.isNotEmpty) ...[
          _Breadcrumb(segments: breadcrumb!),
          const SizedBox(height: EdenSpacing.space1),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final hasActions = actions != null && actions!.isNotEmpty;
            final shouldOverflow = hasActions &&
                (actions!.length > actionsOverflowAtCount ||
                    constraints.maxWidth < narrowBreakpoint);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: EdenSpacing.space2),
                ],
                Expanded(child: titleText),
                if (statusBadge != null) ...[
                  const SizedBox(width: EdenSpacing.space2),
                  statusBadge!,
                ],
                if (hasActions) ...[
                  const SizedBox(width: EdenSpacing.space3),
                  if (shouldOverflow)
                    _OverflowActions(actions: actions!)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!
                          .map(
                            (a) => IconButton(
                              icon: Icon(a.icon),
                              tooltip: a.tooltip,
                              onPressed: a.onPressed,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                ],
              ],
            );
          },
        ),
        if (subtitle != null) ...[
          const SizedBox(height: EdenSpacing.space1),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Breadcrumb segments rendered as `A › B › C` using a [Wrap] so long
/// breadcrumbs line-wrap rather than overflowing.
class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.segments});
  final List<String> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 12,
    );

    final children = <Widget>[];
    for (var i = 0; i < segments.length; i++) {
      children.add(Text(segments[i], style: muted));
      if (i < segments.length - 1) {
        children.add(Text(' › ', style: muted));
      }
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// PopupMenuButton variant used when the action row is too long for the
/// available width. Returns a `PopupMenuButton<int>` keyed by action index
/// so widget tests can predictably locate it.
class _OverflowActions extends StatelessWidget {
  const _OverflowActions({required this.actions});
  final List<EdenDetailHeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'More actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (i) => actions[i].onPressed(),
      itemBuilder: (context) => [
        for (var i = 0; i < actions.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Row(
              children: [
                Icon(actions[i].icon, size: 18),
                const SizedBox(width: EdenSpacing.space2),
                Text(actions[i].tooltip),
              ],
            ),
          ),
      ],
    );
  }
}
