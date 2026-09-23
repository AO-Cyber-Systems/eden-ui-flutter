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
  });
}
