// Do NOT regenerate via LLM — hand-built fixtures for EdenWorkflowNodes.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hand-built fixtures for workflow-node tests (TRD 020-02 / 020-03).
/// Stable, deterministic, reviewable.

// ─────────── Trigger node context fixtures ───────────

EdenDiagramNodeContext triggerNodeContextFixture({
  EdenWorkflowTriggerType triggerType =
      EdenWorkflowTriggerType.entity_created,
  String category = 'appointment',
  bool selected = false,
  bool dropTarget = false,
}) {
  return EdenDiagramNodeContext(
    node: EdenDiagramNode(
      id: 'trigger-0',
      x: 0,
      y: 0,
      width: 200,
      height: 80,
      label: 'Trigger',
      data: {
        'nodeType': 'trigger',
        'triggerType': triggerType.name,
        'category': category,
        'config': const <String, dynamic>{},
      },
    ),
    selected: selected,
    dropTarget: dropTarget,
  );
}

// ─────────── Field registry fixtures ───────────

EdenWorkflowField customerNameFieldFixture() => const EdenWorkflowField(
      name: 'customer.name',
      label: 'Customer Name',
      type: 'string',
      category: 'appointment',
    );

EdenWorkflowField customerEmailFieldFixture() => const EdenWorkflowField(
      name: 'customer.email',
      label: 'Customer Email',
      type: 'string',
      category: 'appointment',
    );

EdenWorkflowField appointmentStartFieldFixture() => const EdenWorkflowField(
      name: 'start_time',
      label: 'Start Time',
      type: 'date',
      category: 'appointment',
    );

EdenWorkflowField taskPriorityFieldFixture() => const EdenWorkflowField(
      name: 'priority',
      label: 'Priority',
      type: 'string',
      category: 'task',
    );

EdenWorkflowField projectBudgetFieldFixture() => const EdenWorkflowField(
      name: 'budget',
      label: 'Budget',
      type: 'number',
      category: 'project',
    );

// ─────────── wrap helper (per global TDD playbook) ───────────

/// Wraps a widget in MaterialApp + Scaffold for widget tests, with optional
/// fixed width to exercise iPhone-narrow rendering.
Widget wrap(Widget child, {double? width}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: width != null ? SizedBox(width: width, child: child) : child,
      ),
    ),
  );
}

// ─────────── Trigger editor open helper ───────────

Future<void> openTriggerEditor(WidgetTester tester) async {
  // Tap the trigger card body to open the popover editor.
  await tester.tap(find.byType(InkWell).first);
  await tester.pumpAndSettle();
}
