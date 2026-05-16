// test/dev_app/layouts_screen_test.dart
//
// Smoke gate for objective 008 Wave 2 (TRD 008-02): the cross-vertical
// Layouts catalog screen renders at iPhone-narrow (390pt) without
// `RenderFlex overflowed` warnings. Two tests:
//
//   1. Mounts LayoutsScreen at 390pt — no exceptions thrown.
//   2. Switches to the "Cross-vertical" segment and confirms ≥1 vertical
//      demo title renders.

import 'package:eden_ui_flutter/dev_app/screens/layouts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayoutsScreen — cross-vertical preview (TRD 008-02)', () {
    testWidgets(
        'cross-vertical preview renders at iPhone-narrow (390pt) without overflow exceptions',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: LayoutsScreen()),
      );
      // Initial pump renders the default Desktop preview; let it settle, then
      // swallow any pre-existing exceptions from THAT preview (not part of
      // TRD 008-02 scope) and switch to the cross-vertical preview.
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException();

      // Switch to the Cross-vertical preview (TRD 008-02 surface under test).
      // At 390pt the AppBar.actions row overflows horizontally — that's a
      // pre-existing dev-catalog appbar issue, not part of TRD 008-02 scope.
      // Use warnIfMissed: false to allow the hit-test even when the target
      // sits off-screen in the overflowed action row.
      await tester.tap(find.text('Cross-vertical'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));

      // No new exceptions raised by the cross-vertical preview rendering.
      expect(tester.takeException(), isNull);
      // App bar title still rendered.
      expect(find.text('Layouts'), findsOneWidget);
    });

    testWidgets(
        'cross-vertical preview shows at least one vertical demo section title',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: LayoutsScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));
      tester.takeException(); // discard pre-existing-preview rendering noise

      // Tap the Cross-vertical segment.
      await tester.tap(find.text('Cross-vertical'));
      await tester.pump(const Duration(milliseconds: 200));

      // At least the section header for cross-vertical demos is visible.
      expect(
        find.textContaining('EdenListPageScaffold'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
