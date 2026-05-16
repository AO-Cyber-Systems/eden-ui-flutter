// Do NOT regenerate via LLM — hand-built fixtures for EdenBlockingAlerts.
//
// Hand-picked task / context / reason combinations covering both severities.
// Add new fixtures by hand only.

import 'package:eden_ui_flutter/eden_ui.dart';

class EdenBlockingAlertsFixtures {
  EdenBlockingAlertsFixtures._();

  static EdenBlockingAlertData redAlert({
    String task = 'Install HVAC',
    String context = 'Phase 2',
    String reason = 'Waiting on permit approval',
    List<EdenBlockingAction> actions = const <EdenBlockingAction>[],
  }) {
    return EdenBlockingAlertData(
      task: task,
      context: context,
      reason: reason,
      severity: EdenBlockingSeverity.red,
      actions: actions,
    );
  }

  static EdenBlockingAlertData amberAlert({
    String task = 'Pour foundation',
    String context = 'Phase 1',
    String reason = 'Awaiting inspection',
    List<EdenBlockingAction> actions = const <EdenBlockingAction>[],
  }) {
    return EdenBlockingAlertData(
      task: task,
      context: context,
      reason: reason,
      severity: EdenBlockingSeverity.amber,
      actions: actions,
    );
  }

  static List<EdenBlockingAlertData> mixedList(int redCount, int amberCount) {
    final list = <EdenBlockingAlertData>[];
    for (var i = 0; i < redCount; i++) {
      list.add(redAlert(
        task: i == 0 ? 'Install HVAC' : 'Install electrical panel',
        context: i == 0 ? 'Phase 2' : 'Phase 3',
        reason: i == 0
            ? 'Waiting on permit approval'
            : 'Material backordered 14 days',
      ));
    }
    for (var i = 0; i < amberCount; i++) {
      list.add(amberAlert(
        task: i == 0 ? 'Pour foundation' : 'Inspect roof',
        context: i == 0 ? 'Phase 1' : 'Permit review',
        reason: i == 0
            ? 'Awaiting inspection'
            : 'Survey not received',
      ));
    }
    return list;
  }
}
