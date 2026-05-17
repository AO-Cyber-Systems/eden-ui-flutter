import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_process_validation_fixtures.dart';

void main() {
  group('EdenProcessValidator — valid process', () {
    test('returns isValid=true, no issues, orphanCount=0', () {
      final f = validProcessFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
      expect(result.orphanCount, 0);
      expect(result.summary.errors, 0);
      expect(result.summary.warnings, 0);
    });
  });

  group('EdenProcessValidator — orphan warnings', () {
    test('3 orphans emit 3 warnings and orphanCount=3', () {
      final f = processWith3OrphansFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      expect(result.orphanCount, 3);
      final orphanWarnings = result.issues.where(
        (i) =>
            i.type == EdenProcessValidationSeverity.warning &&
            i.message.contains('not connected to the process'),
      );
      expect(orphanWarnings, hasLength(3));
    });

    test('orphan warning carries the orphanType in the suggestion', () {
      final f = processWith3OrphansFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final suggestions = result.issues
          .where((i) => i.suggestion != null)
          .map((i) => i.suggestion!);
      expect(
        suggestions.where((s) => s.contains('task') || s.contains('phase')),
        isNotEmpty,
      );
    });
  });

  group('EdenProcessValidator — empty-phase warning', () {
    test('phase with no groups → warning', () {
      final f = processWithEmptyPhaseFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final emptyPhaseWarn = result.issues.firstWhere(
        (i) => i.message.contains('has no task groups'),
        orElse: () => const EdenProcessValidationIssue(
          type: EdenProcessValidationSeverity.error,
          nodeId: 'missing',
          message: 'missing',
        ),
      );
      expect(emptyPhaseWarn.message, contains('Empty phase'));
      expect(emptyPhaseWarn.type, EdenProcessValidationSeverity.warning);
    });
  });

  group('EdenProcessValidator — empty-group warning', () {
    test('phase with 1 empty group → empty-group warning + phase-no-tasks warning', () {
      final f = processWithEmptyGroupFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final emptyGroup = result.issues.where(
        (i) => i.message.contains('"Empty group" is empty'),
      );
      expect(emptyGroup, hasLength(1));
      final phaseNoTasks = result.issues.where(
        (i) => i.message.contains('has no tasks'),
      );
      expect(phaseNoTasks, hasLength(1));
    });
  });

  group('EdenProcessValidator — decision missing branches', () {
    test('only yes branch → error', () {
      final f = processWithDecisionMissingBranchesFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final decisionErr = result.issues.where(
        (i) =>
            i.type == EdenProcessValidationSeverity.error &&
            i.message.contains('missing branches'),
      );
      expect(decisionErr, hasLength(1));
      expect(result.isValid, isFalse);
    });

    test('legacy edges with sourcePort.right + sourcePort.bottom → no error',
        () {
      final f = processWithDecisionLegacyHandlesFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final decisionErr = result.issues.where(
        (i) => i.message.contains('missing branches'),
      );
      expect(decisionErr, isEmpty);
    });
  });

  group('EdenProcessValidator — disconnected nodes', () {
    test('phase with no edges → disconnected warning', () {
      final f = processWithDisconnectedNodeFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final disconnectedWarn = result.issues.where(
        (i) =>
            i.type == EdenProcessValidationSeverity.warning &&
            i.message.contains('has no connections'),
      );
      expect(disconnectedWarn, hasLength(1));
      expect(disconnectedWarn.first.nodeId, 'phase-99');
    });

    test('start + end nodes are never flagged as disconnected', () {
      final f = processWithDisconnectedNodeFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      final startEndWarn = result.issues.where(
        (i) =>
            (i.nodeId == 'start' || i.nodeId == 'end') &&
            i.message.contains('has no connections'),
      );
      expect(startEndWarn, isEmpty);
    });
  });

  group('EdenProcessValidator — no phases error', () {
    test('empty phases list → error', () {
      final f = processWithNoPhasesFixture();
      final result = EdenProcessValidator.validate(f.def, f.nodes, f.edges);
      expect(result.isValid, isFalse);
      final err = result.issues.firstWhere(
        (i) =>
            i.type == EdenProcessValidationSeverity.error &&
            i.message == 'Process has no phases',
      );
      expect(err.nodeId, 'start');
    });
  });

  group('EdenProcessValidator — summary record', () {
    test('summary splits errors and warnings correctly', () {
      // Combine decision-missing-branches (1 error) + 3 orphans (3 warnings)
      // via the orphans fixture decorated with a missing decision.
      final orphansFixture = processWith3OrphansFixture();
      final brokenFixture = processWithDecisionMissingBranchesFixture();
      final mergedNodes = [
        ...orphansFixture.nodes,
        ...brokenFixture.nodes.where((n) => n.id == 'decision-7'),
      ];
      final mergedEdges = [
        ...orphansFixture.edges,
        ...brokenFixture.edges.where((e) =>
            e.sourceId == 'decision-7' || e.targetId == 'decision-7'),
      ];
      final mergedDef = EdenProcessDefinition(
        id: brokenFixture.def.id,
        processTypeId: brokenFixture.def.processTypeId,
        name: brokenFixture.def.name,
        displayName: brokenFixture.def.displayName,
        version: brokenFixture.def.version,
        isDefault: brokenFixture.def.isDefault,
        isActive: brokenFixture.def.isActive,
        isPublished: brokenFixture.def.isPublished,
        hasUnpublishedChanges: brokenFixture.def.hasUnpublishedChanges,
        config: brokenFixture.def.config,
        phases: orphansFixture.def.phases,
      );
      final result = EdenProcessValidator.validate(
        mergedDef,
        mergedNodes,
        mergedEdges,
      );
      expect(result.summary.errors, 1); // missing-branches
      expect(result.summary.warnings >= 3, isTrue); // 3 orphans + maybe more
      expect(result.isValid, isFalse);
    });
  });
}
