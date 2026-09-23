import 'package:flutter/material.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_selectable_region.dart';
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
///
/// ## Text selection — OPT-IN since eden-ui-flutter#33
///
/// [body] is NOT wrapped in an [EdenSelectableRegion] unless you pass
/// `selectableBody: true`. The default used to be `true`; it was flipped
/// because a `SelectionArea` over a subtree containing a Navigator asserts on
/// deep-link to a nested route (flutter#151536, fix flutter#184900 unmerged),
/// and every go_router shell app has a Navigator in [body]. See the
/// [selectableBody] dartdoc for the full reason.
///
/// When you do opt in, only [body] is wrapped: sidebar, top bar, nav items and
/// the bottom bar are chrome, not data, so a drag-select cannot pick up
/// navigation labels.
///
/// Not using an Eden layout? You can install one region app-wide with
/// `MaterialApp.builder` — but **only if the app has no Navigator under it**,
/// which for a `MaterialApp` is almost never true. This recipe carries exactly
/// the same flutter#151536 exposure as `selectableBody: true`, so prefer
/// wrapping the specific text subtree instead:
/// ```dart
/// // Safe: scoped to content that is not a Navigator.
/// EdenSelectableRegion(child: MyArticleBody())
///
/// // Exposed to flutter#151536 — a Navigator lives under `child`:
/// // MaterialApp(
/// //   builder: (context, child) =>
/// //       EdenSelectableRegion(child: child ?? const SizedBox.shrink()),
/// //   home: MyHomePage(),
/// // )
/// ```
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
    this.selectableBody = false,
    this.itemBuilder,
    this.sectionBuilder,
  });

  /// Renders one nav row in place of the built-in renderer; return `null` for
  /// a row to keep the default treatment.
  ///
  /// The same slot as [EdenDesktopLayout.itemBuilder], with the same rules:
  /// composition over flags, one path (the default renderer is the fallback,
  /// never a branch), and the `eden-nav-<id>` semantics identifier plus the
  /// `button`/`label`/`selected` annotations and the tap action applied by the
  /// layout OUTSIDE this builder's result — exactly one semantics node per
  /// row, whoever rendered it.
  ///
  /// It is consulted for bottom-bar tabs, drawer tiles and "More"-sheet rows.
  /// It is NOT consulted for captions or dividers in the bottom bar, because
  /// the bar never renders those at all (see [maxBottomItems] and
  /// `_flatItems`) — the exclusion is the layout's rule, not the renderer's,
  /// so a consumer builder cannot smuggle a decoration into the bar.
  final EdenNavItemBuilder? itemBuilder;

  /// Renders a caption or divider row in place of the built-in treatment;
  /// return `null` to keep the default. Sections are non-interactive and carry
  /// no semantics identifier, in either path.
  ///
  /// Only the DRAWER has sections — the bottom bar excludes them by design.
  final EdenNavSectionBuilder? sectionBuilder;

  final List<EdenNavItem> navItems;
  final String selectedId;
  final ValueChanged<String> onNavChanged;
  final Widget body;
  final EdenTopBarConfig? topBar;
  final EdenLayoutUser? user;
  final Widget? logo;
  final Widget? floatingAction;
  final int maxBottomItems;

  /// Wraps [body] in an [EdenSelectableRegion] so its text is drag-selectable
  /// and copyable.
  ///
  /// **Defaults to `false` — opt in.** A `SelectionArea` over a subtree
  /// containing a Navigator asserts when a nested route is deep-linked:
  /// `SelectionArea`'s `_compareScreenOrder` calls `getTransformTo` on a
  /// covered page that has never been laid out (flutter#151536; the fix,
  /// flutter#184900, is unmerged). Every go_router shell app has a Navigator
  /// in [body]. Measured in aodex#611: six routing tests red, and aodex took
  /// the `selectableBody: false` opt-out by hand. eden-ui-flutter#33.
  ///
  /// Opt in with `selectableBody: true` on surfaces whose [body] is NOT a
  /// Navigator, or wrap the specific text subtree in an [EdenSelectableRegion]
  /// yourself.
  ///
  /// Only [body] is ever wrapped. Sidebar, top bar, nav items and the bottom
  /// bar are chrome, not data, and stay outside the region so a drag-select
  /// cannot pick up navigation labels.
  final bool selectableBody;

  // -------------------------------------------------------------------------
  // The single point at which a nav row is emitted (TRD 23-06 Task 1, mobile)
  // -------------------------------------------------------------------------

  /// Emits ONE nav row — bottom-bar tab, drawer tile or "More"-sheet row.
  ///
  /// This is the only place the mobile layout publishes a row's semantics. The
  /// `Semantics` wrapper is applied UNIFORMLY here — the same node for the
  /// built-in renderer's result and for a consumer [itemBuilder]'s result —
  /// which is why [_BottomItem] and [_DrawerTile] no longer annotate anything
  /// themselves. Exactly one semantics node per row, whoever rendered it.
  ///
  /// (Annotating in both places would nest two `Semantics` widgets, and a
  /// nested `Semantics` without `container: true` is not published at all on
  /// Flutter 3.41 — its annotations merge upward and the parent's identifier
  /// wins. Stripping the private renderers is what keeps the identifier
  /// addressable.)
  Widget _navRow({
    required BuildContext context,
    required EdenNavItem item,
    required EdenNavItemState state,
    required Widget Function() defaultRenderer,
    VoidCallback? onTap,
  }) {
    // One path, with a default builder — never a branch on whether a consumer
    // supplied one. A builder that returns null declines THIS row and the
    // default renders it.
    final EdenNavItemBuilder build = itemBuilder ?? (_, __, ___) => null;
    final child = build(context, item, state) ?? defaultRenderer();
    return Semantics(
      identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
      button: true,
      label: item.label,
      selected: state.isSelected,
      onTap: onTap,
      child: child,
    );
  }

  /// Emits one non-interactive drawer section (caption, divider or a group's
  /// uppercase band). Sections carry no identifier and no button semantics in
  /// either path — same as today.
  Widget _navSection({
    required BuildContext context,
    required EdenNavItem item,
    required Widget Function() defaultRenderer,
  }) {
    final EdenNavSectionBuilder build = sectionBuilder ?? (_, __) => null;
    return build(context, item) ?? defaultRenderer();
  }

  /// The overflow tab. Not a destination — tapping it opens the "More" sheet.
  /// Extracted only so the emission point and the default renderer are handed
  /// the same item; unchanged behaviour.
  static const EdenNavItem _moreItem = EdenNavItem(
    id: '__more__',
    label: 'More',
    icon: Icons.more_horiz,
    semanticsIdentifier: 'eden-nav-more',
  );

  /// Flatten grouped nav items into the list of real DESTINATIONS.
  ///
  /// Captions and dividers are decorations of the desktop rail, not routes:
  /// their ids (`__caption__`, `__divider__`) match nothing a consumer can
  /// navigate to. Rendering them as tabs fired onNavChanged with a dead id AND
  /// consumed [maxBottomItems] slots, pushing real destinations into overflow.
  /// Consumers share one navItems list across both layouts, so the bar has to
  /// understand everything the rail does.
  List<EdenNavItem> get _flatItems {
    final flat = <EdenNavItem>[];
    for (final item in navItems) {
      if (item.isDivider || item.isCaption) continue;
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
      body: selectableBody ? EdenSelectableRegion(child: body) : body,
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
                // bottomItems comes from _flatItems, which has ALREADY dropped
                // every caption and divider. The exclusion therefore happens
                // before the emission point, so a consumer itemBuilder is
                // never even offered a decoration — the rule is the layout's,
                // not the renderer's (TRD 23-06 cases 10-11).
                for (final item in bottomItems)
                  Expanded(
                    child: _navRow(
                      context: context,
                      item: item,
                      state: EdenNavItemState(isSelected: item.id == selectedId),
                      onTap: () => onNavChanged(item.id),
                      defaultRenderer: () => _BottomItem(
                        item: item,
                        isSelected: item.id == selectedId,
                        onTap: () => onNavChanged(item.id),
                      ),
                    ),
                  ),
                if (showMore)
                  Expanded(
                    child: _navRow(
                      context: context,
                      item: _moreItem,
                      state: EdenNavItemState(isSelected: isOverflowSelected),
                      onTap: () =>
                          _showMoreSheet(context, theme, overflowItems),
                      defaultRenderer: () => _BottomItem(
                        item: _moreItem,
                        isSelected: isOverflowSelected,
                        onTap: () =>
                            _showMoreSheet(context, theme, overflowItems),
                      ),
                    ),
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
            // `tooltip` is the semantic LABEL here, not decoration: without it
            // this is a 56x56 tappable node with no name at all — a screen
            // reader announces "button" and nothing else, and the drawer is
            // the only route to every overflow destination. Caught by
            // expectUiSane's tappable-label guideline the first time the
            // mobile shell was pumped through the oracle (TRD 23-05 defect 3).
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open navigation menu',
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

  /// The drawer's uppercase section band. One definition, shared by a group
  /// header and by an [EdenNavItem.caption] — two copies of the literals would
  /// drift.
  static Widget _drawerSectionLabel(ThemeData theme, String label) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );

  Widget _buildDrawer(BuildContext context, ThemeData theme, List<EdenNavItem> flat) {
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
                    // Decorations keep their meaning in the drawer, where there
                    // is room for them — a rule stays a rule and a caption
                    // stays the same uppercase band a group header already
                    // draws. Neither becomes a tappable row.
                    if (group.isDivider)
                      _navSection(
                        context: context,
                        item: group,
                        defaultRenderer: () => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: EdenSpacing.space2,
                          ),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      )
                    else if (group.isCaption)
                      _navSection(
                        context: context,
                        item: group,
                        defaultRenderer: () =>
                            _drawerSectionLabel(theme, group.label),
                      )
                    else if (group.children.isNotEmpty) ...[
                      _navSection(
                        context: context,
                        item: group,
                        defaultRenderer: () =>
                            _drawerSectionLabel(theme, group.label),
                      ),
                      for (final child in group.children)
                        _navRow(
                          context: context,
                          item: child,
                          state: EdenNavItemState(
                            isSelected: child.id == selectedId,
                            depth: 1,
                          ),
                          onTap: () {
                            onNavChanged(child.id);
                            Navigator.pop(context);
                          },
                          defaultRenderer: () => _DrawerTile(
                            item: child,
                            isSelected: child.id == selectedId,
                            onTap: () {
                              onNavChanged(child.id);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                    ] else
                      _navRow(
                        context: context,
                        item: group,
                        state:
                            EdenNavItemState(isSelected: group.id == selectedId),
                        onTap: () {
                          onNavChanged(group.id);
                          Navigator.pop(context);
                        },
                        defaultRenderer: () => _DrawerTile(
                          item: group,
                          isSelected: group.id == selectedId,
                          onTap: () {
                            onNavChanged(group.id);
                            Navigator.pop(context);
                          },
                        ),
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
                _navRow(
                  context: ctx,
                  item: item,
                  state: EdenNavItemState(isSelected: item.id == selectedId),
                  onTap: () {
                    Navigator.pop(ctx);
                    onNavChanged(item.id);
                  },
                  defaultRenderer: () => ListTile(
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

    // No Semantics and no Expanded here: both are applied by the layout's
    // single emission point (EdenMobileLayout._navRow and its Expanded at the
    // call site), uniformly for this default renderer and for a consumer
    // itemBuilder's result alike. Annotating here too would nest two
    // Semantics widgets and the identifier would not be published at all.
    return GestureDetector(
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

    // No Semantics here — see the note in _BottomItem. The identifier, the
    // button/label/selected annotations and the tap action are published once
    // by EdenMobileLayout._navRow, outside whatever rendered this row.
    return GestureDetector(
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
      );
  }
}
