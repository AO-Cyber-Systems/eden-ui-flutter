import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_button.dart';
import 'eden_search_input.dart';

/// Composable scaffold for list/index pages with consistent structure.
///
/// Assembles a standard list page layout: page header with optional create
/// button, filter pills, search bar, optional alert slot, and a body
/// (typically a data table or list). Works standalone as a full-page list
/// or inside an [EdenSplitPanel] sidebar.
///
/// ```dart
/// EdenListScaffold(
///   title: 'Projects',
///   createButtonLabel: 'Create Project',
///   onCreatePressed: () => showCreateDialog(),
///   filterPills: EdenFilterChipRow(...),
///   searchHint: 'Search projects...',
///   onSearchChanged: (q) => updateFilter(q),
///   body: EdenDataTable(...),
/// )
/// ```
class EdenListScaffold extends StatelessWidget {
  const EdenListScaffold({
    super.key,
    required this.title,
    this.createButtonLabel,
    this.onCreatePressed,
    this.createButton,
    this.filterPills,
    this.searchHint = 'Search...',
    this.onSearchChanged,
    this.alertSlot,
    required this.body,
    this.padding = const EdgeInsets.symmetric(
      horizontal: EdenSpacing.space6,
      vertical: EdenSpacing.space4,
    ),
  });

  /// Page title displayed in the header.
  final String title;

  /// Label for the auto-generated "+ Create" button. If null and
  /// [createButton] is null, no button is shown.
  final String? createButtonLabel;

  /// Callback when the auto-generated create button is pressed.
  final VoidCallback? onCreatePressed;

  /// Custom create button widget. Takes precedence over [createButtonLabel].
  /// Use this when you need RBAC gating or a non-standard button.
  final Widget? createButton;

  /// Optional filter widget (e.g., [EdenFilterChipRow]).
  final Widget? filterPills;

  /// Placeholder text for the search bar.
  final String searchHint;

  /// Called when search text changes. If null, the search bar is hidden.
  final ValueChanged<String>? onSearchChanged;

  /// Optional alert/banner slot below the search bar.
  final Widget? alertSlot;

  /// The main content area (typically a data table or list).
  final Widget body;

  /// Padding around the scaffold content.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: title + create button
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (createButton != null)
                createButton!
              else if (createButtonLabel != null)
                EdenButton(
                  label: '+ $createButtonLabel',
                  onPressed: onCreatePressed,
                  size: EdenButtonSize.sm,
                ),
            ],
          ),
          const SizedBox(height: EdenSpacing.space4),

          // Filter pills
          if (filterPills != null) ...[
            filterPills!,
            const SizedBox(height: EdenSpacing.space3),
          ],

          // Search bar
          if (onSearchChanged != null) ...[
            EdenSearchInput(
              hint: searchHint,
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: EdenSpacing.space3),
          ],

          // Alert slot
          if (alertSlot != null) ...[
            alertSlot!,
            const SizedBox(height: EdenSpacing.space3),
          ],

          // Body (expanded)
          Expanded(child: body),
        ],
      ),
    );
  }
}
