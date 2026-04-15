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

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  @override
  void didUpdateWidget(covariant EdenDesktopLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync collapse state when the parent forces a change (e.g. responsive resize).
    if (widget.initiallyCollapsed != oldWidget.initiallyCollapsed) {
      _collapsed = widget.initiallyCollapsed;
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
                        if (item.children.isNotEmpty) ...[
                          if (!_collapsed)
                            Padding(
                              key: item.widgetKey,
                              padding: const EdgeInsets.only(
                                left: 12, top: 16, bottom: 4,
                              ),
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
                        ] else
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
// Nav tile
// ---------------------------------------------------------------------------

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.collapsed,
    required this.onTap,
  });

  final EdenNavItem item;
  final bool isSelected;
  final bool collapsed;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
// Expandable nav tile (for 2-level nesting)
// ---------------------------------------------------------------------------

class _ExpandableNavTile extends StatelessWidget {
  const _ExpandableNavTile({
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
      key: item.widgetKey,
      onTap: onToggle,
      child: Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: isHighlighted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
