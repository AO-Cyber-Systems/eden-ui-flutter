import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'layout_data.dart';

/// Standard mobile layout with app bar, bottom navigation, and drawer.
///
/// ```
/// +----------------------------------+
/// |  App Bar (title, actions)        |
/// +----------------------------------+
/// |                                  |
/// |  Content                         |
/// |                                  |
/// |                                  |
/// +----------------------------------+
/// |  Bottom Nav (up to 5 items)      |
/// +----------------------------------+
/// ```
///
/// When [bottomNavItems] is provided, those exact items are used for the
/// bottom nav bar (typically 5 items with a `__more__` sentinel). When null,
/// falls back to auto-flattening [navItems] for backward compatibility.
///
/// The `__more__` sentinel item auto-opens the drawer when tapped.
///
/// The drawer supports:
/// - Dividers between nav groups (via [EdenNavItem.isDivider])
/// - Expandable sub-menus for items with nested children
/// - Group headers rendered as uppercase section labels
class EdenMobileLayout extends StatefulWidget {
  const EdenMobileLayout({
    super.key,
    required this.navItems,
    required this.selectedId,
    required this.onNavChanged,
    required this.body,
    this.topBar,
    this.user,
    this.logo,
    this.floatingAction,
    this.maxBottomItems = 5,
    this.bottomNavItems,
  });

  /// Full grouped navigation items for the drawer.
  final List<EdenNavItem> navItems;

  /// Currently selected nav item ID.
  final String selectedId;

  /// Callback when a nav item is selected.
  final ValueChanged<String> onNavChanged;

  /// Main content body.
  final Widget body;

  /// Top bar configuration.
  final EdenTopBarConfig? topBar;

  /// User info for drawer header.
  final EdenLayoutUser? user;

  /// Logo widget for drawer header.
  final Widget? logo;

  /// Optional FAB.
  final Widget? floatingAction;

  /// Max items in bottom nav (only used when [bottomNavItems] is null).
  final int maxBottomItems;

  /// Explicit bottom nav items. When provided, these are used instead of
  /// auto-flattening [navItems]. Include an item with id `__more__` to
  /// auto-open the drawer.
  final List<EdenNavItem>? bottomNavItems;

  @override
  State<EdenMobileLayout> createState() => _EdenMobileLayoutState();
}

class _EdenMobileLayoutState extends State<EdenMobileLayout> {
  final Set<String> _expandedDrawerIds = {};

  /// Flatten grouped nav items for display (legacy behavior).
  List<EdenNavItem> get _flatItems {
    final flat = <EdenNavItem>[];
    for (final item in widget.navItems) {
      if (item.isDivider) continue;
      if (item.children.isNotEmpty) {
        flat.addAll(item.children);
      } else {
        flat.add(item);
      }
    }
    return flat;
  }

  /// Check if any descendant is selected.
  bool _isAnyDescendantSelected(EdenNavItem item) {
    for (final child in item.children) {
      if (child.id == widget.selectedId) return true;
      if (child.children.isNotEmpty && _isAnyDescendantSelected(child)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine bottom nav items
    final List<EdenNavItem> bottomItems;
    final bool hasMore;
    final List<EdenNavItem> overflowItems;

    if (widget.bottomNavItems != null) {
      // Explicit bottom nav items -- use as-is
      bottomItems = widget.bottomNavItems!;
      hasMore = bottomItems.any((i) => i.id == '__more__');
      overflowItems = const [];
    } else {
      // Legacy: auto-flatten
      final flat = _flatItems;
      final showMore = flat.length > widget.maxBottomItems;
      bottomItems = showMore
          ? flat.take(widget.maxBottomItems - 1).toList()
          : flat;
      overflowItems = showMore
          ? flat.skip(widget.maxBottomItems - 1).toList()
          : <EdenNavItem>[];
      hasMore = showMore;
    }

    final selectedIndex = bottomItems.indexWhere((i) => i.id == widget.selectedId);
    final isOverflowSelected = selectedIndex == -1 &&
        (widget.bottomNavItems != null
            ? true // When using explicit items, "More" highlights if selected isn't in bottom
            : _flatItems.any((i) => i.id == widget.selectedId));

    return Scaffold(
      appBar: widget.topBar != null ? _buildAppBar(context, theme) : null,
      drawer: _buildDrawer(context, theme),
      body: widget.body,
      floatingActionButton: widget.floatingAction,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (final item in bottomItems)
                  if (item.id == '__more__')
                    _BottomItem(
                      item: item,
                      isSelected: isOverflowSelected,
                      onTap: () {
                        // Auto-open the drawer for __more__
                        Scaffold.of(context).openDrawer();
                      },
                    )
                  else
                    _BottomItem(
                      item: item,
                      isSelected: item.id == widget.selectedId,
                      onTap: () => widget.onNavChanged(item.id),
                    ),
                // Legacy "More" for auto-flatten mode
                if (hasMore && widget.bottomNavItems == null)
                  _BottomItem(
                    item: const EdenNavItem(
                      id: '__more__',
                      label: 'More',
                      icon: Icons.more_horiz,
                    ),
                    isSelected: isOverflowSelected,
                    onTap: () => _showMoreSheet(context, theme, overflowItems),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      leading: widget.topBar!.leading ??
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
      title: widget.topBar!.titleWidget ??
          (widget.topBar!.title != null ? Text(widget.topBar!.title!) : null),
      actions: [
        ...widget.topBar!.actions,
        if (widget.topBar!.trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: widget.topBar!.trailing!,
          ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _DrawerHeader(logo: widget.logo, user: widget.user),
            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: EdenSpacing.space2,
                  horizontal: EdenSpacing.space2,
                ),
                children: _buildDrawerItems(context, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context, ThemeData theme) {
    final widgets = <Widget>[];

    for (final item in widget.navItems) {
      // Divider
      if (item.isDivider) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Divider(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        );
        continue;
      }

      // Leaf item (no children)
      if (item.children.isEmpty) {
        widgets.add(
          _DrawerTile(
            item: item,
            isSelected: item.id == widget.selectedId,
            onTap: () {
              widget.onNavChanged(item.id);
              Navigator.pop(context);
            },
          ),
        );
        continue;
      }

      // Group with children: render group header + children
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
          child: Text(
            item.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

      for (final child in item.children) {
        if (child.children.isNotEmpty) {
          // Expandable sub-menu
          final isExpanded = _expandedDrawerIds.contains(child.id);
          final isChildSelected = _isAnyDescendantSelected(child);

          widgets.add(
            _ExpandableDrawerTile(
              item: child,
              isExpanded: isExpanded,
              isAnyChildSelected: isChildSelected,
              onToggle: () {
                setState(() {
                  if (_expandedDrawerIds.contains(child.id)) {
                    _expandedDrawerIds.remove(child.id);
                  } else {
                    _expandedDrawerIds.add(child.id);
                  }
                });
              },
            ),
          );

          if (isExpanded) {
            for (final sub in child.children) {
              widgets.add(
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: _DrawerTile(
                    item: sub,
                    isSelected: sub.id == widget.selectedId,
                    onTap: () {
                      widget.onNavChanged(sub.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            }
          }
        } else {
          // Regular leaf child
          widgets.add(
            _DrawerTile(
              item: child,
              isSelected: child.id == widget.selectedId,
              onTap: () {
                widget.onNavChanged(child.id);
                Navigator.pop(context);
              },
            ),
          );
        }
      }
    }

    return widgets;
  }

  void _showMoreSheet(
    BuildContext context,
    ThemeData theme,
    List<EdenNavItem> items,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: EdenSpacing.space3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
              ),
              for (final item in items)
                ListTile(
                  leading: Icon(
                    item.id == widget.selectedId
                        ? (item.activeIcon ?? item.icon)
                        : item.icon,
                    color: item.id == widget.selectedId
                        ? theme.colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: item.id == widget.selectedId
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: item.id == widget.selectedId
                          ? theme.colorScheme.primary
                          : null,
                    ),
                  ),
                  trailing: item.badge != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: EdenRadii.borderRadiusFull,
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onNavChanged(item.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer header
// ---------------------------------------------------------------------------

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({this.logo, this.user});
  final Widget? logo;
  final EdenLayoutUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EdenSpacing.space4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (logo != null)
            logo!
          else
            Text(
              'Menu',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          if (user != null) ...[
            const SizedBox(height: EdenSpacing.space4),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: user!.initials != null
                      ? Text(
                          user!.initials!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : Icon(Icons.person,
                          size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user!.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (user!.email != null)
                        Text(
                          user!.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav item
// ---------------------------------------------------------------------------

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final EdenNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                  size: 22,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (item.badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: EdenRadii.borderRadiusFull,
                      ),
                      child: Text(
                        item.badge!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer tile
// ---------------------------------------------------------------------------

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final EdenNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : null,
          borderRadius: EdenRadii.borderRadiusMd,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (item.badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Text(
                  item.badge!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expandable drawer tile (for nested sub-menus)
// ---------------------------------------------------------------------------

class _ExpandableDrawerTile extends StatelessWidget {
  const _ExpandableDrawerTile({
    required this.item,
    required this.isExpanded,
    required this.isAnyChildSelected,
    required this.onToggle,
  });

  final EdenNavItem item;
  final bool isExpanded;
  final bool isAnyChildSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHighlighted = isAnyChildSelected;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        height: 44,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
          borderRadius: EdenRadii.borderRadiusMd,
        ),
        child: Row(
          children: [
            Icon(
              isHighlighted ? (item.activeIcon ?? item.icon) : item.icon,
              size: 20,
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
