// test/widgets/eden_purpose_sweep_10_test.dart
//
// TRD 40-10 -- migration sweep 2 of 8: the auth and account pages.
//
// These five pages are the ones a password manager actually cares about, so the
// sweep is tested rather than assumed. Three things are covered:
//
//   1. RESOLVED SEMANTICS. Every field's autofill hints, keyboard type, obscure
//      flag and input action, read back off the constructed `TextField`. Two of
//      them are a pre-existing DEFECT REPAIR, not a cosmetic change -- see
//      `kKeyboardWasWrong` below.
//   2. THE SAVE PATH. Hints only make a field FILLABLE. A credential is never
//      SAVED without `TextInput.finishAutofillContext`, and it must fire ONLY on
//      a success path. Most of the cases here are negatives: no commit on a
//      rejected login, a client-side validation failure, or a dev-login bypass.
//   3. CLIPBOARD POSTURE. Obscured fields cannot copy (framework-enforced);
//      ordinary ones still can. Both asserted with a REAL non-collapsed
//      selection, because `copyEnabled` is
//      `!obscureText && !selection.isCollapsed` and an empty selection makes
//      every field report false (40-RESEARCH.md Appendix A).
//
// Fixtures are hand-built inline -- no generated data, no property-based
// library -- following `test/widgets/eden_input_test.dart`.

import 'dart:async';

import 'package:eden_ui_flutter/eden_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Reused, NOT re-declared. `AutofillHints.newPassword` is the camelCase string
// `newPassword`, which does NOT contain lowercase `password`; the engine maps
// `hints.first` through `BrowserAutofillHints.flutterToEngine` FIRST
// (`text_editing.dart:466-468`) and only then runs the case-sensitive
// `contains('password')` check that decides the DOM input type (`:514-531`).
// A second copy of that map here could drift away from the one TRD 40-01 pins.
import 'eden_field_purpose_test.dart' show browserTokenFor;

/// One field's expected resolved semantics, keyed by the `hintText` it renders
/// -- which is also its DOM `placeholder` on web (`text_editing.dart:471`).
///
/// Keyed by hint rather than by index: an index-based finder silently retargets
/// the moment a field is inserted above it.
class FieldCase {
  const FieldCase({
    required this.hint,
    required this.label,
    required this.purpose,
    required this.firstHint,
    required this.keyboardType,
    required this.obscure,
    required this.action,
  });

  /// The field's `hintText`, used as its finder.
  final String hint;

  /// The visible label, for test names.
  final String label;

  /// The purpose assigned by this TRD.
  final EdenFieldPurpose purpose;

  /// `autofillHints.first` -- the ONLY hint iOS and web consume
  /// (`autofill.dart:688-694`).
  final String firstHint;

  final TextInputType keyboardType;
  final bool obscure;
  final TextInputAction action;
}

/// The two fields this sweep actually REPAIRS rather than merely annotates.
///
/// Both carried (or needed) `AutofillHints.name` while resolving
/// `TextInputType.text`, because `TextField` collapses a null `keyboardType` in
/// its own initializer list (`text_field.dart:355`) before `EditableText` can
/// run `_inferKeyboardType`. `editable_text.dart:1855-1858` states that
/// `AutofillHints.name` "requires TextInputType.name", so these were broken for
/// iOS autofill while looking correct in review (40-RESEARCH.md Appendix B1).
const Map<String, String> kKeyboardWasWrong = <String, String>{
  'Your name': 'EdenSignUpPage display name: TextInputType.text -> name',
  'Your display name': 'EdenProfilePage display name: TextInputType.text -> name',
};

// ---------------------------------------------------------------------------
// Expected resolved semantics, one table per page.
// ---------------------------------------------------------------------------

const List<FieldCase> kLoginFields = <FieldCase>[
  FieldCase(
    hint: 'you@example.com',
    label: 'Email',
    purpose: EdenFieldPurpose.email,
    firstHint: AutofillHints.email,
    keyboardType: TextInputType.emailAddress,
    obscure: false,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Enter your password',
    label: 'Password',
    purpose: EdenFieldPurpose.currentPassword,
    firstHint: AutofillHints.password,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.done,
  ),
];

const List<FieldCase> kSignUpFields = <FieldCase>[
  FieldCase(
    hint: 'Your name',
    label: 'Display name',
    purpose: EdenFieldPurpose.personName,
    firstHint: AutofillHints.name,
    keyboardType: TextInputType.name,
    obscure: false,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'you@example.com',
    label: 'Email',
    purpose: EdenFieldPurpose.email,
    firstHint: AutofillHints.email,
    keyboardType: TextInputType.emailAddress,
    obscure: false,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Create a password',
    label: 'Password',
    purpose: EdenFieldPurpose.newPassword,
    firstHint: AutofillHints.newPassword,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Re-enter your password',
    label: 'Confirm password',
    purpose: EdenFieldPurpose.newPasswordConfirm,
    firstHint: AutofillHints.newPassword,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.done,
  ),
];

const List<FieldCase> kResetFields = <FieldCase>[
  FieldCase(
    hint: 'Enter your new password',
    label: 'New password',
    purpose: EdenFieldPurpose.newPassword,
    firstHint: AutofillHints.newPassword,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Re-enter your new password',
    label: 'Confirm password',
    purpose: EdenFieldPurpose.newPasswordConfirm,
    firstHint: AutofillHints.newPassword,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.done,
  ),
];

const List<FieldCase> kForgotFields = <FieldCase>[
  FieldCase(
    hint: 'you@example.com',
    label: 'Email',
    purpose: EdenFieldPurpose.email,
    firstHint: AutofillHints.email,
    keyboardType: TextInputType.emailAddress,
    obscure: false,
    action: TextInputAction.next,
  ),
];

const List<FieldCase> kProfileFields = <FieldCase>[
  FieldCase(
    hint: 'Your display name',
    label: 'Display name',
    purpose: EdenFieldPurpose.personName,
    firstHint: AutofillHints.name,
    keyboardType: TextInputType.name,
    obscure: false,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'your@email.com',
    label: 'Email',
    purpose: EdenFieldPurpose.email,
    firstHint: AutofillHints.email,
    keyboardType: TextInputType.emailAddress,
    obscure: false,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Optional',
    label: 'Phone',
    purpose: EdenFieldPurpose.telephoneNumber,
    firstHint: AutofillHints.telephoneNumber,
    keyboardType: TextInputType.phone,
    obscure: false,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Enter your current password',
    label: 'Current password',
    purpose: EdenFieldPurpose.currentPassword,
    firstHint: AutofillHints.password,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.done,
  ),
  FieldCase(
    hint: 'Choose a new password',
    label: 'New password',
    purpose: EdenFieldPurpose.newPassword,
    firstHint: AutofillHints.newPassword,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.next,
  ),
  FieldCase(
    hint: 'Re-enter your new password',
    label: 'Confirm new password',
    purpose: EdenFieldPurpose.newPasswordConfirm,
    firstHint: AutofillHints.newPassword,
    keyboardType: TextInputType.text,
    obscure: true,
    action: TextInputAction.done,
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Finds a `TextField` by the hint it renders. Deliberately not `.at(index)`.
Finder fieldByHint(String hint) => find.byWidgetPredicate(
      (Widget w) => w is TextField && w.decoration?.hintText == hint,
      description: 'TextField(hintText: "$hint")',
    );

Widget hostLogin({
  Future<void> Function(String, String)? onLogin,
  EdenDevLoginConfig? devLoginConfig,
}) =>
    MaterialApp(
      home: EdenLoginPage(
        onLogin: onLogin ?? (String e, String p) async {},
        devLoginConfig: devLoginConfig,
      ),
    );

Widget hostSignUp({Future<void> Function(String, String, String)? onSignUp}) =>
    MaterialApp(
      home: EdenSignUpPage(
        onSignUp: onSignUp ?? (String n, String e, String p) async {},
      ),
    );

Widget hostReset({Future<void> Function(String)? onResetPassword}) =>
    MaterialApp(
      home: EdenResetPasswordPage(
        onResetPassword: onResetPassword ?? (String p) async {},
      ),
    );

Widget hostForgot({
  Future<void> Function(String)? onSendResetLink,
}) =>
    MaterialApp(
      home: EdenForgotPasswordPage(
        onSendResetLink: onSendResetLink ?? (String e) async {},
      ),
    );

Widget hostProfile({
  Future<void> Function(String, String)? onChangePassword,
}) =>
    MaterialApp(
      home: Scaffold(
        body: EdenProfilePage(
          name: 'Ada Lovelace',
          email: 'ada@example.com',
          onChangePassword: onChangePassword,
        ),
      ),
    );

/// Gives the test a viewport tall enough to render the whole profile page.
///
/// The default 800x600 surface puts "Update Password" at y=993 -- outside the
/// root render box entirely -- so `tap()` silently misses it and the handler
/// under test never runs. Scrolling would work too, but resizing keeps every
/// field hit-testable for the whole test.
void useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Every framework-to-platform `SystemChannels.textInput` call made from the
/// moment this is installed.
///
/// MUST be installed only AFTER the last `tester.enterText`. It REPLACES
/// `TestTextInput`'s own handler, and `TestTextInput.updateEditingValue`
/// asserts that handler is still registered -- so text entry afterwards would
/// fail rather than silently no-op.
List<MethodCall> spyOnTextInput(
  WidgetTester tester, {
  void Function(MethodCall call)? onCall,
}) {
  final List<MethodCall> calls = <MethodCall>[];
  final TestDefaultBinaryMessenger messenger =
      tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.textInput,
      (MethodCall call) async {
    calls.add(call);
    onCall?.call(call);
    return null;
  });
  addTearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.textInput, null);
    tester.binding.testTextInput.register();
  });
  return calls;
}

/// The save calls only -- `TextInput.finishAutofillContext` with
/// `shouldSave: true`. `cancel()` sends the same method with `false`, so the
/// argument is checked, not just the method name.
List<MethodCall> savesIn(List<MethodCall> calls) => calls
    .where((MethodCall c) =>
        c.method == 'TextInput.finishAutofillContext' && c.arguments == true)
    .toList();

void main() {
  // -------------------------------------------------------------------------
  // 1. Resolved semantics, per page, per field.
  // -------------------------------------------------------------------------
  group('resolved field semantics', () {
    Future<void> checkPage(
      WidgetTester tester,
      Widget host,
      List<FieldCase> cases,
      String page,
    ) async {
      await tester.pumpWidget(host);
      await tester.pumpAndSettle();

      for (final FieldCase c in cases) {
        final Finder f = fieldByHint(c.hint);
        expect(f, findsOneWidget,
            reason: '$page: no field renders hintText "${c.hint}"');
        final TextField field = tester.widget<TextField>(f);

        // A field with NO hints is DOM autocomplete="on" with no name and no
        // id (`text_editing.dart:514-531`) -- nothing for a password manager
        // to classify by. That is the defect this whole sweep exists to fix.
        expect(field.autofillHints, isNotNull,
            reason: '$page/${c.label}: must carry autofill hints');
        expect(field.autofillHints!.first, c.firstHint,
            reason: '$page/${c.label}: iOS and web consume ONLY the first hint '
                '(autofill.dart:688-694), so its identity is load-bearing');

        expect(field.keyboardType, c.keyboardType,
            reason: '$page/${c.label}: hint and keyboard must agree '
                '(editable_text.dart:1855-1858). '
                '${kKeyboardWasWrong[c.hint] ?? ""}');

        expect(field.obscureText, c.obscure,
            reason: '$page/${c.label}: obscureText must match the purpose');
        expect(field.textInputAction, c.action,
            reason: '$page/${c.label}: textInputAction is resolved by the '
                'purpose, never set independently');

        // The purpose is the single source of all of the above; assert the
        // table agrees with the enum so a drifting table cannot certify a
        // wrong field.
        expect(c.purpose.semantics.autofillHints?.first, c.firstHint,
            reason: '${c.purpose} must resolve ${c.firstHint}');
        expect(c.purpose.semantics.keyboardType, c.keyboardType);
        expect(c.purpose.semantics.obscureText, c.obscure);
        expect(c.purpose.semantics.textInputAction, c.action);
      }

      // No field on these pages is left unpurposed: every TextField the page
      // renders is one of the table's entries.
      expect(tester.widgetList<TextField>(find.byType(TextField)).length,
          cases.length,
          reason: '$page renders a field the expectation table does not cover');
    }

    testWidgets('EdenLoginPage', (WidgetTester tester) async {
      await checkPage(tester, hostLogin(), kLoginFields, 'EdenLoginPage');
    });
    testWidgets('EdenSignUpPage', (WidgetTester tester) async {
      await checkPage(tester, hostSignUp(), kSignUpFields, 'EdenSignUpPage');
    });
    testWidgets('EdenResetPasswordPage', (WidgetTester tester) async {
      await checkPage(
          tester, hostReset(), kResetFields, 'EdenResetPasswordPage');
    });
    testWidgets('EdenForgotPasswordPage', (WidgetTester tester) async {
      await checkPage(
          tester, hostForgot(), kForgotFields, 'EdenForgotPasswordPage');
    });
    testWidgets('EdenProfilePage', (WidgetTester tester) async {
      await checkPage(tester, hostProfile(), kProfileFields, 'EdenProfilePage');
    });
  });

  // -------------------------------------------------------------------------
  // 2. The keyboard repair (40-RESEARCH.md Appendix B1).
  // -------------------------------------------------------------------------
  group('mis-keyboarded name fields are repaired', () {
    testWidgets('EdenSignUpPage display name resolves TextInputType.name',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostSignUp());
      await tester.pumpAndSettle();
      final TextField f = tester.widget<TextField>(fieldByHint('Your name'));
      expect(f.autofillHints!.first, AutofillHints.name);
      expect(f.keyboardType, TextInputType.name,
          reason: 'was TextInputType.text -- TextField collapses a null '
              'keyboardType in its own initializer list '
              '(text_field.dart:355) before _inferKeyboardType can run, so '
              'the hint alone never fixed this');
    });

    testWidgets('EdenProfilePage display name resolves TextInputType.name',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostProfile());
      await tester.pumpAndSettle();
      final TextField f =
          tester.widget<TextField>(fieldByHint('Your display name'));
      expect(f.autofillHints!.first, AutofillHints.name);
      expect(f.keyboardType, TextInputType.name,
          reason: 'was TextInputType.text with NO hints at all');
    });
  });

  // -------------------------------------------------------------------------
  // 3. Obscured fields carry a password-family hint (mapped through the
  //    BROWSER token, per 40-RESEARCH.md Appendix B2).
  // -------------------------------------------------------------------------
  group('every obscured field is a DOM password field', () {
    Future<void> checkObscured(
      WidgetTester tester,
      Widget host,
      List<FieldCase> cases,
      String page,
    ) async {
      await tester.pumpWidget(host);
      await tester.pumpAndSettle();
      final Iterable<FieldCase> obscured =
          cases.where((FieldCase c) => c.obscure);
      expect(obscured, isNotEmpty, reason: '$page has no obscured field');

      for (final FieldCase c in obscured) {
        final TextField f = tester.widget<TextField>(fieldByHint(c.hint));
        expect(f.obscureText, isTrue);
        final String token = browserTokenFor(f.autofillHints!.first);
        expect(token.contains('password'), isTrue,
            reason: '$page/${c.label}: the DOM input type comes from the HINT '
                'string, never from obscureText '
                '(text_editing.dart:514-531). The raw constant is mapped '
                'through BrowserAutofillHints FIRST (:466-468), so '
                '"${f.autofillHints!.first}" must become a token containing '
                '"password" -- it became "$token"');
      }
    }

    testWidgets('EdenLoginPage', (WidgetTester tester) async {
      await checkObscured(tester, hostLogin(), kLoginFields, 'EdenLoginPage');
    });
    testWidgets('EdenSignUpPage', (WidgetTester tester) async {
      await checkObscured(tester, hostSignUp(), kSignUpFields, 'EdenSignUpPage');
    });
    testWidgets('EdenResetPasswordPage', (WidgetTester tester) async {
      await checkObscured(
          tester, hostReset(), kResetFields, 'EdenResetPasswordPage');
    });
    testWidgets('EdenProfilePage', (WidgetTester tester) async {
      await checkObscured(
          tester, hostProfile(), kProfileFields, 'EdenProfilePage');
    });
  });

  // -------------------------------------------------------------------------
  // 4. The deliberate duplicate-DOM-id pairs.
  // -------------------------------------------------------------------------
  group('new-password pairs share a hint on purpose', () {
    Future<void> checkPair(
      WidgetTester tester,
      Widget host,
      String newHint,
      String confirmHint,
      String page,
    ) async {
      await tester.pumpWidget(host);
      await tester.pumpAndSettle();
      final TextField a = tester.widget<TextField>(fieldByHint(newHint));
      final TextField b = tester.widget<TextField>(fieldByHint(confirmHint));

      expect(a.autofillHints!.first, AutofillHints.newPassword);
      expect(b.autofillHints!.first, AutofillHints.newPassword,
          reason: '$page: the confirm field keeps the SAME hint deliberately. '
              'element.name AND element.id are both the hint string '
              '(text_editing.dart:514-531), so this pair emits duplicate DOM '
              'ids -- accepted, because dropping the hint would make the '
              'confirm field DOM type="text" (password in plaintext, '
              'invisible to 1Password) and a custom hint string would emit an '
              'invalid autocomplete token. See '
              'EdenFieldPurpose.newPasswordConfirm');
      expect(browserTokenFor(a.autofillHints!.first), 'new-password');
      expect(browserTokenFor(b.autofillHints!.first), 'new-password');

      // Same hint, but they remain distinct MEMBERS, and the difference is
      // observable: the confirm field ends the form.
      expect(a.textInputAction, TextInputAction.next);
      expect(b.textInputAction, TextInputAction.done,
          reason: '$page: newPasswordConfirm is a separate enum member and '
              'resolves a different input action');
    }

    testWidgets('EdenSignUpPage', (WidgetTester tester) async {
      await checkPair(tester, hostSignUp(), 'Create a password',
          'Re-enter your password', 'EdenSignUpPage');
    });
    testWidgets('EdenResetPasswordPage', (WidgetTester tester) async {
      await checkPair(tester, hostReset(), 'Enter your new password',
          'Re-enter your new password', 'EdenResetPasswordPage');
    });
    testWidgets('EdenProfilePage', (WidgetTester tester) async {
      await checkPair(tester, hostProfile(), 'Choose a new password',
          'Re-enter your new password', 'EdenProfilePage');
    });
  });

  // -------------------------------------------------------------------------
  // 5. THE SAVE PATH. Positives first, then the negatives that matter more.
  // -------------------------------------------------------------------------
  group('save path -- EdenLoginPage', () {
    testWidgets('commits after a successful sign-in',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostLogin());
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      await tester.enterText(fieldByHint('Enter your password'), 'hunter2');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), hasLength(1),
          reason: 'hints only make a field FILLABLE; nothing is ever SAVED '
              'without TextInput.finishAutofillContext (on web saveForms() '
              'clicks the hidden submitBtn, text_editing.dart:2245)');
    });

    testWidgets('does NOT commit when onLogin throws',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostLogin(
        onLogin: (String e, String p) async => throw Exception('bad creds'),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      await tester.enterText(fieldByHint('Enter your password'), 'wrong');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'committing after a REJECTED sign-in makes 1Password offer '
              'to save the WRONG password');
      expect(find.textContaining('bad creds'), findsOneWidget,
          reason: 'the page must still surface the failure');
    });

    testWidgets('does NOT commit when the fields are empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostLogin());
      await tester.pumpAndSettle();

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'client-side validation rejected the attempt before onLogin '
              'ever ran');
      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });

    testWidgets('dev login never commits', (WidgetTester tester) async {
      await tester.pumpWidget(hostLogin(
        devLoginConfig: const EdenDevLoginConfig(enabled: true),
      ));
      await tester.pumpAndSettle();

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Dev Login'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'dev login bypasses the text fields entirely, so a commit '
              'would ask the password manager to save the empty inputs under '
              'the real origin');
    });
  });

  group('save path -- EdenSignUpPage', () {
    testWidgets('commits after a successful sign-up',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostSignUp());
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('Your name'), 'Ada');
      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      await tester.enterText(fieldByHint('Create a password'), 'hunter2');
      await tester.enterText(fieldByHint('Re-enter your password'), 'hunter2');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), hasLength(1));
    });

    testWidgets('does NOT commit when onSignUp throws',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostSignUp(
        onSignUp: (String n, String e, String p) async =>
            throw Exception('email taken'),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('Your name'), 'Ada');
      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      await tester.enterText(fieldByHint('Create a password'), 'hunter2');
      await tester.enterText(fieldByHint('Re-enter your password'), 'hunter2');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'the account was never created; saving would store a '
              'credential that does not exist');
      expect(find.textContaining('email taken'), findsOneWidget);
    });

    testWidgets('does NOT commit when the passwords do not match',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostSignUp());
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('Your name'), 'Ada');
      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      await tester.enterText(fieldByHint('Create a password'), 'hunter2');
      await tester.enterText(fieldByHint('Re-enter your password'), 'typo');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'client-side validation stopped the submit before onSignUp');
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  group('save path -- EdenResetPasswordPage', () {
    testWidgets('commits after a successful reset',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostReset());
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('Enter your new password'), 'hunter2');
      await tester.enterText(
          fieldByHint('Re-enter your new password'), 'hunter2');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      // TWO saves, and both are accounted for:
      //   1. `EdenAutofillScope.commit()` on the success path -- the one this
      //      TRD adds, fired at the moment the new password is accepted.
      //   2. `AutofillGroupState.dispose()`, because
      //      `AutofillGroup.onDisposeAction` DEFAULTS to
      //      `AutofillContextAction.commit` (`autofill.dart:75`, dispatched at
      //      `:232-243`) and reaching the success state unmounts the form that
      //      holds the group.
      //
      // The second is pre-existing framework behaviour, not something this
      // sweep introduced -- the page already wrapped these fields in a bare
      // `AutofillGroup`. It is pinned here rather than tolerated as a fuzzy
      // ">= 1" so that either half disappearing fails loudly.
      expect(savesIn(calls), hasLength(2),
          reason: 'one explicit commit on success, one from the framework '
              'disposing the topmost AutofillGroup (autofill.dart:232-243)');
      expect(find.text('Password reset successful'), findsOneWidget,
          reason: 'the page must reach its success state too');
    });

    testWidgets('does NOT commit when onResetPassword throws',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostReset(
        onResetPassword: (String p) async => throw Exception('token expired'),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(fieldByHint('Enter your new password'), 'hunter2');
      await tester.enterText(
          fieldByHint('Re-enter your new password'), 'hunter2');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'the password was never changed; saving it would leave the '
              'manager holding a secret the account does not have. The form '
              'stays mounted on this path, so the dispose-time commit '
              '(autofill.dart:232-243) cannot mask a missing guard here');
      expect(find.textContaining('token expired'), findsOneWidget);
    });
  });

  group('save path -- EdenProfilePage', () {
    testWidgets('commits BEFORE the password fields are cleared',
        (WidgetTester tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
          hostProfile(onChangePassword: (String a, String b) async {}));
      await tester.pumpAndSettle();
      await tester.enterText(
          fieldByHint('Enter your current password'), 'old-one');
      await tester.enterText(fieldByHint('Choose a new password'), 'hunter2');
      await tester.enterText(
          fieldByHint('Re-enter your new password'), 'hunter2');

      // Read the live controller text at the exact moment the save fires. On
      // web the browser reads the DOM input values when saveForms() clicks the
      // hidden submit button, so a commit placed after the clears would offer
      // to save three EMPTY fields.
      //
      // The controller is captured HERE rather than looked up inside the
      // callback: the callback runs from a platform-channel reply, where
      // evaluating a Finder throws "Bad state: No element". The controller
      // object itself is created once in the page's initState, so this
      // reference stays valid across the rebuilds.
      final TextEditingController newPassword =
          tester.widget<TextField>(fieldByHint('Choose a new password'))
              .controller!;
      String textAtSave = 'NEVER CAPTURED';
      final List<MethodCall> calls = spyOnTextInput(tester,
          onCall: (MethodCall c) {
        if (c.method == 'TextInput.finishAutofillContext') {
          textAtSave = newPassword.text;
        }
      });

      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), hasLength(1));
      expect(textAtSave, 'hunter2',
          reason: 'the commit must happen while the fields still hold the new '
              'password -- clearing first would save empty values');
      expect(newPassword.text, isEmpty,
          reason: 'and the fields are still cleared afterwards');
    });

    testWidgets('does NOT commit when the passwords do not match',
        (WidgetTester tester) async {
      useTallViewport(tester);
      await tester.pumpWidget(
          hostProfile(onChangePassword: (String a, String b) async {}));
      await tester.pumpAndSettle();
      await tester.enterText(
          fieldByHint('Enter your current password'), 'old-one');
      await tester.enterText(fieldByHint('Choose a new password'), 'hunter2');
      await tester.enterText(fieldByHint('Re-enter your new password'), 'typo');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty,
          reason: 'client-side validation stopped the submit before '
              'onChangePassword ran');
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('does NOT commit while the change is still in flight',
        (WidgetTester tester) async {
      useTallViewport(tester);
      // A Completer, not `async => throw`: it puts the moment the request
      // resolves under the test's control, so the commit can be observed
      // BEFORE and AFTER the await resumes.
      //
      // COVERAGE GAP, recorded deliberately: the REJECTION half of this case
      // cannot be asserted here. `EdenProfilePage._handleChangePassword` has a
      // `finally` but no `catch`, so a rejected `onChangePassword` escapes as
      // an uncaught async error into the test zone, which terminates the test
      // body before any assertion or `takeException()` can run -- and wrapping
      // the tap in `runZonedGuarded` trips TestAsyncUtils. Giving the page a
      // `catch` would fix it but is a behaviour change this purpose sweep must
      // not make. The same commit-on-rejection path IS covered on
      // EdenLoginPage, EdenSignUpPage and EdenResetPasswordPage, which all
      // catch their own failures.
      final Completer<void> pending = Completer<void>();
      await tester.pumpWidget(hostProfile(
        onChangePassword: (String a, String b) => pending.future,
      ));
      await tester.pumpAndSettle();
      await tester.enterText(
          fieldByHint('Enter your current password'), 'old-one');
      await tester.enterText(fieldByHint('Choose a new password'), 'hunter2');
      await tester.enterText(
          fieldByHint('Re-enter your new password'), 'hunter2');

      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Update Password'));
      await tester.pump();

      expect(savesIn(calls), isEmpty,
          reason: 'the request has not resolved yet -- the commit must sit '
              'AFTER the await, not beside the button press. A commit wired to '
              'the tap would offer to save before the server agreed');

      pending.complete();
      await tester.pumpAndSettle();

      expect(savesIn(calls), hasLength(1),
          reason: 'and it fires once the change is actually accepted');
    });
  });

  group('save path -- EdenForgotPasswordPage', () {
    testWidgets('installs no autofill scope and never commits',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostForgot());
      await tester.pumpAndSettle();

      expect(find.byType(EdenAutofillScope), findsNothing,
          reason: 'there is no credential on this page -- only an address to '
              'send a link to. A scope would add a save path for something '
              'that must never be stored as a credential. The absence is a '
              'decision, not an oversight');

      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      final List<MethodCall> calls = spyOnTextInput(tester);
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      expect(savesIn(calls), isEmpty);
      expect(find.text('Check your email'), findsOneWidget,
          reason: 'the page must still complete its own flow');
    });

    testWidgets('Enter still submits despite textInputAction.next',
        (WidgetTester tester) async {
      String? captured;
      await tester.pumpWidget(hostForgot(
        onSendResetLink: (String e) async => captured = e,
      ));
      await tester.pumpAndSettle();

      final TextField f = tester.widget<TextField>(fieldByHint('you@example.com'));
      expect(f.textInputAction, TextInputAction.next,
          reason: 'EdenFieldPurpose.email resolves next; this field passed no '
              'action at all before the sweep');

      await tester.enterText(fieldByHint('you@example.com'), 'ada@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(captured, 'ada@example.com',
          reason: 'onSubmitted fires for every action in '
              'EditableText._finalizeEditing, not only for done -- the '
              'changed action must not have cost this one-field form its '
              'Enter-to-submit');
    });
  });

  // -------------------------------------------------------------------------
  // 6. Clipboard posture. Both cases set a REAL non-collapsed selection first:
  //    copyEnabled is `!obscureText && !selection.isCollapsed`, so an empty
  //    selection makes EVERY field report false and the assertion vacuous
  //    (40-RESEARCH.md Appendix A).
  // -------------------------------------------------------------------------
  group('clipboard posture is unchanged by the sweep', () {
    testWidgets('an obscured field still cannot copy, with a real selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostLogin());
      await tester.pumpAndSettle();

      final Finder f = fieldByHint('Enter your password');
      await tester.enterText(f, 'hunter2-secret');
      final TextEditingController c = tester.widget<TextField>(f).controller!;
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 14);
      await tester.pump();

      final EditableTextState state = tester.state<EditableTextState>(
        find.descendant(of: f, matching: find.byType(EditableText)),
      );
      expect(state.textEditingValue.selection.isCollapsed, isFalse,
          reason: 'guards against the vacuous form of this assertion');
      expect(state.copyEnabled, isFalse,
          reason: 'obscureText hard-disables copy and cut '
              '(editable_text.dart:2641-2646); a secret needs an explicit copy '
              'button, not a clipboard gesture');
      expect(state.cutEnabled, isFalse);
    });

    testWidgets('an ordinary field can still copy, with a real selection',
        (WidgetTester tester) async {
      await tester.pumpWidget(hostProfile());
      await tester.pumpAndSettle();

      final Finder f = fieldByHint('your@email.com');
      await tester.enterText(f, 'ada@example.com');
      final TextEditingController c = tester.widget<TextField>(f).controller!;
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 15);
      await tester.pump();

      final EditableTextState state = tester.state<EditableTextState>(
        find.descendant(of: f, matching: find.byType(EditableText)),
      );
      expect(state.textEditingValue.selection.isCollapsed, isFalse,
          reason: 'guards against the vacuous form of this assertion');
      expect(state.copyEnabled, isTrue,
          reason: 'the sweep assigns purposes; it must not have taken copy '
              'away from any non-secret field');
    });
  });
}
