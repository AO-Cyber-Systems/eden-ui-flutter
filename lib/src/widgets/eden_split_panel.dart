import 'package:flutter/material.dart';

/// Tier 1 split-panel layout: left sidebar list + right detail panel.
///
/// Mirrors the React app's sidebar+detail pattern used for Customers, Team,
/// Suppliers, Subcontractors, Processes, Workflows, and Templates.
///
/// On wide screens (>= [breakpoint]), shows side-by-side panels.
/// On narrow screens, shows only the list (tapping navigates to detail).
///
/// ```dart
/// EdenSplitPanel(
///   sidebarWidth: 320,
///   sidebar: CustomerSidebarList(...),
///   detail: selectedCustomer != null
///       ? CustomerDetailPanel(customer: selectedCustomer)
///       : EdenEmptyState(title: 'Select a customer'),
/// )
/// ```
class EdenSplitPanel extends StatelessWidget {
  const EdenSplitPanel({
    super.key,
    required this.sidebar,
    required this.detail,
    this.sidebarWidth = 320,
    this.breakpoint = 900,
    this.showDivider = true,
  });

  /// The left panel content (typically a searchable, filterable list).
  final Widget sidebar;

  /// The right panel content (detail view or empty state).
  final Widget detail;

  /// Width of the sidebar panel on desktop.
  final double sidebarWidth;

  /// Breakpoint below which only the sidebar is shown.
  final double breakpoint;

  /// Whether to show a divider between panels.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= breakpoint;

        if (!isDesktop) {
          return sidebar;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: sidebarWidth,
              child: sidebar,
            ),
            if (showDivider)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context)
                    .colorScheme
                    .outlineVariant
                    .withValues(alpha: 0.5),
              ),
            Expanded(child: detail),
          ],
        );
      },
    );
  }
}
