import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The authentication type for a service account.
enum EdenAuthType {
  /// OAuth-based authentication.
  oauth,

  /// API key-based authentication.
  apiKey,
}

/// The current status of a service account.
enum EdenAccountStatus {
  /// Account is active and operational.
  active,

  /// Account is temporarily paused.
  paused,

  /// Account has hit its rate limit.
  rateLimited,

  /// Account credentials have expired.
  expired,
}

/// A card displaying a service account with usage metrics and action controls.
///
/// Shows account identity, authentication type, current status, and optional
/// usage metrics including rate limits, session expiry, request counts,
/// response times, and error rates.
class EdenAccountCard extends StatelessWidget {
  const EdenAccountCard({
    super.key,
    required this.name,
    required this.authType,
    required this.status,
    this.rateLimitRemaining,
    this.rateLimitTotal,
    this.sessionExpiry,
    this.requestCount,
    this.avgResponseTime,
    this.errorRate,
    this.onPause,
    this.onResume,
    this.onTest,
    this.onRemove,
    this.loading = false,
  });

  /// Display name of the service account.
  final String name;

  /// The authentication method used by this account.
  final EdenAuthType authType;

  /// The current operational status.
  final EdenAccountStatus status;

  /// Number of rate-limited requests remaining, if applicable.
  final int? rateLimitRemaining;

  /// Total rate limit quota, if applicable.
  final int? rateLimitTotal;

  /// Human-readable session expiry time.
  final String? sessionExpiry;

  /// Total number of requests made.
  final int? requestCount;

  /// Average response time as a formatted string.
  final String? avgResponseTime;

  /// Error rate as a formatted string (e.g. "2.1%").
  final String? errorRate;

  /// Called when the user requests to pause the account.
  final VoidCallback? onPause;

  /// Called when the user requests to resume the account.
  final VoidCallback? onResume;

  /// Called when the user requests to test the account connection.
  final VoidCallback? onTest;

  /// Called when the user requests to remove the account.
  final VoidCallback? onRemove;

  /// Whether the card is in a loading state.
  final bool loading;

  Color _statusDotColor() {
    switch (status) {
      case EdenAccountStatus.active:
        return EdenColors.success;
      case EdenAccountStatus.paused:
        return EdenColors.neutral[400]!;
      case EdenAccountStatus.rateLimited:
        return EdenColors.warning;
      case EdenAccountStatus.expired:
        return EdenColors.error;
    }
  }

  String _statusLabel() {
    switch (status) {
      case EdenAccountStatus.active:
        return 'Active';
      case EdenAccountStatus.paused:
        return 'Paused';
      case EdenAccountStatus.rateLimited:
        return 'Rate Limited';
      case EdenAccountStatus.expired:
        return 'Expired';
    }
  }

  String _authTypeLabel() {
    switch (authType) {
      case EdenAuthType.oauth:
        return 'OAuth';
      case EdenAuthType.apiKey:
        return 'API Key';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final surfaceColor = isDark ? EdenColors.neutral[900]! : EdenColors.neutral[50]!;
    final borderColor = isDark ? EdenColors.neutral[700]! : EdenColors.neutral[200]!;
    final mutedTextColor = isDark ? EdenColors.neutral[400]! : EdenColors.neutral[500]!;

    return AnimatedOpacity(
      opacity: loading ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: EdgeInsets.all(EdenSpacing.space4),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: borderColor),
          borderRadius: EdenRadii.borderRadiusLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme, mutedTextColor),
            Padding(
              padding: EdgeInsets.symmetric(vertical: EdenSpacing.space3),
              child: Divider(height: 1, color: borderColor),
            ),
            _buildMetrics(theme, mutedTextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color mutedTextColor) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _statusDotColor(),
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: EdenSpacing.space2),
        Tooltip(
          message: _statusLabel(),
          child: Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: EdenSpacing.space2),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: EdenSpacing.space2,
            vertical: EdenSpacing.space1 / 2,
          ),
          decoration: BoxDecoration(
            color: EdenColors.info.withValues(alpha: 0.1),
            borderRadius: EdenRadii.borderRadiusSm,
          ),
          child: Text(
            _authTypeLabel(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: EdenColors.info,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        _buildActions(theme, mutedTextColor),
      ],
    );
  }

  Widget _buildActions(ThemeData theme, Color mutedTextColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == EdenAccountStatus.active && onPause != null)
          _ActionButton(
            icon: Icons.pause_circle_outline,
            tooltip: 'Pause',
            onPressed: loading ? null : onPause,
            color: mutedTextColor,
          )
        else if (status == EdenAccountStatus.paused && onResume != null)
          _ActionButton(
            icon: Icons.play_circle_outline,
            tooltip: 'Resume',
            onPressed: loading ? null : onResume,
            color: EdenColors.success,
          ),
        if (onTest != null)
          _ActionButton(
            icon: Icons.science_outlined,
            tooltip: 'Test Connection',
            onPressed: loading ? null : onTest,
            color: mutedTextColor,
          ),
        if (onRemove != null)
          _ActionButton(
            icon: Icons.delete_outline,
            tooltip: 'Remove',
            onPressed: loading ? null : onRemove,
            color: EdenColors.error,
          ),
      ],
    );
  }

  Widget _buildMetrics(ThemeData theme, Color mutedTextColor) {
    final hasRateLimit =
        rateLimitRemaining != null && rateLimitTotal != null && rateLimitTotal! > 0;
    final hasAnyMetric = hasRateLimit ||
        sessionExpiry != null ||
        requestCount != null ||
        avgResponseTime != null ||
        errorRate != null;

    if (!hasAnyMetric) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: EdenSpacing.space4,
      runSpacing: EdenSpacing.space2,
      children: [
        if (hasRateLimit)
          _RateLimitIndicator(
            remaining: rateLimitRemaining!,
            total: rateLimitTotal!,
            textStyle: theme.textTheme.bodySmall,
            mutedColor: mutedTextColor,
          ),
        if (sessionExpiry != null)
          _MetricChip(
            label: 'Expires',
            value: sessionExpiry!,
            icon: Icons.schedule,
            textStyle: theme.textTheme.bodySmall,
            mutedColor: mutedTextColor,
          ),
        if (requestCount != null)
          _MetricChip(
            label: 'Requests',
            value: requestCount.toString(),
            icon: Icons.sync_alt,
            textStyle: theme.textTheme.bodySmall,
            mutedColor: mutedTextColor,
          ),
        if (avgResponseTime != null)
          _MetricChip(
            label: 'Avg Response',
            value: avgResponseTime!,
            icon: Icons.speed,
            textStyle: theme.textTheme.bodySmall,
            mutedColor: mutedTextColor,
          ),
        if (errorRate != null)
          _MetricChip(
            label: 'Error Rate',
            value: errorRate!,
            icon: Icons.error_outline,
            textStyle: theme.textTheme.bodySmall,
            mutedColor: mutedTextColor,
            valueColor: EdenColors.error,
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: EdenRadii.borderRadiusSm,
          child: Padding(
            padding: EdgeInsets.all(EdenSpacing.space1),
            child: Icon(icon, size: 18, color: onPressed != null ? color : color.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}

class _RateLimitIndicator extends StatelessWidget {
  const _RateLimitIndicator({
    required this.remaining,
    required this.total,
    required this.textStyle,
    required this.mutedColor,
  });

  final int remaining;
  final int total;
  final TextStyle? textStyle;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final ratio = remaining / total;
    final barColor = ratio > 0.5
        ? EdenColors.success
        : ratio > 0.2
            ? EdenColors.warning
            : EdenColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.data_usage, size: 14, color: mutedColor),
        SizedBox(width: EdenSpacing.space1),
        Text(
          'Rate Limit',
          style: textStyle?.copyWith(color: mutedColor),
        ),
        SizedBox(width: EdenSpacing.space2),
        SizedBox(
          width: 60,
          height: 4,
          child: ClipRRect(
            borderRadius: EdenRadii.borderRadiusSm,
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              backgroundColor: mutedColor.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        SizedBox(width: EdenSpacing.space1),
        Text(
          '$remaining/$total',
          style: textStyle?.copyWith(
            color: mutedColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.textStyle,
    required this.mutedColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final TextStyle? textStyle;
  final Color mutedColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: mutedColor),
        SizedBox(width: EdenSpacing.space1),
        Text(
          '$label: ',
          style: textStyle?.copyWith(color: mutedColor),
        ),
        Text(
          value,
          style: textStyle?.copyWith(
            color: valueColor ?? mutedColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
