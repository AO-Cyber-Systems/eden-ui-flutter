// Do NOT regenerate via LLM — hand-built fixtures for EdenMeterReadingEntry.
import 'package:eden_ui_flutter/eden_ui.dart';

/// Hand-built fixtures for EdenMeterReadingEntry tests.
class EdenMeterReadingEntryFixtures {
  EdenMeterReadingEntryFixtures._();

  /// Fully-populated draft for initialDraft pre-population tests.
  static final EdenMeterReadingDraft validDraft = EdenMeterReadingDraft(
    gallons: 320.5,
    source: EdenMeterReadingSource.telemetry,
    timestamp: DateTime(2026, 5, 16, 9, 0),
    operatorId: 'op-1',
    notes: 'tank read at 9am',
  );

  /// Minimum-valid draft — gallons=0 (empty tank), manual source.
  static final EdenMeterReadingDraft minimalDraft = EdenMeterReadingDraft(
    gallons: 0,
    source: EdenMeterReadingSource.manual,
    timestamp: DateTime(2026, 5, 16),
    operatorId: 'op-2',
  );

  /// Draft including a photo signed URL.
  static final EdenMeterReadingDraft photoDraft = EdenMeterReadingDraft(
    gallons: 100,
    source: EdenMeterReadingSource.manual,
    timestamp: DateTime(2026, 5, 16),
    operatorId: 'op-1',
    photoSignedUrl: 'https://example.com/photo.jpg',
  );

  /// Photo picker that returns a sample signed URL.
  static Future<String?> goodPhotoPick() async =>
      'https://example.com/photo.jpg';

  /// Photo picker that simulates user cancellation.
  static Future<String?> cancelledPhotoPick() async => null;
}
