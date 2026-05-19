// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerMonthView.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenSchedulerMonthViewFixtures {
  EdenSchedulerMonthViewFixtures._();

  /// Saturday 2026-05-16.
  static final DateTime today = DateTime(2026, 5, 16);

  /// First day of May 2026 — used for focusedDate.
  static final DateTime may1 = DateTime(2026, 5, 1);

  /// Builds N events on the same day for overflow testing.
  static List<EdenSchedulerEvent> eventsOnMay15(int count) {
    return List.generate(count, (i) {
      return EdenSchedulerEvent(
        id: 'may15-$i',
        title: 'Event $i',
        start: DateTime(2026, 5, 15, 9 + i),
        end: DateTime(2026, 5, 15, 10 + i),
        color: i % 2 == 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
      );
    });
  }

  static Widget wrap(Widget child,
      {double width = 1200, double height = 800}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  /// Narrow-height wrap to surface RenderFlex overflow in month cells.
  /// height=400 over 6 calendar rows ≈ 66pt per cell; insufficient for
  /// the default chip stack and triggers the overflow bug pre-fix.
  static Widget wrapNarrow(Widget child,
      {double width = 1200, double height = 400}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }

  /// Wraps in a generously-tall bounded parent to exercise the
  /// "plenty of vertical room" branch of the height-aware chip cap.
  ///
  /// NOTE: A truly unbounded vertical parent is incompatible with
  /// `EdenSchedulerMonthView`'s outer Column+Expanded grid (Flutter requires
  /// bounded constraints for Expanded). The defensive `c.maxHeight.isFinite`
  /// guard inside `_MonthDayCell` is therefore not directly reachable from a
  /// widget-test fixture without bypassing the public widget structure. A
  /// large finite height exercises the same OBSERVABLE contract: no
  /// overflow, chip count clamped at `maxEventsPerCell` (not exceeded).
  static Widget wrapTallHeight(Widget child,
      {double width = 1200, double height = 4000}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );
  }
}
