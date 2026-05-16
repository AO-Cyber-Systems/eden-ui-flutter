// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerListView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenSchedulerListViewFixtures {
  EdenSchedulerListViewFixtures._();

  /// Today is Saturday 2026-05-16.
  static final DateTime today = DateTime(2026, 5, 16);

  static DateTime Function() clock() => () => today;

  /// Today at 9 AM.
  static final EdenSchedulerEvent todayMorning = EdenSchedulerEvent(
    id: 'today-9',
    title: 'Coffee meeting',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    assignee: 'Alice',
  );

  /// Today at 8 AM (earlier).
  static final EdenSchedulerEvent todayEarly = EdenSchedulerEvent(
    id: 'today-8',
    title: 'Strategy session',
    start: DateTime(2026, 5, 16, 8),
    end: DateTime(2026, 5, 16, 9),
    assignee: 'Bob',
  );

  /// Today at 7 AM (earliest).
  static final EdenSchedulerEvent todayEarliest = EdenSchedulerEvent(
    id: 'today-7',
    title: 'Pre-dawn standup',
    start: DateTime(2026, 5, 16, 7),
    end: DateTime(2026, 5, 16, 8),
  );

  /// Tomorrow.
  static final EdenSchedulerEvent tomorrowEvent = EdenSchedulerEvent(
    id: 'tomorrow',
    title: 'Doc review',
    start: DateTime(2026, 5, 17, 11),
    end: DateTime(2026, 5, 17, 12),
  );

  /// Yesterday — Friday 2026-05-15.
  static final EdenSchedulerEvent yesterdayEvent = EdenSchedulerEvent(
    id: 'yesterday',
    title: 'Retro',
    start: DateTime(2026, 5, 15, 15),
    end: DateTime(2026, 5, 15, 16),
  );

  /// 5 days from today — Thursday 2026-05-21.
  static final EdenSchedulerEvent fiveDaysFromNow = EdenSchedulerEvent(
    id: 'plus5',
    title: 'Quarterly review',
    start: DateTime(2026, 5, 21, 10),
    end: DateTime(2026, 5, 21, 11),
  );

  /// Within 14-day range from week-start (Mon May 11) — Sun May 24 = day 13.
  static final EdenSchedulerEvent withinRange = EdenSchedulerEvent(
    id: 'within',
    title: 'Sprint demo',
    start: DateTime(2026, 5, 24, 10),
    end: DateTime(2026, 5, 24, 11),
  );

  /// 20 days from today — OUTSIDE 14-day range (June 5).
  static final EdenSchedulerEvent twentyDaysFromNow = EdenSchedulerEvent(
    id: 'plus20',
    title: 'Roadmap planning',
    start: DateTime(2026, 6, 5, 10),
    end: DateTime(2026, 6, 5, 11),
  );

  /// Event with resourceIds for filter testing.
  static final EdenSchedulerEvent withResource = EdenSchedulerEvent(
    id: 'res',
    title: 'Truck 47 visit',
    start: DateTime(2026, 5, 16, 13),
    end: DateTime(2026, 5, 16, 14),
    resourceIds: const ['r-47'],
  );

  static Widget wrap(Widget child, {double width = 800, double height = 800}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
