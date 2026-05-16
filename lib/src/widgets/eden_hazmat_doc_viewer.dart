import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'eden_attachment_preview.dart';

/// Driver hazmat cert status. Consumer maps domain semantics (expiry windows,
/// renewal grace periods) to this enum.
enum EdenHazmatCertStatus { valid, expiringSoon, expired, none }

/// Generic value class for [EdenHazmatDocViewer]. Consumer maps domain rows
/// (`hazmat_documents` + `users.cert_state` for fuel-delivery; equivalent
/// rows for insurance / OSHA / contractor-license consumers) to this class.
@immutable
class EdenHazmatDocData {
  const EdenHazmatDocData({
    required this.manifestAttachment,
    this.msdsAttachment,
    this.driverCertLabel,
    this.certStatus = EdenHazmatCertStatus.valid,
  });

  final EdenAttachment manifestAttachment;
  final EdenAttachment? msdsAttachment;

  /// e.g. 'DOT HM-126F • Driver J. Smith'. When null no cert pill renders.
  final String? driverCertLabel;
  final EdenHazmatCertStatus certStatus;
}

/// Read-only DOT manifest + MSDS overlay + driver-cert pill viewer.
///
/// Composes [EdenAttachmentPreview] for the manifest body and (in a modal
/// bottom sheet) the MSDS body. Generic — generalizes to any
/// document-with-overlay-cert viewer (insurance cards, OSHA training records,
/// contractor licenses).
///
/// v1 is read-only: no signature flow, no edit, no download. Signature
/// capture is a v2 follow-up (`005-future: EdenHazmatSignatureFlow` would
/// compose `eden_signature_pad`).
class EdenHazmatDocViewer extends StatelessWidget {
  const EdenHazmatDocViewer({
    super.key,
    required this.data,
    this.title = 'DOT Manifest',
    this.msdsButtonLabel = 'View MSDS',
  });

  final EdenHazmatDocData data;
  final String title;
  final String msdsButtonLabel;

  static Color _certColor(EdenHazmatCertStatus s) {
    switch (s) {
      case EdenHazmatCertStatus.valid:
        return EdenColors.success;
      case EdenHazmatCertStatus.expiringSoon:
        return EdenColors.warning;
      case EdenHazmatCertStatus.expired:
        return EdenColors.error;
      case EdenHazmatCertStatus.none:
        return const Color(0xFF94A3B8);
    }
  }

  static String _certSuffix(EdenHazmatCertStatus s) => switch (s) {
        EdenHazmatCertStatus.valid => 'Valid',
        EdenHazmatCertStatus.expiringSoon => 'Expiring soon',
        EdenHazmatCertStatus.expired => 'Expired',
        EdenHazmatCertStatus.none => 'No cert',
      };

  void _openMsdsSheet(BuildContext context, EdenAttachment msds) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(EdenSpacing.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Material Safety Data Sheet',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: EdenSpacing.space2),
              EdenAttachmentPreview(attachment: msds),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header — title + optional cert pill, wraps at narrow widths.
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (data.driverCertLabel != null)
              _CertPill(
                label: data.driverCertLabel!,
                color: _certColor(data.certStatus),
                suffix: _certSuffix(data.certStatus),
              ),
          ],
        ),
        const SizedBox(height: EdenSpacing.space3),
        // Manifest preview or unavailable placeholder.
        if (data.manifestAttachment.url == null)
          Container(
            padding: const EdgeInsets.all(EdenSpacing.space4),
            decoration: BoxDecoration(
              borderRadius: EdenRadii.borderRadiusMd,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: const Text('Manifest unavailable'),
          )
        else
          EdenAttachmentPreview(attachment: data.manifestAttachment),
        const SizedBox(height: EdenSpacing.space3),
        // MSDS button — disabled when no MSDS attachment.
        OutlinedButton.icon(
          icon: const Icon(Icons.science_outlined, size: 18),
          label: Text(msdsButtonLabel),
          onPressed: data.msdsAttachment == null
              ? null
              : () => _openMsdsSheet(context, data.msdsAttachment!),
        ),
      ],
    );
  }
}

class _CertPill extends StatelessWidget {
  const _CertPill({
    required this.label,
    required this.color,
    required this.suffix,
  });

  final String label;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('eden-hazmat-cert-pill'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label • $suffix',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
