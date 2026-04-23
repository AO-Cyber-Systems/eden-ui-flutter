import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/radii.dart';

/// The validity status of an SSL/TLS certificate.
enum EdenCertificateStatus {
  /// Certificate is valid and not near expiry.
  valid,

  /// Certificate is valid but approaching its expiry date.
  expiringSoon,

  /// Certificate has expired.
  expired,
}

/// A card widget displaying SSL/TLS certificate details including subject,
/// issuer, expiry, and a regeneration action.
///
/// ```dart
/// EdenCertificateCard(
///   subject: '*.example.com',
///   issuer: "Let's Encrypt Authority X3",
///   expiry: '2026-12-01',
///   status: EdenCertificateStatus.valid,
///   onRegenerate: () => regenerateCert(),
/// )
/// ```
class EdenCertificateCard extends StatelessWidget {
  /// Creates an Eden certificate card.
  const EdenCertificateCard({
    super.key,
    required this.subject,
    this.issuer,
    this.expiry,
    required this.status,
    this.onRegenerate,
    this.loading = false,
  });

  /// The certificate subject (e.g. domain name).
  final String subject;

  /// The certificate issuer name.
  final String? issuer;

  /// The certificate expiry date string.
  final String? expiry;

  /// The current validity status of the certificate.
  final EdenCertificateStatus status;

  /// Callback invoked when the regenerate action is triggered.
  final VoidCallback? onRegenerate;

  /// Whether the card is in a loading state.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _CertificateStatusColors.forStatus(status);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? EdenColors.neutral[900]!
            : EdenColors.neutral[50]!,
        border: Border.all(
          color: isDark
              ? EdenColors.neutral[700]!
              : EdenColors.neutral[200]!,
        ),
        borderRadius: EdenRadii.borderRadiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(
            statusColor: statusColor,
            status: status,
            isDark: isDark,
            theme: theme,
          ),
          Divider(
            height: 1,
            color: isDark
                ? EdenColors.neutral[700]!
                : EdenColors.neutral[200]!,
          ),
          _Body(
            subject: subject,
            issuer: issuer,
            expiry: expiry,
            isDark: isDark,
            theme: theme,
          ),
          if (onRegenerate != null) ...[
            Divider(
              height: 1,
              color: isDark
                  ? EdenColors.neutral[700]!
                  : EdenColors.neutral[200]!,
            ),
            _Footer(
              onRegenerate: onRegenerate!,
              loading: loading,
              statusColor: statusColor,
            ),
          ],
        ],
      ),
    );
  }
}

class _CertificateStatusColors {
  static Color forStatus(EdenCertificateStatus status) {
    switch (status) {
      case EdenCertificateStatus.valid:
        return EdenColors.success;
      case EdenCertificateStatus.expiringSoon:
        return EdenColors.warning;
      case EdenCertificateStatus.expired:
        return EdenColors.error;
    }
  }

  static String labelForStatus(EdenCertificateStatus status) {
    switch (status) {
      case EdenCertificateStatus.valid:
        return 'Valid';
      case EdenCertificateStatus.expiringSoon:
        return 'Expiring Soon';
      case EdenCertificateStatus.expired:
        return 'Expired';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.statusColor,
    required this.status,
    required this.isDark,
    required this.theme,
  });

  final Color statusColor;
  final EdenCertificateStatus status;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_rounded,
            size: 18,
            color: statusColor,
          ),
          const SizedBox(width: EdenSpacing.space2),
          Expanded(
            child: Text(
              'SSL Certificate',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: EdenSpacing.space2,
              vertical: EdenSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: EdenRadii.borderRadiusSm,
            ),
            child: Text(
              _CertificateStatusColors.labelForStatus(status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.subject,
    this.issuer,
    this.expiry,
    required this.isDark,
    required this.theme,
  });

  final String subject;
  final String? issuer;
  final String? expiry;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(EdenSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow(
            label: 'Subject',
            value: subject,
            isDark: isDark,
            theme: theme,
          ),
          if (issuer != null) ...[
            const SizedBox(height: EdenSpacing.space2),
            _DetailRow(
              label: 'Issuer',
              value: issuer!,
              isDark: isDark,
              theme: theme,
            ),
          ],
          if (expiry != null) ...[
            const SizedBox(height: EdenSpacing.space2),
            _DetailRow(
              label: 'Expires',
              value: expiry!,
              isDark: isDark,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
    required this.theme,
  });

  final String label;
  final String value;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EdenColors.neutral[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: isDark
                  ? EdenColors.neutral[200]!
                  : EdenColors.neutral[800]!,
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onRegenerate,
    required this.loading,
    required this.statusColor,
  });

  final VoidCallback onRegenerate;
  final bool loading;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EdenSpacing.space4,
        vertical: EdenSpacing.space3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: loading ? null : onRegenerate,
            icon: loading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: statusColor,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 16),
            label: Text(loading ? 'Regenerating...' : 'Regenerate'),
          ),
        ],
      ),
    );
  }
}
