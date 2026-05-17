import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_staff_schedule_fixtures.dart';

Widget wrap(Widget child, {double width = 1200, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenStaffCapabilityMatrix grid rendering', () {
    testWidgets('renders DataTable with 4 service columns + 5 staff rows',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStaffCapabilityMatrix(
        staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
        services: EdenStaffCapabilityMatrixFixtures.fourServices(),
        capabilities:
            EdenStaffCapabilityMatrixFixtures.realisticCapabilities(),
        onCapabilityToggled: (_, __, ___) {},
      )));
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Haircut'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Balayage'), findsOneWidget);
      expect(find.text('Facial'), findsOneWidget);
      expect(find.text('Aisha A.'), findsOneWidget);
      expect(find.text('Elena E.'), findsOneWidget);
    });

    testWidgets('capability cell (aisha, haircut) renders checked Checkbox',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStaffCapabilityMatrix(
        staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
        services: EdenStaffCapabilityMatrixFixtures.fourServices(),
        capabilities:
            EdenStaffCapabilityMatrixFixtures.realisticCapabilities(),
        onCapabilityToggled: (_, __, ___) {},
      )));
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('cap-st-aisha-srv-haircut')),
      );
      expect(checkbox.value, true);
    });

    testWidgets('absent capability renders unchecked Checkbox',
        (tester) async {
      await tester.pumpWidget(wrap(EdenStaffCapabilityMatrix(
        staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
        services: EdenStaffCapabilityMatrixFixtures.fourServices(),
        capabilities:
            EdenStaffCapabilityMatrixFixtures.realisticCapabilities(),
        onCapabilityToggled: (_, __, ___) {},
      )));
      // Brendan doesn't have color capability.
      final checkbox = tester.widget<Checkbox>(
        find.byKey(const ValueKey('cap-st-brendan-srv-color')),
      );
      expect(checkbox.value, false);
    });
  });

  group('EdenStaffCapabilityMatrix toggle capability', () {
    testWidgets('tap unchecked checkbox fires onCapabilityToggled with true',
        (tester) async {
      String? staffId;
      String? serviceId;
      bool? canPerform;
      await tester.pumpWidget(wrap(EdenStaffCapabilityMatrix(
        staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
        services: EdenStaffCapabilityMatrixFixtures.fourServices(),
        capabilities:
            EdenStaffCapabilityMatrixFixtures.realisticCapabilities(),
        onCapabilityToggled: (s, sv, cp) {
          staffId = s;
          serviceId = sv;
          canPerform = cp;
        },
      )));
      // Brendan doesn't have color capability — checkbox is unchecked.
      await tester.tap(find.byKey(const ValueKey('cap-st-brendan-srv-color')));
      expect(staffId, 'st-brendan');
      expect(serviceId, 'srv-color');
      expect(canPerform, true);
    });

    testWidgets('tap checked checkbox fires onCapabilityToggled with false',
        (tester) async {
      bool? canPerform;
      await tester.pumpWidget(wrap(EdenStaffCapabilityMatrix(
        staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
        services: EdenStaffCapabilityMatrixFixtures.fourServices(),
        capabilities:
            EdenStaffCapabilityMatrixFixtures.realisticCapabilities(),
        onCapabilityToggled: (_, __, cp) => canPerform = cp,
      )));
      await tester.tap(find.byKey(const ValueKey('cap-st-aisha-srv-haircut')));
      expect(canPerform, false);
    });
  });

  group('EdenStaffCapabilityMatrix composes EdenServiceCatalogEntry', () {
    testWidgets('column headers show entry.name', (tester) async {
      await tester.pumpWidget(wrap(EdenStaffCapabilityMatrix(
        staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
        services: EdenStaffCapabilityMatrixFixtures.fourServices(),
        capabilities: const [],
        onCapabilityToggled: (_, __, ___) {},
      )));
      expect(find.text('Haircut'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Balayage'), findsOneWidget);
      expect(find.text('Facial'), findsOneWidget);
    });
  });

  group('EdenStaffCapabilityMatrix iPhone-narrow (390pt)', () {
    testWidgets('5 staff × 4 services scrolls horizontally', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 800,
            child: EdenStaffCapabilityMatrix(
              staff: EdenStaffCapabilityMatrixFixtures.fiveStaff(),
              services: EdenStaffCapabilityMatrixFixtures.fourServices(),
              capabilities:
                  EdenStaffCapabilityMatrixFixtures.realisticCapabilities(),
              onCapabilityToggled: (_, __, ___) {},
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // First column still visible
      expect(find.text('Aisha A.'), findsOneWidget);
    });
  });
}
