// EdenMediaPickerView / EdenMediaPickerModal widget tests — RED phase.
//
// Tests are written against the public contract BEFORE the implementation
// exists in eden_ui_flutter. They test EdenMediaPickerView directly (pure
// view isolation — no Riverpod, no ConnectRPC, no dart:html).
//
// Coverage:
//   1. Widget renders: two tabs visible (Library + Upload)
//   2. Library tab shows empty-state message when browseFn is null (MVP stub)
//   3. Upload tab shows "Choose file" button
//   4. Successful upload: calls onUrlSelected with CDN URL + shows toast
//   5. Upload with invalid MIME: shows inline error banner, no upload call
//   6. User cancels file picker: no error shown
//   7. Upload failure: shows inline error banner with server message
//   8. Cancel button closes modal (Navigator.pop)

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_media_picker_fixtures.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wrap EdenMediaPickerView in a minimal MaterialApp scaffold so we get a
/// Navigator (needed for Navigator.pop in cancel button) and a Scaffold
/// (needed for EdenToast SnackBar layer).
Widget wrapView({
  required UploadFn uploadFn,
  required PickFileFn pickFileFn,
  void Function(String)? onUrlSelected,
  List<String>? allowedMimeTypes,
  int? maxUploadBytes,
}) {
  return MaterialApp(
    home: Scaffold(
      body: EdenMediaPickerView(
        uploadFn: uploadFn,
        pickFileFn: pickFileFn,
        onUrlSelected: onUrlSelected ?? (_) {},
        allowedMimeTypes: allowedMimeTypes ??
            const ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml'],
        maxUploadBytes: maxUploadBytes ?? (10 * 1024 * 1024),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('EdenMediaPickerView — tab structure', () {
    testWidgets('1. Renders Library and Upload tabs', (tester) async {
      await tester.pumpWidget(wrapView(
        uploadFn: successUploadFn,
        pickFileFn: pickCancelled,
      ));

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Upload'), findsOneWidget);
    });

    testWidgets('2. Library tab shows empty-state / stub message', (tester) async {
      await tester.pumpWidget(wrapView(
        uploadFn: successUploadFn,
        pickFileFn: pickCancelled,
      ));

      // Tap Library tab (index 0)
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      // Should show an empty-state placeholder (no real library until browseFn is wired)
      expect(find.byType(EdenEmptyState), findsOneWidget);
    });

    testWidgets('3. Upload tab shows "Choose file" button', (tester) async {
      await tester.pumpWidget(wrapView(
        uploadFn: successUploadFn,
        pickFileFn: pickCancelled,
      ));

      // Upload tab is the default (index 1)
      expect(find.text('Choose file'), findsOneWidget);
    });
  });

  group('EdenMediaPickerView — successful upload', () {
    testWidgets('4. Successful upload calls onUrlSelected with CDN URL', (tester) async {
      String? capturedUrl;

      await tester.pumpWidget(wrapView(
        uploadFn: successUploadFn,
        pickFileFn: pickJpeg,
        onUrlSelected: (url) => capturedUrl = url,
      ));

      await tester.tap(find.text('Choose file'));
      await tester.pump(); // start async
      await tester.pump(); // complete upload

      expect(capturedUrl, equals('https://cdn.example.com/media/photo.jpg'));
    });
  });

  group('EdenMediaPickerView — MIME validation', () {
    testWidgets('5. Invalid MIME shows inline error banner, does not call onUrlSelected',
        (tester) async {
      bool uploadCalled = false;
      String? capturedUrl;

      await tester.pumpWidget(wrapView(
        uploadFn: ({required filename, required contentType, required bytes}) async {
          uploadCalled = true;
          return 'https://cdn.example.com/media/$filename';
        },
        pickFileFn: pickInvalidMime,
        onUrlSelected: (url) => capturedUrl = url,
      ));

      await tester.tap(find.text('Choose file'));
      await tester.pump();
      await tester.pump();

      expect(uploadCalled, isFalse);
      expect(capturedUrl, isNull);
      expect(find.byType(EdenInlineErrorBanner), findsOneWidget);
    });
  });

  group('EdenMediaPickerView — cancel and failure', () {
    testWidgets('6. User cancels file picker: no error banner shown', (tester) async {
      await tester.pumpWidget(wrapView(
        uploadFn: successUploadFn,
        pickFileFn: pickCancelled,
      ));

      await tester.tap(find.text('Choose file'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(EdenInlineErrorBanner), findsNothing);
    });

    testWidgets('7. Upload failure shows inline error banner with server message',
        (tester) async {
      await tester.pumpWidget(wrapView(
        uploadFn: failingUploadFn,
        pickFileFn: pickJpeg,
      ));

      await tester.tap(find.text('Choose file'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(EdenInlineErrorBanner), findsOneWidget);
      expect(find.textContaining('Upload failed'), findsOneWidget);
    });

    testWidgets('8. Cancel button closes via Navigator.pop', (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Navigator(
                onPopPage: (route, result) {
                  popped = true;
                  return route.didPop(result);
                },
                pages: [
                  MaterialPage(
                    child: Scaffold(
                      body: EdenMediaPickerView(
                        uploadFn: successUploadFn,
                        pickFileFn: pickCancelled,
                        onUrlSelected: (_) {},
                        allowedMimeTypes: const ['image/jpeg'],
                        maxUploadBytes: 10 * 1024 * 1024,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });
}
