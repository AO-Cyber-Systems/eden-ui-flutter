// Do NOT regenerate via LLM — hand-built fixtures for
// EdenGpsStatusIndicator.
//
// Cross-vertical promotion fixtures per
// COMPANION_UX_PATTERNS_2026-05-15.md §P-17 evidence:
//   T = trades (route adherence, on-site check-in)
//   F = fuel (route adherence)
//   M = medical (home-visit chain-of-custody)
//   G = gov (field inspection chain-of-custody)
//
// Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenGpsStatusIndicatorFixtures {
  EdenGpsStatusIndicatorFixtures._();

  /// New York City — canonical positive-lat / negative-lng fixture.
  static const EdenLatLng nyc = EdenLatLng(lat: 40.7128, lng: -74.0060);

  /// Sydney — negative-lat / positive-lng (eastern hemisphere) fixture.
  static const EdenLatLng sydney = EdenLatLng(lat: -33.8568, lng: 151.2153);
}
