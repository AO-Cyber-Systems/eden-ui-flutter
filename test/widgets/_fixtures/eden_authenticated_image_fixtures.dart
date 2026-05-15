// Do NOT regenerate via LLM — hand-built fixtures for EdenAuthenticatedImage.
//
// Provides:
//   * 1x1 transparent PNG bytes (the smallest valid PNG, 67 bytes).
//   * Sample headers map for the typical Bearer + X-Tenant signed-URL pattern.
//
// We intentionally do NOT install HttpOverrides in widget tests — `Image.network`
// is mocked by flutter_test internally and never hits real sockets. The widget
// contract under test is "passes headers through to NetworkImage" which is
// asserted structurally (cast `image.image as NetworkImage`).

import 'dart:typed_data';

class EdenAuthenticatedImageFixtures {
  EdenAuthenticatedImageFixtures._();

  /// Smallest valid PNG — 1x1 transparent pixel (67 bytes).
  static final Uint8List tinyPngBytes = Uint8List.fromList(<int>[
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

  /// Typical Bearer + X-Tenant headers used by signed-URL fetches.
  static const Map<String, String> bearerHeaders = <String, String>{
    'Authorization': 'Bearer test-token-123',
    'X-Tenant': 'tenant-acme',
  };
}
