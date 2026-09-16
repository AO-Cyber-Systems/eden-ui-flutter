// lib/src/widgets/eden_field_purpose.dart
//
// EdenFieldPurpose — the semantic enum that makes two documented Flutter traps
// structurally unrepresentable.
//
// TRAP 1 — the hint <-> keyboardType coupling.
//   `editable_text.dart:1855-1858` states that some autofill hints only work with
//   specific keyboard types: `AutofillHints.name` requires `TextInputType.name`,
//   and `AutofillHints.email` works only with `TextInputType.emailAddress`.
//   Flutter's own `_inferKeyboardType` helper (`editable_text.dart:2225`) derives
//   the right keyboard from the hints, but it runs ONLY when `keyboardType` is
//   null:  `keyboardType ?? _inferKeyboardType(...)`.  Any caller that passes an
//   explicit keyboard therefore silently breaks iOS autofill with no warning.
//   Here, ONE purpose resolves BOTH — they cannot drift apart.
//
// TRAP 2 — platform divergence in hint handling.
//   `services/autofill.dart:688-694`: iOS translates only the FIRST hint (to a
//   `UITextContentType`), web translates only the FIRST hint (to an `autocomplete`
//   token), Android translates ALL of them.  Hint ORDER is load-bearing.  Every
//   list below is ordered iOS/web-first, with Android-only extras after index 0.
//
// TRAP 3 — `obscureText` does NOT make a web password field.
//   `web_ui/.../text_editing.dart:514-531` sets
//   `element.type = autofillHint.contains('password') ? 'password' : 'text'`.
//   The DOM type comes from the HINT STRING, never from `obscureText`.  A password
//   input without a password-family hint renders as `type="text"` — the secret is
//   plaintext in the DOM and 1Password can neither fill nor save it.  Every
//   obscured member below therefore emits a password-family hint at index 0; the
//   test suite enforces it.
//
// Convention: plain `enum` + `@immutable` const value class, matching
// `eden_secret_field.dart:22` and `eden_data_table.dart:345`.  No code generation
// — neither freezed nor json_serializable is a dependency of this package.

import 'package:flutter/material.dart';

/// The complete, internally consistent set of text-input semantics that one
/// [EdenFieldPurpose] resolves to.
///
/// There is deliberately no public path that lets a caller supply
/// [autofillHints] and [keyboardType] independently — that is precisely the
/// mismatch this type exists to delete (see TRAP 1 in the file header).
@immutable
class EdenFieldSemantics {
  const EdenFieldSemantics({
    this.autofillHints,
    required this.keyboardType,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  /// Ordered iOS/web-FIRST. Index 0 is the only hint iOS and web consume
  /// (`autofill.dart:688-694`); any entries after it are Android-only extras.
  ///
  /// `null` means "deliberately no autofill purpose" — never an empty list.
  /// An empty list would be an ambiguous third state that reads as "I tried
  /// and found nothing" rather than "this field has no autofill purpose".
  final List<String>? autofillHints;

  /// Always non-null, so Flutter's `_inferKeyboardType` fallback never has to
  /// run and can never disagree with [autofillHints].
  final TextInputType keyboardType;

  /// Note: `true` HARD-DISABLES copy and cut in the framework
  /// (`editable_text.dart:2641-2646`). It is not configurable. Obscured fields
  /// that need a copy affordance must supply an explicit button — that is why
  /// `EdenSecretField` has one.
  final bool obscureText;

  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
}

// ── Hint lists ───────────────────────────────────────────────────────────────
// Declared as `const` top-level lists so the shared instance cannot be mutated
// by a consumer. Index 0 of each is the iOS/web token; anything after it is an
// Android-only extra.

const List<String> _kUsername = <String>[AutofillHints.username];
const List<String> _kEmail = <String>[AutofillHints.email, AutofillHints.username];
const List<String> _kCurrentPassword = <String>[AutofillHints.password];
const List<String> _kNewPassword = <String>[AutofillHints.newPassword];
const List<String> _kOneTimeCode = <String>[AutofillHints.oneTimeCode];
const List<String> _kPersonName = <String>[AutofillHints.name];
const List<String> _kGivenName = <String>[AutofillHints.givenName, AutofillHints.name];
const List<String> _kFamilyName = <String>[AutofillHints.familyName, AutofillHints.name];
const List<String> _kOrganizationName = <String>[AutofillHints.organizationName];
const List<String> _kJobTitle = <String>[AutofillHints.jobTitle];
const List<String> _kTelephoneNumber = <String>[AutofillHints.telephoneNumber];
const List<String> _kStreetAddressLine1 = <String>[
  AutofillHints.streetAddressLine1,
  AutofillHints.fullStreetAddress,
];
const List<String> _kStreetAddressLine2 = <String>[AutofillHints.streetAddressLine2];
const List<String> _kAddressCity = <String>[AutofillHints.addressCity];
const List<String> _kAddressState = <String>[AutofillHints.addressState];
const List<String> _kPostalCode = <String>[AutofillHints.postalCode];
const List<String> _kCountryName = <String>[AutofillHints.countryName];
const List<String> _kCreditCardNumber = <String>[AutofillHints.creditCardNumber];
const List<String> _kCreditCardExpirationDate = <String>[
  AutofillHints.creditCardExpirationDate,
];
const List<String> _kCreditCardSecurityCode = <String>[
  AutofillHints.creditCardSecurityCode,
];
const List<String> _kCreditCardName = <String>[
  AutofillHints.creditCardName,
  AutofillHints.name,
];
const List<String> _kBirthday = <String>[AutofillHints.birthday];

/// The semantic purpose of a text input.
///
/// Choosing a purpose resolves [EdenFieldSemantics.autofillHints] (in
/// platform-correct order), [EdenFieldSemantics.keyboardType],
/// [EdenFieldSemantics.obscureText], [EdenFieldSemantics.textInputAction] and
/// [EdenFieldSemantics.textCapitalization] as ONE consistent set. A caller
/// cannot pick a hint and a mismatched keyboard.
enum EdenFieldPurpose {
  /// Deliberately no autofill purpose — search boxes, chat composers, filters.
  ///
  /// Greppable: choosing `none` is a decision, omitting a purpose is a bug the
  /// guard test (TRD 40-17) will catch.
  none,

  /// A login identifier that is not necessarily an email address.
  username,

  /// An email address, usable as a login identifier on Android (which reads all
  /// hints, so `username` follows as an Android-only extra).
  email,

  /// An existing password being entered to sign in. Maps to the web
  /// `autocomplete="current-password"` token.
  currentPassword,

  /// A password being chosen for the first time, or being reset. Maps to the
  /// web `autocomplete="new-password"` token.
  newPassword,

  /// The "confirm new password" field of a signup or password-reset form.
  ///
  /// Duplicate-DOM-id decision (locked in `40-RESEARCH.md`, consumed by
  /// TRD 40-10): `element.name` AND `element.id` are both the hint string
  /// (`text_editing.dart:514-531`), so two fields sharing a hint in one
  /// `AutofillGroup` — new password + confirm password, both
  /// `AutofillHints.newPassword` — emit duplicate DOM ids.
  ///
  /// **Decision: emit `AutofillHints.newPassword` for BOTH, and keep them as two
  /// distinct enum members (`newPassword`, `newPasswordConfirm`).** Rationale:
  /// - Two `autocomplete="new-password"` inputs is the standard HTML signup
  ///   shape; browsers and 1Password handle it. Duplicate `id` is tolerated by
  ///   HTML parsing (`getElementById` returns the first) and is a Flutter-web
  ///   artifact, not a spec violation we can fix from here.
  /// - The alternatives are worse: dropping the hint on confirm makes it DOM
  ///   `type="text"` — the password visible in the DOM and invisible to
  ///   1Password; inventing a custom hint string emits an invalid `autocomplete`
  ///   token, which `40-RESEARCH.md` §7 explicitly warns against ("do not invent
  ///   workarounds that fight the engine").
  /// - Keeping `newPasswordConfirm` as a separate MEMBER means the semantic
  ///   distinction is greppable and a future upstream fix is a one-line change in
  ///   this file rather than a sweep.
  newPasswordConfirm,

  /// A one-time passcode from SMS, email or an authenticator app.
  oneTimeCode,

  /// A person's full name in one field.
  personName,

  /// A person's first/given name.
  givenName,

  /// A person's last/family name.
  familyName,

  /// A company or organisation name.
  organizationName,

  /// A person's job title or role.
  jobTitle,

  /// A telephone number.
  telephoneNumber,

  /// The first line of a street address.
  streetAddressLine1,

  /// The second line of a street address — apartment, suite, unit.
  streetAddressLine2,

  /// The city or locality of an address.
  addressCity,

  /// The state, province or region of an address.
  addressState,

  /// A postal or ZIP code. Alphanumeric in CA/UK, hence a text keyboard.
  postalCode,

  /// The country of an address.
  countryName,

  /// A payment card number.
  creditCardNumber,

  /// A payment card expiry date.
  creditCardExpirationDate,

  /// A payment card security code (CVV/CVC).
  ///
  /// Deliberately NOT obscured: a CVV is conventionally visible, and obscuring it
  /// would hard-disable copy and cut (`editable_text.dart:2641-2646`) for no
  /// security benefit.
  creditCardSecurityCode,

  /// The cardholder name printed on a payment card.
  creditCardName,

  /// A date of birth.
  birthday,

  /// A search box. Typed but deliberately unfilled — there is no
  /// `AutofillHints` constant for a search query, and inventing one would emit an
  /// invalid `autocomplete` token.
  searchQuery,

  /// A free-form multi-line composer — notes, descriptions, messages. Typed but
  /// deliberately unfilled.
  multilineText,

  /// A whole-number quantity or count. Typed but deliberately unfilled.
  quantity,

  /// A decimal money or measurement amount. Typed but deliberately unfilled.
  decimalAmount,

  /// A web address. Typed but deliberately unfilled.
  url;

  /// The complete, internally consistent semantics for this purpose.
  ///
  /// Implemented as a `switch` expression with NO default arm, so adding a member
  /// to [EdenFieldPurpose] is a compile error until it is resolved here.
  EdenFieldSemantics get semantics => switch (this) {
        EdenFieldPurpose.none => const EdenFieldSemantics(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.sentences,
          ),
        EdenFieldPurpose.username => const EdenFieldSemantics(
            autofillHints: _kUsername,
            keyboardType: TextInputType.text,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.email => const EdenFieldSemantics(
            autofillHints: _kEmail,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.currentPassword => const EdenFieldSemantics(
            autofillHints: _kCurrentPassword,
            keyboardType: TextInputType.text,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.newPassword => const EdenFieldSemantics(
            autofillHints: _kNewPassword,
            keyboardType: TextInputType.text,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.newPasswordConfirm => const EdenFieldSemantics(
            autofillHints: _kNewPassword,
            keyboardType: TextInputType.text,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.oneTimeCode => const EdenFieldSemantics(
            autofillHints: _kOneTimeCode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.personName => const EdenFieldSemantics(
            autofillHints: _kPersonName,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.givenName => const EdenFieldSemantics(
            autofillHints: _kGivenName,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.familyName => const EdenFieldSemantics(
            autofillHints: _kFamilyName,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.organizationName => const EdenFieldSemantics(
            autofillHints: _kOrganizationName,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.jobTitle => const EdenFieldSemantics(
            autofillHints: _kJobTitle,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.telephoneNumber => const EdenFieldSemantics(
            autofillHints: _kTelephoneNumber,
            keyboardType: TextInputType.phone,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.streetAddressLine1 => const EdenFieldSemantics(
            autofillHints: _kStreetAddressLine1,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.streetAddressLine2 => const EdenFieldSemantics(
            autofillHints: _kStreetAddressLine2,
            keyboardType: TextInputType.streetAddress,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.addressCity => const EdenFieldSemantics(
            autofillHints: _kAddressCity,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.addressState => const EdenFieldSemantics(
            autofillHints: _kAddressState,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
          ),
        // Alphanumeric in CA/UK — a number keyboard would make `K1A 0B1`
        // untypeable, so this is deliberately `text`.
        EdenFieldPurpose.postalCode => const EdenFieldSemantics(
            autofillHints: _kPostalCode,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.countryName => const EdenFieldSemantics(
            autofillHints: _kCountryName,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
          ),
        EdenFieldPurpose.creditCardNumber => const EdenFieldSemantics(
            autofillHints: _kCreditCardNumber,
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.creditCardExpirationDate => const EdenFieldSemantics(
            autofillHints: _kCreditCardExpirationDate,
            keyboardType: TextInputType.datetime,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.creditCardSecurityCode => const EdenFieldSemantics(
            autofillHints: _kCreditCardSecurityCode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.creditCardName => const EdenFieldSemantics(
            autofillHints: _kCreditCardName,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.birthday => const EdenFieldSemantics(
            autofillHints: _kBirthday,
            keyboardType: TextInputType.datetime,
            autocorrect: false,
            enableSuggestions: false,
          ),
        EdenFieldPurpose.searchQuery => const EdenFieldSemantics(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.search,
          ),
        EdenFieldPurpose.multilineText => const EdenFieldSemantics(
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
          ),
        EdenFieldPurpose.quantity => const EdenFieldSemantics(
            keyboardType: TextInputType.number,
          ),
        EdenFieldPurpose.decimalAmount => const EdenFieldSemantics(
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        EdenFieldPurpose.url => const EdenFieldSemantics(
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
          ),
      };
}
