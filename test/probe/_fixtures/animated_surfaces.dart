// Hand-built surfaces for EdenProbeScope's settle-knob tests.
//
// Each surface exists to let ONE animation-settling question be asked with a
// known right answer: an EXIT animation (FAB removal) and an ENTRANCE
// animation (route push) -- the two shapes a probe capture actually meets.
// Nothing here is generated and nothing is shared with another test file.
library;

import 'package:flutter/material.dart';

/// Key of the [FloatingActionButton] rendered while the surface's FAB is
/// showing.
const Key fabRemovalFabKey = ValueKey<String>('probe-fab');

/// A [Scaffold] whose `floatingActionButton` becomes `null` on a `setState`.
///
/// Lets EdenProbeScope be asked: does a single frame after removal actually
/// complete the FAB's built-in exit animation, or leave it mid-flight (the
/// `scaffold-fab-exit-animation-widget-test` trap this TRD inverts)?
class FabRemovalSurface extends StatefulWidget {
  const FabRemovalSurface({super.key});

  @override
  State<FabRemovalSurface> createState() => FabRemovalSurfaceState();
}

class FabRemovalSurfaceState extends State<FabRemovalSurface> {
  bool _showFab = true;

  /// Removes the FAB, starting its built-in exit animation.
  void removeFab() => setState(() => _showFab = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showFab
          ? FloatingActionButton(
              key: fabRemovalFabKey,
              onPressed: () {},
              child: const Icon(Icons.add),
            )
          : null,
      body: const SizedBox.shrink(),
    );
  }
}

/// Key of the button that pushes the route.
const Key pushedRouteButtonKey = ValueKey<String>('probe-push-button');

/// Key of the pushed page's marker [Text] -- present in the tree as soon as
/// the page is built, mid-transition or not.
const Key pushedRouteMarkerKey = ValueKey<String>('probe-pushed-page');

/// A button that pushes a [MaterialPageRoute] onto the enclosing [Navigator].
///
/// Lets EdenProbeScope be asked: does a single frame after the push actually
/// complete the route's entrance transition, or leave it mid-flight?
class PushedRouteSurface extends StatelessWidget {
  const PushedRouteSurface({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: pushedRouteButtonKey,
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text('pushed', key: pushedRouteMarkerKey),
                ),
              ),
            ),
          ),
          child: const Text('push'),
        ),
      ),
    );
  }
}
