// EdenProbeApi — the Dart entry the JS shim calls, tested over hand-built
// surfaces. A test that asserted `window.__edenProbe != null` would prove
// nothing about the rects the driver receives; these assert the rects.
library;

import 'package:eden_ui_flutter/src/probe/probe_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/probe_surfaces.dart';

Future<void> _pumpSurface(WidgetTester tester, Widget surface) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: surface)));
}

void main() {
  group('EdenProbeApi.find', () {
    testWidgets(
      'find({key:}) returns the keyed element OWN render-box rect, not the parent\'s',
      (WidgetTester tester) async {
        await _pumpSurface(tester, probeKeyedBoxSurface());

        final List<EdenProbeHit> hits =
            EdenProbeApi.find(key: 'probe-target');

        expect(hits, hasLength(1));

        final Rect expected =
            tester.getRect(find.byKey(const ValueKey<String>('probe-target')));
        expect(hits.single.rect, expected);
        expect(hits.single.rect.size, const Size(120, 40));

        // The differential that makes this a geometry test: the parent is
        // 360x200 and a probe that walked up to it would still "find
        // something".
        final Rect parent =
            tester.getRect(find.byKey(const ValueKey<String>('probe-parent')));
        expect(hits.single.rect, isNot(parent));
      },
    );

    testWidgets('find({text:}) matches a Text(\'Hello\')',
        (WidgetTester tester) async {
      await _pumpSurface(tester, probeTextSurface());

      final List<EdenProbeHit> hits = EdenProbeApi.find(text: 'Hello');

      expect(hits, isNotEmpty);
      final Rect expected = tester.getRect(find.text('Hello'));
      expect(
        hits.map((EdenProbeHit h) => h.rect),
        contains(expected),
      );
      // 'Goodbye' is on the same surface and must not be swept in.
      final Rect goodbye = tester.getRect(find.text('Goodbye'));
      expect(hits.map((EdenProbeHit h) => h.rect), isNot(contains(goodbye)));
    });

    testWidgets('find({text:}) also matches the same string inside a Text.rich span',
        (WidgetTester tester) async {
      await _pumpSurface(tester, probeTextSurface());

      final List<EdenProbeHit> hits = EdenProbeApi.find(text: 'Hello');

      // A Text widget's runtime tree IS a RichText, so a probe reading only
      // Text.data misses every composed string a user reads.
      final Rect rich = tester.getRect(
        find.byWidgetPredicate(
          (Widget w) => w is Text && w.data == null && w.textSpan != null,
        ),
      );
      expect(hits.map((EdenProbeHit h) => h.rect), contains(rich));
    });

    testWidgets('find({identifier:}) matches a semantics identifier and returns that node\'s rect',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSurface(tester, probeSemanticsSurface());

      final List<EdenProbeHit> hits =
          EdenProbeApi.find(identifier: 'eden-nav-home');

      expect(hits, hasLength(1));
      expect(hits.single.identifier, 'eden-nav-home');
      expect(hits.single.rect.size, const Size(100, 48));
      expect(hits.single.actions, contains('tap'));
      handle.dispose();
    });

    testWidgets('find({}) with no criteria returns [] and does not throw',
        (WidgetTester tester) async {
      await _pumpSurface(tester, probeKeyedBoxSurface());

      expect(EdenProbeApi.find(), isEmpty);
    });
  });
}
