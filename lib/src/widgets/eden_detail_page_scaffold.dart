import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Tab descriptor for [EdenDetailPageScaffold].
///
/// The scaffold renders a [TabBar] from these descriptors; the caller is
/// responsible for supplying a matching [TabBarView] as the [body] AND for
/// wrapping the whole tree in a [DefaultTabController] (or providing an
/// explicit [TabController] via a [DefaultTabController] ancestor). This
/// keeps the API explicit — no auto-wrap magic — at the cost of a single
/// extra widget at the caller.
class EdenDetailTab {
  const EdenDetailTab({required this.label, this.icon});

  final String label;
  final IconData? icon;
}

/// Composable detail-page scaffold.
///
/// Ported from trades-flutter `lib/shared/widgets/detail_view_scaffold.dart`.
/// Transport-agnostic: no Riverpod, no AI insight provider — slots only.
///
/// Structure (wide viewports):
/// ```
/// Row [
///   Expanded Column [
///     header
///     (optional) TabBar  ← rendered when [tabs] is non-null
///     Expanded body      ← caller-provided (e.g., TabBarView)
///   ]
///   sideRail?            ← rendered at sideRailWidth on wide viewports
/// ]
/// ```
///
/// Structure (narrow viewports, `maxWidth < narrowBreakpoint`):
/// - Side rail collapses to an `OutlinedButton('Details')` rendered as the
///   Scaffold's `bottomSheet` trigger; tapping it opens a modal bottom sheet
///   showing the side-rail content.
///
/// Tabs API: the caller wraps the scaffold in a [DefaultTabController] and
/// passes a [TabBarView] as `body`. This makes the controller wiring
/// explicit; the scaffold itself does NOT introduce its own controller.
class EdenDetailPageScaffold extends StatelessWidget {
  const EdenDetailPageScaffold({
    super.key,
    required this.header,
    this.tabs,
    this.sideRail,
    required this.body,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.sideRailWidth = 320,
    this.narrowBreakpoint = 480,
  });

  /// Header widget — typically an [EdenDetailHeader].
  final Widget header;

  /// Optional tab descriptors. When present, the scaffold renders a TabBar
  /// between the header and the body. The body is expected to be a
  /// [TabBarView] (or other widget wired to a [DefaultTabController]).
  final List<EdenDetailTab>? tabs;

  /// Optional side rail rendered to the right of the header+tabs+body column
  /// on wide viewports. On narrow viewports it collapses to a bottom-sheet
  /// trigger.
  final Widget? sideRail;

  /// Main content area. The scaffold expands the body to fill remaining
  /// vertical space; the body owns its own scrolling. When [tabs] is
  /// provided, callers typically pass a [TabBarView] here.
  final Widget body;

  /// Padding applied around the header area.
  final EdgeInsets padding;

  /// Width of the side rail column on wide viewports.
  final double sideRailWidth;

  /// Below this width (logical px), the side rail collapses to a bottom-sheet
  /// trigger ("Details" button) and the layout switches to single-column.
  final double narrowBreakpoint;

  bool get _hasTabs => tabs != null && tabs!.isNotEmpty;
  bool get _hasSideRail => sideRail != null;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < narrowBreakpoint;
        final showSideRailInline = _hasSideRail && !isNarrow;
        final showSideRailAsSheet = _hasSideRail && isNarrow;

        final mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: EdenSpacing.space4),
                  header,
                  const SizedBox(height: EdenSpacing.space4),
                ],
              ),
            ),
            if (_hasTabs) ...[
              _buildTabBar(context),
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ],
            Expanded(child: body),
            if (showSideRailAsSheet) _buildDetailsTrigger(context),
          ],
        );

        if (!showSideRailInline) {
          return mainColumn;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: mainColumn),
            SizedBox(width: sideRailWidth, child: sideRail!),
          ],
        );
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: tabs!
          .map(
            (t) => Tab(
              icon: t.icon != null ? Icon(t.icon) : null,
              text: t.label,
            ),
          )
          .toList(),
    );
  }

  Widget _buildDetailsTrigger(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.info_outline, size: 18),
          label: const Text('Details'),
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(EdenSpacing.space4),
                  child: sideRail!,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
