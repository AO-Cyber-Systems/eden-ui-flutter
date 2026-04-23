import 'package:flutter/material.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../eden_checklist_builder.dart';

class TypeIcon extends StatelessWidget {
  const TypeIcon({super.key, required this.type, required this.isDark});

  final EdenChecklistItemType type;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;

    switch (type) {
      case EdenChecklistItemType.checkbox:
        return const SizedBox.shrink();
      case EdenChecklistItemType.textInput:
        icon = Icons.short_text;
        color = EdenColors.info;
      case EdenChecklistItemType.photoRequired:
        icon = Icons.camera_alt_outlined;
        color = EdenColors.warning;
      case EdenChecklistItemType.signatureRequired:
        icon = Icons.draw_outlined;
        color = EdenColors.auroraPurple;
    }

    return Icon(icon, size: 16, color: color);
  }
}

// ---------------------------------------------------------------------------
// Note toggle button
// ---------------------------------------------------------------------------

class NoteToggle extends StatelessWidget {
  const NoteToggle({super.key, 
    required this.hasNote,
    required this.isDark,
    required this.onTap,
  });

  final bool hasNote;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
        size: 16,
        color: hasNote
            ? EdenColors.warning
            : (isDark ? EdenColors.neutral[500] : EdenColors.neutral[400]),
      ),
      tooltip: 'Add note',
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

class ChecklistProgressBar extends StatelessWidget {
  const ChecklistProgressBar({super.key, 
    required this.checked,
    required this.total,
    required this.percent,
    required this.isDark,
    required this.theme,
  });

  final int checked;
  final int total;
  final double percent;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final trackColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final fillColor =
        percent >= 1.0 ? EdenColors.success : theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$checked of $total complete',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? EdenColors.neutral[400]
                    : EdenColors.neutral[500],
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: fillColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space1),
        ClipRRect(
          borderRadius: EdenRadii.borderRadiusFull,
          child: SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Completion summary
// ---------------------------------------------------------------------------

class CompletionSummary extends StatelessWidget {
  const CompletionSummary({super.key, 
    required this.checked,
    required this.total,
    required this.percent,
    required this.allRequiredDone,
    required this.isDark,
    required this.theme,
  });

  final int checked;
  final int total;
  final double percent;
  final bool allRequiredDone;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isComplete = checked == total;
    final bgColor = isComplete
        ? EdenColors.successBg
        : (isDark ? EdenColors.neutral[850]! : EdenColors.neutral[50]!);
    final borderColor = isComplete
        ? EdenColors.success.withValues(alpha: 0.3)
        : (isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!);
    final statusColor = isComplete
        ? EdenColors.success
        : (!allRequiredDone ? EdenColors.warning : EdenColors.neutral[500]!);

    final String statusText;
    final IconData statusIcon;

    if (isComplete) {
      statusText = 'All items complete';
      statusIcon = Icons.check_circle;
    } else if (!allRequiredDone) {
      statusText = 'Required items remaining';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = '$checked of $total items complete';
      statusIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusMd,
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 20, color: statusColor),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: EdenSpacing.space1 / 2),
                Text(
                  '${(percent * 100).round()}% complete',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
