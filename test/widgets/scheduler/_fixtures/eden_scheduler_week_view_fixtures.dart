// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerWeekView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenSchedulerWeekViewFixtures {
  EdenSchedulerWeekViewFixtures._();

  /// Monday 2026-05-11.
  static final DateTime mon = DateTime(2026, 5, 11);

  /// Wednesday 2026-05-13.
  static final DateTime wed = DateTime(2026, 5, 13);

  /// Sunday 2026-05-10 (previous Sun, the Sun-Sat 'week' start anchor).
  static final DateTime prevSun = DateTime(2026, 5, 10);

  /// Saturday 2026-05-16.
  static final DateTime sat = DateTime(2026, 5, 16);

  static DateTime Function() clockOn(DateTime today, {int h = 12, int m = 0}) =>
      () => DateTime(today.year, today.month, today.day, h, m);

  static final EdenSchedulerEvent monMorning = EdenSchedulerEvent(
    id: 'e-mon-9',
    title: 'Mon meeting',
    start: DateTime(2026, 5, 11, 9),
    end: DateTime(2026, 5, 11, 10),
  );

  static final EdenSchedulerEvent wedAfternoon = EdenSchedulerEvent(
    id: 'e-wed-2',
    title: 'Wed call',
    start: DateTime(2026, 5, 13, 14),
    end: DateTime(2026, 5, 13, 15),
  );

  static final EdenSchedulerEvent sunMorning = EdenSchedulerEvent(
    id: 'e-sun-9',
    title: 'Sun service',
    start: DateTime(2026, 5, 10, 9),
    end: DateTime(2026, 5, 10, 10),
  );

  static Widget wrap(Widget child, {double width = 1200, double height = 800}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
