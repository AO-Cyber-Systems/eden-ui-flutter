import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_authenticated_image_fixtures.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  const goodUrl = 'http://example.test/img/good.png';

  group('EdenAuthenticatedImage', () {
    testWidgets('renders an Image.network with the given URL', (tester) async {
      await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
        url: goodUrl,
        width: 64,
        height: 64,
      )));
      await tester.pump();
      // Headers resolve synchronously when no headersBuilder is given.
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.url, goodUrl);
    });

    testWidgets('passes static headers map through to NetworkImage',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
        url: goodUrl,
        headers: EdenAuthenticatedImageFixtures.bearerHeaders,
        width: 64,
        height: 64,
      )));
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.headers?['Authorization'], 'Bearer test-token-123');
      expect(provider.headers?['X-Tenant'], 'tenant-acme');
    });

    testWidgets('headers={} (empty map) → no headers on NetworkImage',
        (tester) async {
      await tester.pumpWidget(wrap(const EdenAuthenticatedImage(
        url: goodUrl,
        headers: <String, String>{},
        width: 64,
        height: 64,
      )));
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.headers, isNull);
    });

    testWidgets('custom placeholder shows before headersBuilder resolves',
        (tester) async {
      final never = Completer<Map<String, String>?>();
      addTearDown(() {
        if (!never.isCompleted) never.complete(null);
      });
      await tester.pumpWidget(wrap(EdenAuthenticatedImage(
        url: goodUrl,
        headersBuilder: () => never.future,
        placeholder: const SizedBox(
          key: ValueKey('custom_placeholder'),
          width: 32,
          height: 32,
        ),
      )));
      expect(find.byKey(const ValueKey('custom_placeholder')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('headersBuilder is awaited; Image renders after resolution',
        (tester) async {
      final completer = Completer<Map<String, String>?>();
      await tester.pumpWidget(wrap(EdenAuthenticatedImage(
        url: goodUrl,
        headersBuilder: () => completer.future,
        width: 64,
        height: 64,
      )));
      await tester.pump();
      // Pending — Image not yet rendered.
      expect(find.byType(Image), findsNothing);

      completer.complete(EdenAuthenticatedImageFixtures.bearerHeaders);
      await tester.pump();
      await tester.pump();
      // Image rendered with resolved headers.
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.headers?['Authorization'], 'Bearer test-token-123');
    });

    testWidgets('headersBuilder returns null → NetworkImage with null headers',
        (tester) async {
      await tester.pumpWidget(wrap(EdenAuthenticatedImage(
        url: goodUrl,
        headersBuilder: () async => null,
        width: 64,
        height: 64,
      )));
      await tester.pump();
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as NetworkImage;
      expect(provider.headers, isNull);
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const ValueKey('custom_error')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('default placeholder is EdenSpinner when no headers yet',
        (tester) async {
      final never = Completer<Map<String, String>?>();
      addTearDown(() {
        if (!never.isCompleted) never.complete(null);
      });
      await tester.pumpWidget(wrap(EdenAuthenticatedImage(
        url: goodUrl,
        headersBuilder: () => never.future,
      )));
      expect(find.byType(EdenSpinner), findsOneWidget);
    });

    testWidgets('iPhone-narrow safe: respects parent BoxConstraints',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(const SizedBox(
        width: 100,
        height: 100,
        child: EdenAuthenticatedImage(url: goodUrl),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // Fixture sanity check.
  test('fixture bearerHeaders has Authorization + X-Tenant', () {
    expect(EdenAuthenticatedImageFixtures.bearerHeaders['Authorization'],
        isNotNull);
    expect(
        EdenAuthenticatedImageFixtures.bearerHeaders['X-Tenant'], isNotNull);
    expect(EdenAuthenticatedImageFixtures.tinyPngBytes.length, greaterThan(60));
  });
}
