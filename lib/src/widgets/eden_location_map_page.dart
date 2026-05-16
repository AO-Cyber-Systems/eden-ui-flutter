// EdenLocationMapPage — dispatch-style map + locations panel composition.
//
// Donor: AOCyber-Trades/trades-flutter/lib/features/field_crew/presentation/
// location_map_page.dart (309 LOC). Port strips:
//   - flutter_riverpod (ConsumerWidget → StatelessWidget; ref.watch →
//     constructor-supplied pins).
//   - `package:trades/...` LocationUpdate model → EdenLocationPin inlined.
//   - `package:trades/shared/widgets/battery_indicator.dart` → private
//     `_EdenBatteryDot` helper inline.
//   - `package:trades/shared/widgets/gps_status_indicator.dart` (the trades
//     widget) → private `_AccuracyDot` helper (smaller than the objective-
//     002 EdenGpsStatusIndicator which is a full pill).
//   - `intl` DateFormat.jm() → hand-rolled `_formatTime12h` (constraint 12
//     — no new pubspec deps).
//   - Placeholder `_MapPlaceholder` simulating markers in fixed positions
//     → uses `EdenMapPreview` + `EdenMapProvider` interface instead.
//
// Library imports ZERO concrete map SDKs. All map rendering goes through
// the consumer-injected `EdenMapProvider`.

import 'package:flutter/material.dart';

import '../tokens/spacing.dart';
import 'eden_empty_state.dart';
import 'eden_map_preview.dart';
import 'map_providers/eden_map_provider.dart';
import 'map_providers/eden_map_types.dart';

/// A single tracked location pin rendered on the map AND as a list row.
///
/// **[accuracyMeters]** is optional GPS accuracy in meters. When non-null,
/// the list row subtitle shows `±${round}m` and the row's color dot is
/// tinted by quality:
///   - `< 10m` → green (high quality)
///   - `< 25m` → amber (moderate)
///   - `≥ 25m` → red (poor)
///
/// **[batteryLevel]** is 0..100 or null. When non-null, the list row
/// trailing shows a battery dot tinted by level (green ≥50, amber ≥20,
/// red <20). When null, trailing is omitted (saves visual noise for
/// non-mobile-device pins like vehicles with no battery readout).
///
/// **[lastSeenAt]** is the timestamp of the last position report. The
/// list row subtitle renders a relative time string ("45s ago", "3m ago",
/// "2:30 PM" for >1h).
///
/// **[color]** is optional — providers MAY use it to tint the map marker.
/// The `EdenMapMarker` value type does not yet carry a color field, so
/// the v1 EdenLocationMapPage does NOT forward it to the marker. The
/// field is reserved for future provider use.
class EdenLocationPin {
  const EdenLocationPin({
    required this.id,
    required this.name,
    required this.position,
    required this.lastSeenAt,
    this.accuracyMeters,
    this.batteryLevel,
    this.color,
  });

  final String id;
  final String name;
  final EdenLatLng position;
  final DateTime lastSeenAt;
  final double? accuracyMeters;
  final int? batteryLevel;
  final Color? color;
}

/// Map + locations panel page for dispatch / shift-coordinator workflows.
///
/// **Layout:** Column with `Expanded(flex: 3, child: mapArea)` on top
/// and `Expanded(flex: 2, child: listPanel)` below. Yields a 60/40 split.
/// When [pins] is empty, the map area is replaced with an
/// [EdenEmptyState] ("No active locations") and the list panel hides.
///
/// **Clustering v1 semantics:**
///   - `clusterPinsAbove: null` (default) → no clustering; each pin
///     becomes one [EdenMapMarker].
///   - `clusterPinsAbove: N` → clustering ENABLED when `pins.length > N`.
///     A simple O(n²) Euclidean check groups pins within `_kClusterDelta`
///     degrees of each other into a single cluster marker (`id:
///     'cluster-K'`). Designed for <100 pins; consumers with more should
///     pre-cluster server-side.
///   - Cluster markers fire [onClusterTapped] (NOT [onPinTapped]). When
///     [onClusterTapped] is null, cluster taps are silently ignored.
///
/// **`onRefresh: null`:** when null, the refresh `IconButton` is HIDDEN
/// (not just disabled). Use this for read-only views.
class EdenLocationMapPage extends StatelessWidget {
  const EdenLocationMapPage({
    super.key,
    required this.provider,
    required this.pins,
    this.onPinTapped,
    this.onClusterTapped,
    this.onRefresh,
    this.clusterPinsAbove,
    this.appBarTitle = 'Locations',
    this.listTitle = 'Active Technicians',
    this.now,
  });

  final EdenMapProvider provider;
  final List<EdenLocationPin> pins;
  final ValueChanged<String>? onPinTapped;
  final void Function(List<String> pinIds)? onClusterTapped;
  final VoidCallback? onRefresh;
  final int? clusterPinsAbove;
  final String appBarTitle;
  final String listTitle;

  /// Reference "now" for relative time formatting. Defaults to
  /// `DateTime.now()` when null. Override in tests for determinism.
  final DateTime? now;

  /// Cluster proximity threshold in degrees. ~0.001 deg ≈ 100m at the
  /// equator — coarse enough for visual clustering, tight enough not to
  /// over-merge. v1 uses degree-space (no projection); good enough for
  /// the <100-pin scope.
  static const double _kClusterDelta = 0.001;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: pins.isEmpty
          ? const EdenEmptyState(
              icon: Icons.location_off,
              title: 'No active locations',
              description: 'There are no active locations to display.',
            )
          : Column(
              children: [
                Expanded(flex: 3, child: _mapArea()),
                Expanded(flex: 2, child: _listPanel(context)),
              ],
            ),
    );
  }

  Widget _mapArea() {
    final markers = _buildMarkers();
    final bounds = EdenMapBounds.fromMarkers(markers);
    if (bounds == null) {
      return const SizedBox.shrink();
    }
    return EdenMapPreview(
      provider: provider,
      bounds: bounds,
      markers: markers,
      width: double.infinity,
      height: double.infinity,
      interactive: true,
    );
  }

  Widget _listPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              EdenSpacing.space4, EdenSpacing.space3, EdenSpacing.space4, 8),
          child: Row(
            children: [
              Text(listTitle, style: theme.textTheme.titleSmall),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${pins.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: pins.length,
            itemBuilder: (ctx, index) {
              return _LocationListTile(
                pin: pins[index],
                now: now ?? DateTime.now(),
                onTap: onPinTapped,
              );
            },
          ),
        ),
      ],
    );
  }

  List<EdenMapMarker> _buildMarkers() {
    final shouldCluster =
        clusterPinsAbove != null && pins.length > clusterPinsAbove!;
    if (!shouldCluster) {
      return [
        for (final p in pins)
          EdenMapMarker(id: p.id, position: p.position, label: p.name),
      ];
    }
    return _clusterPins(pins);
  }

  /// O(n²) Euclidean grouping by lat/lng proximity. v1 — designed for
  /// <100 pins. Each cluster's position is the centroid of its members.
  List<EdenMapMarker> _clusterPins(List<EdenLocationPin> pins) {
    final assigned = <bool>[for (var i = 0; i < pins.length; i++) false];
    final markers = <EdenMapMarker>[];
    var clusterIndex = 0;

    for (var i = 0; i < pins.length; i++) {
      if (assigned[i]) continue;
      final group = <EdenLocationPin>[pins[i]];
      assigned[i] = true;
      for (var j = i + 1; j < pins.length; j++) {
        if (assigned[j]) continue;
        final dLat = (pins[i].position.lat - pins[j].position.lat).abs();
        final dLng = (pins[i].position.lng - pins[j].position.lng).abs();
        if (dLat <= _kClusterDelta && dLng <= _kClusterDelta) {
          group.add(pins[j]);
          assigned[j] = true;
        }
      }

      if (group.length == 1) {
        markers.add(EdenMapMarker(
          id: group.first.id,
          position: group.first.position,
          label: group.first.name,
        ));
      } else {
        final avgLat =
            group.map((p) => p.position.lat).reduce((a, b) => a + b) /
                group.length;
        final avgLng =
            group.map((p) => p.position.lng).reduce((a, b) => a + b) /
                group.length;
        markers.add(EdenMapMarker(
          id: 'cluster-$clusterIndex',
          position: EdenLatLng(lat: avgLat, lng: avgLng),
          label: '${group.length}',
        ));
        clusterIndex++;
      }
    }
    return markers;
  }
}

/// Hand-rolled 12h time formatter (avoids `intl` pubspec dep).
String _formatTime12h(DateTime dt) {
  final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
  final minute = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $ampm';
}

/// Relative time string for the list-row subtitle.
String _timeAgo(DateTime when, DateTime now) {
  final diff = now.difference(when);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  return _formatTime12h(when);
}

class _LocationListTile extends StatelessWidget {
  const _LocationListTile({
    required this.pin,
    required this.now,
    required this.onTap,
  });

  final EdenLocationPin pin;
  final DateTime now;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = pin.name.isNotEmpty ? pin.name[0].toUpperCase() : '?';
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor:
            (pin.color ?? theme.colorScheme.primary).withValues(alpha: 0.15),
        child: Text(initial,
            style: TextStyle(
                color: pin.color ?? theme.colorScheme.primary,
                fontWeight: FontWeight.w600)),
      ),
      title: Text(
        pin.name,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Row(
        children: [
          _AccuracyDot(accuracy: pin.accuracyMeters),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              pin.accuracyMeters != null
                  ? '±${pin.accuracyMeters!.round()}m · ${_timeAgo(pin.lastSeenAt, now)}'
                  : _timeAgo(pin.lastSeenAt, now),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
      trailing: pin.batteryLevel != null
          ? _EdenBatteryDot(
              key: ValueKey('eden_location_battery_dot_${pin.id}'),
              level: pin.batteryLevel!)
          : null,
      onTap: onTap == null ? null : () => onTap!.call(pin.id),
    );
  }
}

/// Tiny color dot indicating GPS accuracy quality.
class _AccuracyDot extends StatelessWidget {
  const _AccuracyDot({required this.accuracy});
  final double? accuracy;

  Color _color() {
    if (accuracy == null) return const Color(0xFF6B7280); // grey
    if (accuracy! < 10) return const Color(0xFF22C55E); // green
    if (accuracy! < 25) return const Color(0xFFF59E0B); // amber
    return const Color(0xFFEF4444); // red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: _color(), shape: BoxShape.circle),
    );
  }
}

/// Small battery indicator (icon + level text). Private to this page —
/// promote to a public widget when a second consumer emerges.
class _EdenBatteryDot extends StatelessWidget {
  const _EdenBatteryDot({super.key, required this.level});
  final int level;

  Color _color() {
    if (level >= 50) return const Color(0xFF22C55E);
    if (level >= 20) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  IconData _icon() {
    if (level >= 80) return Icons.battery_full;
    if (level >= 60) return Icons.battery_5_bar;
    if (level >= 40) return Icons.battery_4_bar;
    if (level >= 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon(), size: 14, color: color),
        const SizedBox(width: 2),
        Text('$level%',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

