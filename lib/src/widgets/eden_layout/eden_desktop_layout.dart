import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'layout_data.dart';

/// Standard desktop/web layout with collapsible sidebar, top bar, and content area.
///
/// ```
/// ┌──────────┬──────────────────────────────────┐
/// │          │  Top Bar                          │
/// │  Side    ├──────────────────────────────────│
/// │  bar     │                                  │
/// │          │  Content                          │
/// │          │                                  │
/// │          │                                  │
/// │──────────│                                  │
/// │  User    │                                  │
/// └──────────┴──────────────────────────────────┘
/// ```
class EdenDesktopLayout extends StatefulWidget {
  const EdenDesktopLayout({
    super.key,
    required this.navItems,
    required this.selectedId,
    required this.onNavChanged,
    required this.body,
    this.topBar,
    this.globalTopBar,
    this.user,
    this.logo,
    this.collapsedLogo,
    this.initiallyCollapsed = false,
    this.sidebarWidth = 260,
    this.collapsedWidth = 72,
    this.sidebarFooter,
    this.supportPanel,
  });

  final List<EdenNavItem> navItems;
  final String selectedId;
  final ValueChanged<String> onNavChanged;
  final Widget body;
  final EdenTopBarConfig? topBar;
  /// Full-width bar rendered above the sidebar + content row.
  final Widget? globalTopBar;
  final EdenLayoutUser? user;
  final Widget? logo;
  final Widget? collapsedLogo;
  final bool initiallyCollapsed;
  final double sidebarWidth;
  final double collapsedWidth;
  final Widget? sidebarFooter;

  /// Optional support panel rendered in the Row after the main content area.
  ///
  /// Pass an [EdenSupportPanel] configured in slot mode (no child required):
  /// ```dart
  /// EdenDesktopLayout(
  ///   supportPanel: EdenSupportPanel(config: myCfg),
  ///   body: myBody,
  ///   ...
  /// )
  /// ```
  final Widget? supportPanel;

  @override
  State<EdenDesktopLayout> createState() => _EdenDesktopLayoutState();
}

class _EdenDesktopLayoutState extends State<EdenDesktopLayout> {
  late bool _collapsed;

  /// Ids of expandable groups currently disclosed. Owned here, exactly as
  /// [_collapsed] is: seeded in [initState] from the widget, re-synced in
  /// [didUpdateWidget] when the parent forces a change. Expansion is a view
  /// gesture, not a consumer-held selection, so there is no callback out.
  late Set<String> _expandedGroupIds;

  /// Every expandable group in [items], mapped to the seed it is asking for.
  /// A map, not a set of the true ones: the difference between "this group
  /// wants to be closed" and "this group is not here any more" is the whole
  /// point of [_syncExpansion].
  static Map<String, bool> _seedMap(List<EdenNavItem> items) => {
        for (final item in items)
          if (item.expandable) item.id: item.initiallyExpanded,
      };

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
    _expandedGroupIds = {
      for (final e in _seedMap(widget.navItems).entries)
        if (e.value) e.key,
    };
  }

  @override
  void didUpdateWidget(covariant EdenDesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync collapse state when the parent forces a change (e.g. responsive resize).
    if (widget.initiallyCollapsed != oldWidget.initiallyCollapsed) {
      _collapsed = widget.initiallyCollapsed;
    }
    // Same contract for expansion, but applied PER ID. Comparing whole seed
    // sets and assigning wholesale meant that any group arriving with a changed
    // seed re-derived every other group too — so a group the user had just
    // closed sprang back open under the cursor. Consumers that rebuild
    // navItems from live data (aodex's PROJECTS) hit that on every refresh.
    _syncExpansion(oldWidget.navItems, widget.navItems);
  }

  /// Reconciles [_expandedGroupIds] against a new [newItems] list.
  ///
  /// Two rules, in order:
  ///  1. Prune — an id whose group is gone is dropped, so a group that is
  ///     deleted and later re-added does not resurrect an old disclosure.
  ///  2. Diff — only ids whose OWN `initiallyExpanded` actually changed are
  ///     re-derived from the seed. Every other id keeps whatever the user last
  ///     gestured. A group that is new to the list has no previous seed, so its
  ///     seed is what it asks for.
  void _syncExpansion(List<EdenNavItem> oldItems, List<EdenNavItem> newItems) {
    final oldSeeds = _seedMap(oldItems);
    final newSeeds = _seedMap(newItems);

    _expandedGroupIds.removeWhere((id) => !newSeeds.containsKey(id));

    for (final entry in newSeeds.entries) {
      if (oldSeeds[entry.key] == entry.value) continue;
      if (entry.value) {
        _expandedGroupIds.add(entry.key);
      } else {
        _expandedGroupIds.remove(entry.key);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sideW = _collapsed ? widget.collapsedWidth : widget.sidebarWidth;

    return Scaffold(
      body: Column(
        children: [
          if (widget.globalTopBar != null) widget.globalTopBar!,
          Expanded(
            child: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: sideW,
            decoration: BoxDecoration(
              color: isDark ? EdenColors.neutral[900] : Colors.white,
              border: Border(
                right: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                // Logo / collapse toggle
                _SidebarHeader(
                  logo: widget.logo,
                  collapsedLogo: widget.collapsedLogo,
                  collapsed: _collapsed,
                  onToggle: () => setState(() => _collapsed = !_collapsed),
                ),
                Divider(height: 1, color: theme.colorScheme.outlineVariant),
                // Nav items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: _collapsed ? 8 : EdenSpacing.space3,
                      vertical: EdenSpacing.space2,
                    ),
                    children: [
                      for (final item in widget.navItems) ...[
                        // Non-interactive items first. Both are skipped in the
                        // 72px rail: a rule or a 10px shouted word in an icon
                        // column is noise (D5 — the collapsed rail is icons).
                        if (item.isDivider) ...[
                          if (!_collapsed)
                            Padding(
                              key: item.widgetKey,
                              padding: const EdgeInsets.symmetric(
                                vertical: EdenSpacing.space2,
                              ),
                              child: Divider(
                                height: 1,
                                thickness: 1,
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                        ] else if (item.isCaption) ...[
                          if (!_collapsed)
                            _NavSectionLabel(key: item.widgetKey, label: item.label),
                        ] else if (item.children.isNotEmpty) ...[
                          if (!_collapsed && item.expandable) ...[
                            _ExpandableNavHeader(
                              key: item.widgetKey,
                              item: item,
                              expanded: _expandedGroupIds.contains(item.id),
                              // A CLOSED group stands in for the selected child
                              // it is hiding — otherwise a selection inside a
                              // closed group leaves the whole sidebar with no
                              // selection anywhere. Same substitution the 72px
                              // rail already makes below, and for the same
                              // reason: the child row is not on screen. Once
                              // OPEN the child paints its own highlight, so the
                              // header stops borrowing it.
                              isSelected: item.id == widget.selectedId ||
                                  (!_expandedGroupIds.contains(item.id) &&
                                      item.children.any(
                                          (c) => c.id == widget.selectedId)),
                              onTap: () {
                                final willExpand =
                                    !_expandedGroupIds.contains(item.id);
                                setState(() {
                                  if (willExpand) {
                                    _expandedGroupIds.add(item.id);
                                  } else {
                                    _expandedGroupIds.remove(item.id);
                                  }
                                });
                                // Report the GROUP's own id — never
                                // children.first.id as the collapsed branch
                                // below does. A consumer must be able to scope
                                // on the same tap that discloses (aodex's
                                // PROJECTS header), and it cannot do that if it
                                // can't tell a group tap from a child tap.
                                //
                                // But only on the EXPAND half. Closing a group
                                // is tidying the sidebar; firing there yanked
                                // the user back to the group they were putting
                                // away, from wherever they actually were.
                                if (willExpand) widget.onNavChanged(item.id);
                              },
                            ),
                            if (_expandedGroupIds.contains(item.id))
                              for (final child in item.children)
                                _NavTile(
                                  item: child,
                                  isSelected: child.id == widget.selectedId,
                                  collapsed: _collapsed,
                                  // Line the child's icon up UNDER its header's
                                  // icon. Indented less than the header, an
                                  // expanded group read as a heading followed
                                  // by unrelated top-level rows.
                                  indent: _kExpandableChildIndent,
                                  onTap: () => widget.onNavChanged(child.id),
                                ),
                          ] else ...[
                            if (!_collapsed)
                              Padding(
                                key: item.widgetKey,
                                padding: _kNavSectionLabelPadding,
                                child: Text(
                                  item.label.toUpperCase(),
                                  style: _navSectionLabelStyle(theme),
                                ),
                              ),
                            if (!_collapsed)
                              for (final child in item.children)
                                _NavTile(
                                  item: child,
                                  isSelected: child.id == widget.selectedId,
                                  collapsed: _collapsed,
                                  onTap: () => widget.onNavChanged(child.id),
                                )
                            else
                              // Collapsed: render parent icon but use first child's
                              // ID for navigation and selection matching.
                              _NavTile(
                                item: EdenNavItem(
                                  id: item.children.first.id,
                                  label: item.label,
                                  icon: item.icon,
                                  activeIcon: item.activeIcon ?? item.children.first.activeIcon,
                                  badge: item.children.first.badge,
                                ),
                                isSelected: item.children.any((c) => c.id == widget.selectedId),
                                collapsed: _collapsed,
                                onTap: () => widget.onNavChanged(item.children.first.id),
                              ),
                          ],
                        ] else
                          // Leaf, INCLUDING an `expandable` group whose children
                          // list is empty: no children means no disclosure, so
                          // the chevron is ABSENT rather than inert and the item
                          // renders exactly as it does today. aodex's PROJECTS
                          // on a fresh account lands here (BCP-R8).
                          _NavTile(
                            item: item,
                            isSelected: item.id == widget.selectedId,
                            collapsed: _collapsed,
                            onTap: () => widget.onNavChanged(item.id),
                          ),
                      ],
                    ],
                  ),
                ),
                // Footer
                if (widget.sidebarFooter != null) ...[
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  widget.sidebarFooter!,
                ] else if (widget.user != null) ...[
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                  _UserTile(user: widget.user!, collapsed: _collapsed),
                ],
              ],
            ),
          ),
          // Main area
          Expanded(
            child: Column(
              children: [
                if (widget.topBar != null)
                  _TopBar(config: widget.topBar!, onMenuTap: null),
                Expanded(child: widget.body),
              ],
            ),
          ),
          // Optional support panel slot — rendered after main content area.
          // EdenSupportPanel manages its own open/close state and AnimatedContainer
          // width, so the layout does not need to track panel state.
          if (widget.supportPanel != null) widget.supportPanel!,
        ],
      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar header
// ---------------------------------------------------------------------------

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    this.logo,
    this.collapsedLogo,
    required this.collapsed,
    required this.onToggle,
  });

  final Widget? logo;
  final Widget? collapsedLogo;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (collapsed) {
      return Semantics(
        button: true,
        label: 'Expand sidebar',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onToggle,
          child: SizedBox(
            height: 56,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                collapsedLogo ?? logo ?? Icon(Icons.apps, color: theme.colorScheme.primary),
                const SizedBox(height: 2),
                Icon(Icons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
        child: Row(
          children: [
            logo ?? Text('App', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Collapse sidebar',
              child: GestureDetector(
                onTap: onToggle,
                child: Icon(Icons.menu_open, size: 20, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav row geometry
// ---------------------------------------------------------------------------

/// Horizontal inset of a plain [_NavTile].
const double _kNavTileHorizontalPadding = 12;

/// The chevron column an [_ExpandableNavHeader] carries and a [_NavTile] does
/// not: a leading pad, the chevron itself, and the gap after it.
const double _kExpandableHeaderLeftPadding = 4;
const double _kExpandableChevronSize = 18;
const double _kExpandableChevronGap = 4;

/// How much further a disclosed child indents so its icon lands under its own
/// header's icon rather than under the header's chevron. Derived, not a magic
/// 14, so it cannot drift away from the header if the chevron column changes.
const double _kExpandableChildIndent = _kExpandableHeaderLeftPadding +
    _kExpandableChevronSize +
    _kExpandableChevronGap -
    _kNavTileHorizontalPadding;

// ---------------------------------------------------------------------------
// Section label (shared by the static group header and EdenNavItem.caption)
// ---------------------------------------------------------------------------

const EdgeInsets _kNavSectionLabelPadding =
    EdgeInsets.only(left: 12, top: 16, bottom: 4);

TextStyle _navSectionLabelStyle(ThemeData theme) => TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.8,
      color: theme.colorScheme.onSurfaceVariant,
    );

/// A passive band. No tap target, no icon, no `button: true` — a screen reader
/// must not offer it as an action. Shares its style with the static group
/// header above so a consumer's caption sits pixel-consistent beside it.
class _NavSectionLabel extends StatelessWidget {
  const _NavSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _kNavSectionLabelPadding,
      child: Text(
        label.toUpperCase(),
        style: _navSectionLabelStyle(Theme.of(context)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable group header
// ---------------------------------------------------------------------------

/// Disclosure header for a group with `expandable: true`.
///
/// Sentence case, not the shouted uppercase of the static band: a row the user
/// can act on should not look like a passive heading.
class _ExpandableNavHeader extends StatelessWidget {
  const _ExpandableNavHeader({
    super.key,
    required this.item,
    required this.expanded,
    required this.isSelected,
    required this.onTap,
  });

  final EdenNavItem item;
  final bool expanded;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    // One semantics node for the whole header: `expanded` is the property the
    // screen reader and the E2E tooling key on, and a competing label from the
    // child Text would split it into two nodes. The chevron, icon and badge are
    // decorative here — the count is folded into the label instead.
    return Semantics(
      identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
      button: true,
      expanded: expanded,
      selected: isSelected,
      label: item.badge == null ? item.label : '${item.label}, ${item.badge}',
      // The action has to live HERE, not on the GestureDetector: the
      // ExcludeSemantics below deliberately drops the child subtree (so the
      // chevron, icon, label and badge do not split into competing nodes), and
      // it drops the GestureDetector's SemanticsAction.tap with them. Without
      // this the node announces `button: true`, a reader double-taps, and
      // nothing happens — the children become permanently unreachable.
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.only(
              left: _kExpandableHeaderLeftPadding,
              right: _kNavTileHorizontalPadding,
            ),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
              borderRadius: EdenRadii.borderRadiusMd,
            ),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: _kExpandableChevronSize,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: _kExpandableChevronGap),
                Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 20,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: fg,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // A count belongs to the header, not to a phantom child row.
                if (item.badge != null) _Badge(text: item.badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nav tile
// ---------------------------------------------------------------------------

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
    this.indent = 0,
  });

  final EdenNavItem item;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback onTap;

  /// Extra left inset. Non-zero only for the children of a disclosed group, so
  /// every other caller keeps its exact original geometry.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final icon = Icon(
      isSelected ? (item.activeIcon ?? item.icon) : item.icon,
      size: 20,
      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
    );

    if (collapsed) {
      return Semantics(
        identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
        button: true,
        label: item.label,
        selected: isSelected,
        child: Tooltip(
          message: item.label,
          preferBelow: false,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 44,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
                borderRadius: EdenRadii.borderRadiusMd,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  icon,
                  if (item.badge != null)
                    Positioned(
                      top: 6,
                      right: 10,
                      child: _Badge(text: item.badge!),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
      button: true,
      label: item.label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          margin: const EdgeInsets.only(bottom: 2),
          padding: EdgeInsets.only(
            left: _kNavTileHorizontalPadding + indent,
            right: _kNavTileHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
            borderRadius: EdenRadii.borderRadiusMd,
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badge != null) _Badge(text: item.badge!),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User tile
// ---------------------------------------------------------------------------

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.collapsed});
  final EdenLayoutUser user;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatar = CircleAvatar(
      radius: collapsed ? 16 : 18,
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: user.initials != null
          ? Text(
              user.initials!,
              style: TextStyle(
                fontSize: collapsed ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            )
          : Icon(Icons.person, size: collapsed ? 16 : 18, color: theme.colorScheme.primary),
    );

    return Semantics(
      identifier: 'eden-topbar-user-menu',
      button: user.onTap != null,
      label: 'User profile: ${user.name}',
      child: GestureDetector(
        onTap: user.onTap,
        child: Padding(
          padding: EdgeInsets.all(collapsed ? 12 : EdenSpacing.space3),
        child: collapsed
            ? Center(child: avatar)
            : Row(
                children: [
                  avatar,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.config, this.onMenuTap});
  final EdenTopBarConfig config;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          if (onMenuTap != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Semantics(
                button: true,
                label: 'Open menu',
                child: GestureDetector(
                  onTap: onMenuTap,
                  child: Icon(Icons.menu, size: 22, color: theme.colorScheme.onSurface),
                ),
              ),
            ),
          if (config.leading != null) config.leading!,
          if (config.titleWidget != null)
            config.titleWidget!
          else if (config.title != null)
            Text(config.title!, style: theme.textTheme.titleMedium),
          if (config.showSearch) ...[
            const SizedBox(width: EdenSpacing.space4),
            Flexible(
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        identifier: 'eden-topbar-search',
                        textField: true,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: config.searchHint,
                            hintStyle: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: config.onSearch,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: EdenSpacing.space3),
          ] else
            const Spacer(),
          ...config.actions,
          if (config.trailing != null) ...[
            const SizedBox(width: 8),
            config.trailing!,
          ],
        ],
      ),
    );
  }
}
