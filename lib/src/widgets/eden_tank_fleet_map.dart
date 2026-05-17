import 'package:flutter/material.dart';

import '../theme/eden_status_palette.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import 'eden_card.dart';
import 'eden_empty_state.dart';
import 'eden_status_badge.dart';
import 'eden_tank_gauge.dart';

/// Severity tier for a fleet map marker.
enum EdenFleetMapSeverity {
  full,
  warning,
  critical,
  staleTelemetry,
  unknown,
}

/// Clustering policy for adjacent markers on the map.
enum EdenFleetMapClusterPolicy { zoomAware, never, always }

/// A single marker in the fleet map.
@immutable
class EdenFleetMapMarker {
  const EdenFleetMapMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.severity,
    required this.label,
    this.tankSummary,
    this.lastReadingAt,
    this.lastReadingAgeMinutes,
  });

  final String id;
  final double lat;
  final double lng;
  final EdenFleetMapSeverity severity;
  final String label;
  final EdenTankGaugeData? tankSummary;
  final DateTime? lastReadingAt;
  final int? lastReadingAgeMinutes;
}

/// Viewport bounds for the map.
@immutable
class EdenFleetMapViewport {
  const EdenFleetMapViewport({
    required this.northLat,
    required this.southLat,
    required this.westLng,
    required this.eastLng,
    required this.zoomLevel,
  });

  final double northLat;
  final double southLat;
  final double westLng;
  final double eastLng;
  final double zoomLevel;
}

/// Top-level state container.
@immutable
class EdenFleetMapData {
  const EdenFleetMapData({
    required this.markers,
    this.clusterPolicy = EdenFleetMapClusterPolicy.zoomAware,
    this.visibleSeverities = const {
      EdenFleetMapSeverity.full,
      EdenFleetMapSeverity.warning,
      EdenFleetMapSeverity.critical,
      EdenFleetMapSeverity.staleTelemetry,
      EdenFleetMapSeverity.unknown,
    },
  });

  final List<EdenFleetMapMarker> markers;
  final EdenFleetMapClusterPolicy clusterPolicy;
  final Set<EdenFleetMapSeverity> visibleSeverities;
}

/// Canonical dealer-portal map of customer tanks — generic enough for any
/// clustered severity-tinted fleet (chemical-storage, water-utility meters,
/// HVAC unit fleets).
///
/// **Map provider degradation:** When no real map plugin is loaded, the map
/// zone renders a severity-tinted placeholder grid (per obj 001-03 Wave A
/// NoOpMapProvider pattern). The sidebar list remains fully functional.
class EdenTankFleetMap extends StatefulWidget {
  const EdenTankFleetMap({
    super.key,
    required this.data,
    this.onMultiSelect,
    this.onMarkerTap,
    this.onViewportChanged,
    this.sidebarHeaderSlot,
  });

  final EdenFleetMapData data;
  final ValueChanged<List<String>>? onMultiSelect;
  final ValueChanged<String>? onMarkerTap;
  final ValueChanged<EdenFleetMapViewport>? onViewportChanged;
  final Widget? sidebarHeaderSlot;

  static String severityLabel(EdenFleetMapSeverity s) {
    switch (s) {
      case EdenFleetMapSeverity.full:
        return 'Full';
      case EdenFleetMapSeverity.warning:
        return 'Warning';
      case EdenFleetMapSeverity.critical:
        return 'Critical';
      case EdenFleetMapSeverity.staleTelemetry:
        return 'Stale telemetry';
      case EdenFleetMapSeverity.unknown:
        return 'Unknown';
    }
  }

  static Color severityColor(
      EdenFleetMapSeverity s, EdenStatusPalette? palette) {
    switch (s) {
      case EdenFleetMapSeverity.full:
        return palette?.successFg ?? EdenColors.success;
      case EdenFleetMapSeverity.warning:
        return palette?.warningFg ?? EdenColors.warning;
      case EdenFleetMapSeverity.critical:
        return palette?.dangerFg ?? EdenColors.error;
      case EdenFleetMapSeverity.staleTelemetry:
        return EdenColors.neutral[600] ?? EdenColors.neutral;
      case EdenFleetMapSeverity.unknown:
        return EdenColors.neutral;
    }
  }

  @override
  State<EdenTankFleetMap> createState() => _EdenTankFleetMapState();
}

class _EdenTankFleetMapState extends State<EdenTankFleetMap> {
  late Set<EdenFleetMapSeverity> _visibleSeverities;
  final Set<String> _selectedIds = {};
  bool _multiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _visibleSeverities = Set.from(widget.data.visibleSeverities);
  }

  @override
  void didUpdateWidget(covariant EdenTankFleetMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _visibleSeverities = Set.from(widget.data.visibleSeverities);
    }
  }

  List<EdenFleetMapMarker> get _filteredMarkers => widget.data.markers
      .where((m) => _visibleSeverities.contains(m.severity))
      .toList();

  Map<EdenFleetMapSeverity, int> get _severityCounts {
    final counts = <EdenFleetMapSeverity, int>{};
    for (final m in widget.data.markers) {
      counts[m.severity] = (counts[m.severity] ?? 0) + 1;
    }
    return counts;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _multiSelectMode = _selectedIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _multiSelectMode = false;
    });
  }

  void _toggleSeverityFilter(EdenFleetMapSeverity s) {
    setState(() {
      if (_visibleSeverities.contains(s)) {
        _visibleSeverities.remove(s);
      } else {
        _visibleSeverities.add(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isTabbed = constraints.maxWidth < 1024;
      if (isTabbed) {
        return _buildTabbed(context);
      }
      return _buildTwoZone(context);
    });
  }

  Widget _buildTwoZone(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 3, child: _MapZone(parent: this)),
        const VerticalDivider(width: 1),
        Expanded(flex: 2, child: _SidebarZone(parent: this)),
      ],
    );
  }

  Widget _buildTabbed(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Map'), Tab(text: 'List')]),
          Expanded(
            child: TabBarView(children: [
              _MapZone(parent: this),
              _SidebarZone(parent: this, isTabbed: true),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MapZone extends StatelessWidget {
  const _MapZone({required this.parent});

  final _EdenTankFleetMapState parent;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    final markers = parent._filteredMarkers;
    if (markers.isEmpty) {
      return const EdenEmptyState(
        title: 'No tanks visible',
        description: 'Adjust filters or load fleet markers.',
      );
    }
    return Stack(
      children: [
        // Placeholder grid (NoOpMapProvider pattern from obj 001-03)
        Container(
          color: EdenColors.neutral[100],
          child: Padding(
            padding: const EdgeInsets.all(EdenSpacing.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Fleet map (placeholder grid)',
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 90,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: markers.length,
                    itemBuilder: (ctx, i) {
                      final m = markers[i];
                      final color =
                          EdenTankFleetMap.severityColor(m.severity, palette);
                      final selected = parent._selectedIds.contains(m.id);
                      return InkWell(
                        key: Key('fleet-marker-${m.id}'),
                        onTap: () {
                          if (parent._multiSelectMode) {
                            parent._toggleSelection(m.id);
                          } else {
                            parent.widget.onMarkerTap?.call(m.id);
                          }
                        },
                        onLongPress: () => parent._toggleSelection(m.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : color,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: color,
                                size: 18,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.label,
                                style: Theme.of(context).textTheme.labelSmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (parent._multiSelectMode && parent.widget.onMultiSelect != null)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              key: const Key('fleet-build-route'),
              onPressed: () {
                parent.widget.onMultiSelect!(parent._selectedIds.toList());
                parent._clearSelection();
              },
              icon: const Icon(Icons.route),
              label: Text('Build route (${parent._selectedIds.length})'),
            ),
          ),
      ],
    );
  }
}

class _SidebarZone extends StatelessWidget {
  const _SidebarZone({required this.parent, this.isTabbed = false});

  final _EdenTankFleetMapState parent;
  final bool isTabbed;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<EdenStatusPalette>();
    final counts = parent._severityCounts;
    final visible = parent._filteredMarkers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(EdenSpacing.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fleet (${visible.length} tanks)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (parent.widget.sidebarHeaderSlot != null)
                parent.widget.sidebarHeaderSlot!,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in EdenFleetMapSeverity.values)
                    FilterChip(
                      key: Key('fleet-filter-${s.name}'),
                      label: Text(
                          '${EdenTankFleetMap.severityLabel(s)} (${counts[s] ?? 0})'),
                      selected: parent._visibleSeverities.contains(s),
                      selectedColor: EdenTankFleetMap.severityColor(s, palette)
                          .withValues(alpha: 0.20),
                      onSelected: (_) => parent._toggleSeverityFilter(s),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (parent._selectedIds.isNotEmpty)
          Container(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(
                horizontal: EdenSpacing.space3, vertical: EdenSpacing.space2),
            child: Row(
              children: [
                Expanded(
                    child: Text('${parent._selectedIds.length} selected')),
                TextButton(
                  onPressed: parent._clearSelection,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? const EdenEmptyState(title: 'No tanks match filters')
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (ctx, i) => _SidebarRow(
                      parent: parent,
                      marker: visible[i],
                      palette: palette,
                      isTabbed: isTabbed),
                ),
        ),
      ],
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.parent,
    required this.marker,
    required this.palette,
    required this.isTabbed,
  });

  final _EdenTankFleetMapState parent;
  final EdenFleetMapMarker marker;
  final EdenStatusPalette? palette;
  final bool isTabbed;

  String _ageLabel() {
    if (marker.lastReadingAgeMinutes == null) return 'no reading';
    final m = marker.lastReadingAgeMinutes!;
    if (m < 60) return '${m}m ago';
    if (m < 60 * 24) return '${(m / 60).floor()}h ago';
    return '${(m / 60 / 24).floor()}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final color = EdenTankFleetMap.severityColor(marker.severity, palette);
    final selected = parent._selectedIds.contains(marker.id);
    final row = InkWell(
      key: Key('sidebar-row-${marker.id}'),
      onTap: () {
        if (parent._multiSelectMode) {
          parent._toggleSelection(marker.id);
        } else {
          parent.widget.onMarkerTap?.call(marker.id);
        }
      },
      onLongPress: () => parent._toggleSelection(marker.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EdenSpacing.space3,
          vertical: EdenSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : null,
          border: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(marker.label,
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(_ageLabel(),
                      style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            EdenStatusBadge(status: EdenTankFleetMap.severityLabel(marker.severity)),
          ],
        ),
      ),
    );
    if (isTabbed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: EdenCard(child: row),
      );
    }
    return row;
  }
}
