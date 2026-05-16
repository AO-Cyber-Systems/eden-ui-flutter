// test/dev_app/misc_screen_test.dart
//
// Smoke gate for objective 008 Wave 2 (TRD 008-04): MiscScreen renders at
// iPhone-narrow (390pt) including the new offline-queue + auth-image +
// network-lifecycle demos.
//
// The network-lifecycle Timer defaults to STOPPED, so pumpAndSettle is
// safe (no leaked timer).

import 'package:eden_ui_flutter/dev_app/screens/misc_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'MiscScreen renders at iPhone-narrow (390pt) without overflow exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MiscScreen()),
    );
    // Several frames for ListView + EdenAuthenticatedImage initState.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Misc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
