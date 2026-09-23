// Hand-built surfaces for the runtime-probe tests.
//
// WHY HAND-BUILT: every surface here exists to let ONE probe question be asked
// with a known right answer. Nothing is generated and nothing is shared with
// another test file, so when a probe assertion fails the surface it failed
// against is readable in full, on one screen, next to the assertion.
//
// Each surface below names, in its header, exactly what it lets the probe be
// asked.
library;

import 'package:flutter/material.dart';

/// A 120x40 keyed box sitting inside a deliberately WIDER 360x200 parent.
///
/// Lets the probe be asked: does `find({key:})` return the keyed element's OWN
/// render box, or an ancestor's? The two rects differ in every dimension here,
/// so a probe that walks up to the nearest container is caught (this is the
/// 23-01 40-vs-360 lesson, asked from the other side).
Widget probeKeyedBoxSurface() {
  return Center(
    child: SizedBox(
      key: const ValueKey<String>('probe-parent'),
      width: 360,
      height: 200,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          key: const ValueKey<String>('probe-target'),
          width: 120,
          height: 40,
          child: const ColoredBox(color: Color(0xFF2266CC)),
        ),
      ),
    ),
  );
}

/// A plain `Text('Hello')` AND the same word inside a `Text.rich` span.
///
/// Lets the probe be asked: does `find({text:})` match what a USER READS? A
/// `Text` widget's runtime tree is a `RichText`, and a probe that only reads
/// `Text.data` misses every styled/composed string in the app.
Widget probeTextSurface() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      const Text('Hello'),
      const Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: 'Say '),
            TextSpan(text: 'Hello', style: TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' now'),
          ],
        ),
      ),
      const Text('Goodbye'),
    ],
  );
}

/// Two identified semantics controls; the SECOND declares two tap routes.
///
/// Lets the probe be asked: does `tree()` make a double-declared tap visible
/// from OUTSIDE the app? `fx-probe-double-tap` wraps a second identified,
/// tappable node, so a correct `tree()` reports two overlapping nodes that both
/// advertise `tap` — the same double-fire shape the `expectUiSane` fixture
/// exercises from inside.
Widget probeSemanticsSurface() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      Semantics(
        identifier: 'eden-nav-home',
        container: true,
        label: 'Home',
        onTap: () {},
        child: const SizedBox(width: 100, height: 48),
      ),
      Semantics(
        identifier: 'fx-probe-double-tap',
        container: true,
        label: 'Outer tap route',
        onTap: () {},
        child: Semantics(
          identifier: 'fx-probe-double-tap-inner',
          container: true,
          label: 'Inner tap route',
          onTap: () {},
          child: const SizedBox(width: 80, height: 32),
        ),
      ),
    ],
  );
}

/// A surface whose opacity is driven by a caller-owned [AnimationController].
///
/// Lets the probe be asked: is `settled()` false while a frame is scheduled and
/// true once the animation stops? The controller is passed IN so the test owns
/// its lifecycle and can start/stop it explicitly rather than racing it.
class ProbeAnimatingSurface extends StatefulWidget {
  const ProbeAnimatingSurface({required this.controller, super.key});

  final AnimationController controller;

  @override
  State<ProbeAnimatingSurface> createState() => _ProbeAnimatingSurfaceState();
}

class _ProbeAnimatingSurfaceState extends State<ProbeAnimatingSurface> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: widget.controller,
        child: const SizedBox(
          key: ValueKey<String>('probe-fading'),
          width: 50,
          height: 50,
          child: ColoredBox(color: Color(0xFFCC2222)),
        ),
      ),
    );
  }
}
