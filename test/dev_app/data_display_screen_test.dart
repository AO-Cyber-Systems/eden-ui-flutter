// test/dev_app/data_display_screen_test.dart
//
// Smoke gate for objective 008 Wave 2 (TRD 008-03): the enriched
// data-display catalog screen renders at iPhone-narrow (390pt) without
// rendering exceptions in the NEW cross-vertical sections.

import 'package:eden_ui_flutter/dev_app/screens/data_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'DataDisplayScreen renders at iPhone-narrow (390pt) without overflow exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: DataDisplayScreen()),
    );
    // The screen mounts a large ListView; pump a couple frames for layout.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // App bar title rendered.
    expect(find.text('Data Display'), findsOneWidget);
    // At least one cross-vertical section title visible.
    expect(
      find.textContaining('Trades dispatch KPIs'),
      findsAtLeastNWidgets(1),
    );
    // No rendering exceptions raised.
    expect(tester.takeException(), isNull);
  });
}
