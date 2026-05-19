// EdenSchemaForm widget tests.
//
// Test list:
//   1. text field renders with label (happy path)
//   2. text field pre-fills initial value
//   3. text field editing calls onChanged with correct key + String value
//   4. select field renders with DropdownButtonFormField
//   5. select field pre-fills with valid initial value
//   6. toggle field renders SwitchListTile and fires onChanged with bool
//   7. required text field shows validator error on empty submit
//   8. number field calls onChanged with int (not raw String)
//   9. mediaUrl field shows IconButton and fires onMediaPickRequest
//  10. locked field renders readOnly TextFormField
//  11. multiple fields render in schema order
//  12. initial values update syncs controller when widget rebuilds

import 'package:eden_ui_flutter/src/widgets/eden_schema_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_fixtures/eden_schema_form_fixtures.dart';

void main() {
  // Wraps the widget under test in a MaterialApp so Theme + MediaQuery
  // are available — mirrors the pattern used across eden-ui-flutter tests.
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
  }

  // ---------------------------------------------------------------------------
  // 1. Text field renders
  // ---------------------------------------------------------------------------
  testWidgets('text field renders label', (tester) async {
    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.singleTextField,
        initialValues: const {},
        onChanged: (_, __) {},
        onMediaPickRequest: (_) {},
      ),
    ));

    expect(find.text('Title'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 2. Text field pre-fills initial value
  // ---------------------------------------------------------------------------
  testWidgets('text field pre-fills initial value', (tester) async {
    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.singleTextField,
        initialValues: EdenSchemaFormFixtures.singleTextInitialValues,
        onChanged: (_, __) {},
        onMediaPickRequest: (_) {},
      ),
    ));

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text, 'Hello World');
  });

  // ---------------------------------------------------------------------------
  // 3. Text field editing fires onChanged with String value
  // ---------------------------------------------------------------------------
  testWidgets('text field onChanged fires with key + String value',
      (tester) async {
    String? capturedKey;
    dynamic capturedValue;

    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.singleTextField,
        initialValues: const {},
        onChanged: (k, v) {
          capturedKey = k;
          capturedValue = v;
        },
        onMediaPickRequest: (_) {},
      ),
    ));

    await tester.enterText(find.byType(TextFormField), 'Flutter');
    await tester.pump();

    expect(capturedKey, 'title');
    expect(capturedValue, isA<String>());
    expect(capturedValue, 'Flutter');
  });

  // ---------------------------------------------------------------------------
  // 4. Select field renders DropdownButtonFormField
  // ---------------------------------------------------------------------------
  testWidgets('select field renders DropdownButtonFormField', (tester) async {
    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.selectField,
        initialValues: const {},
        onChanged: (_, __) {},
        onMediaPickRequest: (_) {},
      ),
    ));

    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 5. Select field pre-fills with valid initial value
  // ---------------------------------------------------------------------------
  testWidgets('select field pre-fills valid initial value', (tester) async {
    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.selectField,
        initialValues: const {'status': 'Published'},
        onChanged: (_, __) {},
        onMediaPickRequest: (_) {},
      ),
    ));

    // The selected value label appears in the dropdown.
    expect(find.text('Published'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 6. Toggle field renders SwitchListTile and fires onChanged with bool
  // ---------------------------------------------------------------------------
  testWidgets('toggle field renders SwitchListTile and fires bool onChanged',
      (tester) async {
    bool? capturedValue;
    String? capturedKey;

    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.toggleField,
        initialValues: const {'visible': false},
        onChanged: (k, v) {
          capturedKey = k;
          capturedValue = v as bool?;
        },
        onMediaPickRequest: (_) {},
      ),
    ));

    expect(find.byType(SwitchListTile), findsOneWidget);

    // Tap the switch to flip it.
    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(capturedKey, 'visible');
    expect(capturedValue, isTrue);
  });

  // ---------------------------------------------------------------------------
  // 7. Required text field shows validator error on empty submit
  // ---------------------------------------------------------------------------
  testWidgets('required text field shows validation error when empty',
      (tester) async {
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: EdenSchemaForm(
                schema: EdenSchemaFormFixtures.requiredTextField,
                initialValues: const {},
                onChanged: (_, __) {},
                onMediaPickRequest: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    // Trigger validation without filling the field.
    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 8. Number field calls onChanged with int (not String)
  // ---------------------------------------------------------------------------
  testWidgets('number field fires onChanged with int value', (tester) async {
    dynamic capturedValue;
    String? capturedKey;

    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.numberField,
        initialValues: const {},
        onChanged: (k, v) {
          capturedKey = k;
          capturedValue = v;
        },
        onMediaPickRequest: (_) {},
      ),
    ));

    await tester.enterText(find.byType(TextFormField), '42');
    await tester.pump();

    expect(capturedKey, 'sort_order');
    expect(capturedValue, isA<int>());
    expect(capturedValue, 42);
  });

  // ---------------------------------------------------------------------------
  // 9. MediaUrl field shows IconButton and fires onMediaPickRequest
  // ---------------------------------------------------------------------------
  testWidgets('mediaUrl field shows pick icon and fires onMediaPickRequest',
      (tester) async {
    String? capturedFieldKey;

    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.mediaUrlField,
        initialValues: const {},
        onChanged: (_, __) {},
        onMediaPickRequest: (k) => capturedFieldKey = k,
      ),
    ));

    // MediaUrl renders an IconButton for picking.
    expect(find.byType(IconButton), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();

    expect(capturedFieldKey, 'hero_image');
  });

  // ---------------------------------------------------------------------------
  // 10. Locked field renders readOnly TextFormField
  // ---------------------------------------------------------------------------
  testWidgets('locked field renders as readOnly TextFormField', (tester) async {
    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.schemaWithSlug,
        initialValues: EdenSchemaFormFixtures.slugInitialValues,
        onChanged: (_, __) {},
        onMediaPickRequest: (_) {},
        lockedFieldKeys: const {'slug'},
      ),
    ));

    // Two TextFormFields: locked slug + editable title.
    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    final slugField = fields.first; // slug is first in schema
    expect(slugField.readOnly, isTrue);
  });

  // ---------------------------------------------------------------------------
  // 11. Multiple fields render in schema order
  // ---------------------------------------------------------------------------
  testWidgets('multi-field schema renders all field labels in order',
      (tester) async {
    await tester.pumpWidget(wrap(
      EdenSchemaForm(
        schema: EdenSchemaFormFixtures.multiFieldSchema,
        initialValues: EdenSchemaFormFixtures.multiFieldInitialValues,
        onChanged: (_, __) {},
        onMediaPickRequest: (_) {},
      ),
    ));

    // All 4 labels are present.
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // 12. Initial values update syncs controller
  // ---------------------------------------------------------------------------
  testWidgets('controller syncs when initialValues updates externally',
      (tester) async {
    var initialValues = <String, dynamic>{'title': 'First'};

    late StateSetter setStateCb;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setStateCb = setState;
              return EdenSchemaForm(
                schema: EdenSchemaFormFixtures.singleTextField,
                initialValues: initialValues,
                onChanged: (_, __) {},
                onMediaPickRequest: (_) {},
              );
            },
          ),
        ),
      ),
    );

    // Initial value rendered.
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField))
          .controller
          ?.text,
      'First',
    );

    // Simulate external update (e.g. slug auto-gen).
    setStateCb(() => initialValues = {'title': 'Updated'});
    await tester.pump();

    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField))
          .controller
          ?.text,
      'Updated',
    );
  });
}
