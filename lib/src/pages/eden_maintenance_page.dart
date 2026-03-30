import 'package:flutter/material.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../widgets/eden_button.dart';

/// A maintenance/downtime page displayed when the app or a service is
/// undergoing scheduled maintenance.
///
/// Follows the same centered full-page pattern as [EdenErrorPage].
class EdenMaintenancePage extends StatelessWidget {
  const EdenMaintenancePage({
    super.key,
    this.title = "We'll be back soon",
    this.description =
        "We're performing scheduled maintenance. Thank you for your patience.",
    this.icon = Icons.construction_rounded,
    this.logo,
    this.estimatedReturn,
    this.onCheckStatus,
    this.statusUrl,
    this.contactEmail,
  });

  /// Primary heading. Defaults to "We'll be back soon".
  final String title;

  /// Description text. Defaults to a maintenance message.
  final String description;

  /// Large icon displayed above the title. Defaults to [Icons.construction_rounded].
  final IconData icon;

  /// Optional branding widget displayed at the top of the page.
  final Widget? logo;

  /// If provided, displays the expected return time formatted as "Expected
  /// back at HH:MM".
  final DateTime? estimatedReturn;

  /// Callback for the "Check Status" button.
  final VoidCallback? onCheckStatus;

  /// Optional status page URL displayed as informational text.
  final String? statusUrl;

  /// Optional support email displayed at the bottom.
  final String? contactEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Logo ---
            if (logo != null) ...[
              logo!,
              const SizedBox(height: EdenSpacing.space8),
            ],

            // --- Icon ---
            Icon(
              icon,
              size: 64,
              color: EdenColors.neutral[400],
            ),
            const SizedBox(height: EdenSpacing.space4),

            // --- Title ---
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: EdenSpacing.space2),

            // --- Description ---
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // --- Estimated return ---
            if (estimatedReturn != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space4,
                  vertical: EdenSpacing.space2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: EdenSpacing.space2),
                    Text(
                      'Expected back at ${_formatTime(estimatedReturn!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // --- Check status button ---
            if (onCheckStatus != null) ...[
              const SizedBox(height: EdenSpacing.space6),
              EdenButton(
                label: 'Check Status',
                onPressed: onCheckStatus,
                variant: EdenButtonVariant.secondary,
                icon: Icons.refresh_rounded,
              ),
            ],

            // --- Status URL ---
            if (statusUrl != null) ...[
              const SizedBox(height: EdenSpacing.space3),
              Text(
                statusUrl!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],

            // --- Contact email ---
            if (contactEmail != null) ...[
              const SizedBox(height: EdenSpacing.space4),
              Text(
                'Contact $contactEmail',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
