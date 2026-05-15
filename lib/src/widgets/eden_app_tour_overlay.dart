import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/// A single step in an [EdenAppTourOverlay].
///
/// Callers provide one of these per target widget they want to highlight,
/// pre-creating the [key] in their own scope and attaching it to the
/// target widget tree (via a [Showcase] wrapper or by passing it through
/// the relevant widget).
@immutable
class EdenTourStep {
  /// Creates a tour step.
  const EdenTourStep({
    required this.key,
    required this.title,
    required this.description,
  });

  /// A [GlobalKey] attached to the target widget. The caller is
  /// responsible for using `Showcase(key: stepKey, ...)` (or equivalent)
  /// somewhere in the child tree.
  final GlobalKey key;

  /// Short heading shown in the spotlight tooltip.
  final String title;

  /// Tooltip body text.
  final String description;
}

/// A guided first-run app tour overlay.
///
/// Thin Eden-flavored wrapper around the `showcaseview` package's
/// `ShowCaseWidget`. The widget renders [child] unmodified when no tour
/// is active. Callers retrieve the [EdenAppTourOverlayState] via
/// `EdenAppTourOverlay.of(context)` and call `startTour()` to begin.
///
/// ```dart
/// EdenAppTourOverlay(
///   steps: [
///     EdenTourStep(key: inboxKey, title: 'Your inbox', description: '...'),
///     EdenTourStep(key: filtersKey, title: 'Filters', description: '...'),
///   ],
///   onComplete: () => myState.markTourDone(),
///   onSkip: () => myState.skipTour(),
///   child: const MyAppShell(),
/// )
/// ```
class EdenAppTourOverlay extends StatefulWidget {
  /// Creates an app-tour overlay.
  const EdenAppTourOverlay({
    super.key,
    required this.steps,
    required this.child,
    this.onComplete,
    this.onSkip,
    this.autoStart = false,
  });

  /// Ordered list of tour steps.
  final List<EdenTourStep> steps;

  /// The widget tree being toured. Caller is responsible for attaching
  /// each step's [GlobalKey] to a target inside this tree.
  final Widget child;

  /// Invoked when the user advances past the last step.
  final VoidCallback? onComplete;

  /// Invoked when the user dismisses the tour mid-flight.
  final VoidCallback? onSkip;

  /// When true, the tour starts automatically on first build.
  final bool autoStart;

  /// Looks up the nearest [EdenAppTourOverlayState] in the tree (so
  /// callers can `EdenAppTourOverlay.of(context)?.startTour()`).
  static EdenAppTourOverlayState? of(BuildContext context) =>
      context.findAncestorStateOfType<EdenAppTourOverlayState>();

  @override
  State<EdenAppTourOverlay> createState() => EdenAppTourOverlayState();
}

/// Public state object for [EdenAppTourOverlay].
class EdenAppTourOverlayState extends State<EdenAppTourOverlay> {
  bool _active = false;

  /// Captured descendant context inside [ShowCaseWidget] — populated each
  /// build so [startTour] can call [ShowCaseWidget.of] correctly.
  BuildContext? _innerContext;

  /// Whether a tour is currently active.
  bool get isActive => _active;

  /// Programmatically start the tour. Safe to call multiple times — calls
  /// while the tour is already running are no-ops.
  void startTour() {
    if (_active) return;
    setState(() => _active = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keys = widget.steps.map((s) => s.key).toList();
      if (keys.isEmpty) {
        _complete();
        return;
      }
      final innerCtx = _innerContext;
      if (innerCtx == null) return;
      ShowCaseWidget.of(innerCtx).startShowCase(keys);
    });
  }

  void _complete() {
    if (!_active) return;
    setState(() => _active = false);
    widget.onComplete?.call();
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) startTour();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      onFinish: _complete,
      builder: (innerContext) {
        // Capture the inner context for later `startTour()` calls.
        _innerContext = innerContext;
        return KeyedSubtree(
          key: const ValueKey<String>('eden_app_tour_child'),
          child: widget.child,
        );
      },
    );
  }
}

/// Convenience widget that wires an [EdenTourStep] target to the
/// underlying showcaseview `Showcase` widget. Use this in your tree to
/// annotate which widgets the tour steps target.
///
/// ```dart
/// EdenTourTarget(
///   step: myStep,
///   child: MyTargetWidget(),
/// )
/// ```
class EdenTourTarget extends StatelessWidget {
  /// Creates a tour-target wrapper.
  const EdenTourTarget({
    super.key,
    required this.step,
    required this.child,
  });

  /// The step whose [EdenTourStep.key] anchors this target.
  final EdenTourStep step;

  /// The widget being highlighted.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Showcase(
      key: step.key,
      title: step.title,
      description: step.description,
      child: child,
    );
  }
}
