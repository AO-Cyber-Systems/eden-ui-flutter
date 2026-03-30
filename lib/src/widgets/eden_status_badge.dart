import 'package:flutter/material.dart';

/// Semantic status badge with automatic color mapping.
///
/// Renders a colored chip based on a status string. Includes a built-in
/// color mapping for common statuses (active, completed, pending, etc.)
/// which can be overridden via [statusColors].
///
/// ```dart
/// EdenStatusBadge(status: 'active')
/// EdenStatusBadge(status: 'overdue')
/// EdenStatusBadge(
///   status: 'custom',
///   statusColors: {'custom': Colors.purple},
/// )
/// ```
class EdenStatusBadge extends StatelessWidget {
  const EdenStatusBadge({
    super.key,
    required this.status,
    this.statusColors,
    this.size = EdenStatusBadgeSize.md,
  });

  final String status;

  /// Optional override for status-to-color mapping.
  final Map<String, Color>? statusColors;

  final EdenStatusBadgeSize size;

  /// Default status color mapping.
  static Color colorForStatus(String status) {
    return switch (status.toLowerCase()) {
      'active' || 'in_progress' || 'in progress' || 'confirmed' || 'approved' => Colors.green,
      'completed' || 'done' || 'closed' || 'received' || 'fulfilled' => Colors.blue,
      'on_hold' || 'on hold' || 'pending' || 'draft' || 'waiting' => Colors.orange,
      'cancelled' || 'canceled' || 'rejected' || 'overdue' || 'failed' => Colors.red,
      'scheduled' || 'planning' || 'open' || 'sent' || 'in_transit' => Colors.teal,
      'inactive' || 'archived' || 'expired' => Colors.grey,
      _ => Colors.grey,
    };
  }

  /// Formats a status string for display (replaces underscores, title case).
  static String formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color =
        statusColors?[status.toLowerCase()] ?? colorForStatus(status);
    final sizing = _resolveSizing();

    return Container(
      padding: sizing.padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        formatStatus(status),
        style: TextStyle(
          fontSize: sizing.fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  _StatusBadgeSizing _resolveSizing() {
    switch (size) {
      case EdenStatusBadgeSize.sm:
        return const _StatusBadgeSizing(
          EdgeInsets.symmetric(horizontal: 8, vertical: 2), 11);
      case EdenStatusBadgeSize.md:
        return const _StatusBadgeSizing(
          EdgeInsets.symmetric(horizontal: 10, vertical: 4), 12);
      case EdenStatusBadgeSize.lg:
        return const _StatusBadgeSizing(
          EdgeInsets.symmetric(horizontal: 12, vertical: 5), 13);
    }
  }
}

enum EdenStatusBadgeSize { sm, md, lg }

class _StatusBadgeSizing {
  const _StatusBadgeSizing(this.padding, this.fontSize);
  final EdgeInsets padding;
  final double fontSize;
}
