// Hand-built fixtures. Do NOT regenerate via LLM; mutate in-place when
// EdenMapProvider value types change.
//
// NO Riverpod, NO mocking library, NO LLM-generated test data. Coordinates
// are real-looking but deterministic (SF + NYC anchors and offsets thereof).

import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for the [EdenMapProvider] value-type tests.
class EdenMapProviderFixtures {
  EdenMapProviderFixtures._();

  /// Anchor: San Francisco City Hall area.
  static const EdenLatLng sf = EdenLatLng(lat: 37.7793, lng: -122.4192);

  /// Anchor: NYC Times Square area.
  static const EdenLatLng nyc = EdenLatLng(lat: 40.7580, lng: -73.9855);

  /// Convenience accessor matching the TRD's `sfLatLng()` / `nycLatLng()`
  /// naming.
  static EdenLatLng sfLatLng() => sf;
  static EdenLatLng nycLatLng() => nyc;

  /// Sample address — synthetic but plausibly shaped.
  static EdenAddress sampleAddress() {
    return const EdenAddress(
      streetLine1: '123 Market St',
      streetLine2: 'Suite 400',
      city: 'San Francisco',
      regionCode: 'CA',
      postalCode: '94105',
      countryCode: 'US',
      latLng: sf,
    );
  }

  /// Sample address with null streetLine2 — exercises the optional field
  /// equality case.
  static EdenAddress sampleAddressWithoutSuite() {
    return const EdenAddress(
      streetLine1: '123 Market St',
      city: 'San Francisco',
      regionCode: 'CA',
      postalCode: '94105',
      countryCode: 'US',
      latLng: sf,
    );
  }

  /// `n` deterministic place suggestions.
  static List<EdenPlaceSuggestion> suggestions(int n) {
    return List<EdenPlaceSuggestion>.generate(
      n,
      (i) => EdenPlaceSuggestion(
        placeId: 'place_$i',
        primaryText: 'Result $i',
        secondaryText: 'Secondary $i',
      ),
    );
  }

  /// `n` markers spread around the SF anchor in a small lat/lng grid.
  static List<EdenMapMarker> markers(int n) {
    return List<EdenMapMarker>.generate(n, (i) {
      final dLat = (i % 5) * 0.001;
      final dLng = (i ~/ 5) * 0.001;
      return EdenMapMarker(
        id: 'm_$i',
        position: EdenLatLng(lat: sf.lat + dLat, lng: sf.lng + dLng),
        label: 'Marker $i',
      );
    });
  }
}
