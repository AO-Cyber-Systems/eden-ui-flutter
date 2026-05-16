// Do NOT regenerate via LLM — hand-built fixtures for EdenPhotoCapturePage.
// Edit by hand only.

import 'dart:typed_data';

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenPhotoCapturePageFixtures {
  EdenPhotoCapturePageFixtures._();

  /// 1×1 transparent PNG bytes — tiny + decodes on all platforms.
  static Uint8List onePixelPng() => Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

  static EdenCapturedPhoto sample() => EdenCapturedPhoto(
        filePath: '/tmp/sample.jpg',
        bytes: onePixelPng(),
        mimeType: 'image/png',
        capturedAt: DateTime(2026, 5, 16, 14, 30),
      );

  /// Recorder for capture invocations.
  static (
    List<EdenPhotoCaptureRequest>,
    Future<EdenCapturedPhoto?> Function(EdenPhotoCaptureRequest)
  ) captureRecorder() {
    final captured = <EdenPhotoCaptureRequest>[];
    Future<EdenCapturedPhoto?> fn(EdenPhotoCaptureRequest r) async {
      captured.add(r);
      return sample();
    }
    return (captured, fn);
  }

  /// Slow capture (50ms — enough to observe spinner without flake).
  static Future<EdenCapturedPhoto?> Function(EdenPhotoCaptureRequest)
      slowCapture() => (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return sample();
          };

  /// Failing capture.
  static Future<EdenCapturedPhoto?> Function(EdenPhotoCaptureRequest)
      failingCapture(String msg) => (_) async => throw Exception(msg);

  /// Gallery recorder.
  static (int Function(), Future<EdenCapturedPhoto?> Function())
      galleryRecorder() {
    var calls = 0;
    Future<EdenCapturedPhoto?> fn() async {
      calls++;
      return sample();
    }
    return (() => calls, fn);
  }
}
