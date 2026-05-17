// Do NOT regenerate via LLM — hand-built fixtures for EdenClientSmsThread.
//
// Powers obj 016-05 tests. Sample salon SMS content references real product
// names (Wella, Redken) from MangoMint's competitive landscape — concrete,
// touched by hand. Fixed `kFixedNow` keeps date-separator output deterministic.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenClientSmsThreadFixtures {
  EdenClientSmsThreadFixtures._();

  static final DateTime kFixedNow = DateTime(2026, 5, 17, 14, 30);

  /// 8 messages — mix of inbound + outbound across today + yesterday + 3 days
  /// ago, includes 1 message with a media attachment, mix of delivery statuses.
  static List<EdenSmsMessage> salonStarterThread() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'Hi! Can you confirm my appointment for Thursday 3pm?',
        direction: EdenSmsDirection.inbound,
        sentAt: DateTime(2026, 5, 14, 9, 14),
      ),
      EdenSmsMessage(
        id: 'm2',
        body:
            'Yes — you are confirmed for Thursday May 18 at 3:00 PM with Aisha.',
        direction: EdenSmsDirection.outbound,
        status: EdenSmsDeliveryStatus.delivered,
        sentAt: DateTime(2026, 5, 14, 9, 17),
      ),
      EdenSmsMessage(
        id: 'm3',
        body: 'Perfect, thank you!',
        direction: EdenSmsDirection.inbound,
        sentAt: DateTime(2026, 5, 14, 9, 18),
      ),
      EdenSmsMessage(
        id: 'm4',
        body:
            'Quick question — what dye brand do you carry? I want to match my current color.',
        direction: EdenSmsDirection.inbound,
        sentAt: DateTime(2026, 5, 16, 10, 30),
      ),
      EdenSmsMessage(
        id: 'm5',
        body:
            'We use Wella Professionals + Redken. Send a photo of your current color and Aisha can preview matches.',
        direction: EdenSmsDirection.outbound,
        status: EdenSmsDeliveryStatus.read,
        sentAt: DateTime(2026, 5, 16, 10, 33),
      ),
      EdenSmsMessage(
        id: 'm6',
        body: "Sure! Here's a photo from yesterday.",
        direction: EdenSmsDirection.inbound,
        mediaUrls: const ['https://example.com/photo.jpg'],
        sentAt: DateTime(2026, 5, 17, 8, 30),
      ),
      EdenSmsMessage(
        id: 'm7',
        body:
            'Beautiful — Aisha will bring out the warm copper tones to match. See you Thursday.',
        direction: EdenSmsDirection.outbound,
        status: EdenSmsDeliveryStatus.delivered,
        sentAt: DateTime(2026, 5, 17, 9, 0),
      ),
      EdenSmsMessage(
        id: 'm8',
        body: 'Looking forward to it!',
        direction: EdenSmsDirection.inbound,
        sentAt: DateTime(2026, 5, 17, 11, 30),
      ),
    ];
  }

  static List<EdenSmsMessage> singleInbound() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'Confirming my 3pm Thursday?',
        direction: EdenSmsDirection.inbound,
        sentAt: kFixedNow,
      ),
    ];
  }

  static List<EdenSmsMessage> singleOutboundSent() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'You are confirmed.',
        direction: EdenSmsDirection.outbound,
        status: EdenSmsDeliveryStatus.sent,
        sentAt: kFixedNow,
      ),
    ];
  }

  static List<EdenSmsMessage> singleOutboundDelivered() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'You are confirmed.',
        direction: EdenSmsDirection.outbound,
        status: EdenSmsDeliveryStatus.delivered,
        sentAt: kFixedNow,
      ),
    ];
  }

  static List<EdenSmsMessage> singleOutboundFailed() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'Send failed message.',
        direction: EdenSmsDirection.outbound,
        status: EdenSmsDeliveryStatus.failed,
        sentAt: kFixedNow,
      ),
    ];
  }

  /// 3 messages spanning today + yesterday + 3 days ago — for date-separator
  /// grouping test.
  static List<EdenSmsMessage> threeSpanningDays() {
    final today = DateTime(2026, 5, 17, 14, 30);
    final yesterday = DateTime(2026, 5, 16, 14, 30);
    final threeDaysAgo = DateTime(2026, 5, 14, 14, 30);
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'Three days ago',
        direction: EdenSmsDirection.inbound,
        sentAt: threeDaysAgo,
      ),
      EdenSmsMessage(
        id: 'm2',
        body: 'Yesterday',
        direction: EdenSmsDirection.inbound,
        sentAt: yesterday,
      ),
      EdenSmsMessage(
        id: 'm3',
        body: 'Today',
        direction: EdenSmsDirection.inbound,
        sentAt: today,
      ),
    ];
  }

  static List<EdenSmsMessage> twoSameDay() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'First',
        direction: EdenSmsDirection.inbound,
        sentAt: DateTime(2026, 5, 17, 9, 0),
      ),
      EdenSmsMessage(
        id: 'm2',
        body: 'Second',
        direction: EdenSmsDirection.inbound,
        sentAt: DateTime(2026, 5, 17, 10, 0),
      ),
    ];
  }

  static List<EdenSmsMessage> withMedia() {
    return [
      EdenSmsMessage(
        id: 'm1',
        body: 'See attached',
        direction: EdenSmsDirection.inbound,
        mediaUrls: const ['https://example.com/photo.jpg'],
        sentAt: kFixedNow,
      ),
    ];
  }
}
