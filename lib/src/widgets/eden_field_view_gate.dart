import 'package:flutter/widgets.dart';

import 'eden_app_mode.dart';

/// Inline gate that conditionally renders [child] based on the current
/// [EdenAppMode] from the surrounding [EdenAppModeScope].
///
/// Donor: trades-react `client/src/components/FieldViewGate.tsx`. The
/// donor is a full-page forbidden surface; this Flutter version is
/// more general — use [fallback] to recreate the donor's full-page
/// experience.
///
/// Two variants:
///   - [EdenFieldViewGate.companionOnly] — show [child] only when
///     `EdenAppModeScope.modeOf(context) == EdenAppMode.fieldCompanion`.
///   - [EdenFieldViewGate.adminOnly] — show [child] only when
///     `EdenAppModeScope.modeOf(context) == EdenAppMode.admin`.
///
/// When the current mode does not match the target, renders [fallback]
/// (defaults to `SizedBox.shrink()`) or invokes [builder] with the
/// actual current mode. [fallback] and [builder] are mutually exclusive
/// (debug-only assertion enforces).
///
/// **Rebuild semantics.** Reads the mode via
/// `EdenAppModeScope.maybeOf(context)`, which calls
/// `dependOnInheritedWidgetOfExactType` and therefore rebuilds
/// automatically on `EdenAppModeController.setMode`.
///
/// **`askUser` handling.** Neither variant matches
/// `EdenAppMode.askUser` — both render fallback in that case.
class EdenFieldViewGate extends StatelessWidget {
  const EdenFieldViewGate._({
    super.key,
    required this.targetMode,
    this.fallback,
    this.builder,
    required this.child,
  }) : assert(
          fallback == null || builder == null,
          'EdenFieldViewGate: pass fallback OR builder, not both.',
        );

  /// Renders [child] only when current mode is
  /// [EdenAppMode.fieldCompanion]. Otherwise renders [fallback] (or
  /// [builder]'s result, or `SizedBox.shrink()`).
  factory EdenFieldViewGate.companionOnly({
    Key? key,
    required Widget child,
    Widget? fallback,
    Widget Function(BuildContext, EdenAppMode)? builder,
  }) =>
      EdenFieldViewGate._(
        key: key,
        targetMode: EdenAppMode.fieldCompanion,
        fallback: fallback,
        builder: builder,
        child: child,
      );

  /// Renders [child] only when current mode is [EdenAppMode.admin].
  /// Otherwise renders [fallback] (or [builder]'s result, or
  /// `SizedBox.shrink()`).
  factory EdenFieldViewGate.adminOnly({
    Key? key,
    required Widget child,
    Widget? fallback,
    Widget Function(BuildContext, EdenAppMode)? builder,
  }) =>
      EdenFieldViewGate._(
        key: key,
        targetMode: EdenAppMode.admin,
        fallback: fallback,
        builder: builder,
        child: child,
      );

  final Widget child;
  final EdenAppMode targetMode;
  final Widget? fallback;
  final Widget Function(BuildContext, EdenAppMode)? builder;

  @override
  Widget build(BuildContext context) {
    final controller = EdenAppModeScope.maybeOf(context);
    assert(
      controller != null,
      'EdenFieldViewGate requires an EdenAppModeScope ancestor. '
      'Wrap your subtree in EdenAppModeScope(controller: ...).',
    );
    final current = controller!.currentMode;
    if (current == targetMode) return child;
    if (builder != null) return builder!(context, current);
    return fallback ?? const SizedBox.shrink();
  }
}
