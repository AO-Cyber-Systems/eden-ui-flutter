// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerToolbar.

import 'package:flutter/material.dart';

/// Hand-built DateTime fixtures for SchedulerToolbar title-formatter tests.
class EdenSchedulerToolbarFixtures {
  EdenSchedulerToolbarFixtures._();

  /// Monday 2026-03-09 — anchor for week/workWeek/list/swimlane tests.
  static final DateTime mon2026Mar09 = DateTime(2026, 3, 9);

  /// Tuesday 2026-03-10 — mid-week to verify week math snaps to Mon..Sun.
  static final DateTime tue2026Mar10 = DateTime(2026, 3, 10);

  /// Wednesday 2026-03-11.
  static final DateTime wed2026Mar11 = DateTime(2026, 3, 11);

  /// Sunday 2026-03-15 — last day of the week.
  static final DateTime sun2026Mar15 = DateTime(2026, 3, 15);

  /// Mon 2026-03-30 — week spans Mar 30 .. Apr 5 (month boundary).
  static final DateTime mon2026Mar30 = DateTime(2026, 3, 30);

  /// Wed 2026-12-30 — week spans Dec 28 2026 .. Jan 3 2027 (year boundary).
  static final DateTime wed2026Dec30 = DateTime(2026, 12, 30);

  /// Wrap helper sized for desktop-width tests (toolbar gets full label).
  static Widget wrap(Widget child, {double width = 1400, double height = 200}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
