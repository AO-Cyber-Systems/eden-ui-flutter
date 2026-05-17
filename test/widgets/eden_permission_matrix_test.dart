import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_permission_matrix_fixtures.dart';

Widget wrap(Widget child, {double width = 800, double height = 600}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

void main() {
  group('EdenFederalRoles preset', () {
    test('exposes 3 federal roles', () {
      expect(EdenFederalRoles.allFederal.length, 3);
      expect(EdenFederalRoles.allFederal.map((r) => r.id), [
        'federal-privileged-user',
        'federal-isso',
        'federal-issm',
      ]);
    });

    test('privilegedUser has user management + audit permissions', () {
      expect(
        EdenFederalRoles.privilegedUser.permissions,
        containsAll(<String>['create_user', 'modify_user', 'view_audit_log']),
      );
    });

    test('isso has audit oversight permissions', () {
      expect(
        EdenFederalRoles.isso.permissions,
        containsAll(<String>[
          'view_audit_log',
          'export_audit_log',
          'modify_security_policy',
        ]),
      );
    });

    test('issm has approve_break_glass permission', () {
      expect(
        EdenFederalRoles.issm.permissions.contains('approve_break_glass'),
        isTrue,
      );
    });
  });

  group('EdenPermissionMatrix — additive params + backwards compat', () {
    testWidgets('breakGlassMode defaults to false (existing call sites unchanged)',
        (tester) async {
      const matrix = EdenPermissionMatrix(
        permissions: [],
        roles: [],
      );
      expect(matrix.breakGlassMode, isFalse);
      expect(matrix.onBreakGlass, isNull);
    });

    testWidgets('breakGlassMode=false does NOT render break-glass icons',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
      )));
      expect(find.byIcon(Icons.lock_open_outlined), findsNothing);
    });
  });

  group('EdenPermissionMatrix — break-glass mode enabled', () {
    testWidgets('break-glass icons render on denied cells when enabled',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
        breakGlassMode: true,
      )));
      // At least 1 denied cell exists (modify_security_policy denied for
      // privilegedUser by default per fixtures).
      expect(find.byIcon(Icons.lock_open_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping break-glass icon opens justification dialog',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
        breakGlassMode: true,
        onBreakGlass: (_, __, ___) {},
      )));
      await tester.tap(find.byIcon(Icons.lock_open_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Break-glass override'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('confirm disabled until justification >= 20 chars',
        (tester) async {
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
        breakGlassMode: true,
        onBreakGlass: (_, __, ___) {},
      )));
      await tester.tap(find.byIcon(Icons.lock_open_outlined).first);
      await tester.pumpAndSettle();
      // Confirm button initially disabled.
      final confirm = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirm.onPressed, isNull);
      // Type a too-short justification.
      await tester.enterText(find.byType(TextField),
          EdenPermissionMatrixFixtures.breakGlassJustificationTooShort);
      await tester.pump();
      final confirmShort = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmShort.onPressed, isNull);
      // Type a valid justification.
      await tester.enterText(
        find.byType(TextField),
        EdenPermissionMatrixFixtures.breakGlassJustificationOk,
      );
      await tester.pump();
      final confirmOk = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm'),
      );
      expect(confirmOk.onPressed, isNotNull);
    });

    testWidgets(
        'confirm with valid justification fires onBreakGlass(roleId, permId, justification)',
        (tester) async {
      String? capturedRole;
      String? capturedPerm;
      String? capturedJust;
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
        breakGlassMode: true,
        onBreakGlass: (r, p, j) {
          capturedRole = r;
          capturedPerm = p;
          capturedJust = j;
        },
      )));
      await tester.tap(find.byIcon(Icons.lock_open_outlined).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        EdenPermissionMatrixFixtures.breakGlassJustificationOk,
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
      await tester.pumpAndSettle();
      expect(capturedRole, isNotNull);
      expect(capturedPerm, isNotNull);
      expect(capturedJust,
          EdenPermissionMatrixFixtures.breakGlassJustificationOk);
    });

    testWidgets('cancel closes dialog without firing callback', (tester) async {
      var fired = false;
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
        breakGlassMode: true,
        onBreakGlass: (_, __, ___) => fired = true,
      )));
      await tester.tap(find.byIcon(Icons.lock_open_outlined).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(fired, isFalse);
      expect(find.text('Break-glass override'), findsNothing);
    });
  });

  group('EdenPermissionMatrix — Section 508 a11y', () {
    testWidgets('break-glass icon has Semantics announcing override role + permission',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(EdenPermissionMatrix(
        permissions: EdenPermissionMatrixFixtures.baselinePermissions,
        roles: EdenFederalRoles.allFederal,
        breakGlassMode: true,
      )));
      final hits = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label?.contains('Break-glass override') ?? false),
      );
      expect(hits, findsAtLeastNWidgets(1));
      handle.dispose();
    });
  });
}
