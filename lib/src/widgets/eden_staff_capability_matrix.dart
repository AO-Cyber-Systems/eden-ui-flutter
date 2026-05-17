import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_avatar.dart';
import 'eden_service_catalog_tile.dart';

/// Staff row metadata for [EdenStaffCapabilityMatrix]. Distinct from
/// [EdenServiceStaff] (services-capability metadata in 016-01) and
/// [EdenTimeSlotStaff] (016-02 picker column) — this is the matrix row.
@immutable
class EdenStaffCapabilityRow {
  const EdenStaffCapabilityRow({
    required this.id,
    required this.displayName,
    required this.initials,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String initials;
  final String? avatarUrl;
}

/// One cell in the matrix — boolean "can perform" toggle.
@immutable
class EdenStaffCapability {
  const EdenStaffCapability({
    required this.staffId,
    required this.serviceId,
    required this.canPerform,
  });

  final String staffId;
  final String serviceId;
  final bool canPerform;
}

/// Staff × service capability grid. Composes [EdenServiceCatalogEntry] from
/// 016-01 for column headers. Tap a cell to flip "can perform".
class EdenStaffCapabilityMatrix extends StatelessWidget {
  const EdenStaffCapabilityMatrix({
    super.key,
    required this.staff,
    required this.services,
    required this.capabilities,
    required this.onCapabilityToggled,
  });

  final List<EdenStaffCapabilityRow> staff;
  final List<EdenServiceCatalogEntry> services;
  final List<EdenStaffCapability> capabilities;
  final void Function(String staffId, String serviceId, bool canPerform)
      onCapabilityToggled;

  Map<String, bool> _buildCapMap() {
    final m = <String, bool>{};
    for (final c in capabilities) {
      m['${c.staffId}|${c.serviceId}'] = c.canPerform;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final map = _buildCapMap();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Staff')),
          for (final s in services)
            DataColumn(
              label: SizedBox(
                width: 80,
                child: Text(
                  s.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
        rows: [
          for (final row in staff)
            DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EdenAvatar(
                        initials: row.initials,
                        image: row.avatarUrl != null
                            ? NetworkImage(row.avatarUrl!)
                            : null,
                        size: EdenAvatarSize.sm,
                      ),
                      const SizedBox(width: EdenSpacing.space2),
                      Text(row.displayName),
                    ],
                  ),
                ),
                for (final s in services)
                  DataCell(
                    Checkbox(
                      key: ValueKey('cap-${row.id}-${s.id}'),
                      tristate: false,
                      value: map['${row.id}|${s.id}'] ?? false,
                      onChanged: (v) =>
                          onCapabilityToggled(row.id, s.id, v ?? false),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
