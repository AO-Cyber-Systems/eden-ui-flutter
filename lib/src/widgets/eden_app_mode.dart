import 'package:flutter/widgets.dart';

/// App-mode discrimination per the locked Companion UX research
/// (2026-05-15 decisions A + E in
/// `.planning/COMPANION_UX_PATTERNS_2026-05-15.md`).
///
/// Three states (mirrors trades-react `UXModeToggle.tsx` donor — desktop /
/// mobile / auto, renamed for Eden vocabulary):
///   - [admin] — full desktop chrome (top-bar, side-rail nav).
///   - [fieldCompanion] — narrow mobile chrome (bottom-nav, single column).
///   - [askUser] — ambiguous; consumers may prompt a first-launch picker
///     OR fall back to the most recent toggle value.
///
/// Library is transport-agnostic: this file does NOT import
/// `shared_preferences`, `flutter_riverpod`, or any JWT decoder. The
/// persistence + claim decode + dart-define resolution ARE THE CONSUMER'S
/// JOB — they pass already-resolved values into [resolveAppMode].
enum EdenAppMode { admin, fieldCompanion, askUser }

/// Material 3 Compact tier upper bound (exclusive). Below this logical-pt
/// width, the user is on a phone-class device and field-companion is the
/// default. Locked at COMPANION_UX_PATTERNS_2026-05-15.md §0 lock E.
///
/// NOTE: differs intentionally from `EdenResponsive.mobileMax` (768pt) at
/// `lib/src/utils/responsive.dart`. `EdenResponsive` is the legacy
/// admin-shell breakpoint; this constant + [kEdenAppModeExpandedMin] are
/// the Material 3 tier set for the new companion / adaptive surfaces.
/// Both coexist; do NOT unify.
const double kEdenAppModeCompactMax = 600.0;

/// Material 3 Expanded tier lower bound (inclusive). At or above this
/// logical-pt width, the user is on a tablet-landscape-or-larger and
/// admin is the default. Locked at COMPANION_UX_PATTERNS_2026-05-15.md §0
/// lock E.
const double kEdenAppModeExpandedMin = 840.0;

/// Pure resolver — input → output, no I/O, no state.
///
/// Resolution order (highest precedence first; per COMPANION_B2_SPEC §1
/// transliterated to Dart with lock-E breakpoints):
/// 1. [dartDefineBuildMode] — App-store-pinned build (e.g.,
///    `flutter build --dart-define=APP_BUILD=field-companion`).
/// 2. [claimAppMode] — JWT `app_mode` claim from FedRAMP-restricted
///    backend (Wave C; mechanism in place for v1).
/// 3. [persistedAppMode] — the user's previous toggle / first-launch
///    picker choice (e.g., a SharedPreferences string the consumer
///    reads at app boot). Invalid strings silently fall through.
/// 4. Viewport-driven default — Material 3 tier rules from lock E:
///    `<600pt` → fieldCompanion, `≥840pt` → admin, `600–840pt` →
///    askUser (ambiguous Medium tier).
///
/// [viewport] should be in logical pt (e.g., `MediaQuery.of(context).size`
/// or `LayoutBuilder.constraints.biggest`).
EdenAppMode resolveAppMode({
  required Size viewport,
  String? persistedAppMode,
  EdenAppMode? claimAppMode,
  EdenAppMode? dartDefineBuildMode,
}) {
  // 1. dart-define hard pin.
  if (dartDefineBuildMode != null) return dartDefineBuildMode;

  // 2. JWT claim hard pin.
  if (claimAppMode != null) return claimAppMode;

  // 3. Persisted user choice — silently ignore garbage values.
  if (persistedAppMode != null) {
    for (final mode in EdenAppMode.values) {
      if (mode.name == persistedAppMode) return mode;
    }
  }

  // 4. Viewport-driven default (Material 3 tiers per lock E).
  if (viewport.width < kEdenAppModeCompactMax) return EdenAppMode.fieldCompanion;
  if (viewport.width >= kEdenAppModeExpandedMin) return EdenAppMode.admin;

  // 5. Ambiguous Medium tier.
  return EdenAppMode.askUser;
}

/// ChangeNotifier wrapping the current resolved [EdenAppMode].
///
/// The consumer constructs one per app and passes it to
/// [EdenAppModeScope]. Persistence is the consumer's job — wire the
/// [onChange] callback to SharedPreferences (or any I/O) and read the
/// persisted value back on next app boot to pass into [resolveAppMode]
/// via `persistedAppMode`.
///
/// Mirrors a Riverpod `StateNotifier<EdenAppMode>` shape without
/// depending on `flutter_riverpod`. Callers using Riverpod can wrap
/// with `ChangeNotifierProvider`. Mirrors the precedent in
/// `lib/src/widgets/eden_async_form_scaffold.dart`.
///
/// **Disposal contract.** The library does NOT auto-dispose the
/// controller. The owner (typically the root `App` widget) calls
/// [ChangeNotifier.dispose] when the controller goes out of scope.
class EdenAppModeController extends ChangeNotifier {
  EdenAppModeController({
    required EdenAppMode initialMode,
    this.onChange,
  }) : _currentMode = initialMode;

  EdenAppMode _currentMode;

  /// Optional callback fired AFTER listeners are notified. Wire this
  /// to your persistence layer (e.g., SharedPreferences setString).
  /// Order: `notifyListeners()` runs first so the UI updates before
  /// any I/O begins — important if the I/O is async + the UI should
  /// not be blocked by it.
  final ValueChanged<EdenAppMode>? onChange;

  EdenAppMode get currentMode => _currentMode;

  /// Mutate the current mode. Idempotent — calling with the current
  /// mode is a no-op (no `notifyListeners`, no `onChange`).
  void setMode(EdenAppMode newMode) {
    if (newMode == _currentMode) return;
    _currentMode = newMode;
    notifyListeners();
    onChange?.call(newMode);
  }
}

/// InheritedNotifier scope. Dependents rebuild when the controller
/// fires [ChangeNotifier.notifyListeners].
///
/// Use [EdenAppModeScope.of] to read the controller in widgets that
/// always have a scope ancestor; use [EdenAppModeScope.maybeOf] for
/// optional dependencies. Use [EdenAppModeScope.modeOf] when you just
/// want the current enum.
class EdenAppModeScope extends InheritedNotifier<EdenAppModeController> {
  const EdenAppModeScope({
    super.key,
    required EdenAppModeController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the controller. Asserts if no scope is in the tree.
  static EdenAppModeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<EdenAppModeScope>();
    assert(
      scope != null,
      'EdenAppModeScope.of() called with no scope in the tree.',
    );
    return scope!.notifier!;
  }

  /// Returns the controller, or null if no scope is in the tree.
  /// Use for optional dependencies (a widget that adapts when in a scope
  /// but renders a sensible default outside).
  static EdenAppModeController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<EdenAppModeScope>()
        ?.notifier;
  }

  /// Convenience accessor for just the current enum value. Equivalent
  /// to `EdenAppModeScope.of(context).currentMode`.
  static EdenAppMode modeOf(BuildContext context) => of(context).currentMode;
}
