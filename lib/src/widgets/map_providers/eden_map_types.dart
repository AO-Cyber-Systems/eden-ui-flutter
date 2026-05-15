/// Immutable value types for the [EdenMapProvider] interface.
///
/// These types are deliberately small and SDK-free. The library core ships
/// the interface + value types only; concrete provider implementations
/// (Google Maps, MapLibre + Pelias, etc.) ship as separate downstream
/// dependencies and translate their vendor-specific types into these.
library;

/// Latitude / longitude pair. Pure value type.
class EdenLatLng {
  const EdenLatLng({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenLatLng && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'EdenLatLng(lat: $lat, lng: $lng)';
}

/// Structured address. `regionCode` is a generic admin division code
/// (e.g., 'CA', 'NY', 'BC', 'QC') — not US-only. `countryCode` is ISO 3166-1
/// alpha-2.
class EdenAddress {
  const EdenAddress({
    required this.streetLine1,
    this.streetLine2,
    required this.city,
    required this.regionCode,
    required this.postalCode,
    required this.countryCode,
    this.latLng,
  });

  final String streetLine1;
  final String? streetLine2;
  final String city;
  final String regionCode;
  final String postalCode;
  final String countryCode;
  final EdenLatLng? latLng;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenAddress &&
          other.streetLine1 == streetLine1 &&
          other.streetLine2 == streetLine2 &&
          other.city == city &&
          other.regionCode == regionCode &&
          other.postalCode == postalCode &&
          other.countryCode == countryCode &&
          other.latLng == latLng;

  @override
  int get hashCode => Object.hash(
        streetLine1,
        streetLine2,
        city,
        regionCode,
        postalCode,
        countryCode,
        latLng,
      );

  @override
  String toString() =>
      'EdenAddress($streetLine1, ${streetLine2 ?? ''}, $city, $regionCode '
      '$postalCode, $countryCode)';
}

/// Suggestion from an autocomplete query. `placeId` is an opaque
/// provider-issued identifier passed back to `resolvePlace`.
class EdenPlaceSuggestion {
  const EdenPlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    this.secondaryText,
  });

  final String placeId;
  final String primaryText;
  final String? secondaryText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenPlaceSuggestion &&
          other.placeId == placeId &&
          other.primaryText == primaryText &&
          other.secondaryText == secondaryText;

  @override
  int get hashCode => Object.hash(placeId, primaryText, secondaryText);

  @override
  String toString() =>
      'EdenPlaceSuggestion(placeId: $placeId, primaryText: $primaryText)';
}

/// A single marker on the map. `id` is caller-issued and used by providers
/// to track diffs across [EdenMapProvider.showMap] rebuilds. `icon` is
/// optional — providers may render a default pin when absent.
class EdenMapMarker {
  const EdenMapMarker({
    required this.id,
    required this.position,
    this.label,
    this.icon,
  });

  final String id;
  final EdenLatLng position;
  final String? label;
  final Object? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenMapMarker &&
          other.id == id &&
          other.position == position &&
          other.label == label &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(id, position, label, icon);

  @override
  String toString() => 'EdenMapMarker(id: $id, position: $position)';
}

/// Rectangular geographic bounds (southwest + northeast corners).
class EdenMapBounds {
  const EdenMapBounds({required this.southwest, required this.northeast});

  final EdenLatLng southwest;
  final EdenLatLng northeast;

  /// Computes a bounds rectangle that contains every marker. Returns `null`
  /// when [markers] is empty — consumers can handle null more easily than
  /// catching an exception, so the empty case is encoded in the type rather
  /// than the exception channel.
  static EdenMapBounds? fromMarkers(Iterable<EdenMapMarker> markers) {
    final iter = markers.iterator;
    if (!iter.moveNext()) return null;

    var minLat = iter.current.position.lat;
    var maxLat = minLat;
    var minLng = iter.current.position.lng;
    var maxLng = minLng;

    while (iter.moveNext()) {
      final p = iter.current.position;
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    return EdenMapBounds(
      southwest: EdenLatLng(lat: minLat, lng: minLng),
      northeast: EdenLatLng(lat: maxLat, lng: maxLng),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdenMapBounds &&
          other.southwest == southwest &&
          other.northeast == northeast;

  @override
  int get hashCode => Object.hash(southwest, northeast);

  @override
  String toString() =>
      'EdenMapBounds(sw: $southwest, ne: $northeast)';
}
