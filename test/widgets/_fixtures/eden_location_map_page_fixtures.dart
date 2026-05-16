// Do NOT regenerate via LLM — hand-built fixtures for EdenLocationMapPage.
// Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenLocationMapPageFixtures {
  EdenLocationMapPageFixtures._();

  /// Frozen reference timestamp for deterministic time-ago strings.
  static DateTime frozen() => DateTime(2026, 5, 16, 14, 30);

  static EdenLocationPin tech1() => EdenLocationPin(
        id: 'tech-1',
        name: 'Mike T.',
        position: const EdenLatLng(lat: 37.7749, lng: -122.4194),
        accuracyMeters: 12,
        batteryLevel: 78,
        lastSeenAt: frozen().subtract(const Duration(minutes: 3)),
      );

  static EdenLocationPin tech2() => EdenLocationPin(
        id: 'tech-2',
        name: 'Sarah K.',
        position: const EdenLatLng(lat: 37.7849, lng: -122.4094),
        accuracyMeters: 8,
        batteryLevel: 92,
        lastSeenAt: frozen().subtract(const Duration(seconds: 45)),
      );

  static EdenLocationPin techLongName() => EdenLocationPin(
        id: 'tech-3',
        name: 'Christopher Marlborough-Smithereens',
        position: const EdenLatLng(lat: 37.7949, lng: -122.3994),
        accuracyMeters: 25,
        batteryLevel: 22,
        lastSeenAt: frozen().subtract(const Duration(hours: 2)),
      );

  static EdenLocationPin techNoBattery() => EdenLocationPin(
        id: 'tech-4',
        name: 'No Battery',
        position: const EdenLatLng(lat: 37.8049, lng: -122.4294),
        accuracyMeters: 5,
        batteryLevel: null,
        lastSeenAt: frozen(),
      );

  /// Five pins clustered closely for cluster-on tests (~1e-4 deg apart).
  static List<EdenLocationPin> clusterFive() => [
        EdenLocationPin(
          id: 'c1',
          name: 'C1',
          position: const EdenLatLng(lat: 37.7749, lng: -122.4194),
          lastSeenAt: frozen(),
        ),
        EdenLocationPin(
          id: 'c2',
          name: 'C2',
          position: const EdenLatLng(lat: 37.7750, lng: -122.4195),
          lastSeenAt: frozen(),
        ),
        EdenLocationPin(
          id: 'c3',
          name: 'C3',
          position: const EdenLatLng(lat: 37.7748, lng: -122.4193),
          lastSeenAt: frozen(),
        ),
        EdenLocationPin(
          id: 'c4',
          name: 'C4',
          position: const EdenLatLng(lat: 37.7751, lng: -122.4196),
          lastSeenAt: frozen(),
        ),
        EdenLocationPin(
          id: 'c5',
          name: 'C5',
          position: const EdenLatLng(lat: 37.7747, lng: -122.4192),
          lastSeenAt: frozen(),
        ),
      ];

  /// Two pins (Mike + Sarah).
  static List<EdenLocationPin> twoPins() => [tech1(), tech2()];
}
