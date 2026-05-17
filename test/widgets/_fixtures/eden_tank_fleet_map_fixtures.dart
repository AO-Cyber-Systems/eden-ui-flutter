// Do NOT regenerate via LLM — hand-built fixtures for EdenTankFleetMap.

import 'package:eden_ui_flutter/src/widgets/eden_tank_fleet_map.dart';

class TankFleetMapFixtures {
  TankFleetMapFixtures._();

  /// 25-tank demo: 8 full, 6 warning, 4 critical, 3 stale, 4 unknown.
  static EdenFleetMapData demo25() {
    return EdenFleetMapData(
      markers: [
        for (int i = 1; i <= 8; i++)
          EdenFleetMapMarker(
            id: 'tank-full-$i',
            lat: 40.0 + i * 0.01,
            lng: -74.0 + i * 0.01,
            severity: EdenFleetMapSeverity.full,
            label: 'Tank F$i',
            lastReadingAgeMinutes: 15,
          ),
        for (int i = 1; i <= 6; i++)
          EdenFleetMapMarker(
            id: 'tank-warn-$i',
            lat: 40.1 + i * 0.01,
            lng: -74.1 + i * 0.01,
            severity: EdenFleetMapSeverity.warning,
            label: 'Tank W$i',
            lastReadingAgeMinutes: 60,
          ),
        for (int i = 1; i <= 4; i++)
          EdenFleetMapMarker(
            id: 'tank-crit-$i',
            lat: 40.2 + i * 0.01,
            lng: -74.2 + i * 0.01,
            severity: EdenFleetMapSeverity.critical,
            label: 'Tank C$i',
            lastReadingAgeMinutes: 30,
          ),
        for (int i = 1; i <= 3; i++)
          EdenFleetMapMarker(
            id: 'tank-stale-$i',
            lat: 40.3 + i * 0.01,
            lng: -74.3 + i * 0.01,
            severity: EdenFleetMapSeverity.staleTelemetry,
            label: 'Tank S$i',
            lastReadingAgeMinutes: 60 * 24 * 4, // 4 days
          ),
        for (int i = 1; i <= 4; i++)
          EdenFleetMapMarker(
            id: 'tank-unk-$i',
            lat: 40.4 + i * 0.01,
            lng: -74.4 + i * 0.01,
            severity: EdenFleetMapSeverity.unknown,
            label: 'Tank U$i',
          ),
      ],
    );
  }

  static EdenFleetMapData emptyDemo() {
    return const EdenFleetMapData(markers: []);
  }
}
