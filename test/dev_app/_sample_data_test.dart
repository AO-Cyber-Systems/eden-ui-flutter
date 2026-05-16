// test/dev_app/_sample_data_test.dart
//
// Smoke test for the dev-catalog sample-data library. This test is NOT
// TDD-driven — it's a regression gate that ensures:
//
//   1. All 6 scenario files compile + are reachable via the barrel.
//   2. Each scenario class exposes non-empty fixture lists.
//   3. No fixture has slipped to AI-shaped placeholder patterns
//      ("Customer 1", "John Doe", etc).
//
// If this test fails, somebody emptied a fixture OR fed the file through an
// LLM regen pass — both are contract violations. See the per-file headers
// for the "Do NOT regenerate via LLM" rule.

import 'package:eden_ui_flutter/dev_app/_sample_data/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sample_data library', () {
    test('TradesScenarios fixtures are non-empty', () {
      expect(TradesScenarios.weekEvents, isNotEmpty);
      expect(
        TradesScenarios.monthEvents.length,
        greaterThanOrEqualTo(50),
        reason: 'Wave 5 scheduler stress demo needs 50+ events.',
      );
      expect(TradesScenarios.blockingAlerts, isNotEmpty);
      expect(TradesScenarios.activityFeed, isNotEmpty);
      expect(TradesScenarios.singleEventDay, hasLength(1));
      expect(TradesScenarios.overflowDay.length, greaterThanOrEqualTo(10));
    });

    test('SalonScenarios fixtures are non-empty', () {
      expect(SalonScenarios.weekAppointments, isNotEmpty);
      expect(SalonScenarios.memberClients, isNotEmpty);
      expect(SalonScenarios.blockingAlerts, isNotEmpty);
      expect(SalonScenarios.activityFeed, isNotEmpty);
    });

    test('FuelScenarios fixtures are non-empty', () {
      expect(FuelScenarios.weekDeliveries, isNotEmpty);
      expect(
        FuelScenarios.tankLevels.length,
        greaterThanOrEqualTo(5),
        reason: 'EdenStockLevelIndicator demos need green/amber/red mix.',
      );
      expect(FuelScenarios.networkSamples, isNotEmpty);
    });

    test('MedicalScenarios fixtures are non-empty', () {
      expect(MedicalScenarios.weekVisits, isNotEmpty);
      expect(MedicalScenarios.consentClauses.length, greaterThanOrEqualTo(5));
      expect(MedicalScenarios.intakeQuestions.length, greaterThanOrEqualTo(8));
      expect(MedicalScenarios.patients, isNotEmpty);
    });

    test('GovScenarios fixtures are non-empty', () {
      expect(GovScenarios.weekCases, isNotEmpty);
      expect(GovScenarios.citizens, isNotEmpty);
      expect(GovScenarios.caseworkers, isNotEmpty);
    });

    test('CrossCuttingFixtures expose customers / staff / inventory', () {
      expect(CrossCuttingFixtures.customers.length, greaterThanOrEqualTo(8));
      expect(CrossCuttingFixtures.staff.length, greaterThanOrEqualTo(6));
      expect(CrossCuttingFixtures.inventory.length, greaterThanOrEqualTo(8));
      expect(
        CrossCuttingFixtures.mixedActivityFeed.length,
        greaterThanOrEqualTo(8),
      );
    });

    test('catalogToday is stable across calls (same DateTime value)', () {
      expect(CrossCuttingFixtures.catalogToday,
          DateTime(2026, 5, 16, 9, 0));
      expect(
        CrossCuttingFixtures.catalogToday,
        equals(CrossCuttingFixtures.catalogToday),
      );
    });

    test('No fixture uses AI-shaped placeholder names', () {
      final names = <String>[
        ...CrossCuttingFixtures.customers.map((c) => c.name),
        ...CrossCuttingFixtures.staff.map((s) => s.name),
      ];
      final placeholderPatterns = <RegExp>[
        RegExp(r'(Customer|Staff|User|Person|Patient|Client)\s*\d'),
        RegExp(r'^(John|Jane)\s+Doe$'),
        RegExp(r'^Test\s'),
        RegExp(r'^Example\s'),
        RegExp(r'^Lorem'),
      ];
      for (final n in names) {
        for (final pat in placeholderPatterns) {
          expect(
            pat.hasMatch(n),
            isFalse,
            reason:
                'AI-shaped placeholder detected: "$n" matches ${pat.pattern}. '
                'Rewrite with a believable hand-built name.',
          );
        }
      }
    });

    test('Each vertical scenario exposes at least one cross-vertical staff '
        'or customer reference (sniff-test for vertical leakage)', () {
      // Every vertical fixture set should weave in real cross-cutting refs
      // somewhere — not be a silo'd island. Salon memberClients pulls from
      // CrossCuttingFixtures.customers; gov caseworkers pulls from
      // CrossCuttingFixtures.staff. This test pins that pattern.
      expect(
        SalonScenarios.memberClients.any(
          (c) => CrossCuttingFixtures.customers.contains(c),
        ),
        isTrue,
        reason:
            'SalonScenarios.memberClients should reference CrossCuttingFixtures.customers',
      );
      expect(
        GovScenarios.caseworkers.any(
          (s) => CrossCuttingFixtures.staff.contains(s),
        ),
        isTrue,
        reason:
            'GovScenarios.caseworkers should reference CrossCuttingFixtures.staff',
      );
    });
  });
}
