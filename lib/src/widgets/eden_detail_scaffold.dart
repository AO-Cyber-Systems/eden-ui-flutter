import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Tab definition for [EdenDetailScaffold].
class EdenDetailTab {
  const EdenDetailTab({
    required this.label,
    required this.content,
    this.count,
  });

  /// Tab label displayed in the tab bar.
  final String label;

  /// Widget rendered when this tab is selected.
  final Widget content;

  /// Optional count badge displayed next to the label.
  final int? count;
}

/// Composable detail page layout with header, optional media row, tabbed
/// content, and an optional right-side panel.
///
/// Provides consistent structure for entity detail views (project, customer,
/// order, etc.). The right panel is hidden on screens narrower than
/// [sidePanelBreakpoint].
///
/// ```dart
/// EdenDetailScaffold(
///   header: MyDetailHeader(title: 'Project Name'),
///   tabs: [
///     EdenDetailTab(label: 'Work', content: WorkTab()),
///     EdenDetailTab(label: 'Contacts', content: ContactsTab(), count: 5),
///   ],
///   sidePanel: AiInsightPanel(),
/// )
/// ```
class EdenDetailScaffold extends StatelessWidget {
  const EdenDetailScaffold({
    super.key,
    required this.header,
    this.mediaRow,
    required this.tabs,
    this.sidePanel,
    this.sidePanelBreakpoint = 900,
    this.padding = const EdgeInsets.symmetric(horizontal: EdenSpacing.space6),
  });

  /// Header widget (title, status badge, action buttons).
  final Widget header;

  /// Optional widget shown below the header (e.g., photo row, attachments).
  final Widget? mediaRow;

  /// Tab definitions. Must have at least one.
  final List<EdenDetailTab> tabs;

  /// Optional right-side panel (e.g., AI insights, related items).
  /// Hidden when width < [sidePanelBreakpoint].
  final Widget? sidePanel;

  /// Width below which [sidePanel] is hidden.
  final double sidePanelBreakpoint;

  /// Padding around the header and media row.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidePanel =
            sidePanel != null && constraints.maxWidth >= sidePanelBreakpoint;

        return DefaultTabController(
          length: tabs.length,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
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
                          if (mediaRow != null) ...[
                            const SizedBox(height: EdenSpacing.space3),
                            mediaRow!,
                          ],
                          const SizedBox(height: EdenSpacing.space4),
                        ],
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: tabs.map(_buildTab).toList(),
                    ),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: TabBarView(
                        children: tabs.map((t) => t.content).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              if (showSidePanel) sidePanel!,
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(EdenDetailTab tab) {
    if (tab.count == null) return Tab(text: tab.label);

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tab.label),
          const SizedBox(width: 6),
          _CountBadge(count: tab.count!),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
