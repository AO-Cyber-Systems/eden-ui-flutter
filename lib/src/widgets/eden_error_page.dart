import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';

/// Mirrors the eden_error_page Rails component.
///
/// Full-page error state with icon, title, description, and action.
class EdenErrorPage extends StatelessWidget {
  const EdenErrorPage({
    super.key,
    this.statusCode,
    required this.title,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  /// Common 404 page.
  const EdenErrorPage.notFound({
    super.key,
    this.title = 'Page not found',
    this.description = 'The page you are looking for doesn\'t exist or has been moved.',
    this.actionLabel = 'Go home',
    this.onAction,
  })  : statusCode = '404',
        icon = Icons.search_off_rounded;

  /// Common 500 page.
  const EdenErrorPage.serverError({
    super.key,
    this.title = 'Something went wrong',
    this.description = 'We encountered an unexpected error. Please try again later.',
    this.actionLabel = 'Try again',
    this.onAction,
  })  : statusCode = '500',
        icon = Icons.error_outline_rounded;

  /// Common 403 page.
  const EdenErrorPage.forbidden({
    super.key,
    this.title = 'Access denied',
    this.description = 'You don\'t have permission to view this page.',
    this.actionLabel = 'Go home',
    this.onAction,
  })  : statusCode = '403',
        icon = Icons.lock_outline_rounded;

  final String? statusCode;
  final String title;
  final String? description;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 64,
                color: EdenColors.neutral[400],
              ),
            if (statusCode != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              Text(
                statusCode!,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  height: 1,
                ),
              ),
            ],
            const SizedBox(height: EdenSpacing.space4),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: EdenSpacing.space2),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: EdenSpacing.space6),
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
