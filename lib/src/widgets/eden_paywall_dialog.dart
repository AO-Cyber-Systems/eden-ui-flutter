import 'package:flutter/material.dart';

import 'eden_button.dart';

/// Generic paywall dialog shown when a user-facing action requires
/// upgrading the active plan or topping up credits.
///
/// Designed for the "credits exhausted / quota hit / feature gated"
/// slot — the dialog explains what happened and offers a single
/// affirmative path (typically navigation to the billing screen).
///
/// Behaviour is fully parameterised — this widget does NOT call
/// `context.go(...)` itself. Callers wire navigation via [onUpgrade].
/// The dialog dismisses itself before invoking [onUpgrade] so the
/// caller can `context.go` / `context.push` without first handling
/// the lingering dialog route.
///
/// ## Usage
///
/// ```dart
/// EdenPaywallDialog.show(
///   context,
///   title: 'Credits exhausted',
///   message: "You've run out of credits. Upgrade your plan to continue using AODex.",
///   upgradeLabel: 'Upgrade Plan',
///   onUpgrade: () => context.go('/profile/billing'),
/// );
/// ```
class EdenPaywallDialog extends StatelessWidget {
  const EdenPaywallDialog({
    super.key,
    this.title = 'Credits exhausted',
    this.message =
        "You've run out of credits. Upgrade your plan to continue.",
    this.upgradeLabel = 'Upgrade Plan',
    this.cancelLabel = 'Cancel',
    this.onUpgrade,
    this.onCancel,
  });

  final String title;
  final String message;
  final String upgradeLabel;
  final String cancelLabel;

  /// Invoked AFTER the dialog dismisses when the user taps the upgrade
  /// button. Typically routes the user to the billing screen.
  final VoidCallback? onUpgrade;

  /// Invoked AFTER the dialog dismisses when the user taps cancel.
  /// Optional — defaults to a plain dismiss.
  final VoidCallback? onCancel;

  /// Show the paywall dialog over the current route.
  ///
  /// Returns once the dialog is dismissed.
  static Future<void> show(
    BuildContext context, {
    String title = 'Credits exhausted',
    String message =
        "You've run out of credits. Upgrade your plan to continue.",
    String upgradeLabel = 'Upgrade Plan',
    String cancelLabel = 'Cancel',
    VoidCallback? onUpgrade,
    VoidCallback? onCancel,
  }) =>
      showDialog<void>(
        context: context,
        builder: (_) => EdenPaywallDialog(
          title: title,
          message: message,
          upgradeLabel: upgradeLabel,
          cancelLabel: cancelLabel,
          onUpgrade: onUpgrade,
          onCancel: onCancel,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        EdenButton(
          label: cancelLabel,
          variant: EdenButtonVariant.ghost,
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
        ),
        EdenButton(
          label: upgradeLabel,
          variant: EdenButtonVariant.primary,
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade?.call();
          },
        ),
      ],
    );
  }
}
