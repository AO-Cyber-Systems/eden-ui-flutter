import 'package:flutter/material.dart';

import 'map_providers/eden_map_provider.dart';
import 'map_providers/eden_map_types.dart';

/// Read-only map thumbnail rendered through an injected [EdenMapProvider].
///
/// Transport-agnostic by design: the widget itself imports no map SDK. The
/// injected [provider] (vendor-specific impl in a sibling package, or the
/// in-library [NoOpMapProvider] / [RecordingMapProvider]) renders the
/// actual tiles. When [provider] is a [NoOpMapProvider], renders a
/// graceful-degradation placeholder Card with [unavailableMessage] — this
/// is the default behavior so library consumers can ship without wiring a
/// concrete map SDK.
///
/// Example:
/// ```dart
/// EdenMapPreview(
///   provider: context.read<EdenMapProvider>(),
///   bounds: EdenMapBounds.fromMarkers(markers)!,
///   markers: markers,
///   height: 220,
/// );
/// ```
///
/// Pin-picker mode (`pinPicker: true`) forwards taps on the map back to
/// [onPinSet] via the provider's [EdenMapProvider.showMap] `onTap` callback.
/// Concrete providers handle the gesture detection; this widget only wires
/// the callback.
class EdenMapPreview extends StatelessWidget {
  const EdenMapPreview({
    super.key,
    required this.provider,
    required this.bounds,
    this.markers = const <EdenMapMarker>[],
    this.width,
    this.height = 200,
    this.pinPicker = false,
    this.onPinSet,
    this.interactive = true,
    this.unavailableMessage = 'Map unavailable',
  });

  final EdenMapProvider provider;
  final EdenMapBounds bounds;
  final List<EdenMapMarker> markers;

  /// Logical-pixel width. When null, expands to fill the parent's width.
  final double? width;

  /// Logical-pixel height. Defaults to 200 — a reasonable address-preview
  /// thumb height that fits comfortably on iPhone-narrow (390pt) layouts.
  final double height;

  /// When true, taps on the map fire [onPinSet] with the tap position. When
  /// false (default), the map is purely read-only and taps are ignored.
  final bool pinPicker;

  final ValueChanged<EdenLatLng>? onPinSet;

  /// When false, the provider should disable pan/zoom gestures (use case:
  /// inline address-preview cards that the user only views).
  final bool interactive;

  /// Placeholder text rendered when the provider is a [NoOpMapProvider].
  final String unavailableMessage;

  @override
  Widget build(BuildContext context) {
    // Graceful degradation: when no real map SDK is wired up, show a Card
    // placeholder instead of an empty SizedBox so the surrounding layout
    // doesn't visually disappear.
    if (provider is NoOpMapProvider) {
      return SizedBox(
        width: width,
        height: height,
        child: Card(
          margin: EdgeInsets.zero,
          child: Center(
            child: Text(
              unavailableMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: provider.showMap(
        bounds: bounds,
        markers: markers,
        interactive: interactive,
        onTap: pinPicker ? onPinSet : null,
      ),
    );
  }
}
