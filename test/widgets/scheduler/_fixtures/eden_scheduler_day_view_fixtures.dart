// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerDayView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenSchedulerDayViewFixtures {
  EdenSchedulerDayViewFixtures._();

  /// Saturday 2026-05-16 — fixed today reference.
  static final DateTime today = DateTime(2026, 5, 16);

  /// Sunday 2026-05-17.
  static final DateTime tomorrow = DateTime(2026, 5, 17);

  /// Clock builder for "today at h:m".
  static DateTime Function() clockAt(int h, int m) =>
      () => DateTime(today.year, today.month, today.day, h, m);

  /// 9-10 AM event on today.
  static final EdenSchedulerEvent event9to10 = EdenSchedulerEvent(
    id: 'e-9to10',
    title: '9-10 AM',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    color: const Color(0xFF3B82F6),
  );

  /// 5-6:30 AM event (spans the default startHour=6 boundary).
  static final EdenSchedulerEvent event5to630 = EdenSchedulerEvent(
    id: 'e-5to630',
    title: 'Early',
    start: DateTime(2026, 5, 16, 5),
    end: DateTime(2026, 5, 16, 6, 30),
  );

  /// 3-5 AM event (entirely before default startHour=6).
  static final EdenSchedulerEvent event3to5 = EdenSchedulerEvent(
    id: 'e-3to5',
    title: 'Pre-dawn',
    start: DateTime(2026, 5, 16, 3),
    end: DateTime(2026, 5, 16, 5),
  );

  static Widget wrap(Widget child, {double width = 800, double height = 700}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
