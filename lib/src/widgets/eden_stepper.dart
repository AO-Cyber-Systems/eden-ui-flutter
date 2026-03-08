import 'package:flutter/material.dart';
import '../tokens/colors.dart';

/// Status of a stepper step.
enum EdenStepStatus { complete, current, upcoming }

/// A single step definition.
class EdenStepItem {
  const EdenStepItem({
    required this.label,
    this.status = EdenStepStatus.upcoming,
  });

  final String label;
  final EdenStepStatus status;
}

/// Mirrors the eden_stepper / eden_stepper_item Rails components.
///
/// Horizontal step indicator for multi-step wizards.
class EdenStepper extends StatelessWidget {
  const EdenStepper({
    super.key,
    required this.steps,
  });

  final List<EdenStepItem> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _StepCircle(index: i, step: steps[i]),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: steps[i].status == EdenStepStatus.complete
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.index, required this.step});

  final int index;
  final EdenStepItem step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;
    Widget child;

    switch (step.status) {
      case EdenStepStatus.complete:
        bg = theme.colorScheme.primary;
        fg = Colors.white;
        child = const Icon(Icons.check, size: 16, color: Colors.white);
        break;
      case EdenStepStatus.current:
        bg = theme.colorScheme.primary;
        fg = Colors.white;
        child = Text(
          '${index + 1}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
        );
        break;
      case EdenStepStatus.upcoming:
        bg = isDark ? EdenColors.neutral[800]! : EdenColors.neutral[200]!;
        fg = theme.colorScheme.onSurfaceVariant;
        child = Text(
          '${index + 1}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
        );
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
          alignment: Alignment.center,
          child: child,
        ),
        const SizedBox(height: 6),
        Text(
          step.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: step.status == EdenStepStatus.upcoming
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
            fontWeight: step.status == EdenStepStatus.current ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
