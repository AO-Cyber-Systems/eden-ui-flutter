// test/dev_app/companion_screen_test.dart
//
// Smoke gate for objective 008 Wave 3 (TRD 008-05): the enriched
// companion catalog screen renders at iPhone-narrow without overflow
// exceptions, and exposes the new 5-vertical EdenCompanionShell picker.

import 'package:eden_ui_flutter/dev_app/screens/companion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'CompanionScreen renders at iPhone-narrow (390pt) without overflow exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CompanionScreen()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Companion Shell'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CompanionScreen renders at wide viewport (1280pt) without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: CompanionScreen()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // ListView is lazy — the new vertical-picker section may be below the
    // initial viewport even at 1280pt. Confirming no rendering exception is
    // the contract here; scroll-driven content assertions belong to a
    // future visual regression objective.
    expect(tester.takeException(), isNull);
  });
}
