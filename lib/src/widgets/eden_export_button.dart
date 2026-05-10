import 'package:flutter/material.dart';
import 'eden_button.dart';

/// A two-format export trigger ("Export CSV" / "Export JSON") rendered as an
/// [EdenButton] that opens a popup menu on tap.
///
/// Either or both callbacks may be supplied. Only matching menu items render —
/// passing `onExportCsv: null` hides the CSV row. Passing both `null` leaves
/// the button non-interactive (the popup is empty); callers should guard
/// against this themselves.
class EdenExportButton extends StatelessWidget {
  const EdenExportButton({
    super.key,
    this.onExportCsv,
    this.onExportJson,
    this.loading = false,
    this.label = 'Export',
  });

  /// Invoked when the user picks "Export CSV". Hidden if `null`.
  final VoidCallback? onExportCsv;

  /// Invoked when the user picks "Export JSON". Hidden if `null`.
  final VoidCallback? onExportJson;

  /// Renders the underlying [EdenButton] in its loading state.
  final bool loading;

  /// Button label. Defaults to `Export`.
  final String label;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'csv') onExportCsv?.call();
        if (value == 'json') onExportJson?.call();
      },
      itemBuilder: (context) => [
        if (onExportCsv != null)
          const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
        if (onExportJson != null)
          const PopupMenuItem(value: 'json', child: Text('Export JSON')),
      ],
      child: EdenButton(
        label: label,
        icon: Icons.download,
        variant: EdenButtonVariant.secondary,
        size: EdenButtonSize.sm,
        loading: loading,
        onPressed: null,
      ),
    );
  }
}
