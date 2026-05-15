import 'dart:typed_data';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_authenticated_image_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  const goodUrl = 'http://example.test/img/good.png';
  const badUrl = 'http://example.test/img/missing.png';

  setUp(() {
    EdenAuthenticatedImageFixtures.installFakeHttp(
      responseBytes: <String, Uint8List>{
        goodUrl: EdenAuthenticatedImageFixtures.tinyPngBytes,
      },
    );
  });

  tearDown(() {
    EdenAuthenticatedImageFixtures.uninstallFakeHttp();
  });

  group('EdenAuthenticatedImage', () {
    testWidgets('renders an Image.network with the given URL', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
          url: goodUrl,
          width: 64,
          height: 64,
        )));
        await tester.pump();
      });
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('passes provided headers to the underlying request',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
          url: goodUrl,
          headers: EdenAuthenticatedImageFixtures.bearerHeaders,
          width: 64,
          height: 64,
        )));
        // Let the image fetch run.
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(EdenAuthenticatedImageFixtures.capturedRequests, isNotEmpty);
      final captured = EdenAuthenticatedImageFixtures.capturedRequests.last;
      expect(captured.headers['Authorization'], 'Bearer test-token-123');
      expect(captured.headers['X-Tenant'], 'tenant-acme');
    });

    testWidgets('shows loading placeholder before image loads', (tester) async {
      await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
        url: goodUrl,
        placeholder: SizedBox(
          key: ValueKey('custom_placeholder'),
          width: 32,
          height: 32,
        ),
      )));
      // First frame — no Image resolved yet, placeholder visible.
      expect(find.byKey(const ValueKey('custom_placeholder')), findsOneWidget);
    });

    testWidgets('headersBuilder is awaited; image only resolves once resolved',
        (tester) async {
      final completer = Future<Map<String, String>?>.delayed(
        const Duration(milliseconds: 50),
        () => EdenAuthenticatedImageFixtures.bearerHeaders,
      );
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(EdenAuthenticatedImage(
          url: goodUrl,
          headersBuilder: () => completer,
          width: 64,
          height: 64,
        )));
        // Before headers resolve, no Image widget yet (placeholder shown).
        expect(find.byType(Image), findsNothing);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('headers={} (empty map) loads image without auth header',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
          url: goodUrl,
          headers: <String, String>{},
          width: 64,
          height: 64,
        )));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(EdenAuthenticatedImageFixtures.capturedRequests, isNotEmpty);
      expect(
          EdenAuthenticatedImageFixtures
              .capturedRequests.last.headers['Authorization'],
          isNull);
    });

    testWidgets('headersBuilder returns null → no headers passed',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(EdenAuthenticatedImage(
          url: goodUrl,
          headersBuilder: () async => null,
          width: 64,
          height: 64,
        )));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('custom errorWidget renders when headersBuilder throws',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuthenticatedImage(
        url: goodUrl,
        headersBuilder: () async => throw StateError('test header failure'),
        errorWidget: const SizedBox(
          key: ValueKey('custom_error'),
          width: 16,
          height: 16,
        ),
      )));
      // pump a few frames to let the future settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('custom_error')), findsOneWidget);
    });

    testWidgets('bad URL renders error placeholder', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
          url: badUrl,
          errorWidget: SizedBox(
            key: ValueKey('custom_error'),
            width: 16,
            height: 16,
          ),
          width: 64,
          height: 64,
        )));
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      expect(find.byKey(const ValueKey('custom_error')), findsOneWidget);
    });

    testWidgets('iPhone-narrow safe: image scales to BoxConstraints',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.runAsync(() async {
        await tester.pumpWidget(wrap(const SizedBox(
          width: 100,
          height: 100,
          child: EdenAuthenticatedImage(url: goodUrl),
        )));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
