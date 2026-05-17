// test/dev_app/uswds_screen_test.dart
//
// Smoke gate for objective 011 Wave 1 (TRD 011-11): the new USWDS
// conformance catalog screen renders at iPhone-narrow (390pt) without
// overflow and surfaces the USWDSBanner in its English default state.

import 'package:eden_ui_flutter/dev_app/screens/uswds_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'UswdsScreen renders at iPhone-narrow (390pt) without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: UswdsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('USWDS Conformance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'UswdsScreen renders USWDSBanner in English collapsed state',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: UswdsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('An official website of the United States government'),
        findsOneWidget,
      );
      // Spanish variant present.
      expect(
        find.text('Un sitio web oficial del gobierno de los Estados Unidos'),
        findsOneWidget,
      );
      // Custom govLabel variants.
      expect(
        find.text('An official website of the California State government'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'UswdsScreen renders AgencyIdentifier section (DOD header + HHS footer)',
    (tester) async {
      // Make surface tall enough that everything fits without scrolling.
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: UswdsScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Department of Defense'), findsOneWidget);
      expect(find.text('General Services Administration'), findsOneWidget);
      expect(
        find.text('Department of Health and Human Services'),
        findsOneWidget,
      );
      expect(find.text('About HHS'), findsOneWidget);
    },
  );
}
