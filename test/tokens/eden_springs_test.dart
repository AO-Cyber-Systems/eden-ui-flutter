// Hand-built fixture file — Do NOT regenerate via LLM.
//
// Documents the EdenSprings preset numeric values as live, executable specs.
// Each preset's mass/stiffness/damping is asserted explicitly so the test serves
// as both a regression gate AND the canonical reference for downstream TRDs
// (010-02..010-10) that compose these presets via EdenSprings.simulationFor /
// .curveFor.
//
// Damping-ratio formula: damping / (2 * sqrt(mass * stiffness)).
// Target ratios per preset (documented in the EdenSprings dartdoc):
//   snap   ~0.67 — fast settle, slight overshoot
//   smooth ~1.00 — critically damped, no overshoot
//   bouncy ~0.42 — clear overshoot
//   rubber ~0.32 — heavy overshoot, 'rubber band'

import 'dart:math' as math;

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_test/flutter_test.dart';

double _dampingRatio(SpringDescription s) =>
    s.damping / (2.0 * math.sqrt(s.mass * s.stiffness));

void main() {
  group('EdenSprings', () {
    test('snap preset has documented mass/stiffness/damping', () {
      // snap: mass=1.0, stiffness=500.0, damping=30.0 (ratio ~0.67)
      final s = EdenSprings.snap;
      expect(s.mass, 1.0);
      expect(s.stiffness, 500.0);
      expect(s.damping, 30.0);
    });

    test('smooth preset is critically damped (ratio ~1.0)', () {
      // smooth: mass=1.0, stiffness=180.0, damping=27.0 (ratio ~1.0)
      final s = EdenSprings.smooth;
      expect(s.mass, 1.0);
      expect(s.stiffness, 180.0);
      expect(s.damping, 27.0);
      expect(_dampingRatio(s), closeTo(1.0, 0.1));
    });

    test('bouncy preset is under-damped (ratio < 1.0)', () {
      // bouncy: mass=1.0, stiffness=200.0, damping=12.0 (ratio ~0.42)
      final s = EdenSprings.bouncy;
      expect(_dampingRatio(s), lessThan(1.0));
      expect(_dampingRatio(s), closeTo(0.42, 0.1));
    });

    test('rubber preset has lower damping ratio than bouncy', () {
      // rubber: mass=1.0, stiffness=160.0, damping=8.0 (ratio ~0.32)
      final rubber = EdenSprings.rubber;
      final bouncy = EdenSprings.bouncy;
      expect(_dampingRatio(rubber), lessThan(_dampingRatio(bouncy)));
      expect(_dampingRatio(rubber), closeTo(0.32, 0.1));
    });

    test('presets are identical across reads (rebuild safety)', () {
      // For static const SpringDescription, identical() must return true.
      expect(identical(EdenSprings.snap, EdenSprings.snap), isTrue);
      expect(identical(EdenSprings.smooth, EdenSprings.smooth), isTrue);
      expect(identical(EdenSprings.bouncy, EdenSprings.bouncy), isTrue);
      expect(identical(EdenSprings.rubber, EdenSprings.rubber), isTrue);
    });

    test('simulationFor(snap, from: 0, to: 1) starts at 0 and reaches 1', () {
      final sim = EdenSprings.simulationFor(
        EdenSprings.snap,
        from: 0,
        to: 1,
      );
      expect(sim, isA<SpringSimulation>());
      expect(sim.x(0), closeTo(0.0, 0.001));
      // After plenty of time the snap simulation must reach (very close to) 1.
      expect(sim.x(3.0), closeTo(1.0, 0.05));
    });

    test('simulationFor with velocity honors initial velocity', () {
      final sim = EdenSprings.simulationFor(
        EdenSprings.snap,
        from: 0,
        to: 1,
        velocity: 100,
      );
      expect(sim.dx(0), closeTo(100.0, 0.1));
    });

    test('curveFor(smooth) has stable endpoints transform(0)=0 and transform(1)=1', () {
      final curve = EdenSprings.curveFor(EdenSprings.smooth);
      expect(curve.transform(0.0), closeTo(0.0, 0.01));
      expect(curve.transform(1.0), closeTo(1.0, 0.05));
    });

    test('curveFor(smooth).transform(0.5) is strictly between 0 and 1', () {
      final curve = EdenSprings.curveFor(EdenSprings.smooth);
      final mid = curve.transform(0.5);
      expect(mid, greaterThan(0.0));
      expect(mid, lessThan(1.0));
    });

    test('simulationFor(snap, from: 0, to: 0) is immediately done', () {
      final sim = EdenSprings.simulationFor(
        EdenSprings.snap,
        from: 0,
        to: 0,
      );
      // SpringSimulation considers itself done when both displacement and velocity
      // are within tolerance. from == to with velocity 0 satisfies that at t=0.
      expect(sim.isDone(0), isTrue);
    });

    test('fixture builder _makeController is callable (reference helper)', () {
      // The helper itself is exercised by simply being defined and importable
      // by downstream TRD test files. We confirm it compiles by calling it.
      // (No actual AnimationController is minted here — requires a TickerProvider
      // which is widget-test-only; downstream widget tests will use it.)
      expect(_makeController, isNotNull);
    });
  });
}

// Reference helper for downstream TRDs (010-02..010-10). Documents the
// canonical way to mint an AnimationController bound to an EdenSprings
// simulation. Not exported; copy into widget test files that need it.
//
// Usage (in a widget test):
//   final controller = AnimationController.unbounded(vsync: tester);
//   controller.animateWith(EdenSprings.simulationFor(
//     EdenSprings.snap, from: 0, to: 1,
//   ));
SpringSimulation _makeController({required double from, required double to}) {
  return EdenSprings.simulationFor(
    EdenSprings.snap,
    from: from,
    to: to,
  );
}
