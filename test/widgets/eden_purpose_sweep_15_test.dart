// Purpose-sweep tests for TRD 40-15 — clinical & field ops.
//
// This sweep's whole value is that a purpose is a SEMANTIC CLAIM. Most of its
// fields describe a third party (the patient, the asset, the witness) or are
// observations rather than identities, so the interesting assertions here are
// the NEGATIVE ones: proving a field claims no identity it does not have.
//
// Two traps these cases are written around:
//   * `TextField.autofillHints` defaults to `const <String>[]`, NOT null
//     (40-RESEARCH.md B6). A `none` field reached through shape C keeps that
//     empty list; a field reached through shape B with a hint-free purpose gets
//     an explicit null. Both mean "no autofill identity", so every negative
//     assertion goes through [_noAutofillIdentity] rather than an `isNull` /
//     `isEmpty` check that would only cover one of the two shapes.
//   * `_inferKeyboardType` is unreachable through `TextField`
//     (`material/text_field.dart:355`, 40-RESEARCH.md B1), so a hint without a
//     keyboard is a silent no-op. Every positive case below asserts BOTH halves.

import 'package:eden_ui_flutter/src/widgets/eden_button.dart';
import 'package:eden_ui_flutter/src/widgets/eden_check_in_page.dart';
import 'package:eden_ui_flutter/src/widgets/eden_consent_flow.dart';
import 'package:eden_ui_flutter/src/widgets/eden_field_purpose.dart';
import 'package:eden_ui_flutter/src/widgets/eden_gps_status_indicator.dart';
import 'package:eden_ui_flutter/src/widgets/eden_inspection_form_page.dart';
import 'package:eden_ui_flutter/src/widgets/eden_intake_form.dart';
import 'package:eden_ui_flutter/src/widgets/eden_map_view.dart';
import 'package:eden_ui_flutter/src/widgets/eden_meter_reading_entry.dart';
import 'package:eden_ui_flutter/src/widgets/eden_permission_matrix.dart';
import 'package:eden_ui_flutter/src/widgets/eden_photo_capture_page.dart';
import 'package:eden_ui_flutter/src/widgets/eden_soap_note.dart';
import 'package:eden_ui_flutter/src/widgets/eden_visit_encounter_scaffold.dart';
import 'package:eden_ui_flutter/src/widgets/scheduler/scheduler_controller.dart';
import 'package:eden_ui_flutter/src/widgets/scheduler/scheduler_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Widget _wrap(Widget child, {double width = 900, double height = 1400}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: width, height: height, child: child),
    ),
  );
}

/// "This field claims no autofill identity."
///
/// Covers BOTH shapes the sweep produces (40-RESEARCH.md B6): shape C leaves
/// Flutter's default `const <String>[]`, shape B with a hint-free purpose
/// forwards an explicit `null`. Asserting `isNull` alone would pass vacuously
/// on one shape and fail spuriously on the other.
bool _noAutofillIdentity(Iterable<String>? hints) =>
    hints == null || hints.isEmpty;

/// Finds the `TextField` whose decoration carries [label] as its labelText.
Finder _byLabel(String label) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
      description: 'TextField(labelText: "$label")',
    );

/// Finds the `TextField` whose decoration carries [hint] as its hintText.
Finder _byHint(String hint) => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == hint,
      description: 'TextField(hintText: "$hint")',
    );

TextField _field(WidgetTester tester, Finder f) {
  expect(f, findsOneWidget);
  return tester.widget<TextField>(f);
}

/// Asserts the field resolves the full `multilineText` set — the purpose used
/// for every clinical / field-ops narrative in this TRD.
void _expectNarrative(TextField f, {required String reason}) {
  expect(_noAutofillIdentity(f.autofillHints), isTrue,
      reason: 'narrative content is an observation, not an identity: $reason');
  expect(f.keyboardType, TextInputType.multiline, reason: reason);
  expect(f.textInputAction, TextInputAction.newline,
      reason: 'multilineText must keep Enter inserting a newline: $reason');
  expect(f.textCapitalization, TextCapitalization.sentences, reason: reason);
  expect(f.obscureText, isFalse, reason: reason);
}

/// Asserts the field resolves the full `searchQuery` set.
void _expectSearch(TextField f, {required String reason}) {
  expect(_noAutofillIdentity(f.autofillHints), isTrue,
      reason: 'a search box is a query, not a fillable form field: $reason');
  expect(f.keyboardType, TextInputType.text, reason: reason);
  expect(f.textInputAction, TextInputAction.search, reason: reason);
}

void main() {
  // -------------------------------------------------------------------------
  // eden_intake_form.dart — the one genuine autofill win in this sweep.
  // -------------------------------------------------------------------------
  group('EdenIntakeForm — caller-declared question purposes', () {
    Future<TextField> pumpSingle(
      WidgetTester tester,
      EdenIntakeQuestion q,
    ) async {
      await tester.pumpWidget(_wrap(
        EdenIntakeForm(questions: <EdenIntakeQuestion>[q], onComplete: (_) {}),
      ));
      final f = find.byKey(ValueKey<String>('input_${q.id}'));
      expect(f, findsOneWidget);
      return tester.widget<TextField>(f);
    }

    testWidgets('email question emits the email hint AND the email keyboard',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_email',
          label: 'Your email',
          type: EdenIntakeQuestionType.text,
          purpose: EdenFieldPurpose.email,
        ),
      );
      expect(f.autofillHints, isNotNull);
      expect(f.autofillHints!.first, AutofillHints.email,
          reason: 'iOS and web consume ONLY hints.first '
              '(autofill.dart:688-694)');
      expect(f.keyboardType, TextInputType.emailAddress,
          reason: 'the hint alone is a no-op — TextField resolves keyboardType '
              'in its own initializer list (text_field.dart:355)');
    });

    testWidgets('personName question emits the name hint AND the name keyboard',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_name',
          label: 'Your full name',
          type: EdenIntakeQuestionType.text,
          purpose: EdenFieldPurpose.personName,
        ),
      );
      expect(f.autofillHints!.first, AutofillHints.name);
      expect(f.keyboardType, TextInputType.name,
          reason: 'AutofillHints.name requires TextInputType.name '
              '(editable_text.dart:1855-1858)');
      expect(f.textCapitalization, TextCapitalization.words);
    });

    testWidgets('telephoneNumber question emits the tel hint AND phone keyboard',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_phone',
          label: 'Your phone',
          type: EdenIntakeQuestionType.text,
          purpose: EdenFieldPurpose.telephoneNumber,
        ),
      );
      expect(f.autofillHints!.first, AutofillHints.telephoneNumber);
      expect(f.keyboardType, TextInputType.phone);
      expect(f.autocorrect, isFalse);
    });

    testWidgets('a question with no declared purpose claims no identity',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_symptoms',
          label: 'Describe your symptoms',
          type: EdenIntakeQuestionType.text,
        ),
      );
      expect(_noAutofillIdentity(f.autofillHints), isTrue,
          reason: 'default is EdenFieldPurpose.none — a schema-driven widget '
              'cannot know what a caller-supplied question asks');
      expect(f.keyboardType, TextInputType.text);
    });

    testWidgets('number question keeps its decimal keyboard via the fallback',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_weight',
          label: 'Weight',
          type: EdenIntakeQuestionType.number,
        ),
      );
      expect(f.keyboardType, const TextInputType.numberWithOptions(decimal: true),
          reason: '_effectivePurpose maps number -> decimalAmount so an '
              'unpurposed schema does not silently lose the decimal key');
      expect(_noAutofillIdentity(f.autofillHints), isTrue);
    });

    testWidgets('a declared purpose overrides the type fallback',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_zip',
          label: 'ZIP',
          type: EdenIntakeQuestionType.number,
          purpose: EdenFieldPurpose.postalCode,
        ),
      );
      expect(f.autofillHints!.first, AutofillHints.postalCode);
      expect(f.keyboardType, TextInputType.text,
          reason: 'postal codes are alphanumeric in CA/UK — the purpose, not '
              'the field type, decides');
    });

    testWidgets('longText question with no purpose stays a plain composer',
        (tester) async {
      final f = await pumpSingle(
        tester,
        const EdenIntakeQuestion(
          id: 'q_story',
          label: 'Tell us more',
          type: EdenIntakeQuestionType.longText,
        ),
      );
      expect(_noAutofillIdentity(f.autofillHints), isTrue);
      expect(f.keyboardType, TextInputType.multiline);
    });
  });

  // -------------------------------------------------------------------------
  // eden_consent_flow.dart — the sweep's most dangerous false positive.
  // -------------------------------------------------------------------------
  group('EdenConsentFlow — witness name is a THIRD PARTY', () {
    testWidgets('witness full name claims NO personName identity',
        (tester) async {
      const clauses = <EdenConsentClause>[
        EdenConsentClause(
          id: 'c1',
          title: 'Terms',
          body: 'You agree to the terms.',
        ),
      ];
      await tester.pumpWidget(_wrap(
        EdenConsentFlow(
          clauses: clauses,
          requireWitness: true,
          onComplete: (_) {},
        ),
      ));
      // Step 1: accept the clause (this is what unlocks Next — _canAdvance
      // gates on every clause being accepted).
      await tester.tap(find.byKey(const ValueKey<String>('accept_c1')));
      await tester.pump();
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();
      // Step 2: draw the primary signature.
      final pad = find.byKey(const ValueKey<String>('primary_signature_pad'));
      final gesture = await tester.startGesture(tester.getCenter(pad));
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(0, 20));
      await gesture.up();
      await tester.pump();
      await tester.tap(find.widgetWithText(EdenButton, 'Next'));
      await tester.pumpAndSettle();

      final witness = _field(
        tester,
        find.byKey(const ValueKey<String>('witness_name_field')),
      );
      expect(_noAutofillIdentity(witness.autofillHints), isTrue,
          reason: 'the witness is not the device owner. A personName hint '
              'would offer the signer their OWN saved name and could write the '
              'wrong identity into a legal consent record.');
      expect(witness.obscureText, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // eden_meter_reading_entry.dart
  // -------------------------------------------------------------------------
  group('EdenMeterReadingEntry — readings, identifiers, narrative', () {
    Future<void> pump(WidgetTester tester) =>
        tester.pumpWidget(_wrap(const EdenMeterReadingEntry()));

    testWidgets('Gallons resolves the decimal keyboard and no identity',
        (tester) async {
      await pump(tester);
      final f = _field(tester, _byLabel('Gallons'));
      expect(f.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
      expect(_noAutofillIdentity(f.autofillHints), isTrue,
          reason: 'a metered volume is equipment data, never a person');
    });

    testWidgets('Operator ID claims no username identity', (tester) async {
      await pump(tester);
      final f = _field(tester, _byLabel('Operator ID'));
      expect(_noAutofillIdentity(f.autofillHints), isTrue,
          reason: 'an employer-issued workforce ID is not a login credential; '
              '`username` would make a password manager offer, and offer to '
              'save, the sign-in identity in a field that is not one');
    });

    testWidgets('Notes resolves the multiline narrative set', (tester) async {
      await pump(tester);
      _expectNarrative(_field(tester, _byLabel('Notes (optional)')),
          reason: 'meter reading notes');
    });
  });

  // -------------------------------------------------------------------------
  // eden_inspection_form_page.dart
  // -------------------------------------------------------------------------
  group('EdenInspectionFormPage — findings and measurements', () {
    EdenInspectionForm formWith(EdenInspectionFieldType type) =>
        EdenInspectionForm(
          id: 'f1',
          name: 'Inspection',
          status: EdenInspectionFormStatus.draft,
          sections: <EdenInspectionSection>[
            EdenInspectionSection(
              id: 's1',
              title: 'Section 1',
              fields: <EdenInspectionField>[
                EdenInspectionField(id: 'fld', label: 'Finding', type: type),
              ],
            ),
          ],
          createdAt: DateTime(2026, 5, 16),
        );

    testWidgets('a text finding resolves the multiline narrative set',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EdenInspectionFormPage(form: formWith(EdenInspectionFieldType.text)),
        width: 900,
        height: 1600,
      ));
      _expectNarrative(_field(tester, find.byType(TextField)),
          reason: 'an inspector describing a third party\'s asset');
    });

    testWidgets('a number finding keeps the DECIMAL keyboard, not plain number',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EdenInspectionFormPage(form: formWith(EdenInspectionFieldType.number)),
        width: 900,
        height: 1600,
      ));
      final f = _field(tester, find.byType(TextField));
      expect(f.keyboardType,
          const TextInputType.numberWithOptions(decimal: true));
      expect(f.keyboardType, isNot(TextInputType.number),
          reason: 'decimalAmount, not quantity: quantity resolves '
              'TextInputType.number and would remove the decimal key that '
              'double.tryParse in this field depends on');
      expect(_noAutofillIdentity(f.autofillHints), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // eden_soap_note.dart — all four sections asserted individually.
  // -------------------------------------------------------------------------
  group('EdenSOAPNote — clinical narrative', () {
    testWidgets('each of the four sections resolves multilineText',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EdenSOAPNote(
          data: const EdenSoapNoteData(
            patientId: 'pt-001',
            subjective: 'S text',
            objective: 'O text',
            assessment: 'A text',
            plan: 'P text',
          ),
          patientId: 'pt-001',
        ),
        height: 2400,
      ));
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4),
          reason: 'compose mode renders S, O, A and P');
      // Assert every one individually — a findsAtLeastNWidgets style check
      // here would pass on almost any tree.
      for (var i = 0; i < 4; i++) {
        _expectNarrative(tester.widget<TextField>(fields.at(i)),
            reason: 'SOAP section index $i');
      }
    });

    testWidgets('the four sections share a HINT-FREE purpose', (tester) async {
      await tester.pumpWidget(_wrap(
        EdenSOAPNote(
          data: const EdenSoapNoteData(patientId: 'pt-001'),
          patientId: 'pt-001',
        ),
        height: 2400,
      ));
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        expect(
          _noAutofillIdentity(tester.widget<TextField>(fields.at(i)).autofillHints),
          isTrue,
          reason: 'four fields sharing ONE hint would emit four DOM elements '
              'with the same id/name (text_editing.dart:514-531). A hint-free '
              'purpose sets neither, which is what makes repetition safe '
              '(40-RESEARCH.md B7).',
        );
      }
    });
  });

  // -------------------------------------------------------------------------
  // eden_visit_encounter_scaffold.dart
  // -------------------------------------------------------------------------
  group('EdenVisitEncounterScaffold — chief complaint', () {
    testWidgets('chief complaint is narrative about the PATIENT',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EdenVisitEncounterScaffold(
          data: EdenVisitEncounterData(
            patientId: 'pt-001',
            encounterId: 'enc-1',
            encounterDate: DateTime(2026, 5, 16),
            provider: 'Dr. Roe',
            encounterType: 'Office visit',
          ),
          patientId: 'pt-001',
        ),
        width: 1200,
        height: 900,
      ));
      _expectNarrative(
        _field(tester, find.byKey(const Key('chief-complaint-input'))),
        reason: 'a clinician transcribing the patient\'s stated reason for '
            'the visit — a third party observation, not the user\'s identity',
      );
    });
  });

  // -------------------------------------------------------------------------
  // eden_check_in_page.dart
  // -------------------------------------------------------------------------
  group('EdenCheckInPage — visit notes', () {
    testWidgets('notes resolve multilineText and claim no identity',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EdenCheckInPage(
          appointment: EdenCheckInAppointment(
            id: 'a1',
            title: 'HVAC service',
            address: '1 Main St',
          ),
          gpsStatus: EdenGpsStatus.high,
        ),
        height: 1800,
      ));
      _expectNarrative(_field(tester, _byLabel('Notes (optional)')),
          reason: 'check-in/out identifies the user by session and GPS, so '
              'this page has no contact field to autofill');
    });
  });

  // -------------------------------------------------------------------------
  // eden_photo_capture_page.dart
  // -------------------------------------------------------------------------
  group('EdenPhotoCapturePage — annotation caption', () {
    testWidgets('post-capture annotation resolves multilineText',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EdenPhotoCapturePage(
          onCapture: (_) async => EdenCapturedPhoto(
            filePath: 'a.jpg',
            capturedAt: DateTime(2026, 5, 16),
          ),
          cameraPreviewBuilder: (_) =>
              const ColoredBox(color: Color(0xFF000000)),
        ),
      ));
      await tester
          .tap(find.byKey(const ValueKey('eden_photo_capture_shutter')));
      await tester.pumpAndSettle();
      _expectNarrative(_field(tester, _byHint('Add a note (optional)')),
          reason: 'a caption describing the photographed subject');
    });
  });

  // -------------------------------------------------------------------------
  // Search boxes — sidebar, map, permission matrix.
  // -------------------------------------------------------------------------
  group('Search fields resolve searchQuery', () {
    testWidgets('scheduler sidebar search', (tester) async {
      final c = EdenSchedulerController();
      addTearDown(c.dispose);
      await tester.pumpWidget(_wrap(
        EdenSchedulerSearchField(
          controller: c,
          debounce: const Duration(milliseconds: 50),
        ),
      ));
      _expectSearch(_field(tester, find.byType(TextField)),
          reason: 'scheduler sidebar filter');
    });

    testWidgets('map search is a QUERY, never an address field',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EdenMapView(
          mapBuilder: ColoredBox(color: Color(0xFFEEEEEE)),
        ),
      ));
      final f = _field(tester, _byHint('Search locations...'));
      _expectSearch(f, reason: 'map place search');
      expect(f.keyboardType, isNot(TextInputType.streetAddress),
          reason: 'an address hint here would drop an autofill panel over the '
              'map and claim the typed text is the user\'s own address');
    });

    testWidgets('permission matrix search', (tester) async {
      await tester.pumpWidget(_wrap(
        const EdenPermissionMatrix(
          permissions: <EdenPermission>[
            EdenPermission(id: 'p1', label: 'Read', category: 'Core'),
          ],
          roles: <EdenRole>[EdenRole(id: 'r1', name: 'Admin')],
        ),
      ));
      _expectSearch(_field(tester, _byHint('Search permissions...')),
          reason: 'permission matrix filter');
    });
  });

  // -------------------------------------------------------------------------
  // permission_matrix/matrix_cells.dart
  // -------------------------------------------------------------------------
  group('Break-glass justification dialog', () {
    testWidgets('justification resolves multilineText, not searchQuery',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EdenPermissionMatrix(
          permissions: const <EdenPermission>[
            EdenPermission(id: 'p1', label: 'Read', category: 'Core'),
          ],
          roles: const <EdenRole>[EdenRole(id: 'r1', name: 'Admin')],
          breakGlassMode: true,
          onBreakGlass: (_, __, ___) {},
        ),
      ));
      await tester.tap(find.byIcon(Icons.lock_open_outlined).first);
      await tester.pumpAndSettle();
      final dialogField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      _expectNarrative(_field(tester, dialogField),
          reason: 'a written audit justification, not the matrix filter the '
              'TRD table assumed');
    });
  });
}
