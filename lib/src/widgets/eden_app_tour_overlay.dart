import 'package:flutter/material.dart';

/// A single step in an [EdenAppTourOverlay].
@immutable
class EdenTourStep {
  const EdenTourStep({
    required this.key,
    required this.title,
    required this.description,
  });

  final GlobalKey key;
  final String title;
  final String description;
}

/// RED-phase stub for EdenAppTourOverlay.
class EdenAppTourOverlay extends StatefulWidget {
  const EdenAppTourOverlay({
    super.key,
    required this.steps,
    required this.child,
    this.onComplete,
    this.onSkip,
    this.autoStart = false,
  });

  final List<EdenTourStep> steps;
  final Widget child;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final bool autoStart;

  static EdenAppTourOverlayState? of(BuildContext context) =>
      context.findAncestorStateOfType<EdenAppTourOverlayState>();

  @override
  State<EdenAppTourOverlay> createState() => EdenAppTourOverlayState();
}

class EdenAppTourOverlayState extends State<EdenAppTourOverlay> {
  bool _active = false;
  bool get isActive => _active;
  void startTour() {
    if (_active) return;
    setState(() => _active = true);
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

/// RED-phase stub for EdenTourTarget.
class EdenTourTarget extends StatelessWidget {
  const EdenTourTarget({
    super.key,
    required this.step,
    required this.child,
  });

  final EdenTourStep step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
