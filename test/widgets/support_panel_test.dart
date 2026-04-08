import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:eden_ui_flutter/src/pages/eden_support_panel_demo_page.dart';
import 'package:eden_ui_flutter/src/widgets/support_panel/eden_support_fab.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(
      theme: EdenTheme.dark(brand: EdenColors.gold),
      home: const Scaffold(body: EdenSupportPanelDemoPage()),
    );
  }

  group('EdenSupportPanel', () {
    testWidgets('renders demo page with FAB', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Demo content visible
      expect(find.text('Support Panel Demo'), findsWidgets);

      // FAB should be visible
      expect(find.byType(EdenSupportFab), findsOneWidget);
    });

    testWidgets('FAB opens panel with tabs', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Tap FAB to open panel
      await tester.tap(find.bySemanticsLabel('Open support panel'));
      await tester.pumpAndSettle();

      // Panel should show tabs
      expect(find.text('Help'), findsWidgets);
      expect(find.text('Support'), findsWidgets);
      expect(find.text('Tours'), findsWidgets);
    });

    testWidgets('Help tab shows articles after loading', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.bySemanticsLabel('Open support panel'));
      await tester.pumpAndSettle();

      // Wait for mock data load (500ms delay)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show articles
      expect(find.text('How to create your first project'), findsOneWidget);
    });

    testWidgets('Support tab shows tickets', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.bySemanticsLabel('Open support panel'));
      await tester.pumpAndSettle();

      // Switch to Support tab (use last match — tab label, not header)
      await tester.tap(find.text('Support').last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show tickets
      expect(find.text('Cannot export CSV from data table'), findsOneWidget);
    });

    testWidgets('Tours tab shows available tours', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.bySemanticsLabel('Open support panel'));
      await tester.pumpAndSettle();

      // Switch to Tours tab
      await tester.tap(find.text('Tours'));
      await tester.pumpAndSettle();

      // Should show tour definitions
      expect(find.text('Welcome Tour'), findsOneWidget);
      expect(find.text('Settings Tour'), findsOneWidget);
    });

    testWidgets('panel closes when close button tapped', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.bySemanticsLabel('Open support panel'));
      await tester.pumpAndSettle();

      // Verify panel is open (header visible)
      expect(find.text('Support'), findsWidgets);

      // Tap close button
      await tester.tap(find.bySemanticsLabel('Close support panel'));
      await tester.pumpAndSettle();

      // FAB should reappear
      expect(find.byType(EdenSupportFab), findsOneWidget);
    });

    testWidgets('Help tab article detail and feedback', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.bySemanticsLabel('Open support panel'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Tap on first article
      await tester.tap(find.text('How to create your first project'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Should show article body
      expect(find.textContaining('Creating your first project'), findsOneWidget);
    });
  });
}
