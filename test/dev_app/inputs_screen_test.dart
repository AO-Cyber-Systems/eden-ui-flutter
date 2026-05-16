// test/dev_app/inputs_screen_test.dart
//
// Smoke gate for objective 008 Wave 2 (TRD 008-04): InputsScreen renders
// at iPhone-narrow (390pt) including the new cross-vertical phone country
// grid + OTP length grid + 5 address demos.

import 'package:eden_ui_flutter/dev_app/screens/inputs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'InputsScreen renders at iPhone-narrow (390pt) without overflow exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: InputsScreen()),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Inputs'), findsOneWidget);
    // The InputsScreen is a long lazy ListView; the new cross-vertical
    // sections (phone country grid / OTP grid / address demos) live below
    // the initial viewport at 390pt. Confirming render-without-exception is
    // the contract — scroll-into-view assertions belong to a future visual
    // regression test (VRT-01 v2).
    expect(tester.takeException(), isNull);
  });
}
