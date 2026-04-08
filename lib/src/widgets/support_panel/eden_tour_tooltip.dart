import 'package:flutter/material.dart';

import '../../tokens/radii.dart';
import '../../tokens/shadows.dart';
import '../../tokens/spacing.dart';
import '../../widgets/eden_button.dart';

/// Eden-styled tooltip for use with showcaseview's [Showcase.withWidget].
///
/// This widget is a plain Flutter widget — it does NOT import showcaseview.
/// Consumers wire the [onNext], [onPrevious], and [onDismiss] callbacks to
/// [ShowcaseView.get().next()], [ShowcaseView.get().previous()], and
/// [ShowcaseView.get().dismiss()] respectively.
///
/// Usage in consumer app:
/// ```dart
/// Showcase.withWidget(
///   key: _myKey,
///   container: EdenTourTooltip(
///     title: 'Dashboard',
///     description: 'View your metrics here',
///     stepIndex: 0,
///     totalSteps: 5,
///     onNext: () => ShowcaseView.get().next(),
///     onDismiss: () => ShowcaseView.get().dismiss(),
///   ),
///   child: DashboardWidget(),
/// )
/// ```
class EdenTourTooltip extends StatelessWidget {
  const EdenTourTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    this.onNext,
    this.onPrevious,
    this.onDismiss,
  });

  /// The title shown prominently in the tooltip.
  final String title;

  /// The descriptive body text for this step.
  final String description;

  /// Zero-based index of the current step (e.g. 0 for the first step).
  final int stepIndex;

  /// Total number of steps in the tour.
  final int totalSteps;

  /// Called when the user taps "Next". Wire to [ShowcaseView.get().next()].
  final VoidCallback? onNext;

  /// Called when the user taps "Back". Wire to [ShowcaseView.get().previous()].
  final VoidCallback? onPrevious;

  /// Called when the user taps "Finish" or the close button.
  /// Wire to [ShowcaseView.get().dismiss()].
  final VoidCallback? onDismiss;

  bool get _isLastStep => stepIndex >= totalSteps - 1;
  bool get _isFirstStep => stepIndex <= 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: EdenRadii.borderRadiusLg,
          boxShadow: EdenShadows.lg(dark: isDark),
        ),
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // Header: step indicator + dismiss button
            // ----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Step ${stepIndex + 1} of $totalSteps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Dismiss tour',
                  child: GestureDetector(
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: EdenSpacing.space2),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: EdenSpacing.space2),
            // ----------------------------------------------------------------
            // Title
            // ----------------------------------------------------------------
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: EdenSpacing.space2),
            // ----------------------------------------------------------------
            // Description
            // ----------------------------------------------------------------
            Text(
              description,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: EdenSpacing.space3),
            // ----------------------------------------------------------------
            // Footer navigation: Back (left) + Next/Finish (right)
            // ----------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button — hidden on first step
                if (!_isFirstStep && onPrevious != null)
                  Semantics(
                    button: true,
                    label: 'Previous step',
                    child: TextButton(
                      onPressed: onPrevious,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Back',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                // Next / Finish button
                if (_isLastStep)
                  Semantics(
                    button: true,
                    label: 'Finish tour',
                    child: EdenButton(
                      label: 'Finish',
                      size: EdenButtonSize.sm,
                      onPressed: onDismiss,
                    ),
                  )
                else
                  Semantics(
                    button: true,
                    label: 'Next step',
                    child: EdenButton(
                      label: 'Next',
                      size: EdenButtonSize.sm,
                      onPressed: onNext,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
