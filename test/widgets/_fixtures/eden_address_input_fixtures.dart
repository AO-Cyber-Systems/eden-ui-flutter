// Do NOT regenerate via LLM — hand-built fixtures for EdenAddressInput +
// EdenMapPreview + RecordingMapProvider tests.
//
// No mocking library, no LLM-generated test data. Coordinates anchored on
// real-looking SF / NYC values; suggestion lists are deliberately small
// and shaped after the trades-react donor (Apple HQ / Twitter HQ /
// Salesforce Tower) so the dev catalog and tests stay readable.

import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures shared by the EdenAddressInput / EdenMapPreview /
/// RecordingMapProvider test suites.
class EdenAddressInputFixtures {
  EdenAddressInputFixtures._();

  /// Anchor — One Apple Park Way, Cupertino, CA (close enough for tests).
  /// Re-uses the SF coordinates from EdenMapProviderFixtures to keep all
  /// Wave A map fixtures in one mental ballpark.
  static const EdenLatLng sfLatLng = EdenLatLng(lat: 37.7793, lng: -122.4192);

  /// Canned resolved address (what the provider returns from
  /// `resolvePlace('place_apple_hq')` or `geocodeAddress(...)`).
  static const EdenAddress cannedSf = EdenAddress(
    streetLine1: '1 Apple Park Way',
    streetLine2: null,
    city: 'Cupertino',
    regionCode: 'CA',
    postalCode: '95014',
    countryCode: 'US',
    latLng: sfLatLng,
  );

  /// Empty starting address (all fields blank). Used to assert default-render.
  static const EdenAddress emptyAddress = EdenAddress(
    streetLine1: '',
    city: '',
    regionCode: '',
    postalCode: '',
    countryCode: '',
  );

  /// Partial address — line1 + city only. Asserts initial-pre-fill works for
  /// not-yet-fully-resolved inputs.
  static const EdenAddress partialAddress = EdenAddress(
    streetLine1: '123 Market St',
    city: 'San Francisco',
    regionCode: '',
    postalCode: '',
    countryCode: '',
  );

  /// Three suggestions matching "appl" — modeled on the trades-react donor.
  /// `placeId` values are deterministic and used by tests to verify
  /// `resolvePlace` is invoked with the selected suggestion's id.
  static const List<EdenPlaceSuggestion> cannedSuggestionsForSf =
      <EdenPlaceSuggestion>[
    EdenPlaceSuggestion(
      placeId: 'place_apple_hq',
      primaryText: 'Apple Park',
      secondaryText: '1 Apple Park Way, Cupertino, CA',
    ),
    EdenPlaceSuggestion(
      placeId: 'place_twitter_hq',
      primaryText: 'Twitter HQ',
      secondaryText: '1355 Market St, San Francisco, CA',
    ),
    EdenPlaceSuggestion(
      placeId: 'place_salesforce_tower',
      primaryText: 'Salesforce Tower',
      secondaryText: '415 Mission St, San Francisco, CA',
    ),
  ];

  /// Bounds rectangle around SF — used by EdenMapPreview tests.
  static const EdenMapBounds sfBounds = EdenMapBounds(
    southwest: EdenLatLng(lat: 37.70, lng: -122.50),
    northeast: EdenLatLng(lat: 37.85, lng: -122.35),
  );

  /// Single marker at the SF anchor — used by EdenMapPreview marker tests.
  static const EdenMapMarker sfMarker = EdenMapMarker(
    id: 'sf_pin',
    position: sfLatLng,
    label: 'SF',
  );
}
