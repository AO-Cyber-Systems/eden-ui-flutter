import 'package:eden_ui_flutter/src/widgets/eden_field_purpose.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirror of `BrowserAutofillHints._flutterToEngineMap`
/// (`web_ui/.../text_editing/autofill_hint.dart:11-72`), restricted to the hints
/// [EdenFieldPurpose] can actually emit.
///
/// This indirection is load-bearing and easy to get wrong. The DOM input type is
/// NOT derived from the raw Flutter hint constant: `AutofillInfo.fromFrameworkMessage`
/// (`text_editing.dart:466-468`) maps `hints.first` through `flutterToEngine`
/// FIRST, and only then does `applyToDomElement` (`text_editing.dart:514-531`)
/// run the case-sensitive `autofillHint.contains('password')` check.
///
/// So `AutofillHints.newPassword` — whose raw value is the camelCase string
/// `'newPassword'`, which does NOT contain lowercase `'password'` — is still
/// correct, because it maps to `'new-password'`, which does. Asserting
/// `contains('password')` against the RAW constant would wrongly fail it.
///
/// Note the fallback at `autofill_hint.dart:81`: an unmapped hint passes through
/// unchanged. That is why inventing hint strings is forbidden — they land in the
/// DOM `autocomplete` attribute verbatim as invalid tokens.
const Map<String, String> kFlutterHintToBrowserToken = <String, String>{
  AutofillHints.birthday: 'bday',
  AutofillHints.countryName: 'country-name',
  AutofillHints.creditCardExpirationDate: 'cc-exp',
  AutofillHints.creditCardName: 'cc-name',
  AutofillHints.creditCardNumber: 'cc-number',
  AutofillHints.creditCardSecurityCode: 'cc-csc',
  AutofillHints.email: 'email',
  AutofillHints.familyName: 'family-name',
  AutofillHints.fullStreetAddress: 'street-address',
  AutofillHints.givenName: 'given-name',
  AutofillHints.jobTitle: 'organization-title',
  AutofillHints.name: 'name',
  AutofillHints.newPassword: 'new-password',
  AutofillHints.oneTimeCode: 'one-time-code',
  AutofillHints.organizationName: 'organization',
  AutofillHints.password: 'current-password',
  AutofillHints.postalCode: 'postal-code',
  AutofillHints.streetAddressLine1: 'address-line1',
  AutofillHints.streetAddressLine2: 'address-line2',
  AutofillHints.telephoneNumber: 'tel',
  AutofillHints.username: 'username',
  // NOT in the engine map: AutofillHints.addressCity and AutofillHints.addressState
  // pass through verbatim (autofill_hint.dart:81). See 40-01-SUMMARY.md.
};

/// Reproduces `BrowserAutofillHints.flutterToEngine` (`autofill_hint.dart:79-82`),
/// including its pass-through fallback for unmapped hints.
String browserTokenFor(String flutterHint) =>
    kFlutterHintToBrowserToken[flutterHint] ?? flutterHint;

/// Hand-written expectation table for every purpose that carries MORE THAN ONE
/// hint. Index 0 is the token iOS and web consume; everything after it is an
/// Android-only extra (`services/autofill.dart:688-694`).
///
/// This map is written by hand on purpose — no fuzzing, no generated data. If a
/// new multi-hint purpose is added, case 6 fails until this table is updated,
/// which forces the hint ORDER to be a deliberate decision.
const Map<EdenFieldPurpose, List<String>> kExpectedMultiHintOrder =
    <EdenFieldPurpose, List<String>>{
  EdenFieldPurpose.email: <String>[
    AutofillHints.email,
    AutofillHints.username,
  ],
  EdenFieldPurpose.givenName: <String>[
    AutofillHints.givenName,
    AutofillHints.name,
  ],
  EdenFieldPurpose.familyName: <String>[
    AutofillHints.familyName,
    AutofillHints.name,
  ],
  EdenFieldPurpose.streetAddressLine1: <String>[
    AutofillHints.streetAddressLine1,
    AutofillHints.fullStreetAddress,
  ],
  EdenFieldPurpose.creditCardName: <String>[
    AutofillHints.creditCardName,
    AutofillHints.name,
  ],
};

/// The purposes whose hints include `AutofillHints.name`.
///
/// `editable_text.dart:1855-1858` names this coupling verbatim:
/// "`AutofillHints.name` requires `TextInputType.name`".
const List<EdenFieldPurpose> kNameHintPurposes = <EdenFieldPurpose>[
  EdenFieldPurpose.personName,
  EdenFieldPurpose.givenName,
  EdenFieldPurpose.familyName,
  EdenFieldPurpose.creditCardName,
];

/// Purposes that must never offer autocorrect or predictive suggestions:
/// leaking a password or a one-time code into the keyboard's learning
/// dictionary is a real disclosure.
const List<EdenFieldPurpose> kSecretPurposes = <EdenFieldPurpose>[
  EdenFieldPurpose.currentPassword,
  EdenFieldPurpose.newPassword,
  EdenFieldPurpose.newPasswordConfirm,
  EdenFieldPurpose.oneTimeCode,
];

void main() {
  group('EdenFieldPurpose', () {
    // Case 1
    test('every obscured purpose emits a password-family hint FIRST', () {
      for (final EdenFieldPurpose purpose in EdenFieldPurpose.values) {
        final EdenFieldSemantics semantics = purpose.semantics;
        if (!semantics.obscureText) {
          continue;
        }
        expect(
          semantics.autofillHints,
          isNotNull,
          reason:
              '${purpose.name} is obscured but emits no hints. Flutter web '
              'derives the DOM input type from the hint string, never from '
              'obscureText (text_editing.dart:514-531), so a hintless obscured '
              'field renders as type="text" — plaintext in the DOM and '
              'invisible to password managers.',
        );
        final String firstHint = semantics.autofillHints!.first;
        final String token = browserTokenFor(firstHint);
        expect(
          token.contains('password'),
          isTrue,
          reason:
              '${purpose.name} is obscured, but its FIRST hint "$firstHint" '
              'maps to the browser token "$token", which does not contain the '
              'substring "password". text_editing.dart:466-468 maps hints.first '
              'through BrowserAutofillHints.flutterToEngine, then '
              'text_editing.dart:514-531 sets element.type = '
              'autofillHint.contains("password") ? "password" : "text". '
              'autofill.dart:688-694 says iOS and web read only the FIRST hint '
              '— so this field would render as type="text": the secret would be '
              'plaintext in the DOM and invisible to 1Password.',
        );
      }
    });

    // Case 2
    test('none emits null autofillHints', () {
      expect(
        EdenFieldPurpose.none.semantics.autofillHints,
        isNull,
        reason:
            'none is the explicit, greppable opt-out. It must resolve to null '
            'hints — "deliberately no autofill purpose", not "unset".',
      );
    });

    // Case 3
    test('no purpose emits an empty hint list', () {
      for (final EdenFieldPurpose purpose in EdenFieldPurpose.values) {
        final List<String>? hints = purpose.semantics.autofillHints;
        if (hints == null) {
          continue;
        }
        expect(
          hints,
          isNotEmpty,
          reason:
              '${purpose.name} emits an empty hint list. Empty is an ambiguous '
              'third state between "has a purpose" and "deliberately has none" '
              '— use null for the latter.',
        );
      }
    });

    // Case 4
    test('every purpose resolves a non-null keyboardType', () {
      for (final EdenFieldPurpose purpose in EdenFieldPurpose.values) {
        final TextInputType keyboardType = purpose.semantics.keyboardType;
        expect(
          keyboardType,
          isNotNull,
          reason:
              '${purpose.name} must resolve a concrete keyboardType. That is '
              'the whole point of the coupling fix: EditableText only calls '
              '_inferKeyboardType (editable_text.dart:2225) when keyboardType '
              'is null, so the hint and the keyboard can never disagree if the '
              'purpose always supplies both.',
        );
        expect(
          keyboardType,
          isNot(TextInputType.none),
          reason:
              '${purpose.name} resolves TextInputType.none, which suppresses '
              'the system keyboard entirely. No purpose in this enum wants '
              'that.',
        );
      }
    });

    // Case 5a
    test('email resolves emailAddress keyboard and email hint first', () {
      final EdenFieldSemantics semantics = EdenFieldPurpose.email.semantics;
      expect(
        semantics.keyboardType,
        TextInputType.emailAddress,
        reason:
            'editable_text.dart:1855-1858 — "AutofillHints.email works only '
            'with TextInputType.emailAddress".',
      );
      expect(
        semantics.autofillHints!.first,
        AutofillHints.email,
        reason:
            'autofill.dart:688-694 — iOS and web consume only the FIRST hint. '
            'AutofillHints.username is the Android-only extra and must follow.',
      );
    });

    // Case 5b
    test('personName resolves TextInputType.name', () {
      for (final EdenFieldPurpose purpose in kNameHintPurposes) {
        final EdenFieldSemantics semantics = purpose.semantics;
        expect(
          semantics.autofillHints,
          contains(AutofillHints.name),
          reason:
              '${purpose.name} is listed in kNameHintPurposes but does not '
              'actually emit AutofillHints.name — update the table or the enum.',
        );
        expect(
          semantics.keyboardType,
          TextInputType.name,
          reason:
              'editable_text.dart:1855-1858 — "AutofillHints.name requires '
              'TextInputType.name". ${purpose.name} emits that hint, so it must '
              'pair it with that keyboard.',
        );
      }
    });

    // Case 6
    test('hint order is iOS/web-first', () {
      // Every purpose that actually carries more than one hint must be covered
      // by the hand-written table — a new one cannot slip through unordered.
      final Set<EdenFieldPurpose> actualMultiHint = EdenFieldPurpose.values
          .where((EdenFieldPurpose p) =>
              (p.semantics.autofillHints?.length ?? 0) > 1)
          .toSet();
      expect(
        actualMultiHint,
        kExpectedMultiHintOrder.keys.toSet(),
        reason:
            'The set of multi-hint purposes drifted from the hand-written '
            'expectation table. Hint order is load-bearing '
            '(autofill.dart:688-694) — add the new purpose to '
            'kExpectedMultiHintOrder with its order decided deliberately.',
      );

      kExpectedMultiHintOrder.forEach(
        (EdenFieldPurpose purpose, List<String> expected) {
          final List<String> hints = purpose.semantics.autofillHints!;
          expect(
            hints.first,
            expected.first,
            reason:
                '${purpose.name} must emit "${expected.first}" FIRST — it is '
                'the only hint iOS and web translate '
                '(autofill.dart:688-694).',
          );
          expect(
            hints,
            expected,
            reason:
                '${purpose.name} hint order changed. Android reads ALL hints, '
                'so the extras after index 0 must stay after index 0 '
                '(autofill.dart:688-694).',
          );
          expect(
            hints.sublist(1),
            expected.sublist(1),
            reason:
                'The Android-only extras for ${purpose.name} must appear AFTER '
                'the iOS/web token, never before it.',
          );
        },
      );
    });

    // Case 7
    test(
        'newPassword and newPasswordConfirm both resolve '
        'AutofillHints.newPassword', () {
      const List<String> expected = <String>[AutofillHints.newPassword];
      expect(
        EdenFieldPurpose.newPassword.semantics.autofillHints,
        expected,
        reason:
            'text_editing.dart:514-531 — the hint string becomes the DOM name, '
            'id and autocomplete token. new-password is the standard signup '
            'token.',
      );
      expect(
        EdenFieldPurpose.newPasswordConfirm.semantics.autofillHints,
        expected,
        reason:
            'Locked decision (40-RESEARCH.md, consumed by TRD 40-10): confirm '
            'shares AutofillHints.newPassword with newPassword even though '
            'text_editing.dart:514-531 sets element.id from the hint, so the '
            'two fields emit duplicate DOM ids. Two '
            'autocomplete="new-password" inputs is the standard HTML signup '
            'shape; dropping the hint would make confirm type="text" — '
            'plaintext in the DOM — and inventing a hint string would emit an '
            'invalid autocomplete token. Changing this must be a deliberate '
            'edit of this test.',
      );
    });

    // Case 8
    test('password and one-time-code purposes disable autocorrect and '
        'suggestions', () {
      for (final EdenFieldPurpose purpose in kSecretPurposes) {
        final EdenFieldSemantics semantics = purpose.semantics;
        expect(
          semantics.autocorrect,
          isFalse,
          reason:
              '${purpose.name} must not run autocorrect — it would rewrite a '
              'secret the user typed correctly.',
        );
        expect(
          semantics.enableSuggestions,
          isFalse,
          reason:
              '${purpose.name} must not offer predictive suggestions — they '
              'persist the secret in the keyboard learning dictionary.',
        );
      }
    });

    // Case 9
    test('creditCardSecurityCode is NOT obscured', () {
      expect(
        EdenFieldPurpose.creditCardSecurityCode.semantics.obscureText,
        isFalse,
        reason:
            'editable_text.dart:2641-2646 — obscureText: true HARD-DISABLES '
            'copy AND cut and is not configurable. A CVV is conventionally '
            'visible, so obscuring it would cost the user copy/cut for no '
            'security benefit.',
      );
    });

    // Case 10
    test('every member has a distinct semantics identity or a documented alias',
        () {
      final Map<String, List<EdenFieldPurpose>> byHintList =
          <String, List<EdenFieldPurpose>>{};
      for (final EdenFieldPurpose purpose in EdenFieldPurpose.values) {
        final List<String>? hints = purpose.semantics.autofillHints;
        if (hints == null) {
          continue;
        }
        byHintList
            .putIfAbsent(hints.join(' '), () => <EdenFieldPurpose>[])
            .add(purpose);
      }

      final List<List<EdenFieldPurpose>> aliases = byHintList.values
          .where((List<EdenFieldPurpose> group) => group.length > 1)
          .toList();

      expect(
        aliases,
        hasLength(1),
        reason:
            'Exactly one documented alias group is allowed. Found '
            '${aliases.map((List<EdenFieldPurpose> g) => g.map((EdenFieldPurpose p) => p.name).toList()).toList()}. '
            'Two purposes sharing a hint emit duplicate DOM ids '
            '(text_editing.dart:514-531) — that trade-off was accepted only '
            'for the new-password pair.',
      );
      expect(
        aliases.single.toSet(),
        <EdenFieldPurpose>{
          EdenFieldPurpose.newPassword,
          EdenFieldPurpose.newPasswordConfirm,
        },
        reason:
            'The only permitted hint-list alias is newPassword / '
            'newPasswordConfirm — see the locked duplicate-DOM-id decision on '
            'EdenFieldPurpose.newPasswordConfirm.',
      );
    });
  });
}
