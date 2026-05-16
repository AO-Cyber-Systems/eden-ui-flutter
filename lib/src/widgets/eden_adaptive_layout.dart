import 'package:flutter/widgets.dart';

import 'eden_app_mode.dart' show kEdenAppModeCompactMax, kEdenAppModeExpandedMin;

/// Material 3 responsive tier classification per
/// `.planning/COMPANION_UX_PATTERNS_2026-05-15.md` §0 lock E:
///   - Compact: `<600pt`
///   - Medium: `600–840pt`
///   - Expanded: `≥840pt`
enum EdenAdaptiveTier { compact, medium, expanded }

/// `InheritedWidget` exposing the resolved [EdenAdaptiveTier] to the
/// chosen builder's subtree. Consumers call [EdenAdaptiveTierScope.of]
/// (or [EdenAdaptiveTierScope.maybeOf]) to know which tier was picked.
class EdenAdaptiveTierScope extends InheritedWidget {
  const EdenAdaptiveTierScope({
    super.key,
    required this.tier,
    required super.child,
  });

  final EdenAdaptiveTier tier;

  /// Asserts if no scope is in the tree.
  static EdenAdaptiveTier of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<EdenAdaptiveTierScope>();
    assert(
      scope != null,
      'EdenAdaptiveTierScope.of() called with no EdenAdaptiveLayout in the tree.',
    );
    return scope!.tier;
  }

  /// Returns null if no scope is in the tree.
  static EdenAdaptiveTier? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<EdenAdaptiveTierScope>()
        ?.tier;
  }

  @override
  bool updateShouldNotify(EdenAdaptiveTierScope oldWidget) =>
      tier != oldWidget.tier;
}

/// Material 3 three-tier adaptive scaffold.
///
/// Picks one of [compactBuilder] / [mediumBuilder] / [expandedBuilder]
/// based on the parent's `LayoutBuilder.constraints.maxWidth` (logical
/// pt — NOT raw pixel; per lock E rule 1). Falls back to
/// `MediaQuery.of(context).size.width` only when `constraints.maxWidth`
/// is `double.infinity` (unbounded parent).
///
/// Pass `forceCompact: true` to bypass tier selection and always render
/// [compactBuilder]. This is the hook `EdenCompanionShell` (TRD-05) uses
/// to honor lock E rule 3: "Companion mode pins to Compact at ALL
/// widths."
///
/// Fallback chain when a higher-tier builder is null:
///   - Expanded → expandedBuilder → mediumBuilder → compactBuilder
///   - Medium → mediumBuilder → compactBuilder
///   - Compact → compactBuilder (always required)
///
/// The picked subtree is wrapped in [EdenAdaptiveTierScope] so widgets
/// inside can introspect the resolved tier via
/// `EdenAdaptiveTierScope.of(context)`.
class EdenAdaptiveLayout extends StatelessWidget {
  const EdenAdaptiveLayout({
    super.key,
    required this.compactBuilder,
    this.mediumBuilder,
    this.expandedBuilder,
    this.forceCompact = false,
  });

  final WidgetBuilder compactBuilder;
  final WidgetBuilder? mediumBuilder;
  final WidgetBuilder? expandedBuilder;
  final bool forceCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final tier =
            forceCompact ? EdenAdaptiveTier.compact : _tierFor(width);
        final builder = _builderFor(tier);
        return EdenAdaptiveTierScope(
          tier: tier,
          child: Builder(builder: builder),
        );
      },
    );
  }

  EdenAdaptiveTier _tierFor(double width) {
    if (width < kEdenAppModeCompactMax) return EdenAdaptiveTier.compact;
    if (width < kEdenAppModeExpandedMin) return EdenAdaptiveTier.medium;
    return EdenAdaptiveTier.expanded;
  }

  WidgetBuilder _builderFor(EdenAdaptiveTier tier) {
    switch (tier) {
      case EdenAdaptiveTier.expanded:
        return expandedBuilder ?? mediumBuilder ?? compactBuilder;
      case EdenAdaptiveTier.medium:
        return mediumBuilder ?? compactBuilder;
      case EdenAdaptiveTier.compact:
        return compactBuilder;
    }
  }
}
