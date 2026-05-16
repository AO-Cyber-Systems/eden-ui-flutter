import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_photo_capture_page_fixtures.dart';

Widget wrap(Widget child) => MaterialApp(home: child);

Future<dynamic> openPage(WidgetTester tester,
    {EdenPhotoCapturePage? page}) async {
  dynamic result;
  await tester.pumpWidget(wrap(Builder(builder: (ctx) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            result = await Navigator.of(ctx).push(
              MaterialPageRoute<dynamic>(
                builder: (_) => page ??
                    EdenPhotoCapturePage(
                      onCapture: (_) async =>
                          EdenPhotoCapturePageFixtures.sample(),
                    ),
              ),
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
  group('EdenPhotoCapturePage — composition smoke (pre-capture)', () {
    testWidgets(
        'page mounts with default title, black bg, placeholder when no builder',
        (tester) async {
      await openPage(tester);
      expect(find.byType(EdenPhotoCapturePage), findsOneWidget);
      expect(find.text('Capture Photo'), findsOneWidget);
      expect(find.text('Camera viewfinder placeholder'), findsOneWidget);
      // Shutter button by key.
      expect(find.byKey(const ValueKey('eden_photo_capture_shutter')),
          findsOneWidget);
    });

    testWidgets('cameraPreviewBuilder provided → builder renders, placeholder hidden',
        (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            cameraPreviewBuilder: (ctx) =>
                Container(key: const ValueKey('cam-stub')),
          ));
      expect(find.byKey(const ValueKey('cam-stub')), findsOneWidget);
      expect(find.text('Camera viewfinder placeholder'), findsNothing);
    });
  });

  group('EdenPhotoCapturePage — custom AppBar title', () {
    testWidgets('appBarTitle override visible', (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            appBarTitle: 'Add Inspection Photo',
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
          ));
      expect(find.text('Add Inspection Photo'), findsOneWidget);
    });
  });

  group('EdenPhotoCapturePage — capture flow', () {
    testWidgets('tap shutter fires onCapture with the capture request',
        (tester) async {
      final (captured, fn) =
          EdenPhotoCapturePageFixtures.captureRecorder();
      await openPage(tester,
          page: EdenPhotoCapturePage(
            appointmentId: 'apt-123',
            fieldId: 'before',
            onCapture: fn,
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      expect(captured, hasLength(1));
      expect(captured.first.appointmentId, 'apt-123');
      expect(captured.first.fieldId, 'before');
    });

    testWidgets('after capture, Retake + Use Photo + annotation visible',
        (tester) async {
      await openPage(tester);
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Retake'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Use Photo'), findsOneWidget);
      // AppBar Use Photo TextButton.
      expect(find.widgetWithText(TextButton, 'Use Photo'), findsOneWidget);
      // Annotation TextField.
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('EdenPhotoCapturePage — capture spinner', () {
    testWidgets('slow capture → spinner visible mid-flight', (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: EdenPhotoCapturePageFixtures.slowCapture(),
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pump(); // begin
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('EdenPhotoCapturePage — capture error', () {
    testWidgets('onCapture throws → SnackBar + remains pre-capture',
        (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: EdenPhotoCapturePageFixtures.failingCapture('boom'),
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Capture failed'), findsOneWidget);
      // Still pre-capture.
      expect(find.text('Camera viewfinder placeholder'), findsOneWidget);
    });
  });

  group('EdenPhotoCapturePage — gallery flow', () {
    testWidgets(
        'onPickFromGallery non-null → Gallery icon button visible + tap fires',
        (tester) async {
      final (countFn, fn) =
          EdenPhotoCapturePageFixtures.galleryRecorder();
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            onPickFromGallery: fn,
          ));
      final btn = find.byKey(const ValueKey('eden_photo_capture_gallery'));
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pumpAndSettle();
      expect(countFn(), 1);
    });

    testWidgets('onPickFromGallery null → Gallery button NOT visible',
        (tester) async {
      await openPage(tester);
      expect(find.byKey(const ValueKey('eden_photo_capture_gallery')),
          findsNothing);
    });
  });

  group('EdenPhotoCapturePage — categories', () {
    testWidgets('categories null → no FilterChip row', (tester) async {
      await openPage(tester);
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('categories with 3 items → 3 chips post-capture',
        (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            categories: const ['before', 'during', 'after'],
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsNWidgets(3));
    });

    testWidgets('single-select: tapping a chip selects it', (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            categories: const ['before', 'during', 'after'],
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'during'));
      await tester.pumpAndSettle();
      final chip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'during'));
      expect(chip.selected, isTrue);
    });
  });

  group('EdenPhotoCapturePage — category required', () {
    testWidgets('required + no selection → Use Photo disabled',
        (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            categories: const ['before', 'during', 'after'],
            categoryRequired: true,
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      final btn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Use Photo'));
      expect(btn.onPressed, isNull);
    });

    testWidgets('required + selection → Use Photo enabled', (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            categories: const ['before', 'during', 'after'],
            categoryRequired: true,
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'before'));
      await tester.pumpAndSettle();
      final btn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Use Photo'));
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EdenPhotoCapturePage — Use Photo pop', () {
    testWidgets('tap Use Photo → pop with EdenPhotoCaptureResult',
        (tester) async {
      await openPage(tester,
          page: EdenPhotoCapturePage(
            onCapture: (_) async => EdenPhotoCapturePageFixtures.sample(),
            categories: const ['before', 'during', 'after'],
          ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Notes');
      await tester.tap(find.widgetWithText(FilterChip, 'after'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Use Photo'));
      await tester.pumpAndSettle();
      // Page popped.
      expect(find.byType(EdenPhotoCapturePage), findsNothing);
    });
  });

  group('EdenPhotoCapturePage — Retake', () {
    testWidgets('tap Retake → reverts to pre-capture state', (tester) async {
      await openPage(tester);
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Retake'));
      await tester.pumpAndSettle();
      expect(find.text('Camera viewfinder placeholder'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Retake'), findsNothing);
    });
  });

  group('EdenPhotoCapturePage — constructor assert', () {
    test('onCapture: null + onPickFromGallery: null → AssertionError', () {
      expect(() => EdenPhotoCapturePage(),
          throwsA(isA<AssertionError>()));
    });
  });

  group('EdenPhotoCapturePage — iPhone-narrow ≥390pt', () {
    testWidgets('mounts at 390x800 without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await openPage(tester);
      expect(find.byType(EdenPhotoCapturePage), findsOneWidget);
    });
  });
}
