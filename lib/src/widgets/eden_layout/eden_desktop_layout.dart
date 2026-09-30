import 'package:flutter/material.dart';
import '../../theme/eden_bare_field_theme.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_field_purpose.dart';
import '../eden_selectable_region.dart';
import 'layout_data.dart';
import 'nav_ink.dart';
import 'nav_selection_indicator.dart';

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
    this.selectableBody = false,
    this.itemBuilder,
    this.sectionBuilder,
  });

  /// Renders one nav row in place of the built-in renderer; return `null` for
  /// a row to keep the default treatment.
  ///
  /// Composition over flags: every behaviour added to [EdenNavItem] so far
  /// (`expandable`, `caption`, `isDivider`, `badge`) was a library change plus
  /// a pin bump in two apps. Those flags still work — they render THROUGH the
  /// default renderer — but the next consumer need is a consumer change.
  ///
  /// The `eden-nav-<id>` semantics identifier, the `button`/`label`/`selected`
  /// annotations and the row's tap action are applied by the layout OUTSIDE
  /// this builder's result, uniformly for the default renderer and for a
  /// consumer widget alike — exactly one semantics node per row either way. A
  /// consumer therefore cannot drop the identifier the aodex and eden-biz E2E
  /// flows key off.
  final EdenNavItemBuilder? itemBuilder;

  /// Renders a caption or divider row in place of the built-in treatment;
  /// return `null` to keep the default. Sections are non-interactive and carry
  /// no semantics identifier, in either path.
  final EdenNavSectionBuilder? sectionBuilder;

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

  // -------------------------------------------------------------------------
  // The single point at which a rail row is emitted (TRD 23-06 Task 1)
  // -------------------------------------------------------------------------

  /// Emits ONE rail row.
  ///
  /// This is the only place in the desktop layout that produces a nav row, and
  /// therefore the only place that publishes a row's semantics. The
  /// `Semantics` wrapper is applied UNIFORMLY here — the same node for the
  /// built-in renderer's result and for a consumer [EdenDesktopLayout
  /// .itemBuilder]'s result — which is why [_NavTile] and
  /// [_ExpandableNavHeader] no longer annotate anything themselves. Exactly
  /// one semantics node per row, whoever rendered it.
  ///
  /// (Annotating in both places would nest two `Semantics` widgets. The
  /// version-specific claim this comment used to carry — "a nested
  /// `Semantics` without `container: true` is not published at all on Flutter
  /// 3.41" — has been measured and corrected: it describes an annotation
  /// carrying no semantics of its own directly inside a `container: true`
  /// boundary, and only on 3.41.9; on the 3.47.4 CI pins it publishes its own
  /// node. Two nested IDENTIFIED annotations, the shape at issue here, publish
  /// TWO nodes with identical rects on BOTH SDKs (CI run 35901104815) — two
  /// addressable nodes stacked on one rail row, each carrying the row's label.
  /// One emission point remains the fix; see [EdenMobileLayout] `._navRow` and
  /// `test/ui_oracle/semantics_geometry_test.dart` case 7 for the
  /// measurements.)
  Widget _navRow({
    required BuildContext context,
    required EdenNavItem item,
    required EdenNavItemState state,
    required Widget Function() defaultRenderer,
    String? semanticsLabel,
    bool? expanded,
    VoidCallback? onTap,
    bool excludeChildSemantics = false,
  }) {
    // One path, with a default builder — never a branch on whether a consumer
    // supplied one. A builder that returns null declines THIS row and the
    // default renders it.
    final EdenNavItemBuilder build =
        widget.itemBuilder ?? (_, __, ___) => null;
    final child = build(context, item, state) ?? defaultRenderer();
    return Semantics(
      identifier: item.semanticsIdentifier ?? 'eden-nav-${item.id}',
      button: true,
      label: semanticsLabel ?? item.label,
      selected: state.isSelected,
      expanded: expanded,
      onTap: onTap,
      child: excludeChildSemantics ? ExcludeSemantics(child: child) : child,
    );
  }

  /// Emits one non-interactive section row (caption or divider). Sections
  /// carry no identifier and no button semantics in either path — same as
  /// today.
  /// (`EdenNavItem.widgetKey` stays on the DEFAULT treatment, where it is
  /// today. A consumer-rendered section keys its own widget.)
  Widget _navSection({
    required BuildContext context,
    required EdenNavItem item,
    required Widget Function() defaultRenderer,
  }) {
    final EdenNavSectionBuilder build =
        widget.sectionBuilder ?? (_, __) => null;
    return build(context, item) ?? defaultRenderer();
  }

  /// The stand-in row a group collapses to in the 72px rail: the parent's icon
  /// and label, but the FIRST CHILD's id, because that is what a tap navigates
  /// to. Unchanged behaviour — extracted only so the emission point and the
  /// default renderer are handed the same item.
  EdenNavItem _collapsedGroupRailItem(EdenNavItem item) => EdenNavItem(
        id: item.children.first.id,
        label: item.label,
        icon: item.icon,
        activeIcon: item.activeIcon ?? item.children.first.activeIcon,
        badge: item.children.first.badge,
      );

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
                            _navSection(
                              context: context,
                              item: item,
                              defaultRenderer: () => Padding(
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
                            ),
                        ] else if (item.isCaption) ...[
                          if (!_collapsed)
                            _navSection(
                              context: context,
                              item: item,
                              defaultRenderer: () => _NavSectionLabel(
                                  key: item.widgetKey, label: item.label),
                            ),
                        ] else if (item.children.isNotEmpty) ...[
                          if (!_collapsed && item.expandable) ...[
                            _navRow(
                              context: context,
                              item: item,
                              state: EdenNavItemState(
                                isSelected: item.id == widget.selectedId ||
                                    (!_expandedGroupIds.contains(item.id) &&
                                        item.children.any((c) =>
                                            c.id == widget.selectedId)),
                                isExpanded:
                                    _expandedGroupIds.contains(item.id),
                                isCollapsedRail: _collapsed,
                              ),
                              expanded: _expandedGroupIds.contains(item.id),
                              semanticsLabel: item.badge == null
                                  ? item.label
                                  : '${item.label}, ${item.badge}',
                              // The tap action has to live on the row's node,
                              // not on the GestureDetector: the child subtree
                              // is excluded (so chevron, icon, label and badge
                              // do not split into competing nodes) and that
                              // drops the detector's SemanticsAction.tap with
                              // it. Without this the node announces
                              // `button: true`, a reader double-taps, and
                              // nothing happens.
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
                                if (willExpand) widget.onNavChanged(item.id);
                              },
                              excludeChildSemantics: true,
                              defaultRenderer: () => _ExpandableNavHeader(
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
                            ),
                            if (_expandedGroupIds.contains(item.id))
                              _DisclosedChildren(
                                groupId: item.id,
                                children: [
                                  for (final child in item.children)
                                    _navRow(
                                      context: context,
                                      item: child,
                                      state: EdenNavItemState(
                                        isSelected:
                                            child.id == widget.selectedId,
                                        isCollapsedRail: _collapsed,
                                        depth: 1,
                                      ),
                                      defaultRenderer: () => _NavTile(
                                        item: child,
                                        isSelected:
                                            child.id == widget.selectedId,
                                        collapsed: _collapsed,
                                        onTap: () =>
                                            widget.onNavChanged(child.id),
                                      ),
                                    ),
                                ],
                              ),
                          ] else ...[
                            if (!_collapsed)
                              _navSection(
                                context: context,
                                item: item,
                                defaultRenderer: () => Padding(
                                  key: item.widgetKey,
                                  padding: _kNavSectionLabelPadding,
                                  child: Text(
                                    item.label.toUpperCase(),
                                    style: _navSectionLabelStyle(theme),
                                  ),
                                ),
                              ),
                            if (!_collapsed)
                              for (final child in item.children)
                                _navRow(
                                  context: context,
                                  item: child,
                                  state: EdenNavItemState(
                                    isSelected: child.id == widget.selectedId,
                                    isCollapsedRail: _collapsed,
                                  ),
                                  defaultRenderer: () => _NavTile(
                                    item: child,
                                    isSelected: child.id == widget.selectedId,
                                    collapsed: _collapsed,
                                    onTap: () =>
                                        widget.onNavChanged(child.id),
                                  ),
                                )
                            else
                              // Collapsed: render parent icon but use first child's
                              // ID for navigation and selection matching.
                              _navRow(
                                context: context,
                                item: _collapsedGroupRailItem(item),
                                state: EdenNavItemState(
                                  isSelected: item.children
                                      .any((c) => c.id == widget.selectedId),
                                  isCollapsedRail: _collapsed,
                                ),
                                defaultRenderer: () => _NavTile(
                                  item: _collapsedGroupRailItem(item),
                                  isSelected: item.children.any((c) => c.id == widget.selectedId),
                                  collapsed: _collapsed,
                                  onTap: () => widget.onNavChanged(item.children.first.id),
                                ),
                              ),
                          ],
                        ] else
                          // Leaf, INCLUDING an `expandable` group whose children
                          // list is empty: no children means no disclosure, so
                          // the chevron is ABSENT rather than inert and the item
                          // renders exactly as it does today. aodex's PROJECTS
                          // on a fresh account lands here (BCP-R8).
                          _navRow(
                            context: context,
                            item: item,
                            state: EdenNavItemState(
                              isSelected: item.id == widget.selectedId,
                              isCollapsedRail: _collapsed,
                            ),
                            defaultRenderer: () => _NavTile(
                              item: item,
                              isSelected: item.id == widget.selectedId,
                              collapsed: _collapsed,
                              onTap: () => widget.onNavChanged(item.id),
                            ),
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
                Expanded(
                  child: widget.selectableBody
                      ? EdenSelectableRegion(child: widget.body)
                      : widget.body,
                ),
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

/// Hit area of the sidebar collapse/expand toggle.
///
/// The GLYPH stays 20px; this is the box around it that actually receives the
/// click. A bare `Icon(size: 20)` inside a `GestureDetector` gives a 20x20 hit
/// target — under even WCAG 2.5.8 Target Size (Minimum)'s 24x24 pointer floor,
/// so it is undersized on a mouse-driven rail, not only under touch guidance.
///
/// 44 rather than 24: the header is already 56px tall, so the larger box costs
/// no layout at all, and it clears WCAG 2.5.5 Target Size (Enhanced) as well.
const double _kSidebarToggleHitSize = 44;

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
                // Without `opaque` the 44x44 box is decoration: the padding
                // around the glyph is transparent, does not hit-test, and the
                // real target stays 20x20 while the semantics rect claims 44.
                // The collapsed variant above already carries this; the
                // expanded one did not.
                behavior: HitTestBehavior.opaque,
                onTap: onToggle,
                child: SizedBox(
                  width: _kSidebarToggleHitSize,
                  height: _kSidebarToggleHitSize,
                  child: Icon(Icons.menu_open, size: 20, color: theme.colorScheme.onSurfaceVariant),
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
// Nav row geometry
// ---------------------------------------------------------------------------

/// Horizontal inset of a plain [_NavTile].
const double _kNavTileHorizontalPadding = 12;

/// The chevron column an [_ExpandableNavHeader] carries and a [_NavTile] does
/// not: a leading pad, the chevron itself, and the gap after it.
const double _kExpandableHeaderLeftPadding = 4;
const double _kExpandableChevronSize = 18;

/// Clearance between the chevron and the selection pill beside it.
///
/// MEASURED, not transferred. `_NavTile`'s pill never overlaps its icon
/// because that row has 12px of horizontal padding and nothing else in the
/// way; `_ExpandableNavHeader` has a 4px leading pad, an 18px chevron and
/// only this gap before the icon the pill wraps with a 10px horizontal
/// inset. The non-overlap invariant, independent of the leading pad (it
/// cancels): `gap >= inset.left`, i.e. `gap >= 10`. At the OLD gap of 4, the
/// pill's left edge sits at `4 + 18 + 4 - 10 = 16`, inside the chevron's own
/// `[4, 22]` box — the pill painted OVER the chevron (`Row` paints the
/// chevron first). 12 — already this file's spacing vocabulary — puts the
/// pill's left edge at `4 + 18 + 12 - 10 = 24`, 2px clear of the chevron's
/// right edge at 22 (eden-ui-flutter#58 code review, lower-1).
const double _kExpandableChevronGap = 12;

/// Vertical gap a nav row leaves under itself. Named so the containment rule
/// can stop at the LAST child's bottom edge rather than overhang into it.
const double _kNavRowBottomMargin = 2;

/// The hairline that binds a disclosed group's children to their header.
///
/// It replaces the 14px indent 20-02 first used. An indent buys containment
/// with the scarcest resource this rail has — label width, which already
/// truncates — whereas a rule in the existing gutter costs zero layout width.
/// Same device as aodex's knowledge folder browser, so the two surfaces agree.
const double _kExpandableRuleWidth = 1;

/// Inset from the children block's own left edge. The block starts at the
/// ListView's 12px pad and a child icon starts 12 further in, so 5 lands the
/// rule at dx 17: clear of the pad, clear of the icon column.
const double _kExpandableRuleInset = 5;

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
    // NOT colorScheme.primary when selected. The brand gold on the selected
    // row's 10%-primary band measured 2.05:1 at fontSize 13 in the light
    // theme — the same class of failure the bottom bar (2.20:1) and the
    // drawer (1.97:1) were fixed for. Same ruling as those two: the brand
    // moves OFF the text. onSurface on the rail's own fill is 17.72:1 light,
    // 16.12:1 dark.
    //
    // (Was "16.47:1 / 13.74:1" here — those are onSurface against the
    // 10%-primary BAND, which this branch deleted. Measuring the old surface
    // is how a comment keeps a number long after the thing it measured is
    // gone.)
    //
    // THE BAND ITSELF IS GONE (eden-ui-flutter#58 code review): at 1.08:1
    // light / 1.17:1 dark against the rail's own fill it was never a
    // conformant selection carrier, band or no band beside it, and this row
    // carried the identical `primary@0.1` band `_NavTile` did. The state is
    // now carried by `EdenNavSelectionIndicator` on the icon below — see its
    // dartdoc and the `_NavTile` comment for the measurement.
    final fg = theme.colorScheme.onSurface;

    // No Semantics here: the layout publishes exactly one node per row at the
    // emission point (_EdenDesktopLayoutState._navRow), which is what lets a
    // consumer's itemBuilder result carry the same identifier, label and tap
    // action as this one. The chevron, icon, label and badge below are
    // decorative — the row's subtree semantics are excluded there.
    return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: _kNavRowBottomMargin),
            padding: const EdgeInsets.only(
              left: _kExpandableHeaderLeftPadding,
              right: _kNavTileHorizontalPadding,
            ),
            // No decoration here: a bare `BoxDecoration(borderRadius: ...)`
            // with no colour, border or shadow paints nothing — `Container`
            // does not clip its child (`clipBehavior` defaults to
            // `Clip.none`) — so the previous `decoration:` was dead code
            // that cost a `RenderDecoratedBox` in the tree for zero visible
            // effect (eden-ui-flutter#58 code review, lower-8).
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: _kExpandableChevronSize,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: _kExpandableChevronGap),
                // Insets: 10 horizontal / 5 vertical, the same 40x30 pill
                // `_NavTile` uses around its 20px glyph — this row is the
                // same 40px height, so the same clearance applies.
                EdenNavSelectionIndicator(
                  isSelected: isSelected,
                  inset:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Icon(
                    isSelected ? (item.activeIcon ?? item.icon) : item.icon,
                    size: 20,
                    // THE ICON NOW CARRIES THE INDICATOR, like `_NavTile`'s.
                    color: isSelected
                        ? EdenNavSelectionIndicator.selectedGlyph
                        : theme.colorScheme.onSurfaceVariant,
                  ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Disclosed children of an expandable group
// ---------------------------------------------------------------------------

/// The rows of an OPEN group, bound to their header by a single vertical
/// hairline in the gutter to their left.
///
/// The rows themselves keep the plain [_NavTile] inset, so a disclosed child is
/// geometrically identical to any other nav row and no label width is spent on
/// belonging. The rule is the whole containment signal: one continuous line
/// from the top of the first child to the bottom of the last, never a segment
/// per row, and never present on a collapsed group — the caller only builds
/// this when the group is expanded.
class _DisclosedChildren extends StatelessWidget {
  const _DisclosedChildren({required this.groupId, required this.children});

  final String groupId;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Column(mainAxisSize: MainAxisSize.min, children: children),
        Positioned(
          left: _kExpandableRuleInset,
          top: 0,
          // Stop at the last row's content edge instead of overhanging into
          // the margin it leaves for the next item.
          bottom: _kNavRowBottomMargin,
          child: Container(
            key: ValueKey('eden-nav-group-rule-$groupId'),
            width: _kExpandableRuleWidth,
            color: theme.colorScheme.outlineVariant,
          ),
        ),
      ],
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

    // THE SELECTED ICON TAKES THE INDICATOR, NOT THE LABEL'S ink. This used
    // to say the icon was content and the band beside it was the selection
    // affordance — that claim was the defect (eden-ui-flutter#58 code
    // review): the band is `primary.withValues(alpha: 0.1)`, and it measures
    // 1.08:1 light / 1.17:1 dark against the rail's own fill, under WCAG
    // 1.4.11's 3:1 floor for the visual information identifying a
    // component's state. In the COLLAPSED rail there is no label either, so
    // that band was the ONLY thing claiming to identify the selected row,
    // and it never could.
    //
    // The band is gone. The state is carried by `EdenNavSelectionIndicator`
    // — the same pill+rim widget the bottom bar, drawer and "More" sheet
    // already use — adopted here as the fourth surface. The rim
    // (`onPrimaryContainer`) is what clears 3:1 against the rail's own fill
    // (7.45:1 light / 15.21:1 dark); the pill fill alone (brand gold on
    // white) does not (2.20:1 light). The selected icon sits ON the pill and
    // takes `EdenNavSelectionIndicator.selectedGlyph` (`neutral[900]`), not
    // `onSurface` — onSurface inverts with the theme and would read
    // near-white on the dark theme's gold[400] fill (2.12:1). Measured:
    // 8.04:1 light / 7.61:1 dark on the pill. Unselected is unchanged at
    // `onSurfaceVariant`, 4.83:1 light / 6.91:1 dark on the rail's own
    // surface.
    //
    // Pinned by `test/ui_oracle/desktop_rail_contrast_test.dart`, which
    // COMPUTES the ratio from the resolved colours rather than asserting a
    // hex — a test that pins a literal passes forever and says nothing when
    // the surface token moves underneath it.
    final icon = Icon(
      isSelected ? (item.activeIcon ?? item.icon) : item.icon,
      size: 20,
      color: isSelected
          ? EdenNavSelectionIndicator.selectedGlyph
          : theme.colorScheme.onSurfaceVariant,
    );

    if (collapsed) {
      return Tooltip(
          message: item.label,
          preferBelow: false,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              key: ValueKey<String>('eden-nav-row-${item.id}'),
              width: double.infinity,
              height: 44,
              margin: const EdgeInsets.only(bottom: _kNavRowBottomMargin),
              // No decoration here — see the identical note on
              // _ExpandableNavHeader's Container above; same dead-code
              // removal (lower-8).
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Insets: 10 horizontal / 5 vertical make the pill 40x30
                  // around the 20px glyph — 7px clear of the 44px row's top
                  // and bottom (VERIFIED, not assumed: the mobile bar's
                  // indicator overflowed its fixed 60px bar by 7px when it
                  // was sized by layout instead, which is why the pill is
                  // `Positioned` inside a `Clip.none` stack and takes no
                  // part in layout here either).
                  EdenNavSelectionIndicator(
                    isSelected: isSelected,
                    inset: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    child: icon,
                  ),
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
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: ValueKey<String>('eden-nav-row-${item.id}'),
        height: 40,
          margin: const EdgeInsets.only(bottom: _kNavRowBottomMargin),
          padding: const EdgeInsets.symmetric(
            horizontal: _kNavTileHorizontalPadding,
          ),
          // No decoration here — see the identical note on the collapsed
          // branch's Container above; same dead-code removal (lower-8).
          child: Row(
            children: [
              // Same 40x30 pill as the collapsed branch: in this 40px-high
              // row it clears 5px top and bottom before the row's own
              // 2px bottom margin — the closest mobile precedent is the
              // drawer tile (14px gap, 48 high), sized here to the rail's
              // shorter row instead.
              EdenNavSelectionIndicator(
                isSelected: isSelected,
                inset:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: icon,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    // The label stays `onSurface` (17.72:1 light / 16.12:1
                    // dark on the rail's own fill) and does not move. The
                    // state is carried by `EdenNavSelectionIndicator` beside
                    // it — see the icon comment above and the widget's own
                    // dartdoc (eden-ui-flutter#58 code review).
                    color: theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badge != null) _Badge(text: item.badge!),
            ],
          ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Badge
// ---------------------------------------------------------------------------

/// The count badge a nav row carries.
///
/// `_Badge` is consumed by BOTH `_NavTile` branches — collapsed (painted on
/// top of the selection pill, ~:969 above) and expanded (painted on the
/// rail's own fill, ~:1022 above) — and by `_ExpandableNavHeader` (also on
/// the rail's own fill). Its BOUNDARY has to carry its shape against
/// whichever of those it happens to be sitting on, which is why the rim
/// below is unconditional rather than gated on `isSelected` or on the
/// collapsed/expanded branch: fixing the one adjacency in front of you and
/// never measuring the others is how eden-ui-flutter#58's own fix produced
/// this regression in the first place (code review).
///
/// EVERY ADJACENCY, RE-DERIVED AGAINST THE COMMITTED TOKENS:
///
/// | adjacency                              | light   | dark    |
/// |-----------------------------------------|---------|---------|
/// | rim vs pill fill (collapsed, selected)   | 8.04:1  | 7.61:1  |
/// | rim vs badge fill (both branches)        | 8.04:1  | 7.61:1  |
/// | digit vs badge fill (unchanged)          | 8.04:1  | 7.61:1  |
/// | rim vs rail fill (expanded)              | 17.72:1 | 1.00:1* |
/// | badge fill vs rail fill (expanded)       | 2.20:1  | 7.61:1  |
///
/// \* same token as the rail fill in dark — the rim is inert there, not
/// wrong: `edenNavOnFillInk` (`neutral[900]`) IS the dark rail fill, so the
/// rim simply vanishes into it rather than regressing anything.
///
/// Read the last two rows together: the boundary is carried by the rim OR
/// the fill, and which one carries it SWAPS by theme — light leans on the
/// rim (17.72 vs the fill's 2.20), dark leans on the fill (7.61 vs the
/// rim's inert 1.00). The rim is therefore a NET WIN and never a regression:
/// in light-expanded it replaces a bare 2.20:1 badge-vs-white boundary (a
/// real, pre-existing 1.4.11 defect nobody had named) with 17.72:1; in
/// dark-expanded it is harmless because the fill already carries the shape
/// on its own. Pinned by `desktop_rail_contrast_test.dart`'s test-list item
/// 5 ("the EXPANDED branch's adjacency is MEASURED, not documented"), which
/// asserts `max(wcagContrast(rim, railFill), wcagContrast(badgeFill,
/// railFill)) >= 3.0` and names which side carried it per theme — so a
/// future swap is visible in a diff instead of silently absorbed by `max`.
///
/// TWO ALTERNATIVES WERE REJECTED, recorded so this comment can say why the
/// obvious choices are wrong:
///  - `colorScheme.error` fill (the mobile bar's badge token): 1.71:1 light
///    / 1.62:1 dark against the pill. The 3.76:1 that makes `error` look
///    right is `error` against the rail's WHITE fill — the wrong surface for
///    the collapsed-rail adjacency, which is the pill.
///  - a rim of `onPrimaryContainer` (the pill's OWN rim token): 3.38:1 light
///    but only 2.00:1 dark — fails dark outright.
///
/// RIM WIDTH is 1px, not the pill's 1.5px. `Border` on a `BoxDecoration`
/// grows the `Container` it decorates (no explicit size is given, so the
/// widget shrink-wraps content + padding + border): on the ~18x16 badge,
/// 1.5px would yield ~21x19 — 3/19 = 15.8% of the badge's height is rim,
/// against the pill's 3/30 = 10%. 1px yields ~20x18 — 2/18 = 11.1%, closer
/// to the pill's proportion — and still fits the collapsed row's
/// `Positioned(top: 6, right: 10)` inside the 56x44 tile with room to
/// spare.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey<String>('eden-nav-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        // The rim. See the class dartdoc for the full adjacency matrix this
        // token is measured against, both `_NavTile` branches, both themes.
        border: Border.all(color: edenNavOnFillInk, width: 1),
        borderRadius: EdenRadii.borderRadiusFull,
      ),
      // Was Colors.white on colorScheme.primary: 2.20:1 light, 2.33:1 dark,
      // at fontSize 10 against WCAG 1.4.3's 4.5:1. The IDENTICAL defect the
      // mobile drawer and the "More" sheet carried, in the FOURTH rendering
      // of the same nav row — and the rail had never been audited, because
      // until expectUiSane learned to measure painted text no instrument in
      // the suite could see a badge at all. The same near-black ink the other
      // three take: 8.04:1 and 7.61:1.
      child: Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: edenNavOnFillInk),
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
      // The initials were colorScheme.primary on this 15%-primary circle:
      // 1.98:1 in the light theme at fontSize 12, against a 4.5:1 floor. The
      // circle keeps the brand tint; the text does not, which is the same
      // ruling the bar, the drawer and the sheet were given. onSurface on the
      // tint is 15.89:1 light and 12.45:1 dark. The person glyph moves with
      // it — at 1.98:1 it also failed 1.4.11's 3:1 for a meaningful icon.
      child: user.initials != null
          ? Text(
              user.initials!,
              style: TextStyle(
                fontSize: collapsed ? 11 : 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            )
          : Icon(Icons.person,
              size: collapsed ? 16 : 18, color: theme.colorScheme.onSurface),
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

/// Height of the top bar's search pill — the rounded fill a user sees and
/// clicks.
///
/// LOAD-BEARING, and shared by the pill and the field inside it on purpose.
/// The `TextField` carries `isDense: true` and `contentPadding: EdgeInsets
/// .zero`, so left to its intrinsic height it is the ~21px text line box: the
/// `Semantics(identifier: 'eden-topbar-search')` node collapsed to that,
/// under-reporting a 36px affordance and failing the UI Oracle's 24x24 WCAG
/// 2.5.8 pointer floor. Constraining the field to this height makes the
/// field — the real hit target, since `InputDecorator`'s box is what takes
/// the tap — fill the pill, so the published node and the tappable region are
/// the same rect. Do NOT fix this by enlarging a wrapper around the field: a
/// rect that claims area it cannot receive taps in defeats the oracle instead
/// of satisfying it (pinned by test/ui_oracle/topbar_search_target_test.dart
/// case 2).
const double _kTopBarSearchHeight = 36;

class _TopBar extends StatelessWidget {
  const _TopBar({required this.config, this.onMenuTap});
  final EdenTopBarConfig config;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    // eden-field-purpose: EdenFieldPurpose.searchQuery -- the top-bar search
    // box. No autofill identity; the purpose resolves keyboardType and
    // textInputAction together.
    const searchPurpose = EdenFieldPurpose.searchQuery;
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
                height: _kTopBarSearchHeight,
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
                        // A TIGHT height constraint, not a decorative box: the
                        // TextField itself grows to fill the pill, so the
                        // region that takes the tap grows with the semantics
                        // rect instead of staying a 21px line in the middle
                        // of it.
                        child: SizedBox(
                          height: _kTopBarSearchHeight,
                          child: EdenBareFieldTheme(
                            // THE PILL IS THE CHROME. Without this wrapper the
                            // field inherits EdenTheme's inputDecorationTheme
                            // and paints TWO things over the pill the Container
                            // above draws: an opaque `fillColor` rectangle
                            // (white in light, neutral[800] in dark), sized
                            // from the decorator's ~20px CONTENT height rather
                            // than the 36px the SizedBox forces — which is why
                            // the captured frame showed white for y=11..28 and
                            // the pill's own #e4e4e7 only for y=30..44, and why
                            // the hint measured 4.83:1 against `surface` where
                            // its token pair against the pill is 3.81:1 — and
                            // an `enabledBorder` ring in colorScheme.outline,
                            // which `border: InputBorder.none` does NOT turn
                            // off and which read #dcdcdf along the pill's top
                            // edge. Pinned by topbar_search_pill_paint_test
                            // .dart case 1 and field_border_overpaint_test.dart.
                            child: TextField(
                              autofillHints:
                                  searchPurpose.semantics.autofillHints,
                              keyboardType: searchPurpose.semantics.keyboardType,
                              obscureText: searchPurpose.semantics.obscureText,
                              textInputAction:
                                  searchPurpose.semantics.textInputAction,
                              textCapitalization:
                                  searchPurpose.semantics.textCapitalization,
                              autocorrect: searchPurpose.semantics.autocorrect,
                              enableSuggestions:
                                  searchPurpose.semantics.enableSuggestions,
                              decoration: InputDecoration(
                                hintText: config.searchHint,
                                // `secondary`, not `onSurfaceVariant`: the ink
                                // now sits on the pill's
                                // `surfaceContainerHighest` fill, and
                                // onSurfaceVariant on that is 3.81:1 at 13px —
                                // under 1.4.3's 4.5:1 floor. The failure was
                                // real all along; it was masked for as long as
                                // the glyph was painted on the white overpaint
                                // (4.83:1 against white). In BOTH Eden themes
                                // `secondary` is this palette's muted neutral
                                // (neutral[600] light, neutral[400] dark) and is
                                // the only ColorScheme role that clears the
                                // floor on that fill while still reading as a
                                // hint rather than as entered text: 6.09:1
                                // light, 5.81:1 dark. The DARK value does not
                                // move — dark `secondary` and dark
                                // `onSurfaceVariant` are the same neutral[400].
                                hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.secondary),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              onChanged: config.onSearch,
                            ),
                          ),
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
