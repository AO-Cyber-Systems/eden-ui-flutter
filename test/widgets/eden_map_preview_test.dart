import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_address_input_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('EdenMapPreview', () {
    testWidgets('renders RecordingMapProvider widget keyed on bounds',
        (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenMapPreview(
          provider: provider,
          bounds: EdenAddressInputFixtures.sfBounds,
        ),
      ));

      expect(provider.recordedCalls, hasLength(1));
      expect(provider.recordedCalls.single.method, equals('showMap'));
      expect(
        find.byKey(ValueKey(
            'recorded-map-${EdenAddressInputFixtures.sfBounds.hashCode}')),
        findsOneWidget,
      );
    });

    testWidgets('forwards markers + interactive flag to provider.showMap',
        (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenMapPreview(
          provider: provider,
          bounds: EdenAddressInputFixtures.sfBounds,
          markers: const [EdenAddressInputFixtures.sfMarker],
          interactive: false,
        ),
      ));

      final call = provider.recordedCalls.single;
      expect(call.arguments['interactive'], isFalse);
      expect(
        call.arguments['markers'],
        equals(const [EdenAddressInputFixtures.sfMarker]),
      );
    });

    testWidgets('sizes itself to the given width/height', (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        Center(
          child: EdenMapPreview(
            provider: provider,
            bounds: EdenAddressInputFixtures.sfBounds,
            width: 320,
            height: 180,
          ),
        ),
      ));

      final preview = tester.getSize(find.byType(EdenMapPreview));
      expect(preview.width, equals(320));
      expect(preview.height, equals(180));
    });

    testWidgets(
        'pinPicker=true wires provider.showMap onTap to onPinSet callback',
        (tester) async {
      final provider = RecordingMapProvider();
      EdenLatLng? pinned;
      await tester.pumpWidget(wrap(
        EdenMapPreview(
          provider: provider,
          bounds: EdenAddressInputFixtures.sfBounds,
          pinPicker: true,
          onPinSet: (p) => pinned = p,
        ),
      ));

      final call = provider.recordedCalls.single;
      final onTap = call.arguments['onTap'] as void Function(EdenLatLng)?;
      expect(onTap, isNotNull);
      onTap!(EdenAddressInputFixtures.sfLatLng);
      expect(pinned, equals(EdenAddressInputFixtures.sfLatLng));
    });

    testWidgets('pinPicker=false does NOT forward an onTap', (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenMapPreview(
          provider: provider,
          bounds: EdenAddressInputFixtures.sfBounds,
          // pinPicker defaults to false.
          onPinSet: (_) {},
        ),
      ));

      final call = provider.recordedCalls.single;
      expect(call.arguments['onTap'], isNull);
    });

    testWidgets(
        'NoOpMapProvider renders a placeholder card with "Map unavailable"',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMapPreview(
          provider: NoOpMapProvider(),
          bounds: EdenAddressInputFixtures.sfBounds,
        ),
      ));

      expect(find.text('Map unavailable'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets(
        'NoOpMapProvider respects custom unavailableMessage', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenMapPreview(
          provider: NoOpMapProvider(),
          bounds: EdenAddressInputFixtures.sfBounds,
          unavailableMessage: 'No map for this region',
        ),
      ));

      expect(find.text('No map for this region'), findsOneWidget);
    });

    testWidgets('iPhone-narrow (390pt) renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenMapPreview(
          provider: provider,
          bounds: EdenAddressInputFixtures.sfBounds,
        ),
      ));

      expect(find.byType(EdenMapPreview), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
