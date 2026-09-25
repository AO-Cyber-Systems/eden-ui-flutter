// Non-web no-op.
//
// Mobile and desktop drivers do not talk to a JS bridge — they drive the
// rendered surface through the visual/golden path instead. This file exists so
// `probe_bridge.dart`'s conditional import resolves on every platform without
// `dart:js_interop` ever entering a mobile bundle.
library;

/// No-op on every platform without `dart:js_interop`.
void installProbeBridge() {}
