import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_hazmat_doc_viewer_fixtures.dart';

void main() {
  Widget wrap(Widget child, {double width = 600, double height = 800}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: width, height: height, child: child),
        ),
      );

  Color certPillColorOf(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('eden-hazmat-cert-pill')),
    );
    return (container.decoration as BoxDecoration).color!;
  }

  // -----------------------------------------------------------------
  // Task 1 — Static rendering + cert pill variants + MSDS button enable
  // -----------------------------------------------------------------
  group('EdenHazmatDocViewer static rendering', () {
    testWidgets("renders 'DOT Manifest' title", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      expect(find.text('DOT Manifest'), findsOneWidget);
    });

    testWidgets('renders EdenAttachmentPreview for manifest', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      expect(find.byType(EdenAttachmentPreview), findsOneWidget);
    });

    testWidgets("renders cert pill 'DOT HM-126F • Driver J. Smith • Valid'",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      expect(find.text('DOT HM-126F • Driver J. Smith • Valid'), findsOneWidget);
    });

    testWidgets("renders MSDS button labeled 'View MSDS'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      expect(find.widgetWithText(OutlinedButton, 'View MSDS'), findsOneWidget);
    });

    testWidgets('MSDS button is enabled when msdsAttachment non-null',
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'View MSDS'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('EdenHazmatDocViewer cert pill status variants', () {
    testWidgets('valid → green (success)', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      expect(certPillColorOf(tester), EdenColors.success);
    });

    testWidgets("valid → suffix 'Valid'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.full),
      ));
      expect(find.textContaining('• Valid'), findsOneWidget);
    });

    testWidgets("expiringSoon → amber + suffix 'Expiring soon'",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.expiring),
      ));
      expect(certPillColorOf(tester), EdenColors.warning);
      expect(find.textContaining('• Expiring soon'), findsOneWidget);
    });

    testWidgets("expired → red + suffix 'Expired'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.expired),
      ));
      expect(certPillColorOf(tester), EdenColors.error);
      expect(find.textContaining('• Expired'), findsOneWidget);
    });

    testWidgets("none → grey + suffix 'No cert'", (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.noneCert),
      ));
      expect(certPillColorOf(tester), const Color(0xFF94A3B8));
      expect(find.textContaining('• No cert'), findsOneWidget);
    });
  });

  group('EdenHazmatDocViewer optional fields', () {
    testWidgets('no driverCertLabel → no cert pill rendered', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.noDriverCert),
      ));
      expect(find.byKey(const ValueKey('eden-hazmat-cert-pill')), findsNothing);
    });

    testWidgets('no MSDS → MSDS button disabled', (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(data: EdenHazmatDocViewerFixtures.noMsds),
      ));
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'View MSDS'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets("manifest url null → 'Manifest unavailable' placeholder",
        (tester) async {
      await tester.pumpWidget(wrap(
        const EdenHazmatDocViewer(
          data: EdenHazmatDocViewerFixtures.noManifestUrl,
        ),
      ));
      expect(find.text('Manifest unavailable'), findsOneWidget);
      expect(find.byType(EdenAttachmentPreview), findsNothing);
    });
  });
}
