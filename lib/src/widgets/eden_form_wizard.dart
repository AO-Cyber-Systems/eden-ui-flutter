import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The status of a wizard step.
enum EdenWizardStepStatus {
  /// Step has been completed successfully.
  complete,

  /// Step is the currently active step.
  current,

  /// Step has not been reached yet.
  upcoming,

  /// Step has a validation error.
  error,
}

/// Represents a single step in the form wizard.
class EdenWizardStep {
  /// Creates a wizard step.
  const EdenWizardStep({
    required this.title,
    required this.content,
    this.subtitle,
    this.icon,
    this.validator,
    this.customActions,
  });

  /// The display title for this step.
  final String title;

  /// Optional subtitle shown below the title in the step indicator.
  final String? subtitle;

  /// Optional icon shown in the step indicator circle.
  final IconData? icon;

  /// Builder that returns the content widget for this step.
  ///
  /// Receives the current step index for context.
  final Widget Function(BuildContext context, int stepIndex) content;

  /// Validator callback. Returns `null` if valid, or an error message string.
  ///
  /// Called when the user attempts to proceed past this step.
  final String? Function()? validator;

  /// Optional custom action buttons to replace the default Back/Next/Submit row.
  ///
  /// Receives callbacks for goBack, goNext, and submit so the custom actions
  /// can still drive navigation.
  final Widget Function(
    BuildContext context, {
    required VoidCallback goBack,
    required VoidCallback goNext,
    required VoidCallback submit,
    required bool isFirst,
    required bool isLast,
  })? customActions;
}

/// Navigation mode for the wizard.
enum EdenWizardMode {
  /// Steps must be completed in order; users cannot skip ahead.
  linear,

  /// Users can click any step indicator to jump to that step.
  nonLinear,
}

/// A multi-step form wizard with step indicators, validation, and animated
/// transitions between steps.
///
/// Supports linear and non-linear navigation modes, per-step validation,
/// custom action buttons, and an optional summary/review step.
class EdenFormWizard extends StatefulWidget {
  /// Creates an Eden form wizard.
  const EdenFormWizard({
    super.key,
    required this.steps,
    required this.onSubmit,
    this.mode = EdenWizardMode.linear,
    this.onStepChanged,
    this.onCancel,
    this.initialStep = 0,
    this.submitLabel = 'Submit',
    this.nextLabel = 'Next',
    this.backLabel = 'Back',
    this.cancelLabel = 'Cancel',
    this.showCancelButton = true,
    this.showProgressIndicator = true,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.transitionCurve = Curves.easeInOut,
  });

  /// The ordered list of wizard steps.
  final List<EdenWizardStep> steps;

  /// Called when the user submits on the final step.
  final VoidCallback onSubmit;

  /// Navigation mode — linear or non-linear.
  final EdenWizardMode mode;

  /// Called whenever the active step changes.
  final ValueChanged<int>? onStepChanged;

  /// Called when the user cancels the wizard.
  final VoidCallback? onCancel;

  /// The step index to start on.
  final int initialStep;

  /// Label for the submit button on the last step.
  final String submitLabel;

  /// Label for the next button.
  final String nextLabel;

  /// Label for the back button.
  final String backLabel;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Whether to show a cancel button on the first step.
  final bool showCancelButton;

  /// Whether to show the "Step X of Y" progress indicator.
  final bool showProgressIndicator;

  /// Duration for slide transitions between steps.
  final Duration transitionDuration;

  /// Curve for slide transitions between steps.
  final Curve transitionCurve;

  @override
  State<EdenFormWizard> createState() => _EdenFormWizardState();
}

class _EdenFormWizardState extends State<EdenFormWizard>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  late List<EdenWizardStepStatus> _stepStatuses;
  String? _currentError;

  // Animation state for slide transitions.
  bool _isAnimating = false;
  int _previousStep = 0;
  late final AnimationController _animationController;
  late Animation<Offset> _outgoingSlide;
  late Animation<Offset> _incomingSlide;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, widget.steps.length - 1);
    _previousStep = _currentStep;
    _stepStatuses = List.generate(widget.steps.length, (i) {
      if (i < _currentStep) return EdenWizardStepStatus.complete;
      if (i == _currentStep) return EdenWizardStepStatus.current;
      return EdenWizardStepStatus.upcoming;
    });

    _animationController = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    );
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isAnimating = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step == _currentStep || step < 0 || step >= widget.steps.length) return;
    if (_isAnimating) return;

    // In linear mode, don't allow jumping ahead of the furthest completed step.
    if (widget.mode == EdenWizardMode.linear) {
      final furthestReachable = _stepStatuses.lastIndexWhere(
            (s) =>
                s == EdenWizardStepStatus.complete ||
                s == EdenWizardStepStatus.current,
          ) +
          1;
      if (step > furthestReachable) return;
    }

    final goingForward = step > _currentStep;

    // Configure slide directions.
    if (goingForward) {
      _outgoingSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: widget.transitionCurve,
        ),
      );
      _incomingSlide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: widget.transitionCurve,
        ),
      );
    } else {
      _outgoingSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1.0, 0.0),
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: widget.transitionCurve,
        ),
      );
      _incomingSlide = Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: widget.transitionCurve,
        ),
      );
    }

    setState(() {
      _previousStep = _currentStep;
      _isAnimating = true;
      _currentError = null;

      // Mark old step as complete if going forward.
      if (goingForward) {
        _stepStatuses[_currentStep] = EdenWizardStepStatus.complete;
      }

      _currentStep = step;
      _stepStatuses[_currentStep] = EdenWizardStepStatus.current;
    });

    _animationController.forward(from: 0.0);
    widget.onStepChanged?.call(_currentStep);
  }

  void _goNext() {
    if (_currentStep >= widget.steps.length - 1) return;

    // Run per-step validation.
    final validator = widget.steps[_currentStep].validator;
    if (validator != null) {
      final error = validator();
      if (error != null) {
        setState(() {
          _currentError = error;
          _stepStatuses[_currentStep] = EdenWizardStepStatus.error;
        });
        return;
      }
    }

    _goToStep(_currentStep + 1);
  }

  void _goBack() {
    if (_currentStep <= 0) return;
    _goToStep(_currentStep - 1);
  }

  void _submit() {
    // Validate the final step before submitting.
    final validator = widget.steps[_currentStep].validator;
    if (validator != null) {
      final error = validator();
      if (error != null) {
        setState(() {
          _currentError = error;
          _stepStatuses[_currentStep] = EdenWizardStepStatus.error;
        });
        return;
      }
    }

    setState(() => _currentError = null);
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final stepContent = ClipRect(
          child: _isAnimating
              ? Stack(
                  children: [
                    SlideTransition(
                      position: _outgoingSlide,
                      child: widget.steps[_previousStep]
                          .content(context, _previousStep),
                    ),
                    SlideTransition(
                      position: _incomingSlide,
                      child: widget.steps[_currentStep]
                          .content(context, _currentStep),
                    ),
                  ],
                )
              : widget.steps[_currentStep]
                  .content(context, _currentStep),
        );
        final wrappedContent = hasBoundedHeight
            ? Expanded(child: stepContent)
            : stepContent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Step indicator row.
            _StepIndicatorRow(
              steps: widget.steps,
              statuses: _stepStatuses,
              currentStep: _currentStep,
              isDark: isDark,
              theme: theme,
              allowTap: widget.mode == EdenWizardMode.nonLinear,
              onStepTap: _goToStep,
            ),

            // Progress indicator.
            if (widget.showProgressIndicator) ...[
              const SizedBox(height: EdenSpacing.space2),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                child: Text(
                  'Step ${_currentStep + 1} of ${widget.steps.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? EdenColors.neutral[400]
                        : EdenColors.neutral[500],
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],

            const SizedBox(height: EdenSpacing.space4),

            // Validation error banner.
            if (_currentError != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
                child: _ErrorBanner(message: _currentError!, isDark: isDark),
              ),

            if (_currentError != null) const SizedBox(height: EdenSpacing.space3),

            // Step content with animated transitions.
            wrappedContent,

            const SizedBox(height: EdenSpacing.space4),

            // Action buttons.
            _buildActionRow(theme, isDark),
          ],
        );
      },
    );
  }

  Widget _buildActionRow(ThemeData theme, bool isDark) {
    final step = widget.steps[_currentStep];
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == widget.steps.length - 1;

    // Allow per-step custom action buttons.
    if (step.customActions != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
        child: step.customActions!(
          context,
          goBack: _goBack,
          goNext: _goNext,
          submit: _submit,
          isFirst: isFirst,
          isLast: isLast,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space2,
      ),
      child: Row(
        children: [
          // Cancel / Back button.
          if (isFirst && widget.showCancelButton && widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space5,
                  vertical: EdenSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: EdenRadii.borderRadiusLg,
                ),
              ),
              child: Text(widget.cancelLabel),
            )
          else if (!isFirst)
            TextButton.icon(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(widget.backLabel),
              style: TextButton.styleFrom(
                foregroundColor:
                    isDark ? EdenColors.neutral[300] : EdenColors.neutral[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space5,
                  vertical: EdenSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: EdenRadii.borderRadiusLg,
                ),
              ),
            ),

          const Spacer(),

          // Next / Submit button.
          if (isLast)
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space6,
                  vertical: EdenSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: EdenRadii.borderRadiusLg,
                ),
              ),
              child: Text(widget.submitLabel),
            )
          else
            ElevatedButton(
              onPressed: _goNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: EdenSpacing.space6,
                  vertical: EdenSpacing.space3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: EdenRadii.borderRadiusLg,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.nextLabel),
                  const SizedBox(width: EdenSpacing.space1),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step indicator row
// ---------------------------------------------------------------------------

class _StepIndicatorRow extends StatelessWidget {
  const _StepIndicatorRow({
    required this.steps,
    required this.statuses,
    required this.currentStep,
    required this.isDark,
    required this.theme,
    required this.allowTap,
    required this.onStepTap,
  });

  final List<EdenWizardStep> steps;
  final List<EdenWizardStepStatus> statuses;
  final int currentStep;
  final bool isDark;
  final ThemeData theme;
  final bool allowTap;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: EdenSpacing.space4),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _StepIndicator(
                step: steps[i],
                index: i,
                status: statuses[i],
                isDark: isDark,
                theme: theme,
                onTap: allowTap ? () => onStepTap(i) : null,
              ),
            ),
            if (i < steps.length - 1)
              Expanded(
                child: _ConnectorLine(
                  fromStatus: statuses[i],
                  toStatus: statuses[i + 1],
                  isDark: isDark,
                  theme: theme,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.index,
    required this.status,
    required this.isDark,
    required this.theme,
    this.onTap,
  });

  final EdenWizardStep step;
  final int index;
  final EdenWizardStepStatus status;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;
    final activeLabelColor =
        isDark ? EdenColors.neutral[100]! : EdenColors.neutral[800]!;

    final isCurrent = status == EdenWizardStepStatus.current;
    final isComplete = status == EdenWizardStepStatus.complete;
    final isError = status == EdenWizardStepStatus.error;

    Widget circle = SizedBox(
      width: 32,
      height: 32,
      child: _buildCircle(),
    );

    if (onTap != null) {
      circle = GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: circle,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
        const SizedBox(height: EdenSpacing.space2),
        Text(
          step.title,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                (isCurrent || isComplete) ? FontWeight.w600 : FontWeight.w400,
            color: (isCurrent || isComplete || isError)
                ? activeLabelColor
                : labelColor,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        if (step.subtitle != null)
          Text(
            step.subtitle!,
            style: TextStyle(
              fontSize: 10,
              color: labelColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
      ],
    );
  }

  Widget _buildCircle() {
    switch (status) {
      case EdenWizardStepStatus.complete:
        return Container(
          decoration: const BoxDecoration(
            color: EdenColors.success,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.check, size: 18, color: Colors.white),
          ),
        );

      case EdenWizardStepStatus.current:
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: step.icon != null
                ? Icon(step.icon, size: 18, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
          ),
        );

      case EdenWizardStepStatus.error:
        return Container(
          decoration: const BoxDecoration(
            color: EdenColors.error,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child:
                Icon(Icons.priority_high, size: 18, color: Colors.white),
          ),
        );

      case EdenWizardStepStatus.upcoming:
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
            child: step.icon != null
                ? Icon(step.icon, size: 16, color: textColor)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 14,
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

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine({
    required this.fromStatus,
    required this.toStatus,
    required this.isDark,
    required this.theme,
  });

  final EdenWizardStepStatus fromStatus;
  final EdenWizardStepStatus toStatus;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Align with the vertical center of circles (16px) plus subtitle offset.
      padding: const EdgeInsets.only(bottom: EdenSpacing.space2 + 14),
      child: SizedBox(
        height: 2,
        child: _buildLine(),
      ),
    );
  }

  Widget _buildLine() {
    final neutralColor =
        isDark ? EdenColors.neutral[600]! : EdenColors.neutral[300]!;

    // Both complete: solid success.
    if (fromStatus == EdenWizardStepStatus.complete &&
        toStatus == EdenWizardStepStatus.complete) {
      return Container(color: EdenColors.success);
    }

    // Complete to current: gradient from success to primary.
    if (fromStatus == EdenWizardStepStatus.complete &&
        (toStatus == EdenWizardStepStatus.current ||
            toStatus == EdenWizardStepStatus.error)) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [EdenColors.success, theme.colorScheme.primary],
          ),
        ),
      );
    }

    return Container(color: neutralColor);
  }
}

// ---------------------------------------------------------------------------
// Error banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: EdenColors.errorBg,
        borderRadius: EdenRadii.borderRadiusLg,
        border: Border.all(color: EdenColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: EdenColors.error),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: EdenColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
