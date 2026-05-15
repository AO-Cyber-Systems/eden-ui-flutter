import 'package:eden_ui_flutter/eden_ui.dart' hide EdenMapMarker;
import 'package:eden_ui_flutter/src/widgets/map_providers/eden_map_types.dart'
    show EdenMapMarker;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_map_provider_fixtures.dart';

void main() {
  group('EdenLatLng', () {
    test('equality + hashCode', () {
      const a = EdenLatLng(lat: 37.7793, lng: -122.4192);
      const b = EdenLatLng(lat: 37.7793, lng: -122.4192);
      const c = EdenLatLng(lat: 40.7580, lng: -73.9855);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('EdenAddress', () {
    test('equality with optional streetLine2 set', () {
      final a = EdenMapProviderFixtures.sampleAddress();
      final b = EdenMapProviderFixtures.sampleAddress();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality with null streetLine2', () {
      final a = EdenMapProviderFixtures.sampleAddressWithoutSuite();
      final b = EdenMapProviderFixtures.sampleAddressWithoutSuite();
      expect(a, equals(b));
      // Different from the variant with a suite line.
      expect(a, isNot(equals(EdenMapProviderFixtures.sampleAddress())));
    });
  });

  group('EdenPlaceSuggestion', () {
    test('equality', () {
      const a = EdenPlaceSuggestion(
        placeId: 'p1',
        primaryText: 'Foo',
        secondaryText: 'Bar',
      );
      const b = EdenPlaceSuggestion(
        placeId: 'p1',
        primaryText: 'Foo',
        secondaryText: 'Bar',
      );
      const c = EdenPlaceSuggestion(
        placeId: 'p1',
        primaryText: 'Foo',
        secondaryText: 'Different',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('EdenMapMarker', () {
    test('equality', () {
      const pos = EdenLatLng(lat: 1, lng: 2);
      const a = EdenMapMarker(id: 'm1', position: pos, label: 'A');
      const b = EdenMapMarker(id: 'm1', position: pos, label: 'A');
      const c = EdenMapMarker(id: 'm2', position: pos, label: 'A');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });

  group('EdenMapBounds.fromMarkers', () {
    test('computes bounds for 1 marker', () {
      final markers = EdenMapProviderFixtures.markers(1);
      final bounds = EdenMapBounds.fromMarkers(markers);
      expect(bounds, isNotNull);
      // Single marker → southwest == northeast == that marker.
      expect(bounds!.southwest, equals(markers.first.position));
      expect(bounds.northeast, equals(markers.first.position));
    });

    test('computes bounds for many markers', () {
      final markers = EdenMapProviderFixtures.markers(10);
      final bounds = EdenMapBounds.fromMarkers(markers);
      expect(bounds, isNotNull);
      // Every marker's lat is within [sw.lat, ne.lat].
      for (final m in markers) {
        expect(m.position.lat,
            inInclusiveRange(bounds!.southwest.lat, bounds.northeast.lat));
        expect(m.position.lng,
            inInclusiveRange(bounds.southwest.lng, bounds.northeast.lng));
      }
    });

    test('returns null for empty input', () {
      expect(EdenMapBounds.fromMarkers(const []), isNull);
    });
  });

  group('NoOpMapProvider', () {
    test('geocodeAddress returns null', () async {
      const provider = NoOpMapProvider();
      final result = await provider.geocodeAddress('123 Main St');
      expect(result, isNull);
    });

    test('reverseGeocode returns null', () async {
      const provider = NoOpMapProvider();
      final result = await provider.reverseGeocode(
        const EdenLatLng(lat: 0, lng: 0),
      );
      expect(result, isNull);
    });

    test('autocompletePlaces returns empty list', () async {
      const provider = NoOpMapProvider();
      final result = await provider.autocompletePlaces('foo');
      expect(result, isEmpty);
    });

    test('resolvePlace returns null', () async {
      const provider = NoOpMapProvider();
      final result = await provider.resolvePlace('place_1');
      expect(result, isNull);
    });

    test('showMap returns a SizedBox.shrink widget', () {
      const provider = NoOpMapProvider();
      final widget = provider.showMap(
        bounds: const EdenMapBounds(
          southwest: EdenLatLng(lat: 0, lng: 0),
          northeast: EdenLatLng(lat: 1, lng: 1),
        ),
      );
      expect(widget, isA<SizedBox>());
      // SizedBox.shrink has both dimensions 0.
      final box = widget as SizedBox;
      expect(box.width, 0);
      expect(box.height, 0);
    });
  });
}
