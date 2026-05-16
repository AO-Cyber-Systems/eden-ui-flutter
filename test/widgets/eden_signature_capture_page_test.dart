import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_signature_capture_page_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

/// Pushes the signature page from a host route — emulates real usage.
Future<dynamic> openSignaturePage(
  WidgetTester tester, {
  EdenSignatureCapturePage? page,
}) async {
  dynamic result;
  await tester.pumpWidget(wrap(Builder(builder: (ctx) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            result = await Navigator.of(ctx).push(
              MaterialPageRoute<dynamic>(
                  builder: (_) => page ?? const EdenSignatureCapturePage()),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  })));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('EdenSignatureCapturePage — composition smoke', () {
    testWidgets(
        'page mounts with default title, instructions, pad, divider, buttons',
        (tester) async {
      await openSignaturePage(tester);
      expect(find.byType(EdenSignaturePad), findsOneWidget);
      expect(find.text('Signature'), findsOneWidget);
      expect(find.text('Please sign in the box below'), findsOneWidget);
      // Default signer label.
      expect(find.text('Signer'), findsOneWidget);
      // Button row.
      expect(find.widgetWithText(OutlinedButton, 'Clear'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save Signature'),
          findsOneWidget);
    });
  });

  group('EdenSignatureCapturePage — custom props', () {
    testWidgets('custom title visible in AppBar', (tester) async {
      await openSignaturePage(tester,
          page:
              const EdenSignatureCapturePage(title: 'Customer Signature'));
      expect(find.text('Customer Signature'), findsOneWidget);
    });

    testWidgets('custom instructions visible', (tester) async {
      await openSignaturePage(tester,
          page: const EdenSignatureCapturePage(
              instructions: 'Please sign here for delivery'));
      expect(find.text('Please sign here for delivery'), findsOneWidget);
    });

    testWidgets('signerName visible in divider row', (tester) async {
      await openSignaturePage(tester,
          page:
              const EdenSignatureCapturePage(signerName: 'Mr. Johnson'));
      expect(find.text('Mr. Johnson'), findsOneWidget);
    });
  });

  group('EdenSignatureCapturePage — initial state (no strokes)', () {
    testWidgets('Save FilledButton disabled when no strokes', (tester) async {
      await openSignaturePage(tester);
      final btn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save Signature'));
      expect(btn.onPressed, isNull);
    });

    testWidgets('Body Clear OutlinedButton disabled when no strokes',
        (tester) async {
      await openSignaturePage(tester);
      final btn = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Clear'));
      expect(btn.onPressed, isNull);
    });

    testWidgets('AppBar Clear NOT visible when no strokes (default config)',
        (tester) async {
      await openSignaturePage(tester);
      // Body has Clear (OutlinedButton); AppBar should not have a Clear TextButton.
      expect(find.widgetWithText(TextButton, 'Clear'), findsNothing);
    });
  });

  group('EdenSignatureCapturePage — initialStrokes injection', () {
    testWidgets(
        'initialStrokes: [sample] — Save + Clear enabled + AppBar Clear visible',
        (tester) async {
      await openSignaturePage(tester,
          page: EdenSignatureCapturePage(
            initialStrokes: [
              EdenSignatureCapturePageFixtures.sampleStroke()
            ],
          ));
      final save = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save Signature'));
      expect(save.onPressed, isNotNull);
      final clear = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Clear'));
      expect(clear.onPressed, isNotNull);
      // AppBar Clear visible.
      expect(find.widgetWithText(TextButton, 'Clear'), findsOneWidget);
    });
  });

  group('EdenSignatureCapturePage — clear behavior', () {
    testWidgets('tap body Clear → buttons disabled again', (tester) async {
      await openSignaturePage(tester,
          page: EdenSignatureCapturePage(
            initialStrokes: [
              EdenSignatureCapturePageFixtures.sampleStroke()
            ],
          ));
      await tester
          .tap(find.widgetWithText(OutlinedButton, 'Clear'));
      await tester.pumpAndSettle();
      final save = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save Signature'));
      expect(save.onPressed, isNull);
    });
  });

  group('EdenSignatureCapturePage — save behavior', () {
    testWidgets(
        'tap Save with strokes → onSigned fires with result and page pops',
        (tester) async {
      final (captured, signed) = EdenSignatureCapturePageFixtures.recorder();
      await openSignaturePage(tester,
          page: EdenSignatureCapturePage(
            initialStrokes: [
              EdenSignatureCapturePageFixtures.sampleStroke()
            ],
            metadata: const {'work_order_id': 'WO-4821'},
            onSigned: signed,
          ));
      await tester.tap(find.widgetWithText(FilledButton, 'Save Signature'));
      await tester.pumpAndSettle();
      expect(captured, hasLength(1));
      expect(captured.first.strokes, isNotEmpty);
      expect(captured.first.metadata['work_order_id'], 'WO-4821');
      // Page popped.
      expect(find.byType(EdenSignatureCapturePage), findsNothing);
    });

    testWidgets(
        'onSigned: null — Save still pops with result',
        (tester) async {
      await openSignaturePage(tester,
          page: EdenSignatureCapturePage(
            initialStrokes: [
              EdenSignatureCapturePageFixtures.sampleStroke()
            ],
          ));
      await tester.tap(find.widgetWithText(FilledButton, 'Save Signature'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenSignatureCapturePage), findsNothing);
    });

    testWidgets('onSigned throws → SnackBar visible + page NOT popped',
        (tester) async {
      await openSignaturePage(tester,
          page: EdenSignatureCapturePage(
            initialStrokes: [
              EdenSignatureCapturePageFixtures.sampleStroke()
            ],
            onSigned: EdenSignatureCapturePageFixtures.failing('boom'),
          ));
      await tester.tap(find.widgetWithText(FilledButton, 'Save Signature'));
      await tester.pumpAndSettle();
      expect(find.byType(EdenSignatureCapturePage), findsOneWidget);
      expect(find.textContaining('Failed to save signature'), findsOneWidget);
    });
  });

  group('EdenSignatureCapturePage — date formatter', () {
    testWidgets('"Signed on M/D/YYYY" visible', (tester) async {
      await openSignaturePage(tester);
      final dateRegex = RegExp(r'Signed on \d{1,2}/\d{1,2}/\d{4}');
      expect(
          find.byWidgetPredicate((w) =>
              w is Text &&
              w.data != null &&
              dateRegex.hasMatch(w.data!)),
          findsOneWidget);
    });
  });

  group('EdenSignatureCapturePage — iPhone-narrow ≥390pt', () {
    testWidgets('renders without overflow at 390x800', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openSignaturePage(tester);
      expect(find.byType(EdenSignaturePad), findsOneWidget);
    });
  });
}
