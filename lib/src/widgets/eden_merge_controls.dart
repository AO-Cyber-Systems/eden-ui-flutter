import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// The merge strategy for a pull request.
enum EdenMergeStrategy {
  /// Create a merge commit.
  merge,

  /// Squash and merge into a single commit.
  squash,

  /// Rebase and merge commits onto the base branch.
  rebase,
}

/// A required check with its pass/fail status.
class EdenRequiredCheck {
  /// Creates a required check.
  const EdenRequiredCheck({
    required this.name,
    this.passed = false,
  });

  /// The name of the check.
  final String name;

  /// Whether this check has passed.
  final bool passed;
}

/// A merge controls widget for pull requests.
///
/// Displays a merge button with strategy dropdown, a requirements checklist
/// with pass/fail icons, a conflict warning banner, and an auto-merge toggle.
/// The merge button is disabled with a reason when the PR is not mergeable.
///
/// ```dart
/// EdenMergeControls(
///   mergeStrategy: EdenMergeStrategy.squash,
///   isMergeable: true,
///   ciPassed: true,
///   reviewsApproved: true,
///   hasConflicts: false,
///   branchProtected: true,
///   autoMergeEnabled: false,
///   requiredChecks: [
///     EdenRequiredCheck(name: 'CI / Build', passed: true),
///     EdenRequiredCheck(name: 'CI / Test', passed: true),
///   ],
///   requiredReviewCount: 2,
///   currentReviewCount: 2,
///   onMerge: () {},
///   onStrategyChanged: (strategy) {},
///   onAutoMergeToggled: (enabled) {},
/// )
/// ```
class EdenMergeControls extends StatefulWidget {
  /// Creates an Eden merge controls widget.
  const EdenMergeControls({
    super.key,
    this.mergeStrategy = EdenMergeStrategy.merge,
    this.isMergeable = false,
    this.ciPassed = false,
    this.reviewsApproved = false,
    this.hasConflicts = false,
    this.branchProtected = false,
    this.autoMergeEnabled = false,
    this.requiredChecks = const [],
    this.requiredReviewCount = 1,
    this.currentReviewCount = 0,
    this.onMerge,
    this.onStrategyChanged,
    this.onAutoMergeToggled,
  });

  /// The currently selected merge strategy.
  final EdenMergeStrategy mergeStrategy;

  /// Whether the pull request can be merged.
  final bool isMergeable;

  /// Whether all CI checks have passed.
  final bool ciPassed;

  /// Whether required reviews are approved.
  final bool reviewsApproved;

  /// Whether the pull request has merge conflicts.
  final bool hasConflicts;

  /// Whether the target branch has protection rules.
  final bool branchProtected;

  /// Whether auto-merge is currently enabled.
  final bool autoMergeEnabled;

  /// The list of required checks and their statuses.
  final List<EdenRequiredCheck> requiredChecks;

  /// The number of required reviews.
  final int requiredReviewCount;

  /// The current number of approved reviews.
  final int currentReviewCount;

  /// Called when the merge button is pressed.
  final VoidCallback? onMerge;

  /// Called when the merge strategy is changed.
  final ValueChanged<EdenMergeStrategy>? onStrategyChanged;

  /// Called when the auto-merge toggle is changed.
  final ValueChanged<bool>? onAutoMergeToggled;

  @override
  State<EdenMergeControls> createState() => _EdenMergeControlsState();
}

class _EdenMergeControlsState extends State<EdenMergeControls> {
  bool _strategyDropdownOpen = false;

  String _strategyLabel(EdenMergeStrategy strategy) {
    switch (strategy) {
      case EdenMergeStrategy.merge:
        return 'Create a merge commit';
      case EdenMergeStrategy.squash:
        return 'Squash and merge';
      case EdenMergeStrategy.rebase:
        return 'Rebase and merge';
    }
  }

  String _strategyShortLabel(EdenMergeStrategy strategy) {
    switch (strategy) {
      case EdenMergeStrategy.merge:
        return 'Merge';
      case EdenMergeStrategy.squash:
        return 'Squash';
      case EdenMergeStrategy.rebase:
        return 'Rebase';
    }
  }

  String? _disabledReason() {
    if (widget.hasConflicts) return 'This branch has conflicts';
    if (!widget.ciPassed) return 'Required checks have not passed';
    if (!widget.reviewsApproved) {
      return 'Requires ${widget.requiredReviewCount} approving review(s)';
    }
    if (!widget.isMergeable) return 'This pull request cannot be merged';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor =
        isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor =
        isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final canMerge = widget.isMergeable && !widget.hasConflicts;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: borderColor),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Conflict warning banner
          if (widget.hasConflicts)
            _ConflictBanner(isDark: isDark),

          // Merge button row
          Padding(
            padding: EdgeInsets.all(EdenSpacing.space4),
            child: Row(
              children: [
                Expanded(
                  child: _MergeButton(
                    strategy: widget.mergeStrategy,
                    label: _strategyShortLabel(widget.mergeStrategy),
                    enabled: canMerge,
                    onPressed: widget.onMerge,
                  ),
                ),
                SizedBox(width: 1),
                _StrategyDropdownButton(
                  enabled: canMerge,
                  isOpen: _strategyDropdownOpen,
                  onTap: () {
                    setState(() {
                      _strategyDropdownOpen = !_strategyDropdownOpen;
                    });
                  },
                ),
              ],
            ),
          ),

          // Strategy dropdown options
          if (_strategyDropdownOpen) ...[
            Divider(color: borderColor, height: 1),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: EdenMergeStrategy.values.map((strategy) {
                  final isSelected = widget.mergeStrategy == strategy;
                  return _StrategyOption(
                    label: _strategyLabel(strategy),
                    isSelected: isSelected,
                    onTap: () {
                      widget.onStrategyChanged?.call(strategy);
                      setState(() {
                        _strategyDropdownOpen = false;
                      });
                    },
                    isDark: isDark,
                  );
                }).toList(),
              ),
            ),
          ],

          // Disabled reason
          if (!canMerge && _disabledReason() != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
              ),
              child: Text(
                _disabledReason()!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: EdenColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: EdenSpacing.space3),
          ],

          Divider(color: borderColor, height: 1),

          // Requirements checklist
          Padding(
            padding: EdgeInsets.all(EdenSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Requirements',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? EdenColors.neutral[400]!
                        : EdenColors.neutral[500]!,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: EdenSpacing.space2),

                // CI status
                _RequirementRow(
                  label: 'CI checks',
                  passed: widget.ciPassed,
                ),

                // Reviews
                _RequirementRow(
                  label:
                      'Reviews (${widget.currentReviewCount}/${widget.requiredReviewCount})',
                  passed: widget.reviewsApproved,
                ),

                // No conflicts
                _RequirementRow(
                  label: 'No conflicts',
                  passed: !widget.hasConflicts,
                ),

                // Branch protection
                if (widget.branchProtected)
                  _RequirementRow(
                    label: 'Branch protection rules',
                    passed: widget.isMergeable,
                  ),

                // Individual required checks
                ...widget.requiredChecks.map((check) => _RequirementRow(
                      label: check.name,
                      passed: check.passed,
                    )),
              ],
            ),
          ),

          // Auto-merge toggle
          if (widget.onAutoMergeToggled != null) ...[
            Divider(color: borderColor, height: 1),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: EdenSpacing.space4,
                vertical: EdenSpacing.space3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Auto-merge',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: EdenSpacing.space1 / 2),
                        Text(
                          'Merge automatically when all requirements are met',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? EdenColors.neutral[400]!
                                : EdenColors.neutral[500]!,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: EdenSpacing.space2),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: widget.autoMergeEnabled,
                      onChanged: widget.onAutoMergeToggled,
                      activeThumbColor: EdenColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: EdenColors.warning.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(EdenRadii.lg),
          topRight: Radius.circular(EdenRadii.lg),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: EdenColors.warning,
          ),
          SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              'This branch has conflicts that must be resolved',
              style: theme.textTheme.bodySmall?.copyWith(
                color: EdenColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergeButton extends StatelessWidget {
  const _MergeButton({
    required this.strategy,
    required this.label,
    required this.enabled,
    this.onPressed,
  });

  final EdenMergeStrategy strategy;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  IconData _icon() {
    switch (strategy) {
      case EdenMergeStrategy.merge:
        return Icons.merge_type;
      case EdenMergeStrategy.squash:
        return Icons.compress;
      case EdenMergeStrategy.rebase:
        return Icons.low_priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = enabled ? EdenColors.success : EdenColors.neutral[400]!;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(EdenRadii.md),
        bottomLeft: Radius.circular(EdenRadii.md),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(EdenRadii.md),
          bottomLeft: Radius.circular(EdenRadii.md),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space4,
            vertical: EdenSpacing.space2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon(),
                size: 16,
                color: Colors.white,
              ),
              SizedBox(width: EdenSpacing.space2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategyDropdownButton extends StatelessWidget {
  const _StrategyDropdownButton({
    required this.enabled,
    required this.isOpen,
    required this.onTap,
  });

  final bool enabled;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = enabled ? EdenColors.success : EdenColors.neutral[400]!;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(EdenRadii.md),
        bottomRight: Radius.circular(EdenRadii.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(EdenRadii.md),
          bottomRight: Radius.circular(EdenRadii.md),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space2,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Icon(
            isOpen
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _StrategyOption extends StatelessWidget {
  const _StrategyOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: EdenRadii.borderRadiusSm,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space2,
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected
                    ? EdenColors.success
                    : (isDark
                        ? EdenColors.neutral[400]!
                        : EdenColors.neutral[500]!),
              ),
              SizedBox(width: EdenSpacing.space2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.passed,
  });

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: EdenSpacing.space2),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: passed ? EdenColors.success : EdenColors.error,
          ),
          SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
