// lib/src/utils/eden_web_autofill_fix_stub.dart
//
// Non-web implementation of the autofill geometry shim: a total no-op.
//
// This is what every non-web build compiles, selected by the conditional
// export in `eden_web_autofill_fix.dart`. It exists so callers never have to
// branch on the platform themselves and so `dart:js_interop` is never reached
// on a target that has no DOM.
//
// It is also what `flutter test` compiles, because `flutter test` runs on the
// Dart VM. That is why the unit suite can prove the SHAPE of this API but can
// never prove the DOM behaviour -- see the honesty note in the facade.

import 'package:flutter/foundation.dart';

/// Opt-out switch, mirroring the web implementation's surface.
///
/// Setting this has no effect off web, and is offered only so a consumer can
/// write `edenWebAutofillFixEnabled = false` once, unconditionally, without
/// guarding it with [kIsWeb].
bool edenWebAutofillFixEnabled = true;

/// Always false off web: there is nothing to install.
bool get edenWebAutofillFixInstalled => false;

/// No-op off web.
void edenInstallWebAutofillFix() {
  // Intentionally empty. There is no DOM to observe and no engine-collapsed
  // element to restyle.
}

/// Restores the default state so tests are not order-dependent.
@visibleForTesting
void edenResetWebAutofillFixForTest() {
  edenWebAutofillFixEnabled = true;
}
