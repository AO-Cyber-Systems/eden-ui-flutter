// Do NOT regenerate via LLM — hand-built fixtures for EdenFileUpload.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenFileUploadFixtures {
  EdenFileUploadFixtures._();

  static const baselinePending = EdenUploadFile(
    name: 'doc.pdf',
    sizeBytes: 1024 * 30,
  );

  static const baselineUploading = EdenUploadFile(
    name: 'uploading.pdf',
    sizeBytes: 1024 * 60,
    status: EdenUploadStatus.uploading,
    progress: 0.42,
  );

  static const baselineComplete = EdenUploadFile(
    name: 'done.pdf',
    sizeBytes: 1024 * 80,
    status: EdenUploadStatus.complete,
  );

  static const baselineError = EdenUploadFile(
    name: 'failed.pdf',
    sizeBytes: 1024 * 10,
    status: EdenUploadStatus.error,
    error: 'Upload timed out',
  );

  // Wave 3 compliance additions.
  static const scanningWithProgress = EdenUploadFile(
    name: 'scanning.pdf',
    sizeBytes: 1024 * 50,
    status: EdenUploadStatus.virusScanning,
    scanProgress: 0.4,
  );

  static const scanningIndeterminate = EdenUploadFile(
    name: 'scanning2.pdf',
    sizeBytes: 1024 * 50,
    status: EdenUploadStatus.virusScanning,
  );

  static const scanFailed = EdenUploadFile(
    name: 'malware.exe',
    sizeBytes: 1024 * 200,
    status: EdenUploadStatus.virusScanFailed,
    error: 'Virus scan failed: Trojan.Generic.247',
  );

  static const cuiMarked = EdenUploadFile(
    name: 'pii.csv',
    sizeBytes: 1024 * 10,
    status: EdenUploadStatus.cuiMarked,
    cuiMarking: 'CUI//SP-PII',
  );

  static const quarantined = EdenUploadFile(
    name: 'evil.zip',
    sizeBytes: 1024 * 80,
    status: EdenUploadStatus.quarantined,
    quarantineReason: 'Spillage signature detected — quarantined per SOP',
  );
}
