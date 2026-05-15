import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_address_input_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  // Helper: finds a TextField field by its label/decoration label.
  Finder findField(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextField),
    );
  }

  group('EdenAddressInput', () {
    testWidgets('renders 5 address TextField fields with default labels',
        (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenAddressInput(provider: provider),
      ));

      // 5 fields rendered (line1, line2, city, region, postal).
      expect(find.byType(TextField), findsNWidgets(5));
      // Default labels present.
      expect(find.text('Street address'), findsOneWidget);
      expect(find.text('Apt, suite, etc. (optional)'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      expect(find.text('State / region'), findsOneWidget);
      expect(find.text('Postal code'), findsOneWidget);
    });

    testWidgets('pre-fills fields from initialAddress', (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: provider,
          initialAddress: EdenAddressInputFixtures.cannedSf,
        ),
      ));

      expect(find.text('1 Apple Park Way'), findsOneWidget);
      expect(find.text('Cupertino'), findsOneWidget);
      expect(find.text('CA'), findsOneWidget);
      expect(find.text('95014'), findsOneWidget);
    });

    testWidgets(
        'typing <3 chars in line1 does NOT call provider.autocompletePlaces',
        (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: provider,
          autocompleteDebounce: const Duration(milliseconds: 50),
        ),
      ));

      await tester.enterText(findField('Street address'), 'ap');
      // Wait past the debounce window.
      await tester.pump(const Duration(milliseconds: 200));

      final autocompleteCalls = provider.recordedCalls
          .where((c) => c.method == 'autocompletePlaces');
      expect(autocompleteCalls, isEmpty);
    });

    testWidgets(
        'typing >=3 chars in line1 calls provider.autocompletePlaces after debounce',
        (tester) async {
      final provider = RecordingMapProvider(
        cannedSuggestions: EdenAddressInputFixtures.cannedSuggestionsForSf,
      );
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: provider,
          autocompleteDebounce: const Duration(milliseconds: 50),
        ),
      ));

      await tester.enterText(findField('Street address'), 'appl');
      // Wait past the debounce window.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      final autocompleteCalls = provider.recordedCalls
          .where((c) => c.method == 'autocompletePlaces')
          .toList();
      expect(autocompleteCalls, hasLength(1));
      expect(autocompleteCalls.single.arguments['query'], equals('appl'));
    });

    testWidgets(
        'shows suggestion list after autocomplete returns results',
        (tester) async {
      final provider = RecordingMapProvider(
        cannedSuggestions: EdenAddressInputFixtures.cannedSuggestionsForSf,
      );
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: provider,
          autocompleteDebounce: const Duration(milliseconds: 50),
        ),
      ));

      await tester.enterText(findField('Street address'), 'appl');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      expect(find.text('Apple Park'), findsOneWidget);
      expect(find.text('Twitter HQ'), findsOneWidget);
      expect(find.text('Salesforce Tower'), findsOneWidget);
    });

    testWidgets(
        'tapping a suggestion calls provider.resolvePlace and fills all fields',
        (tester) async {
      final provider = RecordingMapProvider(
        cannedSuggestions: EdenAddressInputFixtures.cannedSuggestionsForSf,
        cannedAddress: EdenAddressInputFixtures.cannedSf,
      );
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: provider,
          autocompleteDebounce: const Duration(milliseconds: 50),
        ),
      ));

      await tester.enterText(findField('Street address'), 'appl');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      // Tap the first suggestion (Apple Park).
      await tester.tap(find.text('Apple Park'));
      await tester.pump();

      // resolvePlace recorded with the correct placeId.
      final resolveCalls = provider.recordedCalls
          .where((c) => c.method == 'resolvePlace')
          .toList();
      expect(resolveCalls, hasLength(1));
      expect(
        resolveCalls.single.arguments['placeId'],
        equals('place_apple_hq'),
      );

      // All 5 fields populated from cannedSf.
      expect(find.text('1 Apple Park Way'), findsOneWidget);
      expect(find.text('Cupertino'), findsOneWidget);
      expect(find.text('CA'), findsOneWidget);
      expect(find.text('95014'), findsOneWidget);
    });

    testWidgets('onChanged fires with current EdenAddress on field edit',
        (tester) async {
      final provider = RecordingMapProvider();
      EdenAddress? lastChange;
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: provider,
          onChanged: (a) => lastChange = a,
          autocompleteDebounce: const Duration(milliseconds: 50),
        ),
      ));

      await tester.enterText(findField('City'), 'Berkeley');
      await tester.pump();

      expect(lastChange, isNotNull);
      expect(lastChange!.city, equals('Berkeley'));
    });

    testWidgets(
        'NoOpMapProvider — autocomplete is suppressed (no suggestion list)',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenAddressInput(
          provider: NoOpMapProvider(),
          autocompleteDebounce: Duration(milliseconds: 50),
        ),
      ));

      await tester.enterText(findField('Street address'), 'appl');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      // No suggestion items appear because no provider data.
      expect(find.text('Apple Park'), findsNothing);
    });

    testWidgets(
        'NoOpMapProvider — fields still render and accept manual entry',
        (tester) async {
      EdenAddress? lastChange;
      await tester.pumpWidget(wrap(
        EdenAddressInput(
          provider: const NoOpMapProvider(),
          onChanged: (a) => lastChange = a,
        ),
      ));

      expect(find.byType(TextField), findsNWidgets(5));

      await tester.enterText(findField('City'), 'Cupertino');
      await tester.pump();

      expect(lastChange?.city, equals('Cupertino'));
    });

    testWidgets('enabled=false disables all 5 fields', (tester) async {
      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenAddressInput(provider: provider, enabled: false),
      ));

      for (final tf in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(tf.enabled, isFalse);
      }
    });

    testWidgets('iPhone-narrow (390pt) — fields stack vertically without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = RecordingMapProvider();
      await tester.pumpWidget(wrap(
        EdenAddressInput(provider: provider),
      ));

      expect(find.byType(EdenAddressInput), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });
  });
}
