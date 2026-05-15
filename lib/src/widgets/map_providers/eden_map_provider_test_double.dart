import 'package:flutter/widgets.dart';

import 'eden_map_provider.dart';
import 'eden_map_types.dart';

/// In-memory test double implementing [EdenMapProvider].
///
/// **Why this lives in `lib/`, not `test/`:** downstream apps' widget tests
/// also need to inject a recording provider without depending on the
/// `eden-ui-flutter` package's private test sources. Shipping the test
/// double on the public API surface means consumers can do:
///
/// ```dart
/// import 'package:eden_ui_flutter/eden_ui.dart';
///
/// testWidgets('my widget uses the map provider', (tester) async {
///   final provider = RecordingMapProvider(
///     cannedSuggestions: const [...],
///     cannedAddress: const EdenAddress(...),
///   );
///   await tester.pumpWidget(MyWidget(provider: provider));
///   // ...
///   expect(provider.recordedCalls, hasLength(2));
/// });
/// ```
///
/// Per `VERTICAL_COVERAGE_ASSESSMENT_2026-05-15.md` §6 locked decision 3,
/// the library core ships only the interface ([EdenMapProvider]) plus
/// [NoOpMapProvider] and this [RecordingMapProvider]. Concrete vendor SDK
/// impls (Google Maps, Mapbox, MapLibre + Pelias) ship as separate sibling
/// packages and pull in their own dependencies.
class RecordingMapProvider implements EdenMapProvider {
  RecordingMapProvider({
    this.cannedAddress,
    this.cannedSuggestions = const <EdenPlaceSuggestion>[],
  });

  /// Returned by [geocodeAddress], [reverseGeocode], and [resolvePlace] when
  /// non-null. When null, those methods return null (matching
  /// `NoOpMapProvider` semantics for unconfigured impls).
  final EdenAddress? cannedAddress;

  /// Returned by [autocompletePlaces]. Defaults to an empty list.
  final List<EdenPlaceSuggestion> cannedSuggestions;

  final List<RecordedMapCall> _calls = <RecordedMapCall>[];

  /// Immutable view of every recorded call in chronological order.
  ///
  /// Tests should assert on `provider.recordedCalls` instead of mutating it;
  /// the list is wrapped in `List.unmodifiable` for that reason.
  List<RecordedMapCall> get recordedCalls =>
      List<RecordedMapCall>.unmodifiable(_calls);

  /// Empties the recorded-calls log. Useful when reusing one provider
  /// instance across multiple test phases (arrange → act → assert → reset).
  void clear() => _calls.clear();

  @override
  Widget showMap({
    required EdenMapBounds bounds,
    List<EdenMapMarker> markers = const <EdenMapMarker>[],
    void Function(EdenLatLng)? onTap,
    bool interactive = true,
  }) {
    _calls.add(RecordedMapCall._('showMap', <String, dynamic>{
      'bounds': bounds,
      'markers': markers,
      'onTap': onTap,
      'interactive': interactive,
    }));
    return Container(key: ValueKey<String>('recorded-map-${bounds.hashCode}'));
  }

  @override
  Future<EdenAddress?> geocodeAddress(String query) async {
    _calls.add(RecordedMapCall._('geocodeAddress', <String, dynamic>{
      'query': query,
    }));
    return cannedAddress;
  }

  @override
  Future<EdenAddress?> reverseGeocode(EdenLatLng position) async {
    _calls.add(RecordedMapCall._('reverseGeocode', <String, dynamic>{
      'position': position,
    }));
    return cannedAddress;
  }

  @override
  Future<List<EdenPlaceSuggestion>> autocompletePlaces(
    String query, {
    int limit = 5,
  }) async {
    _calls.add(RecordedMapCall._('autocompletePlaces', <String, dynamic>{
      'query': query,
      'limit': limit,
    }));
    return cannedSuggestions;
  }

  @override
  Future<EdenAddress?> resolvePlace(String placeId) async {
    _calls.add(RecordedMapCall._('resolvePlace', <String, dynamic>{
      'placeId': placeId,
    }));
    return cannedAddress;
  }
}

/// A single record of a method call against [RecordingMapProvider].
///
/// `method` is the bare method name (e.g. `'autocompletePlaces'`).
/// `arguments` is a `Map<String, dynamic>` keyed by parameter name; tests
/// match against it with `equals(...)` for the cases they care about and
/// ignore the rest.
@immutable
class RecordedMapCall {
  const RecordedMapCall._(this.method, this.arguments);

  final String method;
  final Map<String, dynamic> arguments;

  @override
  String toString() => 'RecordedMapCall($method, $arguments)';
}
