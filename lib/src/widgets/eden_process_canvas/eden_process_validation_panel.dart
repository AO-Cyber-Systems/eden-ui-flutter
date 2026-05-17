import 'package:flutter/material.dart';

import 'process_models.dart';
import 'process_validator.dart';

/// Compact validation summary chip for `EdenVisualProcessCanvas`.
///
/// Renders a PopupMenuButton whose anchor is a Chip showing
/// errors / warnings / valid. Tapping the chip opens a list of issues;
/// selecting an issue fires `onIssueClicked(issue)` (consumers focus the
/// corresponding node).
class EdenProcessValidationPanel extends StatelessWidget {
  const EdenProcessValidationPanel({
    super.key,
    required this.result,
    this.onIssueClicked,
  });

  final EdenProcessValidationResult result;
  final void Function(EdenProcessValidationIssue issue)? onIssueClicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = result.summary;
    final chipColor = summary.errors > 0
        ? theme.colorScheme.error
        : summary.warnings > 0
            ? Colors.amber.shade700
            : Colors.green.shade700;
    final chipLabel = summary.errors > 0
        ? '${summary.errors} error${summary.errors > 1 ? 's' : ''}'
        : summary.warnings > 0
            ? '${summary.warnings} warning${summary.warnings > 1 ? 's' : ''}'
            : 'Valid';
    return PopupMenuButton<EdenProcessValidationIssue>(
      key: const ValueKey('validation-panel-popup'),
      tooltip: 'View validation issues',
      itemBuilder: (ctx) {
        if (result.issues.isEmpty) {
          return const [
            PopupMenuItem(
              enabled: false,
              child: Text('No issues found'),
            ),
          ];
        }
        return [
          for (final issue in result.issues)
            PopupMenuItem(
              value: issue,
              child: ListTile(
                leading: Icon(
                  issue.type == EdenProcessValidationSeverity.error
                      ? Icons.error
                      : Icons.warning,
                  color: issue.type == EdenProcessValidationSeverity.error
                      ? theme.colorScheme.error
                      : Colors.amber.shade700,
                ),
                title: Text(issue.message, style: theme.textTheme.bodySmall),
                subtitle: issue.suggestion != null
                    ? Text(
                        issue.suggestion!,
                        style: theme.textTheme.labelSmall,
                      )
                    : null,
              ),
            ),
        ];
      },
      onSelected: (issue) => onIssueClicked?.call(issue),
      child: Chip(
        avatar: Icon(
          summary.errors > 0
              ? Icons.warning
              : summary.warnings > 0
                  ? Icons.warning_amber
                  : Icons.check_circle,
          size: 14,
          color: chipColor,
        ),
        label: Text(chipLabel, style: TextStyle(color: chipColor)),
        side: BorderSide(color: chipColor),
      ),
    );
  }
}
