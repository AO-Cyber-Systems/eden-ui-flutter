import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_description_list.dart';
import 'eden_status_badge.dart';
import 'eden_timeline.dart';

/// Type of warranty backing the equipment.
enum EdenEquipmentWarrantyType { manufacturer, parts, labor, extended }

/// Display variant for [EdenEquipmentRecordCard].
enum EdenEquipmentRecordVariant { detailed, compact }

/// Warranty status snapshot for a piece of equipment.
@immutable
class EdenEquipmentWarrantyStatus {
  const EdenEquipmentWarrantyStatus({
    required this.expiresOn,
    required this.type,
    this.coverageNotes,
  });

  final DateTime expiresOn;
  final EdenEquipmentWarrantyType type;
  final String? coverageNotes;

  /// Remaining duration. Negative when expired.
  Duration get remaining {
    return expiresOn.difference(DateTime.now());
  }

  bool get isExpired => remaining.isNegative;

  bool get isExpiringSoon {
    final r = remaining;
    return !r.isNegative && r.inDays < 90;
  }

  String get typeLabel {
    switch (type) {
      case EdenEquipmentWarrantyType.manufacturer:
        return 'Manufacturer';
      case EdenEquipmentWarrantyType.parts:
        return 'Parts';
      case EdenEquipmentWarrantyType.labor:
        return 'Labor';
      case EdenEquipmentWarrantyType.extended:
        return 'Extended';
    }
  }
}

/// Maintenance / service-agreement status.
@immutable
class EdenEquipmentAgreementStatus {
  const EdenEquipmentAgreementStatus({
    required this.tierName,
    required this.renewsOn,
    required this.isActive,
  });

  final String tierName;
  final DateTime renewsOn;
  final bool isActive;
}

/// Past service event for a piece of equipment.
@immutable
class EdenEquipmentServiceHistoryEntry {
  const EdenEquipmentServiceHistoryEntry({
    required this.id,
    required this.serviceDate,
    required this.summary,
    this.technicianName,
    this.photoUrls = const [],
  });

  final String id;
  final DateTime serviceDate;
  final String summary;
  final String? technicianName;
  final List<String> photoUrls;
}

/// Immutable container for a single piece of installed equipment.
@immutable
class EdenEquipmentRecordData {
  const EdenEquipmentRecordData({
    required this.id,
    required this.name,
    required this.type,
    required this.customerId,
    required this.location,
    this.make,
    this.model,
    this.serialNumber,
    this.installDate,
    this.warrantyStatus,
    this.agreementStatus,
    this.serviceHistory = const [],
    this.photoUrls = const [],
  });

  final String id;
  final String name;
  final String type; // HVAC / Plumbing / Electrical / Tank / Generator / ...
  final String customerId;
  final String location;
  final String? make;
  final String? model;
  final String? serialNumber;
  final DateTime? installDate;
  final EdenEquipmentWarrantyStatus? warrantyStatus;
  final EdenEquipmentAgreementStatus? agreementStatus;
  final List<EdenEquipmentServiceHistoryEntry> serviceHistory;
  final List<String> photoUrls;
}

/// Equipment detail card — generic across trades HVAC/plumbing/electrical
/// equipment AND fuel customer tanks. Renders header + metadata + warranty +
/// agreement + photo gallery + service history.
///
/// Composes obj 001-04 EdenDescriptionList + EdenTimeline + EdenStatusBadge.
class EdenEquipmentRecordCard extends StatelessWidget {
  const EdenEquipmentRecordCard({
    super.key,
    required this.data,
    this.onFileWarrantyClaim,
    this.onAddService,
    this.onViewServiceHistoryEntry,
    this.variant = EdenEquipmentRecordVariant.detailed,
  });

  final EdenEquipmentRecordData data;
  final VoidCallback? onFileWarrantyClaim;
  final VoidCallback? onAddService;
  final ValueChanged<String>? onViewServiceHistoryEntry;
  final EdenEquipmentRecordVariant variant;

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _warrantyStatusLabel(EdenEquipmentWarrantyStatus? w) {
    if (w == null) return 'no warranty';
    if (w.isExpired) return 'expired';
    if (w.isExpiringSoon) return 'warning';
    return 'active';
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    final isCompact = variant == EdenEquipmentRecordVariant.compact;
    return EdenCard(
      child: Padding(
        padding: const EdgeInsets.all(EdenSpacing.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, palette),
            if (!isCompact) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildMetadata(context),
            ],
            if (data.warrantyStatus != null) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildWarrantySection(context, palette),
            ],
            if (!isCompact && data.agreementStatus != null) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildAgreementSection(context, palette),
            ],
            if (!isCompact && data.photoUrls.isNotEmpty) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildPhotoGallery(context),
            ],
            if (!isCompact && data.serviceHistory.isNotEmpty) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildServiceHistory(context),
            ],
            if (onAddService != null || onFileWarrantyClaim != null) ...[
              const SizedBox(height: EdenSpacing.space3),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EdenStatusPalette? palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.name,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(data.type,
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
        if (data.warrantyStatus != null)
          EdenStatusBadge(
              status: _warrantyStatusLabel(data.warrantyStatus)),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return EdenDescriptionList(
      items: [
        EdenDescriptionItem(label: 'Make', value: data.make ?? '—'),
        EdenDescriptionItem(label: 'Model', value: data.model ?? '—'),
        EdenDescriptionItem(
            label: 'Serial', value: data.serialNumber ?? '—'),
        EdenDescriptionItem(
            label: 'Installed', value: _formatDate(data.installDate)),
        EdenDescriptionItem(label: 'Location', value: data.location),
      ],
    );
  }

  Widget _buildWarrantySection(
      BuildContext context, EdenStatusPalette? palette) {
    final w = data.warrantyStatus!;
    final remaining = w.remaining;
    final daysLabel = w.isExpired
        ? 'expired ${(-remaining.inDays)}d ago'
        : '${remaining.inDays} days remaining';
    final color = w.isExpired
        ? (palette?.dangerFg ?? EdenColors.error)
        : w.isExpiringSoon
            ? (palette?.warningFg ?? EdenColors.warning)
            : (palette?.successFg ?? EdenColors.success);
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${w.typeLabel} warranty',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  'Expires ${_formatDate(w.expiresOn)} — $daysLabel',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (w.coverageNotes != null)
                  Text(w.coverageNotes!,
                      style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgreementSection(
      BuildContext context, EdenStatusPalette? palette) {
    final a = data.agreementStatus!;
    final color = a.isActive
        ? (palette?.successFg ?? EdenColors.success)
        : (palette?.warningFg ?? EdenColors.warning);
    return Container(
      padding: const EdgeInsets.all(EdenSpacing.space3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${a.tierName} — renews ${_formatDate(a.renewsOn)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: data.photoUrls
          .map((u) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: EdenColors.neutral[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.photo, size: 28),
              ))
          .toList(),
    );
  }

  Widget _buildServiceHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Service history',
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        EdenTimeline(
          items: data.serviceHistory
              .map((e) => EdenTimelineItemData(
                    title: e.summary,
                    datetime: _formatDate(e.serviceDate),
                    body: e.technicianName != null
                        ? 'by ${e.technicianName}'
                        : null,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onAddService != null) ...[
          OutlinedButton.icon(
            key: const Key('equipment-add-service'),
            onPressed: onAddService,
            icon: const Icon(Icons.build, size: 14),
            label: const Text('Add Service'),
          ),
          const SizedBox(width: 12),
        ],
        if (onFileWarrantyClaim != null)
          ElevatedButton.icon(
            key: const Key('equipment-file-warranty-claim'),
            onPressed: onFileWarrantyClaim,
            icon: const Icon(Icons.policy, size: 14),
            label: const Text('File Warranty Claim'),
          ),
      ],
    );
  }
}
