import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_search_input.dart';

/// Composable scaffold for list pages.
///
/// Ported from trades-flutter `lib/shared/widgets/list_page_scaffold.dart`
/// (donor commit on trades-flutter `main`). The transport-agnostic library
/// version strips the Riverpod / PermissionGate / search-provider plumbing —
/// callers wire their own state management above this widget.
///
/// Vertical composition (top to bottom):
///   1. Header row: title + optional `+ createLabel` button (slots vertically
///      below `narrowBreakpoint` to avoid RenderFlex overflow on iPhone-narrow)
///   2. Optional alerts slot (e.g., blocking alerts banner)
///   3. Optional filter pills slot (e.g., StatusFilterPills)
///   4. Optional search input slot (driven by [onSearchChanged])
///   5. Body slot (Expanded; consumer owns its own scrolling)
///
/// The scaffold does NOT introduce its own scroll wrapper around [body]; if
/// the body is a tall ListView/CustomScrollView, it owns its own scroll.
///
/// ```dart
/// EdenListPageScaffold(
///   title: 'Projects',
///   createLabel: 'New Project',
///   onCreate: () => showCreateDialog(),
///   filterPills: const Row(children: [Chip(label: Text('Active'))]),
///   onSearchChanged: (q) => setState(() => _query = q),
///   alerts: BlockingAlertsBanner(...),
///   body: EdenDataTable(...),
/// )
/// ```
class EdenListPageScaffold extends StatelessWidget {
  const EdenListPageScaffold({
    super.key,
    required this.title,
    this.createLabel,
    this.onCreate,
    this.filterPills,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.alerts,
    required this.body,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.narrowBreakpoint = 480,
  });

  /// Page title displayed in the header row.
  final String title;

  /// Label for the create button. If null OR `onCreate` is null, no button
  /// is rendered (no dead button).
  final String? createLabel;

  /// Callback when the create button is pressed.
  final VoidCallback? onCreate;

  /// Optional filter widget — caller composes the row of chips/pills/etc.
  final Widget? filterPills;

  /// Placeholder text for the search input (used only when
  /// [onSearchChanged] is non-null).
  final String searchHint;

  /// Called when the search text changes. If null, the search input slot
  /// is not rendered.
  final ValueChanged<String>? onSearchChanged;

  /// Optional alerts slot (e.g., blocking alerts banner). Rendered above
  /// the filter pills.
  final Widget? alerts;

  /// Main content area. Typically a data table or list view. The scaffold
  /// expands the body to fill remaining vertical space; the body owns its
  /// own scrolling.
  final Widget body;

  /// Padding applied around the entire scaffold content.
  final EdgeInsets padding;

  /// Below this width (in logical pixels), the header row stacks the create
  /// button vertically below the title. Mirrors EdenPageHeader's 480pt
  /// breakpoint for consistency.
  final double narrowBreakpoint;

  bool get _hasCreateButton => createLabel != null && onCreate != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header row: title + optional create button
          LayoutBuilder(
            builder: (context, constraints) {
              final titleWidget = Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              );

              if (!_hasCreateButton) {
                return titleWidget;
              }

              final button = EdenButton(
                label: '+ ${createLabel!}',
                onPressed: onCreate,
                size: EdenButtonSize.sm,
              );

              if (constraints.maxWidth < narrowBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: EdenSpacing.space3),
                    Align(alignment: Alignment.centerLeft, child: button),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleWidget),
                  button,
                ],
              );
            },
          ),
          const SizedBox(height: EdenSpacing.space4),

          // 2. Alerts slot
          if (alerts != null) ...[
            alerts!,
            const SizedBox(height: EdenSpacing.space3),
          ],

          // 3. Filter pills
          if (filterPills != null) ...[
            filterPills!,
            const SizedBox(height: EdenSpacing.space3),
          ],

          // 4. Search input
          if (onSearchChanged != null) ...[
            EdenSearchInput(
              hint: searchHint,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: EdenSpacing.space3),
          ],

          // 5. Body (expanded; consumer owns scrolling)
          Expanded(child: body),
        ],
      ),
    );
  }
}
