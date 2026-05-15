// Do NOT regenerate via LLM — hand-built fixtures for EdenOfflineQueueViewer.
//
// Anchored to a fixed reference `now` so relative-time formatting in the
// widget tests is deterministic. Production callers omit the `now`
// override and the widget uses DateTime.now() at render time.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenOfflineQueueViewerFixtures {
  EdenOfflineQueueViewerFixtures._();

  /// Reference clock used in tests — also acts as the `now` injection
  /// value passed to the widget so relative timestamps match expectations.
  static final DateTime referenceNow = DateTime(2026, 5, 15, 10, 0, 0);

  static const List<EdenOfflineQueueItem> empty = <EdenOfflineQueueItem>[];

  /// 5-item mix covering every status: 2 pending, 1 syncing, 1 conflict,
  /// 1 error. Timestamps chosen so the 5-min / 2-h / yesterday / "Jan 5"
  /// branches of the relative-time helper all appear.
  static final List<EdenOfflineQueueItem> mixed = <EdenOfflineQueueItem>[
    EdenOfflineQueueItem(
      id: 'q1',
      actionType: 'Update Customer',
      summary: 'Customer ABC123: phone → 555-0100',
      queuedAt: referenceNow.subtract(const Duration(seconds: 30)),
      payloadPreview: '{"id":"abc123","phone":"555-0100"}',
    ),
    EdenOfflineQueueItem(
      id: 'q2',
      actionType: 'Create Work Order',
      summary: 'New WO for customer ABC123 — leaky faucet',
      queuedAt: referenceNow.subtract(const Duration(minutes: 5)),
    ),
    EdenOfflineQueueItem(
      id: 'q3',
      actionType: 'Update Invoice',
      summary: 'Invoice INV-9012 status → paid',
      queuedAt: referenceNow.subtract(const Duration(hours: 2)),
      status: EdenOfflineQueueItemStatus.syncing,
    ),
    EdenOfflineQueueItem(
      id: 'q4',
      actionType: 'Update Customer',
      summary: 'Customer XYZ987: address conflict',
      queuedAt: referenceNow.subtract(const Duration(days: 1)),
      status: EdenOfflineQueueItemStatus.conflict,
      conflictDescription:
          'Server has a newer address for this customer. Pick one.',
    ),
    EdenOfflineQueueItem(
      id: 'q5',
      actionType: 'Create Photo',
      summary: 'Attach roof.jpg to WO-4455',
      queuedAt: referenceNow.subtract(const Duration(days: 3)),
      status: EdenOfflineQueueItemStatus.error,
      errorMessage: '413: payload too large',
    ),
  ];

  /// 50-item synthetic list for perf demos.
  static final List<EdenOfflineQueueItem> large = List<EdenOfflineQueueItem>
      .generate(
    50,
    (i) => EdenOfflineQueueItem(
      id: 'l$i',
      actionType: i % 3 == 0 ? 'Update Customer' : 'Create Work Order',
      summary: 'Synthetic item #$i',
      queuedAt: referenceNow.subtract(Duration(minutes: i)),
    ),
  );
}
