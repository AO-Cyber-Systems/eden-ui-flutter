// The gate, not the JS object.
//
// `flutter test` runs on the VM, so `probe_bridge_web.dart` is unreachable
// here by construction — that is the point of the conditional import, and it
// is why these tests assert the GATE's behaviour (what a production build
// gets) rather than asserting `window.__edenProbe != null`, which would prove
// nothing about the rects a driver receives.
library;

import 'package:eden_ui_flutter/probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kEdenProbe is false when --dart-define=EDEN_PROBE is absent', () {
    // The default under `flutter test`, and the default of every production
    // build. A const false is what lets the tree shaker drop the bridge.
    expect(kEdenProbe, isFalse);
  });

  test('EdenProbe.install() without the define is a no-op that does not throw',
      () {
    EdenProbe.debugInstallCount = 0;

    EdenProbe.install();

    expect(
      EdenProbe.debugInstallCount,
      0,
      reason: 'install() must return before reaching the bridge when the '
          'define is absent; a non-zero count means the gate is gone and the '
          'bridge would ship in a production bundle',
    );
  });
}
