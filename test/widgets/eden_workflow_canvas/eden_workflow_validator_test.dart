import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_workflow_validator_fixtures.dart';

void main() {
  group('EdenWorkflowValidator — Rule 1 (must have trigger)', () {
    test('empty workflow: error "must have a trigger node"', () {
      final result = EdenWorkflowValidator.validate(const [], const []);
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.error &&
            i.message.contains('must have a trigger')),
        isTrue,
      );
    });

    test('one trigger: no trigger-count error', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0'),
          edgeFixture(id: 'e2', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) => i.message.contains('must have a trigger')),
        isFalse,
      );
    });

    test('two triggers: error "can only have one trigger"', () {
      final result = EdenWorkflowValidator.validate(
        [
          triggerNodeFixture(id: 'trigger-0'),
          triggerNodeFixture(id: 'trigger-1'),
          actionNodeFixture(),
          endNodeFixture(),
        ],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0'),
          edgeFixture(id: 'e2', source: 'action-0', target: 'end-0'),
          edgeFixture(id: 'e3', source: 'trigger-1', target: 'action-0'),
        ],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.error &&
            i.message.contains('only have one trigger')),
        isTrue,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 2 (must have action)', () {
    test('no actions: error', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), endNodeFixture()],
        [edgeFixture(id: 'e1', source: 'trigger-0', target: 'end-0')],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.error &&
            i.message.contains('at least one action')),
        isTrue,
      );
    });

    test('one action: no error', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0'),
          edgeFixture(id: 'e2', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) => i.message.contains('at least one action')),
        isFalse,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 3 (should have end)', () {
    test('no end: warning', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture()],
        [edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0')],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.warning &&
            i.message.contains('no end node')),
        isTrue,
      );
    });

    test('with end: no warning', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0'),
          edgeFixture(id: 'e2', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) => i.message.contains('no end node')),
        isFalse,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 4 (non-trigger needs incoming)', () {
    test('orphan action (no incoming): error', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        // action-0 has no incoming edge
        [edgeFixture(id: 'e1', source: 'trigger-0', target: 'end-0')],
      );
      final orphanError = result.issues.firstWhere(
        (i) =>
            i.severity == EdenProcessValidationSeverity.error &&
            i.message.contains('is not connected to any input'),
        orElse: () => throw StateError('expected orphan error'),
      );
      expect(orphanError.nodeId, 'action-0');
    });

    test('trigger has no incoming and is exempt', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0'),
          edgeFixture(id: 'e2', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any(
            (i) => i.nodeId == 'trigger-0' && i.message.contains('input')),
        isFalse,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 5 (non-end needs outgoing)', () {
    test('action with no outgoing: warning', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        // action-0 has no outgoing edge
        [edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0')],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.warning &&
            i.nodeId == 'action-0' &&
            i.message.contains('no outgoing connection')),
        isTrue,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 6 (branch >= 2 outgoing)', () {
    test('branch with 1 outgoing: warning', () {
      final result = EdenWorkflowValidator.validate(
        [
          triggerNodeFixture(),
          branchNodeFixture(),
          actionNodeFixture(),
          endNodeFixture(),
        ],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'branch-0'),
          edgeFixture(id: 'e2', source: 'branch-0', target: 'action-0'),
          edgeFixture(id: 'e3', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.warning &&
            i.nodeId == 'branch-0' &&
            i.message.contains('split into at least 2 paths')),
        isTrue,
      );
    });

    test('branch with 2+ outgoing: no warning', () {
      final result = EdenWorkflowValidator.validate(
        [
          triggerNodeFixture(),
          branchNodeFixture(),
          actionNodeFixture(id: 'action-0'),
          actionNodeFixture(id: 'action-1'),
          endNodeFixture(),
        ],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'branch-0'),
          edgeFixture(id: 'e2', source: 'branch-0', target: 'action-0'),
          edgeFixture(id: 'e3', source: 'branch-0', target: 'action-1'),
          edgeFixture(id: 'e4', source: 'action-0', target: 'end-0'),
          edgeFixture(id: 'e5', source: 'action-1', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) =>
            i.nodeId == 'branch-0' && i.message.contains('split into')),
        isFalse,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 7 (merge >= 2 incoming)', () {
    test('merge with 1 incoming: warning', () {
      final result = EdenWorkflowValidator.validate(
        [
          triggerNodeFixture(),
          mergeNodeFixture(),
          actionNodeFixture(),
          endNodeFixture(),
        ],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'merge-0'),
          edgeFixture(id: 'e2', source: 'merge-0', target: 'action-0'),
          edgeFixture(id: 'e3', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.warning &&
            i.nodeId == 'merge-0' &&
            i.message.contains('receive at least 2 paths')),
        isTrue,
      );
    });
  });

  group('EdenWorkflowValidator — Rule 8 (condition configured)', () {
    test('unconfigured condition: warning', () {
      final result = EdenWorkflowValidator.validate(
        [
          triggerNodeFixture(),
          unconfiguredConditionFixture(),
          actionNodeFixture(),
          endNodeFixture(),
        ],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'condition-0'),
          edgeFixture(id: 'e2', source: 'condition-0', target: 'action-0'),
          edgeFixture(id: 'e3', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) =>
            i.severity == EdenProcessValidationSeverity.warning &&
            i.nodeId == 'condition-0' &&
            i.message.contains('not configured')),
        isTrue,
      );
    });

    test('configured condition: no warning', () {
      final result = EdenWorkflowValidator.validate(
        [
          triggerNodeFixture(),
          configuredConditionFixture(),
          actionNodeFixture(),
          endNodeFixture(),
        ],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'condition-0'),
          edgeFixture(id: 'e2', source: 'condition-0', target: 'action-0'),
          edgeFixture(id: 'e3', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(
        result.issues.any((i) =>
            i.nodeId == 'condition-0' &&
            i.message.contains('not configured')),
        isFalse,
      );
    });
  });

  group('EdenWorkflowValidationResult', () {
    test('isValid true when only warnings present', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture()],
        [edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0')],
      );
      // Missing end → warning only; rule 5 warning for action (no outgoing).
      // No errors expected.
      expect(result.summary.errors, 0);
      expect(result.isValid, isTrue);
    });

    test('isValid false when at least one error', () {
      final result = EdenWorkflowValidator.validate(const [], const []);
      expect(result.summary.errors, greaterThan(0));
      expect(result.isValid, isFalse);
    });

    test('summary errors + warnings counts', () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture()],
        const [],
      );
      // Errors: Rule 2 (no action). Warnings: Rule 3 (no end), Rule 5
      // (trigger no outgoing).
      expect(result.summary.errors, greaterThan(0));
      expect(result.summary.warnings, greaterThan(0));
    });
  });

  group('EdenWorkflowValidator — full happy path', () {
    test('trigger + action + end fully connected → isValid (warnings ok)',
        () {
      final result = EdenWorkflowValidator.validate(
        [triggerNodeFixture(), actionNodeFixture(), endNodeFixture()],
        [
          edgeFixture(id: 'e1', source: 'trigger-0', target: 'action-0'),
          edgeFixture(id: 'e2', source: 'action-0', target: 'end-0'),
        ],
      );
      expect(result.summary.errors, 0);
      expect(result.isValid, isTrue);
    });
  });
}
