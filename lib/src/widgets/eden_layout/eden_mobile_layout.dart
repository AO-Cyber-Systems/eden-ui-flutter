import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import 'layout_data.dart';

/// Standard mobile layout with app bar, bottom navigation, and drawer.
///
/// ```
/// ┌──────────────────────────────────┐
/// │  App Bar (title, actions)        │
/// ├──────────────────────────────────┤
/// │                                  │
/// │  Content                         │
/// │                                  │
/// │                                  │
/// ├──────────────────────────────────┤
/// │  Bottom Nav (up to 5 items)      │
/// └──────────────────────────────────┘
/// ```
///
/// Overflow nav items (beyond 5) go into a "More" drawer.
class EdenMobileLayout extends StatelessWidget {
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
  });

  final List<EdenNavItem> navItems;
  final String selectedId;
  final ValueChanged<String> onNavChanged;
  final Widget body;
  final EdenTopBarConfig? topBar;
  final EdenLayoutUser? user;
  final Widget? logo;
  final Widget? floatingAction;
  final int maxBottomItems;

  /// Flatten grouped nav items for display.
  List<EdenNavItem> get _flatItems {
    final flat = <EdenNavItem>[];
    for (final item in navItems) {
      if (item.children.isNotEmpty) {
        flat.addAll(item.children);
      } else {
        flat.add(item);
      }
    }
    return flat;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flat = _flatItems;
    final showMore = flat.length > maxBottomItems;
    final bottomItems = showMore ? flat.take(maxBottomItems - 1).toList() : flat;
    final overflowItems = showMore ? flat.skip(maxBottomItems - 1).toList() : <EdenNavItem>[];
    final selectedIndex = bottomItems.indexWhere((i) => i.id == selectedId);
    final isOverflowSelected = selectedIndex == -1 && flat.any((i) => i.id == selectedId);

    return Scaffold(
      appBar: topBar != null
          ? _buildAppBar(context, theme)
          : null,
      drawer: _buildDrawer(context, theme, flat),
      body: body,
      floatingActionButton: floatingAction,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (final item in bottomItems)
                  _BottomItem(
                    item: item,
                    isSelected: item.id == selectedId,
                    onTap: () => onNavChanged(item.id),
                  ),
                if (showMore)
                  _BottomItem(
                    item: const EdenNavItem(
                      id: '__more__',
                      label: 'More',
                      icon: Icons.more_horiz,
                      semanticsIdentifier: 'eden-nav-more',
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
      leading: topBar!.leading ??
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
      title: topBar!.titleWidget ??
          (topBar!.title != null ? Text(topBar!.title!) : null),
      actions: [
        ...topBar!.actions,
        if (topBar!.trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: topBar!.trailing!,
          ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme, List<EdenNavItem> flat) {
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(EdenSpacing.space4),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (logo != null) logo!
                  else Text('Menu', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  if (user != null) ...[
                    const SizedBox(height: EdenSpacing.space4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: user!.initials != null
                              ? Text(user!.initials!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.primary))
                              : Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user!.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              if (user!.email != null)
                                Text(user!.email!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: EdenSpacing.space2, horizontal: EdenSpacing.space2),
                children: [
                  for (final group in navItems)
                    if (group.children.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                        child: Text(
                          group.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      for (final child in group.children)
                        _DrawerTile(
                          item: child,
                          isSelected: child.id == selectedId,
                          onTap: () {
                            onNavChanged(child.id);
                            Navigator.pop(context);
                          },
                        ),
                    ] else
                      _DrawerTile(
                        item: group,
                        isSelected: group.id == selectedId,
                        onTap: () {
                          onNavChanged(group.id);
                          Navigator.pop(context);
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, ThemeData theme, List<EdenNavItem> items) {
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
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
              ),
              for (final item in items)
                Semantics(
                  identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
                  button: true,
                  label: item.label,
                  selected: item.id == selectedId,
                  child: ListTile(
                    leading: Icon(
                      item.id == selectedId ? (item.activeIcon ?? item.icon) : item.icon,
                      color: item.id == selectedId ? theme.colorScheme.primary : null,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: item.id == selectedId ? FontWeight.w600 : FontWeight.w500,
                        color: item.id == selectedId ? theme.colorScheme.primary : null,
                      ),
                    ),
                    trailing: item.badge != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: EdenRadii.borderRadiusFull,
                            ),
                            child: Text(item.badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onNavChanged(item.id);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav item
// ---------------------------------------------------------------------------

class _BottomItem extends StatelessWidget {
  const _BottomItem({required this.item, required this.isSelected, required this.onTap});
  final EdenNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Semantics(
        identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
        button: true,
        label: item.label,
        selected: isSelected,
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
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                if (item.badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: EdenRadii.borderRadiusFull,
                      ),
                      child: Text(item.badge!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
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
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer tile
// ---------------------------------------------------------------------------

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({required this.item, required this.isSelected, required this.onTap});
  final EdenNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
      button: true,
      label: item.label,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : null,
            borderRadius: EdenRadii.borderRadiusMd,
          ),
          child: Row(
          children: [
            Icon(
              isSelected ? (item.activeIcon ?? item.icon) : item.icon,
              size: 20,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (item.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: EdenRadii.borderRadiusFull,
                ),
                child: Text(item.badge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
