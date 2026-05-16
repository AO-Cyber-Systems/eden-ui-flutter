import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';

/// Material banner shown above the scheduler grid when conflicting events
/// exist. Mirrors donor `SchedulingConflictAlert` (parity row D-4).
class EdenSchedulerConflictBanner extends StatelessWidget {
  const EdenSchedulerConflictBanner({
    super.key,
    required this.conflictCount,
    this.onResolve,
    this.onDismiss,
  });

  final int conflictCount;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (conflictCount <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: EdenColors.warning.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: EdenColors.warning, size: 18),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                conflictCount == 1
                    ? '1 scheduling conflict detected.'
                    : '$conflictCount scheduling conflicts detected.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onResolve != null)
              TextButton(onPressed: onResolve, child: const Text('Resolve')),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onDismiss,
              ),
          ],
        ),
      ),
    );
  }
}

/// Banner shown when multiple events are selected. Mirrors donor
/// `GroupEditBanner` (parity row D-5).
class EdenSchedulerSelectionBanner extends StatelessWidget {
  const EdenSchedulerSelectionBanner({
    super.key,
    required this.selectionCount,
    this.onClear,
    this.actions,
  });

  final int selectionCount;
  final VoidCallback? onClear;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    if (selectionCount <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space2,
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: EdenSpacing.space2),
            Expanded(
              child: Text(
                selectionCount == 1
                    ? '1 event selected.'
                    : '$selectionCount events selected.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actions != null) ...actions!,
            if (onClear != null)
              TextButton(onPressed: onClear, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}
