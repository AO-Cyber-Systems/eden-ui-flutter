import 'package:flutter/material.dart';
import 'eden_badge.dart';

/// Opinionated status → variant lookup atop [EdenBadge].
///
/// Maps an admin/ops status string (e.g. `active`, `blocked`, `pending`,
/// `fired`) to a [EdenBadgeVariant] + matching icon. The match is
/// case-insensitive; underscores are converted to spaces and each word is
/// capitalized for the rendered label (`in_progress` → `In Progress`).
///
/// Recognized status vocabulary:
/// - **success** — `active`, `healthy`, `passed`, `completed`, `resolved`,
///   `success`, `delivered`
/// - **danger** — `blocked`, `error`, `failed`, `unhealthy`, `rejected`,
///   `cancelled`
/// - **warning** — `warning`, `degraded`, `soft_limit`, `fired`, `acknowledged`
/// - **info** — `pending`, `processing`, `in_progress`, `queued`
/// - **neutral** — `expired`, `inactive`, `suspended`, `disabled`, and any
///   string not in the above tables
class EdenStatusBadge extends StatelessWidget {
  const EdenStatusBadge({
    super.key,
    required this.status,
    this.size = EdenBadgeSize.sm,
  });

  /// The status string. Case-insensitive; `_` is rendered as a space.
  final String status;

  /// Forwarded to the underlying [EdenBadge].
  final EdenBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(status.toLowerCase());
    return EdenBadge(
      label: config.label,
      variant: config.variant,
      size: size,
      icon: config.icon,
    );
  }

  static _BadgeConfig _resolveConfig(String status) {
    switch (status) {
      case 'active':
      case 'healthy':
      case 'passed':
      case 'completed':
      case 'resolved':
      case 'success':
      case 'delivered':
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.success,
          icon: Icons.check_circle_outline,
        );
      case 'blocked':
      case 'error':
      case 'failed':
      case 'unhealthy':
      case 'rejected':
      case 'cancelled':
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.danger,
          icon: Icons.cancel_outlined,
        );
      case 'warning':
      case 'degraded':
      case 'soft_limit':
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.warning,
          icon: Icons.warning_amber,
        );
      case 'pending':
      case 'processing':
      case 'in_progress':
      case 'queued':
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.info,
          icon: Icons.schedule,
        );
      case 'fired':
      case 'acknowledged':
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.warning,
          icon: Icons.notifications_active,
        );
      case 'expired':
      case 'inactive':
      case 'suspended':
      case 'disabled':
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.neutral,
        );
      default:
        return _BadgeConfig(
          label: _capitalize(status),
          variant: EdenBadgeVariant.neutral,
        );
    }
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }
}

class _BadgeConfig {
  const _BadgeConfig({
    required this.label,
    required this.variant,
    this.icon,
  });

  final String label;
  final EdenBadgeVariant variant;
  final IconData? icon;
}
