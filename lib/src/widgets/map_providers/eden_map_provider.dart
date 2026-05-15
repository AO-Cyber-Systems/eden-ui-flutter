import 'package:flutter/widgets.dart';

import 'eden_map_types.dart';

/// Pluggable map adapter interface.
///
/// Per `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §6 locked decision 3 the
/// `eden-ui-flutter` library core MUST NOT hard-code a vendor SDK. Concrete
/// implementations ship as separate sibling packages (e.g. a Google Maps
/// reference impl, a MapLibre + self-hosted-tiles impl for gov/CUI builds)
/// and downstream apps choose which one to depend on.
///
/// This file imports ONLY `package:flutter/widgets.dart` and sibling value
/// types — verify with `grep -rE "google|mapbox|maplibre"
/// lib/src/widgets/map_providers/` returns no matches.
abstract class EdenMapProvider {
  /// Renders a map widget with the given markers and bounds.
  ///
  /// Implementations may return `SizedBox.shrink()` if maps are not
  /// supported in this build (e.g. test mode, gov build without a tile
  /// vendor wired up). When [interactive] is false, pan/zoom gestures
  /// should be disabled (use cases: read-only address-preview cards).
  Widget showMap({
    required EdenMapBounds bounds,
    List<EdenMapMarker> markers = const [],
    void Function(EdenLatLng)? onTap,
    bool interactive = true,
  });

  /// Forward geocode: free-text address → structured address with optional
  /// `latLng`. Returns `null` when no match is found.
  Future<EdenAddress?> geocodeAddress(String query);

  /// Reverse geocode: coordinates → structured address. Returns `null` when
  /// the location is not addressable (open water, undocumented region).
  Future<EdenAddress?> reverseGeocode(EdenLatLng position);

  /// Autocomplete: partial query → list of place suggestions. `limit`
  /// is advisory; providers may return fewer results.
  Future<List<EdenPlaceSuggestion>> autocompletePlaces(
    String query, {
    int limit = 5,
  });

  /// Resolve a suggestion (selected from autocomplete) to a full structured
  /// address. Returns `null` if the place id is no longer valid.
  Future<EdenAddress?> resolvePlace(String placeId);
}

/// Test / fallback provider that returns deterministic empty/identity
/// values for every method. Useful for widget tests, gov builds that
/// haven't wired up a tile vendor, and offline development.
///
/// Implements (not extends) [EdenMapProvider] so concrete vendor impls
/// don't accidentally inherit no-op behavior.
class NoOpMapProvider implements EdenMapProvider {
  const NoOpMapProvider();

  @override
  Widget showMap({
    required EdenMapBounds bounds,
    List<EdenMapMarker> markers = const [],
    void Function(EdenLatLng)? onTap,
    bool interactive = true,
  }) {
    return const SizedBox.shrink();
  }

  @override
  Future<EdenAddress?> geocodeAddress(String query) async => null;

  @override
  Future<EdenAddress?> reverseGeocode(EdenLatLng position) async => null;

  @override
  Future<List<EdenPlaceSuggestion>> autocompletePlaces(
    String query, {
    int limit = 5,
  }) async =>
      const [];

  @override
  Future<EdenAddress?> resolvePlace(String placeId) async => null;
}
