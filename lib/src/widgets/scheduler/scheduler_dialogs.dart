import 'package:flutter/material.dart';

import '../../tokens/spacing.dart';
import 'scheduler_models.dart';

/// Generic responsive dialog scaffold for [EdenScheduler] create / edit /
/// detail flows. Library does not own form state — consumer plugs a domain
/// form widget into [bodySlot] and pops with form data via Navigator.
///
/// At width ≥ 600pt renders as a modal Dialog (max 480pt wide); below 600pt
/// renders fullscreen Scaffold (Dialog.fullscreen).
class _EdenSchedulerDialogScaffold extends StatelessWidget {
  const _EdenSchedulerDialogScaffold({
    required this.title,
    required this.bodySlot,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.cancelLabel = 'Cancel',
    this.actions,
  });

  final String title;
  final Widget bodySlot;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String cancelLabel;

  /// Extra action buttons for detail dialogs (e.g. Delete, Cancel
  /// appointment). Rendered before the primary action.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final fullscreen = w < 600;

    final actionRow = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(cancelLabel),
      ),
      if (actions != null) ...actions!,
      if (primaryActionLabel != null)
        FilledButton(
          onPressed: onPrimaryAction,
          child: Text(primaryActionLabel!),
        ),
    ];

    if (fullscreen) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(title),
            leading: const CloseButton(),
            actions: [
              if (primaryActionLabel != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EdenSpacing.space2,
                  ),
                  child: TextButton(
                    onPressed: onPrimaryAction,
                    child: Text(primaryActionLabel!),
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            child: bodySlot,
          ),
        ),
      );
    }

    return Dialog(
      child: ConstrainedBox(
        // width: 480 — dialog narrow clamp
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                EdenSpacing.space4,
                EdenSpacing.space4,
                EdenSpacing.space2,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  CloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(EdenSpacing.space4),
                child: bodySlot,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(EdenSpacing.space2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actionRow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Create-event dialog (parity row D-1).
class EdenSchedulerCreateDialog extends StatelessWidget {
  const EdenSchedulerCreateDialog({
    super.key,
    required this.bodySlot,
    this.title = 'New Appointment',
    this.primaryActionLabel = 'Save',
    this.onPrimaryAction,
    this.cancelLabel = 'Cancel',
  });

  final Widget bodySlot;
  final String title;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String cancelLabel;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget bodySlot,
    String title = 'New Appointment',
    String primaryActionLabel = 'Save',
    VoidCallback? onPrimaryAction,
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => EdenSchedulerCreateDialog(
        bodySlot: bodySlot,
        title: title,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EdenSchedulerDialogScaffold(
      title: title,
      bodySlot: bodySlot,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onPrimaryAction,
      cancelLabel: cancelLabel,
    );
  }
}

/// Edit-event dialog (parity row D-2).
class EdenSchedulerEditDialog extends StatelessWidget {
  const EdenSchedulerEditDialog({
    super.key,
    required this.bodySlot,
    this.initialEvent,
    this.title = 'Edit Appointment',
    this.primaryActionLabel = 'Save',
    this.onPrimaryAction,
    this.cancelLabel = 'Cancel',
  });

  final Widget bodySlot;
  final EdenSchedulerEvent? initialEvent;
  final String title;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String cancelLabel;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget bodySlot,
    EdenSchedulerEvent? initialEvent,
    String title = 'Edit Appointment',
    String primaryActionLabel = 'Save',
    VoidCallback? onPrimaryAction,
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => EdenSchedulerEditDialog(
        bodySlot: bodySlot,
        initialEvent: initialEvent,
        title: title,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        cancelLabel: cancelLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EdenSchedulerDialogScaffold(
      title: title,
      bodySlot: bodySlot,
      primaryActionLabel: primaryActionLabel,
      onPrimaryAction: onPrimaryAction,
      cancelLabel: cancelLabel,
    );
  }
}

/// Event-detail dialog (parity row D-3).
class EdenSchedulerDetailDialog extends StatelessWidget {
  const EdenSchedulerDetailDialog({
    super.key,
    required this.bodySlot,
    this.title = 'Appointment',
    this.cancelLabel = 'Close',
    this.actions,
  });

  final Widget bodySlot;
  final String title;
  final String cancelLabel;
  final List<Widget>? actions;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget bodySlot,
    String title = 'Appointment',
    String cancelLabel = 'Close',
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => EdenSchedulerDetailDialog(
        bodySlot: bodySlot,
        title: title,
        cancelLabel: cancelLabel,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _EdenSchedulerDialogScaffold(
      title: title,
      bodySlot: bodySlot,
      cancelLabel: cancelLabel,
      actions: actions,
    );
  }
}
