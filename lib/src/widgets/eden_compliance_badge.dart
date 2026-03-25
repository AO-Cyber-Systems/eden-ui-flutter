import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// A single compliance rule with its pass/fail status.
class EdenComplianceRule {
  /// Creates a compliance rule.
  const EdenComplianceRule({
    required this.name,
    required this.passed,
    this.description,
  });

  /// The rule name or identifier.
  final String name;

  /// Whether this rule passed.
  final bool passed;

  /// An optional description of the rule.
  final String? description;
}

/// A compact, expandable badge showing overall compliance status across
/// a set of rules. Displays a summary count (e.g. "3/4 rules passed")
/// and can expand to show individual rule results.
///
/// ```dart
/// EdenComplianceBadge(
///   rules: [
///     EdenComplianceRule(name: 'HIPAA', passed: true),
///     EdenComplianceRule(name: 'SOC2', passed: true),
///     EdenComplianceRule(name: 'PCI-DSS', passed: false, description: 'Missing encryption at rest'),
///   ],
/// )
/// ```
class EdenComplianceBadge extends StatefulWidget {
  /// Creates an Eden compliance badge.
  const EdenComplianceBadge({
    super.key,
    required this.rules,
  });

  /// The list of compliance rules to evaluate.
  final List<EdenComplianceRule> rules;

  @override
  State<EdenComplianceBadge> createState() => _EdenComplianceBadgeState();
}

class _EdenComplianceBadgeState extends State<EdenComplianceBadge>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final passedCount = widget.rules.where((r) => r.passed).length;
    final totalCount = widget.rules.length;
    final allPassed = passedCount == totalCount;
    final nonePassed = passedCount == 0;

    final statusColor = allPassed
        ? EdenColors.success
        : nonePassed
            ? EdenColors.error
            : EdenColors.warning;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Compact badge
        GestureDetector(
          onTap: _toggleExpanded,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space3,
              vertical: EdenSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
              borderRadius: _isExpanded
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(EdenRadii.md),
                      topRight: Radius.circular(EdenRadii.md),
                    )
                  : EdenRadii.borderRadiusMd,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  allPassed
                      ? Icons.verified_rounded
                      : nonePassed
                          ? Icons.gpp_bad_rounded
                          : Icons.gpp_maybe_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: EdenSpacing.space2),
                Text(
                  '$passedCount/$totalCount rules passed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: EdenSpacing.space1),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable detail
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? EdenColors.neutral[900]
                  : EdenColors.neutral[50],
              border: Border(
                left: BorderSide(
                  color: statusColor.withValues(alpha: 0.3),
                ),
                right: BorderSide(
                  color: statusColor.withValues(alpha: 0.3),
                ),
                bottom: BorderSide(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(EdenRadii.md),
                bottomRight: Radius.circular(EdenRadii.md),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.rules.length; i++)
                  _ComplianceRuleRow(
                    rule: widget.rules[i],
                    isDark: isDark,
                    showBorder: i < widget.rules.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ComplianceRuleRow extends StatelessWidget {
  const _ComplianceRuleRow({
    required this.rule,
    required this.isDark,
    required this.showBorder,
  });

  final EdenComplianceRule rule;
  final bool isDark;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space3,
        vertical: EdenSpacing.space2,
      ),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? EdenColors.neutral[800]!
                      : EdenColors.neutral[200]!,
                ),
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(
            rule.passed
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 16,
            color: rule.passed ? EdenColors.success : EdenColors.error,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rule.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (rule.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    rule.description!,
                    style: TextStyle(
                      fontSize: 11,
                      color: EdenColors.neutral[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
