// The widget a consumer's `main_e2e.dart` wraps its app in so that, under
// `--dart-define=EDEN_PROBE=true`, a capture taken right after an
// interaction is of a SETTLED surface rather than a half-played transition.
//
// WHY NOT `timeDilation`: `timeDilation` (package:flutter/scheduler.dart) is
// a scheduler-clock knob with no effect on the web renderer's compositing --
// it does nothing for a real browser capture. The mechanism here is
// `disableAnimations`.
//
// WHY TWO FLAGS: `MediaQueryData.disableAnimations` is advisory -- only some
// widgets (e.g. `Image`) consult it directly. The FAB's own entrance/exit
// animation and `MaterialPageRoute`'s push transition instead go through
// `AnimationController`, which consults
// `SemanticsBinding.instance.disableAnimations` and, when true, runs an
// `AnimationBehavior.normal` controller at 5% of its declared duration --
// effectively one frame (see `_animateTo` in
// package:flutter/src/animation/animation_controller.dart). Setting only
// the `MediaQuery` flag would leave both of those controllers running at
// full duration.
//
// MECHANISM CAVEAT, recorded for whoever wires this into a release probe
// build (W1c's main_e2e.dart): `SemanticsBinding.instance.disableAnimations`
// has NO non-debug setter on this Flutter generation (checked at the local
// 3.41.9 floor and against the 3.27.0 declared minimum's binding.dart shape)
// -- it is a read-only getter with an assert-gated debug override,
// `debugSemanticsDisableAnimations`, and asserts are stripped from
// `flutter build --release`. This scope sets that debug override, so it
// genuinely settles `flutter test` and `flutter run --debug` captures --
// which is what this TRD's test list and the story/pattern harness run
// under. A REAL `flutter build web --release --dart-define=EDEN_PROBE=true`
// capture will only see `disableAnimations` as true if the browser/OS
// itself is requesting reduced motion; this scope cannot force that in a
// release build. Reported as a finding in 23-08's SUMMARY.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'probe_bridge.dart';

/// Builds the scope's subtree. Extracted from [EdenProbeScope.build] so a
/// test can drive [enabled] directly: [kEdenProbe] is a compile-time const,
/// so a test cannot flip IT at runtime. Case 3 (inert without the define)
/// asserts the widget calls this with [kEdenProbe], not a hardcoded `true`
/// -- do not "simplify" the split away.
@visibleForTesting
Widget buildProbeScope(
  BuildContext context,
  Widget child, {
  required bool enabled,
}) {
  if (!enabled) {
    return child;
  }
  // See the MECHANISM CAVEAT above: this is the only override this Flutter
  // generation exposes, and it is assert-gated (debug-only) by the
  // framework itself, not by this line.
  assert(() {
    debugSemanticsDisableAnimations = true;
    return true;
  }());
  return MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  );
}

/// Wraps an app so that, under the [kEdenProbe] define, an animated removal
/// or route transition settles within one frame instead of possibly being
/// caught mid-flight.
///
/// Inert -- renders [child] unchanged and touches neither
/// [MediaQuery.disableAnimations] nor `SemanticsBinding` -- when the define
/// is absent, so it is safe to leave wired into a production app shell.
class EdenProbeScope extends StatelessWidget {
  const EdenProbeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      buildProbeScope(context, child, enabled: kEdenProbe);
}
