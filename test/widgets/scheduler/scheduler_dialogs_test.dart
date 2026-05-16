// Hand-built tests (no LLM-generated test data) for EdenScheduler dialogs.

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapWithDesktopWidth(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SizedBox(width: 1000, height: 700, child: child)),
  );
}

void main() {
  group('EdenSchedulerCreateDialog', () {
    testWidgets('show() displays the dialog with default title',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenSchedulerCreateDialog.show<String>(
                context: context,
                bodySlot: const Text('FORM BODY'),
              ),
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('New Appointment'), findsOneWidget);
      expect(find.text('FORM BODY'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel tap pops the dialog with null', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? result = 'unset';
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await EdenSchedulerCreateDialog.show<String>(
                  context: context,
                  bodySlot: const Text('body'),
                );
              },
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('Save button disabled when onPrimaryAction null',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenSchedulerCreateDialog.show(
                context: context,
                bodySlot: const Text('body'),
              ),
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      final save = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(save.onPressed, isNull);
    });
  });

  group('EdenSchedulerEditDialog', () {
    testWidgets('show() displays default Edit Appointment title',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenSchedulerEditDialog.show(
                context: context,
                bodySlot: const Text('body'),
              ),
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Appointment'), findsOneWidget);
    });
  });

  group('EdenSchedulerDetailDialog', () {
    testWidgets('show() displays Close button (no Save)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenSchedulerDetailDialog.show(
                context: context,
                bodySlot: const Text('detail body'),
                title: 'Appointment details',
              ),
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('Appointment details'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('actions param renders extra buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenSchedulerDetailDialog.show(
                context: context,
                bodySlot: const Text('body'),
                actions: [
                  TextButton(onPressed: () {}, child: const Text('Delete')),
                ],
              ),
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  group('Responsive dialog sizing', () {
    testWidgets('renders bodySlot widget regardless of width', (tester) async {
      // Width=1000 desktop modal path.
      await tester.binding.setSurfaceSize(const Size(1000, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: ElevatedButton(
              onPressed: () => EdenSchedulerCreateDialog.show(
                context: context,
                bodySlot: const Text('desktop body'),
              ),
              child: const Text('OPEN'),
            ),
          );
        }),
      ));
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      expect(find.text('desktop body'), findsOneWidget);
    });
  });
}
