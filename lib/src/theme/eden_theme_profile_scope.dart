import 'package:flutter/widgets.dart';
import 'eden_theme_profile.dart';

/// InheritedWidget exposing the active [EdenThemeProfile] to descendants.
///
/// Typically installed by [EdenAdaptiveTheme] (objective 009 TRD 05) at the
/// top of the widget tree. Widgets read the active profile via
/// [EdenThemeProfileScope.of] (debug-asserts on missing scope) or
/// [maybeOf] (returns null on missing scope).
///
/// Per OBJECTIVE.md Constraint 7: profile selection is a global per-tenant
/// concern. There is no page-level override API — widgets adapt automatically
/// via their resolved theme tokens. This scope exists for theme-construction
/// helpers that need to read the profile without re-receiving it as a prop.
class EdenThemeProfileScope extends InheritedWidget {
  const EdenThemeProfileScope({
    super.key,
    required this.profile,
    required super.child,
  });

  final EdenThemeProfile profile;

  /// Returns the profile from the nearest ancestor [EdenThemeProfileScope].
  ///
  /// Asserts in debug if no scope is present. Defaults to
  /// [EdenThemeProfile.commercialWarm] in release builds (back-compat — apps
  /// not yet wrapped in [EdenAdaptiveTheme] continue to render commercial).
  static EdenThemeProfile of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<EdenThemeProfileScope>();
    assert(
      scope != null,
      'EdenThemeProfileScope.of() called without an EdenThemeProfileScope '
      'ancestor. Wrap your app in EdenAdaptiveTheme (objective 009) or use '
      'EdenThemeProfileScope.maybeOf if a missing scope is acceptable.',
    );
    return scope?.profile ?? EdenThemeProfile.commercialWarm;
  }

  /// Returns the profile from the nearest ancestor scope, or null if none.
  static EdenThemeProfile? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<EdenThemeProfileScope>()
        ?.profile;
  }

  @override
  bool updateShouldNotify(EdenThemeProfileScope oldWidget) {
    return profile != oldWidget.profile;
  }
}
