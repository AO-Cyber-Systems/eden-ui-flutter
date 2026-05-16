// Do NOT regenerate via LLM — hand-built fixtures for EdenSchedulerEventBlock.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';

class EdenSchedulerEventBlockFixtures {
  EdenSchedulerEventBlockFixtures._();

  /// Vanilla event: title only, no readiness, no resourceIds.
  static final EdenSchedulerEvent vanilla = EdenSchedulerEvent(
    id: 'v',
    title: 'Coffee meeting',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
  );

  /// Event with red color.
  static final EdenSchedulerEvent redColored = EdenSchedulerEvent(
    id: 'r',
    title: 'Red event',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    color: const Color(0xFFEF4444),
  );

  /// Event with dispatch readiness = warning (yellow border).
  static final EdenSchedulerEvent warningReadiness = EdenSchedulerEvent(
    id: 'w',
    title: 'Warning event',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    readiness: EdenSchedulerEventReadiness.warning,
  );

  /// Event with dispatch readiness = ready (green border).
  static final EdenSchedulerEvent readyReadiness = EdenSchedulerEvent(
    id: 'g',
    title: 'Ready event',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    readiness: EdenSchedulerEventReadiness.ready,
  );

  /// Event with dispatch issue (red border regardless of readiness).
  static final EdenSchedulerEvent dispatchIssue = EdenSchedulerEvent(
    id: 'di',
    title: 'Issue event',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    dispatchIssue: 'Missing technician',
  );

  /// Event with location + assignee.
  static final EdenSchedulerEvent locAssignee = EdenSchedulerEvent(
    id: 'la',
    title: 'On-site call',
    start: DateTime(2026, 5, 16, 9),
    end: DateTime(2026, 5, 16, 10),
    location: const EdenSchedulerLocation(name: 'Site A'),
    assignee: 'Alice',
  );

  static Widget wrap(Widget child, {double width = 300, double height = 100}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }
}
