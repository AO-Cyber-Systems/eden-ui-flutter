import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eden_ui_flutter/eden_ui.dart';

import '_fixtures/eden_intake_form_builder_fixtures.dart';

Widget wrap(Widget child, {double width = 1200, double height = 800}) =>
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, height: height, child: child),
      ),
    );

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  group('EdenIntakeFieldSchema.copyWith', () {
    test('preserves all other fields when only label changes', () {
      const original = EdenIntakeFieldSchema(
        id: 'f1',
        type: EdenIntakeFieldType.shortText,
        label: 'Old label',
        required: true,
      );
      final updated = original.copyWith(label: 'New label');
      expect(updated.id, 'f1');
      expect(updated.type, EdenIntakeFieldType.shortText);
      expect(updated.required, true);
      expect(updated.label, 'New label');
    });

    test('clearVisibleWhen sets visibleWhen to null', () {
      const original = EdenIntakeFieldSchema(
        id: 'f1',
        type: EdenIntakeFieldType.shortText,
        label: 'Test',
        visibleWhen:
            EdenIntakeVisibilityRule(fieldId: 'f0', equals: 'something'),
      );
      final cleared = original.copyWith(clearVisibleWhen: true);
      expect(cleared.visibleWhen, isNull);
    });
  });

  group('EdenIntakeFormSchema.copyWith', () {
    test('preserves id + name + version when fields change', () {
      const original = EdenIntakeFormSchema(
        id: 'orig',
        name: 'Original',
        version: 3,
      );
      final updated = original.copyWith(fields: [
        const EdenIntakeFieldSchema(
          id: 'f1',
          type: EdenIntakeFieldType.shortText,
          label: 'New field',
        ),
      ]);
      expect(updated.id, 'orig');
      expect(updated.name, 'Original');
      expect(updated.version, 3);
      expect(updated.fields.length, 1);
    });
  });

  group('EdenIntakeFormBuilder 3-pane layout (≥900pt)', () {
    testWidgets('renders 9 Draggable palette entries', (tester) async {
      await _setLargeSurface(tester);
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      // 9 field types = 9 palette draggable entries
      expect(
        find.byType(Draggable<EdenIntakeFieldType>),
        findsNWidgets(9),
      );
    });

    testWidgets('renders 4 canvas rows for 4-field starter schema',
        (tester) async {
      await _setLargeSurface(tester);
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Date of birth'), findsOneWidget);
      expect(find.text('Known allergies or sensitivities'), findsOneWidget);
      expect(find.text('Sign here'), findsOneWidget);
    });

    testWidgets('required fields show a "Required" chip', (tester) async {
      await _setLargeSurface(tester);
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      // 3 required fields in starter (Full name, DOB, Sign here)
      expect(find.text('Required'), findsAtLeastNWidgets(1));
    });

    testWidgets('Config pane shows empty hint when no field selected',
        (tester) async {
      await _setLargeSurface(tester);
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      expect(find.text('Tap a field to configure'), findsOneWidget);
    });

    testWidgets('renders Publish button', (tester) async {
      await _setLargeSurface(tester);
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      expect(find.text('Publish'), findsOneWidget);
    });
  });

  group('EdenIntakeFormBuilder tabbed layout (<900pt)', () {
    testWidgets('renders TabBar at 600pt width', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(
        EdenIntakeFormBuilder(
          schema: schema,
          onSchemaChanged: (s) => schema = s,
        ),
        width: 600,
        height: 800,
      ));
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('default tab index is 1 (Canvas)', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(
        EdenIntakeFormBuilder(
          schema: schema,
          onSchemaChanged: (s) => schema = s,
        ),
        width: 600,
        height: 800,
      ));
      // Canvas is the default tab — fields visible
      expect(find.text('Full name'), findsOneWidget);
    });

    testWidgets('all 3 tab labels exist', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(
        EdenIntakeFormBuilder(
          schema: schema,
          onSchemaChanged: (s) => schema = s,
        ),
        width: 600,
        height: 800,
      ));
      expect(find.text('Palette'), findsOneWidget);
      expect(find.text('Canvas'), findsOneWidget);
      expect(find.text('Config'), findsOneWidget);
    });
  });

  group('EdenIntakeFormBuilder add field', () {
    testWidgets('addField appends a new shortText field', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.addField(EdenIntakeFieldType.shortText);
      await tester.pump();
      expect(schema.fields.length, 5);
      expect(schema.fields.last.type, EdenIntakeFieldType.shortText);
      expect(schema.fields.last.label, startsWith('New '));
    });

    testWidgets('addField generates unique id', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      final originalIds = schema.fields.map((f) => f.id).toSet();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.addField(EdenIntakeFieldType.yesNo);
      await tester.pump();
      expect(schema.fields.last.id, isNot(isIn(originalIds)));
      expect(schema.fields.last.id, isNotEmpty);
    });
  });

  group('EdenIntakeFormBuilder reorder field', () {
    testWidgets('reorderField via state method moves field', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      final originalFirst = schema.fields.first.id;
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.reorderField(0, 2);
      await tester.pump();
      // After Flutter quirk (newIdx -= 1 when newIdx > oldIdx), the first
      // field is now at index 1.
      expect(schema.fields[1].id, originalFirst);
    });

    testWidgets('reorderField fires onSchemaChanged', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      int callCount = 0;
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) {
          schema = s;
          callCount++;
        },
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.reorderField(0, 1);
      await tester.pump();
      expect(callCount, greaterThanOrEqualTo(1));
    });
  });

  group('EdenIntakeFormBuilder remove field', () {
    testWidgets('removeField shortens schema', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.removeField('f1');
      await tester.pump();
      expect(schema.fields.length, 3);
      expect(schema.fields.any((f) => f.id == 'f1'), isFalse);
    });
  });

  group('EdenIntakeFormBuilder edit field', () {
    testWidgets('updateField updates label', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.updateField('f1', (f) => f.copyWith(label: 'Updated label'));
      await tester.pump();
      expect(schema.fields.first.label, 'Updated label');
    });

    testWidgets('updateField toggles required', (tester) async {
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      // f3 is "Known allergies" — required is false.
      state.updateField('f3', (f) => f.copyWith(required: true));
      await tester.pump();
      expect(schema.fields[2].required, isTrue);
    });

    testWidgets('updateField with options for singleChoice', (tester) async {
      EdenIntakeFormSchema schema = const EdenIntakeFormSchema(
        id: 'test',
        name: 'Test',
        fields: [
          EdenIntakeFieldSchema(
            id: 'f1',
            type: EdenIntakeFieldType.singleChoice,
            label: 'Pick one',
          ),
        ],
      );
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
      )));
      final state = tester.state<EdenIntakeFormBuilderState>(
          find.byType(EdenIntakeFormBuilder));
      state.updateField('f1', (f) => f.copyWith(options: ['A', 'B', 'C']));
      await tester.pump();
      expect(schema.fields.first.options, ['A', 'B', 'C']);
    });
  });

  group('EdenIntakeFormBuilder visibleWhen upstream filter', () {
    test('upstream-fields-only filter returns only earlier fields', () {
      const schema = EdenIntakeFormSchema(
        id: 'test',
        name: 'Test',
        fields: [
          EdenIntakeFieldSchema(
              id: 'f1',
              type: EdenIntakeFieldType.shortText,
              label: 'First'),
          EdenIntakeFieldSchema(
              id: 'f2',
              type: EdenIntakeFieldType.yesNo,
              label: 'Second'),
          EdenIntakeFieldSchema(
              id: 'f3',
              type: EdenIntakeFieldType.shortText,
              label: 'Third'),
        ],
      );
      // The widget exposes upstreamFieldsFor(schema, selectedId) — public for testing.
      final upstream = upstreamFieldsFor(schema, 'f2');
      expect(upstream.length, 1);
      expect(upstream.first.id, 'f1');
    });
  });

  group('EdenIntakeFormBuilder publish callback', () {
    testWidgets('tap Publish fires onPublish', (tester) async {
      int publishCount = 0;
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(EdenIntakeFormBuilder(
        schema: schema,
        onSchemaChanged: (s) => schema = s,
        onPublish: () => publishCount++,
      )));
      await tester.tap(find.text('Publish'));
      await tester.pump();
      expect(publishCount, 1);
    });
  });

  group('EdenIntakeFormBuilder iPhone-narrow (390pt)', () {
    testWidgets('tabbed layout with no overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      EdenIntakeFormSchema schema =
          EdenIntakeFormBuilderFixtures.salonStarter();
      await tester.pumpWidget(wrap(
        EdenIntakeFormBuilder(
          schema: schema,
          onSchemaChanged: (s) => schema = s,
        ),
        width: 390,
        height: 800,
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
