import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_fixtures/eden_address_input_fixtures.dart';

void main() {
  group('RecordingMapProvider', () {
    test('records autocompletePlaces calls with query + limit', () async {
      final provider = RecordingMapProvider();
      await provider.autocompletePlaces('appl', limit: 7);
      await provider.autocompletePlaces('apple p', limit: 3);

      expect(provider.recordedCalls, hasLength(2));
      expect(provider.recordedCalls[0].method, equals('autocompletePlaces'));
      expect(
        provider.recordedCalls[0].arguments,
        equals({'query': 'appl', 'limit': 7}),
      );
      expect(
        provider.recordedCalls[1].arguments,
        equals({'query': 'apple p', 'limit': 3}),
      );
    });

    test('records geocodeAddress calls with the query string', () async {
      final provider = RecordingMapProvider();
      await provider.geocodeAddress('1 Apple Park Way');

      expect(provider.recordedCalls, hasLength(1));
      expect(provider.recordedCalls.single.method, equals('geocodeAddress'));
      expect(
        provider.recordedCalls.single.arguments,
        equals({'query': '1 Apple Park Way'}),
      );
    });

    test('returns canned suggestions when configured', () async {
      final provider = RecordingMapProvider(
        cannedSuggestions: EdenAddressInputFixtures.cannedSuggestionsForSf,
      );
      final result = await provider.autocompletePlaces('appl');

      expect(result, hasLength(3));
      expect(result.first.placeId, equals('place_apple_hq'));
    });

    test('returns canned address from geocodeAddress + resolvePlace', () async {
      final provider = RecordingMapProvider(
        cannedAddress: EdenAddressInputFixtures.cannedSf,
      );

      final geocoded = await provider.geocodeAddress('Apple Park');
      expect(geocoded, equals(EdenAddressInputFixtures.cannedSf));

      final resolved = await provider.resolvePlace('place_apple_hq');
      expect(resolved, equals(EdenAddressInputFixtures.cannedSf));

      // Both calls recorded.
      expect(provider.recordedCalls, hasLength(2));
      expect(provider.recordedCalls[0].method, equals('geocodeAddress'));
      expect(provider.recordedCalls[1].method, equals('resolvePlace'));
      expect(
        provider.recordedCalls[1].arguments,
        equals({'placeId': 'place_apple_hq'}),
      );
    });

    test('showMap returns a deterministic widget keyed on bounds', () {
      final provider = RecordingMapProvider();
      const bounds = EdenAddressInputFixtures.sfBounds;
      final widget = provider.showMap(
        bounds: bounds,
        markers: const [EdenAddressInputFixtures.sfMarker],
        interactive: false,
      );

      expect(
        widget.key,
        equals(ValueKey('recorded-map-${bounds.hashCode}')),
      );
      // showMap call was recorded with its arguments.
      expect(provider.recordedCalls, hasLength(1));
      final call = provider.recordedCalls.single;
      expect(call.method, equals('showMap'));
      expect(call.arguments['bounds'], equals(bounds));
      expect(call.arguments['interactive'], isFalse);
      expect(
        call.arguments['markers'],
        equals(const [EdenAddressInputFixtures.sfMarker]),
      );
    });

    test('clear() resets the recorded calls log', () async {
      final provider = RecordingMapProvider();
      await provider.autocompletePlaces('a');
      await provider.geocodeAddress('b');
      expect(provider.recordedCalls, hasLength(2));

      provider.clear();
      expect(provider.recordedCalls, isEmpty);

      // Subsequent calls record fresh.
      await provider.autocompletePlaces('c');
      expect(provider.recordedCalls, hasLength(1));
    });
  });
}
