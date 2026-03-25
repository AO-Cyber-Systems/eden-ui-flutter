import 'package:flutter/material.dart';

import '../tokens/colors.dart';

import '../tokens/spacing.dart';

/// The state of a workflow step.
enum EdenWorkflowStepState {
  /// Step has been completed successfully.
  completed,

  /// Step is currently active.
  active,

  /// Step has not yet been reached.
  pending,
}

/// Represents a single step in a workflow pipeline.
class EdenWorkflowStep {
  /// Creates a workflow step.
  const EdenWorkflowStep({
    required this.label,
    required this.state,
  });

  /// The display label for this step.
  final String label;

  /// The current state of this step.
  final EdenWorkflowStepState state;
}

/// A horizontal workflow phase indicator for DevFlow pipelines.
///
/// Displays a series of steps connected by lines, with visual states
/// for completed, active, and pending phases. Each step shows a
/// circle with either a checkmark or step number, and a label below.
class EdenWorkflowStepper extends StatelessWidget {
  /// Creates an Eden workflow stepper.
  const EdenWorkflowStepper({
    super.key,
    required this.steps,
    this.onStepTap,
  });

  /// The ordered list of workflow steps.
  final List<EdenWorkflowStep> steps;

  /// Called when a step circle is tapped, with the step index.
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (steps.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Expanded(
                child: _StepColumn(
                  step: steps[i],
                  index: i,
                  isDark: isDark,
                  theme: theme,
                  onTap: onStepTap != null ? () => onStepTap!(i) : null,
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: _ConnectingLine(
                    fromState: steps[i].state,
                    toState: steps[i + 1].state,
                    isDark: isDark,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _StepColumn extends StatelessWidget {
  const _StepColumn({
    required this.step,
    required this.index,
    required this.isDark,
    required this.theme,
    this.onTap,
  });

  final EdenWorkflowStep step;
  final int index;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final activeLabelColor =
        isDark ? EdenColors.neutral[100]! : EdenColors.neutral[800]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepCircle(
          state: step.state,
          index: index,
          isDark: isDark,
          onTap: onTap,
        ),
        SizedBox(height: EdenSpacing.space2),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: step.state == EdenWorkflowStepState.active
                ? FontWeight.w600
                : FontWeight.w400,
            color: step.state == EdenWorkflowStepState.pending
                ? labelColor
                : activeLabelColor,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.state,
    required this.index,
    required this.isDark,
    this.onTap,
  });

  final EdenWorkflowStepState state;
  final int index;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final circle = SizedBox(
      width: 28,
      height: 28,
      child: _buildCircleContent(context),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: circle,
        ),
      );
    }

    return circle;
  }

  Widget _buildCircleContent(BuildContext context) {
    switch (state) {
      case EdenWorkflowStepState.completed:
        return Container(
          decoration: const BoxDecoration(
            color: EdenColors.success,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            ),
          ),
        );

      case EdenWorkflowStepState.active:
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        );

      case EdenWorkflowStepState.pending:
        final borderColor =
            isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!;
        final textColor =
            isDark ? EdenColors.neutral[500]! : EdenColors.neutral[400]!;

        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.0,
              ),
            ),
          ),
        );
    }
  }
}

class _ConnectingLine extends StatelessWidget {
  const _ConnectingLine({
    required this.fromState,
    required this.toState,
    required this.isDark,
  });

  final EdenWorkflowStepState fromState;
  final EdenWorkflowStepState toState;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Position the line at the vertical center of the step circles (14px from top).
    return Padding(
      padding: EdgeInsets.only(bottom: EdenSpacing.space2 + 14),
      child: SizedBox(
        height: 2,
        child: _buildLine(),
      ),
    );
  }

  Widget _buildLine() {
    final neutralColor = EdenColors.neutral[300]!;

    // Both completed: solid success line.
    if (fromState == EdenWorkflowStepState.completed &&
        toState == EdenWorkflowStepState.completed) {
      return Container(color: EdenColors.success);
    }

    // Completed to active: gradient from success to primary.
    if (fromState == EdenWorkflowStepState.completed &&
        toState == EdenWorkflowStepState.active) {
      return Builder(
        builder: (context) {
          final primaryColor = Theme.of(context).colorScheme.primary;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [EdenColors.success, primaryColor],
              ),
            ),
          );
        },
      );
    }

    // All other combinations: neutral line.
    return Container(color: neutralColor);
  }
}
