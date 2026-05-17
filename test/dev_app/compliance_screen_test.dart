// test/dev_app/compliance_screen_test.dart
//
// Smoke gate for objective 011 Wave 1 (TRD 011-01): the new compliance
// catalog screen renders at iPhone-narrow (390pt) without overflow and
// surfaces all 4 federal classification banners.

import 'package:eden_ui_flutter/dev_app/screens/compliance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'ComplianceScreen renders at iPhone-narrow (390pt) without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ComplianceScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Compliance Overlay Primitives'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'ComplianceScreen renders all 4 federal classification banners',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: ComplianceScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('UNCLASSIFIED'), findsAtLeastNWidgets(1));
      expect(find.text('CUI'), findsAtLeastNWidgets(1));
      // SECRET appears in 3 places (bar level + watermark + scaffold top+bottom)
      expect(find.text('SECRET'), findsAtLeastNWidgets(1));
      // TOP SECRET appears in the bar variant + the watermark overlay
      expect(find.text('TOP SECRET'), findsAtLeastNWidgets(1));
    },
  );
}
