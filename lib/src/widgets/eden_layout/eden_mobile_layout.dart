import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
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
  ///
  /// Stripping their `Semantics` was not enough on its own, though. A row's
  /// renderer is a `GestureDetector(onTap:)` — [_BottomItem], [_DrawerTile],
  /// the "More" sheet's `ListTile`, or whatever a consumer [itemBuilder]
  /// returns — and a GestureDetector contributes `SemanticsAction.tap`
  /// IMPLICITLY, with no `Semantics` widget anywhere. The row therefore
  /// published two tap routes: this node's, plus an unidentified descendant's.
  /// On web the semantics node is what receives the click
  /// (memory: flutter-web-semantics-node-is-the-click-target), so that is two
  /// stacked click targets on one row, and `expectUiSane` fails it.
  ///
  /// So when the row owns the tap action, the child subtree is excluded from
  /// the semantics tree — the same remedy, for the same reason, as
  /// `EdenDesktopLayout._navRow`'s `excludeChildSemantics`. The rule is tied
  /// to [onTap] rather than to a flag because that IS the invariant: exactly
  /// the rows that put a tap action on their own node must stop the renderer
  /// publishing a competing one, and a row with no tap action has nothing to
  /// compete with (desktop's leaf rows are that case today).
  ///
  /// [ExcludeSemantics] touches the SEMANTICS tree only — it does not change
  /// hit testing, so the renderer's `GestureDetector` still takes a real
  /// pointer tap and fires the route exactly once. Assistive-tech activation
  /// goes through this node's [onTap], which is the same callback.
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
      child: onTap == null ? child : ExcludeSemantics(child: child),
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
                        // MEASURED. `primary` at 15% over the drawer's
                        // surface composites to #F4EEE1, and the gold
                        // initials on it are 1.91:1 at fontSize 13 — a third
                        // instance of the same gold-on-near-white defect,
                        // found the moment the drawer was first rendered
                        // under the oracle. `primaryContainer` /
                        // `onPrimaryContainer` is the token PAIR that already
                        // exists for exactly this job: 6.40:1, and it is
                        // 6.40:1 in the dark theme too because the pair
                        // inverts together.
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: user!.initials != null
                              ? Text(user!.initials!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimaryContainer))
                              : Icon(Icons.person, size: 20, color: theme.colorScheme.onPrimaryContainer),
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
                  // THE SAME SELECTED STATE AS THE BAR AND THE DRAWER.
                  //
                  // The selected row's title and glyph were
                  // `colorScheme.primary` — the brand gold — on the sheet's
                  // own surface (Material 3's `surfaceContainerLow`,
                  // neutral[50] #FAFAFA light): 2.11:1 at the ListTile's
                  // fontSize 16, against 4.5:1. The same defect as the bar's
                  // 2.20:1 label, in the same file, and equally invisible —
                  // nothing in the suite had ever opened this sheet.
                  //
                  //   light  title gold #D4A853 on the sheet  2.11:1  FAILED
                  //          title onSurface neutral[900]    16.97:1
                  //          pill fill gold on the sheet      2.11:1  alone
                  //          pill rim onPrimaryContainer      7.14:1  clears
                  //          icon neutral[900] on the fill    8.04:1
                  //   dark   title gold[400] on the sheet     7.61:1  passed
                  //          title onSurface neutral[100]    16.12:1
                  //          pill rim onPrimaryContainer     15.21:1
                  //
                  // The title colour is set EXPLICITLY in both states rather
                  // than left null for ListTile to inherit: a colour that is
                  // not written down cannot be held to a floor by a test.
                  defaultRenderer: () => ListTile(
                    // Insets: 8 horizontal / 4 vertical makes the pill 40x32
                    // around ListTile's 24px glyph — inside the 40px leading
                    // slot, and 24px clear of the title.
                    leading: _NavSelectionIndicator(
                      isSelected: item.id == selectedId,
                      inset:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Icon(
                        item.id == selectedId ? (item.activeIcon ?? item.icon) : item.icon,
                        color: item.id == selectedId
                            ? _NavSelectionIndicator.selectedGlyph
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: item.id == selectedId ? FontWeight.w600 : FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    trailing: item.badge != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: EdenRadii.borderRadiusFull,
                            ),
                            // Colors.white on gold was 2.20:1 light / 2.33:1
                            // dark at fontSize 11. Same near-black glyph as
                            // the indicator: 8.04:1 and 7.61:1.
                            child: Text(item.badge!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _NavSelectionIndicator.selectedGlyph,
                                )),
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
    // WHERE THE BRAND COLOUR LIVES IN THE SELECTED STATE.
    //
    // The selected label used to be `colorScheme.primary` — EdenColors.gold
    // #D4A853 — at fontSize 11 on the bar's `colorScheme.surface`, which is
    // Colors.white in the light theme. That measures 2.20:1 against WCAG
    // 1.4.3's 4.5:1 floor for normal-size text. A real failure, caught by
    // expectUiSane on mobile-layout/default — light.
    //
    // The ruling: the gold does not change and is not darkened. It moves OFF
    // the text. The selected state is carried by the INDICATOR below — a
    // filled pill behind the icon, in the brand colour at full saturation —
    // and the label takes the ordinary dark text colour. The brand stays
    // where it is visible and leaves the one role it cannot hold.
    //
    // MEASURED, because "non-text UI components only need 3:1" does not
    // rescue the fill either — gold on white is 2.20:1, which clears neither
    // floor, and the bar really is white (`colorScheme.surface`):
    //
    //   light  fill gold #D4A853  vs white bar        2.20:1  FAILS 1.4.11
    //          rim  onPrimaryContainer gold[900]      7.45:1  clears it
    //          icon neutral[900] on the gold fill     8.04:1
    //          label onSurface neutral[900] on bar   17.72:1
    //   dark   fill gold[400] vs neutral[900] bar     7.61:1  clears it alone
    //          rim  onPrimaryContainer gold[100]     15.21:1
    //          icon neutral[900] on the gold fill     7.61:1
    //          label onSurface neutral[100] on bar   16.12:1
    //
    // So the pill's BOUNDARY is load-bearing, not decoration: WCAG 1.4.11 is
    // met by an indicator whose boundary is identifiable against the adjacent
    // colour, and in the light theme the fill alone never can be. The rim is
    // `onPrimaryContainer`, which is brand-derived (it clears 3:1 on the bar
    // for every EdenColors preset — gold 7.45, blue 10.36, emerald 9.72,
    // purple 10.88, red 10.02, slate 17.85) rather than a gold literal, so a
    // consumer that swaps `EdenTheme.brandColor` keeps a conformant bar.
    //
    // The icon is `EdenColors.neutral[900]` and NOT `onSurface`: onSurface
    // inverts with the theme, and neutral[100] on gold[400] is 2.12:1 — the
    // dark theme would have gained a new failure. A near-black glyph reads as
    // cut out of the bar, and clears 3:1 on every preset's fill (worst case
    // slate at 3.72:1).
    final Color labelColour = isSelected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // The indicator is POSITIONED inside
                // [_NavSelectionIndicator], so it paints around the glyph
                // without taking part in layout.
                //
                // MEASURED, not stylistic: the bar is a fixed 60px and the
                // row already uses 58 of it under the stock Material text
                // theme (22 icon + 4 gap + 32 label). An indicator that sized
                // the Column overflowed it by 7px — three
                // eden_mobile_layout_test cases went red on
                // `A RenderFlex overflowed by 7.0 pixels on the bottom`, which
                // is exactly the defect expectUiSane exists to catch, so it
                // could not be waved through. Positioned with negative insets
                // is the same device the badge below already uses, under the
                // same `clipBehavior: Clip.none`.
                //
                // Insets: 3 vertical keeps the pill 1px clear of the label's
                // box across the 4px gap; 13 horizontal makes it 48 wide,
                // which fits five tabs on a 320px viewport.
                _NavSelectionIndicator(
                  isSelected: isSelected,
                  inset: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
                  child: Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 22,
                    color: isSelected
                        ? _NavSelectionIndicator.selectedGlyph
                        : theme.colorScheme.onSurfaceVariant,
                  ),
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
                color: labelColour,
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
    //
    // THE SAME SELECTED STATE AS THE BAR, for the same measured reason.
    //
    // This tile used to say "selected" with `colorScheme.primary` on BOTH the
    // glyph and the label, over a `primary.withValues(alpha: 0.1)` band. On
    // the drawer's own surface (Material 3's `surfaceContainerLow`,
    // neutral[50] #FAFAFA in the light theme) that band composites to
    // #F6F2E9, and the gold label on it measures 1.97:1 at fontSize 14
    // against WCAG 1.4.3's 4.5:1 floor — the identical failure the bottom bar
    // had at 2.20:1, in the same widget, unchanged when the bar was fixed.
    //
    // No test could see it: `mobile-layout/default` pumps with the drawer
    // CLOSED, so the oracle never rendered this row. That hole is closed by
    // test/ui_oracle/mobile_shell_open_surfaces_test.dart, which opens the
    // drawer before asserting.
    //
    //   light  label gold #D4A853 on the band  1.97:1  FAILED 1.4.3
    //          label onSurface neutral[900]   15.86:1  (no band: 16.97:1)
    //          pill fill gold on drawer        2.11:1  fails alone
    //          pill rim onPrimaryContainer     7.14:1  clears 1.4.11
    //          icon neutral[900] on the fill   8.04:1
    //   dark   label gold[400] on the band     6.49:1  (passed already)
    //          label onSurface neutral[100]   16.12:1
    //          pill fill gold[400] on drawer   7.61:1
    //          pill rim onPrimaryContainer    15.21:1
    //          icon neutral[900] on the fill   7.61:1
    //
    // THE BAND IS GONE, deliberately. At 1.07:1 against the drawer it was
    // never perceivable, and it is the brand at 10% — which is exactly the
    // dilution the bar's ruling rejected. The state is carried by the same
    // indicator the bar uses, at full saturation, with the rim that makes it
    // conformant. One selection language, three surfaces.
    //
    // HEIGHT 48, not 44. Once the drawer was actually rendered under the
    // oracle, every row failed `androidTapTargetGuideline` at 288x46 (44 plus
    // the 2px margin) against the 48x48 floor the mobile shell declares by
    // being a TOUCH surface. 48 + 2 margin = 50.
    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
          children: [
            // Insets: 10 horizontal / 5 vertical makes the pill 40x30 around
            // the 20px glyph. It stays 4px clear of the tile's padding box on
            // the left and 4px clear of the label across the 14px gap, and
            // 9px clear of the row above and below — so it cannot collide
            // with an adjacent row's target.
            _NavSelectionIndicator(
              isSelected: isSelected,
              inset: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Icon(
                isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                size: 20,
                color: isSelected
                    ? _NavSelectionIndicator.selectedGlyph
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
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
                // Was Colors.white on the gold fill: 2.20:1 light, 2.33:1
                // dark, both failing 1.4.3 at fontSize 10. The badge takes the
                // same near-black glyph the indicator does — 8.04:1 and
                // 7.61:1 — because it is the same problem: text on brand gold.
                child: Text(item.badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _NavSelectionIndicator.selectedGlyph,
                    )),
              ),
          ],
        ),
      ),
      );
  }
}

// ---------------------------------------------------------------------------
// Selected-state indicator — ONE definition, three surfaces
// ---------------------------------------------------------------------------

/// Paints the mobile shell's "this row is selected" indicator behind [child].
///
/// WHY THIS IS ONE WIDGET AND NOT THREE COPIES. The bottom bar, the drawer and
/// the "More" sheet are three renderings of the same nav row, and for a while
/// they DISAGREED about what selected looks like: the bar was fixed to move
/// the brand gold off the label and onto an indicator (c828c87) while
/// `_DrawerTile` and the sheet's `ListTile` kept the gold on the text at
/// 1.97:1 and 2.11:1. Two selection languages in one app, and the second one
/// unobservable because no test ever opened those surfaces. A single widget is
/// what stops them drifting apart again: a change to the indicator is a change
/// everywhere, and a surface that opts out has to say so at its call site.
///
/// The pill is [Positioned] with NEGATIVE insets inside a [Clip.none] stack,
/// so it paints around the glyph without taking part in layout. That is
/// measured, not stylistic — an indicator that sized the bottom bar's column
/// overflowed the bar's fixed 60px by 7px (see `_BottomItem`). [inset] is how
/// far the pill extends beyond the glyph on each side, so each surface sizes
/// it to its own glyph without duplicating the mechanism.
///
/// The rim is load-bearing. WCAG 1.4.11 asks 3:1 for the visual information
/// that identifies a component's state, against the ADJACENT colour, and in
/// the light theme the gold fill never clears it (2.11:1 on the drawer,
/// 2.20:1 on the bar). `onPrimaryContainer` does, for every EdenColors preset
/// and in both themes — gold 7.14, blue 8.88, emerald 8.53, purple 9.28, red
/// 8.46, slate 15.21 on the light drawer; 12.5-13.8 across the dark one.
class _NavSelectionIndicator extends StatelessWidget {
  const _NavSelectionIndicator({
    required this.isSelected,
    required this.inset,
    required this.child,
  });

  /// Whether to paint the indicator at all. An indicator on every row
  /// indicates nothing, so this is never defaulted.
  final bool isSelected;

  /// How far the pill extends BEYOND [child] on each side, in logical pixels.
  final EdgeInsets inset;

  /// The glyph the indicator sits behind. Sizes the stack; the pill does not.
  final Widget child;

  /// The colour a glyph takes when it sits ON the indicator's fill.
  ///
  /// `EdenColors.neutral[900]` and NOT `colorScheme.onSurface`: onSurface
  /// inverts with the theme, and neutral[100] on gold[400] is 2.12:1 — the
  /// dark theme would gain a new failure. A near-black glyph clears 3:1 on
  /// every preset's fill (worst case slate at 3.72:1) and 4.5:1 as text on
  /// the badge (worst case slate, still above the floor).
  ///
  /// One getter rather than a literal at each site: the bar, the drawer tile,
  /// the sheet row and both badges must move together or they are back to
  /// disagreeing.
  static Color get selectedGlyph => EdenColors.neutral[900]!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isSelected)
          Positioned(
            left: -inset.left,
            right: -inset.right,
            top: -inset.top,
            bottom: -inset.bottom,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                border: Border.all(
                  color: theme.colorScheme.onPrimaryContainer,
                  width: 1.5,
                ),
                borderRadius: EdenRadii.borderRadiusFull,
              ),
            ),
          ),
        child,
      ],
    );
  }
}
