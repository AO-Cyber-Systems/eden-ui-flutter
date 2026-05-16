import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_empty_state.dart';
import 'map_providers/eden_map_types.dart';

/// Generic per-stop status. Consumer maps domain row → this enum.
enum EdenRouteStopStatus { pending, enRoute, arrived, completed, skipped }

/// Generic value class for [EdenRouteStopList]. Consumer maps domain rows
/// (`delivery_route_stops`, medical-home-visit appointments, courier dispatch
/// stops, etc.) to this class.
@immutable
class EdenRouteStopData {
  const EdenRouteStopData({
    required this.id,
    required this.label,
    this.status = EdenRouteStopStatus.pending,
    this.estimatedArrival,
    this.address,
    this.payloadGal,
    this.notes,
  });

  final String id;
  final String label;
  final EdenRouteStopStatus status;
  final DateTime? estimatedArrival;
  final EdenAddress? address;

  /// Optional payload amount in gallons (fuel-delivery convention; consumers
  /// in other verticals may ignore).
  final double? payloadGal;
  final String? notes;
}

/// Ordered-stop sequence display with drag-reorder, ETA, status badges, and
/// address preview.
///
/// Generic — used by fuel-delivery dispatchers (`delivery_route_stops`), but
/// also reusable for medical home-visits, courier dispatch, sales call
/// sequences, school bus routes.
///
/// Composes [EdenAddress] from the map-types module; renders address as a
/// single-line `{streetLine1}, {city}, {regionCode}` preview with ellipsis.
///
/// Reorder math gotcha — Flutter `ReorderableListView.onReorder` fires
/// `newIndex` as the index AFTER removal (so moving 0→2 fires newIndex=3).
/// This widget adjusts the index BEFORE invoking the consumer's [onReorder]
/// so consumers always receive intuitive `(oldIndex, newIndex)` pairs.
class EdenRouteStopList extends StatelessWidget {
  const EdenRouteStopList({
    super.key,
    required this.stops,
    this.onStopTap,
    this.onStatusTap,
    this.onReorder,
    this.reorderable = true,
    this.emptyMessage = 'No stops planned',
  });

  final List<EdenRouteStopData> stops;
  final void Function(String stopId)? onStopTap;
  final void Function(String stopId)? onStatusTap;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool reorderable;
  final String emptyMessage;

  static String _statusLabel(EdenRouteStopStatus s) => switch (s) {
        EdenRouteStopStatus.pending => 'Pending',
        EdenRouteStopStatus.enRoute => 'En route',
        EdenRouteStopStatus.arrived => 'Arrived',
        EdenRouteStopStatus.completed => 'Completed',
        EdenRouteStopStatus.skipped => 'Skipped',
      };

  static Color _statusColor(EdenRouteStopStatus s) {
    switch (s) {
      case EdenRouteStopStatus.pending:
        return const Color(0xFF94A3B8); // slate-400 (no token alias)
      case EdenRouteStopStatus.enRoute:
        return const Color(0xFF3B82F6); // blue-500 (matches EdenColors.info)
      case EdenRouteStopStatus.arrived:
        return EdenColors.warning;
      case EdenRouteStopStatus.completed:
        return EdenColors.success;
      case EdenRouteStopStatus.skipped:
        return EdenColors.error;
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute;
    final am = h < 12;
    final h12 = (h == 0) ? 12 : (h > 12 ? h - 12 : h);
    final mm = m.toString().padLeft(2, '0');
    return '~$h12:$mm ${am ? 'AM' : 'PM'}';
  }

  static String _addressLine(EdenAddress a) {
    final parts = <String>[];
    if (a.streetLine1.isNotEmpty) parts.add(a.streetLine1);
    if (a.city.isNotEmpty) parts.add(a.city);
    if (a.regionCode.isNotEmpty) parts.add(a.regionCode);
    return parts.join(', ');
  }

  void _handleReorder(int oldIndex, int newIndex) {
    // Flutter quirk: when moving down, newIndex is the index after removal
    // of the dragged item. Subtract 1 to give consumers intuitive indices.
    final adj = newIndex > oldIndex ? newIndex - 1 : newIndex;
    onReorder?.call(oldIndex, adj);
  }

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return EdenEmptyState(title: emptyMessage);
    }
    if (reorderable) {
      return ReorderableListView.builder(
        itemCount: stops.length,
        onReorder: _handleReorder,
        itemBuilder: (context, i) =>
            _buildRow(context, stops[i], i, withDragHandle: true),
      );
    }
    return ListView.builder(
      itemCount: stops.length,
      itemBuilder: (context, i) =>
          _buildRow(context, stops[i], i, withDragHandle: false),
    );
  }

  Widget _buildRow(
    BuildContext context,
    EdenRouteStopData stop,
    int i, {
    required bool withDragHandle,
  }) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(stop.status);
    return Container(
      key: Key('eden-route-stop-${stop.id}'),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: InkWell(
        onTap: () => onStopTap?.call(stop.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EdenSpacing.space3,
            vertical: EdenSpacing.space2,
          ),
          child: Row(
            children: [
              // Stop number badge
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('${i + 1}', style: theme.textTheme.labelSmall),
              ),
              const SizedBox(width: 12),
              // Body — label + address + ETA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stop.label,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stop.address != null)
                      Text(
                        _addressLine(stop.address!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (stop.estimatedArrival != null)
                      Text(
                        _formatTime(stop.estimatedArrival!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              GestureDetector(
                onTap: () => onStatusTap?.call(stop.id),
                child: Container(
                  key: Key('eden-route-stop-status-${stop.id}'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(stop.status),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (withDragHandle) ...[
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle, size: 20),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
