import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The SSL certificate status of a domain.
enum EdenSslStatus {
  /// Certificate is valid and not near expiry.
  valid,

  /// Certificate is valid but approaching its expiry date.
  expiringSoon,

  /// Certificate has expired.
  expired,

  /// No SSL certificate is configured.
  missing,
}

/// The DNS resolution status of a domain.
enum EdenDnsStatus {
  /// Domain resolves correctly.
  resolved,

  /// Domain resolves but with warnings (e.g. propagation delay).
  warning,

  /// Domain does not resolve.
  missing,
}

/// A row widget displaying a domain with its SSL and DNS status badges.
///
/// Supports wildcard domains and optional source labels.
///
/// ```dart
/// EdenDomainRow(
///   domain: 'api.example.com',
///   sslStatus: EdenSslStatus.valid,
///   sslExpiry: '2026-12-01',
///   dnsStatus: EdenDnsStatus.resolved,
///   onTap: () => navigateToDomain('api.example.com'),
/// )
/// ```
class EdenDomainRow extends StatelessWidget {
  /// Creates an Eden domain row.
  const EdenDomainRow({
    super.key,
    required this.domain,
    this.isWildcard = false,
    this.source,
    this.sslStatus = EdenSslStatus.missing,
    this.sslExpiry,
    this.dnsStatus = EdenDnsStatus.missing,
    this.onTap,
  });

  /// The domain name to display.
  final String domain;

  /// Whether this is a wildcard domain entry.
  final bool isWildcard;

  /// The source or origin of this domain (e.g. 'Cloudflare', 'manual').
  final String? source;

  /// The current SSL certificate status.
  final EdenSslStatus sslStatus;

  /// The SSL certificate expiry date string.
  final String? sslExpiry;

  /// The current DNS resolution status.
  final EdenDnsStatus dnsStatus;

  /// Callback invoked when the row is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Domain: $domain',
      button: onTap != null,
      child: InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: EdenSpacing.space4,
          vertical: EdenSpacing.space3,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? EdenColors.neutral[800]!
                  : EdenColors.neutral[200]!,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                domain,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWildcard) ...[
              SizedBox(width: EdenSpacing.space2),
              _Badge(
                label: 'wildcard',
                color: EdenColors.info,
                isDark: isDark,
              ),
            ],
            if (source != null) ...[
              SizedBox(width: EdenSpacing.space2),
              _Badge(
                label: source!,
                color: EdenColors.neutral[500]!,
                isDark: isDark,
              ),
            ],
            SizedBox(width: EdenSpacing.space2),
            _SslBadge(
              status: sslStatus,
              expiry: sslExpiry,
              isDark: isDark,
            ),
            SizedBox(width: EdenSpacing.space2),
            _DnsBadge(
              status: dnsStatus,
              isDark: isDark,
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  final String label;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EdenSpacing.space2,
        vertical: EdenSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: EdenRadii.borderRadiusSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _SslBadge extends StatelessWidget {
  const _SslBadge({
    required this.status,
    this.expiry,
    required this.isDark,
  });

  final EdenSslStatus status;
  final String? expiry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = _SslStatusColors.forStatus(status);
    final label = _SslStatusColors.labelForStatus(status, expiry);

    return _Badge(
      label: label,
      color: color,
      isDark: isDark,
    );
  }
}

class _SslStatusColors {
  static Color forStatus(EdenSslStatus status) {
    switch (status) {
      case EdenSslStatus.valid:
        return EdenColors.success;
      case EdenSslStatus.expiringSoon:
        return EdenColors.warning;
      case EdenSslStatus.expired:
        return EdenColors.error;
      case EdenSslStatus.missing:
        return EdenColors.neutral[500]!;
    }
  }

  static String labelForStatus(EdenSslStatus status, String? expiry) {
    switch (status) {
      case EdenSslStatus.valid:
        return expiry != null ? 'SSL $expiry' : 'SSL valid';
      case EdenSslStatus.expiringSoon:
        return expiry != null ? 'SSL expires $expiry' : 'SSL expiring';
      case EdenSslStatus.expired:
        return 'SSL expired';
      case EdenSslStatus.missing:
        return 'No SSL';
    }
  }
}

class _DnsBadge extends StatelessWidget {
  const _DnsBadge({
    required this.status,
    required this.isDark,
  });

  final EdenDnsStatus status;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = _DnsStatusColors.forStatus(status);
    final label = _DnsStatusColors.labelForStatus(status);

    return _Badge(
      label: label,
      color: color,
      isDark: isDark,
    );
  }
}

class _DnsStatusColors {
  static Color forStatus(EdenDnsStatus status) {
    switch (status) {
      case EdenDnsStatus.resolved:
        return EdenColors.success;
      case EdenDnsStatus.warning:
        return EdenColors.warning;
      case EdenDnsStatus.missing:
        return EdenColors.neutral[500]!;
    }
  }

  static String labelForStatus(EdenDnsStatus status) {
    switch (status) {
      case EdenDnsStatus.resolved:
        return 'DNS ok';
      case EdenDnsStatus.warning:
        return 'DNS warn';
      case EdenDnsStatus.missing:
        return 'No DNS';
    }
  }
}
