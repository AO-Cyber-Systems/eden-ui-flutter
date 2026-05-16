import 'package:flutter/material.dart';

/// Cross-vertical approval-status pill badge.
///
/// Renders a filled rounded pill with a status label, color-coded by status.
/// The donor's `switch` is case-sensitive — mixed-case input falls to the
/// default branch and renders the raw string with underscores replaced by
/// spaces, on a neutral `onSurfaceVariant` tone.
///
/// Recognised statuses:
/// - `pending` (alias `pending_approval`) → "Pending" (amber)
/// - `approved` → "Approved" (green)
/// - `rejected` → "Rejected" (theme error)
/// - `draft` → "Draft" (onSurfaceVariant)
/// - `ordered` → "Ordered" (blue)
/// - `received` → "Received" (teal)
/// - `in_transit` → "In Transit" (blue) — label is hand-written with a space,
///   NOT generated via `replaceAll('_', ' ')`.
/// - `completed` → "Completed" (green)
/// - `fulfilled` → "Fulfilled" (green)
/// - `cancelled` → "Cancelled" (onSurfaceVariant)
/// - (default) → `status.replaceAll('_', ' ')` (onSurfaceVariant). Mixed-case
///   inputs like `Approved` fall here.
///
/// Cross-vertical examples:
/// - Trades: purchase orders, change orders, work-order approvals.
/// - Salon: membership approval workflow.
/// - Medical: referral / prior-auth approval.
/// - Legal: filing approval.
/// - Government: permit approval.
/// - Retail: return / refund approval.
///
/// Donor: `trades-flutter/lib/shared/widgets/approval_status_badge.dart`.
class EdenApprovalStatusBadge extends StatelessWidget {
  const EdenApprovalStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  /// Approval-status string. Case-sensitive; aliases supported (see class doc).
  final String status;

  /// Optional font-size override. When null the label inherits the size of
  /// `theme.textTheme.labelSmall`.
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _getConfig(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      // Note: donor wraps `Text` directly in `Container` (no Row); a stray
      // Flexible here would assert (Flexible requires a Flex ancestor).
      // iPhone-narrow safety is delivered via TextOverflow.ellipsis instead.
      child: Text(
        config.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: config.textColor,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  _BadgeConfig _getConfig(ThemeData theme) {
    switch (status) {
      case 'pending':
      case 'pending_approval':
        return _BadgeConfig(
          label: 'Pending',
          backgroundColor: Colors.amber.withValues(alpha: 0.15),
          textColor: Colors.amber.shade800,
        );
      case 'approved':
        return _BadgeConfig(
          label: 'Approved',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          textColor: Colors.green.shade800,
        );
      case 'rejected':
        return _BadgeConfig(
          label: 'Rejected',
          backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
          textColor: theme.colorScheme.error,
        );
      case 'draft':
        return _BadgeConfig(
          label: 'Draft',
          backgroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          textColor: theme.colorScheme.onSurfaceVariant,
        );
      case 'ordered':
        return _BadgeConfig(
          label: 'Ordered',
          backgroundColor: Colors.blue.withValues(alpha: 0.15),
          textColor: Colors.blue.shade800,
        );
      case 'received':
        return _BadgeConfig(
          label: 'Received',
          backgroundColor: Colors.teal.withValues(alpha: 0.15),
          textColor: Colors.teal.shade800,
        );
      case 'in_transit':
        return _BadgeConfig(
          label: 'In Transit',
          backgroundColor: Colors.blue.withValues(alpha: 0.15),
          textColor: Colors.blue.shade800,
        );
      case 'completed':
        return _BadgeConfig(
          label: 'Completed',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          textColor: Colors.green.shade800,
        );
      case 'fulfilled':
        return _BadgeConfig(
          label: 'Fulfilled',
          backgroundColor: Colors.green.withValues(alpha: 0.15),
          textColor: Colors.green.shade800,
        );
      case 'cancelled':
        return _BadgeConfig(
          label: 'Cancelled',
          backgroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          textColor: theme.colorScheme.onSurfaceVariant,
        );
      default:
        return _BadgeConfig(
          label: status.replaceAll('_', ' '),
          backgroundColor:
              theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
          textColor: theme.colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _BadgeConfig {
  const _BadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
}
