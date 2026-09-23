// The compile-time gate and the conditional export.
//
// WHY A CONDITIONAL IMPORT AND NOT `kIsWeb`: a runtime `if (kIsWeb)` branch
// keeps the `dart:js_interop` code in EVERY bundle, including mobile, and
// keeps `__edenProbe` in a production web bundle where `tool/probe_guard.sh`
// would then find it. The gate has to be something the COMPILER can resolve:
// a conditional import plus a `const bool.fromEnvironment`.
library;

import 'probe_api.dart';

// Resolved at compile time: the web file only when `dart:js_interop` exists.
import 'probe_bridge_stub.dart'
    if (dart.library.js_interop) 'probe_bridge_web.dart';

export 'probe_bridge_stub.dart'
    if (dart.library.js_interop) 'probe_bridge_web.dart';

/// Compile-time gate.
///
/// Set with: `flutter build web --release --dart-define=EDEN_PROBE=true`.
/// Absent (the default, and every production build) this is a `const false`,
/// which is what lets the tree shaker remove the whole bridge — and
/// `tool/probe_guard.sh` is what proves the shaker actually did.
const bool kEdenProbe = bool.fromEnvironment('EDEN_PROBE');

/// The consumer-facing entry point.
abstract final class EdenProbe {
  /// Requests a consumer's HTTP layer has declared in flight.
  ///
  /// Forwards to [EdenProbeApi.inFlightRequests] — the storage lives there so
  /// `probe_api.dart` stays free of any dependency on this file (the web shim
  /// imports `probe_api.dart`, so the other direction would be a cycle).
  static int get inFlightRequests => EdenProbeApi.inFlightRequests;
  static set inFlightRequests(int value) =>
      EdenProbeApi.inFlightRequests = value;

  /// How many times [install] got PAST the gate.
  ///
  /// Exists so the gate is testable on the VM: the stub bridge is a no-op, so
  /// without a counter "install() did nothing" is unobservable and the test
  /// for it could never fail.
  static int debugInstallCount = 0;

  /// Installs `window.__edenProbe` — and only under the define.
  static void install() {
    // CRITICAL: `kEdenProbe` is a compile-time const. `if (!const false)` is
    // what the tree shaker eliminates; `if (!someRuntimeBool)` would keep the
    // whole bridge in the bundle and the guard script would fail.
    if (!kEdenProbe) {
      return;
    }
    debugInstallCount += 1;
    installProbeBridge();
  }
}
