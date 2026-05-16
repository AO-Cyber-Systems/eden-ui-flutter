// Do NOT regenerate via LLM — hand-built fixtures for EdenSignatureCapturePage.
// Edit by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenSignatureCapturePageFixtures {
  EdenSignatureCapturePageFixtures._();

  /// A simple two-point stroke at known coordinates.
  static EdenSignatureStroke sampleStroke() => const EdenSignatureStroke(
        points: [
          EdenSignaturePoint(10, 10),
          EdenSignaturePoint(50, 50),
        ],
      );

  /// Recorder for onSigned invocations.
  static (
    List<EdenSignatureCaptureResult>,
    Future<void> Function(EdenSignatureCaptureResult)
  ) recorder() {
    final captured = <EdenSignatureCaptureResult>[];
    Future<void> signed(EdenSignatureCaptureResult r) async => captured.add(r);
    return (captured, signed);
  }

  /// Failing onSigned closure.
  static Future<void> Function(EdenSignatureCaptureResult) failing(
          String msg) =>
      (_) async => throw Exception(msg);
}
