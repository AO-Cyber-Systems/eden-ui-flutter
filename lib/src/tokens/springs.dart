import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

/// Eden UI spring-physics motion tokens — M3 Expressive-aligned.
///
/// Pairs with [Duration]-based easing in `lib/src/tokens/durations.dart`.
/// Use [EdenSprings] when motion should feel physics-driven (button press,
/// FAB unfurl, card lift, drag release). Use `EdenDurations.easeOutExpo` for
/// legacy / non-motion transitions (color fade, theme switch).
///
/// All 4 presets are tunable via [SpringDescription] mass/stiffness/damping.
/// Damping ratios (damping / (2 * sqrt(mass * stiffness))):
///   snap   = ~0.67  (fast settle, slight overshoot)
///   smooth = ~1.00  (critically damped, no overshoot)
///   bouncy = ~0.42  (visible overshoot)
///   rubber = ~0.32  (heavy overshoot, 'rubber band')
///
/// Two helpers ship alongside the presets:
///
/// * [simulationFor] returns a [SpringSimulation] for use with
///   `AnimationController.animateWith(...)`.
/// * [curveFor] returns a [Curve] adapter that drives the spring simulation
///   inside a normalized `[0, 1]` time range so callers using
///   `Tween + CurvedAnimation` get a spring-shaped curve.
///
/// No new pubspec dependencies — only `package:flutter/physics.dart` and
/// `package:flutter/animation.dart`.
class EdenSprings {
  EdenSprings._();

  /// Snap — fast settle, slight overshoot. Use for button press / segmented
  /// shape morph / quick toggle release.
  ///
  /// Usage:
  /// ```dart
  /// final controller = AnimationController.unbounded(vsync: this);
  /// controller.animateWith(EdenSprings.simulationFor(
  ///   EdenSprings.snap, from: 0, to: 1,
  /// ));
  /// ```
  static const SpringDescription snap = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 30.0,
  );

  /// Smooth — critically damped, no overshoot. Use for skeleton-to-content
  /// cross-fades, card hover lift, gentle reveals.
  ///
  /// Usage:
  /// ```dart
  /// AnimatedCrossFade(
  ///   firstCurve: EdenSprings.curveFor(EdenSprings.smooth),
  ///   secondCurve: EdenSprings.curveFor(EdenSprings.smooth),
  ///   // ...
  /// );
  /// ```
  static const SpringDescription smooth = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 27.0,
  );

  /// Bouncy — visible overshoot. Use for FAB-menu unfurl, playful entrances,
  /// success-state morphs.
  ///
  /// Usage:
  /// ```dart
  /// controller.animateWith(EdenSprings.simulationFor(
  ///   EdenSprings.bouncy, from: 0, to: 1,
  /// ));
  /// ```
  static const SpringDescription bouncy = SpringDescription(
    mass: 1.0,
    stiffness: 200.0,
    damping: 12.0,
  );

  /// Rubber — heavy overshoot ('rubber band'). Use sparingly: drag-release
  /// fling, error shake (paired with [Tween]), pull-to-refresh release.
  ///
  /// Usage:
  /// ```dart
  /// controller.animateWith(EdenSprings.simulationFor(
  ///   EdenSprings.rubber, from: dragOffset, to: 0, velocity: flingVelocity,
  /// ));
  /// ```
  static const SpringDescription rubber = SpringDescription(
    mass: 1.0,
    stiffness: 160.0,
    damping: 8.0,
  );

  /// Returns a [SpringSimulation] driving the [preset] from [from] to [to],
  /// optionally with an initial [velocity]. Pair with
  /// `AnimationController.animateWith(...)`.
  static SpringSimulation simulationFor(
    SpringDescription preset, {
    required double from,
    required double to,
    double velocity = 0.0,
  }) {
    return SpringSimulation(preset, from, to, velocity);
  }

  /// Returns a [Curve] adapter for the given spring [preset]. The curve
  /// samples a normalized 0→1 spring simulation; useful when a caller needs
  /// the spring shape inside `CurvedAnimation` / `Tween` rather than driving
  /// an `AnimationController` directly.
  ///
  /// Under-damped presets ([bouncy] / [rubber]) overshoot the [0, 1] range
  /// naturally; this adapter clamps the output to keep [CurvedAnimation]
  /// callers safe. Callers that want raw physics (including overshoot) should
  /// use [simulationFor] with `AnimationController.animateWith`.
  static Curve curveFor(SpringDescription preset) => _SpringCurve(preset);
}

class _SpringCurve extends Curve {
  _SpringCurve(this._preset)
      : _sim = SpringSimulation(_preset, 0.0, 1.0, 0.0);

  // ignore: unused_field
  final SpringDescription _preset;
  final SpringSimulation _sim;

  // Practical natural settle for stiffness 160-500 is ~3.0s; mapping the
  // input t in [0, 1] to a 3.0s window lets the curve cover the full
  // simulation arc inside a normal Tween call.
  static const double _naturalTimeWindowSeconds = 3.0;

  @override
  double transform(double t) {
    final value = _sim.x(t * _naturalTimeWindowSeconds);
    if (!value.isFinite) return 1.0;
    return value.clamp(0.0, 1.0);
  }
}
