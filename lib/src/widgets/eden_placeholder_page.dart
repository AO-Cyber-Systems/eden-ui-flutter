import 'package:flutter/material.dart';

/// Cross-vertical "coming soon" placeholder page for feature-flagged routes.
///
/// **Owns its own [Scaffold] + [AppBar]** — consumers must NOT wrap this
/// widget in another `Scaffold` (Flutter anti-pattern; results in double
/// AppBar + double safe-area insets). Mount it directly as the route widget.
///
/// Visual structure (donor parity):
/// 1. `AppBar(title: Text(title))`.
/// 2. Centered 64px icon on `theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)`.
/// 3. 16pt gap.
/// 4. `theme.textTheme.headlineSmall` title text.
/// 5. 8pt gap.
/// 6. Optional muted [subtitle] (default `'Coming soon'`; pass `null` to hide).
/// 7. Optional 24pt gap + [FilledButton] when BOTH [onAction] and
///    [actionLabel] are non-null.
///
/// Cross-vertical examples:
/// - Trades feature flag: `/admin/agent-builder` stub renders 'Coming soon'.
/// - Salon migration: `/admin/customizations` stub renders 'Migration in
///   progress' with 'Notify me when ready' action.
/// - Medical phase-out: deprecated route stub with subtitle override and
///   action wired to the new flow.
///
/// Donor: `trades-flutter/lib/shared/widgets/placeholder_page.dart` (extended
/// with optional [subtitle] / [onAction] / [actionLabel]).
class EdenPlaceholderPage extends StatelessWidget {
  const EdenPlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle = 'Coming soon',
    this.onAction,
    this.actionLabel,
  });

  /// AppBar title AND headline below the icon.
  final String title;

  /// 64px placeholder icon (e.g. `Icons.bar_chart`).
  final IconData icon;

  /// Muted line of text beneath the headline. Pass `null` to hide. Default is
  /// `'Coming soon'`.
  final String? subtitle;

  /// Optional tap callback for the action button. Renders only when BOTH
  /// [onAction] and [actionLabel] are non-null.
  final VoidCallback? onAction;

  /// Optional label for the action button. Renders only when BOTH [onAction]
  /// and [actionLabel] are non-null.
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAction = onAction != null && actionLabel != null;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (showAction) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
