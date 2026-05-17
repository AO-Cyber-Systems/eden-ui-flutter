// EdenWorkflowValidationPanel — popover surface for validator findings.
//
// Renders the issues list from EdenWorkflowValidationResult with severity-
// colored backgrounds + click-to-focus callback. Parity row V-3.

import 'package:flutter/material.dart';

import '../eden_process_canvas/process_models.dart'
    show EdenProcessValidationSeverity;
import 'workflow_validator.dart';

class EdenWorkflowValidationPanel extends StatelessWidget {
  const EdenWorkflowValidationPanel({
    super.key,
    required this.result,
    this.onIssueTap,
    this.onClose,
  });

  final EdenWorkflowValidationResult result;
  final ValueChanged<String>? onIssueTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = result.summary;
    final subtitle = result.isValid
        ? (summary.warnings > 0
            ? '${summary.warnings} warning(s) — workflow is activatable'
            : 'Workflow is ready to activate')
        : '${summary.errors} error(s) — fix before activating';

    return SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workflow Validation',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (result.issues.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('No issues detected.'),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: result.issues.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final issue = result.issues[i];
                  final isError =
                      issue.severity == EdenProcessValidationSeverity.error;
                  final bg = isError
                      ? Colors.red.shade50
                      : Colors.amber.shade50;
                  final color =
                      isError ? Colors.red.shade700 : Colors.amber.shade800;
                  final icon = isError ? Icons.error : Icons.warning_amber;
                  return InkWell(
                    onTap: onIssueTap == null || issue.nodeId == null
                        ? null
                        : () => onIssueTap!.call(issue.nodeId!),
                    child: Container(
                      color: bg,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  issue.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (issue.suggestion != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    issue.suggestion!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
