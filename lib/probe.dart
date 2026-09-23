/// Runtime probe bridge for `eden_ui_flutter`.
///
/// Compiled in ONLY under `--dart-define=EDEN_PROBE=true`. Opt in by importing
/// this library directly — it is deliberately NOT exported from
/// `package:eden_ui_flutter/eden_ui.dart`, so a consumer that never mentions it
/// cannot accidentally ship it.
///
///     import 'package:eden_ui_flutter/probe.dart';
///     void main() {
///       EdenProbe.install();   // no-op without the define
///       runApp(const MyApp());
///     }
library;

export 'src/probe/eden_probe_scope.dart' show EdenProbeScope;
export 'src/probe/probe_bridge.dart' show EdenProbe, kEdenProbe;
