// Test fixtures for EdenMediaPickerView / EdenMediaPickerModal tests.
//
// Provides factory helpers that keep test bodies small and intent-focused.

import 'package:eden_ui_flutter/src/widgets/eden_media_picker_view.dart';

/// A PickedFile fixture representing a valid JPEG image.
const PickedFile kValidJpeg = PickedFile(
  name: 'photo.jpg',
  mimeType: 'image/jpeg',
  bytes: [0xFF, 0xD8, 0xFF], // minimal JPEG magic bytes
);

/// A PickedFile fixture representing a valid PNG image.
const PickedFile kValidPng = PickedFile(
  name: 'logo.png',
  mimeType: 'image/png',
  bytes: [0x89, 0x50, 0x4E, 0x47], // PNG magic bytes
);

/// A PickedFile fixture with a MIME type that is NOT in the allowed set.
const PickedFile kInvalidMime = PickedFile(
  name: 'document.pdf',
  mimeType: 'application/pdf',
  bytes: [0x25, 0x50, 0x44, 0x46],
);

/// Upload function that immediately returns a CDN URL.
Future<String> successUploadFn({
  required String filename,
  required String contentType,
  required List<int> bytes,
}) async {
  return 'https://cdn.example.com/media/$filename';
}

/// Upload function that immediately throws an exception.
Future<String> failingUploadFn({
  required String filename,
  required String contentType,
  required List<int> bytes,
}) async {
  throw Exception('Upload failed: HTTP 500');
}

/// Pick function that returns kValidJpeg.
Future<PickedFile?> pickJpeg() async => kValidJpeg;

/// Pick function that returns kInvalidMime.
Future<PickedFile?> pickInvalidMime() async => kInvalidMime;

/// Pick function that returns null (user cancelled).
Future<PickedFile?> pickCancelled() async => null;
