import 'package:flutter/material.dart';

/// Severity level for a blocking alert. Drives both the container tint and
/// the per-alert icon tint:
/// - `red` → `Colors.red` (highest severity)
/// - `amber` → `Colors.amber`
///
/// Mixed lists take the highest severity present — any `red` alert makes the
/// container red-tinted.
enum EdenBlockingSeverity { red, amber }

/// A single action button rendered as a per-alert OutlinedButton.
///
/// Library-owned (no trades dependency). `onPressed` is required; null
/// callbacks should be filtered out by the consumer before passing in.
class EdenBlockingAction {
  const EdenBlockingAction({required this.label, required this.onPressed});

  /// Button label.
  final String label;

  /// Tap callback.
  final VoidCallback onPressed;
}

/// Pure data for a single row inside [EdenBlockingAlerts].
///
/// The library does NOT bind to vertical-specific entity models — consumers
/// map their domain (e.g. trades work-order, salon booking blocker, medical
/// referral hold) to this shape themselves.
class EdenBlockingAlertData {
  const EdenBlockingAlertData({
    required this.task,
    required this.context,
    required this.reason,
    this.severity = EdenBlockingSeverity.red,
    this.actions = const <EdenBlockingAction>[],
  });

  /// Display name of the blocked unit of work (e.g. "Install HVAC").
  final String task;

  /// Context / phase label (e.g. "Phase 2").
  final String context;

  /// Human-readable blocker reason (e.g. "Waiting on permit approval").
  final String reason;

  /// Severity tint (defaults to [EdenBlockingSeverity.red]).
  final EdenBlockingSeverity severity;

  /// Optional per-alert action buttons (rendered as OutlinedButtons).
  final List<EdenBlockingAction> actions;
}

/// Renders a collapsible list of blocking alerts with severity-colored
/// borders.
///
/// If `alerts` is empty, renders [SizedBox.shrink] (no header, no border).
/// Container border + header text color follow the highest severity present:
/// any `red` alert makes the container red-tinted; otherwise amber.
///
/// Header text uses singular vs plural: `'1 blocked item'` / `'N blocked items'`.
///
/// Tap-to-toggle is enabled only when count > 1 — single-alert lists have no
/// chevron and the header `InkWell` is non-interactive.
///
/// Donor: `trades-flutter/lib/shared/widgets/blocking_alerts.dart`.
class EdenBlockingAlerts extends StatefulWidget {
  const EdenBlockingAlerts({super.key, required this.alerts});

  final List<EdenBlockingAlertData> alerts;

  @override
  State<EdenBlockingAlerts> createState() => _EdenBlockingAlertsState();
}

class _EdenBlockingAlertsState extends State<EdenBlockingAlerts> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();

    final hasRed =
        widget.alerts.any((a) => a.severity == EdenBlockingSeverity.red);
    final severityColor = hasRed ? Colors.red : Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.03),
        border: Border.all(color: severityColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(severityColor),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < widget.alerts.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: severityColor.withValues(alpha: 0.1),
                          ),
                        _buildAlertItem(widget.alerts[i]),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color severityColor) {
    final theme = Theme.of(context);
    final count = widget.alerts.length;

    return InkWell(
      onTap: count > 1 ? () => setState(() => _expanded = !_expanded) : null,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.warning_rounded, size: 18, color: severityColor),
            const SizedBox(width: 8),
            Text(
              '$count blocked item${count == 1 ? '' : 's'}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: severityColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (count > 1)
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(EdenBlockingAlertData alert) {
    final theme = Theme.of(context);
    final color = alert.severity == EdenBlockingSeverity.red
        ? Colors.red
        : Colors.amber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lock icon with severity-tinted background.
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.lock_outline, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          // Task info + reason + actions.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.task} — ${alert.context}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  alert.reason,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (alert.actions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: alert.actions
                        .map(
                          (action) => SizedBox(
                            height: 28,
                            child: OutlinedButton(
                              onPressed: action.onPressed,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                textStyle: const TextStyle(fontSize: 12),
                                side: BorderSide(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.3),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(action.label),
                            ),
                          ),
                        )
                        .toList(),
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
