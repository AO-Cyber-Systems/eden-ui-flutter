import 'package:flutter/material.dart';

/// Palette presets for role badges in [EdenRoleDashboardShell].
///
/// Each vertical historically maps its primary brand color into the role
/// badge. The library resolves each enum value to a concrete (background,
/// foreground) pair internally so callers don't need to know about Eden
/// color tokens.
enum EdenRolePalette {
  trades,
  salon,
  medical,
  fuel,
  retail,
  legal,
  gov,
  neutral,
}

/// Display-priority hint for dashboard sections.
enum EdenDashboardSectionPriority { normal, high }

/// One configurable section on an [EdenRoleDashboardShell] grid.
///
/// Each section is a freeform [body] widget — callers fully control
/// content (lists, charts, summaries, whatever the vertical needs).
@immutable
class EdenDashboardSection {
  /// Creates a dashboard section.
  const EdenDashboardSection({
    required this.id,
    required this.title,
    required this.body,
    this.priority = EdenDashboardSectionPriority.normal,
    this.icon,
    this.onTap,
    this.badge,
  });

  /// Stable identifier (used for keys / tap callbacks).
  final String id;

  /// Heading text shown atop the section card.
  final String title;

  /// The section's content. Caller controls everything inside.
  final Widget body;

  /// When [high], the section is sorted to the top of the grid and renders
  /// a small action-needed strip across the top of the card.
  final EdenDashboardSectionPriority priority;

  /// Optional leading icon for the section header.
  final IconData? icon;

  /// Optional tap callback — when present, the entire card is tappable.
  final VoidCallback? onTap;

  /// Optional badge string (e.g. "3 new") rendered on the right side of
  /// the section header.
  final String? badge;
}

/// A role-specific home dashboard shell, used as the landing screen for
/// each user role across every Eden Biz vertical.
///
/// Layout responsive to width:
/// - Tablet+ (>=tabletBreakpoint): 2-col grid for sections, optional right
///   rail to the side.
/// - Narrow tablet (>=narrowBreakpoint, <tabletBreakpoint): 1-col stack
///   with right rail below.
/// - Phone (<narrowBreakpoint): 1-col stack; right rail collapses behind
///   a bottom-sheet trigger button.
///
/// Section bodies are freeform Widgets — caller controls content; library
/// supplies palette + spacing + responsive arrangement.
class EdenRoleDashboardShell extends StatelessWidget {
  /// Creates a role-dashboard shell.
  const EdenRoleDashboardShell({
    super.key,
    required this.greeting,
    required this.roleLabel,
    this.rolePalette = EdenRolePalette.neutral,
    this.avatar,
    this.notificationButton,
    required this.sections,
    this.rightRail,
    this.narrowBreakpoint = 480,
    this.tabletBreakpoint = 768,
  });

  /// Greeting line shown at top-left (e.g. "Good morning, Sarah").
  final String greeting;

  /// Role label rendered in the role-badge chip (e.g. "Dispatcher").
  final String roleLabel;

  /// Palette preset for the role badge background + foreground.
  final EdenRolePalette rolePalette;

  /// Optional avatar widget rendered top-right.
  final Widget? avatar;

  /// Optional notification button (typically an IconButton with a badge).
  final Widget? notificationButton;

  /// Configurable list of sections rendered in the main area.
  final List<EdenDashboardSection> sections;

  /// Optional right-rail widget (insights / quick stats / activity feed).
  final Widget? rightRail;

  /// Width below which sections stack 1-col + right rail collapses.
  final double narrowBreakpoint;

  /// Width above which the 2-col section grid + side rail is shown.
  final double tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final bool isPhone = width < narrowBreakpoint;
        final bool isTabletPlus = width >= tabletBreakpoint;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildHeader(context, isPhone: isPhone),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: _buildBody(
                  context,
                  isPhone: isPhone,
                  isTabletPlus: isTabletPlus,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isPhone}) {
    final (Color bg, Color fg) = _resolvePalette(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          if (avatar != null) ...<Widget>[
            avatar!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow:
                      isPhone ? TextOverflow.ellipsis : TextOverflow.visible,
                ),
                const SizedBox(height: 4),
                Container(
                  key: const ValueKey<String>('role_badge'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roleLabel,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (notificationButton != null) notificationButton!,
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isPhone,
    required bool isTabletPlus,
  }) {
    final sortedSections = <EdenDashboardSection>[...sections]..sort((a, b) {
        final av = a.priority == EdenDashboardSectionPriority.high ? 0 : 1;
        final bv = b.priority == EdenDashboardSectionPriority.high ? 0 : 1;
        return av.compareTo(bv);
      });

    // Build the grid of section cards.
    Widget grid;
    if (sortedSections.isEmpty) {
      grid = const SizedBox.shrink();
    } else if (isTabletPlus) {
      // 2-col grid via row pairs.
      final rows = <Widget>[];
      for (int i = 0; i < sortedSections.length; i += 2) {
        final left = sortedSections[i];
        final right = i + 1 < sortedSections.length
            ? sortedSections[i + 1]
            : null;
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildSectionCard(context, left)),
              const SizedBox(width: 12),
              Expanded(
                child: right != null
                    ? _buildSectionCard(context, right)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ));
      }
      grid = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      );
    } else {
      // 1-col stack.
      grid = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final s in sortedSections)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSectionCard(context, s),
            ),
        ],
      );
    }

    if (rightRail == null) return grid;

    if (isTabletPlus) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: 3, child: grid),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: KeyedSubtree(
              key: const ValueKey<String>('right_rail'),
              child: rightRail!,
            ),
          ),
        ],
      );
    }

    if (isPhone) {
      // Collapse into a bottom-sheet trigger.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          grid,
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              key: const ValueKey<String>('right_rail_trigger'),
              icon: const Icon(Icons.menu_open),
              label: const Text('Insights'),
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: rightRail!,
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Narrow tablet — render rail inline below grid.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        grid,
        const SizedBox(height: 12),
        KeyedSubtree(
          key: const ValueKey<String>('right_rail'),
          child: rightRail!,
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, EdenDashboardSection s) {
    final card = Card(
      key: ValueKey<String>('section_${s.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (s.priority == EdenDashboardSectionPriority.high)
            Container(
              key: ValueKey<String>('priority_strip_${s.id}'),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(
                'Action needed',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (s.icon != null) ...<Widget>[
                      Icon(s.icon, size: 18),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        s.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (s.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s.badge!,
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                s.body,
              ],
            ),
          ),
        ],
      ),
    );
    if (s.onTap == null) return card;
    return InkWell(
      key: ValueKey<String>('tap_${s.id}'),
      onTap: s.onTap,
      child: card,
    );
  }

  (Color bg, Color fg) _resolvePalette(BuildContext context) {
    switch (rolePalette) {
      case EdenRolePalette.trades:
        // Trades dispatcher / forefront — orange/red tier.
        return (const Color(0xFFFFEDD5), const Color(0xFF9A3412));
      case EdenRolePalette.salon:
        // Brand gold.
        return (const Color(0xFFF5E6B8), const Color(0xFF6B4D00));
      case EdenRolePalette.medical:
        // Clinical blue.
        return (const Color(0xFFDBEAFE), const Color(0xFF1E3A8A));
      case EdenRolePalette.fuel:
        // Hazard amber.
        return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
      case EdenRolePalette.retail:
        return (const Color(0xFFFCE7F3), const Color(0xFF831843));
      case EdenRolePalette.legal:
        return (const Color(0xFFE0E7FF), const Color(0xFF1E3A8A));
      case EdenRolePalette.gov:
        return (const Color(0xFFD1FAE5), const Color(0xFF064E3B));
      case EdenRolePalette.neutral:
        final scheme = Theme.of(context).colorScheme;
        return (scheme.surfaceContainerHighest, scheme.onSurfaceVariant);
    }
  }
}
